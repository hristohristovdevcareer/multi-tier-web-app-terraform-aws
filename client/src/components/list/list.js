import { useState, useEffect } from "react";

export default function List({ urlTarget, exportOperation }) {
    const [list, setList] = useState([]);
    const [isLoading, setIsLoading] = useState(false);
    const [error, setError] = useState(null);

    const fetchList = async () => {
        try {
            setIsLoading(true);
            setError(null);

            const controller = new AbortController();
            const timeoutId = setTimeout(() => controller.abort(), 10000);

            const response = await fetch(urlTarget, {
                method: 'GET',
                headers: {
                    'Content-Type': 'application/json',
                },
                signal: controller.signal
            });
            
            clearTimeout(timeoutId);
            
            if (!response.ok) {
                // Special case for empty list (404)
                if (response.status === 404) {
                    setList([]);
                    return;
                }
                
                const errorData = await response.json();
                throw new Error(errorData.error || `Server error: ${response.status}`);
            }
            
            const data = await response.json();
            console.log(data.items);
            setList(data.items);
        } catch (error) {
            console.log('Error fetching items:', error);
            
            // Handle different types of errors
            if (error.name === 'AbortError') {
                setError('Request timed out. Please try again.');
            } else if (error.message === 'Failed to fetch') {
                setError('Unable to connect to the server. Please check your network connection.');
            } else {
                setError(`Error: ${error.message}`);
            }
        } finally {
            setIsLoading(false);
        }
    };

    useEffect(() => {
        fetchList();
    }, [urlTarget]);

    return (
        <div className="w-full flex flex-col items-center">
            <div className="inner">
                {error && (
                    <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
                        <p>{error}</p>
                        <button 
                            onClick={fetchList} 
                            className="mt-2 bg-red-700 text-white rounded-md p-1 px-3 hover:bg-red-500 transition-all duration-300"
                        >
                            Retry
                        </button>
                    </div>
                )}
                
                {isLoading ? (
                    <div className="text-center py-4">Loading items...</div>
                ) : list.length === 0 ? (
                    <div className="text-center py-4">
                        <p>No items found.</p>
                        <p>Create a new item to get started!</p>
                    </div>
                ) : (
                    <div className="flex flex-col items-center w-full">
                        {list.map((item, index) => (
                            <div key={index} className="flex items-center justify-between w-full mb-4">
                                <p 
                                    onClick={() => exportOperation('read', item.id)} 
                                    className="text-lg cursor-pointer hover:underline"
                                >
                                    {item.name}
                                </p>
                                
                                <div className="flex gap-2">
                                    <button 
                                        onClick={() => exportOperation('read', item.id)} 
                                        className="bg-green-700 text-white rounded-md p-2 px-5 hover:bg-green-500 transition-all duration-300"
                                    >
                                        View
                                    </button>
                                    <button 
                                        onClick={() => exportOperation('update', item.id)} 
                                        className="bg-yellow-700 text-white rounded-md p-2 px-5 hover:bg-yellow-500 transition-all duration-300"
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
                        ))}
                    </div>
                )}
            </div>
        </div>
    );
}