
class IDBRequestJs extends DOMTypeJs implements IDBRequest native "*IDBRequest" {

  static final int DONE = 2;

  static final int LOADING = 1;

  int get errorCode() native "return this.errorCode;";

  EventListener get onerror() native "return this.onerror;";

  void set onerror(EventListener value) native "this.onerror = value;";

  EventListener get onsuccess() native "return this.onsuccess;";

  void set onsuccess(EventListener value) native "this.onsuccess = value;";

  int get readyState() native "return this.readyState;";

  IDBAnyJs get result() native "return this.result;";

  IDBAnyJs get source() native "return this.source;";

  IDBTransactionJs get transaction() native "return this.transaction;";

  String get webkitErrorMessage() native "return this.webkitErrorMessage;";

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(EventJs evt) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;
}
