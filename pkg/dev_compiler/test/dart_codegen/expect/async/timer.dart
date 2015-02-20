part of dart.async;

abstract class Timer {
  factory Timer(Duration duration, void callback()) {
    if (Zone.current == Zone.ROOT) {
      return Zone.current.createTimer(duration, callback);
    }
    return Zone.current.createTimer(
        duration, Zone.current.bindCallback(callback, runGuarded: true));
  }
  factory Timer.periodic(Duration duration, void callback(Timer timer)) {
    if (Zone.current == Zone.ROOT) {
      return Zone.current.createPeriodicTimer(duration, callback);
    }
    return Zone.current.createPeriodicTimer(duration, Zone.current
        .bindUnaryCallback(DDC$RT.wrap((void f(Timer __u132)) {
      void c(Timer x0) => f(DDC$RT.cast(x0, dynamic, Timer, "CastParam",
          """line 80, column 50 of dart:async/timer.dart: """, x0 is Timer,
          true));
      return f == null ? null : c;
    }, callback, __t135, __t133, "Wrap",
        """line 80, column 50 of dart:async/timer.dart: """,
        callback is __t133), runGuarded: true));
  }
  static void run(void callback()) {
    new Timer(Duration.ZERO, callback);
  }
  void cancel();
  bool get isActive;
  @patch static Timer _createTimer(Duration duration, void callback()) {
    int milliseconds = duration.inMilliseconds;
    if (milliseconds < 0) milliseconds = 0;
    return ((__x137) => DDC$RT.cast(__x137, dynamic, Timer, "CastExact",
        """line 111, column 12 of dart:async/timer.dart: """, __x137 is Timer,
        true))(new TimerImpl(milliseconds, callback));
  }
  @patch static Timer _createPeriodicTimer(
      Duration duration, void callback(Timer timer)) {
    int milliseconds = duration.inMilliseconds;
    if (milliseconds < 0) milliseconds = 0;
    return ((__x138) => DDC$RT.cast(__x138, dynamic, Timer, "CastExact",
        """line 118, column 12 of dart:async/timer.dart: """, __x138 is Timer,
        true))(new TimerImpl.periodic(milliseconds, callback));
  }
}
typedef dynamic __t133(dynamic __u134);
typedef void __t135(Timer __u136);
