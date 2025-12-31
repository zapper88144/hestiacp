#!/bin/bash
#
# HestiaCP Bats Test Runner for Docker
# Handles environment setup for running Bats tests in non-systemd Docker containers
#

CONTAINER_IMAGE="${1:-hestiacp-test:phpcbffixes}"
TEST_FILTER="${2:-}"

echo "=========================================="
echo "HestiaCP Bats Test Runner"
echo "=========================================="
echo "Image: $CONTAINER_IMAGE"
echo "Filter: ${TEST_FILTER:-all tests}"
echo ""

# Build the complete command to run in the container
# shellcheck disable=SC2016,SC2026,SC1073,SC1072,SC1009
DOCKER_CMD='
# Start all services manually (no systemd)
echo "=== Starting services ==="
for svc in nginx apache2 php8.3-fpm php8.4-fpm mariadb exim4 dovecot; do
    service "$svc" start >/dev/null 2>&1 || true
done

echo "=== Setting up HestiaCP environment ==="
# Source HestiaCP config to get proper paths
source /usr/local/hestia/conf/hestia.conf 2>/dev/null || true

echo "=== Creating test IP directly in data directory ==="
mkdir -p /usr/local/hestia/data/ips
cat > /usr/local/hestia/data/ips/198.18.0.125 << 'EOF'
OWNER=admin
STATUS=shared
INTERFACE=eth0
NETMASK=255.255.255.255
SHARED=yes
SUSPENDED=no
TIME=$(date +%s)
DATE=$(date)
EOF

echo "=== Creating missing log directories ==="
mkdir -p /var/log/nginx
mkdir -p /var/log/apache2/domains
mkdir -p /var/log/php-fpm
mkdir -p /var/log/exim4
mkdir -p /var/log/dovecot

echo "=== Creating test user ==="
/usr/local/hestia/bin/v-add-user test-5285 test-5285 test-5285@hestiacp.com default "Super Test" 2>/dev/null || true

echo "=== Registered users ==="
/usr/local/hestia/bin/v-list-users 2>/dev/null | head -10 || true

echo ""
echo "=========================================="
echo "Running Bats Tests from /opt/hestiacp/test"
echo "=========================================="
echo ""

cd /opt/hestiacp/test
'

# Add test filtering if specified
if [ -n "$TEST_FILTER" ]; then
	DOCKER_CMD="${DOCKER_CMD}bats --filter '$TEST_FILTER' test.bats"
else
	DOCKER_CMD="${DOCKER_CMD}bats test.bats"
fi

# Execute the container with all setup
sudo docker run --rm -it \
	--entrypoint /bin/bash \
	"$CONTAINER_IMAGE" \
	-c "$DOCKER_CMD"

EXIT_CODE=$?

echo ""
echo "=========================================="
echo "Test run complete (exit code: $EXIT_CODE)"
echo "=========================================="

exit $EXIT_CODE
