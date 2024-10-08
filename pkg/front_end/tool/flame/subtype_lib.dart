// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/src/types.dart';
import '../../test/simple_stats.dart';

bool _collect = true;
int _recursionLevel = 0;
Stopwatch _stopWatch = new Stopwatch();
List<_SubtypeRelation> _subtypeRelations = [];

class _SubtypeRelation {
  final Types types;
  final DartType subtype;
  final DartType supertype;

  _SubtypeRelation(this.types, this.subtype, this.supertype);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _SubtypeRelation &&
          runtimeType == other.runtimeType &&
          types == other.types &&
          subtype == other.subtype &&
          supertype == other.supertype;

  @override
  int get hashCode {
    return Object.hash(types, subtype, supertype);
  }

  @override
  String toString() => '${types.runtimeType}: '
      '${subtype.toStringInternal()} <: ${supertype.toStringInternal()}';
}

void before() {
  _collect = true;
  _recursionLevel = 0;
  _subtypeRelations = [];
  _stopWatch.reset();
}

void enter(Types types, DartType subtype, DartType supertype) {
  if (_collect) {
    if (_recursionLevel++ == 0) {
      _SubtypeRelation relation =
          new _SubtypeRelation(types, subtype, supertype);
      _subtypeRelations.add(relation);
      _stopWatch.start();
    }
  }
}

void exit() {
  if (_collect) {
    if (--_recursionLevel == 0) {
      _stopWatch.stop();
    }
  }
}

void after() {
  _collect = false;
  int identicalTypes = 0;
  int sameTypes = 0;
  int sum = _subtypeRelations.length;
  Map<_SubtypeRelation, int> _subtypeRelationCount = {};
  for (_SubtypeRelation relation in _subtypeRelations) {
    if (identical(relation.subtype, relation.supertype)) {
      identicalTypes++;
    }
    if (relation.subtype == relation.supertype) {
      sameTypes++;
    }
    _subtypeRelationCount[relation] =
        (_subtypeRelationCount[relation] ?? 0) + 1;
  }

  var list = _subtypeRelationCount.entries.toList()
    ..sort((a, b) => -a.value.compareTo(b.value));
  int? lastCount;
  print('-----');
  for (var e in list) {
    if (e.value > 1) {
      if (e.value != lastCount) {
        print('${e.value}:');
        print(' ${e.key}');
      }
      lastCount = e.value;
    }
  }
  print('-----');
  print('identical types: $identicalTypes');
  print('same types     : $sameTypes');
  print('total checks   : $sum');
  print('time           : ${_stopWatch.elapsedMilliseconds}ms');
  print('-----');
  int count = 20;
  List<int> narrowTiming = [];
  for (int j = 0; j < count; j++) {
    Stopwatch narrow = new Stopwatch();
    for (_SubtypeRelation relation in _subtypeRelations) {
      Types types = relation.types;
      DartType s = relation.subtype;
      DartType t = relation.supertype;
      narrow.start();
      types.performNullabilityAwareSubtypeCheck(s, t);
      narrow.stop();
    }
    narrowTiming.add(narrow.elapsedMicroseconds);
  }
  print('---narrow---');
  print('average: ${SimpleTTestStat.average(narrowTiming)}, '
      'variance: ${SimpleTTestStat.variance(narrowTiming)}');
  print('------------');
  narrowTiming.forEach(print);

  List<int> loopTiming = [];
  for (int j = 0; j < count; j++) {
    Stopwatch loop = new Stopwatch();
    loop.start();
    for (_SubtypeRelation relation in _subtypeRelations) {
      Types types = relation.types;
      DartType s = relation.subtype;
      DartType t = relation.supertype;
      types.performNullabilityAwareSubtypeCheck(s, t);
    }
    loop.stop();
    loopTiming.add(loop.elapsedMicroseconds);
  }
  print('----loop----');
  print('average: ${SimpleTTestStat.average(loopTiming)}, '
      'variance: ${SimpleTTestStat.variance(loopTiming)}');
  print('------------');
  loopTiming.forEach(print);

  List<int> loopOnlyTiming = [];
  for (int j = 0; j < count; j++) {
    Stopwatch loopOnly = new Stopwatch();
    loopOnly.start();
    for (_SubtypeRelation relation in _subtypeRelations) {
      // ignore: unused_local_variable
      Types types = relation.types;
      // ignore: unused_local_variable
      DartType s = relation.subtype;
      // ignore: unused_local_variable
      DartType t = relation.supertype;
    }
    loopOnly.stop();
    loopOnlyTiming.add(loopOnly.elapsedMicroseconds);
  }
  print('--loop-only--');
  print('average: ${SimpleTTestStat.average(loopOnlyTiming)}, '
      'variance: ${SimpleTTestStat.variance(loopOnlyTiming)}');
  print('-------------');
  loopOnlyTiming.forEach(print);
}
