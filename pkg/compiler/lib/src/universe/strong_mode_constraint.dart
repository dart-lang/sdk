// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(48820): delete this class once migration is complete.
abstract class StrongModeConstraintInterface {
  bool get isThis;
  bool get isExact;
  String get className;
}
