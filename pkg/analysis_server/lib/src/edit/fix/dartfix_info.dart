// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart' show DartFix;
import 'package:analysis_server/src/edit/edit_dartfix.dart';

const allFixes = <DartFixInfo>[
  //
  // Required fixes
  //
  const DartFixInfo(
    fixNamedConstructorTypeArgs,
    'Move named constructor type arguments from the name to the type.',
    isRequired: true,
  ),
  const DartFixInfo(
    useMixin,
    'Convert classes used as a mixin to the new mixin syntax.',
    isRequired: true,
  ),
  //
  // Suggested fixes
  //
  const DartFixInfo(
    doubleToInt,
    'Find double literals ending in .0 and remove the .0\n'
        'wherever double context can be inferred.',
  ),
  //
  // Expermimental fixes
  //
  const DartFixInfo(
    nonNullable,
    // TODO(danrubel) update description and make default/required
    // when NNBD fix is ready
    'Experimental: Update sources to be non-nullable by default.\n'
        'Requires the experimental non-nullable flag to be enabled.\n'
        'This is not applied unless explicitly included.',
    isDefault: false,
  ),
];

/// [DartFixInfo] represents a fix that can be applied by [EditDartFix].
class DartFixInfo {
  final String key;
  final String description;
  final bool isDefault;
  final bool isRequired;

  const DartFixInfo(this.key, this.description,
      {this.isDefault = true, this.isRequired = false});

  String setup(EditDartFix dartfix) {
    // TODO(danrubel): return DartFixTask rather than String
    return key;
  }

  DartFix asDartFix() =>
      new DartFix(key, description: description, isRequired: isRequired);
}
