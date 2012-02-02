
class _TimeRangesJs extends _DOMTypeJs implements TimeRanges native "*TimeRanges" {

  int get length() native "return this.length;";

  num end(int index) native;

  num start(int index) native;
}
