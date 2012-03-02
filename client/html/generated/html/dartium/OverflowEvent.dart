
class _OverflowEventImpl extends _EventImpl implements OverflowEvent {
  _OverflowEventImpl._wrap(ptr) : super._wrap(ptr);

  bool get horizontalOverflow() => _wrap(_ptr.horizontalOverflow);

  int get orient() => _wrap(_ptr.orient);

  bool get verticalOverflow() => _wrap(_ptr.verticalOverflow);
}
