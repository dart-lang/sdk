
class OverflowEvent extends Event native "*OverflowEvent" {

  static final int BOTH = 2;

  static final int HORIZONTAL = 0;

  static final int VERTICAL = 1;

  bool horizontalOverflow;

  int orient;

  bool verticalOverflow;

  void initOverflowEvent(int orient, bool horizontalOverflow, bool verticalOverflow) native;
}
