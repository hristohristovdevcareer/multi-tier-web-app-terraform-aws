"use client";

import Navigation from "@/components/navigation/navigation";
import { useState, useEffect } from "react";
import Create from "@/components/create/create";
import List from "@/components/list/list";
import Read from "@/components/read/read";
import Update from "@/components/update/update";
import Delete from "@/components/delete/delete";

export default function Content() {
    const [activeTab, setActiveTab] = useState("list");
    const [activeId, setActiveId] = useState(null);
    const [error, setError] = useState(null);
    
    // Update urlTarget to use relative path
    const urlTarget = "/api/proxy";
    
    const tabs = ["create", "list"];

    const setOperation = (operation, id) => {
        setActiveTab(operation);
        setActiveId(id);
    }

    console.log(urlTarget);

    const operation = (tab) => {
        if (error) {
            return (
                <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded">
                    <p className="font-bold">Configuration Error</p>
                    <p>{error}</p>
                </div>
            );
        }
        
        switch (tab) {
            case "create":
                return <Create urlTarget={urlTarget} exportOperation={setOperation} />;
            case "list":
                return <List urlTarget={urlTarget} exportOperation={setOperation} />;
            case "read":
                return <Read urlTarget={urlTarget} id={activeId} exportOperation={setOperation} />;
            case "update":
                return <Update urlTarget={urlTarget} id={activeId} exportOperation={setOperation} />;
            case "delete":
                return <Delete urlTarget={urlTarget} id={activeId} exportOperation={setOperation} />;
            default:
                return <List urlTarget={urlTarget} exportOperation={setOperation} />;
        }
    }

    return (
        <div className="w-full flex flex-col items-center justify-center">
            <div className="inner">
                <Navigation tabs={tabs} exportTab={setActiveTab} />

                <div className="w-full flex flex-col items-center justify-center my-10 border border-black rounded-lg p-10 md:p-3">
                    {operation(activeTab)}
                </div>
            </div>
        </div>
    );
}