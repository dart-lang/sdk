
class _ValidityStateImpl extends _DOMTypeBase implements ValidityState {
  _ValidityStateImpl._wrap(ptr) : super._wrap(ptr);

  bool get customError() => _wrap(_ptr.customError);

  bool get patternMismatch() => _wrap(_ptr.patternMismatch);

  bool get rangeOverflow() => _wrap(_ptr.rangeOverflow);

  bool get rangeUnderflow() => _wrap(_ptr.rangeUnderflow);

  bool get stepMismatch() => _wrap(_ptr.stepMismatch);

  bool get tooLong() => _wrap(_ptr.tooLong);

  bool get typeMismatch() => _wrap(_ptr.typeMismatch);

  bool get valid() => _wrap(_ptr.valid);

  bool get valueMissing() => _wrap(_ptr.valueMissing);
}
