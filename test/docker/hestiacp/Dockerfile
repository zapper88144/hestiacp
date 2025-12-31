FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
ENV HESTIA="/usr/local/hestia"

# Basic tooling
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    ca-certificates \
    wget \
    curl \
    gnupg \
    git \
    sudo \
    lsb-release \
    apt-transport-https \
    locales \
    cron \
    dialog \
    procps \
    iproute2 \
    iputils-ping \
    software-properties-common \
    net-tools \
 && rm -rf /var/lib/apt/lists/*

# Ensure hostname resolution for demo host
RUN echo "127.0.0.1 demo.hestiacp.com" >> /etc/hosts || true

# Copy repo into image
COPY . /opt/hestiacp
WORKDIR /opt/hestiacp

# Make installers executable
RUN chmod +x ./install/hst-install-ubuntu.sh || true

# Ensure bash is default shell and create a minimal /etc/profile.d/hestia.sh required by tests
RUN mkdir -p /etc/profile.d && echo 'export HESTIA="/usr/local/hestia"' > /etc/profile.d/hestia.sh

# Install bats (testing tool) - try apt then fallback to clone
RUN apt-get update && apt-get install -y bats || ( \
    git clone https://github.com/bats-core/bats-core.git /tmp/bats-core && \
    /tmp/bats-core/install.sh /usr/local && rm -rf /tmp/bats-core ); \
    rm -rf /var/lib/apt/lists/*

# Run the Hestia installer non-interactively to create a usable test environment
# --force to overwrite anything, --interactive no to avoid prompts
# Admin user = admin / Password123, email admin@example.com, hostname demo.hestiacp.com
RUN /bin/bash -lc "bash ./install/hst-install-ubuntu.sh --hostname demo.hestiacp.com --email admin@example.com --username admin --password Password123 --with-debs /tmp/hestiacp-src/debs --interactive no --force" || true

# Provide test helper env file expected by the bats tests
RUN cat > /tmp/hestia-test-env.sh <<'EOF'
user=test-5285
user2=test-5286
userbk=testbk-5285
userpass1=test-5285
userpass2=t3st-p4ssw0rd
HESTIA=/usr/local/hestia
domain=test-5285.hestiacp.com
domainuk=test-5285.hestiacp.com.uk
rootdomain=testhestiacp.com
subdomain=cdn.testhestiacp.com
database=test-5285_database
dbuser=test-5285_dbuser
EOF

# Provide wildcard helper used by wildcard tests
RUN cat > /tmp/wildcard.sh <<'EOF'
user=test-5285
user2=test-5286
domain=test-5285.hestiacp.com
ip=127.0.0.1
EOF

# Install PHP CLI and Composer so we can add PHP dependencies
RUN apt-get update && apt-get install -y --no-install-recommends php-cli php-zip unzip php-xml php-mbstring composer && rm -rf /var/lib/apt/lists/*

# Provide a php binary path expected by Hestia (/usr/local/hestia/php/bin/php)
RUN mkdir -p /usr/local/hestia/php/bin && ln -s /usr/bin/php /usr/local/hestia/php/bin/php || true

# Run v-add-sys-dependencies to install PHPMailer and other composer deps
RUN /usr/local/hestia/bin/v-add-sys-dependencies || true

# Entry: run the test suite
ENTRYPOINT ["/usr/bin/bats"]
CMD ["/opt/hestiacp/test"]
