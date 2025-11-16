import psycopg2
from psycopg2 import pool
import boto3
import json
import os

class DatabaseConnection:
    def __init__(self):
        self.connection_pool = None
        self._initialize_pool()

    def _get_db_credentials(self):
        """Fetch RDS credentials from Secrets Manager"""
        session = boto3.session.Session()
        client = session.client('secretsmanager', region_name='us-east-1')

        secret_name = "linguallearn-rds-credentials-dev"
        response = client.get_secret_value(SecretId=secret_name)
        secret = json.loads(response['SecretString'])

        return secret

    def _initialize_pool(self):
        """Initialize connection pool"""
        creds = self._get_db_credentials()

        self.connection_pool = psycopg2.pool.SimpleConnectionPool(
            1, 20,
            user=creds['username'],
            password=creds['password'],
            host=creds['host'],
            port=creds['port'],
            database=creds['dbname']
        )

    def get_connection(self):
        """Get a connection from the pool"""
        return self.connection_pool.getconn()

    def return_connection(self, conn):
        """Return connection to pool"""
        self.connection_pool.putconn(conn)

db = DatabaseConnection()
