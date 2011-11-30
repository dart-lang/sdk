
class EntryCallback native "*EntryCallback" {

  bool handleEvent(Entry entry) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
