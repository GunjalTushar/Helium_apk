# Helium Public API Documentation

**Base URL:** `https://api.he2.ai`

## 🚀 Quick Start

Helium is an AI-powered platform that creates websites, apps, images, videos, and more using natural language. This guide shows you how to use the Public API.

### Get Your API Key

1. Visit [https://app.he2.ai](https://app.he2.ai) and sign up
2. Go to Settings → API Keys
3. Create a new API key (format: `he-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`)
4. Keep it secure - never share or commit to code

### Your First API Call

```bash
curl -X POST "https://api.he2.ai/api/v1/public/quick-action" \
  -H "X-API-Key: he-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" \
  -F "prompt=Create a simple hello world website"
```

**Response:**
```json
{
  "success": true,
  "project_id": "proj_abc123",
  "thread_id": "thread_xyz789",
  "agent_run_id": "run_123456",
  "message": "Task created and execution started"
}
```

### Get Results

```bash
curl -X GET "https://api.he2.ai/api/v1/public/threads/thread_xyz789/response?project_id=proj_abc123" \
  -H "X-API-Key: he-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

---

## 📋 Table of Contents


- [Authentication](#authentication)
- [API Endpoints](#api-endpoints)
- [Rate Limits](#rate-limits)
- [Error Handling](#error-handling)
- [Code Examples](#code-examples)
- [Best Practices](#best-practices)

---

## 🔐 Authentication

Include your API key in every request:

```bash
-H "X-API-Key: he-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

**Alternative:** Use JWT tokens for web applications:
```bash
-H "Authorization: Bearer <jwt_token>"
```

---

## 📡 API Endpoints

### 1. Create Task (Quick Action)

**POST** `/api/v1/public/quick-action`

Creates and executes a task immediately using FormData.

**Request (FormData):**
```bash
curl -X POST "https://api.he2.ai/api/v1/public/quick-action" \
  -H "X-API-Key: he-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" \
  -F "prompt=Create a portfolio website with dark mode" \
  -F "source=web" \
  -F "enable_thinking=false" \
  -F "show_in_recent_tasks=true"
```

**Parameters:**
- `prompt` (optional): Task description (1-5000 characters). Required if no files provided
- `agent_id` (optional): Specific agent to use
- `model_name` (optional): Model override
- `enable_thinking` (optional): Enable thinking mode (default: false)
- `reasoning_effort` (optional): "low", "medium", or "high" (default: "low")
- `enable_context_manager` (optional): Enable context manager (default: false)
- `source` (optional): Source platform ("web", "mobile", "widget")
- `metadata` (optional): Additional metadata as JSON string
- `show_in_recent_tasks` (optional): Show task in recent tasks list (default: true)
- `files` (optional): File uploads (see File Uploads section below)

**Query Parameters:**
- `show_in_recent_tasks` (optional): Overrides body parameter if provided (default: true)

**Response:**
```json
{
  "success": true,
  "project_id": "proj_123",
  "thread_id": "thread_456",
  "agent_run_id": "run_789",
  "message": "Task created and execution started"
}
```

**File Uploads:**

You can upload files with your request using `multipart/form-data`:

```bash
curl -X POST "https://api.he2.ai/api/v1/public/quick-action" \
  -H "X-API-Key: he-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" \
  -F "prompt=Analyze this image and create a website" \
  -F "files=@/path/to/image.png" \
  -F "source=web"
```

**Supported Files:**
- Images: .png, .jpg, .jpeg, .gif, .svg, .webp
- Documents: .pdf, .docx, .xlsx, .pptx, .csv
- Text: .txt, .json, .xml, .md
- Audio: .mp3, .wav, .flac, .aac
- Archives: .zip, .rar, .7z

**Limits:**
- Max 10 files per request
- Max 50MB per file
- Max 200MB total

---

### 2. Get Task Results

**GET** `/api/v1/public/threads/{thread_id}/response`

Fetches results from a completed or running task.

**Request:**
```bash
curl -X GET "https://api.he2.ai/api/v1/public/threads/thread_456/response?project_id=proj_123&timeout=300" \
  -H "X-API-Key: he-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

**Parameters:**
- `project_id` (required): Project ID from quick action response
- `timeout` (optional): Max wait time in seconds (0-600, default: 300)
- `realtime` (optional): Enable WebSocket-based streaming (default: false)
- `include_file_content` (optional): Include file content inline (default: false)
- `page` (optional): Page number for pagination (default: 1)
- `page_size` (optional): Items per page (1-1000, default: 100)

**Response:**
```json
{
  "success": true,
  "thread_id": "thread_456",
  "project_id": "proj_123",
  "agent_run_id": "run_789",
  "status": "completed",
  "response": {
    "role": "assistant",
    "content": "Here is your website...",
    "message_id": "msg_1"
  },
  "has_code": true,
  "has_files": true,
  "code_blocks": [
    {
      "language": "html",
      "code": "<!DOCTYPE html>..."
    }
  ],
  "files": [
    {
      "file_id": "file_1",
      "file_name": "index.html",
      "file_size": 2048,
      "included_inline": true,
      "content": "<!DOCTYPE html>...",
      "encoding": "utf-8"
    }
  ]
}
```

**Status Values:**
- `completed`: Task finished successfully
- `running`: Task still in progress
- `failed`: Task encountered an error
- `stopped`: Task was manually stopped
- `no_run`: No task exists for this thread

**Real-Time Streaming:**

Get live updates as the AI works using WebSocket-based streaming:

```bash
curl -X GET "https://api.he2.ai/api/v1/public/threads/thread_456/response?project_id=proj_123&realtime=true" \
  -H "X-API-Key: he-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

Stream events:
```
data: {"type": "status", "status": "running"}
data: {"type": "content", "content": "First chunk..."}
data: {"type": "status", "status": "completed"}
```

---

### 3. Continue Conversation (Follow-up)

**POST** `/api/v1/public/threads/{thread_id}/response`

Add a follow-up message to an existing conversation using FormData.

**Request (FormData):**
```bash
curl -X POST "https://api.he2.ai/api/v1/public/threads/thread_456/response?project_id=proj_123" \
  -H "X-API-Key: he-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" \
  -F "prompt=Add a contact form to the website"
```

**Parameters:**
- `project_id` (required): Project ID (query parameter)
- `prompt` (optional): Follow-up message (1-5000 characters). Required if no files provided
- `files` (optional): File uploads

**Response:**
```json
{
  "success": true,
  "agent_run_id": "run_123",
  "status": "running",
  "message": "Follow-up accepted"
}
```

**With Files:**
```bash
curl -X POST "https://api.he2.ai/api/v1/public/threads/thread_456/response?project_id=proj_123" \
  -H "X-API-Key: he-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" \
  -F "prompt=Analyze this additional file" \
  -F "files=@/path/to/document.pdf"
```

---

### 4. Stop Agent

**POST** `/api/v1/public/threads/{thread_id}/agent/stop`

Stop a running task.

**Request:**
```bash
curl -X POST "https://api.he2.ai/api/v1/public/threads/thread_456/agent/stop?project_id=proj_123" \
  -H "X-API-Key: he-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

**Response:**
```json
{
  "success": true,
  "agent_run_id": "run_123",
  "status": "stopped"
}
```

---

### 5. Get Conversation History

**GET** `/api/v1/public/threads/{thread_id}/history`

Retrieve the complete conversation history.

**Request:**
```bash
curl -X GET "https://api.he2.ai/api/v1/public/threads/thread_456/history?project_id=proj_123&page=1&page_size=50" \
  -H "X-API-Key: he-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

**Parameters:**
- `project_id` (required): Project ID
- `page` (optional): Page number (default: 1)
- `page_size` (optional): Messages per page (1-1000, default: 100)
- `include_file_content` (optional): Include file content (default: false)
- `include_status_messages` (optional): Include status messages (default: false)
- `compact` (optional): Return minimal fields (default: false)

**Response:**
```json
{
  "success": true,
  "thread_id": "thread_456",
  "messages": [
    {
      "message_id": "msg_1",
      "role": "user",
      "content": "Create a website",
      "created_at": "2024-01-01T10:00:00Z"
    },
    {
      "message_id": "msg_2",
      "role": "assistant",
      "content": "Here is your website...",
      "created_at": "2024-01-01T10:00:30Z",
      "has_code": true,
      "has_files": true
    }
  ],
  "pagination": {
    "current_page": 1,
    "total_pages": 1,
    "has_next": false
  }
}
```

---

### 6. List Thread Files

**GET** `/api/v1/public/threads/{thread_id}/files`

Get a list of all files generated in a thread.

**Request:**
```bash
curl -X GET "https://api.he2.ai/api/v1/public/threads/thread_456/files?project_id=proj_123" \
  -H "X-API-Key: he-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

**Response:**
```json
{
  "success": true,
  "files": [
    {
      "file_id": "file_1",
      "file_name": "index.html",
      "file_size": 2048,
      "file_type": "text/html"
    }
  ],
  "pagination": {
    "current_page": 1,
    "total_items": 1
  }
}
```

---

### 7. Get File Content

**GET** `/api/v1/public/files/{file_id}`

Download a specific file.

**Request (JSON with metadata):**
```bash
curl -X GET "https://api.he2.ai/api/v1/public/files/thread_456:/workspace/index.html?project_id=proj_123&thread_id=thread_456" \
  -H "X-API-Key: he-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

**Request (Raw download):**
```bash
curl -X GET "https://api.he2.ai/api/v1/public/files/thread_456:/workspace/index.html?project_id=proj_123&thread_id=thread_456&download=true" \
  -H "X-API-Key: he-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" \
  --output index.html"
```

**Parameters:**
- `project_id` (required): Project ID
- `thread_id` (required): Thread ID
- `download` (optional): Return raw bytes if true (default: false)

**Response (JSON):**
```json
{
  "success": true,
  "file": {
    "file_id": "thread_456:/workspace/index.html",
    "file_name": "index.html",
    "file_size": 2048,
    "file_type": "text/html",
    "included_inline": true,
    "content": "<!DOCTYPE html>...",
    "encoding": "utf-8"
  }
}
```

---

## ⚡ Rate Limits

| Tier | Requests/Hour |
|------|---------------|
| Free | 100 |
| Pro | 10,000 |
| Enterprise | Custom |

**Rate Limit Headers:**
```
X-RateLimit-Limit: 10000
X-RateLimit-Remaining: 9995
X-RateLimit-Reset: 1640995200
```

---

## 🚨 Error Handling

### HTTP Status Codes

| Code | Meaning | Action |
|------|---------|--------|
| 200 | Success | Process response |
| 400 | Bad Request | Check parameters |
| 401 | Unauthorized | Verify API key |
| 402 | Payment Required | Check billing/credits |
| 404 | Not Found | Check IDs |
| 422 | Validation Error | Fix input format |
| 429 | Rate Limited | Wait and retry |
| 500 | Server Error | Retry later |

### Error Response Format

```json
{
  "detail": "Error message describing the issue"
}
```

### Handling Rate Limits

```python
import time
import requests

def make_request_with_retry(url, headers, max_retries=3):
    for attempt in range(max_retries):
        response = requests.get(url, headers=headers)
        
        if response.status_code == 429:
            reset_time = int(response.headers.get('X-RateLimit-Reset', 0))
            wait_time = max(60, reset_time - time.time())
            print(f"Rate limited. Waiting {wait_time}s...")
            time.sleep(wait_time)
            continue
            
        return response
    
    raise Exception("Max retries exceeded")
```

---

## 💻 Code Examples

### Python

```python
import requests
import time

class HeliumAPI:
    def __init__(self, api_key):
        self.api_key = api_key
        self.base_url = "https://api.he2.ai"
        self.headers = {
            "X-API-Key": api_key
        }
    
    def create_task(self, prompt):
        """Create and start a new task"""
        response = requests.post(
            f"{self.base_url}/api/v1/public/quick-action",
            data={"prompt": prompt},
            headers=self.headers
        )
        response.raise_for_status()
        return response.json()
    
    def get_results(self, thread_id, project_id, timeout=300):
        """Get task results"""
        response = requests.get(
            f"{self.base_url}/api/v1/public/threads/{thread_id}/response",
            params={"project_id": project_id, "timeout": timeout},
            headers=self.headers
        )
        response.raise_for_status()
        return response.json()
    
    def create_website(self, description):
        """Complete workflow: create and get results"""
        # Create task
        task = self.create_task(description)
        print(f"Task created: {task['thread_id']}")
        
        # Get results
        results = self.get_results(task['thread_id'], task['project_id'])
        
        if results['status'] == 'completed':
            print("✅ Task completed!")
            return results
        else:
            print(f"Status: {results['status']}")
            return results

# Usage
api = HeliumAPI("he-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx")
results = api.create_website("Build a modern blog website")
```

### JavaScript/Node.js

```javascript
const fetch = require('node-fetch');

class HeliumAPI {
    constructor(apiKey) {
        this.apiKey = apiKey;
        this.baseUrl = 'https://api.he2.ai';
        this.headers = {
            'X-API-Key': apiKey
        };
    }
    
    async createTask(prompt) {
        const formData = new FormData();
        formData.append('prompt', prompt);
        
        const response = await fetch(`${this.baseUrl}/api/v1/public/quick-action`, {
            method: 'POST',
            headers: this.headers,
            body: formData
        });
        
        if (!response.ok) {
            throw new Error(`API Error: ${response.status}`);
        }
        
        return await response.json();
    }
    
    async getResults(threadId, projectId, timeout = 300) {
        const url = new URL(`${this.baseUrl}/api/v1/public/threads/${threadId}/response`);
        url.searchParams.set('project_id', projectId);
        url.searchParams.set('timeout', timeout);
        
        const response = await fetch(url, {
            method: 'GET',
            headers: this.headers
        });
        
        if (!response.ok) {
            throw new Error(`API Error: ${response.status}`);
        }
        
        return await response.json();
    }
    
    async createWebsite(description) {
        console.log(`Creating: ${description}`);
        
        // Create task
        const task = await this.createTask(description);
        console.log(`Task started: ${task.thread_id}`);
        
        // Get results
        const results = await this.getResults(task.thread_id, task.project_id);
        
        if (results.status === 'completed') {
            console.log('✅ Task completed!');
            return results;
        } else {
            console.log(`Status: ${results.status}`);
            return results;
        }
    }
}

// Usage
const api = new HeliumAPI('he-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx');
api.createWebsite('Create a restaurant website with online reservations')
    .then(results => console.log('Success!', results))
    .catch(error => console.error('Error:', error));
```

### React (Web Widget)

```jsx
import React, { useState } from 'react';

function HeliumWidget() {
    const [prompt, setPrompt] = useState('');
    const [loading, setLoading] = useState(false);
    const [result, setResult] = useState(null);
    
    const API_KEY = 'he-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';
    const BASE_URL = 'https://api.he2.ai';
    
    const handleSubmit = async (e) => {
        e.preventDefault();
        if (!prompt.trim()) return;
        
        setLoading(true);
        
        try {
            // Create task
            const formData = new FormData();
            formData.append('prompt', prompt);
            formData.append('source', 'web_widget');
            
            const taskResponse = await fetch(`${BASE_URL}/api/v1/public/quick-action`, {
                method: 'POST',
                headers: {
                    'X-API-Key': API_KEY
                },
                body: formData
            });
            
            const taskData = await taskResponse.json();
            
            // Get results
            const resultsResponse = await fetch(
                `${BASE_URL}/api/v1/public/threads/${taskData.thread_id}/response?project_id=${taskData.project_id}&timeout=300`,
                { headers: { 'X-API-Key': API_KEY } }
            );
            
            const resultsData = await resultsResponse.json();
            setResult(resultsData);
            
        } catch (err) {
            console.error('Error:', err);
        } finally {
            setLoading(false);
        }
    };
    
    return (
        <div style={{ maxWidth: '600px', margin: '0 auto', padding: '20px' }}>
            <h2>Helium AI Builder</h2>
            
            <form onSubmit={handleSubmit}>
                <textarea
                    value={prompt}
                    onChange={(e) => setPrompt(e.target.value)}
                    placeholder="Describe what you want to build..."
                    rows={4}
                    style={{ width: '100%', padding: '10px' }}
                    disabled={loading}
                />
                
                <button
                    type="submit"
                    disabled={loading || !prompt.trim()}
                    style={{
                        padding: '10px 20px',
                        backgroundColor: loading ? '#ccc' : '#007bff',
                        color: 'white',
                        border: 'none',
                        borderRadius: '5px',
                        cursor: loading ? 'not-allowed' : 'pointer'
                    }}
                >
                    {loading ? 'Building...' : 'Build It!'}
                </button>
            </form>
            
            {result && result.status === 'completed' && (
                <div style={{ marginTop: '20px' }}>
                    <h3>✅ Project Created!</h3>
                    <p>Files: {result.files?.length || 0}</p>
                </div>
            )}
        </div>
    );
}

export default HeliumWidget;
```

### React Native (Mobile App)

```jsx
import React, { useState } from 'react';
import { View, Text, TextInput, TouchableOpacity, ScrollView, Alert } from 'react-native';

const HeliumMobileApp = () => {
    const [prompt, setPrompt] = useState('');
    const [loading, setLoading] = useState(false);
    const [result, setResult] = useState(null);
    
    const API_KEY = 'he-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx';
    const BASE_URL = 'https://api.he2.ai';
    
    const createProject = async () => {
        if (!prompt.trim()) {
            Alert.alert('Error', 'Please describe what you want to build');
            return;
        }
        
        setLoading(true);
        
        try {
            // Create task
            const formData = new FormData();
            formData.append('prompt', prompt);
            formData.append('source', 'mobile_app');
            formData.append('metadata', JSON.stringify({ platform: 'ios' }));
            
            const taskResponse = await fetch(`${BASE_URL}/api/v1/public/quick-action`, {
                method: 'POST',
                headers: {
                    'X-API-Key': API_KEY
                },
                body: formData
            });
            
            const taskData = await taskResponse.json();
            
            // Get results
            const resultsResponse = await fetch(
                `${BASE_URL}/api/v1/public/threads/${taskData.thread_id}/response?project_id=${taskData.project_id}&timeout=300`,
                { headers: { 'X-API-Key': API_KEY } }
            );
            
            const resultsData = await resultsResponse.json();
            
            if (resultsData.status === 'completed') {
                setResult(resultsData);
                Alert.alert('Success!', `Created ${resultsData.files?.length || 0} files`);
            }
            
        } catch (error) {
            Alert.alert('Error', error.message);
        } finally {
            setLoading(false);
        }
    };
    
    return (
        <ScrollView style={{ flex: 1, padding: 20 }}>
            <Text style={{ fontSize: 24, fontWeight: 'bold', marginBottom: 20 }}>
                Helium AI Builder
            </Text>
            
            <TextInput
                style={{
                    borderWidth: 1,
                    borderColor: '#ccc',
                    borderRadius: 8,
                    padding: 12,
                    marginBottom: 16,
                    height: 100
                }}
                placeholder="What do you want to build?"
                value={prompt}
                onChangeText={setPrompt}
                multiline
                editable={!loading}
            />
            
            <TouchableOpacity
                style={{
                    backgroundColor: loading ? '#ccc' : '#007bff',
                    padding: 16,
                    borderRadius: 8,
                    alignItems: 'center'
                }}
                onPress={createProject}
                disabled={loading}
            >
                <Text style={{ color: 'white', fontSize: 16, fontWeight: 'bold' }}>
                    {loading ? 'Building...' : 'Build It!'}
                </Text>
            </TouchableOpacity>
            
            {result && (
                <View style={{ marginTop: 20 }}>
                    <Text style={{ fontSize: 18, fontWeight: 'bold' }}>
                        Project Created! 🎉
                    </Text>
                    <Text>Files: {result.files?.length || 0}</Text>
                </View>
            )}
        </ScrollView>
    );
};

export default HeliumMobileApp;
```

---

## 💡 Best Practices

### 1. Write Clear Prompts

**Good:**
```
"Create a React Native mobile app for tracking daily water intake"
```

**Better:**
```
"Build a React Native water tracking app with:
- Daily water intake logging
- Progress visualization with charts
- Local storage for offline use
- Push notifications for reminders
- Material Design UI
- iOS and Android support"
```

### 2. Handle Files Efficiently

```python
import base64
import os

def save_files(results):
    """Save generated files to disk"""
    os.makedirs("generated_files", exist_ok=True)
    
    for file_info in results.get('files', []):
        filename = file_info['file_name']
        filepath = f"generated_files/{filename}"
        
        if file_info['included_inline']:
            # File content is included
            if file_info['encoding'] == 'utf-8':
                # Text file
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(file_info['content'])
            else:
                # Binary file (base64)
                with open(filepath, 'wb') as f:
                    f.write(base64.b64decode(file_info['content']))
        else:
            # Download from URL
            import requests
            response = requests.get(file_info['download_url'])
            with open(filepath, 'wb') as f:
                f.write(response.content)
        
        print(f"✅ Saved: {filename}")
```

### 3. Monitor Progress

```python
def wait_for_completion(thread_id, project_id, max_minutes=10):
    """Wait for task completion with progress updates"""
    import time
    
    start_time = time.time()
    max_seconds = max_minutes * 60
    
    while time.time() - start_time < max_seconds:
        results = get_results(thread_id, project_id, timeout=30)
        
        if results['status'] == 'completed':
            print("✅ Task completed!")
            return results
        elif results['status'] == 'failed':
            print("❌ Task failed!")
            return results
        elif results['status'] == 'running':
            elapsed = int(time.time() - start_time)
            print(f"⏳ Still working... ({elapsed}s)")
            time.sleep(10)
    
    print("⏰ Timeout reached")
    return results
```

### 4. Implement Retry Logic

```python
def robust_request(prompt, max_retries=3):
    """Create task with automatic retry"""
    for attempt in range(max_retries):
        try:
            task = create_task(prompt)
            results = wait_for_completion(
                task['thread_id'],
                task['project_id']
            )
            
            if results['status'] == 'completed':
                return results
            elif attempt < max_retries - 1:
                print(f"Attempt {attempt + 1} failed, retrying...")
                time.sleep(5 * (attempt + 1))
            
        except Exception as e:
            if attempt < max_retries - 1:
                print(f"Error: {e}. Retrying...")
                time.sleep(2 ** attempt)
            else:
                raise e
```

### 5. Use Streaming for Real-Time Updates

```python
import requests
import json

def stream_response(thread_id, project_id):
    """Stream real-time updates"""
    url = f"https://api.he2.ai/api/v1/public/threads/{thread_id}/response"
    params = {
        "project_id": project_id,
        "realtime": "true",
        "timeout": 300
    }
    headers = {"X-API-Key": "he-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"}
    
    response = requests.get(url, params=params, headers=headers, stream=True)
    
    for line in response.iter_lines():
        if line:
            line = line.decode('utf-8')
            if line.startswith('data: '):
                data = json.loads(line[6:])
                print(f"Event: {data.get('type')}")
                
                if data.get('type') == 'content':
                    print(f"Content: {data.get('content')}")
                elif data.get('type') == 'status':
                    print(f"Status: {data.get('status')}")
```

---

## 🔧 Troubleshooting

### "API Key not found" Error

**Problem:** Getting 401 Unauthorized

**Solutions:**
1. Verify API key format: `he-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`
2. Check for extra spaces or characters
3. Ensure key hasn't been revoked
4. Try creating a new API key

### "Rate limit exceeded" Error

**Problem:** Getting 429 Too Many Requests

**Solutions:**
1. Check usage in dashboard
2. Wait for reset time in `X-RateLimit-Reset` header
3. Upgrade plan for higher limits
4. Implement exponential backoff

### Tasks Taking Too Long

**Problem:** Tasks running for extended periods

**Solutions:**
1. Check task status regularly
2. Some tasks (videos) naturally take longer
3. Break complex requests into smaller ones
4. Contact support if task seems stuck

### Missing Files

**Problem:** Expected files not in response

**Solutions:**
1. Verify task status is "completed"
2. Check if files were actually generated
3. Try more specific prompts
4. Use `include_file_content=true` parameter

### Connection Timeouts

**Problem:** Requests timing out

**Solutions:**
1. Increase timeout value (up to 600 seconds)
2. Check internet connection
3. Try during off-peak hours
4. Break large requests into smaller ones

---

## 📞 Support & Resources

### Getting Help

- **Documentation:** This guide
- **Dashboard:** [https://app.he2.ai](https://app.he2.ai)
- **Support:** support@he2.ai
- **Status:** Check for service incidents

### Example Prompts

**Beginner:**
- "Create a simple HTML/CSS personal website"
- "Build a Python calculator script"
- "Make a basic to-do list app"

**Intermediate:**
- "Create a React dashboard with charts"
- "Build a Node.js blog API"
- "Design a habit tracking mobile app"

**Advanced:**
- "Build a full-stack e-commerce site"
- "Create a video editing web app"
- "Develop an AI code review tool"

---

## 🎉 You're Ready!

Start building with Helium Public API:

1. Get your API key from [app.he2.ai](https://app.he2.ai)
2. Try the Quick Start example
3. Explore the code examples
4. Build something amazing!

**Happy building! 🚀**

---

*Last updated: January 2025 | Helium Public API v1.0*
