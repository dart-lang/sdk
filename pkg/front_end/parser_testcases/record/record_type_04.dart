void gftTests() {
  // GFT with no return type.
  Function ((int, int) a, ({String foo}) b) x;

  // GFT with simple return type.
  int Function ((int, int) a) y1;

  // GFT with nullable simple return type.
  int? Function ((int, int) a) y2;

  // GFT with record return type.
  (int, int) Function ((int, int) a) z1;

  // GFT with nullable record return type.
  (int, int)? Function ((int, int) a) z2;

  // GFT with return type that is (GFT with record return type).
  (int, int) Function(bool) Function ((int, int) a) z3;

  // GFT with return type that is (GFT with nullable record return type).
  (int, int)? Function(bool) Function ((int, int) a) z4;
}
