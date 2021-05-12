Future<int> f() => Future.value(7);
// @dart=2.9
List<int> g() {
  yield f();
}
