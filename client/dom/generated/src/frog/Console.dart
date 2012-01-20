
class Console native "=(typeof console == 'undefined' ? {} : console)" {

  MemoryInfo memory;

  List profiles;

  void assertCondition(bool condition) native;

  void count() native;

  void debug(Object arg) native;

  void dir() native;

  void dirxml() native;

  void error(Object arg) native;

  void group() native;

  void groupCollapsed() native;

  void groupEnd() native;

  void info(Object arg) native;

  void log(Object arg) native;

  void markTimeline() native;

  void profile(String title) native;

  void profileEnd(String title) native;

  void time(String title) native;

  void timeEnd(String title) native;

  void timeStamp() native;

  void trace(Object arg) native;

  void warn(Object arg) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
