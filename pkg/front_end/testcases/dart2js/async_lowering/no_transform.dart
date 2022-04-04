Future<void> foo1() async {
  await 6;
}

Future<int> foo2() async {
  return await 6;
}

void main() {
  foo1();
  foo2();
}
