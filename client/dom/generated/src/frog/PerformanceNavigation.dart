
class PerformanceNavigation native "*PerformanceNavigation" {

  static final int TYPE_BACK_FORWARD = 2;

  static final int TYPE_NAVIGATE = 0;

  static final int TYPE_RELOAD = 1;

  static final int TYPE_RESERVED = 255;

  int redirectCount;

  int type;

  var dartObjectLocalStorage;

  String get typeName() native;
}
