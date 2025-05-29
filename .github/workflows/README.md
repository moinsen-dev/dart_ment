# GitHub Actions Workflows

## Release Workflow

The `release.yaml` workflow automatically creates GitHub releases when version tags are pushed.

### Triggering a Release

The workflow is triggered when you push a tag matching the version pattern:
- `v[0-9]+.[0-9]+.[0-9]+` (e.g., v0.1.0, v1.2.3)
- `[0-9]+.[0-9]+.[0-9]+` (e.g., 0.1.0, 1.2.3)

To create a release:
```bash
# Tag the release
git tag v0.1.0
git push origin v0.1.0

# Or without the 'v' prefix
git tag 0.1.0
git push origin 0.1.0
```

### What the Release Workflow Does

1. **Runs tests** to ensure code quality
2. **Extracts version** from the tag
3. **Extracts changelog** for the specific version from CHANGELOG.md
4. **Creates GitHub release** with:
   - Release name: `dart_ment v[version]`
   - Release notes from CHANGELOG.md
   - Auto-generated release notes from GitHub
5. **Publishes to pub.dev** (if credentials are configured)

### Required Secrets

To enable publishing to pub.dev, you need to configure these secrets in your repository settings:

1. **PUB_CREDENTIALS**: The contents of your pub.dev credentials JSON file
   - Get this by running `dart pub login` locally and copying the credentials file
   - Usually located at `~/.config/dart/pub-credentials.json`

2. **PUB_TOKEN**: Your pub.dev authentication token (optional, for additional authentication)

### Setting Up Secrets

1. Go to your repository settings
2. Navigate to Secrets and variables > Actions
3. Click "New repository secret"
4. Add the required secrets

Note: If these secrets are not configured, the release will still be created on GitHub, but the pub.dev publishing step will fail.