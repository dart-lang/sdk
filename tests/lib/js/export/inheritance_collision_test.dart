// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests collisions of `@JSExport` members using inheritance.

import 'dart:js_interop';

import 'package:js/js_util.dart';

// Overridden members do not count as an export name collision.
@JSExport()
class SuperclassNoCollision {
  int field = throw '';
  final int finalField = throw '';
  int get getSet => throw '';
  set getSet(int val) => throw '';
  void method() => throw '';
}

@JSExport()
mixin MixinNoCollision {
  int field = throw '';
  final int finalField = throw '';
  int get getSet => throw '';
  set getSet(int val) => throw '';
  void method() => throw '';
}

@JSExport()
mixin MixinNoCollision2 {
  int field = throw '';
  final int finalField = throw '';
  int get getSet => throw '';
  set getSet(int val) => throw '';
  void method() => throw '';
}

@JSExport()
class InheritanceOneOverrideNoCollision extends SuperclassNoCollision
    with MixinNoCollision {}

@JSExport()
class InheritanceTwoOverridesNoCollision extends SuperclassNoCollision
    with MixinNoCollision, MixinNoCollision2 {}

@JSExport()
class InheritanceThreeOverridesNoCollision extends SuperclassNoCollision
    with MixinNoCollision, MixinNoCollision2 {
  int field = throw '';
  final int finalField = throw '';
  int get getSet => throw '';
  set getSet(int val) => throw '';
  void method() => throw '';
}

// Export name collisions can exist across classes and mixin applications.
@JSExport()
class SuperclassCollision {
  @JSExport('field')
  int fieldSuper = throw '';
  @JSExport('finalField')
  final int finalFieldSuper = throw '';
  @JSExport('getSet')
  int get getSetSuper => throw '';
  @JSExport('getSet')
  set getSetSuper(int val) => throw '';
  @JSExport('method')
  void methodSuper() => throw '';
}

@JSExport()
mixin MixinCollision {
  @JSExport('field')
  int fieldMixin = throw '';
  @JSExport('finalField')
  final int finalFieldMixin = throw '';
  @JSExport('getSet')
  int get getSetMixin => throw '';
  @JSExport('getSet')
  set getSetMixin(int val) => throw '';
  @JSExport('method')
  void methodMixin() => throw '';
}

@JSExport()
mixin MixinCollision2 {
  @JSExport('field')
  int fieldMixin2 = throw '';
  @JSExport('finalField')
  final int finalFieldMixin2 = throw '';
  @JSExport('getSet')
  int get getSetMixin2 => throw '';
  @JSExport('getSet')
  set getSetMixin2(int val) => throw '';
  @JSExport('method')
  void methodMixin2() => throw '';
}

@JSExport()
class InheritanceRenameOneCollision extends SuperclassCollision
//    ^
// [web] The following class members collide with the same export 'field': MixinCollision.fieldMixin, SuperclassCollision.fieldSuper.
// [web] The following class members collide with the same export 'finalField': MixinCollision.finalFieldMixin, SuperclassCollision.finalFieldSuper.
// [web] The following class members collide with the same export 'getSet': MixinCollision.getSetMixin, MixinCollision.getSetMixin, SuperclassCollision.getSetSuper, SuperclassCollision.getSetSuper.
// [web] The following class members collide with the same export 'method': MixinCollision.methodMixin, SuperclassCollision.methodSuper.
    with
        MixinCollision {}

@JSExport()
class InheritanceRenameTwoCollisions extends SuperclassCollision
//    ^
// [web] The following class members collide with the same export 'field': MixinCollision.fieldMixin, MixinCollision2.fieldMixin2, SuperclassCollision.fieldSuper.
// [web] The following class members collide with the same export 'finalField': MixinCollision.finalFieldMixin, MixinCollision2.finalFieldMixin2, SuperclassCollision.finalFieldSuper.
// [web] The following class members collide with the same export 'getSet': MixinCollision.getSetMixin, MixinCollision.getSetMixin, MixinCollision2.getSetMixin2, MixinCollision2.getSetMixin2, SuperclassCollision.getSetSuper, SuperclassCollision.getSetSuper.
// [web] The following class members collide with the same export 'method': MixinCollision.methodMixin, MixinCollision2.methodMixin2, SuperclassCollision.methodSuper.
    with
        MixinCollision,
        MixinCollision2 {}

@JSExport()
class InheritanceRenameThreeCollisions extends SuperclassCollision
//    ^
// [web] The following class members collide with the same export 'field': InheritanceRenameThreeCollisions.fieldDerived, MixinCollision.fieldMixin, MixinCollision2.fieldMixin2, SuperclassCollision.fieldSuper.
// [web] The following class members collide with the same export 'finalField': InheritanceRenameThreeCollisions.finalFieldDerived, MixinCollision.finalFieldMixin, MixinCollision2.finalFieldMixin2, SuperclassCollision.finalFieldSuper.
// [web] The following class members collide with the same export 'getSet': InheritanceRenameThreeCollisions.getSetDerived, InheritanceRenameThreeCollisions.getSetDerived, MixinCollision.getSetMixin, MixinCollision.getSetMixin, MixinCollision2.getSetMixin2, MixinCollision2.getSetMixin2, SuperclassCollision.getSetSuper, SuperclassCollision.getSetSuper.
// [web] The following class members collide with the same export 'method': InheritanceRenameThreeCollisions.methodDerived, MixinCollision.methodMixin, MixinCollision2.methodMixin2, SuperclassCollision.methodSuper.
    with
        MixinCollision,
        MixinCollision2 {
  @JSExport('field')
  int fieldDerived = throw '';
  @JSExport('finalField')
  final int finalFieldDerived = throw '';
  @JSExport('getSet')
  int get getSetDerived => throw '';
  @JSExport('getSet')
  set getSetDerived(int val) => throw '';
  @JSExport('method')
  void methodDerived() => throw '';
}

// No collision if superclass doesn't contain any members marked for export.
class SuperclassNoMembers {
  int field = throw '';
  final int finalField = throw '';
  int get getSet => throw '';
  set getSet(int val) => throw '';
  void method() => throw '';
}

class InheritanceNoSuperclassMembers extends SuperclassNoMembers {
  @JSExport('field')
  int fieldDerived = throw '';
  @JSExport('finalField')
  final int finalFieldDerived = throw '';
  @JSExport('getSet')
  int get getSetDerived => throw '';
  @JSExport('getSet')
  set getSetDerived(int val) => throw '';
  @JSExport('method')
  void methodDerived() => throw '';
}

class Fields {
  int getterField = throw '';
  int setterField = throw '';
}

// These partial overrides are okay, as there's still one getter and one setter
// per name.
@JSExport()
class PartialOverrideFieldNoCollision extends Fields {
  set getterField(int val) => throw '';
  int get setterField => throw '';
}

@JSExport()
class GetSet {
  int get getter => throw '';
  set setter(int val) => throw '';
}

// Getters and setters through inheritance should be okay.
@JSExport()
class GetSetInheritanceNoCollision extends Fields {
  int get setter => throw '';
  set getter(int val) => throw '';
}

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

  // Same method with different name and type.
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
