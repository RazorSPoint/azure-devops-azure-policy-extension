# <a id="Change-Log"> </a> Change Log

## 0.4.0

### Minor

- Changed the azure connection to only use scope levels of "ManagementGroup".
**Note** This changes how the connection you created changes it's behavior. Before this connection of the scope level "Subscriptions" where accepted. Now only connection for "ManagementGroup" scope levels are used. This will cause that you previous connection will not be shown anymore. Even though, this change can break your pipeline only a minor version is changed. This is due to it's previous status.

## 0.3.4

### Patch

- Fixed a problem that didn't allow to deploy policy definitions with a management group scope
- fixed ps modules path used in the extension

## 0.3.0

### Minor Changes

- Release of first preview of Azure Policy tasks



