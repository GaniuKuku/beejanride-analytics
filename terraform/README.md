# Terraform Infrastructure

Terraform is used to provision and manage the Google Cloud infrastructure for BeejanRide as Infrastructure as Code (IaC). Instead of creating cloud resources manually, the desired infrastructure is defined declaratively in Terraform configuration files.

## Authentication

Two Google Cloud authentication commands serve different purposes:

*   `gcloud auth login`
    Authenticates the gcloud CLI.
*   `gcloud auth application-default login`
    Creates Application Default Credentials (ADC), which Terraform can use when communicating with Google Cloud.

## How Terraform Works

Terraform follows a declarative approach. I describe the desired end state, and Terraform determines what changes are required to make the real infrastructure match it.

The core workflow is:

**Configuration → init → plan → apply → state**

### terraform init
Initializes the working directory, downloads required providers, and prepares Terraform to manage the configuration.

It also creates `.terraform.lock.hcl`, which records the selected provider versions. The lock file is committed to Git, while the generated `.terraform/` directory is ignored.

### terraform validate
Checks whether the Terraform configuration is syntactically and structurally valid.

It does not create or modify infrastructure.

### terraform plan
Compares the desired configuration with the current state and infrastructure, then shows the changes Terraform would make.

Common plan symbols:
```text
+   create
~   update in-place
-   destroy
-/+ replace
```

### terraform apply
Executes the changes proposed by Terraform.

### Terraform State
Terraform state is more than a history of previous operations. It is Terraform's record of the infrastructure it manages and the relationship between the configuration and real resources.

For example:

```terraform state list```

shows the resources currently tracked by Terraform.

Because state can contain sensitive infrastructure information, it should not normally be committed to Git.

### Remote State
Instead of keeping state only on the local machine, this project uses a Google Cloud Storage (GCS) backend to store Terraform state remotely.

Benefits include:

- Centralized state storage

- Persistence outside the local machine

- A shared location for collaborative workflows

- Protection against losing the local state file

- Support for safer concurrent Terraform workflows through backend state locking mechanisms

The Terraform state bucket has versioning enabled, allowing previous versions of the state object to be retained.

The bootstrap problem
The state bucket itself had to be created before Terraform could use it as its backend.

The process was therefore:

- Use local state initially

- Create the dedicated GCS state bucket

- Configure the GCS backend

- Run terraform init

- Migrate the state to GCS

This is a common Terraform bootstrap pattern.

## **Providers, Resources, Variables, Locals and Outputs**

Terraform configurations are built from several important components:

| Concept | Purpose |
|---|---|
| **Provider** | Allows Terraform to communicate with an external platform such as Google Cloud |
| **Resource** | Defines infrastructure Terraform creates or manages |
| **Variable** | Provides configurable inputs to the configuration |
| **Local** | Defines reusable internal values within the configuration |
| **Data source** | Reads existing information without managing its lifecycle |
| **Output** | Exposes useful values after Terraform operations |

## Resource vs Data Source
The distinction is important:

### Resource
Terraform manages its lifecycle.
It can create, update or destroy the resource.

### Data source
Terraform reads information that already exists.

For example, the project number was retrieved using the Google Cloud project data source rather than hardcoding it.

### Resource Referencing
Terraform resources can reference one another directly instead of hardcoding values.

For example, one resource can use an attribute from another resource:

```resource.attribute```

This creates an implicit dependency, allowing Terraform to determine the correct order in which resources should be created.

It also makes the configuration more dynamic and less dependent on manually entered values.

### Computed Values
Terraform sometimes displays:

(known after apply)

This means Terraform knows the value will exist but cannot determine its final value until the resource is created or queried by the provider.

Examples include generated resource IDs, URLs and timestamps.

This helped demonstrate that Terraform plans can contain values that are resolved during the apply phase.

### Infrastructure Provisioned
Terraform provisions the core Google Cloud infrastructure for the project:

- GCS data lake bucket

- GCS bucket for Terraform remote state

- Four BigQuery datasets

- Associated configuration such as labels, bucket versioning and uniform bucket-level access

The BigQuery warehouse is organized into four layers:

- beejanride_raw

- beejanride_stg

- beejanride_int

- beejanride_marts


This keeps ingestion, transformation and analytical models logically separated.

```for_each```

The four BigQuery datasets share similar configuration, so Terraform's for_each meta-argument was used instead of repeating four resource blocks.

Terraform
```
for_each = toset([
  "beejanride_raw",
  "beejanride_stg",
  "beejanride_int",
  "beejanride_marts"
])
```
for_each creates multiple instances of the same resource from a collection of values.

Each instance can then be referenced using its key:

Terraform
```
google_bigquery_dataset.layers["beejanride_raw"]
google_bigquery_dataset.layers["beejanride_stg"]
google_bigquery_dataset.layers["beejanride_int"]
google_bigquery_dataset.layers["beejanride_marts"]
```
The main lesson was that for_each is useful when several resources share a configuration pattern but should still be tracked and managed independently.

### Terraform Modules
A module is a reusable package of Terraform configuration.

The directory containing the main Terraform configuration is the root module. Reusable infrastructure can be extracted into child modules.

For this project, the GCS data lake bucket was refactored into a reusable storage module.

This separates the implementation details of the bucket from the root infrastructure configuration and makes the component easier to reuse in future projects.

### Resource addresses and refactoring
Moving an existing resource into a module changes its Terraform resource address.

For example:

```google_storage_bucket.data_lake```

became:

```module.data_lake.google_storage_bucket.this```

Terraform could otherwise interpret this as an old resource being destroyed and a new one being created.

A moved block tells Terraform that the resource has only changed its address, allowing the existing infrastructure to remain intact.

This was an important practical lesson: Terraform tracks resources by their addresses in state, so refactoring configuration requires preserving that relationship explicitly.

### Infrastructure Design Decisions
The project intentionally avoids unnecessary cloud infrastructure complexity.

Security and governance are addressed where they directly affect the data platform, while more advanced infrastructure such as custom VPC architecture, customer-managed encryption keys and complex organization-wide policies are outside the scope of this project.

The goal is to demonstrate appropriate infrastructure engineering without over-engineering a portfolio-scale analytics platform.

### Key Takeaways
The main Terraform concepts applied in this project were:

- Infrastructure as Code and declarative configuration

- Terraform providers and resources

- init, validate, plan and apply

- Terraform state and remote state

- State bootstrapping and GCS backend configuration

- Resource references and implicit dependencies

- Data sources

- Variables and locals

- Computed values

- for_each

- Terraform modules

- Resource addresses and moved blocks

- Version-controlled Terraform configuration