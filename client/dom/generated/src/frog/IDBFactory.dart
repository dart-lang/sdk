
class _IDBFactoryJs extends _DOMTypeJs implements IDBFactory native "*IDBFactory" {

  int cmp(_IDBKeyJs first, _IDBKeyJs second) native;

  _IDBVersionChangeRequestJs deleteDatabase(String name) native;

  _IDBRequestJs getDatabaseNames() native;

  _IDBRequestJs open(String name) native;
}
