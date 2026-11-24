# Changelog

Breaking changes are listed first in each entry. Railway shows an update notice to everyone who deployed this template when `main` changes, so read the entry before you apply an update.

## 1.1.0-railway.1 (2026-11-24)

First release of the Railway template.

- OpenCode Manager 1.1.0 (OpenCode 2.1.2 bundled), image `ghcr.io/chriswritescode-dev/opencode-manager:1.1.0@sha256:aef6f397944af41f2f48be4492bf1dc432a9bc23abf77f0a8e7395cf43383495`.
- One volume at `/data` for the database (`/data/app`) and the workspace (`/data/workspace`).
- Admin account created on first boot from `ADMIN_EMAIL` / generated `ADMIN_PASSWORD`; the service refuses to start without them, so sign-up is never open.
- Trusted origin, passkey origin and secure cookies set from Railway's public domain.
- Optional `LLM_API_KEY` / `LLM_BASE_URL` / `LLM_MODEL` add an OpenAI-compatible provider.
- Live models.dev catalogue fetch off (`OPENCODE_DISABLE_MODELS_FETCH=1`), git pack threads capped, thread pools sized to the service's CPUs, and an unexpected clean exit turned into exit 1 so Railway restarts the service.
