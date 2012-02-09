
class _IDBKeyRangeJs extends _DOMTypeJs implements IDBKeyRange native "*IDBKeyRange" {

  final _IDBKeyJs lower;

  final bool lowerOpen;

  final _IDBKeyJs upper;

  final bool upperOpen;

  _IDBKeyRangeJs bound(_IDBKeyJs lower, _IDBKeyJs upper, [bool lowerOpen = null, bool upperOpen = null]) native;

  _IDBKeyRangeJs lowerBound(_IDBKeyJs bound, [bool open = null]) native;

  _IDBKeyRangeJs only(_IDBKeyJs value) native;

  _IDBKeyRangeJs upperBound(_IDBKeyJs bound, [bool open = null]) native;
}
