
class _IDBFactoryImpl implements IDBFactory native "*IDBFactory" {

  int cmp(_IDBKeyImpl first, _IDBKeyImpl second) native;

  _IDBVersionChangeRequestImpl deleteDatabase(String name) native;

  _IDBRequestImpl getDatabaseNames() native;

  _IDBRequestImpl open(String name) native;
}
