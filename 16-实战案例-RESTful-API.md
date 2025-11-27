# 第16章：实战案例一：RESTful API 测试

## 16.1 项目背景

### 场景描述

测试一个用户管理系统的 RESTful API，包括：
- 用户注册
- 用户登录
- 获取用户信息
- 更新用户信息
- 删除用户

### 系统架构

```
前端应用
    ↓
API Gateway
    ↓
用户服务 API (RESTful)
    ↓
数据库
```

## 16.2 测试需求分析

### 测试目标

1. **功能验证**：验证 API 功能正常
2. **性能测试**：验证 API 性能指标
3. **稳定性测试**：验证长时间运行的稳定性

### 性能指标

- 响应时间：P95 < 500ms
- 错误率：< 1%
- QPS：> 100 req/s

## 16.3 测试脚本编写

### 完整测试脚本

```javascript
import http from 'k6/http';
import { check, sleep, group } from 'k6';
import { Rate, Trend } from 'k6/metrics';

// 自定义指标
const loginSuccessRate = new Rate('login_success_rate');
const apiResponseTime = new Trend('api_response_time');

const BASE_URL = __ENV.BASE_URL || 'https://api.example.com';

export const options = {
  stages: [
    { duration: '30s', target: 20 },
    { duration: '1m', target: 50 },
    { duration: '1m', target: 50 },
    { duration: '30s', target: 0 },
  ],
  thresholds: {
    http_req_duration: ['p(95)<500', 'p(99)<1000'],
    http_req_failed: ['rate<0.01'],
    login_success_rate: ['rate>0.95'],
  },
};

export default function () {
  let userId;
  let token;
  
  group('用户注册', function () {
    const registerPayload = JSON.stringify({
      username: `user${__VU}${__ITER}`,
      email: `user${__VU}${__ITER}@example.com`,
      password: 'password123',
    });
    
    const registerRes = http.post(
      `${BASE_URL}/api/users/register`,
      registerPayload,
      {
        headers: { 'Content-Type': 'application/json' },
        tags: { name: 'Register', endpoint: '/api/users/register' },
      }
    );
    
    const registerSuccess = check(registerRes, {
      '注册状态码是 201': (r) => r.status === 201,
      '返回用户ID': (r) => {
        if (r.status === 201) {
          const data = JSON.parse(r.body);
          userId = data.id;
          return userId !== undefined;
        }
        return false;
      },
    });
    
    if (!registerSuccess) {
      return; // 注册失败，停止后续操作
    }
  });
  
  sleep(1);
  
  group('用户登录', function () {
    const loginPayload = JSON.stringify({
      username: `user${__VU}${__ITER}`,
      password: 'password123',
    });
    
    const loginRes = http.post(
      `${BASE_URL}/api/users/login`,
      loginPayload,
      {
        headers: { 'Content-Type': 'application/json' },
        tags: { name: 'Login', endpoint: '/api/users/login' },
      }
    );
    
    const loginSuccess = check(loginRes, {
      '登录状态码是 200': (r) => r.status === 200,
      '返回 Token': (r) => {
        if (r.status === 200) {
          const data = JSON.parse(r.body);
          token = data.token;
          return token !== undefined;
        }
        return false;
      },
    });
    
    loginSuccessRate.add(loginSuccess);
    
    if (!loginSuccess) {
      return; // 登录失败，停止后续操作
    }
  });
  
  sleep(1);
  
  group('获取用户信息', function () {
    const getUserRes = http.get(
      `${BASE_URL}/api/users/${userId}`,
      {
        headers: { 'Authorization': `Bearer ${token}` },
        tags: { name: 'GetUser', endpoint: '/api/users/:id' },
      }
    );
    
    const getUserSuccess = check(getUserRes, {
      '获取用户信息成功': (r) => r.status === 200,
      '用户信息正确': (r) => {
        if (r.status === 200) {
          const data = JSON.parse(r.body);
          return data.id === userId;
        }
        return false;
      },
    });
    
    apiResponseTime.add(getUserRes.timings.duration);
  });
  
  sleep(1);
  
  group('更新用户信息', function () {
    const updatePayload = JSON.stringify({
      email: `updated${__VU}${__ITER}@example.com`,
    });
    
    const updateRes = http.put(
      `${BASE_URL}/api/users/${userId}`,
      updatePayload,
      {
        headers: {
          'Authorization': `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        tags: { name: 'UpdateUser', endpoint: '/api/users/:id' },
      }
    );
    
    check(updateRes, {
      '更新用户信息成功': (r) => r.status === 200,
    });
  });
  
  sleep(1);
  
  group('删除用户', function () {
    const deleteRes = http.del(
      `${BASE_URL}/api/users/${userId}`,
      {
        headers: { 'Authorization': `Bearer ${token}` },
        tags: { name: 'DeleteUser', endpoint: '/api/users/:id' },
      }
    );
    
    check(deleteRes, {
      '删除用户成功': (r) => r.status === 200 || r.status === 204,
    });
  });
  
  sleep(1);
}
```

## 16.4 测试场景设计

### 场景 1：负载测试

```javascript
export const options = {
  vus: 100,
  duration: '10m',
};
```

### 场景 2：压力测试

```javascript
export const options = {
  stages: [
    { duration: '2m', target: 100 },
    { duration: '5m', target: 200 },
    { duration: '5m', target: 300 },
    { duration: '2m', target: 0 },
  ],
};
```

### 场景 3：峰值测试

```javascript
export const options = {
  stages: [
    { duration: '1m', target: 50 },
    { duration: '10s', target: 500 },
    { duration: '30s', target: 500 },
    { duration: '10s', target: 50 },
  ],
};
```

## 16.5 结果分析与优化

### 结果分析

运行测试后，关注以下指标：

1. **响应时间**：
   - 平均响应时间
   - P95、P99 响应时间
   - 各接口响应时间对比

2. **错误率**：
   - 总体错误率
   - 各接口错误率
   - 错误类型分析

3. **吞吐量**：
   - QPS
   - 各接口 QPS

### 性能优化建议

**发现的问题**：
1. 注册接口响应时间较长（P95 = 800ms）
2. 登录接口在高并发下错误率较高（5%）

**优化建议**：
1. **注册接口优化**：
   - 异步处理用户创建
   - 优化数据库查询
   - 添加缓存

2. **登录接口优化**：
   - 增加连接池大小
   - 优化认证逻辑
   - 添加限流机制

### 优化后的脚本

```javascript
// 添加重试机制
function httpPostWithRetry(url, payload, options, maxRetries = 3) {
  for (let i = 0; i < maxRetries; i++) {
    const response = http.post(url, payload, options);
    
    if (response.status === 200 || response.status === 201) {
      return response;
    }
    
    if (i < maxRetries - 1) {
      sleep(Math.pow(2, i)); // 指数退避
    }
  }
  
  return null;
}

// 使用批处理
const responses = http.batch([
  ['GET', `${BASE_URL}/api/users/${userId}`],
  ['GET', `${BASE_URL}/api/users/${userId}/orders`],
]);
```

## 16.6 持续监控

### CI/CD 集成

```yaml
# .github/workflows/performance.yml
name: API Performance Tests

on:
  push:
    branches: [ main ]

jobs:
  performance:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: grafana/k6-action@v0.3.0
        with:
          filename: tests/api-test.js
          cloud: false
```

### 监控集成

```bash
# 输出到 InfluxDB
k6 run --out influxdb=http://localhost:8086/k6 tests/api-test.js
```

## 16.7 总结

RESTful API 测试要点：

✅ **完整流程**：覆盖 CRUD 完整流程  
✅ **错误处理**：处理各种错误情况  
✅ **性能指标**：设置合理的阈值  
✅ **结果分析**：深入分析性能瓶颈  
✅ **持续优化**：根据结果持续改进  

通过这个案例，可以掌握完整的 API 性能测试流程！

---

**下一章**：[第17章：实战案例二：用户登录流程测试](./17-实战案例-登录流程.md)

