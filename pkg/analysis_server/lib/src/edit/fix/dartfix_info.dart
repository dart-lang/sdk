// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart' show DartFix;
import 'package:analysis_server/src/edit/edit_dartfix.dart';
import 'package:analysis_server/src/edit/fix/dartfix_listener.dart';
import 'package:analysis_server/src/edit/fix/dartfix_registrar.dart';
import 'package:analysis_server/src/edit/fix/fix_error_task.dart';
import 'package:analysis_server/src/edit/fix/non_nullable_fix.dart';
import 'package:analysis_server/src/edit/fix/prefer_int_literals_fix.dart';
import 'package:analysis_server/src/edit/fix/prefer_mixin_fix.dart';
import 'package:analysis_server/src/edit/fix/prefer_spread_collections_fix.dart';

const allFixes = <DartFixInfo>[
  //
  // Required fixes
  //
  const DartFixInfo(
    'fix-named-constructor-type-arguments',
    'Move named constructor type arguments from the name to the type.',
    FixErrorTask.fixNamedConstructorTypeArgs,
    isRequired: true,
  ),
  const DartFixInfo(
    'use-mixin',
    'Convert classes used as a mixin to the new mixin syntax.',
    PreferMixinFix.task,
    isRequired: true,
  ),
  //
  // Suggested fixes
  //
  const DartFixInfo(
    'double-to-int',
    'Find double literals ending in .0 and remove the .0\n'
    'wherever double context can be inferred.',
    PreferIntLiteralsFix.task,
  ),
  //
  // Experimental fixes
  //
  const DartFixInfo(
    'non-nullable',
    // TODO(danrubel) update description and make default/required
    // when NNBD fix is ready
    'Experimental: Update sources to be non-nullable by default.\n'
    'Requires the experimental non-nullable flag to be enabled.\n'
    'This is not applied unless explicitly included.',
    NonNullableFix.task,
    isDefault: false,
  ),
  const DartFixInfo(
    'use-spread-collections',
    'Convert to using collection spread operators.',
    PreferSpreadCollectionsFix.task,
    isDefault: false,
  ),
];

/// [DartFixInfo] represents a fix that can be applied by [EditDartFix].
class DartFixInfo {
  final String key;
  final String description;
  final bool isDefault;
  final bool isRequired;
  final void Function(DartFixRegistrar dartfix, DartFixListener listener) setup;

  const DartFixInfo(this.key, this.description, this.setup,
      {this.isDefault = true, this.isRequired = false});

  DartFix asDartFix() =>
      new DartFix(key, description: description, isRequired: isRequired);
}
