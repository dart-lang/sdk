// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol_generated.dart' show DartFix;
import 'package:analysis_server/src/edit/edit_dartfix.dart';
import 'package:analysis_server/src/edit/fix/dartfix_listener.dart';
import 'package:analysis_server/src/edit/fix/dartfix_registrar.dart';
import 'package:analysis_server/src/edit/fix/fix_error_task.dart';
import 'package:analysis_server/src/edit/fix/non_nullable_fix.dart';
import 'package:analysis_server/src/edit/fix/prefer_mixin_fix.dart';
import 'package:analysis_server/src/edit/fix/basic_fix_lint_assist_task.dart';
import 'package:analysis_server/src/edit/fix/basic_fix_lint_error_task.dart';

const allFixes = <DartFixInfo>[
  //
  // Required fixes due to errors or upcoming language changes
  //
  const DartFixInfo(
    'fix-named-constructor-type-arguments',
    '''
Move named constructor type arguments from the name to the type.

For example, this
  new List.filled<String>(20, 'value');

will be converted to
  new List<String>.filled(20, 'value');''',
    FixErrorTask.fixNamedConstructorTypeArgs,
    isRequired: true,
  ),
  const DartFixInfo(
    'use-mixin',
    '''
Convert classes used as a mixin to the new mixin syntax.

For example, this
  class C with M { }
  class M { }

will be converted to
  class C with M { }
  mixin M { }

There are several situations where a class cannot be automatically converted
to a mixin such as when the class contains a constructor. In that situation
a message is displayed and the class is not converted to a mixin.''',
    PreferMixinFix.task,
    isRequired: true,
  ),
  //
  // Fixes enabled by default
  //
  const DartFixInfo(
    'double-to-int',
    '''
Find double literals ending in .0 and remove the .0
wherever double context can be inferred.

For example, this
  const double myDouble = 8.0;

will be converted to
  const double myDouble = 8;''',
    BasicFixLintAssistTask.preferIntLiterals,
  ),
  const DartFixInfo(
    'prefer-equal-for-default-values',
    '''
Convert declarations to use = to separate a named parameter from its default value.

For example, this
  f({a: 1}) { }

will be converted to
  f({a = 1}) { }''',
    BasicFixLintErrorTask.preferEqualForDefaultValues,
  ),
  const DartFixInfo(
    'prefer-is-empty',
    '''
Convert to using 'isEmpty' when checking if a collection or iterable is empty.

For example, this
  if (lunchBox.length == 0) return 'so hungry...';

will be converted to
  if (lunchBox.isEmpty) return 'so hungry...';''',
    BasicFixLintErrorTask.preferIsEmpty,
    isDefault: false,
  ),
  const DartFixInfo(
    'prefer-is-not-empty',
    '''
Convert to using 'isNotEmpty' when checking if a collection or iterable is not empty.

For example, this
  if (words.length != 0) return words.join(' ');

will be converted to
  if (words.isNotEmpty) return words.join(' ');''',
    BasicFixLintErrorTask.preferIsNotEmpty,
    isDefault: false,
  ),
  //
  // Fixes that may be explicitly enabled
  //
  const DartFixInfo(
    'use-spread-collections',
    '''
Convert to using collection spread operators.

For example, this
  var l1 = ['b'];
  var l2 = ['a']..addAll(l1);

will be converted to
  var l1 = ['b'];
  var l2 = ['a', ...l1];''',
    BasicFixLintAssistTask.preferSpreadCollections,
    isDefault: false,
  ),
  const DartFixInfo(
    'collection-if-elements',
    '''
Convert to using if elements when building collections.

For example, this
  f(bool b) => ['a', b ? 'c' : 'd', 'e'];

will be converted to
  f(bool b) => ['a', if (b) 'c' else 'd', 'e'];''',
    BasicFixLintAssistTask.preferIfElementsToConditionalExpressions,
    isDefault: false,
  ),
  const DartFixInfo(
    'map-for-elements',
    '''
Convert to for elements when building maps from iterables.

For example, this
  Map<int, int>.fromIterable([1, 2, 3], key: (i) => i, value: (i) => i * 2)

will be converted to
  <int, int>{ for(int i in [1, 2, 3]) i : i * 2, }''',
    BasicFixLintAssistTask.preferForElementsToMapFromIterable,
    isDefault: false,
  ),
  //
  // Experimental fixes
  //
  const DartFixInfo(
    'non-nullable',
    // TODO(danrubel) update description and make default/required
    // when NNBD fix is ready
    '''
EXPERIMENTAL: Update sources to be non-nullable by default.
This requires the experimental non-nullable flag to be enabled
when running the updated application.''',
    NonNullableFix.task,
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
