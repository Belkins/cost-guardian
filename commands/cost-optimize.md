---
description: Get AI-powered suggestions to reduce Claude Code costs
argument-hint: [--aggressive|--balanced|--minimal]
allowed-tools: Read, Bash(cat:*), Bash(grep:*), Bash(wc:*)
---

# Cost Optimization Command

Analyze your usage patterns and get personalized cost-saving recommendations.

## Current Session Data

!`cat ~/.claude/cost-guardian/sessions/current.json 2>/dev/null || echo '{}'`

## Historical Data

!`cat ~/.claude/cost-guardian/history.json 2>/dev/null || echo '{}'`

## Arguments Received: $ARGUMENTS

## Instructions

Analyze the session data and provide optimization suggestions:

### Analysis Areas

1. **Redundant Operations**
   - Look for the same file being read multiple times
   - Identify repeated similar operations
   - Calculate potential savings

2. **Large Context Operations**
   - Find operations with high token counts
   - Suggest more specific queries
   - Recommend file path specificity

3. **Model Optimization**
   - Analyze operation complexity
   - Suggest appropriate models:
     - Haiku: Simple formatting, boilerplate, quick lookups
     - Sonnet: Standard coding, debugging, refactoring
     - Opus: Complex architecture, novel solutions

4. **Caching Opportunities**
   - Identify repeated patterns
   - Suggest prompt caching strategies
   - Calculate potential cache savings (90% on reads)

5. **Tool Efficiency**
   - Analyze tool overhead impact
   - Suggest batch operations
   - Recommend glob patterns over multiple reads

### Output Format

```
Cost Guardian: Optimization Analysis
====================================

IMMEDIATE SAVINGS OPPORTUNITIES

1. Redundant Reads Detected
   Potential savings: $X.XX
   - [file1] read X times
   - [file2] read X times
   Action: Read once, reference in prompts

2. Large Context Warning
   Potential savings: XX% on input costs
   - Average context size: XX,XXX tokens
   - XX operations over 10,000 tokens
   Action: Use specific file paths, summarize large contexts

3. Model Optimization
   Potential savings: $X.XX
   - XX operations could use Haiku instead of Sonnet
   - Types: formatting, simple lookups, boilerplate
   Action: Consider model selection for routine tasks

4. Caching Opportunity
   Potential savings: $X.XX/session
   - System prompts repeated XX times
   - Large files re-read frequently
   Action: Leverage prompt caching (90% discount on reads)

EFFICIENCY SCORE: X/100

Current efficiency: [Good/Needs improvement/Poor]

PROJECTED SAVINGS
-----------------
If all recommendations applied:
  Per session: $X.XX (XX% reduction)
  Per day:     $X.XX
  Per month:   $XX.XX
```

### Optimization Levels

- **--minimal**: Only easy wins, no workflow changes
- **--balanced** (default): Mix of quick fixes and moderate changes
- **--aggressive**: Maximum savings, may require workflow adjustments

## Calculations

For redundant operations:
- Count operations by file path
- Multiply duplicates by average read cost

For model optimization:
- Categorize operations by complexity
- Calculate cost difference (Opus vs Sonnet vs Haiku)

For caching:
- Identify repeated large inputs
- Calculate 90% savings on cache hits
