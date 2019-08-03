// This file contains code that has been modified by running dartfix.
// See example.dart for the original unmodified code.

// ignore_for_file: prefer_is_empty

// Dart will automatically convert int literals to doubles.
// Running dartfix converts this double literal to an int
// if --double-to-int is specified on the command line.
const double myDouble = 4;

// This class is used as a mixin but does not use the new mixin syntax.
// Running dartfix converts this class to use the new syntax.
mixin MyMixin {
  final someValue = myDouble;
}

class MyClass with MyMixin {}

main(List<String> args) {
  if (args.length == 0) {
    print('myDouble = ${MyClass().someValue}');
  }
}
