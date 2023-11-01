// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';

/// This class tracks the set of names already added in the completion list in
/// order to prevent suggesting elements that have been shadowed by local
/// declarations.
class VisibilityTracker {
  /// The set of known previously declared names.
  final Set<String> declaredNames = {};

  /// Before completions are added by the helper, we verify with this method
  /// whether the name of the element has already been added, in order to
  /// prevent suggesting elements that are shadowed.
  bool isVisible(Element? element) {
    var name = element?.name;
    return name != null && declaredNames.add(name);
  }
}
