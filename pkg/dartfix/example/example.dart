// This file contains code that is modified by running dartfix.
// After running dartfix, the content of this file matches example-fixed.dart.

// Dart will automatically convert int literals to doubles.
// Running dartfix converts this double literal to an int.
const double myDouble = 4.0;

// This class is used as a mixin but does not use the new mixin syntax.
// Running dartfix converts this class to use the new syntax.
class MyMixin {
  final someValue = myDouble;
}

class MyClass with MyMixin {}

main() {
  print('myDouble = ${MyClass().someValue}');
}
