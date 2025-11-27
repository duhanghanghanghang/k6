# 第11章：WebSocket 测试

## 11.1 WebSocket 连接

### 基本连接

```javascript
import ws from 'k6/ws';
import { check } from 'k6';

export default function () {
  const url = 'wss://echo.websocket.org';
  const params = { tags: { name: 'WebSocket' } };
  
  const response = ws.connect(url, params, function (socket) {
    socket.on('open', function () {
      console.log('WebSocket 连接已建立');
    });
    
    socket.on('close', function () {
      console.log('WebSocket 连接已关闭');
    });
  });
  
  check(response, {
    'WebSocket 连接成功': (r) => r && r.status === 101,
  });
}
```

## 11.2 消息发送与接收

### 发送消息

```javascript
import ws from 'k6/ws';

export default function () {
  const url = 'wss://echo.websocket.org';
  
  ws.connect(url, {}, function (socket) {
    socket.on('open', function () {
      // 发送文本消息
      socket.send('Hello from k6!');
      
      // 发送 JSON 消息
      socket.send(JSON.stringify({
        type: 'message',
        content: 'Hello',
      }));
    });
  });
}
```

### 接收消息

```javascript
import ws from 'k6/ws';

export default function () {
  const url = 'wss://echo.websocket.org';
  
  ws.connect(url, {}, function (socket) {
    socket.on('open', function () {
      socket.send('Hello');
    });
    
    socket.on('message', function (data) {
      console.log('收到消息:', data);
      socket.close();
    });
  });
}
```

## 11.3 事件处理

### 事件类型

```javascript
import ws from 'k6/ws';

export default function () {
  const url = 'wss://echo.websocket.org';
  
  ws.connect(url, {}, function (socket) {
    socket.on('open', function () {
      console.log('连接打开');
    });
    
    socket.on('message', function (data) {
      console.log('收到消息:', data);
    });
    
    socket.on('close', function () {
      console.log('连接关闭');
    });
    
    socket.on('error', function (e) {
      console.error('错误:', e);
    });
    
    socket.on('ping', function () {
      console.log('收到 ping');
    });
    
    socket.on('pong', function () {
      console.log('收到 pong');
    });
  });
}
```

## 11.4 连接管理

### 超时设置

```javascript
import ws from 'k6/ws';

export default function () {
  const url = 'wss://echo.websocket.org';
  
  ws.connect(url, {}, function (socket) {
    socket.setTimeout(function () {
      console.log('连接超时，关闭连接');
      socket.close();
    }, 5000); // 5秒超时
  });
}
```

### 手动关闭

```javascript
import ws from 'k6/ws';

export default function () {
  const url = 'wss://echo.websocket.org';
  
  ws.connect(url, {}, function (socket) {
    socket.on('open', function () {
      socket.send('Hello');
    });
    
    socket.on('message', function (data) {
      console.log('收到:', data);
      socket.close(); // 手动关闭
    });
  });
}
```

## 11.5 实时通信测试场景

### 场景 1：聊天应用测试

```javascript
import ws from 'k6/ws';
import { check } from 'k6';

export const options = {
  vus: 10,
  duration: '30s',
};

export default function () {
  const url = 'wss://chat.example.com/ws';
  
  const response = ws.connect(url, {}, function (socket) {
    socket.on('open', function () {
      // 发送登录消息
      socket.send(JSON.stringify({
        type: 'login',
        username: `user${__VU}`,
      }));
    });
    
    socket.on('message', function (data) {
      const message = JSON.parse(data);
      
      if (message.type === 'login_success') {
        // 发送聊天消息
        socket.send(JSON.stringify({
          type: 'chat',
          message: `Hello from user${__VU}`,
        }));
      }
      
      if (message.type === 'chat') {
        console.log('收到聊天消息:', message.message);
        socket.close();
      }
    });
  });
  
  check(response, {
    'WebSocket 连接成功': (r) => r && r.status === 101,
  });
}
```

### 场景 2：实时数据推送测试

```javascript
import ws from 'k6/ws';
import { check } from 'k6';

export default function () {
  const url = 'wss://api.example.com/realtime';
  
  ws.connect(url, {}, function (socket) {
    let messageCount = 0;
    
    socket.on('open', function () {
      // 订阅数据
      socket.send(JSON.stringify({
        action: 'subscribe',
        channel: 'updates',
      }));
    });
    
    socket.on('message', function (data) {
      messageCount++;
      const update = JSON.parse(data);
      
      check(update, {
        '数据格式正确': (u) => u.timestamp && u.data !== undefined,
      });
      
      if (messageCount >= 10) {
        socket.close();
      }
    });
    
    socket.setTimeout(function () {
      socket.close();
    }, 30000); // 30秒超时
  });
}
```

### 场景 3：心跳检测

```javascript
import ws from 'k6/ws';

export default function () {
  const url = 'wss://api.example.com/ws';
  
  ws.connect(url, {}, function (socket) {
    socket.on('open', function () {
      // 定期发送心跳
      const heartbeat = setInterval(function () {
        socket.ping();
      }, 5000);
      
      socket.on('pong', function () {
        console.log('收到 pong，连接正常');
      });
      
      socket.on('close', function () {
        clearInterval(heartbeat);
      });
    });
  });
}
```

## 11.6 性能测试配置

### 并发连接测试

```javascript
import ws from 'k6/ws';

export const options = {
  stages: [
    { duration: '30s', target: 100 },  // 100个并发连接
    { duration: '1m', target: 100 },
    { duration: '30s', target: 0 },
  ],
};

export default function () {
  const url = 'wss://api.example.com/ws';
  
  ws.connect(url, {}, function (socket) {
    socket.on('open', function () {
      socket.send('test message');
    });
    
    socket.on('message', function (data) {
      socket.close();
    });
  });
}
```

### 消息吞吐量测试

```javascript
import ws from 'k6/ws';

export default function () {
  const url = 'wss://api.example.com/ws';
  
  ws.connect(url, {}, function (socket) {
    socket.on('open', function () {
      // 快速发送多条消息
      for (let i = 0; i < 100; i++) {
        socket.send(`message ${i}`);
      }
    });
    
    let receivedCount = 0;
    socket.on('message', function (data) {
      receivedCount++;
      if (receivedCount >= 100) {
        socket.close();
      }
    });
  });
}
```

## 11.7 最佳实践

### 1. 错误处理

```javascript
import ws from 'k6/ws';
import { check } from 'k6';

export default function () {
  const url = 'wss://api.example.com/ws';
  
  const response = ws.connect(url, {}, function (socket) {
    socket.on('error', function (e) {
      console.error('WebSocket 错误:', e);
    });
    
    socket.on('open', function () {
      socket.send('test');
    });
  });
  
  check(response, {
    '连接成功': (r) => r && r.status === 101,
  });
}
```

### 2. 超时处理

```javascript
socket.setTimeout(function () {
  console.log('连接超时');
  socket.close();
}, 10000);
```

### 3. 消息验证

```javascript
socket.on('message', function (data) {
  try {
    const message = JSON.parse(data);
    check(message, {
      '消息格式正确': (m) => m.type && m.data,
    });
  } catch (e) {
    console.error('消息解析失败:', e);
  }
});
```

## 11.8 总结

WebSocket 测试要点：

✅ **连接管理**：正确建立和关闭连接  
✅ **消息处理**：发送和接收消息  
✅ **事件监听**：处理各种事件  
✅ **错误处理**：处理连接错误  
✅ **性能测试**：测试并发连接和消息吞吐量  

掌握 WebSocket 测试，可以测试实时通信应用！

---

**下一章**：[第12章：gRPC 测试](./12-gRPC测试.md)

