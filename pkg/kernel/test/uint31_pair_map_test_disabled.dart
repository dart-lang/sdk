import 'dart:math';
import 'package:kernel/type_propagation/canonicalizer.dart';
import 'package:test/test.dart';

Random random = new Random(12345);

main() {
  test('Uint31PairMap randomized tests', runTest);
}

runTest() {
  const int trials = 1000;
  const int insertions = 1000;
  const int uniqueKeys = 900;
  for (int trial = 0; trial < trials; ++trial) {
    int nextValue = 1;
    Map<Point<int>, int> trusted = <Point<int>, int>{};
    Uint31PairMap candidate = new Uint31PairMap();
    for (int i = 0; i < insertions; ++i) {
      int x = random.nextInt(uniqueKeys);
      int y = random.nextInt(uniqueKeys);
      Point key = new Point(x, y);
      int trustedValue = trusted[key];
      int candidateValue = candidate.lookup(x, y);
      expect(candidateValue, equals(trustedValue));
      if (trustedValue == null) {
        int newValue = nextValue++;
        trusted[key] = newValue;
        candidate.put(newValue);
      }
    }
  }
}
