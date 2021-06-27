void f(bool b, int i) {
  print('b=$b, i=$i');
}

g(int x, int y, Object o) {
  f((x < y), (o as Function)());
}

main() {
  g(0, 1, () => 2);
}
