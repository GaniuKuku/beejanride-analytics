import os
import sys

import pytest
from airflow.models import DagBag


# Ensure the DAG directory is available for imports
DAG_FOLDER = os.path.abspath(
    os.path.join(os.path.dirname(__file__), "../dags")
)

sys.path.insert(0, DAG_FOLDER)


@pytest.fixture()
def dagbag():
    """Load BeejanRide DAGs for testing."""
    return DagBag(
        dag_folder=DAG_FOLDER
    )


def test_dag_loaded(dagbag):
    """Verify the BeejanRide DAG loads without import errors."""

    dag = dagbag.get_dag(dag_id="beejanride_elt")

    assert dag is not None, "beejanride_elt DAG was not found."

    assert len(dagbag.import_errors) == 0, (
        f"DAG import errors: {dagbag.import_errors}"
    )


def test_dag_configuration(dagbag):
    """Verify important DAG configuration settings."""

    dag = dagbag.get_dag(dag_id="beejanride_elt")

    assert dag is not None

    # Prevent overlapping DAG runs
    assert dag.max_active_runs == 1

    # Historical runs should not execute automatically
    assert dag.catchup is False


def test_task_structure_and_dependencies(dagbag):
    """Verify all required tasks exist in the DAG."""

    dag = dagbag.get_dag(dag_id="beejanride_elt")

    assert dag is not None

    expected_tasks = {
        "airbyte_ingestion.trigger_airbyte_sync",
        "airbyte_ingestion.wait_for_airbyte_sync",
        "dbt_transformation.dbt_run",
        "dbt_transformation.dbt_test",
    }

    actual_task_ids = {
        task.task_id
        for task in dag.tasks
    }

    for expected_task in expected_tasks:
        assert expected_task in actual_task_ids, (
            f"Task {expected_task} is missing from the DAG."
        )


def test_task_dependencies(dagbag):
    """Verify the ELT execution order."""

    dag = dagbag.get_dag(dag_id="beejanride_elt")

    assert dag is not None

    trigger = dag.get_task(
        "airbyte_ingestion.trigger_airbyte_sync"
    )

    wait = dag.get_task(
        "airbyte_ingestion.wait_for_airbyte_sync"
    )

    dbt_run = dag.get_task(
        "dbt_transformation.dbt_run"
    )

    dbt_test = dag.get_task(
        "dbt_transformation.dbt_test"
    )

    # Airbyte trigger → Airbyte wait
    assert wait.task_id in {
        task.task_id
        for task in trigger.downstream_list
    }

    # Airbyte wait → dbt run
    assert dbt_run.task_id in {
        task.task_id
        for task in wait.downstream_list
    }

    # dbt run → dbt test
    assert dbt_test.task_id in {
        task.task_id
        for task in dbt_run.downstream_list
    }


def test_task_retries(dagbag):
    """Verify retry policy is configured for every task."""

    dag = dagbag.get_dag(dag_id="beejanride_elt")

    assert dag is not None

    for task in dag.tasks:
        assert task.retries == 2, (
            f"Task {task.task_id} should have exactly 2 retries, "
            f"but has {task.retries}."
        )


def test_task_execution_timeout(dagbag):
    """Verify tasks have an execution timeout."""

    dag = dagbag.get_dag(dag_id="beejanride_elt")

    assert dag is not None

    for task in dag.tasks:
        assert task.execution_timeout is not None, (
            f"Task {task.task_id} has no execution timeout."
        )


def test_dag_has_expected_task_count(dagbag):
    """Verify the DAG contains exactly the expected tasks."""

    dag = dagbag.get_dag(dag_id="beejanride_elt")

    assert dag is not None

    assert len(dag.tasks) == 4, (
        f"Expected 4 tasks, found {len(dag.tasks)}."
    )
