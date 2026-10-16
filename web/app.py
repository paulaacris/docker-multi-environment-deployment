import os
import json
import time

import mysql.connector
import redis
from flask import Flask, jsonify, request, send_file

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

CACHE_KEY = "favoritos"
CACHE_TTL = 60  # sec

@app.route("/")
def home():
    return send_file("index.html")

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

def check_db():
    """check if the database is connected"""
    try:
        conn = get_db()
        ok = conn.is_connected()
        conn.close()
        return "Connected" if ok else "Disconnected"
    except Exception:
        return "Disconnected"


def check_cache():
    """check if the cache is not disconnected"""
    cache = get_cache()
    if cache is None:
        return "Not applicable (dev)"
    try:
        return "Connected" if cache.ping() else "Disconnected"
    except Exception:
        return "Disconnected"


@app.route("/status")
def status():
    db_status = check_db()
    cache_status = check_cache()
    return jsonify(
        {
            "environment": APP_ENV,
            "database": db_status,
            "cache": cache_status,
        }
    )

@app.route("/favoritos", methods=["GET"])
def listar_favoritos():
    cache = get_cache()

    # with cache 
    if cache:
        try:
            cached = cache.get(CACHE_KEY)
            if cached:
                return jsonify({
                    "origen": "cache (Redis)", 
                    "items": json.loads(cached)
                })
        except Exception:
            pass  # if redis fails, try with db 

    # with db
    try:
        conn = get_db()
        cur = conn.cursor(dictionary=True) # data with format 
        cur.execute("SELECT id, nombre FROM favoritos ORDER BY id DESC")
        result = cur.fetchall()
        cur.close()
        conn.close()
    except Exception:
        return jsonify({"error": "Base de datos no disponible"}), 503

    # save in caché for the next time
    if cache:
        try:
            cache.set(CACHE_KEY, json.dumps(result), ex=CACHE_TTL)
        except Exception:
            pass

    return jsonify({
        "origen": "base de datos (MySQL)", 
        "items": result
    })

@app.route("/favoritos", methods=["POST"])
def crear_favorito():
    nombre = ((request.get_json(silent=True) or {}).get("nombre") or "").strip()
    if not 1 <= len(nombre) <= 50:
        return jsonify({"error": "Nombre inválido (1-50 caracteres)"}), 400
    if not nombre:
        return jsonify({"error":"El nombre es obligatorio"}), 400

    try:
        conn = get_db()
        cur = conn.cursor()
        cur.execute("INSERT INTO favoritos (nombre) VALUES (%s)", (nombre,))
        conn.commit()
        cur.close()
        conn.close()
    except Exception:
        return jsonify({"error": "Base de datos no disponible"}), 503

    # invalidate the cache, the data has changed
    cache = get_cache()
    if cache:
        try:
            cache.delete(CACHE_KEY)
        except Exception:
            pass

    return jsonify({"ok": True}), 201

def init_db(retries=10):
    """create the favorites table when the web starts"""
    for _ in range(retries):
        try:
            conn = get_db()
            cur = conn.cursor()
            cur.execute(
                "CREATE TABLE IF NOT EXISTS favoritos ("
                "id INT AUTO_INCREMENT PRIMARY KEY,"
                "nombre VARCHAR(50) NOT NULL,"
                "creado TIMESTAMP DEFAULT CURRENT_TIMESTAMP)"
            )
            conn.commit()
            cur.close()
            conn.close()
            print("Tabla 'favoritos' verificada/creada con éxito.")
            return
        except Exception:
            # if MySQL is still starting up, wait 2s and rety
            time.sleep(2)

# execute the function upon startup
init_db()

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)