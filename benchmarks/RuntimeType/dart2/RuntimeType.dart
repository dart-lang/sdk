// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Benchmark for runtimeType patterns as used in Flutter.

// ignore_for_file: prefer_const_constructors
// ignore_for_file: avoid_function_literals_in_foreach_calls

// @dart=2.9

import 'dart:typed_data';

import 'package:benchmark_harness/benchmark_harness.dart';

abstract class Key {
  const factory Key(String value) = ValueKey<String>;
  const Key.empty();
}

abstract class LocalKey extends Key {
  const LocalKey() : super.empty();
}

class ValueKey<T> extends LocalKey {
  const ValueKey(this.value);
  final T value;
  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is ValueKey<T> && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;
}

abstract class Widget {
  const Widget({this.key});
  final Key key;

  @pragma('dart2js:noInline')
  static bool canUpdate(Widget oldWidget, Widget newWidget) {
    return oldWidget.runtimeType == newWidget.runtimeType &&
        oldWidget.key == newWidget.key;
  }
}

class AWidget extends Widget {
  const AWidget({Key key}) : super(key: key);
}

class BWidget extends Widget {
  const BWidget({Key key}) : super(key: key);
}

class CWidget extends Widget {
  const CWidget({Key key}) : super(key: key);
}

class DWidget extends Widget {
  const DWidget({Key key}) : super(key: key);
}

class EWidget extends Widget {
  const EWidget({Key key}) : super(key: key);
}

class FWidget extends Widget {
  const FWidget({Key key}) : super(key: key);
}

class WWidget<W extends Widget> extends Widget {
  final W /*?*/ ref;
  const WWidget({this.ref, Key key}) : super(key: key);
}

class WidgetCanUpdateBenchmark extends BenchmarkBase {
  WidgetCanUpdateBenchmark() : super('RuntimeType.Widget.canUpdate.byType');

  // All widgets have different types.
  static List<Widget> _widgets() => [
        AWidget(),
        BWidget(),
        CWidget(),
        DWidget(),
        EWidget(),
        FWidget(),
        WWidget<AWidget>(),
        WWidget<BWidget>(ref: const BWidget()),
        WWidget<CWidget>(ref: CWidget()),
        const WWidget<DWidget>(ref: DWidget()),
      ];
  // Bulk up list to reduce loop overheads.
  final List<Widget> widgets = _widgets() + _widgets() + _widgets();

  @override
  void exercise() => run();

  @override
  void run() {
    for (var w1 in widgets) {
      for (var w2 in widgets) {
        if (Widget.canUpdate(w1, w2) != Widget.canUpdate(w2, w1)) {
          throw 'Hmm $w1 $w2';
        }
      }
    }
  }

  // Normalize by number of calls to [Widgets.canUpdate].
  @override
  double measure() => super.measure() / (widgets.length * widgets.length * 2);
}

class ValueKeyEqualBenchmark extends BenchmarkBase {
  ValueKeyEqualBenchmark() : super('RuntimeType.Widget.canUpdate.byKey');

  // All widgets the same class but distinguished on keys.
  static List<Widget> _widgets() => [
        AWidget(),
        AWidget(key: ValueKey(1)),
        AWidget(key: ValueKey(1)),
        AWidget(key: ValueKey(2)),
        AWidget(key: ValueKey(2)),
        AWidget(key: ValueKey(3)),
        AWidget(key: ValueKey('one')),
        AWidget(key: ValueKey('two')),
        AWidget(key: ValueKey('three')),
        AWidget(key: ValueKey(Duration(seconds: 5))),
      ];
  // Bulk up list to reduce loop overheads.
  final List<Widget> widgets = _widgets() + _widgets() + _widgets();

  @override
  void exercise() => run();

  @override
  void run() {
    for (var w1 in widgets) {
      for (var w2 in widgets) {
        if (Widget.canUpdate(w1, w2) != Widget.canUpdate(w2, w1)) {
          throw 'Hmm $w1 $w2';
        }
      }
    }
  }

  // Normalize by number of calls to [Widgets.canUpdate].
  @override
  double measure() => super.measure() / (widgets.length * widgets.length * 2);
}

void pollute() {
  // Various bits of code to make environment less unrealistic.
  void check(dynamic a, dynamic b) {
    if (a.runtimeType != b.runtimeType) throw 'mismatch $a $b';
  }

  check(Uint8List(1), Uint8List(2)); // dart2js needs native interceptors.
  check(Int16List(1), Int16List(2));
  check([], []);
  check(<bool>{}, <bool>{});
}

void main() {
  pollute();

  final benchmarks = [
    WidgetCanUpdateBenchmark(),
    ValueKeyEqualBenchmark(),
  ];

  // Warm up all benchmarks before running any.
  benchmarks.forEach((bm) => bm.run());

  benchmarks.forEach((bm) => bm.report());
}
