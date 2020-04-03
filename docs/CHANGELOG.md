---
title: Change Log
has_children: false
nav_order: 3
---

# Change Log

## 0.4.0

### Minor

- Changed the Azure connection to only use scope levels of "ManagementGroup".

**Note** This changes how the connection you created changes its behaviour. Before this connection of the scope level "Subscriptions" where accepted. Now only connection for "ManagementGroup" scope levels are used. This will cause your previous connection not being shown anymore. Even though, this change can break your pipeline only a minor version is changed. This is due to its previous status.

## 0.3.4

### Patch

- Fixed a problem that didn't allow to deploy policy definitions with a management group scope
- fixed ps modules path used in the extension

## 0.3.0

### Minor Changes

- Release of first preview of Azure Policy tasks



