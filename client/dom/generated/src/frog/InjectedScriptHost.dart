
class InjectedScriptHost native "InjectedScriptHost" {

  void clearConsoleMessages() native;

  void copyText(String text) native;

  int databaseId(Object database) native;

  Object evaluate(String text) native;

  void inspect(Object objectId, Object hints) native;

  Object inspectedNode(int num) native;

  Object internalConstructorName(Object object) native;

  bool isHTMLAllCollection(Object object) native;

  int storageId(Object storage) native;

  String type(Object object) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
