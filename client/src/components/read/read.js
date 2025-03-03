import { useState, useEffect } from "react";

export default function Read({ urlTarget, id, exportOperation }) {
    const [item, setItem] = useState(null);

    useEffect(() => {
        fetch(`${urlTarget}/api/items/${id}`)
            .then(response => response.json())
            .then(data => setItem(data))
            .catch(error => console.error(error));
    }, [id]);

    return <div className="w-full flex flex-col justify-start">
        <h3 className="text-2xl font-bold text-center">Item details</h3>

        <button onClick={() => exportOperation('list')} className="w-fit mb-4 bg-green-700 text-white rounded-md p-2 px-5 hover:bg-green-500 transition-all duration-300">Back</button>
        <div className="w-full flex flex-col items-start justify-start text-left">
            <p className="mb-2">Name: {item?.name}</p>
            <p className="mb-2">Id: {item?.id}</p>
            <p className="mb-2">Created At: {item?.createdAt}</p>
        </div>
        <div className="flex items-start justify-start gap-2 w-full">
            <button onClick={() => exportOperation('update', item.id)} className="bg-green-700 text-white rounded-md p-2 px-5 hover:bg-green-500 transition-all duration-300">Update</button>
            <button onClick={() => exportOperation('delete', item.id)} className="bg-red-700 text-white rounded-md p-2 px-5 hover:bg-red-500 transition-all duration-300">Delete</button>
        </div>
    </div>;
}