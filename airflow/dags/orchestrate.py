from datetime import datetime, timedelta
from airflow import DAG
from airflow.providers.standard.operators.bash import BashOperator
from airflow.providers.databricks.operators.databricks import DatabricksRunNowOperator

default_args = {
	'owner': 'airflow',
	'depends_on_past': False,
	'email_on_failure': False,
	'retries': 1,
	'retry_delay': timedelta(minutes=5),
}

with DAG(
	'youtube_medallion_pipeline',
	default_args=default_args,
	description='Run Databricks PySpark Auto Loader then execute dbt Core models',
	schedule='@daily',
	start_date=datetime(2026, 1, 1),
	catchup=False,
) as dag:

	run_databricks_ingestion = DatabricksRunNowOperator(
		task_id='run_pyspark_autoloader',
		databricks_conn_id='databricks_default',
		json={
			"job_id": 860154554207330
		}
	)

	run_dbt = BashOperator(
		task_id='dbt_run_models',
		bash_command='cd /opt/airflow/youtube && dbt run --target dev',
	)

	test_dbt = BashOperator(
		task_id='dbt_test_models',
		bash_command='cd /opt/airflow/youtube && dbt test --target dev',
	)

	run_databricks_ingestion >> run_dbt >> test_dbt
