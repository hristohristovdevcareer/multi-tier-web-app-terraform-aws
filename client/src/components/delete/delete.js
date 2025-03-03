export default function Delete({ urlTarget, id, exportOperation }) {
    const handleDelete = () => {
        fetch(`${urlTarget}/api/items/${id}`, {
            method: 'DELETE',
        });
        exportOperation('list');
    }
    return <div>
        <div>
            <h3>Are you sure you want to delete this item?</h3>
        </div>
        <div className="flex items-center justify-between gap-2">
            <button onClick={() => exportOperation('list')} className="bg-green-700 text-white rounded-md p-2 px-5 hover:bg-green-500 transition-all duration-300">Back</button>
            <button onClick={handleDelete} className="bg-red-700 text-white rounded-md p-2 px-5 hover:bg-red-500 transition-all duration-300">Delete</button>
        </div>
    </div>;
}