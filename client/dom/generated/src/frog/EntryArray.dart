
class EntryArrayJS implements EntryArray native "*EntryArray" {

  int get length() native "return this.length;";

  EntryJS item(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
