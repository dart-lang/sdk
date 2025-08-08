# 2.1.0
- Deprecate `DdsExtension.getAvailableCachedCpuSamples` and
  `DdsExtension.getCachedCpuSamples` methods.

# 2.0.2
- Require dart sdk v. 3.5.0 or higher.
- Add `DdsExtension.onTimerEventWithHistory`.
- Fix a bug that could make any `DdsExtension.on*EventWithHistory` stream
  contain an incorrect set of events.
- Remove dependency on `package:async`.

# 2.0.1
- Update `vm_service` to `>=14.0.0 <16.0.0`.

# 2.0.0
- Updated to DDS protocol 2.0.
- Added:
  - `readyToResume`
  - `requireUserPermissionToResume`

# 1.7.0
- Added:
  - `ClientName`
  - `DdsExtension.getClientName`
  - `DdsExtension.getLogHistorySize`
  - `DdsExtension.setClientName`
  - `DdsExtension.setLogHistorySize`
  - `DdsExtension.requirePermissionToResume`
  - `Size`

# 1.6.3
- Updated `vm_service` version to `^14.0.0`.

# 1.6.2
- Updated `vm_service` version to `^13.0.0`.

# 1.6.1
- Updated `vm_service` version to `^12.0.0`.

## 1.6.0
- Made DAP extensions methods accessible in lib.

## 1.5.0
- Added `DdsExtension.postEvent`.

## 1.4.0

- Added `DdsExtension.getPerfettoVMTimelineWithCpuSamples`.

## 1.3.3

- Updated `vm_service` version to ^11.0.0.

## 1.3.2

- Updated `vm_service` version to ^10.0.0.

## 1.3.1

- Updated `vm_service` version to 9.0.0.

## 1.3.0

- Moved `package:dds/vm_service_extensions.dart` into a standalone package.
