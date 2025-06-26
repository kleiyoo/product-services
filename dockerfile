# Use the official Python base image
FROM python:3.12-slim-bullseye

# Install system dependencies, including the MS ODBC Driver
RUN apt-get update && apt-get install -y \
    curl \
    gnupg \
    apt-transport-https \
    ca-certificates \
    gcc \
    g++ \
    unixodbc \
    unixodbc-dev \
    libpq-dev \
    libsasl2-dev \
    libssl-dev \
    libffi-dev \
    libodbc1 \
    && curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
    && curl https://packages.microsoft.com/config/debian/11/prod.list > /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    && ACCEPT_EULA=Y apt-get install -y msodbcsql17 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# --- THIS IS THE FIX ---
# Copy the driver configuration file to tell unixODBC where to find the driver library.
COPY odbcinst.ini /etc/odbcinst.ini
# ----------------------

# Set up the application environment
WORKDIR /app

# Copy and install Python dependencies
COPY requirements.txt .
RUN pip install --upgrade pip
RUN pip install -r requirements.txt

# Copy the rest of the application code
COPY . .

# Expose the port your app will run on inside the container
EXPOSE 10000

# The command to run your app (This serves as a default for local dev)
# Render will use the command from its UI, which should match this.
CMD ["gunicorn", "-k", "uvicorn.workers.UvicornWorker", "main:app", "--bind", "0.0.0.0:10000"]