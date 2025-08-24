"use client";

import { useEffect, useState } from "react";

export default function Home() {
  const [lat, setLat] = useState("");
  const [lng, setLng] = useState("");

  useEffect(() => {
    // Listener for native app sending data
    window.onNativeData = (payload) => {
      console.log("Got data from native app:", payload);
      try {
        if (typeof payload === "string") {
          payload = JSON.parse(payload);
        }
        if (payload.lat) setLat(payload.lat);
        if (payload.lng) setLng(payload.lng);
      } catch (err) {
        console.error("Error parsing payload:", err);
      }
    };
  }, []);

  const requestLocation = () => {
    // Send a message to the FlutterFlow app
    if (window.FFBridge && window.FFBridge.postMessage) {
      window.FFBridge.postMessage("getLocation");
    } else {
      alert("Native bridge not available");
    }
  };

  return (
    <main className="flex min-h-screen flex-col items-center justify-center p-6">
      <h1 className="text-3xl font-bold mb-4">Next.js Web ↔ Native Demo</h1>

      <form className="flex flex-col gap-3">
        <input
          type="text"
          placeholder="Latitude"
          value={lat}
          readOnly
          className="border p-2"
        />
        <input
          type="text"
          placeholder="Longitude"
          value={lng}
          readOnly
          className="border p-2"
        />
        <button
          type="button"
          onClick={requestLocation}
          className="bg-blue-600 text-white px-4 py-2 rounded"
        >
          Get My Location
        </button>
      </form>
    </main>
  );
}
