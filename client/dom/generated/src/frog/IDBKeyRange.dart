
class IDBKeyRange native "*IDBKeyRange" {

  IDBKey lower;

  bool lowerOpen;

  IDBKey upper;

  bool upperOpen;

  IDBKeyRange bound(IDBKey lower, IDBKey upper, [bool lowerOpen = null, bool upperOpen = null]) native;

  IDBKeyRange lowerBound(IDBKey bound, [bool open = null]) native;

  IDBKeyRange only(IDBKey value) native;

  IDBKeyRange upperBound(IDBKey bound, [bool open = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
