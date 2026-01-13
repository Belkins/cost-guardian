# Changelog

All notable changes to Cost Guardian will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- Team cost dashboards
- Webhook notifications (Slack, Discord)
- Cost forecasting with ML
- Automatic model routing
- VS Code extension

## [1.0.0] - 2025-01-XX

### Added
- Initial release of Cost Guardian
- Real-time cost tracking via hooks
- `/budget` command for setting limits
  - Session, daily, monthly scopes
  - Warn, confirm, block enforcement modes
  - Configurable alert thresholds
- `/cost` command for viewing current costs
  - Token breakdown (input/output)
  - Per-operation tracking
  - Tool cost attribution
- `/cost-report` command for analytics
  - Session reports
  - Period reports (day/week/month)
  - Efficiency metrics
- `/cost-optimize` command for suggestions
  - Redundant operation detection
  - Model optimization recommendations
  - Caching opportunity identification
- `/cost-share` command for export
  - Shareable HTML reports
  - Embeddable efficiency badges
  - JSON data export
- Hook implementations
  - SessionStart: Initialize tracking
  - PreToolUse: Cost estimation & warnings
  - PostToolUse: Actual usage tracking
  - SessionEnd: Summary generation
- Efficiency scoring system (A+ to F)
- Local data storage (~/.claude/cost-guardian/)
- Support for all Claude models (Opus, Sonnet, Haiku)
- Tool overhead calculations

### Security
- All data stored locally
- No external API calls
- Opt-in sharing only

---

## Version History

| Version | Date | Highlights |
|---------|------|------------|
| 1.0.0 | 2025-01-XX | Initial release |

---

## Upgrade Guide

### To 1.0.0

First release - no upgrade needed. Install with:

```bash
/plugin install cost-guardian
```
