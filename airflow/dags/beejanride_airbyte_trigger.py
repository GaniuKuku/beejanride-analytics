import asyncio
import requests

from airflow.sdk import BaseHook
from airflow.triggers.base import BaseTrigger, TriggerEvent


class AirbyteJobTrigger(BaseTrigger):

    def __init__(self, connection_id, job_id, poll_interval=30):
        super().__init__()
        self.connection_id = connection_id
        self.job_id = job_id
        self.poll_interval = poll_interval

    def serialize(self):
        return (
            "beejanride_airbyte_trigger.AirbyteJobTrigger",
            {
                "connection_id": self.connection_id,
                "job_id": self.job_id,
                "poll_interval": self.poll_interval,
            },
        )

    async def run(self):
        connection = BaseHook.get_connection(self.connection_id)

        while True:
            try:
                token_response = await asyncio.to_thread(
                    requests.post,
                    "https://api.airbyte.com/v1/applications/token",
                    json={
                        "client_id": connection.login,
                        "client_secret": connection.password,
                        "grant-type": "client_credentials",
                    },
                    timeout=30,
                )

                token_response.raise_for_status()
                access_token = token_response.json()["access_token"]

                job_response = await asyncio.to_thread(
                    requests.get,
                    f"https://api.airbyte.com/v1/jobs/{self.job_id}",
                    headers={
                        "Authorization": f"Bearer {access_token}",
                    },
                    timeout=30,
                )

                job_response.raise_for_status()
                job = job_response.json()
                status = job.get("status")

                self.log.info(
                    "Airbyte job %s status: %s",
                    self.job_id,
                    status,
                )

                if status == "succeeded":
                    yield TriggerEvent(
                        {
                            "status": "succeeded",
                            "job_id": self.job_id,
                        }
                    )
                    return

                if status in {"failed", "cancelled", "incomplete"}:
                    yield TriggerEvent(
                        {
                            "status": status,
                            "job_id": self.job_id,
                        }
                    )
                    return

            except Exception as exc:
                self.log.warning(
                    "Error checking Airbyte job %s: %s",
                    self.job_id,
                    exc,
                )

            await asyncio.sleep(self.poll_interval)
