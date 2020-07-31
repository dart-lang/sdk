Future<void> f() => Future.value();

void g() {
  await f();
}
