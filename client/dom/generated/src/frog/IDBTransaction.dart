
class IDBTransactionJs extends DOMTypeJs implements IDBTransaction native "*IDBTransaction" {

  static final int READ_ONLY = 0;

  static final int READ_WRITE = 1;

  static final int VERSION_CHANGE = 2;

  IDBDatabaseJs get db() native "return this.db;";

  int get mode() native "return this.mode;";

  EventListener get onabort() native "return this.onabort;";

  void set onabort(EventListener value) native "this.onabort = value;";

  EventListener get oncomplete() native "return this.oncomplete;";

  void set oncomplete(EventListener value) native "this.oncomplete = value;";

  EventListener get onerror() native "return this.onerror;";

  void set onerror(EventListener value) native "this.onerror = value;";

  void abort() native;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(EventJs evt) native;

  IDBObjectStoreJs objectStore(String name) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;
}
