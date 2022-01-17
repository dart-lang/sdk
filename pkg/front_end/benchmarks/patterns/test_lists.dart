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

const Strategy simpleAddStrategy = Strategy('simple-add', '''
Add entries to a list one at a time.''');

const Strategy spreadStrategy = Strategy('spread', '''
Create the list via spreads.''');

const Strategy listGenerateGrowableStrategy =
    Strategy('list-generate-growable', '''
Create list via List.generate with growable = true.''');

const Strategy listGenerateNotGrowableStrategy =
    Strategy('list-generate-not-growable', '''
Create list via List.generate with growable = false.''');

const Strategy listFilledGrowableStrategy = Strategy('list-filled-growable', '''
Create list via List.generate with growable = true.''');

const Strategy listFilledNotGrowableStrategy =
    Strategy('list-filled-not-growable', '''
Create list via List.generate with growable = false.''');

const Strategy listFilledAlternativeGrowableStrategy =
    Strategy('list-filled-alt-growable', '''
Create list via List.generate with growable = true in an alternative way.''');

const Strategy listFilledAlternativeNotGrowableStrategy =
    Strategy('list-filled-alt-not-growable', '''
Create list via List.generate with growable = false in an alternative way.''');

const Scenario emptyScenario = Scenario('empty', '''
The input and output is empty.''');
const Scenario oneEntryScenario = Scenario('one', '''
The input is one entry.''');
const Scenario severalEntriesScenario = Scenario('several', '''
The input has several entries.''');

Map<Scenario, InputOutputData<String>> scenarios = {
  emptyScenario: const InputOutputData([], []),
  oneEntryScenario: const InputOutputData(["a"], ["<", "a", ">"]),
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
      "<",
      "a",
      ", ",
      "b",
      ", ",
      "c",
      ", ",
      "d",
      ", ",
      "e",
      ", ",
      "f",
      ", ",
      "g",
      ">",
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
    simpleAddStrategy: simplyAdd,
    listGenerateGrowableStrategy: listGenerateGrowable,
    listGenerateNotGrowableStrategy: listGenerateNotGrowable,
    listFilledGrowableStrategy: listFilledGrowable,
    listFilledNotGrowableStrategy: listFilledNotGrowable,
    listFilledAlternativeGrowableStrategy: listFilledAlternativeGrowable,
    listFilledAlternativeNotGrowableStrategy: listFilledAlternativeNotGrowable,
    spreadStrategy: spread,
  }),
];

List<String> simplyAdd(List<String> input) {
  if (input.isEmpty) return [];
  List<String> result = [];
  result.add("<");
  result.add(input[0]);
  for (int i = 1; i < input.length; i++) {
    result.add(", ");
    result.add(input[i]);
  }
  result.add(">");
  return result;
}

List<String> listGenerateGrowable(List<String> input) {
  if (input.isEmpty) return [];
  int size = input.length * 2 + 1;
  return List<String>.generate(size, (index) {
    if (index == 0) return "<";
    if (index == size - 1) return ">";
    if (index.isEven) return ", ";
    return input[index >> 1];
  }, growable: true);
}

List<String> listGenerateNotGrowable(List<String> input) {
  if (input.isEmpty) return [];
  int size = input.length * 2 + 1;
  return List<String>.generate(size, (index) {
    if (index == 0) return "<";
    if (index == size - 1) return ">";
    if (index.isEven) return ", ";
    return input[index >> 1];
  }, growable: false);
}

List<String> listFilledAlternativeGrowable(List<String> input) {
  if (input.isEmpty) return [];
  int size = input.length * 2 + 1;
  List<String> result = List<String>.filled(size, ", ", growable: true);
  for (int i = 0; i < input.length; i++) {
    result[(i << 1) + 1] = input[i];
  }
  result[0] = "<";
  result[result.length - 1] = ">";

  return result;
}

List<String> listFilledAlternativeNotGrowable(List<String> input) {
  if (input.isEmpty) return [];
  int size = input.length * 2 + 1;
  List<String> result = List<String>.filled(size, ", ", growable: false);
  for (int i = 0; i < input.length; i++) {
    result[(i << 1) + 1] = input[i];
  }
  result[0] = "<";
  result[result.length - 1] = ">";

  return result;
}

List<String> listFilledGrowable(List<String> input) {
  if (input.isEmpty) return [];
  int size = input.length * 2 + 1;
  List<String> result = List<String>.filled(size, "", growable: true);
  int j = 0;
  result[j++] = "<";
  result[j++] = input[0];
  for (int i = 1; i < input.length; i++) {
    result[j++] = ", ";
    result[j++] = input[i];
  }
  result[j++] = ">";

  return result;
}

List<String> listFilledNotGrowable(List<String> input) {
  if (input.isEmpty) return [];
  int size = input.length * 2 + 1;
  List<String> result = List<String>.filled(size, "", growable: false);
  int j = 0;
  result[j++] = "<";
  result[j++] = input[0];
  for (int i = 1; i < input.length; i++) {
    result[j++] = ", ";
    result[j++] = input[i];
  }
  result[j++] = ">";

  return result;
}

List<String> spread(List<String> input) {
  return [
    if (input.isNotEmpty) ...[
      '<',
      input.first,
      for (String s in input.skip(1)) ...[', ', s],
      '>',
    ]
  ];
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
        registry: registry, runs: 10, iterations: 100000, scenarios: scenarios);
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
