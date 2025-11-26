# k6 性能测试学习资料

这是一个关于 k6 性能测试工具的完整学习资料库，包含详细的学习指南、实战示例、工具对比和简历建议。

## 📚 文档目录

### 1. [k6 学习指南](./k6学习指南.md)
全面的 k6 学习文档，涵盖：
- k6 核心概念和特性
- 安装与配置
- 脚本编写详解
- 测试场景配置
- 指标与结果分析
- 高级功能（WebSocket、gRPC等）
- 最佳实践

### 2. [k6 vs JMeter 对比](./k6-vs-JMeter对比.md)
详细的工具对比分析：
- 架构与性能对比
- 脚本编写方式对比
- 资源消耗对比
- CI/CD 集成对比
- 报告与监控对比
- 适用场景分析
- 迁移建议

### 3. [k6 快速上手指南](./k6快速上手指南.md)
实战快速入门指南：
- 5 分钟快速开始
- 5 个实战示例（API测试、CRUD流程、峰值测试等）
- 常用配置模板
- CI/CD 集成示例
- 常见问题解决
- 性能优化技巧

### 4. [简历技能选择建议](./简历技能选择建议.md)
求职简历编写建议：
- JMeter vs k6 在简历中的选择
- 不同公司类型的建议
- 简历写法示例
- 面试准备建议
- 行业趋势分析

## 🚀 快速开始

### 安装 k6

**macOS**:
```bash
brew install k6
```

**Linux**:
```bash
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
echo "deb https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
sudo apt-get update
sudo apt-get install k6
```

**验证安装**:
```bash
k6 version
```

### 第一个测试脚本

创建 `test.js`:

```javascript
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  vus: 10,
  duration: '30s',
};

export default function () {
  const response = http.get('https://test-api.k6.io/public/crocodiles/');
  check(response, {
    '状态码是 200': (r) => r.status === 200,
  });
  sleep(1);
}
```

运行测试:
```bash
k6 run test.js
```

## 📖 学习路径建议

1. **初学者**：先阅读 [k6 快速上手指南](./k6快速上手指南.md)
2. **深入学习**：阅读 [k6 学习指南](./k6学习指南.md)
3. **工具选择**：参考 [k6 vs JMeter 对比](./k6-vs-JMeter对比.md)
4. **求职准备**：查看 [简历技能选择建议](./简历技能选择建议.md)

## 🎯 k6 核心优势

- ✅ **简洁高效**：JavaScript 脚本，几行代码即可完成测试
- ✅ **性能卓越**：单机可模拟 10,000+ 并发用户
- ✅ **启动快速**：<1 秒启动，无需等待
- ✅ **资源友好**：内存占用仅为 JMeter 的 1/3
- ✅ **CI/CD 完美**：原生支持自动化流程
- ✅ **现代工具**：符合开发者习惯的工作流

## 📚 官方资源

- [k6 官方网站](https://k6.io/)
- [k6 官方文档](https://grafana.com/docs/k6/latest/)
- [k6 GitHub](https://github.com/grafana/k6)
- [k6 社区](https://k6.io/slack)

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

本仓库内容采用 MIT 许可证。

## ⭐ Star History

如果这个仓库对你有帮助，请给个 Star ⭐

---

**最后更新**: 2024年

