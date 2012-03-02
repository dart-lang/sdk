
class _IDBKeyRangeImpl implements IDBKeyRange native "*IDBKeyRange" {

  final _IDBKeyImpl lower;

  final bool lowerOpen;

  final _IDBKeyImpl upper;

  final bool upperOpen;

  _IDBKeyRangeImpl bound(_IDBKeyImpl lower, _IDBKeyImpl upper, [bool lowerOpen = null, bool upperOpen = null]) native;

  _IDBKeyRangeImpl lowerBound(_IDBKeyImpl bound, [bool open = null]) native;

  _IDBKeyRangeImpl only(_IDBKeyImpl value) native;

  _IDBKeyRangeImpl upperBound(_IDBKeyImpl bound, [bool open = null]) native;
}
