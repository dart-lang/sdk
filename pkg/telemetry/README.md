# telemetry

A library to facilitate reporting crash reports.

## Crash reporting

To use the crash reporting functionality, import `crash_reporting.dart`, and
create a new `CrashReportSender` instance:

```dart
import 'package:telemetry/crash_reporting.dart';

void main() {
  Analytics analytics = ...;
  CrashReportSender sender = new CrashReportSender.prod(...);

  try {
    ...
  } catch (e, st) {
    sender.sendReport(e, st);
  }
}
```
