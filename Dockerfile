FROM quay.io/wakaba/docker-perl-app-base

ADD Makefile /app/

RUN cd /app && \
    git init && \
    make deps PMBP_OPTIONS=--execute-system-package-installer && \
    echo '#!/bin/bash' > /server && \
    echo 'exec /app/bin/server' >> /server && \
    chmod u+x /server && \
    rm -fr /app/.git /app/deps /app/t /app/t_deps

CMD ["/server"]
