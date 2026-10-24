# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-10-24

### Added
- Offline-first SQLite database schema for invoices and inventory with auto-incrementing sequential invoice numbers.
- Point-of-Sale invoice generator supporting battery item names, HSN/SAC codes, and line-item serial numbers.
- High-precision GST calculation engine back-calculating taxable values from inclusive retail rates with 0 floating-point drift.
- Standard A4 Tax Invoice PDF generation, native printing, and sharing via Android FileProvider.
- Automated backup and restore functionality for SQLite databases (`.db` export/import).
- Comprehensive automated test suite for tax calculation logic, number-to-words currency converter, and data models.
- GitHub Actions CI workflow for static analysis and automated testing.

### Security
- Sanitized real-world banking and contact credentials in constants with clean open-source demonstration templates.
- Added comprehensive `.gitignore` rules preventing exposure of build artifacts, local databases, and IDE configuration.
