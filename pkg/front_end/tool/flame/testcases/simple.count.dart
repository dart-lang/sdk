void foo(List<String> args) {
  // No "only some" calls in here.
  print("hello");
}

void bar(List<String> args) {
  // There is a "only some" call in here.
  print("hello: ${args.any((s) => s.length == 42)}");
  print("hello: ${args.firstWhereOrNull((s) => s.length == 42)}");
}

void baz(List<String> args) {
  // There is a "only some" call in here.
  if (args.length == 42) {
    print("hello: ${args.any((s) => s.length == 42)}");
  }
}

void main(List<String> args) {}

extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    // dummy that does nothing
    return null;
  }
}
