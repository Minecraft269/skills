# AI Agent Project Pre-Launch Checklist (Reference)

> This document is the complete expanded version of the AI Agent project startup checklist. Load it when the user confirms the project type is AI Agent, or asks about agent-related risks and considerations.
>
> **Chapter Mapping**:
> - Chapter 1 → Step 1 of the 5-step process (Problem Definition)
> - Chapters 2–3 → Step 2 of the 5-step process (Capability Boundaries + Brain Architecture)
> - Chapter 4 → Step 3 of the 5-step process (Feasibility and Cost)
> - Chapters 5–6 → Step 3 Extension (Data and Frameworks)
> - Chapters 7–8 → AI Agent Additional Checks (Evaluation and Security)
> - Chapter 9 → Step 4 Extension (Team and Process)
>
> The full text follows below.

---

# Checklist Before Launching an AI Agent Project

When you are about to start an AI Agent project, the worst thing you can do is jump straight into coding and picking frameworks. The core of an agent is "autonomous decision-making + tool execution", which means the risk of losing control and the design complexity are far higher than traditional applications. Before you begin, walk through the framework below to ensure you have a clear understanding of "why build, how to build, and how to validate".

---

## 1. Define the Problem First, Then Define the Agent
- **Who is the user? What is the pain point?**
  Be clear whether the agent serves internal staff (e.g. automated ticket processing) or external customers (e.g. customer service chatbot). Different audiences have vastly different error tolerance.
- **What is the "end state" when the agent completes a task?**
  Is it outputting text, calling an API, modifying a database, or controlling physical devices? The more specific the end state, the clearer the boundaries.
- **Can the problem be solved without an agent?**
  If a deterministic rule engine can handle it (e.g. simple form filling), there is no need to force an agent. Agents are best suited for long chains, reasoning-heavy, multi-step planning, and ambiguous-instruction scenarios.

---

## 2. Define Capability Boundaries: What the Agent Can and Must Never Do
- **Explicitly list capabilities**: Reasoning, summarization, programming, search, which internal systems can be called…
- **Define "no-fly zones"**: Must not delete production data, must not make external transfers, must not send unapproved content. These guardrails must be built in from day one.
- **Determine interaction mode**:
  - Fully autonomous (scheduled trigger, no human intervention)
  - Human-in-the-loop (confirmation required for critical decisions)
  - Conversational (multi-turn clarification)
  The interaction mode directly determines architectural complexity.

---

## 3. Design the "Brain" Architecture (Diagram First, Code Later)
Break down the agent's reasoning process into basic components and draw the workflow:
- **Memory System**: How are short-term memory (conversation context) and long-term memory (user profiles, knowledge bases) stored and retrieved?
- **Planning Strategy**: ReAct (think-act loop), Plan-and-Execute (plan first, then execute), or multi-agent coordination? Is simple linear reasoning enough, or is tree search needed?
- **Tool Set**: What external tools does the agent need (search engine, calculator, CRM interface, code interpreter)? Each tool's input/output schema must be strictly defined.
- **Decision Logic**: When to call a tool? When to ask a human for help? When to terminate a task?

---

## 4. Evaluate Feasibility and Cost
- **Create a "paper prototype" with the strongest current model**
  Write the problem as a detailed prompt (without code) and manually simulate the agent going through the process. Observe whether the model can reliably complete the task within 3–5 steps. If even the strongest model frequently goes off track, the task needs simplification or more guardrails.
- **Do the math**: How many tokens does each task consume on average? Can latency meet business requirements? If expensive tools or large models are required, is the cost sustainable?
- **Flag critical risks**: For example, the safety cost of hallucinations leading to incorrect decisions, or the risk of prompt injection attacks. High-risk steps must have manual verification nodes.

---

## 5. Prepare Data and Knowledge Foundation
- **General knowledge vs. private knowledge**: What can the model handle independently, and what must be retrieved from internal documents via RAG (Retrieval-Augmented Generation)?
- **Knowledge base structure**: Unstructured documents, structured databases, real-time API data… Different sources require different indexing and retrieval strategies.
- **Maintenance mechanism**: How is knowledge updated? By whom? How is outdated information pruned?

---

## 6. Choose a Framework, But Don't Let the Framework Choose You
Popular options include LangChain, AutoGen, CrewAI, OpenAI Assistants, Dify, and more. Before choosing, answer:
- Is the team more familiar with Python or JS? Leaning toward low-code or full control?
- Is multi-agent coordination needed, or a single agent with multiple tools?
- Is streaming output, offline execution, or private deployment required?
Recommendation: First validate the core path with the lightest approach (e.g. direct model API calls + simple function calling), then introduce a framework for production engineering — avoid the abstraction trap.

---

## 7. Build an Evaluation System (Design from Day One)
- **What counts as "good"?**
  Task success rate, tool call accuracy, user satisfaction, latency, cost… These need to be quantified as specific metrics.
- **Build a "bad" scenario test set**
  Don't only test the happy path — design edge cases: user requests an unauthorized action, input is ambiguous, tool returns an error. Observe whether the agent can safely degrade or proactively ask for help.
- **Design a feedback loop**: How to collect explicit feedback (thumbs up/down) and implicit signals (repeated corrections, abandoned conversations), for continuous tuning?

---

## 8. Essential Security and Ethics Checks
- **Injection Protection**: User input, web content, and tool return values may all contain malicious instructions — they must be sanitized and isolated.
- **Least Privilege**: The agent must only be able to call interfaces necessary for the task. All write operations must be logged and may require secondary confirmation.
- **Transparency**: Always make it clear to users that they are interacting with AI. Exposing the AI's "reasoning process" to some degree increases credibility.
- **Compliance**: Sort out in advance where data is stored, privacy anonymization, and industry-specific regulatory requirements (e.g. finance, healthcare).

---

## 9. Team and Process Preparation
- **Required Roles**: Product manager (defines tasks and evaluation criteria), prompt engineer / AI engineer (designs reasoning chains and tools), backend/integration engineer, frontend (if user-facing), security reviewer.
- **Collaboration Process**: Use agile iteration — break large tasks into multiple "micro-capabilities", delivering incrementally. Re-evaluate agent performance each cycle and revise prompts and tool definitions.

---

## 📋 Actionable Checklist You Can Execute Immediately
1. **Write a one-page Agent Design Document** covering: problem to solve, user personas, success metrics, capability boundaries, core workflow (flowchart), and tool inventory.
2. **Manual Simulation**: In a browser, use GPT-4 or Claude, input instructions one by one, record outputs, and verify the entire task can be completed end-to-end.
3. **Implement the "Minimum Viable Agent" with minimal code**: One model call + one tool (e.g. search) — verify the end-to-end path.
4. **Define a test set**: At least 10 representative scenarios covering success, error, and edge cases.
5. **Convene stakeholders**: Reach consensus on the design document and risk points above, obtain explicit approval, then commit to full development.

> The difficulty with AI Agents is not "can we build it", but "once built, do you trust it enough to let it run". The deep thinking done upfront is exactly what gives you that confidence when it's time to let go.
