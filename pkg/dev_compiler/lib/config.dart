// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Configuration of DDC rule set.
library ddc.config;

// Options shared by the compiler and runtime.
class TypeOptions {
  static const NONNULLABLE_TYPES = const <String>['int', 'double'];
  final List<String> nonnullableTypes;

  TypeOptions({this.nonnullableTypes: NONNULLABLE_TYPES});
}

List<String> optionsToList(String option,
    {List<String> defaultValue: const <String>[]}) {
  if (option == null) {
    return defaultValue;
  } else if (option.isEmpty) {
    return <String>[];
  } else {
    return option.split(',');
  }
}
