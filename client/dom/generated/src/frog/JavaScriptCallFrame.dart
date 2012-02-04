
class _JavaScriptCallFrameJs extends _DOMTypeJs implements JavaScriptCallFrame native "*JavaScriptCallFrame" {

  static final int CATCH_SCOPE = 4;

  static final int CLOSURE_SCOPE = 3;

  static final int GLOBAL_SCOPE = 0;

  static final int LOCAL_SCOPE = 1;

  static final int WITH_SCOPE = 2;

  final _JavaScriptCallFrameJs caller;

  final int column;

  final String functionName;

  final int line;

  final List scopeChain;

  final int sourceID;

  final Object thisObject;

  final String type;

  void evaluate(String script) native;

  int scopeType(int scopeIndex) native;
}
