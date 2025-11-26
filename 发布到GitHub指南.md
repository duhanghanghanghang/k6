# 发布到 GitHub 指南

本地 Git 仓库已经初始化并提交完成！现在需要将代码推送到 GitHub。

## 📋 步骤说明

### 步骤 1: 在 GitHub 上创建仓库

1. 登录 [GitHub](https://github.com)
2. 点击右上角的 **"+"** 按钮，选择 **"New repository"**
3. 填写仓库信息：
   - **Repository name**: `k6-learning` (或你喜欢的名字)
   - **Description**: `k6 性能测试工具学习资料`
   - **Visibility**: 选择 **Public** (公开) 或 **Private** (私有)
   - ⚠️ **不要**勾选 "Initialize this repository with a README"（我们已经有了）
4. 点击 **"Create repository"**

### 步骤 2: 添加远程仓库并推送

创建仓库后，GitHub 会显示推送命令。你可以使用以下命令：

#### 方法 1: 使用 HTTPS（推荐，简单）

```bash
cd /Users/d/Desktop/k6

# 添加远程仓库（将 YOUR_USERNAME 替换为你的 GitHub 用户名）
git remote add origin https://github.com/YOUR_USERNAME/k6-learning.git

# 推送代码
git branch -M main
git push -u origin main
```

#### 方法 2: 使用 SSH（如果你配置了 SSH 密钥）

```bash
cd /Users/d/Desktop/k6

# 添加远程仓库（将 YOUR_USERNAME 替换为你的 GitHub 用户名）
git remote add origin git@github.com:YOUR_USERNAME/k6-learning.git

# 推送代码
git branch -M main
git push -u origin main
```

### 步骤 3: 输入认证信息

如果使用 HTTPS，GitHub 会要求你输入：
- **用户名**: 你的 GitHub 用户名
- **密码**: 使用 **Personal Access Token**（不是账户密码）

#### 如何创建 Personal Access Token:

1. 登录 GitHub
2. 点击右上角头像 → **Settings**
3. 左侧菜单选择 **Developer settings**
4. 选择 **Personal access tokens** → **Tokens (classic)**
5. 点击 **Generate new token** → **Generate new token (classic)**
6. 填写信息：
   - **Note**: `k6-learning-push`
   - **Expiration**: 选择过期时间（或 No expiration）
   - **Select scopes**: 勾选 `repo`（完整仓库权限）
7. 点击 **Generate token**
8. **复制 token**（只显示一次，请保存好）
9. 推送时，密码输入框输入这个 token

## 🚀 一键推送脚本

你也可以使用以下脚本（记得先修改用户名和仓库名）：

```bash
#!/bin/bash
# 修改以下变量
GITHUB_USERNAME="YOUR_USERNAME"
REPO_NAME="k6-learning"

cd /Users/d/Desktop/k6

# 添加远程仓库
git remote add origin https://github.com/${GITHUB_USERNAME}/${REPO_NAME}.git 2>/dev/null || \
git remote set-url origin https://github.com/${GITHUB_USERNAME}/${REPO_NAME}.git

# 推送代码
git branch -M main
git push -u origin main
```

## ✅ 验证推送成功

推送成功后，访问你的 GitHub 仓库地址：
```
https://github.com/YOUR_USERNAME/k6-learning
```

你应该能看到所有文档文件。

## 🔄 后续更新

以后如果有更新，只需要：

```bash
cd /Users/d/Desktop/k6
git add .
git commit -m "更新文档内容"
git push
```

## 📝 常见问题

### Q1: 提示 "remote origin already exists"

**解决**：删除旧的远程仓库，重新添加
```bash
git remote remove origin
git remote add origin https://github.com/YOUR_USERNAME/k6-learning.git
```

### Q2: 推送时提示认证失败

**解决**：
- 确认使用 Personal Access Token（不是密码）
- 确认 token 有 `repo` 权限
- 或者配置 SSH 密钥

### Q3: 如何配置 SSH 密钥？

```bash
# 1. 生成 SSH 密钥（如果还没有）
ssh-keygen -t ed25519 -C "your_email@example.com"

# 2. 复制公钥
cat ~/.ssh/id_ed25519.pub

# 3. 在 GitHub 上添加 SSH 密钥
# Settings → SSH and GPG keys → New SSH key
# 粘贴公钥内容

# 4. 测试连接
ssh -T git@github.com
```

## 🎉 完成！

推送成功后，你的文档就发布到 GitHub 了！可以：
- 分享链接给其他人
- 在简历中展示
- 继续更新和维护

---

**需要帮助？** 查看 [GitHub 官方文档](https://docs.github.com/)

