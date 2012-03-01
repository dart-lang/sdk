
class _ElementTraversalImpl extends _DOMTypeBase implements ElementTraversal {
  _ElementTraversalImpl._wrap(ptr) : super._wrap(ptr);

  int get childElementCount() => _wrap(_ptr.childElementCount);

  Element get firstElementChild() => _wrap(_ptr.firstElementChild);

  Element get lastElementChild() => _wrap(_ptr.lastElementChild);

  Element get nextElementSibling() => _wrap(_ptr.nextElementSibling);

  Element get previousElementSibling() => _wrap(_ptr.previousElementSibling);
}
