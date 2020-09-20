main() {
  // Identifiers can't have non-ascii characters.
  // Having this comment shouldn't trigger any asserts though.
  int æFoo = 42;
  // Try comment on an identifier that doesn't start with a non-ascii char too.
  int fooÆ = 42;
  // Try comment on an OK identifier too.
  int foo = 42;
  print(/* comment */ æFoo);
  print(/* comment */ fooÆ);
  print(/* comment */ foo);
}