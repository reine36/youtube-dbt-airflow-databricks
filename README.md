uv init
dbt init youtube

dbc-bddf67d8-1921.cloud.databricks.com
/sql/1.0/warehouses/507b1fceb5df2be8

pip install dbt-databricks

pip install apache-airflow apache-airflow-providers-amazon apache-airflow-providers-databricks

------
This project uses csv files from s3, ingested into bronze in databricks with autoloader. Performed transformation using DBT to give silver and gold tables. Orchestrated using Airflow local via docker.

-->if u want to use requirements.txt just use uv pip freeze > requirements.txt


FOR DOCUMENTATION JUST RUN THIS
Set-Location "C:\Users\reyva\Desktop\airflow_dbt_databrics_youtube\youtube"
dbt docs generate --profile youtube --no-partial-parse
dbt docs serve --profile youtube --port 8081