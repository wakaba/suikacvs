FROM quay.io/wakaba/docker-perl-app-base

ADD .git/ /app/.git/
ADD .gitmodules /app/.gitmodules
ADD Makefile /app/
ADD bin/ /app/bin/
ADD local/cvsrepo/ /app/local/cvsrepo/
ADD config/ /app/config/

RUN cd /app && \
    apt-get update && apt-get install -y rcs python && \
    make deps-server PMBP_OPTIONS=--execute-system-package-installer && \
    echo '#!/bin/bash' > /server && \
    echo 'cd /app' >> /server && \
    echo 'exec ./plackup -s Twiggy -p 8080 bin/server.psgi' >> /server && \
    chmod u+x /server && \
    rm -fr /app/.git /app/deps /app/t /app/t_deps && \
    rm -rf /var/lib/apt/lists/*

CMD ["/server"]
