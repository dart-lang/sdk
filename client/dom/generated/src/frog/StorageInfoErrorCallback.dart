
class StorageInfoErrorCallback native "StorageInfoErrorCallback" {

  bool handleEvent(DOMException error) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
