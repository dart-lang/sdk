
class HTMLPropertiesCollectionJS extends HTMLCollectionJS implements HTMLPropertiesCollection native "*HTMLPropertiesCollection" {

  int get length() native "return this.length;";

  NodeJS item(int index) native;
}
