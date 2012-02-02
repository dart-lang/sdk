
class _ElementTraversalJs extends _DOMTypeJs implements ElementTraversal native "*ElementTraversal" {

  int get childElementCount() native "return this.childElementCount;";

  _ElementJs get firstElementChild() native "return this.firstElementChild;";

  _ElementJs get lastElementChild() native "return this.lastElementChild;";

  _ElementJs get nextElementSibling() native "return this.nextElementSibling;";

  _ElementJs get previousElementSibling() native "return this.previousElementSibling;";
}
