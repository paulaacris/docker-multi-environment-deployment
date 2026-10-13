import os
import mysql.connector
import redis
from flask import Flask

app = Flask(__name__)

APP_ENV = os.environ.get("APP_ENV")

DB_CONFIG = {
    "host": os.environ.get("DB_HOST"),
    "user": os.environ.get("MYSQL_USER"),
    "password": os.environ.get("MYSQL_PASSWORD"),
    "database": os.environ.get("MYSQL_DATABASE"),
    "connection_timeout": 2,
}

REDIS_HOST = os.environ.get("REDIS_HOST")  # only in prod
REDIS_PASSWORD = os.environ.get("REDIS_PASSWORD")


def get_db():
    """get configuration data and connect to MySQL"""
    return mysql.connector.connect(**DB_CONFIG)

def get_cache():
    """Returns Redis client, None if there is no cache (dev env)"""
    if not REDIS_HOST:
        return None
    
    return redis.Redis(
        host=REDIS_HOST,
        port=6379,
        password=REDIS_PASSWORD,
        decode_responses=True,
        socket_timeout=2,
        socket_connect_timeout=2,
    )

