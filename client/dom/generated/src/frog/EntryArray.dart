
class EntryArray native "*EntryArray" {

  int get length() native "return this.length;";

  Entry item(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
