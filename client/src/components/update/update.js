import { useState, useEffect } from "react";

export default function Update({ urlTarget, id, exportOperation }) {
    const [item, setItem] = useState(null);
    const [isLoading, setIsLoading] = useState(true);
    const [isSaving, setIsSaving] = useState(false);
    const [error, setError] = useState(null);

    useEffect(() => {
        const fetchItem = async () => {
            try {
                setIsLoading(true);
                setError(null);
                
                const response = await fetch(`${urlTarget}?id=${id}`);
                
                if (!response.ok) {
                    throw new Error(`Failed to fetch item: ${response.status}`);
                }
                
                const data = await response.json();
                setItem(data);
            } catch (error) {
                console.log('Error fetching item:', error);
                setError('Failed to load item details. Please try again.');
            } finally {
                setIsLoading(false);
            }
        };
        
        fetchItem();
    }, [id, urlTarget]);

    const handleUpdate = async () => {
        if (!item || !item.name || !item.name.trim()) {
            setError("Name cannot be empty");
            return;
        }
        
        try {
            setIsSaving(true);
            setError(null);
            
            const response = await fetch(`${urlTarget}?id=${id}`, {
                method: 'PUT',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ name: item.name }),
            });
            
            if (!response.ok) {
                const errorData = await response.json();
                throw new Error(errorData.error || `Failed to update: ${response.status}`);
            }
            
            // Only navigate after successful update
            exportOperation('list');
        } catch (error) {
            console.log('Update error:', error);
            setError(error.message || 'Failed to update item. Please try again.');
        } finally {
            setIsSaving(false);
        }
    };

    if (isLoading) {
        return (
            <div className="w-full flex flex-col justify-start items-center">
                <h3 className="text-2xl font-bold text-center">Loading item details...</h3>
            </div>
        );
    }

    if (error && !item) {
        return (
            <div className="w-full flex flex-col justify-start items-center">
                <h3 className="text-2xl font-bold text-center">Error</h3>
                <p className="text-red-500">{error}</p>
                <button 
                    onClick={() => exportOperation('list')} 
                    className="mt-4 bg-green-700 text-white rounded-md p-2 px-5 hover:bg-green-500 transition-all duration-300"
                >
                    Back to List
                </button>
            </div>
        );
    }

    if (!item) {
        return (
            <div className="w-full flex flex-col justify-start items-center">
                <h3 className="text-2xl font-bold text-center">Item not found</h3>
                <button 
                    onClick={() => exportOperation('list')} 
                    className="mt-4 bg-green-700 text-white rounded-md p-2 px-5 hover:bg-green-500 transition-all duration-300"
                >
                    Back to List
                </button>
            </div>
        );
    }

    return (
        <div className="w-full flex flex-col justify-start">
            <h3 className="text-2xl font-bold text-center">Update Item</h3>

            <button 
                onClick={() => exportOperation('list')} 
                className="w-fit mb-4 bg-green-700 text-white rounded-md p-2 px-5 hover:bg-green-500 transition-all duration-300"
                disabled={isSaving}
            >
                Back
            </button>

            <div className="w-full flex flex-col items-start justify-start text-left">
                <h3 className="text-2xl font-bold">Item details</h3>
                <div className="w-full flex flex-col items-start justify-start text-left">
                    <p className="mb-2">Name: {item.name}</p>
                    <p className="mb-2">Id: {item.id}</p>
                    <p className="mb-2">Created At: {item.createdAt}</p>
                </div>
            </div>

            <div className="w-full flex flex-col items-start justify-start text-left mb-5">
                <h3 className="text-2xl font-bold">Update Item</h3>
                <input 
                    type="text" 
                    placeholder="Name" 
                    value={item.name} 
                    onChange={(e) => setItem({ ...item, name: e.target.value })}
                    disabled={isSaving}
                    className="w-full p-2 border rounded"
                />
                {error && <p className="text-red-500 mt-2">{error}</p>}
            </div>

            <div className="w-full flex flex-col items-start justify-start text-left">
                <button 
                    onClick={handleUpdate} 
                    className={`bg-yellow-700 text-white rounded-md p-2 px-5 hover:bg-yellow-500 transition-all duration-300 ${isSaving ? 'opacity-50 cursor-not-allowed' : ''}`}
                    disabled={isSaving}
                >
                    {isSaving ? 'Updating...' : 'Update'}
                </button>
            </div>
        </div>
    );
}