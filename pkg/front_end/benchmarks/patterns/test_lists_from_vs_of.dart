// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'util.dart';

typedef TestFunction<T> = List<T> Function(List<T>);

class InputOutputData<T> {
  final List<T> input;
  final List<T> output;

  const InputOutputData(this.input, this.output);
}

const Strategy fromStrategy = Strategy('from', '''
Using List.from.''');

const Strategy ofStrategy = Strategy('of', '''
Using List.of.''');

const Scenario emptyScenario = Scenario('empty', '''
The input and output is empty.''');
const Scenario oneEntryScenario = Scenario('one', '''
The input is one entry.''');
const Scenario severalEntriesScenario = Scenario('several', '''
The input has several entries.''');

Map<Scenario, InputOutputData<String>> scenarios = {
  emptyScenario: const InputOutputData([], []),
  oneEntryScenario: const InputOutputData(["a"], ["a"]),
  severalEntriesScenario: const InputOutputData(
    [
      "a",
      "b",
      "c",
      "d",
      "e",
      "f",
      "g",
    ],
    [
      "a",
      "b",
      "c",
      "d",
      "e",
      "f",
      "g",
    ],
  ),
};

class Test<T> {
  final int size;
  final Map<Strategy, TestFunction<T>> strategies;

  const Test(this.size, this.strategies);

  void _test(Registry registry, SeriesKey key, int runs, int iterations,
      List<T> input, List<T> expectedResult, TestFunction<T> testFunction) {
    for (int run = 0; run < runs; run++) {
      Stopwatch sw = new Stopwatch();
      for (int i = 0; i < iterations; i++) {
        sw.start();
        List<T> actualOutput = testFunction(input);
        sw.stop();
        checkEquals(actualOutput, expectedResult);
      }
      registry.registerData(key, size, sw.elapsedMicroseconds);
    }
  }

  void checkEquals(List<T> a, List<T> b) {
    if (a.length != b.length) throw "length for $a vs $b";
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) throw "index $i for $a vs $b";
    }
  }

  void performTest(
      {required Registry registry,
      required int runs,
      required int iterations,
      required Map<Scenario, InputOutputData<T>> scenarios}) {
    for (MapEntry<Scenario, InputOutputData<T>> scenario in scenarios.entries) {
      List<T> scenarioInput = scenario.value.input;
      List<T> scenarioExpectedOutput = scenario.value.output;
      for (MapEntry<Strategy, TestFunction<T>> entry in strategies.entries) {
        _test(registry, new SeriesKey(entry.key, scenario.key), runs,
            iterations, scenarioInput, scenarioExpectedOutput, entry.value);
      }
    }
  }
}

List<Test<String>> tests = [
  // "size" isn't used here...
  Test<String>(-1, {
    fromStrategy: from,
    ofStrategy: of,
  }),
];

List<String> from(List<String> input) {
  return new List<String>.from(input);
}

List<String> of(List<String> input) {
  return new List<String>.of(input);
}

void main() {
  // Dry run
  for (Test test in tests) {
    test.performTest(
        registry: new Registry(),
        runs: 5,
        iterations: 10,
        scenarios: scenarios);
  }
  // Actual test
  Registry registry = new Registry();
  for (Test test in tests) {
    test.performTest(
        registry: registry, runs: 10, iterations: 200000, scenarios: scenarios);
  }
  SeriesSet seriesSet = registry.generateSeriesSet();
  print('== Raw data ==');
  for (Scenario scenario in scenarios.keys) {
    print(seriesSet.getFullSpreadByScenario(scenario));
  }
  print('== Reduced averages ==');
  SeriesSet reducedSeriesSet = seriesSet.filter((list) => removeMax(list, 3));
  for (Scenario scenario in scenarios.keys) {
    print(reducedSeriesSet.getAveragedSpreadByScenario(scenario));
  }
}
