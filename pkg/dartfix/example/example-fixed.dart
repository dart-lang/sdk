// This file contains code that has been modified by running dartfix.
// See example.dart for the original unmodified code.

// Dart will automatically convert int literals to doubles.
// Running dartfix converts this double literal to an int.
const double myDouble = 4;

// This class is used as a mixin but does not use the new mixin syntax.
// Running dartfix converts this class to use the new syntax.
mixin MyMixin {
  final someValue = myDouble;
}

class MyClass with MyMixin {}

main() {
  print('myDouble = ${MyClass().someValue}');
}
