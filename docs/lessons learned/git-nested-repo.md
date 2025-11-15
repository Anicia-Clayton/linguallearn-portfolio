# Lessons Learned: Git Nested Repository and Merge Conflict Resolution

**Project:** LinguaLearn AI
**Date:** November 14, 2025
**Environment:** Windows with WSL, Git version control
**Status:** Resolved

---

## Executive Summary

Encountered a complex Git synchronization issue involving an accidental nested repository, diverged branches (4 local commits vs 17 remote commits), merge conflicts, and project restructuring. Resolution required diagnosing multiple interconnected Git issues and resolving conflicts while maintaining data integrity. Successfully resolved by removing nested repository, restructuring project folders, and carefully merging diverged histories.

---

## Challenge: Unable to Sync Local Repository with GitHub

### Initial Symptoms

Attempting to push local changes resulted in errors:
```
! [rejected]        main -> main (non-fast-forward)
error: failed to push some refs to 'https://github.com/.../linguallearn-portfolio.git'
hint: Updates were rejected because the tip of your current branch is behind
hint: its remote counterpart.
```

Attempting to pull remote changes resulted in:
```
error: The following untracked working tree files would be overwritten by merge:
        linguallearn-infrastructure/terraform/main.tf
        linguallearn-infrastructure/terraform/outputs.tf
        [... multiple terraform files ...]
Please move or remove them before you merge.
```

Standard Git operations (`git pull`, `git push`, `git stash`) were ineffective.

---

## Root Cause Analysis

### Issue 1: Accidental Nested Git Repository

**Discovery:**
```cmd
cd linguallearn-infrastructure\terraform
git status
```

Result: The `terraform/` folder had its own `.git` directory, creating a repository within a repository (submodule without proper configuration).

**Why this happened:**
- Ran `git init` in the terraform folder at some point
- Parent repo (root) couldn't properly track changes in the nested repo

### Issue 2: Diverged Branch History

Local repository had **4 commits** not on GitHub.
GitHub repository had **17 commits** not in local.

**Why this happened:**
- Made changes directly on GitHub (via web interface)
- Made different changes locally
- Both histories diverged from a common ancestor

### Issue 3: Git Not Tracking Files

Even after removing nested `.git`, running `git status` showed:
```
modified:   linguallearn-infrastructure/terraform (modified content)
```

But the individual files weren't listed as tracked or untracked.

**Why this happened:**
- Git still had the folder registered as a submodule reference
- The `.gitmodules` file or Git index had stale metadata

---

## Diagnostic Steps Taken

### Step 1: Identified Nested Repository

**Command:**
```cmd
cd linguallearn-infrastructure\terraform
git status
```

**Result:** Confirmed separate Git repository in subfolder

### Step 2: Checked Branch Divergence

**Commands:**
```cmd
git status
git log --oneline -5
```

**Result:**
```
Your branch and 'origin/main' have diverged,
and have 4 and 17 different commits each, respectively.
```

### Step 3: Attempted Standard Resolution

**Commands tried:**
```cmd
git stash          # Result: "No local changes to save"
git pull           # Result: "would be overwritten by merge"
git add .          # Result: Files not recognized
```

### Step 4: Investigated File Visibility

**Commands:**
```cmd
dir linguallearn-infrastructure\terraform\*.tf    # Files exist
git status                                         # Git doesn't see them
type .gitignore                                    # Not being ignored
```

---

## Solution Implementation

### Phase 1: Remove Nested Repository

**Remove Git tracking from nested folder:**
```cmd
cd linguallearn-infrastructure\terraform
rmdir /s /q .git
cd ..\..
```

**Outcome:** Removed nested Git repository, kept all files intact.

### Phase 2: Restructure Project (Bonus Improvement)

**Move terraform to root for cleaner structure:**
```cmd
move linguallearn-infrastructure\terraform .\terraform
rmdir linguallearn-infrastructure
```

**New structure:**
```
linguallearn-portfolio/
├── terraform/              ← Moved from nested location
│   ├── main.tf
│   ├── vpc.tf
│   ├── ec2.tf
│   └── ...
├── docs/
├── src/
└── README.md
```

### Phase 3: Stage Files for Commit

**Add terraform files to main repository:**
```cmd
git add terraform/
git commit -m "Restructure: move Terraform to root directory"
```

**Note:** Encountered line ending warnings (CRLF → LF) due to `.gitattributes` rules. This is expected and correct - Git automatically normalized line endings.

### Phase 4: Resolve Diverged Branches

**Attempt to merge remote changes:**
```cmd
git pull origin main --no-rebase
```

**Result:** Merge conflicts in multiple files:
```
CONFLICT (content): Merge conflict in README.md
CONFLICT (content): Merge conflict in src/App.jsx
CONFLICT (file/directory): directory in the way of linguallearn-infrastructure/terraform
```

### Phase 5: Resolve Merge Conflicts

**Handle deleted folder (old terraform location):**
```cmd
git rm -rf linguallearn-infrastructure/terraform
```

**Resolve README.md conflict (keep local version):**
```cmd
git checkout --ours README.md
git add README.md
```

**Resolve src/App.jsx conflict (keep remote version):**
```cmd
git checkout --theirs src/App.jsx
git add src/App.jsx
```

### Phase 6: Handle Submodule Metadata Issue

**Problem:** Git created `terraform~HEAD` folder and treated it as unresolved conflict.

**Error encountered:**
```
Unmerged paths:
  added by us:     linguallearn-infrastructure/terraform~HEAD
```

**Attempted solutions:**
```cmd
git rm -rf linguallearn-infrastructure/terraform~HEAD    # Partial success
git add linguallearn-infrastructure/terraform~HEAD       # Failed - submodule error
```

**Final solution - remove from Git index:**
```cmd
git rm --cached -r linguallearn-infrastructure/terraform~HEAD
```

This removed the stale submodule reference without attempting to process it as a repository.

### Phase 7: Complete Merge and Push

**Finalize merge:**
```cmd
git status    # Confirmed: "All conflicts fixed but you are still merging"
git commit -m "Merge remote changes: restructure terraform to root, resolve conflicts"
```

**Push to GitHub:**
```cmd
git push origin main
```

**Success:**
```
Enumerating objects: 52, done.
Counting objects: 100% (50/50), done.
Writing objects: 100% (38/38), 14.25 KiB | 1.29 MiB/s, done.
To https://github.com/.../linguallearn-portfolio.git
   5dea614..c1cdf9d  main -> main
```

---

## Key Takeaways

### 1. **Nested Repositories Are Sneaky**
Accidental nested Git repositories cause cascading issues. Always check for `.git` folders in subdirectories before assuming Git tracking problems.

**Prevention:**
```cmd
# Before initializing Git in any folder, check parent:
cd ..
git status    # If this shows a repo, don't init in subfolder
```

### 2. **Diverged Branches Require Careful Merging**
When local and remote have different commit histories, standard `git pull` may fail. Understanding merge strategies is critical.

**Key commands:**
- `git pull --no-rebase` - Creates merge commit (preserves both histories)
- `git checkout --ours` - Keep local version during conflict
- `git checkout --theirs` - Keep remote version during conflict

### 3. **Git Index Can Have Stale Metadata**
Even after removing `.git` folders, Git's index may retain submodule references. `git rm --cached` removes index entries without deleting files.

### 4. **Restructuring During Conflict Resolution**
Opportunity emerged to improve project structure during conflict resolution. Combined restructuring with merge resolution in single operation.

### 5. **"Fatal" Doesn't Always Mean Fatal**
Many "fatal" errors in Git are about file system operations (like folder deletion on Windows), not data loss. Understanding the difference between Git index operations and file system operations is crucial.

### 6. **Backup Before Complex Operations**
Created backup folder before attempting fixes:
```cmd
xcopy terraform terraform-backup\ /E /I /H
```

This provided safety net without interfering with Git operations.

---

## Commands Reference

### Diagnostic Commands
```cmd
# Check for nested repos
cd subfolder
git status

# View branch divergence
git log --oneline -5
git status

# Check file line endings
git ls-files --eol
```

### Resolution Commands
```cmd
# Remove nested Git repo (keeps files)
rmdir /s /q .git

# Force remove from Git tracking
git rm -rf folder/
git rm --cached -r folder/

# Resolve merge conflicts
git checkout --ours filename      # Keep local version
git checkout --theirs filename    # Keep remote version

# Complete merge
git add .
git commit -m "Merge message"
git push origin main
```

---

## Prevention Checklist

For future development:

- [ ] Verify no `.git` folders in subdirectories before committing
- [ ] Regularly sync with remote to prevent major divergence
- [ ] Make structural changes (like folder moves) in separate commits
- [ ] Test `git status` after major file operations
- [ ] Keep backups before complex Git operations
- [ ] Use `git pull` frequently to stay in sync with remote
- [ ] Avoid editing files directly on GitHub if working locally

---

## Time Investment

**Total time to resolve:** ~1.5-2 hours

**Breakdown:**
- Diagnosis: 30 minutes
- Attempted standard solutions: 20 minutes
- Research and custom solution: 40 minutes
- Conflict resolution: 30 minutes

**Value:** Deep understanding of Git internals, conflict resolution, and repository management. Skills directly applicable to team collaboration scenarios.

---

## Related Issues

- [Line Ending Warnings (TROUBLESHOOTING.md)](../TROUBLESHOOTING.md#line-ending-warnings-lf-vs-crlf)
- [SSM Connectivity Issues (Lessons Learned)](ssm-connectivity-troubleshooting.md)

---

## References

- [Git Submodules Documentation](https://git-scm.com/book/en/v2/Git-Tools-Submodules)
- [Git Merge Strategies](https://git-scm.com/docs/merge-strategies)
- [Resolving Merge Conflicts](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/addressing-merge-conflicts)
