// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix_generators.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';

/// Prints lints that are bulk-fixable in a format that can be included in
/// analysis options.
void main() {
  var bulkFixCodes = registeredFixGenerators.lintProducers.entries
      .where((e) => e.value
          .where((generator) =>
              generator(context: StubCorrectionProducerContext.instance)
                  .canBeAppliedAcrossFiles)
          .isNotEmpty)
      .map((e) => e.key);
  print('    # bulk-fixable lints');
  for (var lintName in bulkFixCodes) {
    print('    - $lintName');
  }
}
