
class IDBFactoryJS implements IDBFactory native "*IDBFactory" {

  int cmp(IDBKeyJS first, IDBKeyJS second) native;

  IDBVersionChangeRequestJS deleteDatabase(String name) native;

  IDBRequestJS getDatabaseNames() native;

  IDBRequestJS open(String name) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
