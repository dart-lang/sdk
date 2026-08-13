# Getting Started

## Creating a Minimal Plugin

To implement a plugin, start by creating a simple package and create a class
that is a subclass of `ServerPlugin`. This class will need to implement a
constructor, three getters, and two methods. The getters provide some basic
information about your plugin: the name and version, both of which are included
in error messages if there is a problem encountered, and a list of glob patterns
for the files that the plugin cares about. The methods ...

Here's an example of what a minimal plugin might look like.

```dart
class MyPlugin extends ServerPlugin {
  MyPlugin(ResourceProvider provider) : super(provider);

  @override
  List<String> get fileGlobsToAnalyze => <String>['**/*.dart'];

  @override
  String get name => 'My fantastic plugin';

  @override
  String get version => '1.0.0';

  @override
  AnalysisDriverGeneric createAnalysisDriver(ContextRoot contextRoot) {
    // TODO: implement createAnalysisDriver
    return null;
  }

  @override
  void sendNotificationsForSubscriptions(
      Map<String, List<AnalysisService>> subscriptions) {
    // TODO: implement sendNotificationsForSubscriptions
  }
}
```
