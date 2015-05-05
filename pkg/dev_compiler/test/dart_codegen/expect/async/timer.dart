part of dart.async;
 abstract class Timer {factory Timer(Duration duration, void callback()) {
  if (Zone.current == Zone.ROOT) {
    return Zone.current.createTimer(duration, callback);
    }
   return Zone.current.createTimer(duration, Zone.current.bindCallback(callback, runGuarded: true));
  }
 factory Timer.periodic(Duration duration, void callback(Timer timer)) {
  if (Zone.current == Zone.ROOT) {
    return Zone.current.createPeriodicTimer(duration, callback);
    }
   return Zone.current.createPeriodicTimer(duration, ((__x83) => DEVC$RT.cast(__x83, ZoneUnaryCallback, __CastType81, "CompositeCast", """line 80, column 19 of dart:async/timer.dart: """, __x83 is __CastType81, false))(Zone.current.bindUnaryCallback(callback, runGuarded: true)));
  }
 static void run(void callback()) {
  new Timer(Duration.ZERO, callback);
  }
 void cancel();
 bool get isActive;
 external static Timer _createTimer(Duration duration, void callback());
 external static Timer _createPeriodicTimer(Duration duration, void callback(Timer timer));
}
 typedef void __CastType81(Timer __u82);
