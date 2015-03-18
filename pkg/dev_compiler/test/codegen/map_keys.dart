import 'dart:math' show Random;
main() {
  // Uses a JS object literal
  print({ '1': 2, '3': 4, '5': 6 });
  // Uses array literal
  print({ 1: 2, 3: 4, 5: 6 });
  // Uses ES6 enhanced object literal
  print({ '1': 2, '${new Random().nextInt(2) + 2}': 4, '5': 6 });
  String x = '3';
  // Could use enhanced object literal if we knew `x` was not null
  print({ '1': 2, x: 4, '5': 6 });
  // Array literal
  print({ '1': 2, null: 4, '5': 6 });
}
