
class IDBFactory native "IDBFactory" {

  IDBRequest getDatabaseNames() native;

  IDBRequest open(String name) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
