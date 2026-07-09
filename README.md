# coolify-devbox

A persistent cloud dev box you SSH into. It runs on your own [Coolify](https://coolify.io)
server and keeps **Claude Code** + your toolchain (node, pnpm, git, tmux, ripgrep, gh) always
on, in a durable home volume. Work from any machine; long-running agent tasks keep running
when your laptop sleeps.

```
ssh devbox        # lands you straight in a tmux session
claude            # already installed & authenticated
```

## Why

**Replaces developing on your laptop.**
- ➕ Sessions persist — close the lid, switch machines, come back to the same running tmux + agent.
- ➕ Consistent env on real server CPU/bandwidth; a sandbox away from your main machine.
- ➕ Reachable from anything with SSH (second laptop, iPad).
- ➖ Costs a server; some network latency; secrets live on the box; no local GUI apps.

**Vs. Codespaces / Gitpod.**
- ➕ You own it — no per-hour billing, runs on infra you already pay for, sessions *truly* persist.
- ➖ You maintain it, and there's no polished web IDE out of the box (you bring your own editor).

## How you use it

- **Connect:** `ssh devbox` → drops into tmux `main` (auto-reattaches next time).
- **Edit files** (pick one):
  - **VS Code / Cursor Remote-SSH** → connect to host `devbox`, open a folder. Full editor, the
    files stay on the box. *Recommended.*
  - Ask `claude` to make the edit.
  - Terminal editors are installed (`micro` for a friendly one, plus `vim`/`nano`).
- **Preview a dev server instantly:** run it in the box, then from your machine
  `ssh -L 3000:localhost:3000 devbox` and open <http://localhost:3000>. Hot-reload, no deploy.
- **Rotate SSH access:** edit the `AUTHORIZED_KEYS` env var in Coolify → restart. One key per line.

## What's in here

| File | Role |
|---|---|
| `Dockerfile` | `node:22` + openssh + Claude Code, pnpm, git, tmux, gh, micro. User `dev`, key-only SSH. |
| `entrypoint.sh` | Injects your public key at runtime; persists SSH **host keys** on the volume (redeploys don't trip host-key warnings). |
| `docker-compose.yml` | Publishes `2222:22`, mounts the `devhome` volume, healthchecks sshd. |

Durable state lives only in the `devhome` volume (`/home/dev`) or in git — the image is
disposable. The volume survives redeploys; it does **not** survive a worker-node swap (after
which you re-auth `claude`/`gh` and re-clone).

## Setup

Fastest path: **[let your AI set it up](#let-my-ai-set-it-up)**. Or do it by hand:

1. Put these files in a **private** repo and push.
2. In Coolify, create an app from it on your server — build pack **Docker Compose**, branch `main`,
   using a **deploy key** (not a webhook, so a push never auto-redeploys and kills your sessions).
3. Add a runtime env var `AUTHORIZED_KEYS` = your SSH public key. Deploy.
4. Make sure TCP **2222** is open to the box (cloud firewall), add a `Host devbox` block to
   `~/.ssh/config` (`Port 2222`, `User dev`, your `IdentityFile`), and `ssh devbox`.
5. First login: run `claude` (OAuth), set `git config`, `gh auth login`.

## Let my AI set it up

Paste this into Claude Code (or any coding agent) on your machine. Fill in the two blanks first.

```text
Set up a personal cloud "devbox" on my Coolify server that I SSH into and that runs Claude Code.
Use the container files from https://github.com/floo-one/coolify-devbox (Dockerfile,
entrypoint.sh, docker-compose.yml) AS-IS — don't rewrite them.

I'll give you:
- My Coolify URL and API token. Treat the token as a secret: never echo it, never write it to a
  file, never commit it. Read it from an env var when you call the API.
- Which Coolify server to deploy on (ask me if there's more than one; the target is a worker, not
  the manager/localhost).
- My SSH PUBLIC key to authorize (default ~/.ssh/id_ed25519.pub; generate a dedicated one if I say so).

Do this, verifying each step before moving on:
1. Create a new PRIVATE GitHub repo "devbox" containing those three files; push to main.
2. Create a Coolify application from that repo on my chosen server: build pack = Docker Compose,
   branch main. Use a DEPLOY KEY as the source (not a GitHub App / webhook) so a git push never
   auto-redeploys and kills my live tmux sessions.
3. Set a RUNTIME env var AUTHORIZED_KEYS = my SSH public key. Note: Coolify may create a duplicate
   empty copy of a compose-referenced var — delete the extra so exactly one remains with my key.
4. Trigger a deploy and poll until the app is healthy.
5. Confirm TCP 2222 on the server is reachable from my machine (tell me the exact firewall rule if
   it isn't — don't touch my firewall yourself). Append a `Host devbox` block to my ~/.ssh/config
   (HostName <server ip>, Port 2222, User dev, IdentityFile <my key>, IdentitiesOnly yes), then
   verify: ssh devbox 'whoami && node --version && claude --version'.

Hard rules: key-only SSH (no passwords), never mount the Docker socket, never enable
--dangerously-skip-permissions. All durable state must live in the /home/dev volume or in git.
After it's up, I'll finish the one-time interactive setup myself: run `claude` for OAuth, set my
git identity, and `gh auth login`.
```

## License

MIT — see [LICENSE](LICENSE).
