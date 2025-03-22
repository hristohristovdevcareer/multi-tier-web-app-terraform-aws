import { useState, useEffect } from "react";

export default function Read({ urlTarget, id, exportOperation }) {
    const [item, setItem] = useState(null);
    const [isLoading, setIsLoading] = useState(true);
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

    if (isLoading) {
        return (
            <div className="w-full flex flex-col justify-start items-center">
                <h3 className="text-2xl font-bold text-center">Loading item details...</h3>
            </div>
        );
    }

    if (error) {
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
            <h3 className="text-2xl font-bold text-center">Item details</h3>

            <button 
                onClick={() => exportOperation('list')} 
                className="w-fit mb-4 bg-green-700 text-white rounded-md p-2 px-5 hover:bg-green-500 transition-all duration-300"
            >
                Back
            </button>
            
            <div className="w-full flex flex-col items-start justify-start text-left">
                <p className="mb-2">Name: {item.name}</p>
                <p className="mb-2">Id: {item.id}</p>
                <p className="mb-2">Created At: {item.createdAt}</p>
            </div>
            
            <div className="flex items-start justify-start gap-2 w-full">
                <button 
                    onClick={() => exportOperation('update', item.id)} 
                    className="bg-green-700 text-white rounded-md p-2 px-5 hover:bg-green-500 transition-all duration-300"
                >
                    Update
                </button>
                <button 
                    onClick={() => exportOperation('delete', item.id)} 
                    className="bg-red-700 text-white rounded-md p-2 px-5 hover:bg-red-500 transition-all duration-300"
                >
                    Delete
                </button>
            </div>
        </div>
    );
}