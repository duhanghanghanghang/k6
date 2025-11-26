#!/bin/bash

# k6 学习资料推送到 GitHub 脚本
# 使用方法: ./push-to-github.sh YOUR_USERNAME REPO_NAME

set -e

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 k6 学习资料推送到 GitHub${NC}\n"

# 检查参数
if [ -z "$1" ] || [ -z "$2" ]; then
    echo -e "${YELLOW}使用方法:${NC}"
    echo "  ./push-to-github.sh YOUR_USERNAME REPO_NAME"
    echo ""
    echo -e "${YELLOW}示例:${NC}"
    echo "  ./push-to-github.sh zhangsan k6-learning"
    echo ""
    echo -e "${YELLOW}或者手动执行:${NC}"
    echo "  1. 在 GitHub 上创建仓库"
    echo "  2. 运行以下命令："
    echo "     git remote add origin https://github.com/YOUR_USERNAME/REPO_NAME.git"
    echo "     git branch -M main"
    echo "     git push -u origin main"
    exit 1
fi

GITHUB_USERNAME=$1
REPO_NAME=$2
REPO_URL="https://github.com/${GITHUB_USERNAME}/${REPO_NAME}.git"

echo -e "${YELLOW}配置信息:${NC}"
echo "  GitHub 用户名: ${GITHUB_USERNAME}"
echo "  仓库名称: ${REPO_NAME}"
echo "  仓库地址: ${REPO_URL}"
echo ""

# 检查是否已经添加了远程仓库
if git remote get-url origin &>/dev/null; then
    echo -e "${YELLOW}检测到已存在的远程仓库，更新地址...${NC}"
    git remote set-url origin ${REPO_URL}
else
    echo -e "${GREEN}添加远程仓库...${NC}"
    git remote add origin ${REPO_URL}
fi

# 确保在 main 分支
echo -e "${GREEN}切换到 main 分支...${NC}"
git branch -M main

# 检查是否有未提交的更改
if ! git diff-index --quiet HEAD --; then
    echo -e "${YELLOW}检测到未提交的更改，是否提交？(y/n)${NC}"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        git add .
        git commit -m "更新文档"
    fi
fi

# 推送代码
echo -e "${GREEN}推送代码到 GitHub...${NC}"
echo -e "${YELLOW}提示: 如果使用 HTTPS，需要输入 GitHub 用户名和 Personal Access Token${NC}"
echo ""

git push -u origin main

echo ""
echo -e "${GREEN}✅ 推送成功！${NC}"
echo -e "${GREEN}访问你的仓库: ${REPO_URL}${NC}"

