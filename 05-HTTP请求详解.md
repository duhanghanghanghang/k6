# 第5章：HTTP 请求详解

## 5.1 GET 请求

### 基本 GET 请求

```javascript
import http from 'k6/http';

export default function () {
  const response = http.get('https://api.example.com/users');
  console.log('Status:', response.status);
  console.log('Body:', response.body);
}
```

### 带查询参数的 GET 请求

```javascript
// 方法 1：URL 中直接拼接
const response = http.get('https://api.example.com/users?page=1&limit=10');

// 方法 2：使用 params 对象
const params = {
  page: 1,
  limit: 10,
  sort: 'created_at',
};
const response = http.get('https://api.example.com/users', { params: params });
```

### 带请求头的 GET 请求

```javascript
const headers = {
  'Authorization': 'Bearer token123',
  'Content-Type': 'application/json',
  'User-Agent': 'k6-test',
};

const response = http.get('https://api.example.com/users', { headers: headers });
```

### 带标签的 GET 请求

```javascript
const response = http.get('https://api.example.com/users', {
  tags: {
    name: 'GetUsers',
    endpoint: '/users',
    method: 'GET',
  },
});
```

## 5.2 POST 请求

### 基本 POST 请求

```javascript
const payload = JSON.stringify({
  name: 'John Doe',
  email: 'john@example.com',
});

const response = http.post('https://api.example.com/users', payload);
```

### POST JSON 数据

```javascript
const payload = JSON.stringify({
  name: 'John Doe',
  email: 'john@example.com',
});

const headers = {
  'Content-Type': 'application/json',
};

const response = http.post(
  'https://api.example.com/users',
  payload,
  { headers: headers }
);
```

### POST 表单数据

```javascript
const payload = {
  name: 'John Doe',
  email: 'john@example.com',
};

const response = http.post(
  'https://api.example.com/users',
  payload,
  {
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
  }
);
```

### POST 文件上传

```javascript
const fileData = open('./test-file.pdf', 'b'); // 'b' 表示二进制模式

const response = http.post(
  'https://api.example.com/upload',
  fileData,
  {
    headers: {
      'Content-Type': 'application/pdf',
    },
  }
);
```

## 5.3 PUT/PATCH 请求

### PUT 请求（完整更新）

```javascript
const payload = JSON.stringify({
  name: 'Jane Doe',
  email: 'jane@example.com',
});

const response = http.put(
  'https://api.example.com/users/123',
  payload,
  {
    headers: { 'Content-Type': 'application/json' },
  }
);
```

### PATCH 请求（部分更新）

```javascript
const payload = JSON.stringify({
  email: 'newemail@example.com',
});

const response = http.patch(
  'https://api.example.com/users/123',
  payload,
  {
    headers: { 'Content-Type': 'application/json' },
  }
);
```

## 5.4 DELETE 请求

### 基本 DELETE 请求

```javascript
const response = http.del('https://api.example.com/users/123');
console.log('Status:', response.status);
```

### 带请求体的 DELETE 请求

```javascript
const payload = JSON.stringify({
  reason: 'User requested deletion',
});

const response = http.del(
  'https://api.example.com/users/123',
  payload,
  {
    headers: { 'Content-Type': 'application/json' },
  }
);
```

## 5.5 请求头设置

### 常用请求头

```javascript
const headers = {
  'Authorization': 'Bearer your_token_here',
  'Content-Type': 'application/json',
  'Accept': 'application/json',
  'User-Agent': 'k6-performance-test/1.0',
  'X-Request-ID': 'unique-request-id',
  'X-API-Key': 'your-api-key',
};

const response = http.get('https://api.example.com/data', { headers: headers });
```

### 动态请求头

```javascript
export default function () {
  const timestamp = Date.now();
  const headers = {
    'X-Timestamp': timestamp.toString(),
    'X-Request-ID': `req-${__VU}-${__ITER}`,
  };
  
  const response = http.get('https://api.example.com/data', { headers: headers });
}
```

## 5.6 请求体处理

### JSON 请求体

```javascript
const payload = JSON.stringify({
  name: 'John Doe',
  age: 30,
  email: 'john@example.com',
});

const response = http.post(
  'https://api.example.com/users',
  payload,
  {
    headers: { 'Content-Type': 'application/json' },
  }
);
```

### 表单请求体

```javascript
const payload = {
  username: 'john',
  password: 'secret123',
};

const response = http.post(
  'https://api.example.com/login',
  payload,
  {
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
  }
);
```

### 原始字符串请求体

```javascript
const payload = 'raw string data';

const response = http.post(
  'https://api.example.com/data',
  payload,
  {
    headers: { 'Content-Type': 'text/plain' },
  }
);
```

## 5.7 Cookie 管理

### 自动 Cookie 管理

```javascript
// 登录后 Cookie 自动保存
const loginResponse = http.post('https://api.example.com/login', {
  username: 'user',
  password: 'pass',
});

// 后续请求自动携带 Cookie
const profileResponse = http.get('https://api.example.com/profile');
```

### 手动设置 Cookie

```javascript
const cookies = {
  session_id: 'abc123',
  csrf_token: 'xyz789',
};

const response = http.get('https://api.example.com/data', {
  cookies: cookies,
});
```

### Cookie Jar 管理

```javascript
import { CookieJar } from 'k6/http';

const jar = new CookieJar();

jar.set('https://api.example.com', 'session_id', 'abc123');

const response = http.get('https://api.example.com/data', {
  jar: jar,
});
```

## 5.8 会话保持

### 使用 Cookie 保持会话

```javascript
export default function () {
  // 登录
  const loginRes = http.post('https://api.example.com/login', {
    username: 'user',
    password: 'pass',
  });
  
  // Cookie 自动保存，后续请求自动携带
  const profileRes = http.get('https://api.example.com/profile');
  const ordersRes = http.get('https://api.example.com/orders');
}
```

### 使用 Token 保持会话

```javascript
export default function () {
  // 登录获取 Token
  const loginRes = http.post('https://api.example.com/login', {
    username: 'user',
    password: 'pass',
  });
  
  const token = JSON.parse(loginRes.body).token;
  
  // 使用 Token 访问受保护资源
  const headers = {
    'Authorization': `Bearer ${token}`,
  };
  
  const profileRes = http.get('https://api.example.com/profile', { headers: headers });
  const ordersRes = http.get('https://api.example.com/orders', { headers: headers });
}
```

## 5.9 批量请求

### 使用 batch() 函数

```javascript
const responses = http.batch([
  ['GET', 'https://api.example.com/users'],
  ['GET', 'https://api.example.com/posts'],
  ['GET', 'https://api.example.com/comments'],
]);

console.log('Users:', responses[0].status);
console.log('Posts:', responses[1].status);
console.log('Comments:', responses[2].status);
```

### 带参数的批量请求

```javascript
const requests = [
  {
    method: 'GET',
    url: 'https://api.example.com/users/1',
  },
  {
    method: 'GET',
    url: 'https://api.example.com/users/2',
  },
  {
    method: 'POST',
    url: 'https://api.example.com/users',
    body: JSON.stringify({ name: 'New User' }),
    params: { headers: { 'Content-Type': 'application/json' } },
  },
];

const responses = http.batch(requests);
```

## 5.10 请求超时设置

### 全局超时设置

```javascript
export const options = {
  vus: 10,
  duration: '30s',
  httpReq: {
    timeout: '10s', // 10 秒超时
  },
};

export default function () {
  const response = http.get('https://api.example.com');
}
```

### 单个请求超时设置

```javascript
const response = http.get('https://api.example.com', {
  timeout: '5s', // 5 秒超时
});
```

### 超时处理

```javascript
export default function () {
  try {
    const response = http.get('https://api.example.com', {
      timeout: '5s',
    });
    
    if (response.status === 0) {
      console.error('Request timeout');
    }
  } catch (error) {
    console.error('Error:', error.message);
  }
}
```

## 5.11 重试机制

### 手动重试

```javascript
function httpGetWithRetry(url, maxRetries = 3) {
  for (let i = 0; i < maxRetries; i++) {
    const response = http.get(url);
    
    if (response.status === 200) {
      return response;
    }
    
    if (i < maxRetries - 1) {
      sleep(Math.pow(2, i)); // 指数退避：1s, 2s, 4s
    }
  }
  
  return null;
}

export default function () {
  const response = httpGetWithRetry('https://api.example.com/data');
  if (!response) {
    console.error('All retries failed');
  }
}
```

### 条件重试

```javascript
function httpGetWithConditionalRetry(url) {
  let retries = 0;
  const maxRetries = 3;
  
  while (retries < maxRetries) {
    const response = http.get(url);
    
    // 只在 5xx 错误时重试
    if (response.status >= 500 && response.status < 600) {
      retries++;
      if (retries < maxRetries) {
        sleep(1);
        continue;
      }
    }
    
    return response;
  }
  
  return null;
}
```

## 5.12 响应处理

### 响应对象结构

```javascript
const response = http.get('https://api.example.com/users');

// 响应属性
console.log('Status:', response.status);           // 状态码
console.log('Status Text:', response.status_text); // 状态文本
console.log('Body:', response.body);               // 响应体（字符串）
console.log('Headers:', response.headers);         // 响应头
console.log('Cookies:', response.cookies);         // Cookie

// 时间信息
console.log('Duration:', response.timings.duration);      // 总时间
console.log('Waiting:', response.timings.waiting);        // 等待时间
console.log('Connecting:', response.timings.connecting); // 连接时间
console.log('Sending:', response.timings.sending);       // 发送时间
console.log('Receiving:', response.timings.receiving);   // 接收时间
```

### JSON 响应解析

```javascript
const response = http.get('https://api.example.com/users');

try {
  const data = JSON.parse(response.body);
  console.log('Users:', data.users);
  console.log('Total:', data.total);
} catch (e) {
  console.error('JSON parse error:', e);
}
```

### 响应头处理

```javascript
const response = http.get('https://api.example.com/data');

// 获取特定响应头
const contentType = response.headers['Content-Type'];
const etag = response.headers['ETag'];

console.log('Content-Type:', contentType);
console.log('ETag:', etag);
```

## 5.13 HTTP/2 支持

### 启用 HTTP/2

```javascript
export const options = {
  vus: 10,
  duration: '30s',
  httpReq: {
    http2: true, // 启用 HTTP/2
  },
};

export default function () {
  const response = http.get('https://api.example.com');
}
```

## 5.14 最佳实践

### 1. 使用标签

```javascript
http.get('https://api.example.com/users', {
  tags: { name: 'GetUsers', endpoint: '/users' },
});
```

### 2. 错误处理

```javascript
const response = http.get('https://api.example.com/users');

if (response.status !== 200) {
  console.error(`Request failed: ${response.status}`);
  return;
}

try {
  const data = JSON.parse(response.body);
  // 处理数据
} catch (e) {
  console.error('Parse error:', e);
}
```

### 3. 请求复用

```javascript
// 使用批处理减少网络往返
const responses = http.batch([
  ['GET', 'https://api.example.com/users'],
  ['GET', 'https://api.example.com/posts'],
]);
```

### 4. 超时设置

```javascript
// 合理设置超时时间
const response = http.get('https://api.example.com', {
  timeout: '10s',
});
```

## 5.15 总结

k6 的 HTTP 请求功能非常强大：

✅ **支持所有 HTTP 方法**：GET、POST、PUT、PATCH、DELETE  
✅ **灵活的请求配置**：请求头、Cookie、超时等  
✅ **自动会话管理**：Cookie 自动保存和携带  
✅ **批量请求支持**：提高测试效率  
✅ **完善的响应处理**：状态码、响应体、时间信息等  

掌握这些 HTTP 请求功能，就可以编写各种复杂的测试场景了！

---

**下一章**：[第6章：测试场景配置](./06-测试场景配置.md)

