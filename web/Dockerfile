FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# unprivileged user (security)
RUN useradd -r -u 1001 appuser
COPY --chown=appuser . .
USER appuser

EXPOSE 5000

HEALTHCHECK --interval=15s --timeout=3s --start-period=10s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/status', timeout=2)" || exit 1

CMD ["python", "app.py"]