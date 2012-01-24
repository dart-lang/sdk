
class HTMLOptionsCollectionJS extends HTMLCollectionJS implements HTMLOptionsCollection native "*HTMLOptionsCollection" {

  int get length() native "return this.length;";

  void set length(int value) native "this.length = value;";

  int get selectedIndex() native "return this.selectedIndex;";

  void set selectedIndex(int value) native "this.selectedIndex = value;";

  void remove(int index) native;
}
