"use client";

import React, { useState, useEffect } from 'react';

const NativeFunctionsTest = () => {
  const [logs, setLogs] = useState([]);
  const [connectionStatus, setConnectionStatus] = useState('Checking...');

  // Add log entry
  const addLog = (message, type = 'info') => {
    const timestamp = new Date().toLocaleTimeString();
    setLogs(prev => [...prev, { message, type, timestamp }]);
  };

  // Initialize native bridge
  useEffect(() => {
    // Check if running in native app
    if (typeof window !== 'undefined') {
      if (window.NativeApp) {
        setConnectionStatus('Connected to Native App');
        addLog('Native bridge detected', 'success');
      } else if (window.FFBridge) {
        setConnectionStatus('Connected via FFBridge');
        addLog('FFBridge detected', 'success');
      } else {
        setConnectionStatus('Running in Web Browser');
        addLog('No native bridge found - running in browser', 'warning');
      }

      // Listen for native responses
      window.onNativeResponse = (data) => {
        addLog(`Native Response: ${JSON.stringify(data)}`, 'success');
      };

      window.onNativeData = (data) => {
        addLog(`Native Data: ${JSON.stringify(data)}`, 'success');
      };
    }
  }, []);

  // Helper function to send native commands
  const sendNativeCommand = (action, params = {}) => {
    try {
      if (window.NativeApp) {
        // New format
        window.NativeApp.postMessage(JSON.stringify({ action, params }));
        addLog(`Sent: ${action}`, 'info');
      } else if (window.FFBridge) {
        // Legacy format
        if (action === 'GET_LOCATION') {
          window.FFBridge.postMessage('getLocation');
        } else {
          window.FFBridge.postMessage(JSON.stringify({ action, params }));
        }
        addLog(`Sent via FFBridge: ${action}`, 'info');
      } else {
        addLog('No native bridge available', 'error');
      }
    } catch (error) {
      addLog(`Error sending command: ${error.message}`, 'error');
    }
  };

  // Test Functions
  const testGetLocation = () => {
    sendNativeCommand('GET_LOCATION');
  };

  const testCapturePhoto = () => {
    sendNativeCommand('CAPTURE_PHOTO', {
      quality: 0.8,
      maxWidth: 1920,
      maxHeight: 1920,
      source: 'camera'
    });
  };

  const testSelectFromGallery = () => {
    sendNativeCommand('CAPTURE_PHOTO', {
      quality: 0.8,
      maxWidth: 1920,
      maxHeight: 1920,
      source: 'gallery'
    });
  };

  const testScanQR = () => {
    sendNativeCommand('SCAN_QR');
  };

  const testScanBarcode = () => {
    sendNativeCommand('SCAN_BARCODE');
  };

  const testMakeCall = () => {
    const phoneNumber = prompt('Enter phone number:');
    if (phoneNumber) {
      sendNativeCommand('MAKE_CALL', { number: phoneNumber });
    }
  };

  const testGetCallLogs = () => {
    sendNativeCommand('GET_CALL_LOGS', { days: 7 });
  };

  const testShowToast = () => {
    sendNativeCommand('SHOW_TOAST', { message: 'Hello from Web App!' });
  };

  const testGetContacts = () => {
    sendNativeCommand('GET_CONTACTS');
  };
  

  const testUploadFile = () => {
    // Create a simple base64 test file
    const testData = 'SGVsbG8gV29ybGQh'; // "Hello World!" in base64
    sendNativeCommand('UPLOAD_FILE', {
      base64: testData,
      filename: 'test.txt'
    });
  };

  const testDownloadFile = () => {
    sendNativeCommand('DOWNLOAD_FILE', {
      url: 'https://httpbin.org/json',
      filename: 'downloaded.json'
    });
  };

  const testGetDeviceInfo = () => {
    sendNativeCommand('GET_DEVICE_INFO');
  };

  const testStorageSet = () => {
    const testData = {
      user: 'test_user',
      timestamp: Date.now(),
      settings: { theme: 'dark', notifications: true }
    };
    sendNativeCommand('STORAGE_SET', {
      key: 'test_data',
      value: testData
    });
  };

  const testStorageGet = () => {
    sendNativeCommand('STORAGE_GET', { key: 'test_data' });
  };

  const testGetNetworkStatus = () => {
    sendNativeCommand('GET_NETWORK_STATUS');
  };

  const clearLogs = () => {
    setLogs([]);
  };

  return (
    <div className="min-h-screen bg-gray-50 p-4">
      <div className="max-w-4xl mx-auto">
        {/* Header */}
        <div className="bg-white rounded-lg shadow-md p-6 mb-6">
          <h1 className="text-3xl font-bold text-gray-800 mb-2">
            Native Functions Test
          </h1>
          <div className="flex items-center gap-2">
            <span className="text-sm font-medium">Status:</span>
            <span className={`px-3 py-1 rounded-full text-xs font-medium ${
              connectionStatus.includes('Connected') 
                ? 'bg-green-100 text-green-800' 
                : connectionStatus.includes('Browser')
                ? 'bg-yellow-100 text-yellow-800'
                : 'bg-gray-100 text-gray-800'
            }`}>
              {connectionStatus}
            </span>
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* Test Functions */}
          <div className="bg-white rounded-lg shadow-md p-6">
            <h2 className="text-xl font-semibold mb-4 text-gray-800">Test Functions</h2>
            
            <div className="space-y-3">
              {/* Location */}
              <div className="border-b pb-3">
                <h3 className="font-medium text-gray-700 mb-2">📍 Location Services</h3>
                <button
                  onClick={testGetLocation}
                  className="bg-blue-500 hover:bg-blue-600 text-white px-4 py-2 rounded text-sm transition-colors"
                >
                  Get Current Location
                </button>
              </div>

              {/* Camera */}
              <div className="border-b pb-3">
                <h3 className="font-medium text-gray-700 mb-2">📸 Camera & Gallery</h3>
                <div className="flex gap-2 flex-wrap">
                  <button
                    onClick={testCapturePhoto}
                    className="bg-green-500 hover:bg-green-600 text-white px-4 py-2 rounded text-sm transition-colors"
                  >
                    Take Photo
                  </button>
                  <button
                    onClick={testSelectFromGallery}
                    className="bg-green-500 hover:bg-green-600 text-white px-4 py-2 rounded text-sm transition-colors"
                  >
                    Select from Gallery
                  </button>
                </div>
              </div>

              {/* Scanner */}
              <div className="border-b pb-3">
                <h3 className="font-medium text-gray-700 mb-2">🔍 Scanner</h3>
                <div className="flex gap-2 flex-wrap">
                  <button
                    onClick={testScanQR}
                    className="bg-purple-500 hover:bg-purple-600 text-white px-4 py-2 rounded text-sm transition-colors"
                  >
                    Scan QR Code
                  </button>
                  <button
                    onClick={testScanBarcode}
                    className="bg-purple-500 hover:bg-purple-600 text-white px-4 py-2 rounded text-sm transition-colors"
                  >
                    Scan Barcode
                  </button>
                </div>
              </div>

              {/* Phone */}
              <div className="border-b pb-3">
                <h3 className="font-medium text-gray-700 mb-2">☎️ Phone Functions</h3>
                <div className="flex gap-2 flex-wrap">
                  <button
                    onClick={testMakeCall}
                    className="bg-red-500 hover:bg-red-600 text-white px-4 py-2 rounded text-sm transition-colors"
                  >
                    Make Call
                  </button>
                  <button
                    onClick={testGetCallLogs}
                    className="bg-red-500 hover:bg-red-600 text-white px-4 py-2 rounded text-sm transition-colors"
                  >
                    Get Call Logs
                  </button>
                  <button
                    onClick={testGetContacts}
                    className="bg-red-500 hover:bg-red-600 text-white px-4 py-2 rounded text-sm transition-colors"
                  >
                    Get Contacts
                  </button>
                  
                </div>
              </div>

              {/* Files */}
              <div className="border-b pb-3">
                <h3 className="font-medium text-gray-700 mb-2">📁 File Management</h3>
                <div className="flex gap-2 flex-wrap">
                  <button
                    onClick={testUploadFile}
                    className="bg-indigo-500 hover:bg-indigo-600 text-white px-4 py-2 rounded text-sm transition-colors"
                  >
                    Upload Test File
                  </button>
                  <button
                    onClick={testDownloadFile}
                    className="bg-indigo-500 hover:bg-indigo-600 text-white px-4 py-2 rounded text-sm transition-colors"
                  >
                    Download File
                  </button>
                </div>
              </div>

              {/* Storage */}
              <div className="border-b pb-3">
                <h3 className="font-medium text-gray-700 mb-2">💾 Local Storage</h3>
                <div className="flex gap-2 flex-wrap">
                  <button
                    onClick={testStorageSet}
                    className="bg-orange-500 hover:bg-orange-600 text-white px-4 py-2 rounded text-sm transition-colors"
                  >
                    Set Storage Data
                  </button>
                  <button
                    onClick={testStorageGet}
                    className="bg-orange-500 hover:bg-orange-600 text-white px-4 py-2 rounded text-sm transition-colors"
                  >
                    Get Storage Data
                  </button>
                </div>
              </div>

              {/* System */}
              <div>
                <h3 className="font-medium text-gray-700 mb-2">⚙️ System Functions</h3>
                <div className="flex gap-2 flex-wrap">
                  <button
                    onClick={testGetDeviceInfo}
                    className="bg-gray-500 hover:bg-gray-600 text-white px-4 py-2 rounded text-sm transition-colors"
                  >
                    Get Device Info
                  </button>
                  <button
                    onClick={testGetNetworkStatus}
                    className="bg-gray-500 hover:bg-gray-600 text-white px-4 py-2 rounded text-sm transition-colors"
                  >
                    Network Status
                  </button>
                  <button
                    onClick={testShowToast}
                    className="bg-gray-500 hover:bg-gray-600 text-white px-4 py-2 rounded text-sm transition-colors"
                  >
                    Show Toast
                  </button>
                </div>
              </div>
            </div>
          </div>

          {/* Logs Panel */}
          <div className="bg-white rounded-lg shadow-md p-6">
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-xl font-semibold text-gray-800">Activity Logs</h2>
              <button
                onClick={clearLogs}
                className="bg-gray-500 hover:bg-gray-600 text-white px-3 py-1 rounded text-sm transition-colors"
              >
                Clear Logs
              </button>
            </div>
            
            <div className="bg-gray-50 rounded-lg p-4 h-96 overflow-y-auto">
              {logs.length === 0 ? (
                <p className="text-gray-500 text-center">No logs yet. Click a test button to start.</p>
              ) : (
                <div className="space-y-2">
                  {logs.map((log, index) => (
                    <div key={index} className="text-sm">
                      <div className="flex items-start gap-2">
                        <span className="text-gray-500 text-xs font-mono">
                          {log.timestamp}
                        </span>
                        <span className={`px-2 py-1 rounded text-xs font-medium ${
                          log.type === 'success' ? 'bg-green-100 text-green-800' :
                          log.type === 'error' ? 'bg-red-100 text-red-800' :
                          log.type === 'warning' ? 'bg-yellow-100 text-yellow-800' :
                          'bg-blue-100 text-blue-800'
                        }`}>
                          {log.type.toUpperCase()}
                        </span>
                      </div>
                      <pre className="mt-1 text-gray-700 whitespace-pre-wrap break-words">
                        {log.message}
                      </pre>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        </div>

        {/* Instructions */}
        <div className="bg-blue-50 border-l-4 border-blue-400 p-4 mt-6 rounded">
          <div className="flex">
            <div className="ml-3">
              <p className="text-sm text-blue-700">
                <strong>Instructions:</strong> This page tests all native functions. 
                When running in a native app, click the buttons to test each function. 
                Responses will appear in the Activity Logs panel. 
                When running in a browser, you'll see "No native bridge found" messages.
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default NativeFunctionsTest;