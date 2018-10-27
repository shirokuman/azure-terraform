# Proviers
provider "azurerm" {}

# Variables
variable "sas_token" {}

# Local Values
locals {
  resource_group_name      = "w-tfrm-rg"
  location                 = "japanwest"
  storage_account_name     = "wtfrmstorage"
  storage_account_tier     = "Standard"
  storage_replication_type = "LRS"
  storage_queue_name       = "queue"
  job_collection_name      = "w-arm-scheduler-1"
  job_name                 = "Scheduler01"
}

# Resources
resource "azurerm_resource_group" "rg" {
  name     = "${local.resource_group_name}"
  location = "${local.location}"
}

resource "azurerm_scheduler_job_collection" "scheduler" {
  name                = "${local.job_collection_name}"
  location            = "${azurerm_resource_group.rg.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  sku                 = "free"
  state               = "enabled"

  quota {
      max_job_count            = 5
      max_recurrence_interval  = 1
      max_recurrence_frequency = "hour"
  }
}

resource "random_integer" "num" {
  min = 10000
  max = 99999
}

resource "azurerm_storage_account" "str" {
  name                     = "${local.storage_account_name}${random_integer.num.result}"
  resource_group_name      = "${azurerm_resource_group.rg.name}"
  location                 = "${azurerm_resource_group.rg.location}"
  account_tier             = "${local.storage_account_tier}"
  account_replication_type = "${local.storage_replication_type}"
}

resource "azurerm_storage_queue" "queue" {
  name                 = "${local.storage_queue_name}"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  storage_account_name = "${azurerm_storage_account.str.name}"
}

resource "azurerm_scheduler_job" "jobs" {
  name                = "${local.job_name}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  job_collection_name = "${azurerm_scheduler_job_collection.scheduler.name}"

  action_storage_queue = {
    storage_account_name = "${azurerm_storage_account.str.name}"
    storage_queue_name   = "${azurerm_storage_queue.queue.name}"
    sas_token            = "${var.sas_token}"
    message              = "Hello!World."
  }

  retry {
    interval = "01:00:00"
    count    =  12
  }

  start_time = "2018-07-07T07:07:07-00:00"
}
