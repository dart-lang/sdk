// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'nodes.dart';
import '../util/features.dart';

/// Log used for unit testing optimizations.
class OptimizationLog {
  List<OptimizationLogEntry> entries = [];

  void registerFieldGet(HInvokeDynamicGetter node, HFieldGet fieldGet) {
    Features features = new Features();
    features['name'] =
        '${fieldGet.element.enclosingClass.name}.${fieldGet.element.name}';
    entries.add(new OptimizationLogEntry('FieldGet', features));
  }

  void registerFieldSet(HInvokeDynamicSetter node, HFieldSet fieldSet) {
    Features features = new Features();
    features['name'] =
        '${fieldSet.element.enclosingClass.name}.${fieldSet.element.name}';
    entries.add(new OptimizationLogEntry('FieldSet', features));
  }

  String getText() {
    return entries.join(',\n');
  }
}

/// A registered optimization.
class OptimizationLogEntry {
  /// String that uniquely identifies the optimization kind.
  final String tag;

  /// Additional data for this optimization.
  final Features features;

  OptimizationLogEntry(this.tag, this.features);

  String toString() => '$tag(${features.getText()})';
}
