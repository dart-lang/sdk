// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

const String _augmentedNamePrefix = '_#';
const String _augmentedNameSuffix = '#augment';

/// Creates the synthesized name to use for the [index]th augmented
/// member by the given [name] in [library].
///
/// The index refers to the augmentation layer. For instance if we have
///
///     // 'origin.dart':
///     import augment 'augment1.dart';
///     import augment 'augment2.dart';
///     void method() {} // Index 0.
///
///     // 'augment1.dart':
///     augment void method() { // Index 1.
///       augment super(); // Calling index 0.
///     }
///
///     // 'augment2.dart':
///     augment void method() { // Not indexed.
///       augment super(); // Calling index 1.
///     }
///
/// the declaration from 'origin.dart' has index 0 and is generated with the
/// name '_#method#augment0, the declaration from 'augment1.dart' has index 1
/// and is generated with the name '_#method#augment1', and the declaration from
/// 'augment2.dart' has no index but is generated using the declared name
/// 'method' because it serves as the entry point for all external access to
/// the method body.
Name augmentedName(String name, Library library, int index) {
  return new Name(
      '$_augmentedNamePrefix'
      '${name.isEmpty ? 'new' : name}'
      '$_augmentedNameSuffix'
      '$index',
      library);
}
