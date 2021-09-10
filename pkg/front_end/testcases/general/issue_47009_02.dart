main() {
  int b = 1;
  int c = 2;
  int d = 3;
  int e = 4;
  int as = 5;
  a(b < c, d < e, as >> (1));
}

void a(bool x, bool y, int z) {
  print("$x $y $z");
}