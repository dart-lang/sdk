// Introduce a named parameter with a given string name.
typedef Bar = String Function({String someString});

class Foo {
  Bar? _bar;
  Foo(this._bar);
}

void main() {
  // Create a String constant that matches the name of the above named param.
  print("someString");

  // Include an expression whose static type involves the named param above. But
  // importantly do not create an instance of the type.
  final x = Foo(null)._bar;
}
