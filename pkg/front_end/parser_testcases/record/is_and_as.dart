foo(dynamic a) {
  final b = a;
  if (a is (int, int)) {
    print("a is (int, int)");
  }
  final c = b as (int, int);
}
