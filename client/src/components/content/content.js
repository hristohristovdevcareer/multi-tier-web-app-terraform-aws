"use client";

import Navigation from "@/components/navigation/navigation";
import { useState } from "react";
import Create from "@/components/create/create";
import List from "@/components/list/list";
import Read from "@/components/read/read";
import Update from "@/components/update/update";
import Delete from "@/components/delete/delete";

export default function Content() {
    const [activeTab, setActiveTab] = useState("list");
    const [activeId, setActiveId] = useState(null);
    const urlTarget = "http://localhost:8080";
    const tabs = ["create", "list"];

    const setOperation = (operation, id) => {
        setActiveTab(operation);
        setActiveId(id);
    }

    const operation = (tab) => {
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