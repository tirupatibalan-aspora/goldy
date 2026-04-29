# Quick Setup Guide

Get the Claude Code Review bot running in 5 minutes.

## Prerequisites

- Repository with `.github/workflows/` directory
- Admin/maintainer access to repository settings
- Anthropic API key (from https://console.anthropic.com/keys)

## Step 1: Add Anthropic API Key

**In both app-ios and app-android repos:**

1. Open your repository on GitHub
2. Go to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Fill in:
   - **Name**: `ANTHROPIC_API_KEY`
   - **Secret**: Paste your Anthropic API key
5. Click **Add secret**

Repeat for both repositories.

## Step 2: Copy Files

Copy the entire action to your repository:

```bash
# From this repo
cp -r .github/workflows/claude-review.yml YOUR_REPO/.github/workflows/
cp -r .github/actions/claude-review/ YOUR_REPO/.github/actions/
```

Or manually:

1. Create `.github/workflows/claude-review.yml` with the workflow from this repo
2. Create `.github/actions/claude-review/` directory with:
   - `action.yml`
   - `index.js`
   - `package.json`
   - `prompts/ios-review-prompt.md`
   - `prompts/android-review-prompt.md`

## Step 3: Test

Create a test PR with:
- A force unwrap (iOS): `let x = dict["key"]!`
- A Double for money (Android): `val price: Double = 250.5`

Push and watch the bot review it. You should see feedback within 1 minute.

## Step 4: Make it Required (Optional)

To block merging without bot approval:

1. Go to **Settings** → **Branches** → **Branch protection rules**
2. Add rule for `main` or `develop`
3. Check **Require status checks to pass before merging**
4. Add **Claude Code Review** to required checks
5. Click **Save**

## Step 5: Customize (Optional)

Edit review standards:

- **iOS**: `.github/actions/claude-review/prompts/ios-review-prompt.md`
- **Android**: `.github/actions/claude-review/prompts/android-review-prompt.md`

Add your own criteria, examples, or severity levels.

## Verify Installation

In your repo, check:
- ✅ `.github/workflows/claude-review.yml` exists
- ✅ `.github/actions/claude-review/` directory exists with all files
- ✅ `ANTHROPIC_API_KEY` secret is set in Settings → Secrets
- ✅ `.github/actions/claude-review/package.json` has dependencies listed

## Troubleshooting

### "Action failed: API key is invalid"
- Verify API key in Secrets is correct
- Check Anthropic console that key has access

### "Diff file not found"
- Ensure workflow has `fetch-depth: 0` in checkout step

### "Platform detection wrong"
- Manually set platform in workflow YAML: `platform: ios`

### "No reviews posted"
- Check GitHub Actions logs for errors
- Verify GitHub token permissions

## Cost Check

Reviews cost ~$0.02 each with Sonnet 4. For 100 PRs/month: ~$2 cost.

See README.md for detailed cost breakdown.

## Next Steps

1. Create a test PR to verify it works
2. Read `README.md` for full documentation
3. Customize review standards as needed
4. Share with team!

---

Questions? Check the main README.md or Reviewer A's/Reviewer B's review standards documents.
