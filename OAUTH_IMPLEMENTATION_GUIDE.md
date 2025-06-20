# OAuth Implementation Guide for Airbyte

## Changes Made

### 1. Updated values.yaml
- Added OAuth configuration section with provider settings
- Added OAuth environment variables to server configuration
- Maintained fallback admin user for emergency access

### 2. Updated GitHub Workflow
- Added OAuth secrets creation in deployment pipeline
- Configured `airbyte-oauth-secrets` Kubernetes secret

## Required Steps to Complete Implementation

### 1. Choose OAuth Provider and Configure Application

#### For Google OAuth:
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing project
3. Enable Google+ API
4. Go to "Credentials" → "Create Credentials" → "OAuth 2.0 Client IDs"
5. Configure OAuth consent screen
6. Add authorized redirect URIs:
   - `https://airbyte.thg-reporting.com/auth/callback`
7. Note down Client ID and Client Secret

#### For GitHub OAuth:
1. Go to GitHub Settings → Developer settings → OAuth Apps
2. Create new OAuth App with:
   - Homepage URL: `https://airbyte.thg-reporting.com`
   - Authorization callback URL: `https://airbyte.thg-reporting.com/auth/callback`
3. Note down Client ID and Client Secret

#### For Azure AD:
1. Go to Azure Portal → Azure Active Directory → App registrations
2. Create new registration
3. Configure redirect URI: `https://airbyte.thg-reporting.com/auth/callback`
4. Generate client secret
5. Note down Application (client) ID and client secret

### 2. Configure GitHub Secrets

Add these secrets to your GitHub repository (Settings → Secrets and variables → Actions):

```
OAUTH_CLIENT_ID=your_oauth_client_id
OAUTH_CLIENT_SECRET=your_oauth_client_secret
```

### 3. Update values.yaml for Specific Provider

#### For Google:
```yaml
global:
  auth:
    oauth:
      provider: "google"
      authorizationUrl: "https://accounts.google.com/o/oauth2/auth"
      tokenUrl: "https://oauth2.googleapis.com/token"
      userInfoUrl: "https://www.googleapis.com/oauth2/v2/userinfo"
```

#### For GitHub:
```yaml
global:
  auth:
    oauth:
      provider: "github"
      authorizationUrl: "https://github.com/login/oauth/authorize"
      tokenUrl: "https://github.com/login/oauth/access_token"
      userInfoUrl: "https://api.github.com/user"
```

#### For Azure AD:
```yaml
global:
  auth:
    oauth:
      provider: "azure"
      authorizationUrl: "https://login.microsoftonline.com/{tenant}/oauth2/v2.0/authorize"
      tokenUrl: "https://login.microsoftonline.com/{tenant}/oauth2/v2.0/token"
      userInfoUrl: "https://graph.microsoft.com/v1.0/me"
```

### 4. Additional Airbyte Configuration

**Important Note**: Airbyte OSS (Open Source) may have limited built-in OAuth support. You might need to:

1. **Check Airbyte Documentation**: Verify current OAuth support in your Airbyte version (0.50.0)
2. **Consider Airbyte Cloud/Enterprise**: Full OAuth support is typically available in paid versions
3. **Implement Custom OAuth Proxy**: Use a reverse proxy (like OAuth2-Proxy) in front of Airbyte

### 5. OAuth Proxy Implementation (Recommended Approach)

If Airbyte OSS doesn't have native OAuth support, implement OAuth2-Proxy:

```yaml
# Add to values.yaml
oauth2-proxy:
  enabled: true
  image:
    repository: quay.io/oauth2-proxy/oauth2-proxy
    tag: v7.4.0
  config:
    clientID: ""  # From secret
    clientSecret: ""  # From secret
    cookieSecret: ""  # Generate random 32-char string
    configFile: |-
      email_domains = ["thehutgroup.com"]  # Restrict to your domain
      upstreams = ["http://airbyte-webapp:80"]
      cookie_domains = [".thg-reporting.com"]
      whitelist_domains = [".thg-reporting.com"]
```

### 6. Update Ingress Configuration

```yaml
# In values.yaml, update webapp ingress
webapp:
  ingress:
    annotations:
      # Add OAuth2-Proxy annotations if using proxy approach
      nginx.ingress.kubernetes.io/auth-url: "https://airbyte.thg-reporting.com/oauth2/auth"
      nginx.ingress.kubernetes.io/auth-signin: "https://airbyte.thg-reporting.com/oauth2/start"
```

### 7. Deployment Steps

1. **Update GitHub Secrets**: Add OAuth credentials
2. **Update values.yaml**: Choose and configure your OAuth provider
3. **Deploy**: Run your GitHub workflow with the 'deploy' action
4. **Test**: Access `https://airbyte.thg-reporting.com` and verify OAuth flow

### 8. Verification Checklist

- [ ] OAuth provider application configured
- [ ] GitHub secrets added
- [ ] values.yaml updated with provider-specific URLs
- [ ] Deployment successful
- [ ] OAuth login flow works
- [ ] Users can access Airbyte after OAuth authentication
- [ ] Emergency admin access still works (if needed)

## Troubleshooting

### Common Issues:
1. **Redirect URI Mismatch**: Ensure OAuth app redirect URI exactly matches your domain
2. **Scope Issues**: Verify OAuth scopes include necessary permissions (email, profile)
3. **SSL/HTTPS**: OAuth requires HTTPS - ensure your ingress has valid TLS
4. **Network Policies**: Check if Kubernetes network policies allow OAuth traffic

### Testing OAuth Flow:
1. Clear browser cookies for your domain
2. Navigate to `https://airbyte.thg-reporting.com`
3. Should redirect to OAuth provider login
4. After authentication, should return to Airbyte dashboard

## Security Considerations

1. **Restrict Access**: Configure OAuth app to only allow users from your organization
2. **Session Management**: Configure appropriate session timeouts
3. **RBAC**: Map OAuth user attributes to Airbyte roles/permissions
4. **Audit Logging**: Enable OAuth authentication logging
5. **Backup Access**: Keep emergency admin credentials secure

## Alternative: Airbyte Enterprise

For full OAuth support without custom implementation, consider:
- Airbyte Cloud (SaaS)
- Airbyte Enterprise (self-hosted with OAuth support)

These provide native OAuth integration with multiple providers and advanced user management features.