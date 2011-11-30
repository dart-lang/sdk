
class EntryArraySync native "*EntryArraySync" {

  int length;

  EntrySync item(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
