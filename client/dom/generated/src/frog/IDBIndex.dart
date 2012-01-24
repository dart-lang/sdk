
class IDBIndexJS implements IDBIndex native "*IDBIndex" {

  String get keyPath() native "return this.keyPath;";

  bool get multiEntry() native "return this.multiEntry;";

  String get name() native "return this.name;";

  IDBObjectStoreJS get objectStore() native "return this.objectStore;";

  bool get unique() native "return this.unique;";

  IDBRequestJS count([IDBKeyRangeJS range = null]) native;

  IDBRequestJS getObject(IDBKeyJS key) native;

  IDBRequestJS getKey(IDBKeyJS key) native;

  IDBRequestJS openCursor([IDBKeyRangeJS range = null, int direction = null]) native;

  IDBRequestJS openKeyCursor([IDBKeyRangeJS range = null, int direction = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
