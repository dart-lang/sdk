void foo() {
  // With ending comma.
  (42, 42, 42, );
  (foo: 42, bar: 42, 42, baz: 42, );

  // Nested.
  ((42, 42), 42);

  // With function inside.
  ((foo, bar) => 42, 42);
}
