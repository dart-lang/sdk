
class JavaScriptCallFrame native "JavaScriptCallFrame" {

  JavaScriptCallFrame caller;

  int column;

  String functionName;

  int line;

  int sourceID;

  String type;

  void evaluate(String script) native;

  int scopeType(int scopeIndex) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
