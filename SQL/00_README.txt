Healthcare Claims Analytics - SQL Project

Synthetic healthcare claims portfolio project. No PHI.

Run order:
01 Create database/schemas
02 Create source tables (skip if dbo tables already exist)
03 Validate source
04-13 Individual DQ rules DQ01-DQ10
14 Create consolidated DQ views
15 Create reporting view
16 Final validation checks

Current architecture:
dbo.Claims / Members / Providers / Payers = imported source
dq.* = data-quality layer
reporting.* = analytics-ready layer
