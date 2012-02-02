
class _EntryArrayJs extends _DOMTypeJs implements EntryArray native "*EntryArray" {

  int get length() native "return this.length;";

  _EntryJs item(int index) native;
}
