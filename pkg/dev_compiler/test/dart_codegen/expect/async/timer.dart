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
   return Zone.current.createPeriodicTimer(duration, Zone.current.bindUnaryCallback(DDC$RT.wrap((void f(Timer __u176)) {
    void c(Timer x0) => f(DDC$RT.cast(x0, dynamic, Timer, "CastParam", """line 80, column 50 of dart:async/timer.dart: """, x0 is Timer, true));
     return f == null ? null : c;
    }
  , callback, __t179, __t177, "Wrap", """line 80, column 50 of dart:async/timer.dart: """, callback is __t177), runGuarded: true));
  }
 static void run(void callback()) {
  new Timer(Duration.ZERO, callback);
  }
 void cancel();
 bool get isActive;
 external static Timer _createTimer(Duration duration, void callback());
 external static Timer _createPeriodicTimer(Duration duration, void callback(Timer timer));
}
 typedef dynamic __t177(dynamic __u178);
 typedef void __t179(Timer __u180);
