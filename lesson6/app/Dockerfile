FROM python:3.13-alpine
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

RUN apk update && apk add bash openjdk21-jdk

RUN apk add build-base python3-dev

WORKDIR /app

ENV VIRTUAL_ENV="/opt/venv"

ENV UV_PROJECT_ENVIRONMENT=$VIRTUAL_ENV
ENV UV_LINK_MODE=copy

RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --locked --no-install-project

ADD . /app

RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --locked

CMD ["/opt/venv/bin/python", "-m", "jupyter", "lab", "--ip", "0.0.0.0", "--allow-root"]

EXPOSE 8888