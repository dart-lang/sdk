// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'util.dart';

typedef TestFunction<T, U> = Set<U> Function(List<T>);

class InputOutputData<T, U> {
  final List<T> input;
  final Set<U> output;

  const InputOutputData(this.input, this.output);
}

const Strategy simpleAddStrategy = Strategy('simple-add', '''
Add entries to a list one at a time.''');

const Strategy mapToSetStrategy = Strategy('mapToSet', '''
Create the set via new Set.from([...].map([...]).''');

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

const Scenario emptyScenario = Scenario('empty', '''
The input and output is empty.''');
const Scenario oneEntryScenario = Scenario('one', '''
The input is one entry.''');
const Scenario severalEntriesScenario = Scenario('several', '''
The input has several entries.''');

class Input {
  final String content;

  const Input(this.content);
}

Map<Scenario, InputOutputData<Input, String>> scenarios = {
  emptyScenario: const InputOutputData([], {}),
  oneEntryScenario: const InputOutputData([Input("a")], {"a"}),
  severalEntriesScenario: const InputOutputData(
    [
      Input("a"),
      Input("b"),
      Input("c"),
      Input("d"),
      Input("e"),
      Input("f"),
    ],
    {
      "a",
      "b",
      "c",
      "d",
      "e",
      "f",
    },
  ),
};

class Test<T, U> {
  final int size;
  final Map<Strategy, TestFunction<T, U>> strategies;

  const Test(this.size, this.strategies);

  void _test(Registry registry, SeriesKey key, int runs, int iterations,
      List<T> input, Set<U> expectedResult, TestFunction<T, U> testFunction) {
    for (int run = 0; run < runs; run++) {
      Stopwatch sw = new Stopwatch();
      for (int i = 0; i < iterations; i++) {
        sw.start();
        Set<U> actualOutput = testFunction(input);
        sw.stop();
        checkEquals(actualOutput, expectedResult);
      }
      registry.registerData(key, size, sw.elapsedMicroseconds);
    }
  }

  void checkEquals(Set<U> a, Set<U> b) {
    if (a.length != b.length) throw "length for $a vs $b";
    Set<U> copy = new Set<U>.of(a);
    copy.removeAll(b);
    if (copy.isNotEmpty) throw "Not same content";
  }

  void performTest(
      {required Registry registry,
      required int runs,
      required int iterations,
      required Map<Scenario, InputOutputData<T, U>> scenarios}) {
    for (MapEntry<Scenario, InputOutputData<T, U>> scenario
        in scenarios.entries) {
      List<T> scenarioInput = scenario.value.input;
      Set<U> scenarioExpectedOutput = scenario.value.output;
      for (MapEntry<Strategy, TestFunction<T, U>> entry in strategies.entries) {
        _test(registry, new SeriesKey(entry.key, scenario.key), runs,
            iterations, scenarioInput, scenarioExpectedOutput, entry.value);
      }
    }
  }
}

List<Test<Input, String>> tests = [
  // "size" isn't used here...
  Test<Input, String>(-1, {
    simpleAddStrategy: simplyAdd,
    listGenerateGrowableStrategy: listGenerateGrowable,
    listGenerateNotGrowableStrategy: listGenerateNotGrowable,
    listFilledGrowableStrategy: listFilledGrowable,
    listFilledNotGrowableStrategy: listFilledNotGrowable,
    mapToSetStrategy: mapToSet,
  }),
];

Set<String> simplyAdd(List<Input> input) {
  Set<String> result = {};
  for (int i = 0; i < input.length; i++) {
    result.add(input[i].content);
  }
  return result;
}

Set<String> listGenerateGrowable(List<Input> input) {
  return Set<String>.from(List<String>.generate(
      input.length, (index) => input[index].content,
      growable: true));
}

Set<String> listGenerateNotGrowable(List<Input> input) {
  return Set<String>.from(List<String>.generate(
      input.length, (index) => input[index].content,
      growable: false));
}

Set<String> listFilledGrowable(List<Input> input) {
  List<String> result = List<String>.filled(input.length, "", growable: true);
  for (int i = 0; i < input.length; i++) {
    result[i] = input[i].content;
  }
  return Set<String>.from(result);
}

Set<String> listFilledNotGrowable(List<Input> input) {
  List<String> result = List<String>.filled(input.length, "", growable: false);
  for (int i = 0; i < input.length; i++) {
    result[i] = input[i].content;
  }
  return Set<String>.from(result);
}

Set<String> mapToSet(List<Input> input) {
  return new Set<String>.from(input.map((e) => e.content));
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
