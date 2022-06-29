// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

const String _augmentedNamePrefix = '_#';
const String _augmentedNameSuffix = '#augment';

/// Creates the synthesized name to use for the [index]th augmented member by
/// the given [name] in [library].
Name augmentedName(String name, Library library, int index) {
  return new Name(
      '$_augmentedNamePrefix'
      '${name.isEmpty ? 'new' : name}'
      '$_augmentedNameSuffix'
      '$index',
      library);
}
