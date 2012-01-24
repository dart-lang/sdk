
class IDBKeyRangeJS implements IDBKeyRange native "*IDBKeyRange" {

  IDBKeyJS get lower() native "return this.lower;";

  bool get lowerOpen() native "return this.lowerOpen;";

  IDBKeyJS get upper() native "return this.upper;";

  bool get upperOpen() native "return this.upperOpen;";

  IDBKeyRangeJS bound(IDBKeyJS lower, IDBKeyJS upper, [bool lowerOpen = null, bool upperOpen = null]) native;

  IDBKeyRangeJS lowerBound(IDBKeyJS bound, [bool open = null]) native;

  IDBKeyRangeJS only(IDBKeyJS value) native;

  IDBKeyRangeJS upperBound(IDBKeyJS bound, [bool open = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
