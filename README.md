

# Linux & PostgreSQL User/Database Setup Script

This Bash script automates the creation of a new Linux user, a corresponding PostgreSQL role, and a dedicated PostgreSQL database. It generates a secure random password for both the Linux user and the PostgreSQL role, assigns ownership, and grants necessary privileges.

## Table of Contents

*   [Features](#features)
*   [Prerequisites](#prerequisites)
*   [How it Works](#how-it-works)
*   [Configuration](#configuration)
*   [Usage](#usage)
*   [Important Security Notes](#important-security-notes)
*   [Post-Setup Steps](#post-setup-steps)
*   [Troubleshooting](#troubleshooting)

## Features

*   **Automated Setup:** Creates a Linux user, PostgreSQL role, and PostgreSQL database with a single command.
*   **Secure Password Generation:** Generates a 16-character alphanumeric password for both the Linux user and PostgreSQL role.
*   **Idempotent:** Safely re-run the script multiple times; it will check if users, roles, and databases already exist before attempting to create them.
*   **Privilege Management:**
    *   Adds the new Linux user to the `sudo` group.
    *   Grants `LOGIN` privilege to the PostgreSQL role.
    *   Sets the new role as the owner of the new database.
    *   Grants `ALL PRIVILEGES` on the database to the new role.
*   **Clear Output:** Provides step-by-step progress and instructions upon completion.

## Prerequisites

Before running this script, ensure you have:

*   A Linux system (e.g., Ubuntu, Debian, CentOS).
*   **PostgreSQL installed and running** on the system.
*   `sudo` privileges for the user executing the script.
*   Standard command-line tools (`adduser`, `chpasswd`, `psql`, `id`, `grep`, `head`, `tr`) which are usually available by default.

## How it Works

The script performs the following steps:

1.  **Configuration:** Defines the Linux username, PostgreSQL role name, and PostgreSQL database name.
2.  **Password Generation:** Generates a strong, random password.
3.  **Root Check:** Ensures the script is run with `sudo` or as root.
4.  **Linux User Creation:**
    *   Checks if the Linux user already exists.
    *   If not, it creates the user without a password prompt and immediately sets the generated password.
    *   Adds the user to the `sudo` group.
5.  **PostgreSQL Role Creation:**
    *   Checks if the PostgreSQL role already exists.
    *   If not, it creates a new PostgreSQL role with `LOGIN` privileges and the generated password.
6.  **PostgreSQL Database Creation:**
    *   Checks if the PostgreSQL database already exists.
    *   If not, it creates a new database and sets its owner to the newly created PostgreSQL role.
7.  **Grant Privileges:** Explicitly grants `ALL PRIVILEGES` on the new database to the new PostgreSQL role.
8.  **Completion Message:** Displays the generated password and instructions for using the new user/role/database, along with recommendations for changing passwords.

## Configuration

You can easily customize the names for the Linux user, PostgreSQL role, and database by modifying the following variables at the top of the script:

```bash
# --- Configuration ---
LINUX_USER="studio"   # Desired Linux username
PG_ROLE="studio"      # Desired PostgreSQL role name
PG_DB="studio"        # Desired PostgreSQL database name
```

**Note:** If you change these after running the script once, re-running the script will create *new* users/roles/databases with the new names, as the script is idempotent for existing entities.

## Usage

1.  **Save the script:**
    Save the provided script content to a file, for example, `setup_env.sh`.

2.  **Make it executable:**
    ```bash
    chmod +x setup_env.sh
    ```

3.  **Run the script with sudo:**
    ```bash
    sudo ./setup_env.sh
    ```

## Important Security Notes

*   **Password Display:** The script explicitly displays the generated password on the console. While convenient for immediate use, this is **NOT recommended for highly sensitive production environments** where passwords should be managed through secure secrets management systems (e.g., Vault, KMS).
*   **Change Passwords Immediately:** For any environment, it is **CRITICAL** to change both the Linux user and PostgreSQL role passwords immediately after setup. The generated password serves as a temporary initial credential.
*   **Sudo Access for New User:** The script adds the new Linux user to the `sudo` group. If this is not desired, remove the line `adduser "$LINUX_USER" sudo > /dev/null` from the script.

## Post-Setup Steps

Once the script completes, you will see a summary. Here's how to proceed:

1.  **Store the Generated Password Securely:** Copy the displayed password and store it in a secure password manager or equivalent.

2.  **Change Linux User Password:**
    ```bash
    sudo passwd studio # Replace 'studio' with your LINUX_USER
    ```
    Follow the prompts to set a new, strong password.

3.  **Change PostgreSQL Role Password:**
    ```bash
    sudo -u postgres psql -c "ALTER USER studio WITH PASSWORD 'your_new_secure_pg_password';" # Replace 'studio' and 'your_new_secure_pg_password'
    ```
    **Important:** Remember to use single quotes around the new password and escape any special characters if necessary, or use `DO $$ BEGIN ALTER USER ... END $$;` syntax for more complex passwords.

4.  **Switch to the new Linux user:**
    ```bash
    su - studio # Use the new password you set in step 2
    ```

5.  **Connect to the PostgreSQL database as the new user:**
    Once logged in as the new Linux user, or from another user with `psql` access:
    ```bash
    psql -U studio -d studio # Use the new PostgreSQL password you set in step 3
    ```

## Troubleshooting

*   **"This script must be run with sudo or as root."**: You forgot to use `sudo` when running the script.
*   **"psql: command not found"**: PostgreSQL client tools are not installed or not in your system's PATH. Ensure PostgreSQL is fully installed.
*   **"Peer authentication failed" for PostgreSQL**: This usually means the `pg_hba.conf` file is configured to use peer authentication for local connections by default. The script runs `psql` commands as the `postgres` user, which typically bypasses this. If you encounter issues, verify your `pg_hba.conf` and ensure the `postgres` user can administer the database.
*   **Script exits unexpectedly**: The `set -euo pipefail` directive ensures the script exits on any error. Carefully read the error message for clues.

