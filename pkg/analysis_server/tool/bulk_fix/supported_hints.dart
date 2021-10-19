// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix_internal.dart';
import 'package:analyzer/error/error.dart';

import 'parse_utils.dart';

/// Print hint bulk-fix info.
Future<void> main() async {
  var overrideDetails = await BulkFixDetails().collectOverrides();

  print('hints w/ correction producers:\n');

  var hintEntries = FixProcessor.nonLintProducerMap.entries
      .where((e) => e.key.type == ErrorType.HINT);
  for (var hint in hintEntries) {
    var canBeAppliedInBulk = false;
    var missingExplanations = <String>[];
    for (var generator in hint.value) {
      var producer = generator();
      if (!producer.canBeAppliedInBulk) {
        var producerName = producer.runtimeType.toString();
        if (overrideDetails.containsKey(producerName)) {
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

    print('${hint.key} bulk fixable: $canBeAppliedInBulk');
    for (var producer in missingExplanations) {
      print('  => override explanation missing for: $producer');
    }
  }
}
