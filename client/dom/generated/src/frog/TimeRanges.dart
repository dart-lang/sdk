
class TimeRanges native "TimeRanges" {

  int length;

  num end(int index) native;

  num start(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
