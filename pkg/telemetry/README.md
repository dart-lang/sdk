# telemetry

A library to facilitate reporting analytics and crash reports.

## Analytics

This library is designed to allow all Dart SDK tools to easily send analytics
information and crash reports. The tools share a common setting to configure
sending analytics data. To use this library for a specific tool:

```
import 'package:telemtry/telemtry.dart';
import 'package:usage/usage.dart';

main() async {
  final String myAppTrackingID = ...;
  final String myAppName = ...;

  Analytics analytics = createAnalyticsInstance(myAppTrackingID, myAppName);
  ...
  analytics.sendScreenView('home');
  ...
  await analytics.waitForLastPing();
}
```

The analytics object reads from the correct user configuration file
automatically without any additional configuration. Analytics will not be sent
if the user has opted-out.

## Crash reporting

To use the crash reporting functionality, import `crash_reporting.dart`, and
create a new `CrashReportSender` instance:

```dart
import 'package:telemtry/crash_reporting.dart';

main() {
  Analytics analytics = ...;
  CrashReportSender sender = new CrashReportSender(analytics);
  try {
    ...
  } catch (e, st) {
    sender.sendReport(e, st);
  }
}
```

Crash reports will only be sent if the cooresponding [Analytics] object is
configured to send analytics.
