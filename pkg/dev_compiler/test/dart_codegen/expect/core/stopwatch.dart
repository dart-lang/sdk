part of dart.core;

class Stopwatch {
  int get frequency => _frequency;
  num _start;
  num _stop;
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
    return ((__x34) => DDC$RT.cast(__x34, num, int, "CastGeneral",
        """line 102, column 12 of dart:core/stopwatch.dart: """, __x34 is int,
        true))((_stop == null) ? (_now() - _start) : (_stop - _start));
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
  @patch static void _initTicker() {
    Primitives.initTicker();
    _frequency = DDC$RT.cast(Primitives.timerFrequency, dynamic, int,
        "CastGeneral", """line 140, column 18 of dart:core/stopwatch.dart: """,
        Primitives.timerFrequency is int, true);
  }
  @patch static int _now() => ((__x35) => DDC$RT.cast(__x35, dynamic, int,
      "CastGeneral", """line 143, column 24 of dart:core/stopwatch.dart: """,
      __x35 is int, true))(Primitives.timerTicks());
}
