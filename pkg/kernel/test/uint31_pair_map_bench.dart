import 'package:kernel/type_propagation/canonicalizer.dart';

main() {
  Stopwatch watch = new Stopwatch()..start();

  const int lowBiasKeys = 100;
  const int highBiasKeys = 10000;
  const int noBiasKeys = 1000;

  Uint31PairMap map;

  // Warm up.
  map = new Uint31PairMap();
  for (int i = 0; i < noBiasKeys; ++i) {
    for (int j = 0; j < noBiasKeys; ++j) {
      map.lookup(i, j);
      map.put(i + j);
    }
  }

  // Even distributed tuple components.
  watch.reset();
  map = new Uint31PairMap();
  for (int i = 0; i < noBiasKeys; ++i) {
    for (int j = 0; j < noBiasKeys; ++j) {
      map.lookup(i, j);
      map.put(i + j);
    }
  }
  int noBiasTime = watch.elapsedMicroseconds;

  // Left-bias: more unique keys in the first component.
  watch.reset();
  map = new Uint31PairMap();
  for (int i = 0; i < highBiasKeys; ++i) {
    for (int j = 0; j < lowBiasKeys; ++j) {
      map.lookup(i, j);
      map.put(i + j);
    }
  }
  int leftBiasTime = watch.elapsedMicroseconds;

  // Right-bias: more unique keys in the second component.
  watch.reset();
  map = new Uint31PairMap();
  for (int i = 0; i < lowBiasKeys; ++i) {
    for (int j = 0; j < highBiasKeys; ++j) {
      map.lookup(i, j);
      map.put(i + j);
    }
  }
  int rightBiasTime = watch.elapsedMicroseconds;

  print('''
bias.none:  ${formatTime(noBiasTime)}
bias.left:  ${formatTime(leftBiasTime)}
bias.right: ${formatTime(rightBiasTime)}
''');
}


String formatTime(int microseconds) {
  double seconds = microseconds / 1000000.0;
  return '$seconds s';
}
