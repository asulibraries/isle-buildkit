#!/usr/bin/with-contenv bash
set -e

# Transform the given string to uppercase.
function uppercase {
    local string="${1}"; shift
    echo $(tr '[:lower:]' '[:upper:]' <<< ${string})
}

# Get variable value for given site.
function matomo_site_env {
    local site="$(uppercase ${1})"; shift
    local suffix="$(uppercase ${1})"; shift
    if [ "${site}" = "DEFAULT" ]; then
        var="MATOMO_DEFAULT_${suffix}"
    else
        var="MATOMO_SITE_${site}_${suffix}"
    fi
    echo "${!var}"
}

# Creates database / user if not already exists. This needs to be seperated as
# we cannot use 'User Defined' variables to select database/tables.
function create_database {
    cat <<- EOF | create-database.sh
-- Create matomo database in mariadb or mysql. 
CREATE DATABASE IF NOT EXISTS ${MATOMO_DB_NAME};

-- Create matomo_user and grant rights.
CREATE USER IF NOT EXISTS ${MATOMO_DB_USERNAME}@'%' IDENTIFIED BY "${MATOMO_DB_PASSWORD}";
GRANT ALL PRIVILEGES ON ${MATOMO_DB_NAME}.* to ${MATOMO_DB_USERNAME}@'%';
FLUSH PRIVILEGES;
EOF
}

# Matomo only works with MySQL.
# https://github.com/matomo-org/matomo/issues/500
function update_user {
    cat <<- EOF | execute-sql-file.sh
USE ${MATOMO_DB_NAME};

-- Update db user password.
SET PASSWORD FOR '${MATOMO_DB_USER}'@'%' = PASSWORD('${MATOMO_DB_PASSWORD}');

-- Update site name, host, timezone (idsite is hardcoded for the default site).
UPDATE matomo_site set
    site = 'DEFAULT',
    name = '${MATOMO_DEFAULT_NAME}',
    main_url = '${MATOMO_DEFAULT_HOST}',
    timezone = '${MATOMO_DEFAULT_TIMEZONE}'
    WHERE idsite = 1;

-- Update admin user password, email.
UPDATE matomo_user set
    password = '${MATOMO_USER_PASS}', 
    email = '${MATOMO_USER_EMAIL}'
    WHERE login = '${MATOMO_USER_NAME}';
EOF
}

function update_site {
    local site="$(uppercase ${1})"; shift
    local name=$(matomo_site_env "${site}" "NAME")
    local host=$(matomo_site_env "${site}" "HOST")
    local timezone=$(matomo_site_env "${site}" "TIMEZONE")
    local user=$(matomo_site_env "${site}" "USER_NAME")
    local password=$(matomo_site_env "${site}" "USER_PASS")
    local email=$(matomo_site_env "${site}" "USER_EMAIL")
    local token=$(echo "${user}-$(date +%s)" | md5sum | cut -f1 -d' ') # token must be an unique MD5.
    cat <<- EOF | execute-sql-file.sh
USE ${MATOMO_DB_NAME};

SET @site = '${site}',
    @name = '${name}',
    @host = '${host}',
    @timezone = '${timezone}',
    @user = '${user}',
    @password = '${password}',
    @email = '${email}',
    @token = '${token}';

-- Update or create row if 'site' already exists.
-- Default values come from 'create-matomo-database.sql.tmpl'.
INSERT INTO matomo_site (name, main_url, ts_created, ecommerce, sitesearch, sitesearch_keyword_parameters, sitesearch_category_parameters, timezone, currency, exclude_unknown_urls, excluded_ips, excluded_parameters, excluded_user_agents, excluded_referrers, \`group\`, type, keep_url_fragment, creator_login)
VALUES (@name, @host, NOW(), 0, 1, '', '', @timezone, 'USD', 0, '', '', '', '', '', 'website', 0, 'anonymous')
ON DUPLICATE KEY UPDATE
    name = @name,
    main_url = @host,
    timezone = @timezone;

-- Update or create row if 'user' already exists.
INSERT INTO matomo_user (login, password, email, twofactor_secret, superuser_access, date_registered, ts_password_modified)
VALUES (@user, @password, @email, '', 0, NOW(), NOW())
ON DUPLICATE KEY UPDATE
    password = @password,
    email = @email,
    ts_password_modified = NOW();

-- Update or create row for the admin user to 'access' the site.
INSERT INTO matomo_access (login, idsite, access)
SELECT @user, idsite, 'admin'
FROM matomo_site
WHERE name = @name
ON DUPLICATE KEY UPDATE
    idsite = matomo_site.idsite;
EOF
}

function update_database {
    echo "Updating Database: ${MATOMO_DB_NAME}"
    for site in ${MATOMO_SITES}; do
        echo "Adding Site: ${site}"
        update_site "${site}"
    done
}

function database_exists {
    cat <<- EOF | execute-sql-file.sh
USE '${MATOMO_DB_NAME}';
EOF
}

# https://dev.mysql.com/doc/refman/8.0/en/user-variables.html
# Note that:
# "User variables are intended to provide data values. They cannot be used directly in an SQL statement as an identifier or as part of an identifier..."
function set_variables {
   cat <<- EOF
USE ${MATOMO_DB_NAME};

set @SITE_URL = "${MATOMO_FIRST_SITE_URL}";
set @SITE_NAME = "${MATOMO_FIRST_SITE_NAME}";
set @SITE_TIMEZONE = "${MATOMO_DEFAULT_TIMEZONE}";
set @USER_EMAIL = "${MATOMO_FIRST_USER_EMAIL}";
set @USER_NAME = "${MATOMO_FIRST_USER_NAME}";
set @USER_PASS = "${MATOMO_FIRST_USER_PASSWORD}";
EOF
}

function created_database {
    if ! database_exists; then
        echo "Creating database: ${MATOMO_DB_NAME}"
        create_database
        execute-sql-file.sh <(cat <(set_variables) /etc/matomo/create-matomo-database.sql)
    else
        echo "Database: ${MATOMO_DB_NAME} already exists"
    fi
}

function main {
    created_database
    update_database
    chown -R nginx: "/var/www/matomo/tmp"
}
main
