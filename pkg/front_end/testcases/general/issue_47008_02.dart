main() {
  int b = 1;
  int c = 2;
  int d = 3;
  int e = 4;
  int f = 5;
  int g = 6;
  a(b < c, d < e, f < g, 1 >>> (2));
}

void a(bool x, bool y, bool z1, int z2) {
  print("$x $y $z1 $z2");
}