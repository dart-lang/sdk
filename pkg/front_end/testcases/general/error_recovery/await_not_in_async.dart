Future<void> f() => Future.value();
// @dart=2.9
void g() {
  await f();
}
