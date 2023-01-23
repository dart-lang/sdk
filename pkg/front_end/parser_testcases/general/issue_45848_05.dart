void f(bool b1, bool b2) {
  print('b1=$b1, b2=$b2');
}

g1(int x, int y, int o, Object p) {
  f(x < y, o > (p as int));
}

g2(int x, int y, int o, int p) {
  // Spec example where it says
  // "In this situation, the expression is always
  //  parsed as a generic function invocation."
  f(x<y, o>(p));
}

main() {
  g1(0, 1, 2, 3);
  g2(0, 1, 2, 3);
}
