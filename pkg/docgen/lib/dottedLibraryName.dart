library library.name.wiith.dots.init;

/// This library is purely for testing purposes, to ensure
/// that we have a library that has dots in its name and
/// that it works properly
///
/// In addition, it's nice to have something which has paragraph
/// breaks inside a triple-slash doc comment.
///
/// Like this.

/// This is a top level field holding the number three;
int topLevelInt = 3;

/// This is a class with various ways of getting the number three.
///
/// It also has a comment with paragraph breaks.
class SomeClass {
  /// This is a method that returns the number three. See
  /// [three]
  someMethod() => 3;

  /// This is a symbolic representation of the number three.
  int three = 3;
}

/// This is another class.
class AnotherClass {
  /// This method returns [List<int>] containing the number
  /// three three times. Compare with [SomeClass.someMethod].
  List<int> anotherMethod() {
    return const [3, 3, 3];
  }
}
