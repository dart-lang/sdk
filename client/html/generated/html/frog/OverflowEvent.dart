
class _OverflowEventImpl extends _EventImpl implements OverflowEvent native "*OverflowEvent" {

  static final int BOTH = 2;

  static final int HORIZONTAL = 0;

  static final int VERTICAL = 1;

  final bool horizontalOverflow;

  final int orient;

  final bool verticalOverflow;
}
