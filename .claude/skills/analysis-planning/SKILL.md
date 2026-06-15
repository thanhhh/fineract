---
name: analysis-planning
description: Pre-preparation and planning for integrated analysis. Pre-investigates the codebase, and proposes the optimal analysis approach based on client requirements. Designs the report table of contents and visualization plan. Use when asked for "pre-preparation for integrated analysis", "analysis planning", "analysis plan", or "want to decide an analysis approach".
---

# Analysis Planning

Before conducting integrated analysis, **pre-investigate the codebase**, **analyze client requirements**, and **design the report down to the table-of-contents level**.

## Trigger Keywords

- Pre-preparation for integrated analysis, pre-preparation for analysis
- Analysis planning, analysis plan
- Want to decide an analysis approach, analysis approach
- Want to create planning.md

---

## Attitude for This Skill

**Propose an analysis approach with ownership — exercise judgment**

- Rather than simply gathering requirements, investigate the code yourself to discover issues
- Understand the background and purpose of client requirements, and identify truly necessary analysis perspectives
- **Propose with specific reasoning: "Because the client is in this state, we should include these items"**
- **Specifically design the integrated report's table of contents and visualization plan**
- **Effectively place Mermaid diagrams and graphs to design an easy-to-understand report**

### Principles of Judgment-Driven Planning

**Rather than simply summarizing hearing results, explicitly state the analyst's views and recommendations.**

| NG (Passive)                                                          | OK (Judgment-Driven)                                                                                                                                                                                                                             |
| --------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| "Since you emphasized maintainability, we'll analyze maintainability" | "For the challenge of difficult maintenance, we should focus on 'implicit declaration risks' discovered in the technical investigation. This is a common cause of reduced maintainability in Fortran, directly linked to the client's challenge" |
| "Since you want all sections, we'll analyze everything"               | "All sections requested, but the large files (2,500+ lines) discovered in the code investigation are likely bottlenecks. We should strengthen the architecture analysis and include module splitting recommendations"                            |
| "Era-Context is for reference only, as stated"                        | "Era-Context for reference only, but Fortran 90 was a rational choice in the 2000s. Taking this into account, we'll use a dual evaluation of 'justified then, room for improvement now' to ensure fairness"                                      |

### Points Where Judgment Should Be Exercised

1. **Rationale for proposed focus sections**
   - "Because the client is struggling with ○○, we should prioritize analysis of △△"
   - "Because technical investigation revealed □□ as a typical problem, this should be confirmed"

2. **Basis for exclusion/reduction decisions**
   - "○○ has little relevance to the current challenge, so an overview is sufficient"
   - "△△ was found to have no issues in the technical investigation, so we can touch on it lightly"

3. **Design intent of report structure**
   - "Since the audience is management, the executive summary should be substantial"
   - "Since the purpose is migration decision-making, modernization options should be presented concretely"

4. **How to use technical investigation results**
   - "The Fortran common problem 'IMPLICIT implicit declaration' was detected, so this is set as a priority check item"
   - "Technical investigation revealed 'large subroutines are inhumane'. Multiple files exceed 2,500 lines, so splitting recommendations will be included"

---

## Execution Flow

### Phase 0: Document Availability Assessment (★★★ Required)

**Load the document-list.md created by asis-preparation and evaluate the sufficiency of information**

> **Prerequisites**: The `asis-preparation` skill has been executed and `02_asis_analysis/06_planning/document-list.md` exists.
> If it does not exist, guide the user to run the `asis-preparation` skill first.

#### 0-1. Load document-list.md

```
02_asis_analysis/06_planning/document-list.md
```

Contents to load:

- List of available documents (type, source location, target location)
- List of unprovided documents

#### 0-2. Priority Mapping (Internal Processing)

Compare the contents of document-list.md against the following priority list:

| Priority | Document Type              | Impact on Analysis | When Missing                           |
| :------: | -------------------------- | ------------------ | -------------------------------------- |
|  **S**   | Source Code                | Required           | Analysis not possible                  |
|  **A**   | Requirements Document      | High               | Infer design intent from code          |
|  **A**   | DB Design (ER Diagram/DDL) | High               | Generate ER diagram from DDL           |
|  **B**   | Test Specs/Test Data       | Medium-High        | Infer test cases from code             |
|  **B**   | Screen Design/UI Specs     | Medium-High        | Supplement by analyzing UI layer code  |
|  **B**   | External IF Specs          | Medium-High        | Identify integrations via code         |
|  **C**   | Operation Manuals          | Medium             | Infer from batch processing code       |
|  **C**   | Issue/Change History       | Medium             | Supplement via interviews              |
|  **D**   | Infrastructure Diagrams    | Low-Medium         | Treat as reference information         |
|  **D**   | Glossaries/Business Flows  | Low-Medium         | Infer from comments and variable names |

**Legend**: S=Required / A=Strongly recommended / B=Recommended / C=Useful if available / D=Reference info

#### 0-3. Interviewing When High-Priority Documents Are Missing

Only conduct when high-priority (S/A/B) documents are unprovided. **Must be conducted for each missing document.**

**Q1: Confirm whether to continue analysis**

```typescript
AskUserQuestion({
  questions: [
    {
      question: `The following important documents are unprovided:\n${missing_high_priority_list}\n\nShould we continue with the analysis in this state?`,
      header: "Continue Analysis",
      multiSelect: false,
      options: [
        {
          label: "Continue",
          description:
            "Missing information supplemented via code analysis (includes inference)",
        },
        {
          label: "Provide additional documents",
          description: "Restart after adding documents",
        },
        {
          label: "Limit scope",
          description: "Conduct with limited analysis scope",
        },
      ],
    },
  ],
});
```

**Q2: Confirm reason for missing documents** (for each high-priority document)

```typescript
AskUserQuestion({
  questions: [
    {
      question: `Please tell us why "${missing_doc}" was not provided`,
      header: "Reason Not Provided",
      multiSelect: false,
      options: [
        { label: "Does not exist", description: "Was never created" },
        {
          label: "Lost/scattered",
          description: "Existed previously but now unknown",
        },
        {
          label: "Cannot be provided",
          description:
            "Exists but cannot be provided due to confidentiality, etc.",
        },
        { label: "Not maintained", description: "Only exists fragmentarily" },
      ],
    },
  ],
});
```

#### 0-4. Determining Analysis Strategy Based on Reason for Missing Documents

| Reason Missing     | Analysis Strategy                                         | Record in planning.md                                              |
| ------------------ | --------------------------------------------------------- | ------------------------------------------------------------------ |
| **Does not exist** | Full supplement via code analysis. Note inferred sections | "No design docs. Reverse engineering from code"                    |
| **Lost/scattered** | Same + confirm if interview can supplement                | "Past documents lost. To be supplemented via verbal interview"     |
| **Cannot provide** | Note analysis limits. Relevant parts at overview level    | "Detailed analysis excluded due to confidentiality. Overview only" |
| **Not maintained** | Reference fragmentary info, combine with code analysis    | "Analyzed using partial information. Completeness has limitations" |

#### 0-5. Phase 0 Completion Report

```
## Document Availability Assessment Results

### Available Documents
| Type | Priority | Storage Location |
|------|:--------:|------------------|
| Source Code | S | 01_asis_code/src/ |
| Requirements Document | A | 02_DAC/requirements/ |

### Missing Documents
| Type | Priority | Missing Reason | Response Plan |
|------|:--------:|----------------|---------------|
| DB Design Document | A | Does not exist | Generate ER diagram from DDL |
| Test Specifications | B | Lost | Infer test cases from code |

Based on these results, we will begin the pre-investigation in Phase 1.
```

---

### Phase 0: Requirements Organization (Extraction from Received Documents and Meeting Minutes) [★ Execute First]

**Organize client challenges and requests from received documents and meeting minutes in the meetings folder**

In this phase, **systematically organize requirements from existing documents** before technical investigation or interviews.
The organized requirements will serve as the foundation for subsequent phases (technical investigation, interviews, analysis approach design).

#### 0-1. Confirm Received Documents and Convert to MD

Explore received documents and meeting minutes from the following folders:

```
meetings/ext/     # Client meeting minutes
meetings/int/     # Internal meeting minutes
01_asis_code/     # Provided design documents, RFPs, etc. (when bundled with source)
```

**Target files for exploration:**

- RFP (Request for Proposal)
- Requirements documents
- Meeting minutes
- Email records
- Other client-provided documents

##### 0-1-1. Convert RFPs and Important Documents to MD (★ Recommended)

**Convert Excel/Word/PDF documents to Markdown to organize information.**
This enables comprehensive understanding and easier subsequent processing.

**Conversion priority:**

| Priority | Document Type                 | Reason                                           |
| -------- | ----------------------------- | ------------------------------------------------ |
| 🔴 High  | RFP (Request for Proposal)    | Foundation of project requirements               |
| 🔴 High  | Requirements document         | Source of functional/non-functional requirements |
| 🟡 Med   | Meeting minutes (important)   | Record of agreements and decisions               |
| 🟢 Low   | Other supplementary materials | Convert as needed                                |

**Conversion process:**

1. **Check documents**

   ```
   Glob: meetings/**/*.{xlsx,xls,docx,doc,pdf,pptx,ppt}
   Glob: 01_asis_code/**/*.{xlsx,xls,docx,doc,pdf}
   ```

2. **Convert RFPs and important documents**
   - Read contents with the Read tool (supports Excel/PDF)
   - Organize in Markdown in the following format:

   ```markdown
   # [Document Name] - MD Converted Version

   > **Source File**: [file path]
   > **Conversion Date**: [date]
   > **Converted By**: CRA Team

   ---

   ## 1. Document Overview

   [Document purpose and positioning]

   ## 2. Contents

   ### 2.1 [Section Name]

   [Content organized in structured form]

   ### 2.2 [Section Name]

   [Content organized in structured form]

   ...

   ## 3. Key Points Extracted

   ### Requirements

   | #   | Requirement | Detail   | Source Location in Document |
   | --- | ----------- | -------- | --------------------------- |
   | 1   | [req]       | [detail] | [Page/Sheet name]           |

   ### Constraints

   - [Constraint 1]
   - [Constraint 2]

   ### Unclear Points / Items to Confirm

   - [Unclear point 1] → Confirm via interview
   - [Unclear point 2] → Confirm via interview

   ---

   📋 Converted by: CRA Team
   ```

3. **Store conversion results**
   ```
   02_asis_analysis/01_requirements/
   ├── source_docs/           # Converted MD files
   │   ├── RFP_converted.md
   │   ├── requirements_document_converted.md
   │   └── meeting_minutes_YYYYMMDD_converted.md
   └── requirements.md        # Integrated requirements document (created in 0-3)
   ```

**Confirmation via AskUserQuestion (when multiple documents exist):**

```
AskUserQuestion({
  questions: [
    {
      question: "The following documents were found. Please select which ones to convert to MD (multiple selections allowed)",
      header: "MD Conversion Targets",
      options: [
        { label: "[Document 1]", description: "[File type/size]" },
        { label: "[Document 2]", description: "[File type/size]" },
        { label: "[Document 3]", description: "[File type/size]" },
        { label: "Convert all", description: "Convert all found documents" }
      ],
      multiSelect: true
    }
  ]
})
```

**Report after conversion:**

```
📄 **RFP and important document MD conversion complete**

| Source Document | Converted File | Key Points Extracted |
|----------------|----------------|---------------------|
| [RFP.xlsx] | source_docs/RFP_converted.md | X requirements, Y constraints |
| [requirements.docx] | source_docs/requirements_document_converted.md | X requirements, Y unclear points |

Based on these conversion results, we will create the requirements document (requirements.md).
```

#### 0-2. Perspectives for Requirements Extraction

Extract and organize the following information from documents:

| Category                | Information to Extract                                              |
| ----------------------- | ------------------------------------------------------------------- |
| **Background**          | Why this project started, the trigger                               |
| **Current Issues**      | Problems and difficulties the client feels                          |
| **Goals/Objectives**    | What they want to achieve, definition of success                    |
| **Scope**               | Target systems, out-of-scope areas                                  |
| **Constraints**         | Budget, timeline, technical constraints, organizational constraints |
| **Stakeholders**        | Involved parties, decision-makers, report readers                   |
| **Expected Outputs**    | Reports, recommendations, migration plans, etc.                     |
| **Priority/Importance** | Perspectives they particularly value                                |

#### 0-3. Creating the Requirements Document

Organize information extracted from **MD-converted documents in 0-1-1** and **other received documents** in the following format and output to `02_asis_analysis/01_requirements/requirements.md`:

> **Source Priority**
>
> 1. MD-converted documents (`01_requirements/source_docs/`) ← Comprehensively organized
> 2. Meeting minutes under meetings/
> 3. Design documents, etc. under 01_asis_code/

```markdown
# Requirements Document

## 1. Project Overview

### 1.1 Background

[Background information extracted from documents]

> Source: From [filename]

### 1.2 Project Objectives

[What is to be achieved]

### 1.3 Scope

- **In scope**: [target systems/areas]
- **Out of scope**: [explicitly excluded items]

---

## 2. Current Issues

### 2.1 Issues Recognized by Client

| #   | Issue     | Detail   | Source        |
| --- | --------- | -------- | ------------- |
| 1   | [Issue 1] | [Detail] | [Source file] |
| 2   | [Issue 2] | [Detail] | [Source file] |

### 2.2 Issue Priority (Client Perspective)

- 🔴 High: [Most important issue]
- 🟡 Medium: [Next most important issue]
- 🟢 Low: [Relatively lower priority issue]

---

## 3. Requirements

### 3.1 Functional Requirements

| #    | Requirement | Detail   | Source   |
| ---- | ----------- | -------- | -------- |
| FR-1 | [Req 1]     | [Detail] | [Source] |

### 3.2 Non-Functional Requirements

| #     | Requirement | Detail   | Source   |
| ----- | ----------- | -------- | -------- |
| NFR-1 | [Req 1]     | [Detail] | [Source] |

### 3.3 Expected Outputs

- [ ] [Output 1]
- [ ] [Output 2]

---

## 4. Constraints

### 4.1 Technical Constraints

- [Constraint 1]

### 4.2 Organizational/Business Constraints

- [Constraint 1]

### 4.3 Schedule

- [Deadlines/milestones]

---

## 5. Stakeholders

| Role           | Name/Department | Area of Interest |
| -------------- | --------------- | ---------------- |
| Decision-maker | [Name]          | [Interest]       |
| Technical lead | [Name]          | [Interest]       |
| Report reader  | [Name]          | [Interest]       |

---

## 6. Success Criteria

- [Definition of success 1]
- [Definition of success 2]

---

## 7. Unclear Points / Items to Confirm

| #   | Unclear Point | How to Confirm        | Status      |
| --- | ------------- | --------------------- | ----------- |
| 1   | [Unclear 1]   | Confirm via interview | Unconfirmed |
| 2   | [Unclear 2]   | Confirm via interview | Unconfirmed |

---

📋 Created by: CRA Team
📅 Created: [Date]
📚 Referenced documents:

- MD-converted documents: [list of files under source_docs/]
- Other referenced documents: [document list]
```

#### 0-4. When Documents Are Insufficient

When received documents or meeting minutes are not found:

```
AskUserQuestion({
  questions: [
    {
      question: "No received documents or meeting minutes found in the meetings folder. How would you like to proceed?",
      header: "Document Confirmation",
      options: [
        { label: "Specify document location", description: "Documents are in a different location" },
        { label: "Collect via interview", description: "Confirm requirements through dialogue" },
        { label: "Start with minimal information", description: "Proceed with the assumption of adding more later" }
      ],
      multiSelect: false
    }
  ]
})
```

#### 0-5. Phase 0 Completion Guide

After creating the requirements document, report the following to the user:

```
✅ Requirements organization complete.

## MD-Converted Documents

| Source Document | Converted File |
|----------------|----------------|
| [Source file 1] | source_docs/[Converted file 1].md |
| [Source file 2] | source_docs/[Converted file 2].md |

## Created Files

📄 Requirements Document: 02_asis_analysis/01_requirements/requirements.md

## Key Information Extracted

| Category | Summary |
|---------|---------|
| Background | [1-line summary] |
| Key Issues | [number] issues |
| Requirements | [number] items |
| Constraints | [number] items |
| Items to Confirm | [number] unclear points (to be confirmed via interview)

## Next Steps

Based on this requirements document:
1. Collect technical knowledge related to the issues via tech-researcher
2. Confirm unclear points via interview
3. Design analysis approach

Continue to Phase 1 (codebase investigation)?
```

---

### Phase 1: Pre-Investigation (Codebase)

**Based on the requirements document, investigate the code to understand the system's characteristics**

#### 1-1. Review Existing Materials

```
02_asis_analysis/01_requirements/         # Requirements document (created in Phase 0)
02_asis_analysis/02_statistics/           # Check cloc statistics if available
02_asis_analysis/03_DAC/                  # Check design document conversion results if available
02_asis_analysis/04_technology_research/  # Check technology research results if available (recommended)
02_asis_analysis/05_hearing/              # Hearing results storage
02_asis_analysis/06_planning/             # Planning results storage
01_asis_code/                             # Check source code layout
```

> **Using the Requirements Document**
> Reference the `01_requirements/requirements.md` created in Phase 0 and
> focus on investigating areas related to client challenges and requirements.

> **Using Technology Research Results**
> If the `technology-research` skill was run beforehand,
> `04_technology_research/technology_research.md` contains common issues and modernization patterns specific to the language/framework.
> Reflecting this information in the analysis approach will produce an **analysis plan that resonates with the client**.
> If no research results exist, understand the tech stack from the quick scan below.

> ⚠️ **About documents in 02_DAC/**
> This folder contains documents provided by the client that have been converted to Markdown.
> **This is reference information only, and the content may be outdated, inaccurate, or incomplete.**
> If there are contradictions with the actual source code, the source code takes precedence.

#### 1-2. Review Technology Research Results (Important)

**If technology research results exist, always load them:**

```
02_asis_analysis/04_technology_research/technology_research.md
```

technology_research.md contains the following information:

| Section                      | How to Use                                                    |
| ---------------------------- | ------------------------------------------------------------- |
| Detected Technology Stack    | Understand analysis target technologies in advance            |
| Common Problems              | **Patterns to check intensively in analysis**                 |
| Known Limitations            | Recognize language/framework-specific constraints             |
| Modernization Patterns       | Reference for the recommendations section                     |
| Era-Context Considerations   | **Setting standards for temporal appropriateness evaluation** |
| Recommendations for Analysis | **Used to determine priority focus areas**                    |

> **When no technology research results exist**
> Recommend running the `technology-research` skill first.
> Or, call the tech-researcher Sub Agent in Phase 1-3 to conduct the research.

#### 1-3. Quick Codebase Scan

Investigate the following yourself:

| Investigation Item | How to Check                      | What to Understand                      |
| ------------------ | --------------------------------- | --------------------------------------- |
| Scale              | Directory structure, file count   | Criteria for analysis depth/breadth     |
| Technology stack   | package.json, pom.xml, extensions | Estimating era, setting evaluation axes |
| Architecture       | Folder structure, key classes     | Identifying priority analysis areas     |
| Complex areas      | Large files, deep nesting         | Technical debt candidates               |
| Test coverage      | test/, spec/ folders              | Perspective for quality evaluation      |

#### 1-4. Technology Research (tech-researcher Sub Agent) [Background Execution with Confirmation]

**If no technology research results exist, run a web investigation on the detected tech stack in the background**

After identifying the tech stack (languages, frameworks) in 1-3, **confirm with the user** before **launching the `tech-researcher` Sub Agent in the background**, running **the investigation in parallel with Phase 2 interviewing**.

> **Benefits of parallel processing**
>
> - Reduces user wait time
> - Investigation completes during interviews, enabling smooth transition to Phase 3
> - Results are obtained and integrated after Phase 2 is complete

**Restrictions on languages to investigate (important):**

- Investigate **only languages that exist in `01_asis_code/src/`**
- Do not add languages by inference

**Confirmation with user (required):**

Present the tech stack detected in 1-3 to the user and confirm execution of the background investigation:

```
I investigated the codebase and detected the following tech stack:

| Category | Technology | LOC | Notes |
|---------|-----------|-----|-------|
| Language | [detected language] | [lines] | [characteristics] |
| ... | ... | ... | ... |

Estimated development period: [period]

🔍 **Technology Research Proposal**

I can conduct a web investigation of common issues and modernization patterns for these technologies.
This can be run in the background in parallel with interviewing and used for analysis approach design in Phase 3.

Should we conduct a technology research?
```

Confirm using AskUserQuestion tool:

```
AskUserQuestion({
  questions: [
    {
      question: "Should we conduct a background web investigation on the detected technologies?",
      header: "Technology Research",
      options: [
        { label: "Conduct (recommended)", description: "Run research in parallel with interviewing" },
        { label: "Use existing results", description: "When technology_research.md already exists" },
        { label: "Skip", description: "Proceed without research" }
      ],
      multiSelect: false
    }
  ]
})
```

**Processing when "Conduct" is selected:**

Launch tech-researcher agent in the background using the Task tool:

```
{
  "subagent_type": "tech-researcher",
  "run_in_background": true,
  "description": "Technology research in progress",
  "prompt": "Please research the following technologies:

    - Language: [detected language (e.g., Fortran 90)]  ← Only languages detected from 01_asis_code/src/
    - Estimated period: [estimated development period]
    - Client concerns: [if known, otherwise 'general research']
    - Context: Modernization analysis of a legacy system

    Research points:
    1. Common issues and challenges with this language/framework
    2. Typical patterns that reduce maintainability
    3. Common approaches to modernization
    4. Recommended resources

    Output results to 02_asis_analysis/04_technology_research/technology_research.md"
}
```

After launch, notify the user:

```
🔄 **Technology research running in background**
tech-researcher Sub Agent is conducting technical research in parallel.
Results will be reflected as soon as they are available while we proceed with interviewing.

Proceeding to interviewing now.
```

**Timing for obtaining research results:**

- After Phase 2 interviewing is complete, obtain results using the `TaskOutput` tool
- Reflect results in Phase 3 analysis approach design

**How to use research results:**

- Results output to `02_asis_analysis/04_technology_research/technology_research.md`
- Referenced in Phase 3 analysis approach design to set analysis perspectives that resonate with the client
- Used as basis for Era-Context evaluation

> **When "Use existing results" is selected**
> Load `04_technology_research/technology_research.md` and use it in Phase 3
>
> **When "Skip" is selected**
> Proceed to Phase 2 interviewing without technology research

#### 1-5. Organizing Findings

Organize points noticed during the investigation:

- **Technical characteristics**: Technologies used, design patterns, era context
- **Potential issues**: Areas with high complexity, signs of technical debt
- **Notable points**: Unique implementations, domain-specific logic
- **Areas where visualization would be effective**: Dependencies, data flows, architecture
- **Insights from technology research**:
  - "Common problems" obtained from technology_research.md
  - Era-Context considerations (best practices of that era)
  - Priority focus area recommendations
  - Modernization pattern candidates

#### 1-6. Phase 1 Completion Guide

After pre-investigation is complete, report results to the user:

**When "Conduct" was selected for technology research:**

```
Codebase pre-investigation complete.
[Report summary of investigation results]

🔄 **Technology research running in background**
tech-researcher Sub Agent is conducting technical research in parallel.
Results will be reflected as soon as they are available while we proceed with interviewing.

Proceeding to interviewing now.
```

**When technology research was "Skipped" or "Using existing results":**

```
Codebase pre-investigation complete.
[Report summary of investigation results]

Proceeding to interviewing now.
```

---

### Phase 2: Understanding Client Requirements

**Review meeting minutes and requests to understand the true purpose of the analysis**
**(Technology research running in parallel in the background)**

#### 2-1. Review Meeting Minutes

```
meetings/ext/  # Client meeting minutes
meetings/int/  # Internal meeting minutes
```

Key points to check:

- Issues and concerns mentioned by the client
- Usage scenarios for analysis results (proposal materials, internal review, estimates, etc.)
- Stakeholder expectations
- **Who is the report audience (management, technical staff, both)?**

#### 2-2. Confirmation Interview with User

**Based on pre-investigation results**, confirm missing information. Conduct interviews in three stages: **goal state definition** → **basic questions** → **dynamic questions**.

> **Important: Use the AskUserQuestion tool**
> Always use the `AskUserQuestion` tool for multiple-choice questions.
> This allows users to answer by clicking options, enabling efficient interviewing.
> Only ask open-ended text questions when free-form answers are needed.

---

##### Step 0: Goal State Definition (★★★ Most Important)

**Ask this before all other questions.**
**All information selection and report structure will be back-calculated from this goal state.**

**0-1. Confirm Goal State (using AskUserQuestion tool)**

```
AskUserQuestion({
  questions: [
    {
      question: "What state do you want the reader to be in after reading this report? (multiple selections allowed)",
      header: "Goal State",
      options: [
        { label: "Able to make a decision", description: "Can decide yes/no, or which option to choose" },
        { label: "Understanding the current state", description: "Understanding what is happening, grasp of the overall picture" },
        { label: "Next actions are clear", description: "Knows specifically what to do" },
        { label: "At ease", description: "Situation is organized, vague anxiety resolved" }
      ],
      multiSelect: true
    },
    {
      question: "What feelings do you want the reader to have after reading?",
      header: "Emotion",
      options: [
        { label: "Reassured", description: "Calm after understanding the situation, feels it's in good hands" },
        { label: "Convinced", description: "Clear rationale, makes sense, feels 'I see'" },
        { label: "Motivated", description: "Wants to work on improvements, feels positive" },
        { label: "Sense of urgency", description: "Feels ignoring this would be bad, needs to act" }
      ],
      multiSelect: false
    },
    {
      question: "Conversely, what state do you absolutely not want the reader to be in after reading?",
      header: "State to Avoid",
      options: [
        { label: "Only anxiety remains", description: "Problem is understood, but don't know what to do" },
        { label: "Confused by too much information", description: "Too much information, can't tell what's important" },
        { label: "Insufficient basis for decision", description: "Want to decide but don't have the information" },
        { label: "Feels irrelevant", description: "Doesn't feel personally related, doesn't resonate" }
      ],
      multiSelect: true
    }
  ]
})
```

**0-2. Articulate the Goal State**

Upon receiving the answers, articulate and confirm the goal state:

```
Thank you. Let me confirm my understanding:

[Goal of this report]
After reading, the reader will be in a state of "[selected state]".
And they will feel "[selected emotion]".

[What to absolutely avoid]
They will not be in a state of "[selected state to avoid]".

Is this understanding correct?
```

> **Important: This goal state becomes the judgment criterion that runs throughout the entire report**
>
> - Information selection: Judged by "Is this necessary to achieve the goal?"
> - Structure decisions: Judged by "Is this order leading to the goal?"
> - Expression adjustments: Judged by "Is this an appropriate way to convey for this goal?"

---

##### Step 1: Basic Questions (Required)

First report investigation results in text, then ask questions using AskUserQuestion.

**1-1. Report Investigation Results (Text)**

```
Upon reviewing the code, it appears to be a [scale] system built with [tech stack].
[Discovered characteristics] are observed.

Let me ask a few questions.
```

**1-2. Basic Questions (using AskUserQuestion tool)**

```
AskUserQuestion({
  questions: [
    {
      question: "When was this system approximately developed?",
      header: "Development Period",
      options: [
        { label: "2020s", description: "Developed after 2020" },
        { label: "2010s", description: "Developed between 2010-2019" },
        { label: "2000s", description: "Developed between 2000-2009" },
        { label: "1990s or earlier", description: "Developed before 1999" }
      ],
      multiSelect: false
    },
    {
      question: "What is the main purpose of this analysis?",
      header: "Analysis Purpose",
      options: [
        { label: "Current state assessment", description: "For onboarding, system understanding" },
        { label: "Refactoring", description: "Consideration for code quality improvement" },
        { label: "Migration/replacement", description: "Decision material for tech migration or renewal" },
        { label: "Technical debt visualization", description: "Quantifying debt for reporting" }
      ],
      multiSelect: false
    },
    {
      question: "Who are the main readers of the report? (multiple selections allowed)",
      header: "Audience",
      options: [
        { label: "Management", description: "Decision-makers, those making investment decisions" },
        { label: "Technical leads", description: "Architects, tech leads" },
        { label: "Development team", description: "Developers who actually work with the code" },
        { label: "Client", description: "External customers" }
      ],
      multiSelect: true
    }
  ]
})
```

**1-3. Additional Open-Ended Confirmation (Text)**

Upon receiving answers to basic questions, confirm via text:

```
Thank you. Let me confirm a few additional points:
- Are there any specific areas or concerns you'd like us to focus on?
- Is there any other supplementary information?

(If none, please answer "Nothing in particular")
```

---

##### Step 2: Dynamic Questions (AsIs Analysis / Integrated Report Specific)

**Based on the answers to basic questions and pre-investigation results, select appropriate questions from the following and conduct additional interviews via AskUserQuestion.**

> **Approach**: Efficiently collect information necessary for AsIs analysis and integrated report creation.
> AskUserQuestion allows up to 4 questions per call. Split into multiple calls if needed.

---

###### A. Integrated Report Direction Confirmation (★★★ Required)

**Conduct in all cases: Questions to determine the integrated report's structure and focus**

```
AskUserQuestion({
  questions: [
    {
      question: "Which sections would you like the integrated report to develop in depth? (multiple selections allowed)",
      header: "Focus Sections",
      options: [
        { label: "Technical debt assessment", description: "Identifying and prioritizing issues" },
        { label: "Architecture analysis", description: "Visualizing structure and dependencies" },
        { label: "Code quality analysis", description: "Complexity, duplication, maintainability" },
        { label: "Modernization recommendations", description: "Improvement direction and recommended actions" }
      ],
      multiSelect: true
    },
    {
      question: "How much should Era-Context (historical background) evaluation be emphasized?",
      header: "Era-Context",
      options: [
        { label: "Important", description: "Fairly evaluate based on technical standards at time of development" },
        { label: "For reference only", description: "Mention supplementally with modern standards as primary" },
        { label: "Not needed", description: "Evaluate only by modern standards" }
      ],
      multiSelect: false
    },
    {
      question: "What level of detail should the report be?",
      header: "Level of Detail",
      options: [
        { label: "Executive-oriented", description: "Focused on overview and summary" },
        { label: "Standard", description: "Understandable by technical staff" },
        { label: "Detailed", description: "Including code-level analysis" }
      ],
      multiSelect: false
    }
  ]
})
```

---

###### B. Client Issue Deep-Dive (★★★ Required)

**Questions to clarify client challenges and concerns**

```
AskUserQuestion({
  questions: [
    {
      question: "What is the client's biggest challenge?",
      header: "Main Issues",
      options: [
        { label: "Maintenance is difficult", description: "Changes and fixes take a long time" },
        { label: "Talent shortage", description: "No one available who can handle the technology" },
        { label: "Failures/bugs", description: "Problems occur frequently" },
        { label: "Cannot scale", description: "Difficult to add new features" }
      ],
      multiSelect: true
    },
    {
      question: "What is the client's intention for the system's future?",
      header: "Future Direction",
      options: [
        { label: "Extend its life", description: "Maintain and improve the current system" },
        { label: "Considering migration", description: "Considering migration to new technology" },
        { label: "Replacement planned", description: "Planning full renewal" },
        { label: "Undecided", description: "Will decide after seeing the report" }
      ],
      multiSelect: false
    },
    {
      question: "What is the report's usage scenario?",
      header: "Usage Scenario",
      options: [
        { label: "Internal proposal", description: "Material for internal review at client" },
        { label: "Budget acquisition", description: "Securing budget for repairs/migration" },
        { label: "Vendor selection", description: "Material for requesting development companies" },
        { label: "Current state record", description: "For documentation/handover" }
      ],
      multiSelect: false
    }
  ]
})
```

---

###### C. Technical Debt Assessment Policy (★★☆ Recommended)

**Detailed confirmation regarding technical debt visualization**

```
AskUserQuestion({
  questions: [
    {
      question: "Which perspectives should be emphasized in technical debt assessment? (multiple selections allowed)",
      header: "Assessment Perspectives",
      options: [
        { label: "Maintainability", description: "Ease of changing code" },
        { label: "Readability", description: "Ease of understanding code" },
        { label: "Testability", description: "Ease of writing tests" },
        { label: "Security", description: "Vulnerabilities and risks" }
      ],
      multiSelect: true
    },
    {
      question: "Is quantification of debt necessary?",
      header: "Quantification",
      options: [
        { label: "Necessary", description: "Express with scores/numbers" },
        { label: "Nice to have", description: "For reference only" },
        { label: "Not needed", description: "Qualitative evaluation is sufficient" }
      ],
      multiSelect: false
    },
    {
      question: "Is presentation of improvement priorities necessary?",
      header: "Priority",
      options: [
        { label: "Necessary", description: "Clearly indicate priority order" },
        { label: "For reference only", description: "Only broad direction" },
        { label: "Not needed", description: "Leave judgment to the reader" }
      ],
      multiSelect: false
    }
  ]
})
```

---

###### D. Modernization Recommendation Direction (★★☆ Recommended)

**When the purpose is migration/replacement decision-making**

```
AskUserQuestion({
  questions: [
    {
      question: "What perspectives should be emphasized in modernization recommendations?",
      header: "Recommendation Perspectives",
      options: [
        { label: "Feasibility", description: "Whether it's practically executable" },
        { label: "Cost efficiency", description: "Return on investment" },
        { label: "Risk minimization", description: "Reducing failure risk" },
        { label: "Future-proofing", description: "Long-term technology trends" }
      ],
      multiSelect: true
    },
    {
      question: "What level of specificity should the recommendations be?",
      header: "Specificity",
      options: [
        { label: "Direction only", description: "Presenting broad options" },
        { label: "Roadmap", description: "Phased plan proposal" },
        { label: "Detailed plan", description: "Specific tasks and steps" }
      ],
      multiSelect: false
    },
    {
      question: "Is it necessary to present candidate migration target technologies?",
      header: "Technology Candidates",
      options: [
        { label: "Necessary", description: "Recommend specific technologies" },
        { label: "For reference only", description: "Mention as options" },
        { label: "Not needed", description: "Current state analysis alone is sufficient" }
      ],
      multiSelect: false
    }
  ]
})
```

---

###### E. Audience/Recipient Detail Confirmation (★★☆ Recommended)

**When "client" is included among the audience**

```
AskUserQuestion({
  questions: [
    {
      question: "How technically knowledgeable is the client?",
      header: "Technical Understanding",
      options: [
        { label: "High", description: "Can understand technical details" },
        { label: "Moderate", description: "Understands basic terms" },
        { label: "Low", description: "Needs explanations for non-technical people" }
      ],
      multiSelect: false
    },
    {
      question: "What about use of sensitive expressions?",
      header: "Expression Considerations",
      options: [
        { label: "No issue", description: "Using terms like 'debt' and 'problems' is OK" },
        { label: "Need consideration", description: "Use neutral expressions" },
        { label: "Need to consult", description: "Expressions need prior confirmation" }
      ],
      multiSelect: false
    },
    {
      question: "Is explanation of technical terms necessary?",
      header: "Term Explanation",
      options: [
        { label: "Necessary", description: "Add glossary or annotations" },
        { label: "Minimal", description: "Only important terms" },
        { label: "Not needed", description: "Technical audience, no issue" }
      ],
      multiSelect: false
    }
  ]
})
```

---

###### F. Confirmation Based on Code Investigation Results (★☆☆ Situation-Dependent)

Compose AskUserQuestion based on findings from Phase 1 investigation:

**When test code does not exist:**

```
AskUserQuestion({
  questions: [
    {
      question: "How should the absence of tests be handled in the report?",
      header: "Absence of Tests",
      options: [
        { label: "Important issue", description: "Mention prominently as technical debt" },
        { label: "Record as issue", description: "Record as a problem" },
        { label: "Reference only", description: "Mention lightly" }
      ],
      multiSelect: false
    }
  ]
})
```

**When multiple languages/technologies are mixed:**

```
AskUserQuestion({
  questions: [
    {
      question: "How should the technology mix be handled in the report?",
      header: "Technology Mix",
      options: [
        { label: "Recommend integration", description: "Include recommendations for technology unification" },
        { label: "Maintain current state", description: "Limit to analysis of each technology" },
        { label: "To be considered", description: "Decide after seeing analysis results" }
      ],
      multiSelect: false
    }
  ]
})
```

**When large files (1000+ lines) exist:**

```
AskUserQuestion({
  questions: [
    {
      question: "How deeply should large files be analyzed?",
      header: "Large Files",
      options: [
        { label: "Detailed analysis", description: "Include splitting and refactoring proposals" },
        { label: "Identify issues", description: "Record as complexity issue" },
        { label: "Overview only", description: "Just record their existence" }
      ],
      multiSelect: false
    }
  ]
})
```

---

###### G. Technology Research Results Confirmation (★★☆ Recommended)

**When technology_research.md exists**

```
AskUserQuestion({
  questions: [
    {
      question: "Of the issues reported in the technology research, which would you like analyzed first? (multiple selections allowed)",
      header: "Priority Analysis",
      options: [
        { label: "[Issue 1]", description: "[Issue 1 explanation]" },
        { label: "[Issue 2]", description: "[Issue 2 explanation]" },
        { label: "[Issue 3]", description: "[Issue 3 explanation]" },
        { label: "All equal", description: "No particular priority" }
      ],
      multiSelect: true
    },
    {
      question: "How should the technology research insights be reflected in the report?",
      header: "Research Reflection",
      options: [
        { label: "Dedicated section", description: "Record technology research insights separately" },
        { label: "Integrate throughout", description: "Incorporate into relevant analysis sections" },
        { label: "For reference only", description: "Cite as needed" }
      ],
      multiSelect: false
    }
  ]
})
```

---

###### H. Report Output Confirmation (★☆☆ Situation-Dependent)

> **Mermaid diagram usage policy (no confirmation needed)**
> Mermaid diagrams (architecture diagrams, flow diagrams, ER diagrams, etc.) should be **used proactively**.
> No need to confirm with users. Place appropriate diagrams effectively according to codebase characteristics.

```
AskUserQuestion({
  questions: [
    {
      question: "What is the preferred format for the report?",
      header: "Format",
      options: [
        { label: "Markdown", description: "Text-based, easy to edit" },
        { label: "PDF", description: "For printing/formal submission" },
        { label: "No preference", description: "Any format is fine" }
      ],
      multiSelect: false
    },
    {
      question: "How many diagrams and figures?",
      header: "Diagram Volume",
      options: [
        { label: "More", description: "Easy to understand visually" },
        { label: "Standard", description: "Appropriately in necessary places" },
        { label: "Less", description: "Text-centered" }
      ],
      multiSelect: false
    }
  ]
})
```

---

###### I. Analysis Scope Confirmation (★☆☆ Situation-Dependent)

```
AskUserQuestion({
  questions: [
    {
      question: "Are there any areas that should be excluded from analysis?",
      header: "Excluded Areas",
      options: [
        { label: "No exclusions", description: "Everything is an analysis target" },
        { label: "Confidential modules", description: "Excluded for security reasons" },
        { label: "Third-party", description: "External libraries excluded" },
        { label: "Specific functions", description: "Exclude certain functionality" }
      ],
      multiSelect: true
    },
    {
      question: "Besides source code, what else would you like to include in analysis? (multiple selections allowed)",
      header: "Additional Targets",
      options: [
        { label: "DB design", description: "Database structure" },
        { label: "Configuration files", description: "Various settings/environment variables" },
        { label: "Documentation", description: "Existing design documents" },
        { label: "Code only", description: "Source code is sufficient" }
      ],
      multiSelect: true
    }
  ]
})
```

---

###### J. Past History Confirmation (☆☆☆ Only When Needed)

```
AskUserQuestion({
  questions: [
    {
      question: "Has there been previous analysis or improvement attempts on this system?",
      header: "Past Efforts",
      options: [
        { label: "Yes (successful)", description: "Previous improvements were successful" },
        { label: "Yes (unsuccessful)", description: "Did not go well" },
        { label: "No", description: "This is the first time" },
        { label: "Unknown", description: "Not aware of" }
      ],
      multiSelect: false
    },
    {
      question: "Are there existing analysis materials or documentation?",
      header: "Existing Materials",
      options: [
        { label: "Yes", description: "There are materials that can be referenced" },
        { label: "No", description: "This is the first time" },
        { label: "Unknown", description: "Needs confirmation" }
      ],
      multiSelect: false
    }
  ]
})
```

---

###### K. Operational Status Confirmation (☆☆☆ Only When Needed)

```
AskUserQuestion({
  questions: [
    {
      question: "What is the current maintenance structure?",
      header: "Maintenance Structure",
      options: [
        { label: "Dedicated team", description: "Team specialized for this system" },
        { label: "Shared responsibilities", description: "Also responsible for other systems" },
        { label: "Outsourced", description: "Delegated to a vendor" },
        { label: "No structure", description: "No clear structure" }
      ],
      multiSelect: false
    },
    {
      question: "Is there dependence on key individuals (siloing)?",
      header: "Knowledge Siloing",
      options: [
        { label: "High", description: "Depends on specific individuals" },
        { label: "Moderate", description: "Some areas are dependent" },
        { label: "Low", description: "Knowledge is distributed" },
        { label: "Unknown", description: "Not aware of" }
      ],
      multiSelect: false
    }
  ]
})
```

---

##### Step 3: Organizing and Confirming Information

After receiving dynamic question answers, organize and confirm understanding with the user:

```
Thank you. Let me organize the information gathered so far:

[Report Goal State] ★Most Important
After reading, the reader will:
- Be in a state of [selected state]
- Feel [selected emotion]
- Absolutely NOT be in a state of "[state to avoid]"

[Main Audience]
- [Summary of audience]

[Analysis Purpose]
- [Summary of purpose]

[Priority Analysis Areas] (information needed to achieve the goal)
- [Area 1]: [Why it's needed to achieve the goal]
- [Area 2]: [Why it's needed to achieve the goal]

[Areas to Exclude from Analysis] (information not needed to achieve the goal)
- [Excluded area]: [Why it's not needed]

[Key Points from Technology Research]
- [Point 1]
- [Point 2]

[Report Format]
- [Summary of format]

Is this understanding correct? Please let me know if there are additions or corrections.
```

---

##### Interviewing Guidelines

1. **Conversational approach**: Don't ask many questions at once; ask 2-3 questions and wait for answers
2. **Branching based on answers**: Dynamically select next questions based on response content
3. **Confirmation and summary**: Summarize understanding after each round and confirm
4. **Judgment to probe further**: Ask follow-up questions for ambiguous responses or important perspectives
5. **Judgment to end**: Finish when sufficient information has been obtained to formulate an analysis approach

---

##### Question Category Selection Guide

**Priority table when unsure which category to use (AsIs analysis / integrated report specific):**

| Priority           | Category                                    | Usage Condition                                               |
| ------------------ | ------------------------------------------- | ------------------------------------------------------------- |
| ★★★ Required       | A. Integrated report direction confirmation | Clarify focus sections and level of detail for report         |
| ★★★ Required       | B. Client issue deep-dive                   | Understand issue priority and background                      |
| ★★☆ Recommended    | C. Technical debt assessment policy         | Determine debt evaluation criteria and expression method      |
| ★★☆ Recommended    | D. Modernization recommendation direction   | Confirm scope and approach for recommendations                |
| ★★☆ Recommended    | E. Audience/recipient detail confirmation   | Adjust report expression and tone                             |
| ★☆☆ Situational    | F. Code investigation result confirmation   | When there are noteworthy findings from Phase 1               |
| ★★☆ Recommended    | G. Technology research confirmation         | When technology_research.md exists                            |
| ★☆☆ Situational    | H. Report output confirmation               | When there are specific format/diagram requests               |
| ★☆☆ Situational    | I. Analysis scope confirmation              | When there appear to be excluded areas/constraints            |
| ☆☆☆ Only if needed | J. Past history confirmation                | When there are past failure experiences or existing materials |
| ☆☆☆ Only if needed | K. Operational status confirmation          | When there are concerns about siloing/maintenance structure   |

---

##### Recommended Question Flows by Purpose (AsIs Analysis / Integrated Report)

**Standard AsIs analysis:**

```
Basic questions → A (direction) → B (issues) → C (debt assessment) → E (audience)
```

**Technical debt visualization focus:**

```
Basic questions → A (direction) → B (issues) → C (debt assessment) → G (tech research) → D (recommendations)
```

**Modernization proposal focus:**

```
Basic questions → A (direction) → D (recommendations) → G (tech research) → F (code investigation) → H (output)
```

**Management-oriented report:**

```
Basic questions → A (direction) → E (audience) → C (debt assessment) → D (recommendations) → H (output)
```

**Detailed technical report:**

```
Basic questions → A (direction) → F (code investigation) → G (tech research) → I (scope) → K (operations)
```

---

##### Deep-Dive Patterns for Ambiguous/Insufficient Answers

| Ambiguous Answer Example                 | Follow-up Question                                                       |
| ---------------------------------------- | ------------------------------------------------------------------------ |
| "Nothing in particular" / "I don't know" | "For example, how about perspectives like ○○ or △△?"                     |
| "Everything is important"                | "If you had to choose just one?" / "What's the most troublesome issue?"  |
| "I'll think about it later"              | "Should we proceed with a tentative plan and adjust later?"              |
| "I don't know about technical things"    | "Are there any challenges or expectations from the business side?"       |
| "My predecessor handled it"              | "Is there any information or challenges inherited from the predecessor?" |

---

> **Estimated number of interview rounds**
>
> - Simple cases: Basic questions + confirmation = 2 rounds
> - Standard cases: Basic questions + 1-2 dynamic question types + confirmation = 3-4 rounds
> - Complex cases: Basic questions + 3+ dynamic question types + deep-dive + confirmation = 5-6 rounds

---

#### 2-3. MD Output of Interview Results

**After interviewing is complete, output results to a separate file:**

```
02_asis_analysis/05_hearing/hearing_result.md
```

**Output contents:**

- Date and time of interview
- Person in charge
- List of basic question answers
- List of dynamic question answers (only questions that were conducted)
- Additional comments/supplementary information
- Summary of confirmed understanding

> **Purpose**
>
> - Record raw interview information separate from the planning results (`06_planning/planning.md`)
> - Used for later reference and audit trail
> - planning.md is positioned as a processed/organized output of the interview results

#### 2-4. Obtaining Background Technology Research Results

**Execute only when "Conduct" was selected for technology research in Phase 1-4:**

After interviewing is complete, obtain the results of the background-launched technology research:

```
Use TaskOutput tool to obtain results:
- task_id: [ID of SubAgent launched in Phase 1-4]
- block: true (wait until complete)
```

**The obtained results will be used in Phase 3 analysis approach design.**

**When "Skip" or "Use existing results" was selected:**

- Skip the TaskOutput call
- For "Use existing results", load `02_asis_analysis/02_technology_research/technology_research.md`

#### 2-5. Phase 2 Completion Guide

After interviewing is complete, tell the user:

**When "Conduct" was selected for technology research:**

```
Interviewing complete.

📝 **Interview results saved**
→ 02_asis_analysis/05_hearing/hearing_result.md

✅ **Technology research also complete**
→ 02_asis_analysis/04_technology_research/technology_research.md

Moving to Phase 3 to design and propose the analysis approach.
```

**When "Use existing results" was selected:**

```
Interviewing complete.

📝 **Interview results saved**
→ 02_asis_analysis/05_hearing/hearing_result.md

📚 **Referencing existing technology research results**
→ 02_asis_analysis/04_technology_research/technology_research.md

Moving to Phase 3 to design and propose the analysis approach.
```

**When "Skip" was selected:**

```
Interviewing complete.

📝 **Interview results saved**
→ 02_asis_analysis/05_hearing/hearing_result.md

Moving to Phase 3 to design and propose the analysis approach.
```

---

### Phase 3: Analysis Approach Design and Proposal

**Back-calculate from the goal state and design a report containing only necessary information**

#### 3-0. Back-Calculation from Goal State (★ Most Important)

**Before designing the report, clarify the following:**

```markdown
## Back-Calculation from Goal State

### Reader's Goal State (defined in Step 0)

- State after reading: [can make a decision / understand current state / action is clear / at ease]
- Emotion after reading: [reassured / convinced / motivated / sense of urgency]
- State to avoid: [only anxiety / information overload / insufficient basis / irrelevant]

### Information Needed to Achieve This Goal

| What the reader needs to know | Why it's needed    | Where in the report to convey it |
| ----------------------------- | ------------------ | -------------------------------- |
| [Information 1]               | [Relation to goal] | [Section]                        |
| [Information 2]               | [Relation to goal] | [Section]                        |

### Information Not Needed for This Goal (not to include)

| Information to exclude | Why it's not needed                            |
| ---------------------- | ---------------------------------------------- |
| [Information A]        | Does not contribute to goal / causes confusion |
| [Information B]        | "Nice to have" level, not essential            |

### Report Flow (Reader Experience Design)

1. First convey ○○ → reader feels "△△"
2. Next show ○○ → reader understands "△△"
3. Finally propose ○○ → reader is in a state where they can "△△"
```

#### 3-1. Determining Integrated Report Direction

**Report design based on goal state:**

| Analysis Purpose         | Audience               | Report Focus             | Key Visualizations                            |
| ------------------------ | ---------------------- | ------------------------ | --------------------------------------------- |
| Current state assessment | Technical staff        | Structural understanding | Architecture diagram, component diagram       |
| Refactoring              | Technical staff        | Areas to improve         | Complexity heat map, dependency diagram       |
| Migration decision       | Management + Technical | Risk/cost                | Risk matrix, phased migration diagram         |
| Debt visualization       | Management             | Quantitative data        | Pie charts, bar charts, evaluation tables     |
| Estimation material      | PM / Management        | Scale/complexity         | Scale comparison graph, effort impact factors |

#### 3-2. Designing the Report Table of Contents

**First reference the following template as a guide for the TOC structure:**

```
.claude/skills/analysis-planning/report_template.md
```

(Original file: `02_asis_analysis/03_analysis_reports/template.md`)

The template contains the standard structure from Chapter 0 to Chapter 6, expression methods for each section, and concrete examples of Mermaid diagrams.
**However, the template is only a reference. Customize flexibly to match actual code characteristics and client interests.**

**Design a specific table of contents and visualization plan:**

```markdown
## Integrated Report Draft Table of Contents

### 1. Executive Summary

- System overview (1 paragraph)
- Key findings (bullet list of 3-5 points)
- Technical debt score
- Recommended actions

📊 **Visualization**: Technical debt score radar chart

### 2. System Overview

#### 2.1 Technology Stack

#### 2.2 Scale/Structure

📊 **Visualizations**:

- Pie chart of code lines by language
- Tree diagram of directory structure

### 3. Architecture Analysis

#### 3.1 Overall Structure

#### 3.2 Layer Structure

#### 3.3 Key Components

📊 **Visualizations**:

- Architecture overview diagram (Mermaid)
- Inter-layer dependency diagram (Mermaid)
- Component relationship diagram (Mermaid)

### 4. Code Quality Analysis

#### 4.1 Complexity Analysis

#### 4.2 Duplicate Code

#### 4.3 Test Coverage

📊 **Visualizations**:

- Complexity heat map (file × complexity)
- Top 10 complex files (bar chart)

### 5. Dependency Analysis

#### 5.1 External Dependencies

#### 5.2 Internal Dependencies

#### 5.3 Circular Dependencies

📊 **Visualizations**:

- Circular dependency diagram (Mermaid)
- Dependency matrix

### 6. Data Model Analysis

#### 6.1 Entity List

#### 6.2 Relationships

📊 **Visualizations**:

- ER diagram (Mermaid)
- Data flow diagram (Mermaid)

### 7. Dual-Scale Evaluation

#### 7.1 Era-Context Evaluation

#### 7.2 Modern-Ref Evaluation

#### 7.3 Evaluation Matrix

📊 **Visualizations**:

- Dual-scale evaluation table
- Improvement cost/effect matrix

### 8. Recommendations

#### 8.1 Priority Actions

#### 8.2 Medium/Long-term Improvement Plan

#### 8.3 Risks and Countermeasures

📊 **Visualizations**:

- Priority matrix (impact × urgency)
- Improvement roadmap (Mermaid Gantt-style)
```

#### 3-3. Reflecting Technology Research Results in Analysis Approach

**When technology_research.md exists, reflect the following in the analysis approach:**

1. **Setting priority check items**
   - Set "Common Problems" as check points in the analysis
   - Example: If "Heavy use of COMMON/EQUIVALENCE" is noted for Fortran 90, prioritize analyzing relevant locations

2. **Refining Era-Context standards**
   - Adopt best practices of the era from the "Era-Context Considerations" section as evaluation criteria
   - Example: "Not using IMPLICIT NONE was acceptable until the early 2000s" → consider in evaluation

3. **Substantiating recommendations**
   - Record "Modernization Patterns" as reference for the recommendations section
   - Also cite rough effort/risk estimates

4. **Relating to client challenges**
   - If a "Relationship to client challenges" section exists, reflect its research focus in the analysis approach

#### 3-4. Analysis Approach Proposal (Judgment-Driven)

**Rather than simply summarizing interview results, make a proposal that explicitly states "why things should be this way."**

```markdown
## Analysis Approach Proposal

### My View: Analysis Required for This System

**Client's current state:**
[Summarize client challenges and concerns in 1-2 sentences]

**Analyst's judgment on this state:**
[Why you are proposing this analysis approach, with clear rationale]

---

### 1. Items That Should Be Analyzed in Depth (with rationale)

| Item     | Why it should be included                                 | Basis                  |
| -------- | --------------------------------------------------------- | ---------------------- |
| [Item 1] | Because the client is struggling with ○○                  | Interview results      |
| [Item 2] | Because "common problem" was pointed out in tech research | technology_research.md |
| [Item 3] | Because △△ was discovered in code investigation           | Phase 1 investigation  |

**Specific proposals:**

1. **[Item 1] should be analyzed in depth**
   - **Relationship to client challenges**: [How it relates]
   - **Support from technical research**: [Alignment with common problems]
   - **What to confirm in analysis**: [Specific check points]

2. **[Item 2] should be included**
   - **Reason**: [Why it's needed]
   - **Expected value**: [Its meaning to the client]

---

### 2. Items That Can Be Reduced/Excluded (with rationale)

| Item     | Reason for reduction/exclusion                |
| -------- | --------------------------------------------- |
| [Item A] | Has little relevance to the current challenge |
| [Item B] | Found to have no issues in technical research |
| [Item C] | Already agreed as out of scope                |

---

### 3. "Common Problem" Checklist from Technology Research

> **Set common problems for this language/framework as priority check items**

| Common Problem                                    | Likelihood in this codebase              | How to address in analysis                                                   |
| ------------------------------------------------- | ---------------------------------------- | ---------------------------------------------------------------------------- |
| [Problem 1: e.g. "IMPLICIT implicit declaration"] | High (detected in code investigation)    | Check IMPLICIT statements in each file, identify problems                    |
| [Problem 2: e.g. "Large subroutines"]             | High (multiple files exceed 2,500 lines) | Complexity analysis to identify split candidates, include in recommendations |
| [Problem 3: e.g. "Global variable dependency"]    | Medium (modata module used)              | Visualize with dependency diagram, highlight impact scope                    |

---

### 4. Report Structure Design Intent

**Why this structure:**

| Section                       | Design Intent                                                                                        |
| ----------------------------- | ---------------------------------------------------------------------------------------------------- |
| Executive Summary             | Expand for management audience. Explicitly show technical debt score as investment decision material |
| Architecture Analysis         | Visualize causes of difficult maintenance. Identify bottlenecks with module dependency diagram       |
| Code Quality Analysis         | Concretely show locations matching "common problems". Present improvement priorities                 |
| Modernization Recommendations | Provide comparison table with multiple options since migration is being considered                   |

---

### 5. Integrated Report Draft Table of Contents

[Customized TOC based on client challenges]

### 6. Visualization Plan

| Section | Visualization Type | Purpose |
| ------- | ------------------ | ------- |
| ...     | ...                | ...     |

---

### Summary of Rationale for This Approach

1. **Client challenges**: [challenge] → Therefore [response]
2. **Technology research results**: [common problems] → Therefore [focus check]
3. **Code investigation findings**: [finding] → Therefore [include]

Is this approach acceptable? Please let us know if adjustments are needed.
```

#### 3-5. Phase 3 Completion Guide

When the user approves the approach, tell them:

```
The analysis approach has been approved. Phase 4 will create planning.md.

💡 **Context Management Request**
A lot of information was organized during approach design.
We recommend running the `/compact` command to organize context before creating planning.md.
(Optional, but helps maintain response quality in long conversations)
```

---

### Phase 4: Creating planning.md

After user approval:

1. Load `prompts/templates/analysis_planning_template.md`
2. Embed research results and agreed approach in the template
3. **[Most Important] Record the "Reader Goal State" section at the beginning**
4. **Clearly record the report table of contents and visualization plan**
5. Save as `02_asis_analysis/06_planning/planning.md`
6. Guide preparation for running the `integrated-analysis` skill (or `/integrated-analysis`)

#### Required Structure for planning.md

```markdown
# Analysis Planning

## Reader Goal State (★ Most Important)

### After reading this report, the reader will:

- **What state**: [can make a decision / understand current state / action is clear / at ease]
- **What feelings**: [reassured / convinced / motivated / sense of urgency]

### What to Absolutely Avoid

- [only anxiety remains / confused by too much info / insufficient decision material / feels irrelevant]

### Information Selection Criteria

Include **only information necessary** to achieve this goal in the report.
Do not include information that is "convenient to have" or "just in case."

---

## Information Availability Matrix (★★★ Required)

> Record results of evaluation in Phase 0

### Available Information

| Type         |  Priority  | Storage Location     | Freshness | Reliability    |
| ------------ | :--------: | -------------------- | --------- | -------------- |
| Source Code  |     S      | 01_asis_code/src/    | Latest    | High           |
| Requirements |     A      | 02_DAC/requirements/ | [years]   | [High/Med/Low] |
| [Other]      | [priority] | [path]               | [years]   | [High/Med/Low] |

### Missing Information and Response Plan

| Type            |  Priority   | Missing Reason                                    | Response Plan                    |
| --------------- | :---------: | ------------------------------------------------- | -------------------------------- |
| [Document name] | [S/A/B/C/D] | [does not exist/lost/cannot provide/unmaintained] | [code analysis supplement, etc.] |

### Analysis Limitations and Notes

- [Analysis limitations due to missing information]
- [Sections that include inference]
- [Areas excluded from detailed analysis due to confidentiality, etc.]

---

## Audience and Purpose

[Items below, from existing sections...]
```

#### Phase 4 Completion Guide (Skill Ends)

After creating planning.md, tell the user:

```
✅ Analysis planning complete.

Created file: `02_asis_analysis/06_planning/planning.md`

## Next Steps

Ready to run integrated analysis.

| Command/Skill | Description |
|--------------|-------------|
| `/integrated-analysis` | Run comprehensive code analysis based on planning.md |
| `integrated-analysis` | Same (via skill) |

💡 **Important: Context Management**
A lot of information was processed during analysis planning.
**Please run the `/compact` command before starting integrated analysis.**
This ensures sufficient context capacity for the integrated analysis phase.

Ready to start integrated analysis?
```

---

## Visualization Guidelines

### Mermaid Diagram Use Cases

| Diagram Type    | Use                           | Examples                                |
| --------------- | ----------------------------- | --------------------------------------- |
| flowchart       | Architecture, processing flow | System configuration, data flow         |
| classDiagram    | Class relationships           | Domain model, inheritance hierarchy     |
| erDiagram       | Data model                    | Table relationships, ER diagram         |
| sequenceDiagram | Processing sequences          | API calls, event flow                   |
| graph           | Dependencies                  | Module dependencies, circular deps      |
| pie             | Composition ratios            | Language ratios, file types             |
| gantt           | Roadmap                       | Improvement plan (order only, no dates) |

### Graph/Table Use Cases

| Type        | Use                     | Expression Method            |
| ----------- | ----------------------- | ---------------------------- |
| Bar chart   | Comparison, ranking     | Markdown table + description |
| Pie chart   | Composition ratios      | Mermaid pie or description   |
| Heat map    | Complexity distribution | Color-coded Markdown table   |
| Matrix      | Two-axis evaluation     | Markdown table               |
| Radar chart | Multi-axis evaluation   | Description + score table    |

### Visualization Principles

1. **1-2 diagrams per section**: Too many diagrams makes reading harder
2. **Explanation immediately after diagram**: Clearly state what it shows
3. **Clear legend**: Explain meaning of colors and symbols
4. **Keep it simple**: Avoid cramming in too much information

---

## Pre-Proposal Checklist

Confirm before proposing an analysis approach:

- [ ] **Was document-list.md loaded and document availability assessed?**
- [ ] **When high-priority documents are missing, was the reason investigated and response strategy decided?**
- [ ] Was the code actually investigated to understand technical characteristics?
- [ ] Was the background and purpose of client requirements understood?
- [ ] Was the report audience identified?
- [ ] Was a report structure designed appropriate to the analysis purpose?
- [ ] **Was a specific table of contents created?**
- [ ] **Was a visualization plan established for each section?**
- [ ] Were Era-Context evaluation criteria established?
- [ ] Was the scope (In/Out) clearly defined?
- [ ] **Was the information availability matrix included in planning.md?**

---

## Reference Template

When designing the report structure, refer to the following template:

```
.claude/skills/analysis-planning/report_template.md
```

(Original file: `02_asis_analysis/03_analysis_reports/template.md`)

This template includes:

- Standard structure from Chapter 0 to Chapter 6
- Content and expression methods for each section
- Concrete examples of Mermaid diagrams and tables

**Important: The template is only a reference. Customize flexibly to match actual codebase characteristics.**

- Unnecessary sections may be omitted
- Sections may be added or merged as needed
- Propose visualizations appropriate to the code's characteristics
- Adjust focus sections according to client interests
- **Do not use emojis**

---

## Outputs

```
02_asis_analysis/01_requirements/requirements.md  # Requirements document (Phase 0)
02_asis_analysis/05_hearing/hearing_result.md     # Interview results (Phase 2)
02_asis_analysis/06_planning/planning.md          # Analysis planning results (Phase 4)
```

**Content to include in planning.md:**

- **[Beginning/Most Important] Reader Goal State**
  - State and emotions after reading
  - States to avoid
  - Information selection criteria
- **[Required] Information Availability Matrix** (Phase 0 evaluation results)
  - List of available information (priority, storage location)
  - Missing information and response plan (priority, missing reason, response)
  - Analysis limitations and notes
- Analysis approach (focus, scope, Era-Context criteria)
- **Priority check items from technical research** (cited from technology_research.md)
- **Report table of contents (section structure)** ← Designed by back-calculating from goal state
- **Reader experience design** (what happens to the reader at each section)
- **Visualization plan (what goes where)**
- Client expectations and value delivery points
- **Path of referenced technical research reports**

---

## Related Skills

| Skill                 | Role                                                                               | Dependencies                               |
| --------------------- | ---------------------------------------------------------------------------------- | ------------------------------------------ |
| `asis-preparation`    | Pre-preparation (document listing, cloc execution, design doc conversion)          | **Prerequisite**: Creates document-list.md |
| `technology-research` | Technology research (language/framework-specific issues and patterns) ※ Standalone | Recommended: Run before Phase 1            |
| `integrated-analysis` | Integrated analysis (executed according to planning.md)                            | Subsequent: Run after creating planning.md |

> **Important**: Before running `analysis-planning`, always run `asis-preparation` first to create `document-list.md`.

---

## Related Sub-Agents

| Sub-Agent         | Role                                                                          | Invocation Timing                       |
| ----------------- | ----------------------------------------------------------------------------- | --------------------------------------- |
| `tech-researcher` | Web research on language/framework-specific issues and modernization patterns | Phases 1-3 (after tech stack detection) |

---

## Execution Start

1. **[Phase 0] Load document-list.md and assess document availability**
   - If it does not exist, guide to run the `asis-preparation` skill
   - Conduct priority mapping
   - When high-priority documents are missing, investigate reasons and decide response strategy
2. [Phase 1] Check existing materials in `01_asis_code/` and `02_asis_analysis/`
3. Quick scan the codebase to understand its characteristics
4. Review meeting minutes if available
5. [Phase 2] Interview the user based on investigation results
6. [Phase 3] Propose an analysis approach including **information availability matrix, report table of contents, and visualization plan**
7. [Phase 4] Create and save planning.md
