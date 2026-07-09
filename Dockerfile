FROM node:22-bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
    openssh-server git ripgrep fzf tmux curl wget sudo ca-certificates \
    build-essential python3 unzip less vim nano micro ncurses-term \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir /run/sshd

RUN useradd -m -s /bin/bash dev \
    && echo "dev ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/dev

RUN npm i -g @anthropic-ai/claude-code pnpm

# Caddy — fronts the public dev-server URL with basic auth (see entrypoint.sh).
# Single static binary; arch-matched so it works on amd64 and arm64 build hosts.
RUN curl -fsSL "https://caddyserver.com/api/download?os=linux&arch=$(dpkg --print-architecture)" \
       -o /usr/local/bin/caddy \
    && chmod +x /usr/local/bin/caddy

# GitHub CLI (official apt repo) — used for `gh auth login` inside the box
RUN mkdir -p -m 755 /etc/apt/keyrings \
    && wget -nv -O- https://cli.github.com/packages/githubcli-archive-keyring.gpg \
       | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
    && chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
       > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends gh \
    && rm -rf /var/lib/apt/lists/*

RUN sed -i \
    -e 's/#PasswordAuthentication yes/PasswordAuthentication no/' \
    -e 's/#PermitRootLogin.*/PermitRootLogin no/' \
    /etc/ssh/sshd_config

COPY tmux.conf /etc/tmux.conf
COPY workstation /usr/local/bin/workstation
COPY profile-devbox.sh /etc/profile.d/99-devbox-tmux.sh
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh /usr/local/bin/workstation
EXPOSE 22 9009
ENTRYPOINT ["/entrypoint.sh"]
