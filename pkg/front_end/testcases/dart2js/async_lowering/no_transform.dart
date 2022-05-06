// Contains await with no return.
Future<void> foo1() async {
  await 6;
}

// Await is not direct child of return.
Future<int> foo2() async {
  return (await 6) + 3;
}

// Function contains an async for-in loop.
Future<void> foo3() async {
  await for (final x in Stream.empty()) {
    break;
  }
}

// Function contains a try-finally statement.
Future<int> foo4() async {
  try {
    return 3;
  } finally {
    return 2;
  }
}

// Function contains a try-catch statement.
Future<int> foo5() async {
  try {
    return 3;
  } catch (e) {
    return 2;
  }
}

void main() {
  foo1();
  foo2();
  foo3();
  foo4();
  foo5();
}
