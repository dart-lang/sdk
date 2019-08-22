// Add to: test/_data/public_member_api_docs/lib/a.dart

extension E on Object { // LINT
  int get z => 0; // LINT

  /// ZZ.
  int get zz => 0;
  set zz(int z) // OK
  { }

  static int baz = 1; // LINT
}

extension _E on Object { // OK
  int get z => 0; // OK
  static int bar = 1; // OK
}

extension on Object { // OK
  int get z => 0; // OK
  static int foo = 1; // OK
}
