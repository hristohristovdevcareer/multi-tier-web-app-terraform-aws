const express = require("express");
const axios = require("axios");
const app = express();

async function getInstanceId() {
  try {
    const response = await axios.get('http://169.254.169.254/latest/meta-data/instance-id');
    return response.data;
  } catch (error) {
    console.error('Error fetching instance ID:', error.message);
    return 'unknown-instance';
  }
}

let cachedInstanceId = null;

app.get("/", async function (req, res) {
  if (!cachedInstanceId) {
    cachedInstanceId = await getInstanceId();
  }
  res.send(`Hello World from instance ${cachedInstanceId}`);
});

app.get('/health', async (req, res) => {
  res.status(200).json({ status: 'healthy' });
  // try {
  //   // Test DB connection
  //   await db.query('SELECT 1');
  //   res.status(200).json({ status: 'healthy' });
  // } catch (error) {
  //   res.status(500).json({ status: 'unhealthy', error: error.message });
  // }
});

app.listen(8080);
