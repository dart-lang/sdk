part of dart.core;

class Stopwatch {
  int get frequency => _frequency;
  int _start;
  int _stop;
  Stopwatch() {
    _initTicker();
  }
  void start() {
    if (isRunning) return;
    if (_start == null) {
      _start = _now();
    } else {
      _start = _now() - (_stop - _start);
      _stop = null;
    }
  }
  void stop() {
    if (!isRunning) return;
    _stop = _now();
  }
  void reset() {
    if (_start == null) return;
    _start = _now();
    if (_stop != null) {
      _stop = _start;
    }
  }
  int get elapsedTicks {
    if (_start == null) {
      return 0;
    }
    return (_stop == null) ? (_now() - _start) : (_stop - _start);
  }
  Duration get elapsed {
    return new Duration(microseconds: elapsedMicroseconds);
  }
  int get elapsedMicroseconds {
    return (elapsedTicks * 1000000) ~/ frequency;
  }
  int get elapsedMilliseconds {
    return (elapsedTicks * 1000) ~/ frequency;
  }
  bool get isRunning => _start != null && _stop == null;
  static int _frequency;
  external static void _initTicker();
  external static int _now();
}
