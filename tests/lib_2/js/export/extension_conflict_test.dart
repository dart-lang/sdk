// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that `createStaticInteropMock` checks for extension member conflicts.

import 'package:js/js.dart';
import 'package:js/js_util.dart';

class EmptyDart {}

@JS()
@staticInterop
class Method {}

extension on Method {
  external void member();
}

@JS()
@staticInterop
class Getter {}

extension NamedExtension on Getter {
  external int get member;
}

@JS()
@staticInterop
class Field {}

extension on Field {
  external final String member;
}

@JS()
@staticInterop
class ExtendsImplementsConflict extends Method implements Getter {}

@JS()
@staticInterop
class ImplementsConflict implements Method, Getter {}

@JS()
@staticInterop
class ManyConflicts extends Method implements Getter, Field {}

@JS()
@staticInterop
class Override implements Method {}

extension on Override {
  external int member();
}

@JS()
@staticInterop
class OverrideOneConflictButNotAll implements Override, Getter {}

@JS()
@staticInterop
class ConflictThroughInheritance implements OverrideOneConflictButNotAll {}

@JS()
@staticInterop
class ResolveThroughOverride implements ConflictThroughInheritance {}

extension on ResolveThroughOverride {
  external int member;
}

class ResolveThroughOverrideDart {
  int member = throw '';
}

@JS()
@staticInterop
class Setter {}

extension on Setter {
  external set member(int val);
}

@JS()
@staticInterop
class NoConflictDueToSubtype implements Override, Method {}

class NoConflictDueToSubtypeDart {
  int member() => throw '';
}

@JS()
@staticInterop
class GetterSetterConflict implements Setter, Getter {}

@JS()
@staticInterop
class GetterSetterSameExtension {}

extension on GetterSetterSameExtension {
  external int get member;
  external set member(int val);
}

class GetterSetterSameExtensionDart extends ResolveThroughOverrideDart {}

@JS()
@staticInterop
class GetterSetterMethodConflict implements GetterSetterSameExtension, Method {}

@JS()
@staticInterop
class NonExternal {}

extension on NonExternal {
  int get member => throw '';
}

@JS()
@staticInterop
class ExternalNonExternal implements NonExternal, GetterSetterSameExtension {}

class ExternalNonExternalDart extends ResolveThroughOverrideDart {}

void main() {
  // Test name conflicts between extended and implemented members.
  createStaticInteropMock<ExtendsImplementsConflict, EmptyDart>(
//^
// [web] External extension member with name 'member' is defined in the following extensions and none are more specific: 'Getter.NamedExtension', 'Method.unnamed'.
      EmptyDart());
  // Test name conflicts between implemented members.
  createStaticInteropMock<ImplementsConflict, EmptyDart>(EmptyDart());
//^
// [web] External extension member with name 'member' is defined in the following extensions and none are more specific: 'Getter.NamedExtension', 'Method.unnamed'.

  // Test multiple name conflicts.
  createStaticInteropMock<ManyConflicts, EmptyDart>(EmptyDart());
//^
// [web] External extension member with name 'member' is defined in the following extensions and none are more specific: 'Field.unnamed', 'Getter.NamedExtension', 'Method.unnamed'.

  // Test name conflicts where one definition is overridden, but there is still
  // a name conflict between the other two.
  createStaticInteropMock<OverrideOneConflictButNotAll, EmptyDart>(
//^
// [web] External extension member with name 'member' is defined in the following extensions and none are more specific: 'Getter.NamedExtension', 'Override.unnamed'.
      EmptyDart());
  // Test case where if we inherit a class with a conflict, the conflict still
  // exists.
  createStaticInteropMock<ConflictThroughInheritance, EmptyDart>(
//^
// [web] External extension member with name 'member' is defined in the following extensions and none are more specific: 'Getter.NamedExtension', 'Override.unnamed'.
      EmptyDart());
  // Test case where name conflicts are resolved using derived class.
  createStaticInteropMock<ResolveThroughOverride, ResolveThroughOverrideDart>(
      ResolveThroughOverrideDart());
  // Test case where you inherit two classes with the same member name but they
  // have a subtype relation, so there is no conflict.
  createStaticInteropMock<NoConflictDueToSubtype, NoConflictDueToSubtypeDart>(
      NoConflictDueToSubtypeDart());
  // Test conflict where getter and setter collide when they are in different
  // extensions.
  createStaticInteropMock<GetterSetterConflict, EmptyDart>(EmptyDart());
//^
// [web] External extension member with name 'member' is defined in the following extensions and none are more specific: 'Getter.NamedExtension', 'Setter.unnamed'.

  // Test no conflict where getter and setter are on the same extension.
  createStaticInteropMock<GetterSetterSameExtension,
      GetterSetterSameExtensionDart>(GetterSetterSameExtensionDart());
  // Test conflict where getter and setter are in one extension, but there is
  // a conflict with another extension.
  createStaticInteropMock<GetterSetterMethodConflict, EmptyDart>(EmptyDart());
//^
// [web] External extension member with name 'member' is defined in the following extensions and none are more specific: 'GetterSetterSameExtension.unnamed', 'Method.unnamed'.

  // Test no conflict between external and non-external members.
  createStaticInteropMock<ExternalNonExternal, ExternalNonExternalDart>(
      ExternalNonExternalDart());
}
