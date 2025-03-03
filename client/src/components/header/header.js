export default function Header({ title, description }) {
    return (
        <div className="w-full flex flex-col items-center justify-center py-10">
            <div className="inner">
                <h1 className="text-4xl font-bold text-center">{title}</h1>
                <p className="text-xl text-center">{description}</p>
            </div>
        </div>
    );
}