from datetime import datetime, timedelta
import subprocess

from airflow.sdk import DAG, task, BaseHook, BaseOperator, TaskGroup
from airflow.exceptions import AirflowException
from airflow.providers.airbyte.operators.airbyte import AirbyteTriggerSyncOperator
from airflow.providers.smtp.notifications.smtp import send_smtp_notification
from config import AIRBYTE_CONNECTION_ID, DBT_PROJECT_DIR, DBT_EXECUTABLE


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
        "on_failure_callback": [
            send_smtp_notification(
                from_email="ganiukuku@gmail.com",
                to="ganiukuku@gmail.com",
                subject="[BeejanRide Airflow] DAG Failed",
                html_content="""
                <h3>BeejanRide ELT DAG Failed</h3>
                <p>DAG: {{ dag.dag_id }}</p>
                <p>Run: {{ run_id }}</p>
                <p>Failed task: {{ ti.task_id }}</p>
                """,
                smtp_conn_id="smtp_gmail",
            )
        ],
    },
    tags=["beejanride", "airbyte", "dbt", "elt"],
) as dag:

    with TaskGroup(group_id="airbyte_ingestion") as airbyte_ingestion:
        airbyte_sync = AirbyteTriggerSyncOperator(
            task_id="airbyte_sync",
            airbyte_conn_id="airbyte_cloud",
            connection_id=AIRBYTE_CONNECTION_ID,
            asynchronous=False,
            deferrable=True,
            timeout=3600,
        )


    with TaskGroup(group_id="dbt_transformation") as dbt_transformation:

        @task
        def dbt_run():
            result = subprocess.run(
                [DBT_EXECUTABLE, "run"],
                cwd=DBT_PROJECT_DIR,
                capture_output=True,
                text=True,
            )
            print(result.stdout)
            if result.returncode != 0:
                print(result.stderr)
                raise AirflowException("dbt run failed.")
            print("dbt run completed successfully.")

        @task
        def dbt_test():
            result = subprocess.run(
                [DBT_EXECUTABLE, "test"],
                cwd=DBT_PROJECT_DIR,
                capture_output=True,
                text=True,
            )
            print(result.stdout)
            if result.returncode != 0:
                print(result.stderr)
                raise AirflowException("dbt test failed.")
            print("dbt test completed successfully.")

        run_dbt = dbt_run()
        test_dbt = dbt_test()

        run_dbt >> test_dbt


    airbyte_ingestion >> dbt_transformation
