Object bar<T1, T2>(T1 t1, T2 t2) => 42;

main() {
  Function f2 = bar;
  f2!<int, String>(42, "42");
}
