// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart' show DartFix;
import 'package:analysis_server/src/edit/edit_dartfix.dart';
import 'package:analysis_server/src/edit/fix/dartfix_listener.dart';
import 'package:analysis_server/src/edit/fix/dartfix_registrar.dart';
import 'package:analysis_server/src/edit/fix/fix_error_task.dart';

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
    useMixin,
    'Convert classes used as a mixin to the new mixin syntax.',
    DartFixInfo.useMixinSetup,
    isRequired: true,
  ),
  //
  // Suggested fixes
  //
  const DartFixInfo(
    doubleToInt,
    'Find double literals ending in .0 and remove the .0\n'
        'wherever double context can be inferred.',
    DartFixInfo.doubleToIntSetup,
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
    DartFixInfo.nonNullableSetup,
    isDefault: false,
  ),
];

/// [DartFixInfo] represents a fix that can be applied by [EditDartFix].
class DartFixInfo {
  // TODO(danrubel): replace these setup method with ones that register tasks
  static String doubleToIntSetup(
          DartFixRegistrar reg, DartFixListener listener) =>
      doubleToInt;
  static String nonNullableSetup(
          DartFixRegistrar reg, DartFixListener listener) =>
      nonNullable;
  static String useMixinSetup(DartFixRegistrar reg, DartFixListener listener) =>
      useMixin;

  final String key;
  final String description;
  final bool isDefault;
  final bool isRequired;
  // TODO(danrubel): make the return value void
  final String Function(DartFixRegistrar dartfix, DartFixListener listener)
      setup;

  const DartFixInfo(this.key, this.description, this.setup,
      {this.isDefault = true, this.isRequired = false});

  DartFix asDartFix() =>
      new DartFix(key, description: description, isRequired: isRequired);
}
