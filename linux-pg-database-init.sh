
#!/bin/bash
set -euo pipefail # Exit immediately if a command exits with a non-zero status,
                  # treat unset variables as an error, and fail if any command
                  # in a pipeline fails.

# --- Configuration ---
LINUX_USER="studio"
PG_ROLE="studio"
PG_DB="studio"

# Generate a strong random password for both Linux and PostgreSQL users
# In a real production script, use a more secure method to store/handle passwords.
# For demonstration, we generate and display it.
PASSWORD=$(head /dev/urandom | tr -dc A-Za-z0-9_ | head -c 16)

# --- Pre-checks ---
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run with sudo or as root."
   exit 1
fi

echo "--- Starting Setup for '$LINUX_USER' ---"
echo "Linux User: ${LINUX_USER}"
echo "PostgreSQL Role: ${PG_ROLE}"
echo "PostgreSQL Database: ${PG_DB}"
echo ""
echo "!!! IMPORTANT: The generated password is: ${PASSWORD} !!!"
echo "!!! Please store this securely and change it later.   !!!"
echo ""

# --- 1. Create Linux User ---
echo "1/4: Creating Linux user '${LINUX_USER}'..."
if id -u "$LINUX_USER" >/dev/null 2>&1; then
    echo "  Linux user '${LINUX_USER}' already exists. Skipping creation."
else
    # --disabled-password: Don't prompt for password during adduser
    # --gecos "": Don't prompt for full name/info
    adduser --disabled-password --gecos "" "$LINUX_USER" > /dev/null
    echo "${LINUX_USER}:${PASSWORD}" | chpasswd
    # Add user to sudo group (optional, remove if not needed)
    adduser "$LINUX_USER" sudo > /dev/null
    echo "  Linux user '${LINUX_USER}' created with home directory and added to 'sudo' group."
fi

# --- 2. Create PostgreSQL Role ---
echo ""
echo "2/4: Creating PostgreSQL role '${PG_ROLE}'..."
# Check if the role already exists
if sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='${PG_ROLE}'" | grep -q 1; then
    echo "  PostgreSQL role '${PG_ROLE}' already exists. Skipping creation."
else
    # Create the role with login privileges and the generated password
    sudo -u postgres psql -c "CREATE ROLE ${PG_ROLE} WITH LOGIN PASSWORD '${PASSWORD}';"
    echo "  PostgreSQL role '${PG_ROLE}' created."
fi

# --- 3. Create PostgreSQL Database ---
echo ""
echo "3/4: Creating PostgreSQL database '${PG_DB}'..."
# Check if the database already exists
if sudo -u postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname='${PG_DB}'" | grep -q 1; then
    echo "  PostgreSQL database '${PG_DB}' already exists. Skipping creation."
else
    # Create the database and set its owner to the new role
    sudo -u postgres psql -c "CREATE DATABASE ${PG_DB} OWNER ${PG_ROLE};"
    echo "  PostgreSQL database '${PG_DB}' created and owned by '${PG_ROLE}'."
fi

# --- 4. Grant all privileges on the database to the role ---
echo ""
echo "4/4: Granting all privileges on database '${PG_DB}' to role '${PG_ROLE}'..."
# Although ownership implies most privileges, explicitly granting ALL ensures full control.
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ${PG_DB} TO ${PG_ROLE};"
echo "  All privileges granted on database '${PG_DB}' to role '${PG_ROLE}'."

echo ""
echo "--- Setup Complete! ---"
echo "You can now:"
echo "1. Switch to the new Linux user:"
echo "   su - ${LINUX_USER}"
echo "   (Use password: ${PASSWORD})"
echo ""
echo "2. Connect to the PostgreSQL database as the new user:"
echo "   psql -U ${PG_ROLE} -d ${PG_DB}"
echo "   (Use password: ${PASSWORD})"
echo ""
echo "Remember to change the password for both Linux and PostgreSQL users for better security:"
echo "  Linux: passwd ${LINUX_USER}"
echo "  PostgreSQL: psql -U postgres -c \"ALTER USER ${PG_ROLE} WITH PASSWORD 'your_new_pg_password';\""


