import requests
from datetime import datetime, timedelta

from airflow.sdk import DAG, task, BaseHook, BaseOperator
from airflow.exceptions import AirflowException
from beejanride_airbyte_trigger import AirbyteJobTrigger

AIRBYTE_CONNECTION_ID = "bf914c75-8e82-4029-897f-42e631e784dc"
AIRBYTE_API_URL = "https://api.airbyte.com"

class AirbyteWaitOperator(BaseOperator):
    # This allows the operator to accept the XCom output from the trigger task
    template_fields = ("job_id",)

    def __init__(self, *, job_id, airbyte_connection_id, **kwargs):
        super().__init__(**kwargs)
        self.job_id = job_id
        self.airbyte_connection_id = airbyte_connection_id

    def execute(self, context):
        self.defer(
            trigger=AirbyteJobTrigger(
                connection_id=self.airbyte_connection_id,
                job_id=str(self.job_id), 
                poll_interval=30,
            ),
            method_name="execute_complete",
        )

    def execute_complete(self, context, event=None):
        if not event:
            raise AirflowException("Airbyte trigger returned no event.")
        status = event.get("status")
        if status != "succeeded":
            raise AirflowException(f"Airbyte job {self.job_id} ended with status: {status}")
        self.log.info("Airbyte job %s completed successfully.", self.job_id)
        return self.job_id

with DAG(
    dag_id="beejanride_elt",
    start_date=datetime(2026, 1, 1),
    schedule="0 6 * * *",
    catchup=False,
    max_active_runs=1,
    default_args={
        "retries": 2,
        "retry_delay": timedelta(minutes=5),
        "execution_timeout": timedelta(minutes=30),
    },
    tags=["beejanride", "airbyte", "elt"],
) as dag:

    @task
    def trigger_airbyte_sync():
        connection = BaseHook.get_connection("airbyte_cloud")

        token_response = requests.post(
            f"{AIRBYTE_API_URL}/v1/applications/token",
            data={ 
                "client_id": connection.login,
                "client_secret": connection.password,
                "grant_type": "client_credentials", 
            },
            timeout=30,
        )
        token_response.raise_for_status()
        access_token = token_response.json()["access_token"]

        response = requests.post(
            f"{AIRBYTE_API_URL}/v1/jobs",
            headers={
                "Authorization": f"Bearer {access_token}",
                "Content-Type": "application/json",
            },
            json={
                "connectionId": AIRBYTE_CONNECTION_ID,
                "jobType": "sync",
            },
            timeout=30,
        )
        response.raise_for_status()
        job_id = response.json()["jobId"]
        
        print(f"Airbyte sync started. Job ID: {job_id}")
        return str(job_id)

    trigger_sync = trigger_airbyte_sync()

    wait_for_sync = AirbyteWaitOperator(
        task_id="wait_for_airbyte_sync",
        job_id=trigger_sync,
        airbyte_connection_id="airbyte_cloud",
    )

    trigger_sync >> wait_for_sync
