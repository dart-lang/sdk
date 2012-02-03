
class _HTMLAllCollectionJs extends _DOMTypeJs implements HTMLAllCollection native "*HTMLAllCollection" {

  int get length() native "return this.length;";

  _NodeJs item(int index) native;

  _NodeJs namedItem(String name) native;

  _NodeListJs tags(String name) native;
}
