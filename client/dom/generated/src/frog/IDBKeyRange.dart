
class IDBKeyRange native "*IDBKeyRange" {

  IDBKey get lower() native "return this.lower;";

  bool get lowerOpen() native "return this.lowerOpen;";

  IDBKey get upper() native "return this.upper;";

  bool get upperOpen() native "return this.upperOpen;";

  IDBKeyRange bound(IDBKey lower, IDBKey upper, [bool lowerOpen = null, bool upperOpen = null]) native;

  IDBKeyRange lowerBound(IDBKey bound, [bool open = null]) native;

  IDBKeyRange only(IDBKey value) native;

  IDBKeyRange upperBound(IDBKey bound, [bool open = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
