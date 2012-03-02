
class _TextMetricsImpl extends _DOMTypeBase implements TextMetrics {
  _TextMetricsImpl._wrap(ptr) : super._wrap(ptr);

  num get width() => _wrap(_ptr.width);
}
