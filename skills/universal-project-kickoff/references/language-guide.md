# Programming Language Selection Guide

This document provides reference data for the `universal-project-kickoff` Step 0b "I'm not sure, recommend for me" branch.
When the user is unsure which programming language to use, load this file and make recommendations based on the user's project type and concerns.

## Language Quick Reference

### Python
- **Best for:** AI/ML, data analysis and visualization, web backend (Django/FastAPI), automation scripts, scientific computing
- **Not suitable for:** High-performance real-time systems, native mobile apps, browser frontend
- **Strengths:** Clean syntax with gentle learning curve, world's #1 AI/ML ecosystem (PyTorch/TensorFlow/Scikit-learn), extremely rich third-party libraries
- **Weaknesses:** 10-100x slower than compiled languages, GIL limits multi-threaded concurrency, weak on mobile and browser
- **Beginner friendliness:** &#11088;&#11088;&#11088;&#11088;&#11088;

### JavaScript / TypeScript
- **Best for:** Web full-stack (React/Vue/Next.js), cross-platform desktop (Electron), mobile (React Native/Expo), backend (Node.js/Express), mini programs
- **Not suitable for:** High-performance computing, systems programming, embedded
- **Strengths:** The only language that runs in both browser and server, largest npm ecosystem in the world, TypeScript provides type safety
- **Weaknesses:** npm ecosystem fragmentation, moderate runtime performance, Node.js standard library less comprehensive than Python/Go
- **Beginner friendliness:** JS &#11088;&#11088;&#11088;&#11088; / TS &#11088;&#11088;&#11088;

### Java
- **Best for:** Enterprise backend (Spring Boot), Android native development, big data (Hadoop/Spark), financial systems
- **Not suitable for:** Rapid prototyping, frontend development, script automation
- **Strengths:** Mature and stable ecosystem, excellent JVM performance, strong typing + rich toolchain, large talent market
- **Weaknesses:** Verbose syntax, slow startup and high memory usage, lower development efficiency than Python/JS
- **Beginner friendliness:** &#11088;&#11088;&#11088;

### Kotlin
- **Best for:** Android development (official first choice), backend (Ktor/Spring Boot), cross-platform mobile (KMP)
- **Not suitable for:** Scenarios requiring minimal syntax, traditional enterprise Java legacy code (interoperable but with learning cost)
- **Strengths:** 40%+ more concise than Java, built-in null safety, native coroutine support, 100% Java interop
- **Weaknesses:** Smaller community than Java, occasionally slow compilation, low visibility outside Android
- **Beginner friendliness:** &#11088;&#11088;&#11088;

### Go
- **Best for:** Cloud native / microservices, CLI tools, network services / API gateways, DevOps tools, high-performance middleware
- **Not suitable for:** Desktop GUI, mobile apps, machine learning, complex business logic (generics still less flexible than traditional OOP languages)
- **Strengths:** Extremely fast compilation, simple deployment (single binary), first-class concurrency (goroutines), clean syntax with enforced formatting
- **Weaknesses:** Lacks traditional UI frameworks, generics support is relatively new, complex dependency management history, more boilerplate for simple needs (explicit error handling)
- **Beginner friendliness:** &#11088;&#11088;&#11088;&#11088;

### Rust
- **Best for:** Systems programming, high-performance services, WebAssembly, embedded, blockchain, memory-safe low-level software
- **Not suitable for:** Rapid prototyping, UI-intensive applications, teams lacking systems programming experience
- **Strengths:** Zero-cost abstractions + memory safety (no GC), performance on par with C++, best-in-class compiler error messages
- **Weaknesses:** Very steep learning curve (ownership/borrowing/lifetimes), long compile times, young ecosystem with fewer libraries
- **Beginner friendliness:** &#11088;&#11088;

### C# (.NET)
- **Best for:** Windows desktop applications, Unity game development, enterprise backend (ASP.NET Core), Xbox/gaming consoles
- **Not suitable for:** Desktop development outside Windows (cross-platform desktop still maturing), traditional first choice for Linux servers
- **Strengths:** Extremely powerful LINQ data queries, first-class Visual Studio IDE, Microsoft's full cross-platform commitment, top choice for game development
- **Weaknesses:** Heavy Windows ecosystem imprint, smaller community than Java/JS, some advanced features require paid Visual Studio
- **Beginner friendliness:** &#11088;&#11088;&#11088;

### Swift
- **Best for:** iOS/macOS/watchOS/tvOS native apps, Apple ecosystem server-side (Vapor)
- **Not suitable for:** Non-Apple platforms, cross-platform mobile development (use Flutter/React Native instead)
- **Strengths:** Top-tier Apple official language support, modern and safe syntax, performance close to C++
- **Weaknesses:** Limited to Apple ecosystem, weak cross-platform capabilities, significantly smaller community than JS/Python
- **Beginner friendliness:** &#11088;&#11088;&#11088;

### Dart (Flutter)
- **Best for:** Cross-platform mobile apps (iOS + Android), Flutter Web, desktop applications (Windows/macOS/Linux)
- **Not suitable for:** Scenarios demanding pure iOS native experience, scenarios requiring extensive native platform API calls
- **Strengths:** Single codebase for multiple platforms, excellent Hot Reload development experience, built-in Material Design, Google's continuous investment
- **Weaknesses:** Dart language has poor generality (almost exclusively used for Flutter), non-standard UI effects require extensive customization, native features require Platform Channel
- **Beginner friendliness:** &#11088;&#11088;&#11088;&#11088;

## Scenario Quick Reference

| Scenario | First Choice | Alternative | Notes |
|----------|-------------|-------------|-------|
| Web full-stack | TypeScript + Next.js | Python + Django | Full-stack JS handles frontend and backend with one language |
| AI/ML applications | Python | -- | Overwhelming ecosystem advantage |
| Cross-platform mobile app | Flutter (Dart) | React Native (TypeScript) | Flutter has better performance, RN has larger ecosystem |
| iOS native | Swift | -- | Apple's official language, no alternative |
| Android native | Kotlin | Java | Kotlin is now the official first choice |
| Cloud native microservices | Go | Rust | Go is concise, Rust offers extreme performance |
| Enterprise backend | Java (Spring Boot) | C# (ASP.NET Core) | Java has the most mature ecosystem |
| CLI tools | Go | Python | Go compiles to a single file for easy distribution |
| Desktop applications | C# (.NET) + WPF | Electron (TypeScript) | C# is preferred for Windows, Electron for cross-platform |
| Game development | C# (Unity) | C++ (Unreal) | Unity is quick to pick up, Unreal has superior graphics |
| Embedded / IoT | Rust | C | Rust's safety makes it the first choice for new projects |
| Rapid prototyping | Python | TypeScript | Python has the fastest development speed |
| Systems programming | Rust | C++ | Rust's memory safety makes it the first choice for new projects |

---

## Maintenance

**Last review date:** 2026-06-28
**Data sources:** TIOBE Index, Stack Overflow 2025 Developer Survey, and practical experience

Language rankings and recommendations should be reviewed every **6 months**. When reviewing:
1. Check if emerging languages need to be added (e.g. Mojo, Zig, etc.)
2. Update language strength/weakness descriptions based on new version features (e.g. Java 21+ virtual threads, Python 3.13 performance improvements)
3. Verify that the first choice / alternative recommendations in the scenario table are still accurate
4. Maintain table format consistency (each row starts with `|` and ends with `|`)

**Update process:**
1. Modify the corresponding table rows in this file
2. If adding a new language, update the language option list in SKILL.md Step 0b (lines 83-92) accordingly
3. Update the "Last review date"
