# OAuth and Multi-Project Configuration Guide

This document provides comprehensive instructions for configuring OAuth providers and enabling multi-project support in your self-hosted Supabase instance.

## Overview

Your Supabase self-hosted setup now includes:
- **OAuth Provider Support**: Google, GitHub, Microsoft/Azure, Facebook, Discord, Apple, and Spotify
- **Multi-Project Organization Support**: Create and manage multiple projects within organizations
- **No Stripe Dependencies**: Pure self-hosted solution without external billing integrations

## OAuth Provider Configuration

### Supported OAuth Providers

1. **Google OAuth**
2. **GitHub OAuth**
3. **Microsoft/Azure OAuth**
4. **Facebook OAuth**
5. **Discord OAuth**
6. **Apple OAuth**
7. **Spotify OAuth**

### Setting Up OAuth Providers

#### 1. Google OAuth

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Enable Google+ API
4. Create OAuth 2.0 credentials
5. Set authorized redirect URI: `http://localhost:8000/auth/v1/callback`
6. Update your `.env` file:

```bash
ENABLE_GOOGLE_OAUTH=true
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret
```

#### 2. GitHub OAuth

1. Go to GitHub Settings > Developer settings > OAuth Apps
2. Create a new OAuth App
3. Set Authorization callback URL: `http://localhost:8000/auth/v1/callback`
4. Update your `.env` file:

```bash
ENABLE_GITHUB_OAUTH=true
GITHUB_CLIENT_ID=your-github-client-id
GITHUB_CLIENT_SECRET=your-github-client-secret
```

#### 3. Microsoft/Azure OAuth

1. Go to [Azure App Registrations](https://portal.azure.com/#blade/Microsoft_AAD_RegisteredApps)
2. Create a new registration
3. Set redirect URI: `http://localhost:8000/auth/v1/callback`
4. Update your `.env` file:

```bash
ENABLE_AZURE_OAUTH=true
AZURE_CLIENT_ID=your-azure-client-id
AZURE_CLIENT_SECRET=your-azure-client-secret
AZURE_URL=https://login.microsoftonline.com/common
```

#### 4. Facebook OAuth

1. Go to [Facebook Developers](https://developers.facebook.com/)
2. Create a new app
3. Add Facebook Login product
4. Set Valid OAuth Redirect URIs: `http://localhost:8000/auth/v1/callback`
5. Update your `.env` file:

```bash
ENABLE_FACEBOOK_OAUTH=true
FACEBOOK_CLIENT_ID=your-facebook-app-id
FACEBOOK_CLIENT_SECRET=your-facebook-app-secret
```

#### 5. Discord OAuth

1. Go to [Discord Developer Portal](https://discord.com/developers/applications)
2. Create a new application
3. Go to OAuth2 section
4. Add redirect: `http://localhost:8000/auth/v1/callback`
5. Update your `.env` file:

```bash
ENABLE_DISCORD_OAUTH=true
DISCORD_CLIENT_ID=your-discord-client-id
DISCORD_CLIENT_SECRET=your-discord-client-secret
```

## Multi-Project Organization Setup

### Configuration

The following environment variables control multi-project support:

```bash
# Organization and project configuration
STUDIO_DEFAULT_ORGANIZATION=Default Organization
STUDIO_DEFAULT_PROJECT=Default Project
STUDIO_DEFAULT_ORG_SLUG=default-org-slug

# Enable multi-project features
ENABLE_ORGANIZATIONS=true
ENABLE_MULTI_PROJECT=true
DISABLE_PLATFORM_FEATURES=false

# Studio environment
STUDIO_ENVIRONMENT=local
NEXT_PUBLIC_ENVIRONMENT=local
NEXT_PUBLIC_IS_PLATFORM=false
NEXT_PUBLIC_LOCAL_MODE=true
```

### Creating New Projects

1. Access Supabase Studio at `http://localhost:3000`
2. Navigate to organization dashboard
3. Click "New Project"
4. Fill in project details:
   - Project name
   - Database password
   - Region (for production deployments)
5. Click "Create new project"

### Managing Organizations

- **Default Organization**: Automatically created as "Default Organization"
- **Organization Slug**: Used in URLs (`default-org-slug`)
- **Multiple Projects**: Each organization can contain multiple projects
- **Team Management**: Add team members to organizations

## Authentication Flow

### OAuth Flow Steps

1. User clicks OAuth provider button in Supabase Auth UI
2. Redirects to OAuth provider (Google, GitHub, etc.)
3. User authorizes application
4. Provider redirects back to: `http://localhost:8000/auth/v1/callback`
5. Supabase Auth processes the callback
6. User is authenticated and redirected to your application

### Integration in Your Application

#### JavaScript/TypeScript

```javascript
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(
  'http://localhost:8000',
  'your-anon-key'
)

// Sign in with OAuth provider
async function signInWithProvider(provider) {
  const { data, error } = await supabase.auth.signInWithOAuth({
    provider: provider, // 'google', 'github', 'azure', etc.
    options: {
      redirectTo: 'http://localhost:3000/auth/callback'
    }
  })
  
  if (error) {
    console.error('Error:', error.message)
  }
}

// Usage
signInWithProvider('google')
signInWithProvider('github')
```

#### React Example

```jsx
import { useSupabaseClient } from '@supabase/auth-helpers-react'

function AuthComponent() {
  const supabase = useSupabaseClient()

  const handleOAuthSignIn = async (provider) => {
    await supabase.auth.signInWithOAuth({
      provider,
      options: {
        redirectTo: `${window.location.origin}/auth/callback`
      }
    })
  }

  return (
    <div>
      <button onClick={() => handleOAuthSignIn('google')}>
        Sign in with Google
      </button>
      <button onClick={() => handleOAuthSignIn('github')}>
        Sign in with GitHub
      </button>
      <button onClick={() => handleOAuthSignIn('azure')}>
        Sign in with Microsoft
      </button>
    </div>
  )
}
```

## Testing OAuth Configuration

### Test OAuth Providers

1. Restart your Supabase services:
```bash
docker-compose down
docker-compose up -d
```

2. Check auth configuration:
```bash
curl http://localhost:8000/auth/v1/settings
```

3. Test OAuth redirect URLs:
- Google: `http://localhost:8000/auth/v1/authorize?provider=google`
- GitHub: `http://localhost:8000/auth/v1/authorize?provider=github`
- Azure: `http://localhost:8000/auth/v1/authorize?provider=azure`

### Verify Multi-Project Setup

1. Access Studio: `http://localhost:3000`
2. Check organization dashboard
3. Try creating a new project
4. Verify project creation flow

## Database Schema for Multi-Project Support

The following tables support multi-project functionality:

```sql
-- Organizations table
CREATE TABLE IF NOT EXISTS auth.organizations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- User organization memberships
CREATE TABLE IF NOT EXISTS auth.organization_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES auth.organizations(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'member',
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(organization_id, user_id)
);

-- Projects table
CREATE TABLE IF NOT EXISTS auth.projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id UUID REFERENCES auth.organizations(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  database_url TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
```

## Security Considerations

### OAuth Security

1. **Redirect URI Validation**: Ensure redirect URIs are properly configured
2. **Client Secret Protection**: Keep client secrets secure and never expose them
3. **HTTPS in Production**: Use HTTPS for all OAuth redirects in production
4. **Token Validation**: Verify OAuth tokens server-side

### Multi-Project Security

1. **Organization Isolation**: Ensure proper data isolation between organizations
2. **Role-Based Access**: Implement proper role-based access control
3. **Project Permissions**: Verify user permissions for project access

## Troubleshooting

### Common OAuth Issues

1. **Invalid Redirect URI**: Verify redirect URIs match exactly
2. **Client ID/Secret Issues**: Double-check credentials
3. **CORS Errors**: Ensure proper CORS configuration
4. **Token Expiration**: Handle token refresh properly

### Multi-Project Issues

1. **404 Organization Error**: Ensure `STUDIO_DEFAULT_ORG_SLUG` is set
2. **Project Creation Fails**: Check database permissions
3. **Routing Issues**: Verify organization slug configuration

### Debug Commands

```bash
# Check auth service logs
docker logs supabase-auth

# Check studio logs
docker logs supabase-studio

# Test auth endpoint
curl http://localhost:8000/auth/v1/settings

# Check database connection
docker exec -it supabase-db psql -U postgres -d postgres
```

## Production Deployment

### Environment Variables for Production

Update these variables for production deployment:

```bash
# Update for your production domain
API_EXTERNAL_URL=https://your-domain.com
SITE_URL=https://your-app.com
SUPABASE_PUBLIC_URL=https://your-domain.com

# OAuth redirect URIs should use HTTPS
GOTRUE_EXTERNAL_GOOGLE_REDIRECT_URI=https://your-domain.com/auth/v1/callback
GOTRUE_EXTERNAL_GITHUB_REDIRECT_URI=https://your-domain.com/auth/v1/callback
# ... (update all provider redirect URIs)
```

### SSL/TLS Configuration

Ensure proper SSL/TLS setup for production:
1. Use valid SSL certificates
2. Configure HTTPS redirects
3. Update OAuth provider settings with HTTPS URLs

## Support and Resources

- [Supabase Auth Documentation](https://supabase.com/docs/guides/auth)
- [OAuth Provider Setup Guides](https://supabase.com/docs/guides/auth/social-login)
- [Self-Hosting Guide](https://supabase.com/docs/guides/self-hosting)
- [GoTrue Configuration](https://github.com/supabase/gotrue)

## Next Steps

1. Configure your preferred OAuth providers
2. Test authentication flows
3. Set up your application to use the OAuth providers
4. Configure proper production settings
5. Monitor authentication metrics and logs

---

For technical support or questions, refer to the [Supabase Community](https://github.com/supabase/supabase/discussions) or [Discord](https://discord.supabase.com/).