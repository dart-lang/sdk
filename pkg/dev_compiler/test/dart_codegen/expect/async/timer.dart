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
        .bindUnaryCallback(DDC$RT.wrap((void f(Timer __u126)) {
      void c(Timer x0) => f(DDC$RT.cast(x0, dynamic, Timer, "CastParam",
          """line 80, column 50 of dart:async/timer.dart: """, x0 is Timer,
          true));
      return f == null ? null : c;
    }, callback, __t129, __t127, "Wrap",
        """line 80, column 50 of dart:async/timer.dart: """,
        callback is __t127), runGuarded: true));
  }
  static void run(void callback()) {
    new Timer(Duration.ZERO, callback);
  }
  void cancel();
  bool get isActive;
  static Timer _createTimer(Duration duration, void callback()) {
    int milliseconds = duration.inMilliseconds;
    if (milliseconds < 0) milliseconds = 0;
    return ((__x131) => DDC$RT.cast(__x131, dynamic, Timer, "CastExact",
        """line 110, column 12 of dart:async/timer.dart: """, __x131 is Timer,
        true))(new TimerImpl(milliseconds, callback));
  }
  static Timer _createPeriodicTimer(
      Duration duration, void callback(Timer timer)) {
    int milliseconds = duration.inMilliseconds;
    if (milliseconds < 0) milliseconds = 0;
    return ((__x132) => DDC$RT.cast(__x132, dynamic, Timer, "CastExact",
        """line 116, column 12 of dart:async/timer.dart: """, __x132 is Timer,
        true))(new TimerImpl.periodic(milliseconds, callback));
  }
}
typedef dynamic __t127(dynamic __u128);
typedef void __t129(Timer __u130);
