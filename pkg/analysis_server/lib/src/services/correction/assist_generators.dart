// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analysis_server_plugin/src/correction/fix_generators.dart';

final registeredAssistGenerators = _RegisteredAssistGenerators();

/// The collection of various registered [ProducerGenerator]s and
/// [MultiProducerGenerator]s, accessed through [registeredFixGenerators].
class _RegisteredAssistGenerators {
  /// A list of the generators used to produce [CorrectionProducer]s for
  /// assists.
  final Set<ProducerGenerator> producerGenerators = {};

  /// A list of the multi-generators used to produce [CorrectionProducer]s for
  /// assists.
  final Set<MultiProducerGenerator> multiProducerGenerators = {};

  void registerGenerator(ProducerGenerator generator) {
    producerGenerators.add(generator);
  }

  void registerMultiGenerator(MultiProducerGenerator generator) {
    multiProducerGenerators.add(generator);
  }
}
