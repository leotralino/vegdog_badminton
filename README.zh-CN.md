# 菜狗羽球 (VegDog Badminton)

<p align="center">
  <img src="./app/ios/Resources/Brand/vegdog_logo.png" alt="VegDog Logo" width="160" />
</p>

<p align="center">
  <a href="./README.md">English</a> | <b><a href="./README.zh-CN.md">中文</a></b>
</p>

菜狗（VegDog）是一个以 iOS 为优先的羽球约球应用，面向熟人球友群，支持接龙报名、晚退规则处理、收款方式分享。

<p align="center">
  <img src="https://img.shields.io/badge/iOS-17.0+-0A84FF.svg" alt="iOS 17+">
  <img src="https://img.shields.io/badge/Swift-5.10-F05138.svg?logo=swift&logoColor=white" alt="Swift 5.10">
  <img src="https://img.shields.io/badge/UI-SwiftUI-0A84FF.svg" alt="SwiftUI">
  <img src="https://img.shields.io/badge/architecture-MVVM-34C759.svg" alt="MVVM">
  <img src="https://img.shields.io/badge/API-OpenAPI%203.0.3-6E56CF.svg" alt="OpenAPI 3.0.3">
  <img src="https://img.shields.io/badge/project-XcodeGen-111111.svg" alt="XcodeGen">
  <img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="MIT License">
</p>

## 技术栈
- iOS：Swift 5.10、SwiftUI、MVVM、async/await
- API：OpenAPI 3.0.3（`backend/openapi/openapi.yaml`）
- 工程管理：XcodeGen（`app/ios/project.yml`）
- 当前运行模式：默认 Mock 服务（`USE_MOCK_SERVICE=true`）
- 本地化：英文 + 简体中文（`en.lproj`、`zh-Hans.lproj`）

## 产品路线图
- MVP
  - 微信登录
  - 活动创建 / 加入 / 退出 / 锁定名单（接龙核心流程）
  - 收款方式分享 + 付款状态记录
- V1
  - 结算辅助
  - 通知能力
  - 基础历史记录
- 增强模块
  - 对阵组织
  - 记分与基础战绩统计

## 仓库结构
- `docs/SPECS.md`：产品需求与里程碑基线
- `backend/openapi/openapi.yaml`：API 合同源文件
- `app/ios/`：iOS 应用代码与资源
- `app/ios/Resources/Brand/`：Logo 资源（`vegdog_logo.png`、`vegdog_logo.svg`）
- `AGENTS.md`：协作与实现规范

## 快速开始（iOS）
1. 安装 `xcodegen`：
   - `brew install xcodegen`
2. 生成工程：
   - `./app/ios/scripts/generate_xcodeproj.sh`
3. 打开工程：
   - `./app/ios/scripts/open_in_xcode.sh`

## 多语言支持
- 当前支持：
  - English（`en`）
  - 简体中文（`zh-Hans`）
- 应用右上角提供语言切换按钮。

## 文档导航
- 英文文档：`README.md`
- 中文文档：`README.zh-CN.md`（本文件）
- 详细规格：`docs/SPECS.md`
