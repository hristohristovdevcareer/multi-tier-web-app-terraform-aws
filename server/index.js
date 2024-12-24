const express = require("express");

const app = express();

app.get("/", function (req, res) {
  res.send("Hello World");
});

app.get('/health', async (req, res) => {
  try {
    // Test DB connection
    await db.query('SELECT 1');
    res.status(200).json({ status: 'healthy' });
  } catch (error) {
    res.status(500).json({ status: 'unhealthy', error: error.message });
  }
});

app.listen(8080);
