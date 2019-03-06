// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/summary2/reference.dart';

/// A declaration in a scope.
///
/// A declaration can be associated with a named node and have [reference] set;
/// or can be an import prefix, then the [reference] is `null`.
class Declaration {
  final String name;
  final Reference reference;

  Declaration(this.name, this.reference);
}
