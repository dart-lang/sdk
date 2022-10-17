class Foo extends Bar {
  Foo((int, int) super.x);
  Foo([(int, int) super.x]);
  Foo({(int, int) super.x});
  Foo({required (int, int) super.x});
}
