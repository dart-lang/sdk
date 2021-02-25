// https://github.com/dart-lang/sdk/issues/43811
// https://github.com/dart-lang/sdk/issues/43812
// https://github.com/dart-lang/sdk/issues/43813

void main() {
  late x;
}

late y;

class Foo {
  late z;

  void foo() {
    late x;
  }

  static void bar() {
    late x;
  }
}