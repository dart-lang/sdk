class A {}

extension AList on Iterable<A> {
  get foo => null;
}

extension AMap on Map<String, A> {
  get bar => values.foo; // <-- foo is underlined red
}
