"use client";

import { useState } from "react";

export default function Navigation({ tabs, exportTab }) {
    const [activeTab, setActiveTab] = useState(tabs[0]);

    const handleTabClick = (tab) => {
        setActiveTab(tab);
        exportTab(tab);
    }

    return (
        <div className="flex flex-col items-center justify-center w-full">
            <div className="flex items-center justify-center w-full">
                <ul className="flex w-full mx-auto items-center justify-between md:flex-col ">
                    {tabs.map((tab, index) => (
                        <li key={index} className={`px-10 py-4 text-2xl bg-slate-200 text-center cursor-pointer rounded-lg transition-all duration-300  ${activeTab === tab ? 'bg-slate-500' : 'hover:bg-slate-400'} md:w-full md:mb-4`} onClick={() => handleTabClick(tab)}>{tab}</li>
                    ))}
                </ul>
            </div>
        </div>
    );
}