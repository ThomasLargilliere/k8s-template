FROM python:3.14-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

RUN groupadd --system --gid 1001 app \
    && useradd --system --uid 1001 --gid 1001 --no-create-home app \
    && chown -R app:app /app

USER app

EXPOSE 8000
