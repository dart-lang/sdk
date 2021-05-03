void f(bool b1, bool b2) {
  print('b1=$b1, b2=$b2');
}

g(int x, int y, Object o) {
  f(x < y, 0 > (o as int));
}

main() {
  g(0, 1, 2);
}
