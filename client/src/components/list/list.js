import { useState, useEffect } from "react";

export default function List({ urlTarget, exportOperation }) {
    const [list, setList] = useState([]);

    const fetchList = () => {
        fetch(`${urlTarget}/api/items`)
            .then(response => response.json())
            .then(data => setList(data))
            .catch(error => console.error(error));
    }

    useEffect(() => {
        fetchList();
    }, []);

    return <div className="w-full flex flex-col items-center ">
        <div className="inner">
            <div className="flex flex-col items-center w-full">
                {list.map((item, index) => (
                    <div key={index} className="flex items-center justify-between w-full mb-4">
                        <p onClick={() => exportOperation('read', item.id)} className="text-lg cursor-pointer hover:underline ">{item.name}</p>
                        <div className="flex gap-2">
                            <button onClick={() => exportOperation('read', item.id)} className="bg-green-700 text-white rounded-md p-2 px-5 hover:bg-green-500 transition-all duration-300">View</button>
                            <button onClick={() => exportOperation('update', item.id)} className="bg-yellow-700 text-white rounded-md p-2 px-5 hover:bg-yellow-500 transition-all duration-300">Update</button>
                            <button onClick={() => exportOperation('delete', item.id)} className="bg-red-700 text-white rounded-md p-2 px-5 hover:bg-red-500 transition-all duration-300">Delete</button>
                        </div>
                    </div>
                ))}
            </div>
        </div>
    </div>;
}