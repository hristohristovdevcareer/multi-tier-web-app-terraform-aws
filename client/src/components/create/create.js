import { useState } from 'react';

export default function Create({ urlTarget, exportOperation }) {
    const [name, setName] = useState('');

    const handleCreate = () => {
        fetch(`${urlTarget}/api/items`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({ name: name }),
        });

        exportOperation('list');
    }

    return <div className="flex flex-col items-center justify-center">
        <div className="inner flex gap-2 sm:flex-col">
            <input className="" type="text" placeholder="Name" value={name} onChange={(e) => setName(e.target.value)} />
            <button className="bg-green-700 text-white hover:bg-green-500" onClick={handleCreate}>Create</button>
        </div>
    </div>;
}