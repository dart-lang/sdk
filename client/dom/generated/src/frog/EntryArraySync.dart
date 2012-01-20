
class EntryArraySync native "*EntryArraySync" {

  int get length() native "return this.length;";

  EntrySync item(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
