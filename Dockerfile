FROM quay.io/wakaba/docker-perl-app-base

ADD Makefile /app/
ADD bin/ /app/bin/
ADD local/cvsrepo/ /app/local/cvsrepo/
ADD config/ /app/config/

RUN cd /app && \
    git init && \
    apt-get update && apt-get install -y rcs && \
    make deps-server PMBP_OPTIONS=--execute-system-package-installer && \
    echo '#!/bin/bash' > /server && \
    echo 'exec /app/bin/server' >> /server && \
    chmod u+x /server && \
    rm -fr /app/.git /app/deps /app/t /app/t_deps && \
    rm -rf /var/lib/apt/lists/*

CMD ["/server"]
