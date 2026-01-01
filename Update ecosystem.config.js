module.exports = {
  apps: [{
    name: 'school-mis-backend',
    script: './backend/server.js',
    instances: 'max',  // Use all CPU cores
    exec_mode: 'cluster',
    // ... rest of config
  }]
}
