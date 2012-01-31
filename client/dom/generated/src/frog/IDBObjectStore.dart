
class IDBObjectStoreJs extends DOMTypeJs implements IDBObjectStore native "*IDBObjectStore" {

  String get keyPath() native "return this.keyPath;";

  String get name() native "return this.name;";

  IDBTransactionJs get transaction() native "return this.transaction;";

  IDBRequestJs add(Dynamic value, [IDBKeyJs key = null]) native;

  IDBRequestJs clear() native;

  IDBRequestJs count([IDBKeyRangeJs range = null]) native;

  IDBIndexJs createIndex(String name, String keyPath) native;

  IDBRequestJs delete(IDBKeyJs key) native;

  void deleteIndex(String name) native;

  IDBRequestJs getObject(IDBKeyJs key) native;

  IDBIndexJs index(String name) native;

  IDBRequestJs openCursor([IDBKeyRangeJs range = null, int direction = null]) native;

  IDBRequestJs put(Dynamic value, [IDBKeyJs key = null]) native;
}
