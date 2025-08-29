// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:dart_style/dart_style.dart';

import '../../test/simple_stats.dart';

/// Key used for a strategy in a test setup.
class Strategy {
  /// The Dart identifier for this strategy.
  ///
  /// This is used to generate code that refers to this strategy.
  final String dartIdentifier;

  /// The short name of the strategy used in printouts.
  final String name;

  /// A full description of the strategy.
  final String description;

  const Strategy(this.dartIdentifier, this.name, this.description);

  @override
  int get hashCode => name.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Strategy && name == other.name;
  }

  @override
  String toString() => 'Strategy($name)';
}

/// Key used for a scenario used when running a test.
class Scenario {
  /// The Dart identifier for this scenario.
  ///
  /// This is used to generate code that refers to this scenario.
  final String dartIdentifier;

  /// The short name of the scenario used in printouts.
  final String name;

  /// A full description of the scenario.
  final String description;

  const Scenario(this.dartIdentifier, this.name, this.description);

  @override
  int get hashCode => name.hashCode;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Scenario && name == other.name;
  }

  @override
  String toString() => 'Strategy($name)';
}

/// The values that constitutes the input size values of the test.
class XAxis {
  final List<num> values;

  const XAxis(this.values);
}

/// Key for a strategy/scenario pair.
class SeriesKey {
  final Strategy strategy;
  final Scenario scenario;

  const SeriesKey(this.strategy, this.scenario);

  @override
  int get hashCode => strategy.hashCode * 13 + scenario.hashCode * 17;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SeriesKey &&
        strategy == other.strategy &&
        scenario == other.scenario;
  }

  @override
  String toString() => 'SeriesKey($strategy,$scenario)';
}

/// Data collected for running one strategy using one scenario.
class Series {
  /// The key that identifiers this series.
  final SeriesKey key;

  /// The x-axis values corresponding the [values].
  final XAxis xAxis;

  /// The measured values. The indices of the outer list corresponds to the
  /// indices of the [xAxis]. The size of the inner list is the number
  /// measurements performed for that x-value.
  final List<List<num>> values;

  const Series(this.key, this.xAxis, this.values);

  /// Returns a new [Series] where measurements have been removed using
  /// [filter].
  ///
  /// This can for instance be used to remove outliers from the measurements.
  Series filter(List<num> filter(List<num> list)) {
    List<List<num>> filteredValues = [];
    for (List<num> list in values) {
      filteredValues.add(filter(list));
    }
    return new Series(key, xAxis, filteredValues);
  }
}

/// A full set of series collected for a set of strategies and scenarios.
class SeriesSet {
  final String name;

  /// The shared x-axis of all series in [seriesList].
  final XAxis xAxis;

  /// All collected [Series].
  final List<Series> seriesList;

  const SeriesSet(this.name, this.xAxis, this.seriesList);

  /// Returns a new [SeriesSet] where measurements have been removed using
  /// [filter].
  ///
  /// This can for instance be used to remove outliers from the measurements.
  SeriesSet filter(List<num> filter(List<num> list)) {
    List<Series> filteredSeries = [];
    for (Series series in this.seriesList) {
      filteredSeries.add(series.filter(filter));
    }
    return new SeriesSet(name, xAxis, filteredSeries);
  }

  /// Returns a tab-based table of the averages of all measurements for a given
  /// [scenario].
  String getAveragedSpreadByScenario(Scenario scenario) {
    Map<Series, List<num>> stats = {};
    for (Series series in this.seriesList) {
      if (series.key.scenario != scenario) continue;
      stats[series] = series.values
          .map((data) => SimpleTTestStat.average(data))
          .toList(growable: false);
    }
    StringBuffer sb = new StringBuffer();
    sb.write(scenario.name);
    for (Series series in stats.keys) {
      sb.write('\t${series.key.strategy.name}');
    }
    sb.writeln();
    for (int index = 0; index < xAxis.values.length; index++) {
      sb.write(xAxis.values[index]);
      for (List<num> stat in stats.values) {
        sb.write('\t');
        sb.write(stat[index]);
      }
      sb.writeln();
    }
    return sb.toString();
  }

  /// Returns a tab-based table of all measurements for a given [scenario].
  String getFullSpreadByScenarioTable(Scenario scenario) {
    List<Series> seriesList = [];
    for (Series series in this.seriesList) {
      if (series.key.scenario != scenario) continue;
      seriesList.add(series);
    }
    StringBuffer sb = new StringBuffer();
    sb.write(scenario.name);
    for (Series series in seriesList) {
      int columns = series.values.map((l) => l.length).reduce(math.max);
      sb.write('\t${series.key.strategy.name}');
      for (int i = 0; i < columns; i++) {
        sb.write('\t');
      }
    }
    sb.writeln();
    for (int index = 0; index < xAxis.values.length; index++) {
      sb.write(xAxis.values[index]);
      for (Series series in seriesList) {
        List<num> values = series.values[index];
        for (int i = 0; i < values.length; i++) {
          sb.write('\t${values[i]}');
        }
      }
      sb.writeln();
    }
    return sb.toString();
  }

  /// Returns the Dart code for declaring this [SeriesSet].
  ///
  /// This can be used to store a measurement in code for later comparison.
  String toDartCode() {
    String xAxisName = 'xAxis_$name';
    String seriesSetName = 'seriesSet_$name';
    StringBuffer sb = new StringBuffer();
    sb.write('const XAxis $xAxisName = const XAxis([');
    for (int index = 0; index < xAxis.values.length; index++) {
      if (index > 0) {
        sb.write(', ');
      }
      sb.write(xAxis.values[index]);
    }
    sb.write(']);');

    sb.write('''const SeriesSet $seriesSetName = 
        const SeriesSet('$seriesSetName', $xAxisName, [''');
    for (int seriesIndex = 0; seriesIndex < seriesList.length; seriesIndex++) {
      Series series = seriesList[seriesIndex];
      sb.write('''
      Series(
        SeriesKey(
          ${series.key.strategy.dartIdentifier},
          ${series.key.scenario.dartIdentifier}), 
        $xAxisName, [''');
      for (List<num> values in series.values) {
        sb.write('[');
        for (int index = 0; index < values.length; index++) {
          if (index > 0) {
            sb.write(', ');
          }
          sb.write(values[index]);
        }
        sb.write('],');
      }
      sb.write(']),');
    }
    sb.write(']);');
    return new DartFormatter(
      languageVersion: DartFormatter.latestShortStyleLanguageVersion,
    ).format(sb.toString());
  }
}

/// Registry used to collect data during measurement.
class Registry {
  final Set<num> _xAxisSet = {};
  final Map<SeriesKey, Map<num, List<num>>> _seriesMap = {};

  /// Registers the measurement of [y] for the given [x] value under the
  /// strategy/scenario defined by [key].
  void registerData(SeriesKey key, num x, num y) {
    _xAxisSet.add(x);
    ((_seriesMap[key] ??= {})[x] ??= []).add(y);
  }

  /// Generates [SeriesSet] for all collected measurements.
  SeriesSet generateSeriesSet() {
    XAxis xAxis = new XAxis(_xAxisSet.toList(growable: false)..sort());
    List<Series> series = [];
    for (MapEntry<SeriesKey, Map<num, List<num>>> entry in _seriesMap.entries) {
      SeriesKey key = entry.key;
      Map<num, List<num>> valuesMap = entry.value;
      List<List<num>> values = [];
      for (num x in xAxis.values) {
        values.add(valuesMap[x] ?? []);
      }
      series.add(new Series(key, xAxis, values));
    }
    _xAxisSet.clear();
    _seriesMap.clear();
    return new SeriesSet(new DateTime.now().toText(), xAxis, series);
  }
}

/// Filter function that removes the max [removeMaxCount] values from a list.
///
/// This can be used in [Series.filter] and [SeriesSet.filter] to remove
/// outliers from a set of measurements.
List<num> removeMax(List<num> list, int removeMaxCount) {
  if (removeMaxCount == 0) return list;
  List<num> copy = list.toList()..sort();
  for (int i = 0; i < removeMaxCount; i++) {
    copy.removeLast();
  }
  return copy;
}

extension on DateTime {
  String toText() {
    String y = _padLeft(year, 4);
    String m = _padLeft(month, 2);
    String d = _padLeft(day, 2);
    return '$y$m$d';
  }

  static String _padLeft(int value, int length) {
    String text = '$value';
    return '0' * (length - text.length) + text;
  }
}
