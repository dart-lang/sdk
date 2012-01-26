
class EntryArrayJs extends DOMTypeJs implements EntryArray native "*EntryArray" {

  int get length() native "return this.length;";

  EntryJs item(int index) native;
}
