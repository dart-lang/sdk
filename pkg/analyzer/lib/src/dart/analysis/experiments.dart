// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/generated/engine.dart';

/// A representation of the set of experiments that are active and whether they
/// are enabled.
class Experiments {
  /// The name of the experiment to extend which expressions are constant
  /// expressions.
  static const String constantUpdate2018Name = 'constant-update-2018';

  /// The name of the experiment to support set literals.
  static const String setLiteralName = 'set-literal';

  /// A list containing the names of active experiments.
  static const List<String> activeExperimentNames = <String>[
    constantUpdate2018Name,
    setLiteralName,
  ];

  /// A list containing the names of the experiments that have been enabled.
  final List<String> _enabled;

  /// Initialize a newly created set of experiments from the given set of
  /// analysis [options].
  Experiments(AnalysisOptions options) : _enabled = options.enabledExperiments;

  /// Return `true` if the experiment named 'constant-update-2018' has been
  /// enabled.
  bool get constantUpdate2018 => _enabled.contains(constantUpdate2018Name);

  /// Return `true` if the experiment named 'set-literal' has been enabled.
  bool get setLiteral => _enabled.contains(setLiteralName);
}
