
class ScriptProfileNode native "*ScriptProfileNode" {

  int get callUID() native "return this.callUID;";

  List get children() native "return this.children;";

  String get functionName() native "return this.functionName;";

  int get lineNumber() native "return this.lineNumber;";

  int get numberOfCalls() native "return this.numberOfCalls;";

  num get selfTime() native "return this.selfTime;";

  num get totalTime() native "return this.totalTime;";

  String get url() native "return this.url;";

  bool get visible() native "return this.visible;";

  var dartObjectLocalStorage;

  String get typeName() native;
}
