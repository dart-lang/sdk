main() {
  final record = ((a: 1, b: 2), 3);
  final ((a: a, :b), c) = record;
  print("a = $a; b = $b, c = $c");
}
