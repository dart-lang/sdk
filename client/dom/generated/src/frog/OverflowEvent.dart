
class OverflowEvent extends Event native "OverflowEvent" {

  bool horizontalOverflow;

  int orient;

  bool verticalOverflow;

  void initOverflowEvent(int orient, bool horizontalOverflow, bool verticalOverflow) native;
}
