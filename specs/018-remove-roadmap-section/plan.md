# Implementation Plan: Remove README Roadmap Section

**Branch**: `018-remove-roadmap-section` | **Date**: 2026-09-12 | **Spec**: [spec.md](./spec.md)

## Summary

Delete README's "Roadmap" heading and table; reword the two prose
sections that referenced it so nothing dangles.

## Technical Context

**Language/Version**: Markdown (README.md only).

**Testing**: `grep -i roadmap README.md` after the edit.

## Constitution Check

- **Principle V**: Single, small, self-contained change.

No violations.

## Project Structure

```text
README.md   # Roadmap section removed; two cross-references reworded
```
