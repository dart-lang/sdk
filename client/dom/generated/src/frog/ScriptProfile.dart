
class ScriptProfile native "*ScriptProfile" {

  ScriptProfileNode head;

  String title;

  int uid;

  var dartObjectLocalStorage;

  String get typeName() native;
}
