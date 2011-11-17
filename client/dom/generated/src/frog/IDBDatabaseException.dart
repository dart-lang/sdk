
class IDBDatabaseException native "IDBDatabaseException" {

  int code;

  String message;

  String name;

  String toString() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
