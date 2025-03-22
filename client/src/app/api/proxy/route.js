import https from 'https';

// Dummy data for development
const dummyData = {
  items: [
    { id: '1', name: 'Test Item 1', createdAt: new Date().toISOString() },
    { id: '2', name: 'Test Item 2', createdAt: new Date().toISOString() },
    { id: '3', name: 'Test Item 3', createdAt: new Date().toISOString() }
  ]
};

// Helper to simulate API delay
const delay = (ms) => new Promise(resolve => setTimeout(resolve, ms));

export async function GET(request) {
  if (process.env.NODE_ENV === 'development') {
    await delay(500); // Simulate network delay
    
    const { searchParams } = new URL(request.url);
    const id = searchParams.get('id');
    
    if (id) {
      const item = dummyData.items.find(item => item.id === id);
      if (!item) {
        return new Response(JSON.stringify({ error: 'Item not found' }), { 
          status: 404,
          headers: { 'Content-Type': 'application/json' }
        });
      }
      return Response.json(item);
    }
    
    return Response.json(dummyData);
  }

  // Production code
  const agent = new https.Agent({
    ca: process.env.NODE_EXTRA_CA_CERTS
  });

  const { searchParams } = new URL(request.url);
  const id = searchParams.get('id');
  
  const url = id 
    ? `${process.env.NEXT_PUBLIC_SERVER_URL}/api/items/${id}`
    : `${process.env.NEXT_PUBLIC_SERVER_URL}/api/items`;

  const response = await fetch(url, { agent });
  const data = await response.json();
  return Response.json(data);
}

export async function POST(request) {
  if (process.env.NODE_ENV === 'development') {
    await delay(500);
    
    const body = await request.json();
    const newItem = {
      id: (dummyData.items.length + 1).toString(),
      name: body.name,
      createdAt: new Date().toISOString()
    };
    
    dummyData.items.push(newItem);
    return Response.json(newItem);
  }

  // Production code
  const agent = new https.Agent({
    ca: process.env.NODE_EXTRA_CA_CERTS
  });

  const body = await request.json();
  
  const response = await fetch(`${process.env.NEXT_PUBLIC_SERVER_URL}/api/items`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
    agent
  });
  
  const data = await response.json();
  return Response.json(data);
}

export async function PUT(request) {
  if (process.env.NODE_ENV === 'development') {
    await delay(500);
    
    const { searchParams } = new URL(request.url);
    const id = searchParams.get('id');
    const body = await request.json();
    
    const itemIndex = dummyData.items.findIndex(item => item.id === id);
    if (itemIndex === -1) {
      return new Response(JSON.stringify({ error: 'Item not found' }), { 
        status: 404,
        headers: { 'Content-Type': 'application/json' }
      });
    }
    
    dummyData.items[itemIndex] = {
      ...dummyData.items[itemIndex],
      name: body.name
    };
    
    return Response.json(dummyData.items[itemIndex]);
  }

  // Production code
  const agent = new https.Agent({
    ca: process.env.NODE_EXTRA_CA_CERTS
  });

  const { searchParams } = new URL(request.url);
  const id = searchParams.get('id');
  const body = await request.json();
  
  const response = await fetch(`${process.env.NEXT_PUBLIC_SERVER_URL}/api/items/${id}`, {
    method: 'PUT',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
    agent
  });
  
  const data = await response.json();
  return Response.json(data);
}

export async function DELETE(request) {
  if (process.env.NODE_ENV === 'development') {
    await delay(500);
    
    const { searchParams } = new URL(request.url);
    const id = searchParams.get('id');
    
    const itemIndex = dummyData.items.findIndex(item => item.id === id);
    if (itemIndex === -1) {
      return new Response(JSON.stringify({ error: 'Item not found' }), { 
        status: 404,
        headers: { 'Content-Type': 'application/json' }
      });
    }
    
    dummyData.items.splice(itemIndex, 1);
    return Response.json({ success: true });
  }

  // Production code
  const agent = new https.Agent({
    ca: process.env.NODE_EXTRA_CA_CERTS
  });

  const { searchParams } = new URL(request.url);
  const id = searchParams.get('id');
  
  const response = await fetch(`${process.env.NEXT_PUBLIC_SERVER_URL}/api/items/${id}`, {
    method: 'DELETE',
    agent
  });
  
  const data = await response.json();
  return Response.json(data);
}