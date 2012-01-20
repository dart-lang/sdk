
class HTMLPropertiesCollection extends HTMLCollection native "*HTMLPropertiesCollection" {

  int get length() native "return this.length;";

  Node item(int index) native;
}
