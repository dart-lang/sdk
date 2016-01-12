foo(a, b) => ((a & 0xff0000) >> 1) & b;
main() {
  print(foo(123, 234));
  print(foo(0, 2));
}
