# OpenCode Manager for Railway: the official upstream image, pinned by release tag and digest.
# Upstream: https://github.com/chriswritescode-dev/opencode-manager (MIT)
FROM ghcr.io/chriswritescode-dev/opencode-manager:1.1.0@sha256:aef6f397944af41f2f48be4492bf1dc432a9bc23abf77f0a8e7395cf43383495

# Railway settings baked in, so the template needs only a few variables.
# One Railway volume is mounted at /data: the workspace (repos, OpenCode config,
# provider keys, sessions) and the SQLite database both live under it.
ENV NODE_ENV=production \
    HOST=0.0.0.0 \
    PORT=5003 \
    WORKSPACE_PATH=/data/workspace \
    DATABASE_PATH=/data/app/opencode.db \
    AUTH_SECURE_COOKIES=true \
    OPENCODE_DISABLE_MODELS_FETCH=1 \
    DEBUG=false

# Keep git inside Railway's small memory limits (index-pack and repack threads).
COPY gitconfig /etc/gitconfig
COPY railway-start.sh /usr/local/bin/railway-start.sh
COPY seed-llm.ts /opt/railway/seed-llm.ts
RUN chmod 755 /usr/local/bin/railway-start.sh && chmod 644 /etc/gitconfig

EXPOSE 5003
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/railway-start.sh"]
CMD ["bun", "backend/src/index.ts"]
