# ----------------
# Build stage
# ----------------
FROM python:3.12 AS builder
WORKDIR /app

ENV VENV_PATH=/app/.venv

# create virtual environment
RUN python -m venv ${VENV_PATH}
ENV PATH="${VENV_PATH}/bin:$PATH"

RUN python -m pip install --upgrade pip setuptools wheel uv


# Copy only pyproject.toml
COPY pyproject.toml ./

RUN uv pip compile pyproject.toml -o requirements.txt \
 && uv pip install -r requirements.txt

COPY tests ./tests

 # ----------------
# Final stage
# ----------------
FROM python:3.12-slim
WORKDIR /app
ENV VENV_PATH=/app/.venv
ENV PATH="$VENV_PATH/bin:$PATH"
ENV PYTHONPATH=/app

# Copy venv & tests from builder (exact paths)
COPY --from=builder /app/.venv /app/.venv
COPY --from=builder /app/tests ./tests

COPY cc_simple_server ./cc_simple_server



RUN useradd -m -u 10001 appuser && chown -R appuser:appuser /app
USER appuser
EXPOSE 8000
CMD ["uvicorn", "cc_simple_server.server:app", "--host", "0.0.0.0", "--port", "8000"]
