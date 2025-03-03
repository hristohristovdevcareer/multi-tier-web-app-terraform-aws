'use client';

import { useEffect, useState } from 'react';

export default function Health() {
    const [status, setStatus] = useState({ 
        status: 'loading' 
    });

    useEffect(() => {
        const checkHealth = async () => {
            try {
                const response = await fetch('/api/health');
                const data = await response.json();
                setStatus(data);
            } catch (error) {
                setStatus({ status: 'error' });
            }
        };

        checkHealth();
    }, []);

    return (
        <div>
            <h1>Health Check</h1>
            <p>Status: {status.status}</p>
            {status.timestamp && (
                <p>Last checked: {new Date(status.timestamp).toLocaleString()}</p>
            )}
            {status.environment && <p>Environment: {status.environment}</p>}
        </div>
    );
}