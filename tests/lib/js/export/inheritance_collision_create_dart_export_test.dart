// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:js/js_util.dart';

import 'inheritance_collision_lib.dart';

void main() {
  createDartExport(InheritanceOneOverrideNoCollision());
  createDartExport(InheritanceTwoOverridesNoCollision());
  createDartExport(InheritanceThreeOverridesNoCollision());

  createDartExport(InheritanceRenameOneCollision());
  createDartExport(InheritanceRenameTwoCollisions());
  createDartExport(InheritanceRenameThreeCollisions());

  createDartExport(InheritanceNoSuperclassMembers());

  createDartExport(PartialOverrideFieldNoCollision());
  createDartExport(GetSetInheritanceNoCollision());
}
