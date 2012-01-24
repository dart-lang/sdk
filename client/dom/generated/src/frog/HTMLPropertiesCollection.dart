
class HTMLPropertiesCollectionJs extends HTMLCollectionJs implements HTMLPropertiesCollection native "*HTMLPropertiesCollection" {

  int get length() native "return this.length;";

  NodeJs item(int index) native;
}
