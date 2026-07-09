// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:js_interop';

import 'inheritance_collision_lib.dart';

void main() {
  createJSInteropWrapper(InheritanceOneOverrideNoCollision());
  createJSInteropWrapper(InheritanceTwoOverridesNoCollision());
  createJSInteropWrapper(InheritanceThreeOverridesNoCollision());

  createJSInteropWrapper(InheritanceRenameOneCollision());
  createJSInteropWrapper(InheritanceRenameTwoCollisions());
  createJSInteropWrapper(InheritanceRenameThreeCollisions());

  createJSInteropWrapper(InheritanceNoSuperclassMembers());

  createJSInteropWrapper(PartialOverrideFieldNoCollision());
  createJSInteropWrapper(GetSetInheritanceNoCollision());
}
