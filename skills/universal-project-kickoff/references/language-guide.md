# 编程语言选择参考指南

本文件为 `universal-project-kickoff` 的 Step 0b「我不确定，帮我推荐」分支提供参考数据。
当用户不确定用什么编程语言时，加载本文件并根据用户的项目类型和关注点给出推荐。

## 语言速查表

### Python
- **适合**：AI/ML、数据分析与可视化、Web 后端（Django/FastAPI）、自动化脚本、科学计算
- **不适合**：高性能实时系统、移动端原生 App、浏览器前端
- **优势**：语法简洁学习曲线低、AI/ML 生态全球第一（PyTorch/TensorFlow/Scikit-learn）、第三方库极丰富
- **劣势**：运行速度比编译型语言慢 10-100 倍、GIL 限制多线程并发、移动端和浏览器端弱
- **新手友好度**：⭐⭐⭐⭐⭐

### JavaScript / TypeScript
- **适合**：Web 全栈（React/Vue/Next.js）、跨平台桌面（Electron）、移动端（React Native/Expo）、后端（Node.js/Express）、小程序
- **不适合**：高性能计算、系统编程、嵌入式
- **优势**：唯一同时跑浏览器和服务器的语言、npm 生态全球最大、TypeScript 提供类型安全
- **劣势**：npm 生态碎片化严重、运行时性能中等、Node.js 标准库不如 Python/Go 完善
- **新手友好度**：JS ⭐⭐⭐⭐ / TS ⭐⭐⭐

### Java
- **适合**：企业级后端（Spring Boot）、Android 原生开发、大数据（Hadoop/Spark）、金融系统
- **不适合**：快速原型、前端开发、脚本自动化
- **优势**：生态成熟稳定、JVM 性能优秀、强类型+丰富工具链、人才市场大
- **劣势**：语法冗长、启动慢内存占用高、开发效率不如 Python/JS
- **新手友好度**：⭐⭐⭐

### Kotlin
- **适合**：Android 开发（官方首选）、后端（Ktor/Spring Boot）、跨平台移动（KMP）
- **不适合**：需要极简语法的场景、传统企业 Java 遗留代码（互操作但需学习成本）
- **优势**：比 Java 简洁 40%+、空安全内置、协程原生支持、与 Java 100% 互操作
- **劣势**：社区小于 Java、编译速度有时慢、非 Android 领域知名度低
- **新手友好度**：⭐⭐⭐

### Go
- **适合**：云原生/微服务、CLI 工具、网络服务/API 网关、DevOps 工具、高性能中间件
- **不适合**：桌面 GUI、移动端 App、机器学习、复杂业务逻辑（泛型仍不如传统 OOP 语言灵活）
- **优势**：编译极快、部署简单（单二进制文件）、并发编程一等公民（goroutine）、语法简洁强制统一
- **劣势**：缺少传统 UI 框架、泛型支持较新、依赖管理历史复杂、简单需求代码量偏多（显式错误处理）
- **新手友好度**：⭐⭐⭐⭐

### Rust
- **适合**：系统编程、高性能服务、WebAssembly、嵌入式、区块链、需要内存安全的底层软件
- **不适合**：快速原型、UI 密集型应用、团队缺乏系统编程经验的场景
- **优势**：零成本抽象+内存安全（无 GC）、性能与 C++ 同级、编译器错误信息业界最佳
- **劣势**：学习曲线极陡（所有权/借用/生命周期）、编译时间长、生态年轻库不够丰富
- **新手友好度**：⭐⭐

### C# (.NET)
- **适合**：Windows 桌面应用、Unity 游戏开发、企业级后端（ASP.NET Core）、Xbox/游戏主机
- **不适合**：非 Windows 环境下桌面开发（跨平台桌面仍在成熟中）、Linux 服务器的传统首选
- **优势**：LINQ 数据查询极强、Visual Studio 一流 IDE、微软全面投入跨平台、游戏开发首选之一
- **劣势**：Windows 生态烙印重、社区小于 Java/JS、部分高级功能需付费 Visual Studio
- **新手友好度**：⭐⭐⭐

### Swift
- **适合**：iOS/macOS/watchOS/tvOS 原生 App、Apple 生态服务端（Vapor）
- **不适合**：非 Apple 平台、跨平台移动开发（用 Flutter/React Native 代替）
- **优势**：Apple 官方语言顶级支持、语法现代安全、性能接近 C++
- **劣势**：仅限 Apple 生态、跨平台能力弱、社区规模远小于 JS/Python
- **新手友好度**：⭐⭐⭐

### Dart (Flutter)
- **适合**：跨平台移动 App（iOS + Android）、Flutter Web、桌面应用（Windows/macOS/Linux）
- **不适合**：纯 iOS 原生体验要求极高的场景、需要大量原生平台 API 调用的场景
- **优势**：一套代码多平台、Hot Reload 开发体验极佳、Material Design 内置、Google 持续投入
- **劣势**：Dart 语言本身通用性差（几乎仅用于 Flutter）、非标准 UI 效果需大量定制、原生功能需写 Platform Channel
- **新手友好度**：⭐⭐⭐⭐

## 场景速查表

| 场景 | 首选 | 备选 | 说明 |
|------|------|------|------|
| Web 全栈 | TypeScript + Next.js | Python + Django | 全栈 JS 一套语言搞定前后端 |
| AI/ML 应用 | Python | — | 生态碾压式优势 |
| 移动 App 跨平台 | Flutter (Dart) | React Native (TypeScript) | Flutter 性能更好，RN 生态更大 |
| iOS 原生 | Swift | — | Apple 官方语言，别无选择 |
| Android 原生 | Kotlin | Java | Kotlin 已是官方首选 |
| 云原生微服务 | Go | Rust | Go 简洁，Rust 极致性能 |
| 企业后端 | Java (Spring Boot) | C# (ASP.NET Core) | Java 生态最成熟 |
| CLI 工具 | Go | Python | Go 编译为单文件，分发方便 |
| 桌面应用 | C# (.NET) + WPF | Electron (TypeScript) | Windows 首选 C#，跨平台用 Electron |
| 游戏开发 | C# (Unity) | C++ (Unreal) | Unity 上手快，Unreal 画质强 |
| 嵌入式/IoT | Rust | C | Rust 安全性是新项目首选 |
| 快速原型 | Python | TypeScript | Python 开发速度最快 |
| 系统编程 | Rust | C++ | Rust 内存安全是新项目首选 |
