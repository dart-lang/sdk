// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(39733): This file exists now just to register the use of
// 'boolConversionCheck'. Fix the registration and remove this file.

import '../common_elements.dart';
import '../universe/call_structure.dart' show CallStructure;
import '../universe/use.dart' show StaticUse;

class CheckedModeHelper {
  final String name;

  const CheckedModeHelper(String this.name);

  StaticUse getStaticUse(CommonElements commonElements) {
    // TODO(johnniwinther): Refactor this to avoid looking up directly in the
    // js helper library but instead access commonElements.
    return new StaticUse.staticInvoke(
        commonElements.findHelperFunction(name), callStructure);
  }

  CallStructure get callStructure => CallStructure.ONE_ARG;
}

class CheckedModeHelpers {
  CheckedModeHelpers();

  /// All the checked mode helpers.
  static const List<CheckedModeHelper> helpers = const <CheckedModeHelper>[
    const CheckedModeHelper('boolConversionCheck'),
  ];
}
