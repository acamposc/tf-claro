# cargar variables de entorno
# https://stackoverflow.com/questions/55052153/how-to-configure-environment-variables-in-hashicorp-terraform
        variable "PROJECT_NAME" {}
        variable "CREDENTIALS" {}
        variable "BUCKET_ID" {}
 

#Crear un bucket en el proyecto de gcp de Claro Ecommerce Analitica
#referencia: https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference
#referencia: https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket
#referencia: https://stackoverflow.com/questions/60055109/want-to-deploy-a-storage-bucket-with-public-readable-storage-object-permission-i


        provider "google" {
        project = var.PROJECT_NAME
        credentials = var.CREDENTIALS
        }


        resource "google_storage_default_object_access_control" "public_rule" {
        bucket = google_storage_bucket.bucket_input.name
        role   = "READER"
        entity = "allUsers"
        }

        resource "google_storage_bucket" "bucket_input" {
        name = "${var.PROJECT_NAME}-files_input"
        project = var.PROJECT_NAME
        storage_class = "STANDARD"
        location = "US"
        }

########
        resource "google_storage_bucket" "bucket_output" {
        name = "${var.PROJECT_NAME}-files_output"
        project = var.PROJECT_NAME
        storage_class = "STANDARD"
        location = "US"
        }


# Crear un topic en pubsub
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_topic
# https://stackoverflow.com/questions/61318241/gcp-terraform-how-to-connect-pubsub-topic-to-budget
        resource "google_pubsub_topic" "topic" {
        name    = "${var.PROJECT_NAME}-file_topic"
        project = var.PROJECT_NAME
        }

# Crear una subscripcion de pubsub y vincularla al topic
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_subscription
        resource "google_pubsub_subscription" "subscription" {
        name = "${var.PROJECT_NAME}-file_subscription"
        topic = google_pubsub_topic.topic.name 

        message_retention_duration = "1200s"
        retain_acked_messages      = true

        ack_deadline_seconds = 20

        expiration_policy {
            ttl = "300000.5s"
        }
        retry_policy {
            minimum_backoff = "10s"
        }

        enable_message_ordering    = false
        }

# Notificar, en pubsub cuando un archivo se carga en un bucket
# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_notification
        resource "google_storage_notification" "notification" {
        bucket         = google_storage_bucket.bucket_input.name
        payload_format = "JSON_API_V1"
        topic          = google_pubsub_topic.topic.id
        event_types    = ["OBJECT_FINALIZE", "OBJECT_METADATA_UPDATE"]
        custom_attributes = {
            #timestamp = timestamp(),
            dev = "AC"
                    }
        depends_on = [google_pubsub_topic_iam_binding.binding]
        }

        // Enable notifications by giving the correct IAM permission to the unique service account.

        data "google_storage_project_service_account" "gcs_account" {
        }

        resource "google_pubsub_topic_iam_binding" "binding" {
        topic   = google_pubsub_topic.topic.id
        role    = "roles/pubsub.publisher"
        members = ["serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"]
        }


## Cloud function que se suscriba al topic de cloud storage.
## https://diarmuid.ie/blog/setting-up-a-recurring-google-cloud-function-with-terraform
## https://stackoverflow.com/questions/55978786/deploying-google-cloud-function-by-terraform-got-error-400-the-request-has-err

resource "google_cloudfunctions_function" "function" {
  name                = "tst_function_001"
  entry_point         = "upload_to_bucket"
  available_memory_mb = 128
  project             = var.PROJECT_NAME
  runtime             = "python37"
  region              = "us-central1"

  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.topic.name
  }

  source_archive_bucket = "${var.PROJECT_NAME}-files_input"
  source_archive_object = google_storage_bucket_object.archive.name
}

 data "archive_file" "src" {
        type        = "zip"
        source_dir  = "${path.root}/fn" # Directory where your Python source code is
        output_path = "${path.root}/generated/fn.zip"
        }

resource "google_storage_bucket_object" "archive" {
  name       = "fn-${timestamp()}.zip"
  bucket     = "${var.PROJECT_NAME}-files_input"
  source     = "${path.root}/generated/fn.zip"
  depends_on = [data.archive_file.src]
}
