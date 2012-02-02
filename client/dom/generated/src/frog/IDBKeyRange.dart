
class _IDBKeyRangeJs extends _DOMTypeJs implements IDBKeyRange native "*IDBKeyRange" {

  _IDBKeyJs get lower() native "return this.lower;";

  bool get lowerOpen() native "return this.lowerOpen;";

  _IDBKeyJs get upper() native "return this.upper;";

  bool get upperOpen() native "return this.upperOpen;";

  _IDBKeyRangeJs bound(_IDBKeyJs lower, _IDBKeyJs upper, [bool lowerOpen = null, bool upperOpen = null]) native;

  _IDBKeyRangeJs lowerBound(_IDBKeyJs bound, [bool open = null]) native;

  _IDBKeyRangeJs only(_IDBKeyJs value) native;

  _IDBKeyRangeJs upperBound(_IDBKeyJs bound, [bool open = null]) native;
}
