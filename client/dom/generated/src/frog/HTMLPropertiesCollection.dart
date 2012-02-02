
class _HTMLPropertiesCollectionJs extends _HTMLCollectionJs implements HTMLPropertiesCollection native "*HTMLPropertiesCollection" {

  int get length() native "return this.length;";

  _NodeJs item(int index) native;
}
