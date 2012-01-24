
class IDBFactoryJs extends DOMTypeJs implements IDBFactory native "*IDBFactory" {

  int cmp(IDBKeyJs first, IDBKeyJs second) native;

  IDBVersionChangeRequestJs deleteDatabase(String name) native;

  IDBRequestJs getDatabaseNames() native;

  IDBRequestJs open(String name) native;
}
