
class _CSSTransformValueImpl extends _CSSValueListImpl implements CSSTransformValue {
  _CSSTransformValueImpl._wrap(ptr) : super._wrap(ptr);

  int get operationType() => _wrap(_ptr.operationType);
}
