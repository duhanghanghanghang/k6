# 第12章：gRPC 测试

## 12.1 gRPC 协议介绍

### 什么是 gRPC

gRPC 是一个高性能、开源的 RPC 框架，使用 Protocol Buffers 作为接口定义语言。

### gRPC 特点

- **高性能**：基于 HTTP/2，支持流式传输
- **跨语言**：支持多种编程语言
- **类型安全**：使用 Protocol Buffers 定义接口
- **流式支持**：支持单向流、双向流

## 12.2 Protocol Buffers 配置

### 定义 .proto 文件

**hello.proto**：
```protobuf
syntax = "proto3";

package hello;

service HelloService {
  rpc SayHello (HelloRequest) returns (HelloResponse);
}

message HelloRequest {
  string name = 1;
}

message HelloResponse {
  string message = 1;
}
```

### 编译 .proto 文件

```bash
# 安装 protoc
# macOS
brew install protobuf

# 编译（k6 不需要编译，直接使用 .proto 文件）
```

## 12.3 gRPC 客户端使用

### 基本用法

```javascript
import grpc from 'k6/net/grpc';
import { check } from 'k6';

const client = new grpc.Client();
client.load(['../proto'], 'hello.proto');

export default function () {
  client.connect('localhost:50051', {
    plaintext: true,  // 使用明文连接（开发环境）
  });
  
  const data = { name: 'k6' };
  const response = client.invoke('hello.HelloService/SayHello', data);
  
  check(response, {
    '状态码是 OK': (r) => r.status === grpc.StatusOK,
    '响应消息正确': (r) => r.message.message === 'Hello k6',
  });
  
  client.close();
  sleep(1);
}
```

## 12.4 服务调用

### 一元调用（Unary）

```javascript
import grpc from 'k6/net/grpc';

const client = new grpc.Client();
client.load(['../proto'], 'user.proto');

export default function () {
  client.connect('localhost:50051', { plaintext: true });
  
  // 调用一元 RPC
  const response = client.invoke('user.UserService/GetUser', {
    id: '123',
  });
  
  console.log('用户信息:', response.message);
  
  client.close();
}
```

### 流式调用

**服务器流（Server Streaming）**：
```javascript
import grpc from 'k6/net/grpc';

const client = new grpc.Client();
client.load(['../proto'], 'stream.proto');

export default function () {
  client.connect('localhost:50051', { plaintext: true });
  
  const stream = client.invoke('stream.StreamService/ServerStream', {
    count: 10,
  });
  
  for (const message of stream) {
    console.log('收到消息:', message);
  }
  
  client.close();
}
```

## 12.5 流式调用测试

### 客户端流（Client Streaming）

```javascript
import grpc from 'k6/net/grpc';

const client = new grpc.Client();
client.load(['../proto'], 'stream.proto');

export default function () {
  client.connect('localhost:50051', { plaintext: true });
  
  const stream = client.invoke('stream.StreamService/ClientStream');
  
  // 发送多条消息
  for (let i = 0; i < 10; i++) {
    stream.write({ message: `Message ${i}` });
  }
  
  stream.end();
  
  const response = stream.read();
  console.log('响应:', response);
  
  client.close();
}
```

### 双向流（Bidirectional Streaming）

```javascript
import grpc from 'k6/net/grpc';

const client = new grpc.Client();
client.load(['../proto'], 'stream.proto');

export default function () {
  client.connect('localhost:50051', { plaintext: true });
  
  const stream = client.invoke('stream.StreamService/BidirectionalStream');
  
  // 发送消息
  stream.write({ message: 'Hello' });
  
  // 接收消息
  for (const message of stream) {
    console.log('收到:', message);
    break; // 只接收一条
  }
  
  stream.end();
  client.close();
}
```

## 12.6 认证配置

### TLS 连接

```javascript
import grpc from 'k6/net/grpc';

const client = new grpc.Client();
client.load(['../proto'], 'service.proto');

export default function () {
  client.connect('api.example.com:443', {
    plaintext: false,  // 使用 TLS
    // 可选：指定证书
    // tls: {
    //   cert: open('./client.crt'),
    //   key: open('./client.key'),
    // },
  });
  
  const response = client.invoke('service.Service/Method', {});
  client.close();
}
```

### Token 认证

```javascript
import grpc from 'k6/net/grpc';

const client = new grpc.Client();
client.load(['../proto'], 'service.proto');

export default function () {
  client.connect('localhost:50051', { plaintext: true });
  
  // 设置元数据（用于认证）
  const metadata = {
    'authorization': 'Bearer token123',
  };
  
  const response = client.invoke(
    'service.Service/Method',
    {},
    { metadata: metadata }
  );
  
  client.close();
}
```

## 12.7 实际应用示例

### 示例 1：用户服务测试

**user.proto**：
```protobuf
syntax = "proto3";

package user;

service UserService {
  rpc GetUser (GetUserRequest) returns (User);
  rpc CreateUser (CreateUserRequest) returns (User);
  rpc ListUsers (ListUsersRequest) returns (ListUsersResponse);
}

message GetUserRequest {
  string id = 1;
}

message CreateUserRequest {
  string name = 1;
  string email = 2;
}

message User {
  string id = 1;
  string name = 2;
  string email = 3;
}

message ListUsersRequest {
  int32 page = 1;
  int32 page_size = 2;
}

message ListUsersResponse {
  repeated User users = 1;
  int32 total = 2;
}
```

**测试脚本**：
```javascript
import grpc from 'k6/net/grpc';
import { check, sleep } from 'k6';

const client = new grpc.Client();
client.load(['../proto'], 'user.proto');

export const options = {
  vus: 10,
  duration: '30s',
};

export default function () {
  client.connect('localhost:50051', { plaintext: true });
  
  // 创建用户
  const createRes = client.invoke('user.UserService/CreateUser', {
    name: `User ${__VU}`,
    email: `user${__VU}@example.com`,
  });
  
  check(createRes, {
    '创建用户成功': (r) => r.status === grpc.StatusOK,
  });
  
  const userId = createRes.message.id;
  
  // 获取用户
  const getRes = client.invoke('user.UserService/GetUser', {
    id: userId,
  });
  
  check(getRes, {
    '获取用户成功': (r) => r.status === grpc.StatusOK,
    '用户信息正确': (r) => r.message.id === userId,
  });
  
  // 列出用户
  const listRes = client.invoke('user.UserService/ListUsers', {
    page: 1,
    page_size: 10,
  });
  
  check(listRes, {
    '列出用户成功': (r) => r.status === grpc.StatusOK,
    '返回用户列表': (r) => r.message.users.length > 0,
  });
  
  client.close();
  sleep(1);
}
```

## 12.8 性能测试配置

### 并发测试

```javascript
import grpc from 'k6/net/grpc';

const client = new grpc.Client();
client.load(['../proto'], 'service.proto');

export const options = {
  stages: [
    { duration: '30s', target: 50 },
    { duration: '1m', target: 100 },
    { duration: '30s', target: 0 },
  ],
};

export default function () {
  client.connect('localhost:50051', { plaintext: true });
  
  const response = client.invoke('service.Service/Method', {});
  
  client.close();
  sleep(1);
}
```

## 12.9 最佳实践

### 1. 连接复用

```javascript
// 好的做法：在 setup 中创建连接
export function setup() {
  const client = new grpc.Client();
  client.load(['../proto'], 'service.proto');
  client.connect('localhost:50051', { plaintext: true });
  return { client: client };
}

export default function (data) {
  const response = data.client.invoke('service.Service/Method', {});
  // ...
}

export function teardown(data) {
  data.client.close();
}
```

### 2. 错误处理

```javascript
const response = client.invoke('service.Service/Method', {});

if (response.status !== grpc.StatusOK) {
  console.error('gRPC 调用失败:', response.status);
  return;
}
```

### 3. 超时设置

```javascript
const response = client.invoke(
  'service.Service/Method',
  {},
  { timeout: '5s' }
);
```

## 12.10 总结

gRPC 测试要点：

✅ **Protocol Buffers**：定义服务接口  
✅ **客户端创建**：加载 .proto 文件  
✅ **服务调用**：一元调用和流式调用  
✅ **认证配置**：TLS 和 Token 认证  
✅ **性能测试**：测试 gRPC 服务性能  

掌握 gRPC 测试，可以测试微服务架构中的 gRPC 服务！

---

**下一章**：[第13章：文件操作](./13-文件操作.md)

