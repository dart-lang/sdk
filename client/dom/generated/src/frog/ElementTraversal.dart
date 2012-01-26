
class ElementTraversalJs extends DOMTypeJs implements ElementTraversal native "*ElementTraversal" {

  int get childElementCount() native "return this.childElementCount;";

  ElementJs get firstElementChild() native "return this.firstElementChild;";

  ElementJs get lastElementChild() native "return this.lastElementChild;";

  ElementJs get nextElementSibling() native "return this.nextElementSibling;";

  ElementJs get previousElementSibling() native "return this.previousElementSibling;";
}
