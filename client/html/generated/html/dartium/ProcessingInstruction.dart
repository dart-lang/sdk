
class _ProcessingInstructionImpl extends _NodeImpl implements ProcessingInstruction {
  _ProcessingInstructionImpl._wrap(ptr) : super._wrap(ptr);

  String get data() => _wrap(_ptr.data);

  void set data(String value) { _ptr.data = _unwrap(value); }

  StyleSheet get sheet() => _wrap(_ptr.sheet);

  String get target() => _wrap(_ptr.target);
}
