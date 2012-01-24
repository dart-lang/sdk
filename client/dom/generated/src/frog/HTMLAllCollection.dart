
class HTMLAllCollectionJs extends DOMTypeJs implements HTMLAllCollection native "*HTMLAllCollection" {

  int get length() native "return this.length;";

  NodeJs item(int index) native;

  NodeJs namedItem(String name) native;

  NodeListJs tags(String name) native;
}
