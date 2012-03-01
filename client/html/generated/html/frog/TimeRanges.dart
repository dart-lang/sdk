
class _TimeRangesImpl implements TimeRanges native "*TimeRanges" {

  final int length;

  num end(int index) native;

  num start(int index) native;
}
