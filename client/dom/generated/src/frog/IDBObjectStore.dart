
class IDBObjectStoreJS implements IDBObjectStore native "*IDBObjectStore" {

  String get keyPath() native "return this.keyPath;";

  String get name() native "return this.name;";

  IDBTransactionJS get transaction() native "return this.transaction;";

  IDBRequestJS add(String value, [IDBKeyJS key = null]) native;

  IDBRequestJS clear() native;

  IDBRequestJS count([IDBKeyRangeJS range = null]) native;

  IDBIndexJS createIndex(String name, String keyPath) native;

  IDBRequestJS delete(IDBKeyJS key) native;

  void deleteIndex(String name) native;

  IDBRequestJS getObject(IDBKeyJS key) native;

  IDBIndexJS index(String name) native;

  IDBRequestJS openCursor([IDBKeyRangeJS range = null, int direction = null]) native;

  IDBRequestJS put(String value, [IDBKeyJS key = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
