Object? foo(int i) => "42";
Object? bar<T>(T t) => 42;

main() {
  Function? f1 = foo;
  f1!(42);

  Function f2 = bar;
  f2<int>(42);
}
