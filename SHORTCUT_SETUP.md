# iPhone meeting-counter shortcut

`meeting_count.txt` is the value displayed by the site. Run
`scripts/increment-meeting-count.ps1` over SSH from an iPhone Shortcut; it
increments the value, creates a Git commit, and pushes it to `origin`.

## One-time computer setup

1. Ensure the computer is reachable from the iPhone. Tailscale is the simplest
   option when they are not on the same Wi-Fi network.
2. Enable the Windows **OpenSSH Server** and start its `sshd` service. Allow
   its port through Windows Firewall.
3. Confirm that your SSH user can run Git and already has GitHub push access.
   From another machine, this command should succeed:

   ```powershell
   ssh sampl@YOUR-COMPUTER "git -C 'C:\Users\sampl\Desktop\S.A.I.A' status"
   ```

   SSH key authentication is recommended. The script intentionally stops if
   the repository has uncommitted changes, rather than risking an unattended
   commit of unrelated files.

## Shortcut setup

Create a shortcut with one action: **Run Script over SSH**.

- **Host:** your computer's local IP or Tailscale hostname/IP
- **User:** `sampl` (or your Windows account)
- **Authentication:** your SSH key
- **Script:**

  ```powershell
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\Users\sampl\Desktop\S.A.I.A\scripts\increment-meeting-count.ps1"
  ```

Turn on **Show When Run** while testing so the shortcut displays the new
counter or any Git/connection error. Once confirmed, it can be disabled.

## Test locally without pushing

This changes only the local file, so reset it afterwards if desired:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\increment-meeting-count.ps1 -NoPush
git restore meeting_count.txt
```
