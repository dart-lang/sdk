Future<int> f() => Future.value(7);

List<int> g() {
  yield f();
}
