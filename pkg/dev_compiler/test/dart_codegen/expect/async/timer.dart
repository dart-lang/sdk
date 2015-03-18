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
   return Zone.current.createPeriodicTimer(duration, ((__x142) => DEVC$RT.wrap((dynamic f(dynamic __u137)) {
    dynamic c(dynamic x0) => f(x0);
     return f == null ? null : c;
    }
  , __x142, __t140, __t138, "Wrap", """line 80, column 19 of dart:async/timer.dart: """, __x142 is __t138))(Zone.current.bindUnaryCallback(callback, runGuarded: true)));
  }
 static void run(void callback()) {
  new Timer(Duration.ZERO, callback);
  }
 void cancel();
 bool get isActive;
 external static Timer _createTimer(Duration duration, void callback());
 external static Timer _createPeriodicTimer(Duration duration, void callback(Timer timer));
}
 typedef void __t138(Timer __u139);
 typedef dynamic __t140(dynamic __u141);
