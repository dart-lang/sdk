
class ElementTraversalJS implements ElementTraversal native "*ElementTraversal" {

  int get childElementCount() native "return this.childElementCount;";

  ElementJS get firstElementChild() native "return this.firstElementChild;";

  ElementJS get lastElementChild() native "return this.lastElementChild;";

  ElementJS get nextElementSibling() native "return this.nextElementSibling;";

  ElementJS get previousElementSibling() native "return this.previousElementSibling;";

  var dartObjectLocalStorage;

  String get typeName() native;
}
