module.exports = (req, res) => {
  res.status(200).json({
    environment: 'production',
    clickpesa_client_id: process.env.CLICKPESA_CLIENT_ID ? 'SET' : 'MISSING',
    clickpesa_api_key: process.env.CLICKPESA_API_KEY ? 'SET' : 'MISSING',
    webhook_secret: process.env.WEBHOOK_SECRET ? 'SET' : 'MISSING',
    firebase_project_id: process.env.FIREBASE_PROJECT_ID ? 'SET' : 'MISSING',
    all_env_keys: Object.keys(process.env).filter(key => 
      key.includes('CLICKPESA') || 
      key.includes('FIREBASE') || 
      key.includes('WEBHOOK')
    )
  });
};
