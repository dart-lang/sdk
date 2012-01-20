
class ElementTraversal native "*ElementTraversal" {

  int get childElementCount() native "return this.childElementCount;";

  Element get firstElementChild() native "return this.firstElementChild;";

  Element get lastElementChild() native "return this.lastElementChild;";

  Element get nextElementSibling() native "return this.nextElementSibling;";

  Element get previousElementSibling() native "return this.previousElementSibling;";

  var dartObjectLocalStorage;

  String get typeName() native;
}
