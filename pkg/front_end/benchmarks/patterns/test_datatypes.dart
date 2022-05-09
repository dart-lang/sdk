// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.14

import 'util.dart';
import 'generated/datatype.dart';

typedef TestFunction<T> = void Function(T, Counter);
typedef DataFunction = List<T> Function<T>(List<T>);

class Counter {
  int _value = 0;

  int get value => _value;

  void inc() {
    _value++;
  }
}

const Strategy ifThenElseStrategy = Strategy('if-then-else', '''
Implements functionality in helper method. Invocation is done by an if-then-else
sequence that uses is-tests to match functionality with subclasses.''');

const Strategy dynamicDispatchStrategy = Strategy('dynamic-dispatch', '''
Implements functionality by adding a method to each subclass that implements an
interface method. Invocation is done as a dynamic dispatch on the interface 
method.''');

const Strategy visitorStrategy = Strategy('visitor', '''
Implements functionality in helper method. Invocation is done by an if-then-else
sequence that uses is-tests to match functionality with subclasses.''');

const Scenario increasingScenario = Scenario('increasing', '''
Implementation is called equally between all subclasses.''');
// TODO(johnniwinther): Should Zipf's Law be used for 'first' and 'last'
//  scenarios?
const Scenario firstScenario = Scenario('first', '''
Implementation is only called for the first two subclasses. For the 
'if-then-else' strategy, this mimics when the order of the subclasses in the 
if-then-else sequence aligns with the frequency of use, always finding a
matching case early in the if-then-else sequence.''');
const Scenario lastScenario = Scenario('last', '''
Implementation is only called for the last two subclasses. For the 
'if-then-else' strategy, this mimics when the order of the subclasses in the 
if-then-else sequence *mis-aligns* with the frequency of use, always finding a
matching case late in the if-then-else sequence.''');

Map<Scenario, DataFunction> scenarios = {
  increasingScenario: <T>(List<T> data) => data,
  firstScenario: <T>(List<T> data) {
    if (data.length < 2) {
      return [data.first, data.first];
    } else {
      return data.take(2).toList();
    }
  },
  lastScenario: <T>(List<T> data) {
    if (data.length < 2) {
      return [data.last, data.last];
    } else {
      return data.skip(data.length - 2).toList();
    }
  },
};

class Test<T> {
  final int size;
  final List<T> Function() createData;
  final Map<Strategy, TestFunction<T>> strategies;

  const Test(this.size, this.createData, this.strategies);

  void _test(Registry registry, SeriesKey key, int runs, int iterations,
      List<T> data, TestFunction<T> testFunction) {
    int length = data.length;
    for (int run = 0; run < runs; run++) {
      Counter counter = new Counter();
      Stopwatch sw = new Stopwatch();
      for (int i = 0; i < iterations; i++) {
        T value = data[i % length];
        sw.start();
        testFunction(value, counter);
        sw.stop();
      }
      registry.registerData(key, size, sw.elapsedMicroseconds);
      if (counter.value != iterations) {
        throw 'Counter mismatch: '
            'Expected $iterations, actual ${counter.value}';
      }
    }
  }

  void performTest(
      {required Registry registry,
      required int runs,
      required int iterations,
      required Map<Scenario, DataFunction> scenarios}) {
    List<T> data = createData();
    for (MapEntry<Scenario, DataFunction> scenario in scenarios.entries) {
      List<T> scenarioData = scenario.value(data);
      for (MapEntry<Strategy, TestFunction<T>> entry in strategies.entries) {
        _test(registry, new SeriesKey(entry.key, scenario.key), runs,
            iterations, scenarioData, entry.value);
      }
    }
  }
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
