
class WorkerNavigatorJS implements WorkerNavigator native "*WorkerNavigator" {

  String get appName() native "return this.appName;";

  String get appVersion() native "return this.appVersion;";

  bool get onLine() native "return this.onLine;";

  String get platform() native "return this.platform;";

  String get userAgent() native "return this.userAgent;";

  var dartObjectLocalStorage;

  String get typeName() native;
}
