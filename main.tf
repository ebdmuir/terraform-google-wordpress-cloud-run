resource "random_string" "password" {
  length           = 16
  special          = true
  override_special = "/@£$"
}

resource "google_cloud_run_service" "this" {
  name     = var.name
  location = local.gke_region
  template {
    spec {
      containers {
        image = var.image
        env {
          name  = "WORDPRESS_DB_HOST"
          value = google_sql_database_instance.this.public_ip_address
        }
        env {
          name  = "WORDPRESS_DB_USER"
          value = "wordpress"
        }
        env {
          name  = "WORDPRESS_DB_PASSWORD"
          value = random_string.password.result
        }
        env {
          name  = "WORDPRESS_DB_NAME"
          value = "wordpress-test"
        }
      }
    }
  }
  traffic {
    percent         = 100
    latest_revision = true
  }
}

resource "google_sql_database_instance" "this" {
  name             = var.name
  region           = local.gke_region
  database_version = "MYSQL_5_7"
  settings {
    tier = var.db_class
  }

  deletion_protection = "false"
}

resource "google_sql_user" "this" {
  name     = "wordpress"
  instance = google_sql_database_instance.this.name
  password = random_string.password.result
}