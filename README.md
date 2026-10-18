# Terminal Control for Home Assistant

A terminal on your Windows PC inside a Home Assistant dashboard, from anywhere: open the view and you are in a
PowerShell running [Claude Code](https://docs.claude.com/en/docs/claude-code/overview) (or any command you choose).
Companion to [VNC Control](https://github.com/mauriporte/ha-vnc-control) and
[ADB Control](https://github.com/mauriporte/ha-adb-control).

Built on [ttyd](https://github.com/tsl0922/ttyd) (a terminal over the web) behind an identity-aware proxy
(Cloudflare Access by default).

> **This gives a shell on your PC to whoever passes the proxy.** Read [Security](#security) before exposing it.

## How it works

```
HA dashboard iframe ──▶ https://terminal.example.com ──▶ Cloudflare Access (login, e.g. one-time code by email)
                                                        └─▶ tunnel ──▶ ttyd :7681 on the PC ──▶ PowerShell ──▶ claude
```

- **ttyd** serves the terminal. It runs with `--auth-header Cf-Access-Authenticated-User-Email`: requests without
  the identity header the proxy adds get `407`, so ttyd has no password of its own and you log in only once.
- **Cloudflare Access** in front: login once per browser, then the session (e.g. a month) lets the dashboard frame
  open directly. No bypass rule: the login is the only way in.
- **Windows Firewall** only lets your tunnel/proxy machine reach the port, so nobody else on the network can send a
  fake header.
- Each browser connection opens a new session (up to 3 at once). Leaving the page closes it.

## Install

On the Windows PC, in PowerShell:

```powershell
git clone https://github.com/mauriporte/ha-terminal-control; cd ha-terminal-control\windows
.\install.ps1 -Startup                       # ttyd + launcher, started now-or-at-logon; command: claude
# as administrator, with your tunnel/proxy machine's IP:
.\install.ps1 -FirewallOnly -TunnelHost <tunnel-host-ip>
wscript "$env:LOCALAPPDATA\terminal-control\terminal-control.vbs"   # start it without logging off
```

Options: `-Command "pwsh -NoLogo"` for another program, `-WorkingDirectory D:\work`, `-Port 7681`,
`-AuthHeader <name>` for another proxy's identity header.

## Cloudflare (tunnel + Access)

1. **Access application first** (Zero Trust → Access → Applications → Self-hosted) for `terminal.example.com`:
   - policy *Allow* with your own email (one-time PIN or your identity provider);
   - session duration as long as you are comfortable with (it is how long a device stays logged in);
   - cookie settings: **SameSite = None** (needed for the login to carry into the Home Assistant iframe),
     HTTP-only on.
2. **Tunnel public hostname** `terminal.example.com` → `http://<pc-ip>:7681`.
3. First time in each browser: open the URL in a tab and log in. From then on the dashboard frame opens directly.

An Access login page cannot be shown inside an iframe ("refused to connect"); that is why step 3 happens in a tab.

## Home Assistant

Add the view in [`examples/dashboard-view.yaml`](examples/dashboard-view.yaml) with your hostname (and optionally the
theme in [`examples/themes/`](examples/themes/terminal_control.yaml) for an edge-to-edge black frame).

## Security

- The terminal runs as your Windows user: anyone who gets through has your files and your Claude Code session.
- Keep the Access policy to your own identity, with no bypass rules or service tokens for this hostname.
- `--auth-header` trusts the header blindly. That is safe only because the firewall rule lets nothing but the tunnel
  machine connect. If other software on that machine could be compromised, add ttyd's own password instead
  (`-c user:password` in the launcher) and accept the second prompt.
- The session cookie is the "device key": log out of Access (or revoke sessions in Zero Trust) on a lost device.

## Claude Code notes

- **"Do you trust the files in this folder?"** appears the first time Claude Code starts in the working directory.
  Answer it once in a normal terminal in that folder (or in the web terminal); it is remembered.
- **"Transcript saving is off — inherited CLAUDE_CODE_CHILD_SESSION marker"**: ttyd was started from another Claude
  Code session and its variables were passed down. The launcher clears `CLAUDE*` variables before starting the
  command; starting ttyd at logon (Startup folder) avoids it as well.

## License

MIT
