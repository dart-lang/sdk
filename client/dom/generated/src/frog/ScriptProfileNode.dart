
class ScriptProfileNode native "ScriptProfileNode" {

  int callUID;

  List children;

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
