void func1() {
  throw new Exception("Test peanut gallery request for Full stacktrace");
}
void func2() {
  func1();
}
void func3() {
  try {
    func2();
  } on Object catch(e, s) {
    print(e);
    var full_trace = s.fullStackTrace;
    Expect.isTrue(full_trace.contains("func1"));
    Expect.isTrue(full_trace.contains("func2"));
    Expect.isTrue(full_trace.contains("func3"));
    Expect.isTrue(full_trace.contains("func4"));
    Expect.isTrue(full_trace.contains("func5"));
    Expect.isTrue(full_trace.contains("func6"));
    Expect.isTrue(full_trace.contains("func7"));
    Expect.isTrue(full_trace.contains("main"));

    var trace = s.stackTrace;
    Expect.isTrue(trace.contains("func1"));
    Expect.isTrue(trace.contains("func2"));
    Expect.isTrue(trace.contains("func3"));

    Expect.isFalse(trace.contains("func4"));
    Expect.isFalse(trace.contains("func5"));
    Expect.isFalse(trace.contains("func6"));
    Expect.isFalse(trace.contains("func7"));
    Expect.isFalse(trace.contains("main"));

    print(s);

    print("Full stack trace");
    print(full_trace);

    print("Stack trace");
    print(trace);
    throw new Exception("This is not a rethrow");
  }
}
int func4() {
  func3();
  return 1;
}
int func5() {
  try {
    func4();
  } on Object catch(e, s) {
    var full_trace = s.fullStackTrace;
    Expect.isFalse(full_trace.contains("func1"));
    Expect.isFalse(full_trace.contains("func2"));
    Expect.isTrue(full_trace.contains("func3"));
    Expect.isTrue(full_trace.contains("func4"));
    Expect.isTrue(full_trace.contains("func5"));
    Expect.isTrue(full_trace.contains("func6"));
    Expect.isTrue(full_trace.contains("func7"));
    Expect.isTrue(full_trace.contains("main"));

    var trace = s.stackTrace;
    Expect.isFalse(trace.contains("func1"));
    Expect.isFalse(trace.contains("func2"));

    Expect.isTrue(trace.contains("func3"));
    Expect.isTrue(trace.contains("func4"));
    Expect.isTrue(trace.contains("func5"));

    Expect.isFalse(trace.contains("func6"));
    Expect.isFalse(trace.contains("func7"));
    Expect.isFalse(trace.contains("main"));

    print(s);

    print("Full stack trace");
    print(full_trace);

    print("Stack trace");
    print(trace);
  }
  return 1;
}
int func6() {
  func5();
  return 1;
}
int func7() {
  func6();
  return 1;
}
main() {
  var i = func7();
  Expect.equals(1, i);
}
