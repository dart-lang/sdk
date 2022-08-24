// Not setter, but method called 'set'.
(int a, String b) set(int x) => (42, "fortytwo");

// Setter called set.
void set set((int a, String b) x) => (42, "fortytwo");

// Getter called set.
(int a, String b) get set => (42, "fortytwo");

// Setter called something else.
void set topLevelSetter((int a, String b) x) => (42, "fortytwo");

class Foo {
  // Not setter, but method called 'set'.
  (int a, String b) set(int x) => (42, "fortytwo");

  // Setter called set.
  void set set((int a, String b) x) => (42, "fortytwo");

  // Getter called set.
  (int a, String b) get set => (42, "fortytwo");

  // Setter called something else.
  void set instanceSetter((int a, String b) x) => (42, "fortytwo");
}

class Bar {
  // Not setter, but method called 'set'.
  static (int a, String b) set(int x) => (42, "fortytwo");

  // Setter called set.
  static void set set((int a, String b) x) => (42, "fortytwo");

  // Getter called set.
  static (int a, String b) get set => (42, "fortytwo");

  // Setter called something else.
  static void set staticSetter((int a, String b) x) => (42, "fortytwo");
}
