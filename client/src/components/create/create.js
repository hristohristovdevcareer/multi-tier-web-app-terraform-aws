import { useState } from 'react';

export default function Create({ urlTarget, exportOperation }) {
    const [name, setName] = useState('');
    const [isLoading, setIsLoading] = useState(false);
    const [error, setError] = useState(null);

    const handleCreate = async () => {
        try {
            setIsLoading(true);
            setError(null);
            
            const response = await fetch(urlTarget, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ name: name }),
            });
            
            if (!response.ok) {
                const errorData = await response.json();
                throw new Error(errorData.error || 'Failed to create item');
            }
            
            // Clear the input field
            setName('');
            
            // Navigate to list view
            exportOperation('list');
        } catch (error) {
            console.log('Error creating item:', error);
            setError(error.message);
        } finally {
            setIsLoading(false);
        }
    }

    return <div className="flex flex-col items-center justify-center">
        <div className="inner flex gap-2 sm:flex-col">
            <input 
                className="" 
                type="text" 
                placeholder="Name" 
                value={name} 
                onChange={(e) => setName(e.target.value)} 
            />
            <button 
                className={`bg-green-700 text-white hover:bg-green-500 ${isLoading ? 'opacity-50 cursor-not-allowed' : ''}`} 
                onClick={handleCreate}
                disabled={isLoading}
            >
                {isLoading ? 'Creating...' : 'Create'}
            </button>
        </div>
        {error && <p className="text-red-500 mt-2">{error}</p>}
    </div>;
}