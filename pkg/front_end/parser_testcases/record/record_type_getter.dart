// Not getter, but method called 'get'.
(int a, String b) get(int x) => (42, "fortytwo");
(int a, String b) get(int x) { return (42, "fortytwo"); }
(int a, String b) get(int x) async => throw "hello";
(int a, String b) get(int x) async { throw "hello"; }
(int a, String b) get(int x) async* => throw "hello";
(int a, String b) get(int x) async* { throw "hello"; }
(int a, String b) get(int x) sync* => throw "hello";
(int a, String b) get(int x) sync* { throw "hello"; }

// Getter called get.
(int a, String b) get get => (42, "fortytwo");
(int a, String b) get get { return (42, "fortytwo"); }
(int a, String b) get get async => throw "hello";
(int a, String b) get get async { throw "hello"; }
(int a, String b) get get async* => throw "hello";
(int a, String b) get get async* { throw "hello"; }
(int a, String b) get get sync* => throw "hello";
(int a, String b) get get sync* { throw "hello"; }

// Getter called something else.
(int a, String b) get topLevelGetter => (42, "fortytwo");
(int a, String b) get topLevelGetter { return (42, "fortytwo"); }
(int a, String b) get topLevelGetter async => throw "hello";
(int a, String b) get topLevelGetter async { throw "hello"; }
(int a, String b) get topLevelGetter async* => throw "hello";
(int a, String b) get topLevelGetter async* { throw "hello"; }
(int a, String b) get topLevelGetter sync* => throw "hello";
(int a, String b) get topLevelGetter sync* { throw "hello"; }

class Foo {
  // Not getter, but method called 'get'.
  (int a, String b) get(int x) => (42, "fortytwo");
  (int a, String b) get(int x) { return (42, "fortytwo"); }
  (int a, String b) get(int x) async => throw "hello";
  (int a, String b) get(int x) async { throw "hello"; }
  (int a, String b) get(int x) async* => throw "hello";
  (int a, String b) get(int x) async* { throw "hello"; }
  (int a, String b) get(int x) sync* => throw "hello";
  (int a, String b) get(int x) sync* { throw "hello"; }

  // Getter called get.
  (int a, String b) get get => (42, "fortytwo");
  (int a, String b) get get { return (42, "fortytwo"); }
  (int a, String b) get get async => throw "hello";
  (int a, String b) get get async { throw "hello"; }
  (int a, String b) get get async* => throw "hello";
  (int a, String b) get get async* { throw "hello"; }
  (int a, String b) get get sync* => throw "hello";
  (int a, String b) get get sync* { throw "hello"; }

  // Getter called something else.
  (int a, String b) get instanceGetter => (42, "fortytwo");
  (int a, String b) get instanceGetter { return (42, "fortytwo"); }
  (int a, String b) get instanceGetter async => throw "hello";
  (int a, String b) get instanceGetter async { return throw "hello"; }
  (int a, String b) get instanceGetter async* => throw "hello";
  (int a, String b) get instanceGetter async* { return throw "hello"; }
  (int a, String b) get instanceGetter sync* => throw "hello";
  (int a, String b) get instanceGetter sync* { return throw "hello"; }
}

class Bar {
  // Not getter, but method called 'get'.
  static (int a, String b) get(int x) => (42, "fortytwo");
  static (int a, String b) get(int x) { return (42, "fortytwo"); }
  static (int a, String b) get(int x) async => throw "hello";
  static (int a, String b) get(int x) async { throw "hello"; }
  static (int a, String b) get(int x) async* => throw "hello";
  static (int a, String b) get(int x) async* { throw "hello"; }
  static (int a, String b) get(int x) sync* => throw "hello";
  static (int a, String b) get(int x) sync* { throw "hello"; }

  // Getter called get.
  static (int a, String b) get get => (42, "fortytwo");
  static (int a, String b) get get { return (42, "fortytwo"); }
  static (int a, String b) get get async => throw "hello";
  static (int a, String b) get get async { throw "hello"; }
  static (int a, String b) get get async* => throw "hello";
  static (int a, String b) get get async* { throw "hello"; }
  static (int a, String b) get get sync* => throw "hello";
  static (int a, String b) get get sync* { throw "hello"; }

  // Getter called something else.
  static (int a, String b) get staticGetter => (42, "fortytwo");
  static (int a, String b) get staticGetter { return (42, "fortytwo"); }
  static (int a, String b) get staticGetter async => throw "hello";
  static (int a, String b) get staticGetter async { throw "hello"; }
  static (int a, String b) get staticGetter async* => throw "hello";
  static (int a, String b) get staticGetter async* { throw "hello"; }
  static (int a, String b) get staticGetter sync* => throw "hello";
  static (int a, String b) get staticGetter sync* { throw "hello"; }
}
