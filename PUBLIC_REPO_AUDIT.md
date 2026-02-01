# OverPass — Public Repo Security & PII Audit

This document summarizes what was checked before making the repository public and what was changed to avoid exposing credentials or personal information.

---

## View-only (no one can change the repo)

- **GitHub:** A public repo is view-only by default. Only people you add as **Collaborators** (with write access) can push. To keep it view-only for everyone: make the repo **Public** and do **not** add any collaborators.
- No extra settings are required for “view only”; just avoid granting write access.

---

## What was checked

| Category | Result |
|----------|--------|
| API keys / passwords / tokens | **None found** in code or docs |
| `.env` or secret config files | **None** (and `.env` would be in `.gitignore` if added) |
| Bearer / Authorization headers | **None** |
| Private keys (PEM, etc.) | **None** |
| Hardcoded IP addresses | **None** (only numeric literals like `10.0` for time intervals) |
| Internal hostnames / machine names | **None** in code |
| Credentials in commit messages | **None** |

---

## Findings and fixes

### 1. Git commit history — author email and name

- **Finding:** Every commit in the history has:
  - **Author name:** `jadederea`
  - **Author email:** `michael@swansegar.com`
- **Risk:** Once the repo is public, anyone can see this email and name in `git log`.
- **Options:**
  - **Leave as-is** if you are fine with the repo being associated with that GitHub account and email.
  - **Rewrite history** to use a generic or GitHub noreply email (e.g. `username@users.noreply.github.com`). This rewrites commit hashes and requires a force-push; do this only if the repo is not yet shared or if all collaborators are aware.

If you want to rewrite history, use **before** making the repo public (or right after, with care):

```bash
# Install git-filter-repo: pip install git-filter-repo
git filter-repo --commit-callback '
  commit.author_email = b"username@users.noreply.github.com"
  commit.author_name = b"Your Public Name"
  commit.committer_email = b"username@users.noreply.github.com"
  commit.committer_name = b"Your Public Name"
'
```

Then push with `git push --force`. Get your noreply address from GitHub: Profile → Settings → Emails → “Keep my email addresses private.”

---

### 2. Personal paths (macOS username)

- **Finding:** These files contained your macOS username in paths:
  - `README.md`: `cd /Users/mswansegar/OverPass`
  - `ICON_CREATION_INSTRUCTIONS.md`: `cd /Users/mswansegar/OverPass`
  - `BUILD_ISSUES.md`: `/Users/mswansegar/Library/Developer/Xcode/DerivedData/OverPass-...`
- **Fix applied:** Paths were genericized to `~/OverPass` or `$HOME/OverPass` and “your project directory” / “your DerivedData path” so they don’t reveal your username.

---

### 3. Apple Development Team ID

- **Finding:** `OverPass.xcodeproj/project.pbxproj` contained `DEVELOPMENT_TEAM = ZV6N68B355` for the OverPass target (your Apple Developer Team ID).
- **Risk:** Low (Team IDs are not secret), but some prefer not to expose them in public repos.
- **Fix applied:** Those two occurrences were set to `DEVELOPMENT_TEAM = ""` so that:
  - The repo is safe to clone without exposing your team ID.
  - Anyone who opens the project in Xcode will need to select their own team (or you can document “Set your Development Team in Xcode” in README or BUILD_ISSUES).

---

### 4. GitHub username in documentation

- **Finding:** `AI_HANDOFF_DOCUMENTATION.md` and `PROJECT_CONTEXT.md` reference:
  - `https://github.com/jadederea/OverPass`
  - `https://github.com/jadederea/KeyRelay`
- **Note:** Making the repo public under the same account will already associate it with “jadederea.” Leaving these URLs as-is is normal; they point to the real repos. No change was required unless you want to genericize to “OWNER/OverPass” for a template.

---

## Summary

- **Credentials / secrets:** None found; no code or config changes needed for those.
- **Personal paths:** Updated in README, ICON_CREATION_INSTRUCTIONS, and BUILD_ISSUES.
- **Team ID:** Blanked in `project.pbxproj` for public clone.
- **Commit history:** Still contains your author name and email; optional to rewrite with the script above if you want to hide them before going public.

After applying the fixes in this repo and (optionally) rewriting history, you can make the repo public and keep it view-only by not adding collaborators.
