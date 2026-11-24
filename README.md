[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/opencode-manager-1?utm_medium=integration&utm_source=button&utm_campaign=opencode-manager)

# OpenCode Manager on Railway

One-click Railway template for [OpenCode Manager](https://github.com/chriswritescode-dev/opencode-manager) (MIT), a self-hosted command center for the [OpenCode](https://opencode.ai) coding agent: sessions, git, diffs, terminal and scheduled agent jobs in one web app.

**Version:** OpenCode Manager **1.1.0** with OpenCode 2.1.2 bundled, from the official image
`ghcr.io/chriswritescode-dev/opencode-manager:1.1.0@sha256:aef6f397944af41f2f48be4492bf1dc432a9bc23abf77f0a8e7395cf43383495` (pinned by tag and digest in the [`Dockerfile`](Dockerfile)).

## What it deploys

| Service | What it does |
|---|---|
| **OpenCode Manager** | Web UI and API on port 5003 (Railway domain, health check `/api/health`). Runs the OpenCode server inside the container on a loopback port. One volume at `/data` holds the SQLite database (`/data/app`), cloned repos, OpenCode settings, provider keys and sessions (`/data/workspace`). |

No database service is needed: the app uses SQLite on the volume.

## Variables

| Variable | Default | Notes |
|---|---|---|
| `ADMIN_EMAIL` | `admin@example.com` | Admin login name. The account is created on first boot and sign-up is disabled. |
| `ADMIN_PASSWORD` | generated (`secret(24)`) | Admin password. Read it from the service's **Variables** tab. |
| `AUTH_SECRET` | generated (`secret(48)`) | Signs login sessions. |
| `PORT` | `5003` | Port the app listens on. |
| `LLM_API_KEY` | empty, optional | An OpenAI-compatible API key. When set, a provider called "railway" is added and becomes the default model. Never written to disk. |
| `LLM_BASE_URL` | `https://api.openai.com/v1`, optional | Base URL of that provider (OpenRouter: `https://openrouter.ai/api/v1`). |
| `LLM_MODEL` | `gpt-4o-mini`, optional | Model name at that provider. |

You can also skip the `LLM_*` variables and add any provider (OpenAI, Anthropic, OpenRouter, Gemini and more) in the app under **Settings → Providers** after signing in.

The wrapper refuses to start without `ADMIN_EMAIL`, an `ADMIN_PASSWORD` of 8+ characters and `AUTH_SECRET`, so the app is never left open for the first visitor to register. Trusted origin, passkey origin and secure cookies are derived from Railway's public domain.

**Change the admin password:** set a new `ADMIN_PASSWORD` and `ADMIN_PASSWORD_RESET=true`, redeploy once, then delete `ADMIN_PASSWORD_RESET`.

## After deploying

1. Open the Railway URL and sign in with `ADMIN_EMAIL` / `ADMIN_PASSWORD`.
2. Add an LLM provider key under Settings (unless you set `LLM_API_KEY`).
3. Clone a repository (Repos → Add) and start a session. For private repos, add a GitHub token or SSH key in Settings.

## Resources

Tested at Railway's 0.5 GB / 1 vCPU limit: about 260 MB of anonymous memory and a 340 MB peak after cloning a repo and running an agent prompt. Big repositories, many parallel sessions or long agent runs work better with 1 GB or more. A crash exits non-zero, so Railway's `ON_FAILURE` restart policy brings the service back.

## Not included

- **Agent sandbox (microsandbox):** needs `/dev/kvm`, which Railway doesn't offer. Agents run directly in the container, and the app shows the sandbox as unavailable.
- **Preview gateway (port 5004):** not exposed. To preview dev servers, add a second Railway domain on port 5004 and set `PREVIEW_PUBLIC_URL` to it.
- **OAuth logins and push notifications:** optional; see the [environment docs](https://opencodemanager.app/docs/configuration/environment) (`GITHUB_CLIENT_ID`, `VAPID_*`, …).

## Updates

The template builds from this repo. When a new OpenCode Manager release is pinned on `main`, Railway shows everyone who deployed the template an "update available" notice, and they choose when to apply it. Read [`CHANGELOG.md`](CHANGELOG.md) first: breaking changes are listed at the top of each entry. Your data stays on the volume across updates.

## Licence

The wrapper files in this repo are MIT. OpenCode Manager is MIT, © Chris Scott.
