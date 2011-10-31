
class EntryArray native "EntryArray" {

  int length;

  Entry item(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
