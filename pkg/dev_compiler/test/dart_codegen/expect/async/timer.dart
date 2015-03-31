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
   return Zone.current.createPeriodicTimer(duration, ((__x129) => DEVC$RT.wrap((dynamic f(dynamic __u124)) {
    dynamic c(dynamic x0) => f(x0);
     return f == null ? null : c;
    }
  , __x129, __t127, __t125, "Wrap", """line 80, column 19 of dart:async/timer.dart: """, __x129 is __t125))(Zone.current.bindUnaryCallback(callback, runGuarded: true)));
  }
 static void run(void callback()) {
  new Timer(Duration.ZERO, callback);
  }
 void cancel();
 bool get isActive;
 external static Timer _createTimer(Duration duration, void callback());
 external static Timer _createPeriodicTimer(Duration duration, void callback(Timer timer));
}
 typedef void __t125(Timer __u126);
 typedef dynamic __t127(dynamic __u128);
