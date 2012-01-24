
class JavaScriptCallFrameJS implements JavaScriptCallFrame native "*JavaScriptCallFrame" {

  static final int CATCH_SCOPE = 4;

  static final int CLOSURE_SCOPE = 3;

  static final int GLOBAL_SCOPE = 0;

  static final int LOCAL_SCOPE = 1;

  static final int WITH_SCOPE = 2;

  JavaScriptCallFrameJS get caller() native "return this.caller;";

  int get column() native "return this.column;";

  String get functionName() native "return this.functionName;";

  int get line() native "return this.line;";

  List get scopeChain() native "return this.scopeChain;";

  int get sourceID() native "return this.sourceID;";

  String get type() native "return this.type;";

  void evaluate(String script) native;

  int scopeType(int scopeIndex) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
