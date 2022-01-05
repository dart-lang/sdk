// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix_internal.dart';
import 'package:analyzer/error/error.dart';

import 'parse_utils.dart';

/// Print diagnostic bulk-fix info.
Future<void> main() async {
  var overrideDetails = await BulkFixDetails().collectOverrides();

  print('diagnostics w/ correction producers:\n');

  var hintEntries = FixProcessor.nonLintProducerMap.entries.where((e) =>
      e.key.type == ErrorType.HINT || e.key.type == ErrorType.STATIC_WARNING);

  var diagnostics = [
    ...hintEntries,
    ...FixProcessor.lintProducerMap.entries,
  ];
  for (var diagnostic in diagnostics) {
    var canBeAppliedInBulk = false;
    var missingExplanations = <String>[];
    var hasOverride = false;
    for (var generator in diagnostic.value) {
      var producer = generator();
      if (!producer.canBeAppliedInBulk) {
        var producerName = producer.runtimeType.toString();
        if (overrideDetails.containsKey(producerName)) {
          hasOverride = true;
          var override = overrideDetails[producerName];
          var hasComment = override!.hasComment;
          if (!hasComment) {
            missingExplanations.add(producerName);
          }
        }
      } else {
        canBeAppliedInBulk = true;
      }
    }

    print('${diagnostic.key} bulk fixable: $canBeAppliedInBulk');
    if (!canBeAppliedInBulk && !hasOverride) {
      print('  => override missing');
    }
    for (var producer in missingExplanations) {
      print('  => override explanation missing for: $producer');
    }
  }
}
