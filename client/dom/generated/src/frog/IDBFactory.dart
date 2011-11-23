
class IDBFactory native "*IDBFactory" {

  int cmp(IDBKey first, IDBKey second) native;

  IDBVersionChangeRequest deleteDatabase(String name) native;

  IDBRequest getDatabaseNames() native;

  IDBRequest open(String name) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
