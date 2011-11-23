
class EntriesCallback native "*EntriesCallback" {

  bool handleEvent(EntryArray entries) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
