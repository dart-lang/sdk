
class EntryArraySyncJS implements EntryArraySync native "*EntryArraySync" {

  int get length() native "return this.length;";

  EntrySyncJS item(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
