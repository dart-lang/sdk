// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/error/error.dart';

final registeredFixGenerators = _RegisteredFixGenerators();

/// A function that can be executed to create a [MultiCorrectionProducer].
typedef MultiProducerGenerator = MultiCorrectionProducer Function(
    {required CorrectionProducerContext context});

/// A function that can be executed to create a [CorrectionProducer].
typedef ProducerGenerator = CorrectionProducer<ParsedUnitResult> Function(
    {required CorrectionProducerContext context});

/// The collection of various registered [ProducerGenerator]s and
/// [MultiProducerGenerator]s, accessed through [registeredFixGenerators].
class _RegisteredFixGenerators {
  /// A map from lint codes to a list of the generators that are used to create
  /// [CorrectionProducer]s.
  ///
  /// The generators are then used to build fixes for those diagnostics. The
  /// generators used for non-lint diagnostics are in the [nonLintProducers].
  final Map<LintCode, List<ProducerGenerator>> lintProducers = {};

  final Map<LintCode, List<MultiProducerGenerator>> lintMultiProducers = {};

  /// A map from error codes to a list of generators used to create multiple
  /// correction producers used to build fixes for those diagnostics.
  ///
  /// The generators used for lint rules are in the [lintMultiProducers].
  final Map<ErrorCode, List<MultiProducerGenerator>> nonLintMultiProducers = {};

  /// A set of generators that are used to create correction producers that
  /// produce corrections that ignore diagnostics locally.
  final Set<ProducerGenerator> ignoreProducerGenerators = {};

  /// A map from error codes to a list of the generators that are used to create
  /// correction producers.
  ///
  /// The generators are then used to build fixes for those diagnostics. The
  /// generators used for lint rules are in the [lintProducers].
  final Map<ErrorCode, List<ProducerGenerator>> nonLintProducers = {};

  /// A map from lint codes to a list of fix generators that work with only
  /// parsed results.
  final Map<LintCode, List<ProducerGenerator>> parseLintProducers = {};

  /// Associates the given correction producer [generator] with the lint with
  /// the given [lintCode].
  void registerFixForLint(LintCode lintCode, ProducerGenerator generator) {
    lintProducers.putIfAbsent(lintCode, () => []).add(generator);
  }
}
