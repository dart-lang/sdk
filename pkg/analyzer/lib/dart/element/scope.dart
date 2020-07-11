// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:meta/meta.dart';

/// Scopes are used to resolve names to elements.
abstract class Scope {
  /// Return the element with the name `id` or `id=` (if [setter] is `true`),
  /// `null` if the name is not defined within this scope.
  Element lookup({@required String id, @required bool setter});
}
