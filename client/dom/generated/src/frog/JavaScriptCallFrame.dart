
class JavaScriptCallFrame native "*JavaScriptCallFrame" {

  static final int CATCH_SCOPE = 4;

  static final int CLOSURE_SCOPE = 3;

  static final int GLOBAL_SCOPE = 0;

  static final int LOCAL_SCOPE = 1;

  static final int WITH_SCOPE = 2;

  JavaScriptCallFrame caller;

  int column;

  String functionName;

  int line;

  List scopeChain;

  int sourceID;

  String type;

  void evaluate(String script) native;

  int scopeType(int scopeIndex) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
