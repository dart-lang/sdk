extension Foo on String {
  int get giveInt => 42;
}

// The below doesn't have to be included.

extension BarExtension on Bar {
  int get giveInt => 42;
}

class Bar {}
