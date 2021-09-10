main() {
  int b = 1;
  int c = 2;
  int as = 3;
  a(b < c, as > (1));
}

void a(bool x, bool y) {
  print("$x $y");
}