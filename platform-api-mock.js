const express = require('express');
const cors = require('cors');
const app = express();

app.use(cors());
app.use(express.json());

// In-memory storage for multi-organization support
let organizations = [
  {
    id: 1,
    slug: 'default-org-slug',
    name: 'Default Organization',
    billing_email: 'admin@localhost',
    tier: 'free',
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString()
  }
];

let projects = [
  {
    id: 1,
    ref: 'default',
    name: 'Default Project',
    organization_id: 1,
    cloud_provider: 'LOCAL',
    region: 'localhost',
    status: 'ACTIVE_HEALTHY',
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString()
  }
];

let nextOrgId = 2;
let nextProjectId = 2;

// Helper function to generate slug from name
function generateSlug(name) {
  return name.toLowerCase().replace(/\s+/g, '-').replace(/[^a-z0-9-]/g, '');
}

// Platform API endpoints
app.get('/api/platform/profile', (req, res) => {
  res.json({
    id: 1,
    email: 'admin@localhost',
    name: 'Local Admin',
    created_at: new Date().toISOString()
  });
});

// Organizations endpoints
app.get('/api/platform/organizations', (req, res) => {
  res.json(organizations);
});

app.get('/api/platform/organizations/:slug', (req, res) => {
  const org = organizations.find(o => o.slug === req.params.slug);
  if (!org) {
    return res.status(404).json({ error: 'Organization not found' });
  }
  res.json(org);
});

app.post('/api/platform/organizations', (req, res) => {
  const { name, type = 'personal', tier = 'free' } = req.body;
  
  if (!name) {
    return res.status(400).json({ error: 'Organization name is required' });
  }
  
  const slug = generateSlug(name);
  
  // Check if slug already exists
  const existingOrg = organizations.find(o => o.slug === slug);
  if (existingOrg) {
    return res.status(400).json({ error: 'Organization with this name already exists' });
  }
  
  const newOrg = {
    id: nextOrgId++,
    slug,
    name,
    type,
    tier,
    billing_email: 'admin@localhost',
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString()
  };
  
  organizations.push(newOrg);
  res.status(201).json(newOrg);
});

app.patch('/api/platform/organizations/:slug', (req, res) => {
  const org = organizations.find(o => o.slug === req.params.slug);
  if (!org) {
    return res.status(404).json({ error: 'Organization not found' });
  }
  
  Object.assign(org, req.body, { updated_at: new Date().toISOString() });
  res.json(org);
});

// Projects endpoints
app.get('/api/platform/organizations/:slug/projects', (req, res) => {
  const { limit = 50, offset = 0, sort = 'name_asc' } = req.query;
  const org = organizations.find(o => o.slug === req.params.slug);
  
  if (!org) {
    return res.status(404).json({ error: 'Organization not found' });
  }
  
  const orgProjects = projects.filter(p => p.organization_id === org.id);
  
  res.json({
    data: orgProjects.slice(parseInt(offset), parseInt(offset) + parseInt(limit)),
    count: orgProjects.length,
    pagination: {
      count: orgProjects.length,
      limit: parseInt(limit),
      offset: parseInt(offset)
    }
  });
});

app.get('/api/platform/projects/:ref', (req, res) => {
  const project = projects.find(p => p.ref === req.params.ref);
  if (!project) {
    return res.status(404).json({ error: 'Project not found' });
  }
  res.json(project);
});

app.post('/api/platform/organizations/:slug/projects', (req, res) => {
  const { name, region = 'localhost', plan = 'free' } = req.body;
  const org = organizations.find(o => o.slug === req.params.slug);
  
  if (!org) {
    return res.status(404).json({ error: 'Organization not found' });
  }
  
  if (!name) {
    return res.status(400).json({ error: 'Project name is required' });
  }
  
  const ref = generateSlug(name);
  
  // Check if ref already exists
  const existingProject = projects.find(p => p.ref === ref);
  if (existingProject) {
    return res.status(400).json({ error: 'Project with this name already exists' });
  }
  
  const newProject = {
    id: nextProjectId++,
    ref,
    name,
    organization_id: org.id,
    cloud_provider: 'LOCAL',
    region,
    plan,
    status: 'ACTIVE_HEALTHY',
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString()
  };
  
  projects.push(newProject);
  res.status(201).json(newProject);
});

app.patch('/api/platform/projects/:ref', (req, res) => {
  const project = projects.find(p => p.ref === req.params.ref);
  if (!project) {
    return res.status(404).json({ error: 'Project not found' });
  }
  
  Object.assign(project, req.body, { updated_at: new Date().toISOString() });
  res.json(project);
});

app.delete('/api/platform/projects/:ref', (req, res) => {
  const projectIndex = projects.findIndex(p => p.ref === req.params.ref);
  if (projectIndex === -1) {
    return res.status(404).json({ error: 'Project not found' });
  }
  
  projects.splice(projectIndex, 1);
  res.status(204).send();
});

// Project settings endpoints
app.get('/api/platform/projects/:ref/settings', (req, res) => {
  const project = projects.find(p => p.ref === req.params.ref);
  if (!project) {
    return res.status(404).json({ error: 'Project not found' });
  }
  
  res.json({
    project: project,
    services: {
      db: { status: 'ACTIVE_HEALTHY' },
      auth: { status: 'ACTIVE_HEALTHY' },
      storage: { status: 'ACTIVE_HEALTHY' },
      realtime: { status: 'ACTIVE_HEALTHY' },
      edge_functions: { status: 'ACTIVE_HEALTHY' }
    }
  });
});

app.patch('/api/platform/projects/:ref/settings', (req, res) => {
  const project = projects.find(p => p.ref === req.params.ref);
  if (!project) {
    return res.status(404).json({ error: 'Project not found' });
  }
  
  Object.assign(project, req.body, { updated_at: new Date().toISOString() });
  res.json({ project: project });
});

app.get('/api/platform/projects/:ref/databases', (req, res) => {
  res.json([{
    identifier: 'default',
    name: 'postgres',
    status: 'ACTIVE_HEALTHY',
    host: 'localhost',
    port: 5432
  }]);
});

app.get('/api/platform/organizations/:slug/billing/subscription', (req, res) => {
  const org = organizations.find(o => o.slug === req.params.slug);
  res.json({
    tier: {
      key: org?.tier || 'free',
      name: org?.tier === 'free' ? 'Free' : 'Pro',
      price: org?.tier === 'free' ? 0 : 25
    },
    usage: {
      db_size: 0,
      bandwidth: 0,
      monthly_active_users: 0
    },
    billing_cycle_anchor: new Date().toISOString()
  });
});

app.get('/api/platform/projects/:ref/run-lints', (req, res) => {
  res.json([]);
});

// Mock pg-meta endpoints
app.post('/api/platform/pg-meta/:ref/query', (req, res) => {
  res.json([]);
});

app.get('/api/platform/pg-meta/:ref/tables', (req, res) => {
  res.json([]);
});

// Debug endpoint to view current state
app.get('/api/debug/state', (req, res) => {
  res.json({
    organizations: organizations,
    projects: projects
  });
});

// Catch-all for any other platform API calls
app.use('/api/platform/*', (req, res) => {
  console.log(`Mock API called: ${req.method} ${req.originalUrl}`);
  res.json({ message: 'Mock platform API response', path: req.originalUrl });
});

// Health check
app.get('/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    service: 'platform-api-mock',
    organizations_count: organizations.length,
    projects_count: projects.length
  });
});

const PORT = 3001;
app.listen(PORT, () => {
  console.log(`Platform API Mock server running on port ${PORT}`);
  console.log(`Health check: http://localhost:${PORT}/health`);
  console.log(`Debug state: http://localhost:${PORT}/api/debug/state`);
  console.log('Multi-organization and multi-project support enabled!');
});