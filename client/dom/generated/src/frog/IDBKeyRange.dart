
class IDBKeyRangeJs extends DOMTypeJs implements IDBKeyRange native "*IDBKeyRange" {

  IDBKeyJs get lower() native "return this.lower;";

  bool get lowerOpen() native "return this.lowerOpen;";

  IDBKeyJs get upper() native "return this.upper;";

  bool get upperOpen() native "return this.upperOpen;";

  IDBKeyRangeJs bound(IDBKeyJs lower, IDBKeyJs upper, [bool lowerOpen = null, bool upperOpen = null]) native;

  IDBKeyRangeJs lowerBound(IDBKeyJs bound, [bool open = null]) native;

  IDBKeyRangeJs only(IDBKeyJs value) native;

  IDBKeyRangeJs upperBound(IDBKeyJs bound, [bool open = null]) native;
}
