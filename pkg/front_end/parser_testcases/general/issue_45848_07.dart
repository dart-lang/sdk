void f(bool b1, bool b2) {
  print('b1=$b1, b2=$b2');
}

g(int x, int y, int a, int b, int c, int d) {
  f(x<y, (a, b) > (c, d));
}

main() {
  g(0, 1, 2, 3, 5, 6);
}

// To make run one should also have an extension method, see
// https://github.com/dart-lang/language/issues/2407#issuecomment-1215378709
