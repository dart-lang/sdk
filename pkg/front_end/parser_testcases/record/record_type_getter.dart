// Not getter, but method called 'get'.
(int a, String b) get(int x) => (42, "fortytwo");
(int a, String b) get(int x) { return (42, "fortytwo"); }

// Getter called get.
(int a, String b) get get => (42, "fortytwo");
(int a, String b) get get { return (42, "fortytwo"); }

// Getter called something else.
(int a, String b) get topLevelGetter => (42, "fortytwo");
(int a, String b) get topLevelGetter { return (42, "fortytwo"); }

class Foo {
  // Not getter, but method called 'get'.
  (int a, String b) get(int x) => (42, "fortytwo");
  (int a, String b) get(int x) { return (42, "fortytwo"); }

  // Getter called get.
  (int a, String b) get get => (42, "fortytwo");
  (int a, String b) get get { return (42, "fortytwo"); }

  // Getter called something else.
  (int a, String b) get instanceGetter => (42, "fortytwo");
  (int a, String b) get instanceGetter { return (42, "fortytwo"); }
}

class Bar {
  // Not getter, but method called 'get'.
  static (int a, String b) get(int x) => (42, "fortytwo");
  static (int a, String b) get(int x) { return (42, "fortytwo"); }

  // Getter called get.
  static (int a, String b) get get => (42, "fortytwo");
  static (int a, String b) get get { return (42, "fortytwo"); }

  // Getter called something else.
  static (int a, String b) get staticGetter => (42, "fortytwo");
  static (int a, String b) get staticGetter { return (42, "fortytwo"); }
}
