method1(o) => switch (o) {
    final int a => 'working',
    final String a => 'working',
    final () a => 'working',
    final (int, String) a => 'working',
    final int a? => 'working',
    final String a? => 'working',
    final () a? => 'working',
    final (int, String) a? => 'working',
    (:final () a) => 'working',
    (:final (int, String) a) => 'working',
    (:final int a?) => 'working',
    (:final String a?) => 'working',
    (:final () a?) => 'working',
    (:final (int, String) a?) => 'working',
    _ => '',
  };

method2(o) => switch (o) {
    final int async => 'working',
    final String async => 'working',
    // Notice how `() async => ` means something here...
    final () async => 'working',
    final (int, String) async => 'working',
    final int async? => 'working',
    final String async? => 'working',
    final () async? => 'working',
    final (int, String) async? => 'working',
    (:final () async) => 'working',
    (:final (int, String) async) => 'working',
    (:final int async?) => 'working',
    (:final String async?) => 'working',
    (:final () async?) => 'working',
    (:final (int, String) async?) => 'working',
    _ => '',
  };

void foo() {
  // ...and the same thing something different here!
  () async => print("async unnamed taking 0 parameters");
  (int x) async => print("async unnamed taking 1 parameter");
  (int x, int y) async => print("async unnamed taking 2 parameters");
}