import { useState } from 'react';

export default function Delete({ urlTarget, id, exportOperation }) {
    const [isLoading, setIsLoading] = useState(false);
    const [error, setError] = useState(null);

    const handleDelete = async () => {
        try {
            setIsLoading(true);
            setError(null);
            
            const response = await fetch(`${urlTarget}?id=${id}`, {
                method: 'DELETE',
            });
            
            if (!response.ok) {
                throw new Error(`Failed to delete: ${response.status}`);
            }
            
            // Only navigate after successful deletion
            exportOperation('list');
        } catch (error) {
            console.log('Delete error:', error);
            setError(error.message);
        } finally {
            setIsLoading(false);
        }
    }
    
    return (
        <div>
            <div>
                <h3>Are you sure you want to delete this item?</h3>
                {error && <p className="text-red-500 mt-2">{error}</p>}
            </div>
            <div className="flex items-center justify-between gap-2">
                <button 
                    onClick={() => exportOperation('list')} 
                    className="bg-green-700 text-white rounded-md p-2 px-5 hover:bg-green-500 transition-all duration-300"
                    disabled={isLoading}
                >
                    Back
                </button>
                <button 
                    onClick={handleDelete} 
                    className="bg-red-700 text-white rounded-md p-2 px-5 hover:bg-red-500 transition-all duration-300"
                    disabled={isLoading}
                >
                    {isLoading ? 'Deleting...' : 'Delete'}
                </button>
            </div>
        </div>
    );
}