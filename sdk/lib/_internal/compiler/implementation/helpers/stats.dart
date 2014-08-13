// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.helpers;

// Helper methods for statistics.

/// Current stats collector. Use [ActiveStats] for active collection of data.
final Stats stats = new ActiveStats(new ConsolePrinter());

/// Interface for gathering and display of statistical information.
/// This class serves as the noop collector.
class Stats {
  const Stats();

  /// Registers [key], [value] pair in the map [id]. If [fromExisting] is
  /// non-null and [key] already exists, the value associated with [key] will
  /// be the return value of [fromExisting] when called with the existing value.
  ///
  /// The recorded information is not dumped automatically.
  void recordMap(id, key, value, {fromExisting(value)}) {}

  /// Returns the map [id] recorded with [recordMap].
  Map getMap(id) => const {};

  /// Registers [element] as an element of the list [id]. If provided, [data]
  /// provides additional data for [element].
  ///
  /// The recorded information is dumped automatically on call to [dumpStats].
  ///
  /// Example:
  ///   Calling [recordElement] like this:
  ///     recordElement('foo', 'a', data: 'first-a-data');
  ///     recordElement('foo', 'a', data: 'second-a-data');
  ///     recordElement('foo', 'b');
  ///     recordElement('bar', 'a', data: 'third-a-data');
  ///     recordElement('bar', 'c');
  ///   will result in a dump like this:
  ///     foo: 2
  ///      value=a data=second-a-data
  ///      b
  ///     bar: 2
  ///      value=a data=third-a-data
  ///      c
  ///
  void recordElement(id, element, {data}) {}

  /// Returns the list [id] recorded with [recordElement].
  Iterable getList(String id) => const [];

  /// Registers [value] as an occurrence of [id]. If passed, [example] provides
  /// an example data of the occurrence of [value].
  ///
  /// The recorded information is dumped automatically on call to [dumpStats].
  ///
  /// Example:
  ///   Calling [recordFrequency] like this:
  ///     recordFrequency('foo', 'a', 'first-a-data');
  ///     recordFrequency('foo', 'a', 'second-a-data');
  ///     recordFrequency('bar', 'b', 'first-b-data');
  ///     recordFrequency('foo', 'c');
  ///     recordFrequency('bar', 'b');
  ///   will result in a dump like this:
  ///     foo:
  ///      a: 2
  ///       first-a-data
  ///       second-a-data
  ///      c: 1
  ///     bar:
  ///      b: 2
  ///       first-b-data
  ///
  void recordFrequency(id, value, [example]) {}

  /// For each key/value pair in [map] the elements in the value are registered
  /// as examples of occurrences of the key in [id].
  void recordFrequencies(id, Map<dynamic, Iterable> map) {}

  /// Returns the examples given for the occurrence of [value] for [id].
  Iterable recordedFrequencies(id, value) => const [];

  /// Increases the counter [id] by 1. If provided, [example] is used as an
  /// example of the count and [data] provides additional information for
  /// [example].
  ///
  /// The recorded information is dumped automatically on call to [dumpStats].
  ///
  /// Example:
  ///   Calling [recordCounter] like this:
  ///     recordCounter('foo', 'a');
  ///     recordCounter('foo', 'a');
  ///     recordCounter('foo', 'b');
  ///     recordCounter('bar', 'c', 'first-c-data');
  ///     recordCounter('bar', 'c', 'second-c-data');
  ///     recordCounter('bar', 'd');
  ///     recordCounter('bar', 'd');
  ///     recordCounter('baz');
  ///     recordCounter('baz');
  ///   will result in a dump like this:
  ///     foo: 3
  ///      count=2 example=a
  ///      count=1 example=b
  ///     bar: 4
  ///      count=2 examples=2
  ///       c:
  ///        first-c-data
  ///        second-c-data
  ///       d
  ///     baz: 2
  ///
  void recordCounter(id, [example, data]) {}

  /// Dumps the stats for the recorded frequencies, sets, and counters. If
  /// provided [beforeClose] is called before closing the dump output. This
  /// can be used to include correlations on the collected data through
  /// [dumpCorrelation].
  void dumpStats({void beforeClose()}) {}

  /// Prints the correlation between the elements of [a] and [b].
  ///
  /// Three sets are output using [idA] and [idB] as labels for the elements
  /// [a] and [b]:
  ///
  ///   'idA && idB' lists the elements both in [a] and [b],
  ///   '!idA && idB' lists the elements not in [a] but in [b], and
  ///   'idA && !idB' lists the elements in [a] but not in [b].
  ///
  /// If [dataA] and/or [dataB] are provided, additional information on the
  /// elements are looked up in [dataA] or [dataB] using [dataA] as the primary
  /// source.
  void dumpCorrelation(idA, Iterable a, idB, Iterable b,
                       {Map dataA, Map dataB}) {}
}

/// Interface for printing output data.
///
/// This class serves as the disabled output.
class StatsOutput {
  const StatsOutput();

  /// Print [text] as on a separate line.
  void println(String text) {}
}

/// Output to the [debugPrint] method.
class DebugOutput implements StatsOutput {
  const DebugOutput();

  void println(String text) => debugPrint(text);
}

/// Interface for printing stats collected in [Stats].
abstract class StatsPrinter {
  /// The number of examples printer. If `null` all examples are printed.
  int get examples => 0;

  /// Start a group [id].
  void start(String id) {}

  /// Create a group [id] with content created by [createGroupContent].
  void group(String id, void createGroupContent()) {
    start(id);
    createGroupContent();
    end(id);
  }

  /// End a group [id].
  void end(String id) {}

  /// Start a stat entry for [id] with additional [data].
  void open(String id,
            [Map<String, dynamic> data = const <String, dynamic>{}]) {}

  /// Create a stat entry for [id] with additional [data] and content created by
  /// [createChildContent].
  void child(String id,
             [Map<String, dynamic> data = const <String, dynamic>{},
              void createChildContent()]) {
    open(id, data);
    if (createChildContent != null) createChildContent();
    close(id);
  }

  /// End a stat entry for [id].
  void close(String id) {}

  /// Starts a group of additional information.
  void beginExtra() {}

  /// Starts a group of additional information.
  void endExtra() {}
}

/// Abstract base class for [ConsolePrinter] and [XMLPrinter].
abstract class BasePrinter extends StatsPrinter with Indentation {
  final int examples;
  final StatsOutput output;

  BasePrinter({this.output: const DebugOutput(),
               this.examples: 10}) {
    indentationUnit = " ";
  }
}

/// [StatsPrinter] that displays stats in console lines.
class ConsolePrinter extends BasePrinter {
  int extraLevel = 0;

  ConsolePrinter({StatsOutput output: const DebugOutput(),
                  int examples: 10})
      : super(output: output, examples: examples);

  void open(String id,
            [Map<String, dynamic> data = const <String, dynamic>{}]) {
    if (extraLevel > 0) return;

    StringBuffer sb = new StringBuffer();
    sb.write(indentation);
    String space = '';
    if (data['title'] != null) {
      sb.write('${data['title']}:');
      space = ' ';
      data.remove('title');
    } else if (data['name'] != null) {
      sb.write('${data['name']}');
      space = ' ';
      data.remove('name');
    }
    Iterable nonNullValues = data.values.where((v) => v != null);
    if (nonNullValues.length == 1) {
      sb.write('$space${nonNullValues.first}');
    } else {
      data.forEach((key, value) {
        sb.write('$space$key=$value');
        space = ' ';
      });
    }
    output.println(sb.toString());
    indentMore();
  }

  void close(String id) {
    if (extraLevel > 0) return;

    indentLess();
  }

  void beginExtra() {
    if (extraLevel == 0) output.println('$indentation...');
    extraLevel++;
  }

  void endExtra() {
    extraLevel--;
  }
}

/// [StatsPrinter] that displays stats in XML format.
class XMLPrinter extends BasePrinter {
  static const HtmlEscape escape = const HtmlEscape();
  bool opened = false;

  XMLPrinter({output: const DebugOutput(),
              int examples: 10})
      : super(output: output, examples: examples);

  void start(String id) {
    if (!opened) {
      output.println('<?xml version="1.0" encoding="UTF-8"?>');
      opened = true;
    }
    open(id);
  }

  void end(String id) {
    close(id);
  }

  void open(String id,
            [Map<String, dynamic> data = const <String, dynamic>{}]) {
    StringBuffer sb = new StringBuffer();
    sb.write(indentation);
    sb.write('<$id');
    data.forEach((key, value) {
      if (value != null) {
        sb.write(' $key="${escape.convert('$value')}"');
      }
    });
    sb.write('>');
    output.println(sb.toString());
    indentMore();
  }

  void close(String id) {
    indentLess();
    output.println('${indentation}</$id>');
  }

  void beginExtra() {
    open('extra');
  }

  void endExtra() {
    close('extra');
  }
}

/// Actual implementation of [Stats].
class ActiveStats implements Stats {
  final StatsPrinter printer;
  Map<dynamic, Map> maps = {};
  Map<dynamic, Map<dynamic, List>> frequencyMaps = {};
  Map<dynamic, Map> setsMap = {};
  Map<dynamic, Map<dynamic, List>> countersMap =
      <dynamic, Map<dynamic, List>>{};

  ActiveStats(StatsPrinter this.printer);

  void recordMap(id, key, value, {fromExisting(value)}) {
    Map map = maps.putIfAbsent(id, () => {});
    if (fromExisting != null && map.containsKey(key)) {
      map[key] = fromExisting(map[key]);
    } else {
      map[key] = value;
    }
  }

  Map getMap(key) {
    return maps[key];
  }

  void recordFrequency(id, value, [example]) {
    Map<int, List> map = frequencyMaps.putIfAbsent(id, () => {});
    map.putIfAbsent(value, () => []);
    map[value].add(example);
  }

  void recordFrequencies(id, Map<dynamic, Iterable> frequencyMap) {
    Map<int, List> map = frequencyMaps.putIfAbsent(id, () => {});
    frequencyMap.forEach((value, examples) {
      map.putIfAbsent(value, () => []);
      map[value].addAll(examples);
    });
  }

  Iterable recordedFrequencies(id, value) {
    Map<dynamic, List> map = frequencyMaps[id];
    if (map == null) return const [];
    List list = map[value];
    if (list == null) return const [];
    return list;
  }

  void recordCounter(id, [reason, example]) {
    Map<dynamic, List> map = countersMap.putIfAbsent(id, () => {});
    map.putIfAbsent(reason, () => []).add(example);
  }

  void recordElement(key, element, {data}) {
    setsMap.putIfAbsent(key, () => new Map())[element] = data;
  }

  Iterable getList(String key) {
    Map map = setsMap[key];
    if (map == null) return const [];
    return map.keys;
  }

  void dumpStats({void beforeClose()}) {
    printer.start('stats');
    dumpFrequencies();
    dumpSets();
    dumpCounters();
    if (beforeClose != null) {
      beforeClose();
    }
    printer.end('stats');
  }

  void dumpSets() {
    printer.group('sets', () {
      setsMap.forEach((k, set) {
        dumpIterable('examples', '$k', set.keys,
            limit: printer.examples, dataMap: set);
      });
    });

  }

  void dumpFrequencies() {
    printer.group('frequencies', () {
      frequencyMaps.forEach((key, Map<dynamic, List> map) {
        printer.child('frequency', {'title': '$key'}, () {
          dumpFrequency(map);
        });
      });
    });
  }

  void dumpFrequency(Map<dynamic, Iterable> map) {
    Map sortedMap = trySortMap(map);
    sortedMap.forEach((k, list) {
      dumpIterable('examples', '$k', list, limit: printer.examples);
    });
  }

  void dumpCounters() {
    printer.group('counters', () {
      countersMap.keys.forEach(dumpCounter);
    });
  }

  void dumpCounter(id) {
    Map<dynamic, List> map = countersMap[id];
    bool hasData(example) {
      if (map == null) return false;
      List list = map[example];
      if (list == null) return false;
      return list.any((data) => data != null);
    }

    int count = 0;
    Map<dynamic, int> frequencyMap = {};
    map.forEach((var category, List examples) {
      if (category != null) {
        frequencyMap.putIfAbsent(category, () => 0);
        frequencyMap[category] += examples.length;
      }
      count += examples.length;
    });
    Map<int, Set> result = sortMap(inverseMap(frequencyMap), (a, b) => b - a);
    int examplesLimit = null;
    if (printer.examples != null && result.length >= printer.examples) {
      examplesLimit = 0;
    }
    int counter = 0;
    bool hasMore = false;
    printer.open('counter', {'title': '$id', 'count': count});
    result.forEach((int count, Set examples) {
      if (counter == printer.examples) {
        printer.beginExtra();
        hasMore = true;
      }
      if (examples.length == 1 &&
          (examplesLimit == 0 || !hasData(examples.first))) {
        printer.child('examples', {'count': count, 'example': examples.first});
      } else {
        printer.child('examples',
            {'count': count, 'examples': examples.length},
            () {
          examples.forEach((example) {
            dumpIterable(
                'examples', '$example', map[example],
                limit: examplesLimit,
                includeCount: false);
          });
        });
      }
      counter++;
    });
    if (hasMore) {
      printer.endExtra();
    }
    printer.close('counter');
  }

  void dumpCorrelation(keyA, Iterable a, keyB, Iterable b,
                       {Map dataA, Map dataB}) {
    printer.child('correlations', {'title': '$keyA vs $keyB'}, () {
      List aAndB = a.where((e) => e != null && b.contains(e)).toList();
      List aAndNotB = a.where((e) => e != null && !b.contains(e)).toList();
      List notAandB = b.where((e) => e != null && !a.contains(e)).toList();
      dumpIterable('correlation', '$keyA && $keyB', aAndB, dataMap: dataA,
          limit: printer.examples);
      dumpIterable('correlation', '$keyA && !$keyB', aAndNotB, dataMap: dataA,
          limit: printer.examples);
      dumpIterable('correlation', '!$keyA && $keyB', notAandB, dataMap: dataB,
          limit: printer.examples);
    });
  }

  void dumpIterable(String tag, String title, Iterable iterable,
                    {int limit, Map dataMap, bool includeCount: true}) {
    if (limit == 0) return;

    Map childData = {};
    Iterable nonNullIterable = iterable.where((e) => e != null);
    if (nonNullIterable.isEmpty && !includeCount) {
      childData['name'] = title;
    } else {
      childData['title'] = title;
    }
    if (includeCount) {
      childData['count'] = iterable.length;
    }
    printer.child(tag, childData, () {
      bool hasMore = false;
      int counter = 0;
      nonNullIterable.forEach((element) {
        if (counter == limit) {
          printer.beginExtra();
          hasMore = true;
        }
        var data = dataMap != null ? dataMap[element] : null;
        if (data != null) {
          printer.child('example', {'value': element, 'data': data});
        } else {
          printer.child('example', {'value': element});
        }
        counter++;
      });
      if (hasMore) {
        printer.endExtra();
      }
    });
  }
}

/// Returns a map that is an inversion of [map], where the keys are the values
/// of [map] and the values are the set of keys in [map] that share values.
///
/// If [equals] and [hashCode] are provided, these are used to determine
/// equality among the values of [map].
///
/// If [isValidKey] is provided, this is used to determine with a value of [map]
/// is a potential key of the inversion map.
Map<dynamic, Set> inverseMap(Map map,
                             {bool equals(key1, key2),
                              int hashCode(key),
                              bool isValidKey(potentialKey)}) {
  Map<dynamic, Set> result = new LinkedHashMap<dynamic, Set>(
      equals: equals, hashCode: hashCode, isValidKey: isValidKey);
  map.forEach((k, v) {
    if (isValidKey == null || isValidKey(v)) {
      result.putIfAbsent(v, () => new Set()).add(k);
    }
  });
  return result;
}

/// Return a new map heuristically sorted by the keys of [map]. If the first
/// key of [map] is [Comparable], the keys are sorted using [sortMap] under
/// the assumption that all keys are [Comparable].
/// Otherwise, the keys are sorted as string using their `toString`
/// representation.
Map trySortMap(Map map) {
  Iterable iterable = map.keys.where((k) => k != null);
  if (iterable.isEmpty) return map;
  var key = iterable.first;
  if (key is Comparable) {
    return sortMap(map);
  }
  return sortMap(map, (a, b) => '$a'.compareTo('$b'));
}

/// Returns a new map in which the keys of [map] are sorted using [compare].
/// If [compare] is null, the keys must be [Comparable].
Map sortMap(Map map, [int compare(a,b)]) {
  List keys = map.keys.toList();
  keys.sort(compare);
  Map sortedMap = new Map();
  keys.forEach((k) => sortedMap[k] = map[k]);
  return sortedMap;
}

