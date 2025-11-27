# 第21章：CI/CD 集成

## 21.1 概述

将 k6 集成到 CI/CD 流程中，可以实现持续性能测试，确保每次代码变更都不会引入性能问题。

## 21.2 GitHub Actions 集成

### 基本配置

创建 `.github/workflows/performance.yml`：

```yaml
name: Performance Tests

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  performance:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Run k6 tests
        uses: grafana/k6-action@v0.3.0
        with:
          filename: tests/load-test.js
          cloud: false
          summary: true
          quiet: false
          
      - name: Upload results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: k6-results
          path: results.json
```

### 高级配置

```yaml
name: Performance Tests

on:
  push:
    branches: [ main ]
  workflow_dispatch:
    inputs:
      vus:
        description: 'Number of virtual users'
        required: false
        default: '10'

jobs:
  performance:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup k6
        uses: grafana/k6-action@v0.3.0
        with:
          filename: tests/load-test.js
          cloud: false
          summary: true
          quiet: false
          additionalArgs: '--env VUS=${{ github.event.inputs.vus || 10 }}'
          
      - name: Upload results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: k6-results
          path: results.json
          
      - name: Comment PR
        if: github.event_name == 'pull_request'
        uses: actions/github-script@v6
        with:
          script: |
            const fs = require('fs');
            const results = JSON.parse(fs.readFileSync('results.json', 'utf8'));
            const comment = `## Performance Test Results
            - Total Requests: ${results.metrics.http_reqs.values.count}
            - Avg Response Time: ${results.metrics.http_req_duration.values.avg}ms
            - P95 Response Time: ${results.metrics.http_req_duration.values['p(95)']}ms
            - Error Rate: ${(results.metrics.http_req_failed.values.rate * 100).toFixed(2)}%`;
            
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: comment
            });
```

## 21.3 GitLab CI 集成

### 基本配置

创建 `.gitlab-ci.yml`：

```yaml
stages:
  - test

performance:
  stage: test
  image: grafana/k6:latest
  script:
    - k6 run --out json=results.json tests/load-test.js
  artifacts:
    when: always
    reports:
      performance: results.json
  only:
    - main
    - develop
```

### 高级配置

```yaml
stages:
  - test

variables:
  K6_VERSION: "latest"

.performance_template: &performance_template
  image: grafana/k6:${K6_VERSION}
  before_script:
    - echo "Starting performance tests"
  after_script:
    - echo "Performance tests completed"

smoke_test:
  <<: *performance_template
  stage: test
  script:
    - k6 run --vus 1 --duration 30s tests/smoke-test.js
  only:
    - merge_requests

load_test:
  <<: *performance_template
  stage: test
  script:
    - k6 run --out json=results.json tests/load-test.js
  artifacts:
    when: always
    reports:
      performance: results.json
  only:
    - main
```

## 21.4 Jenkins 集成

### Pipeline 脚本

创建 `Jenkinsfile`：

```groovy
pipeline {
    agent any
    
    environment {
        K6_VERSION = 'latest'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Performance Test') {
            steps {
                sh '''
                    docker run --rm -i \
                    -v ${WORKSPACE}:/scripts \
                    grafana/k6:${K6_VERSION} \
                    run /scripts/tests/load-test.js \
                    --out json=/scripts/results.json
                '''
            }
        }
        
        stage('Publish Results') {
            steps {
                publishHTML([
                    reportName: 'k6 Performance Report',
                    reportDir: '.',
                    reportFiles: 'results.html',
                    keepAll: true
                ])
            }
        }
    }
    
    post {
        always {
            archiveArtifacts artifacts: 'results.json', fingerprint: true
        }
        failure {
            emailext (
                subject: "Performance Test Failed: ${env.JOB_NAME} - ${env.BUILD_NUMBER}",
                body: "Performance test failed. Check console output for details.",
                to: "${env.CHANGE_AUTHOR_EMAIL}"
            )
        }
    }
}
```

### 使用 Jenkinsfile

```groovy
pipeline {
    agent any
    
    stages {
        stage('Performance Test') {
            steps {
                script {
                    def k6Result = sh(
                        script: 'k6 run --out json=results.json tests/load-test.js',
                        returnStatus: true
                    )
                    
                    if (k6Result != 0) {
                        currentBuild.result = 'UNSTABLE'
                    }
                }
            }
        }
    }
}
```

## 21.5 Azure DevOps 集成

### YAML Pipeline

创建 `azure-pipelines.yml`：

```yaml
trigger:
  branches:
    include:
      - main
      - develop

pool:
  vmImage: 'ubuntu-latest'

steps:
  - task: Docker@2
    displayName: 'Run k6 tests'
    inputs:
      containerRegistry: 'DockerHub'
      command: 'run'
      arguments: '--rm -v $(System.DefaultWorkingDirectory):/scripts grafana/k6:latest run /scripts/tests/load-test.js --out json=/scripts/results.json'
      
  - task: PublishTestResults@2
    displayName: 'Publish test results'
    inputs:
      testResultsFormat: 'JUnit'
      testResultsFiles: 'results.json'
      
  - task: PublishBuildArtifacts@1
    displayName: 'Publish artifacts'
    inputs:
      pathToPublish: 'results.json'
      artifactName: 'k6-results'
```

## 21.6 持续性能测试策略

### 策略 1：每次提交都运行

```yaml
on:
  push:
    branches: [ '*' ]  # 所有分支
```

**优点**：及时发现问题  
**缺点**：资源消耗大

### 策略 2：仅主分支运行

```yaml
on:
  push:
    branches: [ main ]
```

**优点**：节省资源  
**缺点**：发现问题较晚

### 策略 3：PR 时运行轻量测试

```yaml
on:
  pull_request:
    branches: [ main ]

jobs:
  smoke_test:
    steps:
      - k6 run --vus 1 --duration 30s tests/smoke-test.js
```

**优点**：平衡资源消耗和及时性  
**缺点**：需要维护两套测试

### 策略 4：定时运行完整测试

```yaml
on:
  schedule:
    - cron: '0 2 * * *'  # 每天凌晨2点
```

**优点**：定期全面测试  
**缺点**：不能及时发现问题

## 21.7 性能回归测试

### 阈值配置

```javascript
export const options = {
  thresholds: {
    http_req_duration: ['p(95)<500'],  // P95 < 500ms
    http_req_failed: ['rate<0.01'],    // 错误率 < 1%
  },
};
```

### 基准对比

```javascript
// 保存基准值
const baseline = {
  p95: 450,
  errorRate: 0.005,
};

export const options = {
  thresholds: {
    // 不能比基准差10%以上
    http_req_duration: [`p(95)<${baseline.p95 * 1.1}`],
    http_req_failed: [`rate<${baseline.errorRate * 1.1}`],
  },
};
```

### 自动告警

```yaml
- name: Check thresholds
  run: |
    if [ $? -ne 0 ]; then
      echo "Performance regression detected!"
      exit 1
    fi
```

## 21.8 测试结果处理

### 保存结果

```yaml
- name: Save results
  run: |
    k6 run --out json=results.json script.js
    k6 run --out csv=results.csv script.js
```

### 上传到存储

```yaml
- name: Upload to S3
  run: |
    aws s3 cp results.json s3://my-bucket/results/
```

### 发送通知

```yaml
- name: Send notification
  if: failure()
  run: |
    curl -X POST https://hooks.slack.com/services/YOUR/WEBHOOK/URL \
      -d '{"text":"Performance test failed!"}'
```

## 21.9 环境变量管理

### 使用 Secrets

**GitHub Actions**：
```yaml
env:
  API_URL: ${{ secrets.API_URL }}
  API_KEY: ${{ secrets.API_KEY }}
```

**GitLab CI**：
```yaml
variables:
  API_URL: $CI_API_URL
script:
  - k6 run --env API_URL=$API_URL script.js
```

### 配置文件

```javascript
// config.js
export const config = {
  baseUrl: __ENV.API_URL || 'https://api.example.com',
  vus: parseInt(__ENV.VUS) || 10,
  duration: __ENV.DURATION || '30s',
};
```

## 21.10 最佳实践

### 1. 分层测试

```yaml
smoke_test:
  # 快速验证基本功能
  script: k6 run --vus 1 --duration 30s smoke-test.js

load_test:
  # 完整性能测试
  script: k6 run load-test.js
```

### 2. 并行执行

```yaml
strategy:
  matrix:
    test: [test1.js, test2.js, test3.js]
steps:
  - k6 run ${{ matrix.test }}
```

### 3. 结果可视化

```yaml
- name: Generate report
  run: |
    python generate_report.py results.json
```

### 4. 失败处理

```yaml
- name: Run tests
  continue-on-error: true
  run: k6 run script.js
```

## 21.11 总结

CI/CD 集成要点：

✅ **选择合适的触发时机**：push、PR、定时  
✅ **配置合理的阈值**：自动判断测试是否通过  
✅ **保存测试结果**：便于分析和对比  
✅ **发送通知**：及时了解测试结果  
✅ **环境变量管理**：安全地管理敏感信息  

将 k6 集成到 CI/CD，可以实现持续性能监控，确保代码质量！

---

**下一章**：[第22章：k6 vs JMeter 全面对比](./22-k6-vs-JMeter对比.md)

