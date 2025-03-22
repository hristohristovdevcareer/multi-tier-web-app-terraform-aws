const express = require("express");
const cors = require("cors");
const app = express();

app.use(cors({
  origin: '*',  // In production, you should specify your frontend domain
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
app.use(express.json());

async function getInstanceId() {
  try {
    const response = await fetch('http://169.254.169.254/latest/meta-data/instance-id');
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }
    return await response.text();
  } catch (error) {
    console.log('Error fetching instance ID:', error.message);
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

// Temporary in-memory storage
let items = [];
let nextId = 1;


// CREATE - Add a new item
app.post('/api/items', (req, res) => {
  const item = {
    id: nextId++,
    ...req.body,
    createdAt: new Date()
  };
  items.push(item);
  res.status(201).json(item);
});

// READ - Get all items
app.get('/api/items', (req, res) => {
  if (items.length === 0) {
    res.status(200).json({ items: [] });
  } else {
    res.json({ items: items });
  }
});

// READ - Get single item by ID
app.get('/api/items/:id', (req, res) => {
  const item = items.find(item => item.id === parseInt(req.params.id));
  if (!item) {
    return res.status(200).json({ error: 'Item not found' });
  }
  res.json(item);
});

// UPDATE - Update an item
app.put('/api/items/:id', (req, res) => {
  const itemIndex = items.findIndex(item => item.id === parseInt(req.params.id));
  if (itemIndex === -1) {
    return res.status(200).json({ error: 'Item not found' });
  }

  items[itemIndex] = {
    ...items[itemIndex],
    ...req.body,
    id: items[itemIndex].id, // Preserve the original ID
    updatedAt: new Date()
  };

  res.json(items[itemIndex]);
});

// DELETE - Remove an item
app.delete('/api/items/:id', (req, res) => {
  const itemIndex = items.findIndex(item => item.id === parseInt(req.params.id));
  if (itemIndex === -1) {
    return res.status(200).json({ error: 'Item not found' });
  }

  const deletedItem = items.splice(itemIndex, 1)[0];
  res.json(deletedItem);
});

app.listen(8080);
