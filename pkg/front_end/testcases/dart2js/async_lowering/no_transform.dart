// Contains await with no return.
Future<void> foo1() async {
  await 6;
}

// Await is not direct child of return.
Future<int> foo2() async {
  return (await 6) + 3;
}

void main() {
  foo1();
  foo2();
}
