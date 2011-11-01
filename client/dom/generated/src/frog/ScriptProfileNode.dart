
class ScriptProfileNode native "ScriptProfileNode" {

  int callUID;

  String functionName;

  int lineNumber;

  int numberOfCalls;

  num selfTime;

  num totalTime;

  String url;

  bool visible;

  var dartObjectLocalStorage;

  String get typeName() native;
}
