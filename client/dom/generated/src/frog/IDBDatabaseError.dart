
class IDBDatabaseError native "*IDBDatabaseError" {

  int get code() native "return this.code;";

  void set code(int value) native "this.code = value;";

  String get message() native "return this.message;";

  void set message(String value) native "this.message = value;";

  var dartObjectLocalStorage;

  String get typeName() native;
}
