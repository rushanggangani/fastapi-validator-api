FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1

WORKDIR /app

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY ./app ./app

RUN useradd -m python && chown -R python:python /app
USER python

CMD ["uvicorn","app.main:app","--host","0.0.0.0","--port","8000"]