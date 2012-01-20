
class OverflowEvent extends Event native "*OverflowEvent" {

  static final int BOTH = 2;

  static final int HORIZONTAL = 0;

  static final int VERTICAL = 1;

  bool get horizontalOverflow() native "return this.horizontalOverflow;";

  int get orient() native "return this.orient;";

  bool get verticalOverflow() native "return this.verticalOverflow;";
}
