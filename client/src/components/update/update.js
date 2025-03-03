import { useState, useEffect } from "react";

export default function Update({ urlTarget, id, exportOperation }) {
    const [item, setItem] = useState(null);

    useEffect(() => {
        fetch(`${urlTarget}/api/items/${id}`)
            .then(response => response.json())
            .then(data => setItem(data))
            .catch(error => console.error(error));
    }, [id]);

    const handleUpdate = () => {
        fetch(`${urlTarget}/api/items/${id}`, {
            method: 'PUT',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ name: item.name }),
        });
        exportOperation('list');
    }

    return <div className="w-full flex flex-col justify-start">
        <h3 className="text-2xl font-bold text-center">Update Item</h3>

        <button onClick={() => exportOperation('list')} className="w-fit mb-4 bg-green-700 text-white rounded-md p-2 px-5 hover:bg-green-500 transition-all duration-300">Back</button>

        <div className="w-full flex flex-col items-start justify-start text-left">
            <h3 className="text-2xl font-bold">Item details</h3>
            <div className="w-full flex flex-col items-start justify-start text-left">
                <p className="mb-2">Name: {item?.name}</p>
                <p className="mb-2">Id: {item?.id}</p>
                <p className="mb-2">Created At: {item?.createdAt}</p>
            </div>
        </div>

        <div className="w-full flex flex-col items-start justify-start text-left mb-5">
            <h3 className="text-2xl font-bold">Update Item</h3>
            <input type="text" placeholder="Name" value={item?.name ? item.name : ''} onChange={(e) => setItem({ ...item, name: e.target.value })} />
        </div>

        <div className="w-full flex flex-col items-start justify-start text-left">
            <button onClick={handleUpdate} className="bg-yellow-700 text-white rounded-md p-2 px-5 hover:bg-yellow-500 transition-all duration-300">Update</button>
        </div>
    </div>;
}