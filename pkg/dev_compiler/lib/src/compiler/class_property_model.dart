// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection' show HashSet;

import 'package:analyzer/dart/ast/ast.dart' show Identifier;
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/element/element.dart' show FieldElementImpl;

import '../js_ast/js_ast.dart' as JS;
import 'element_helpers.dart';
import 'js_names.dart' as JS;

/// Tracks how fields, getters and setters are represented when emitting JS.
///
/// Dart classes have implicit features that must be made explicit:
///
/// - virtual fields induce a getter and setter pair.
/// - getters and setters are independent.
/// - getters and setters can be overridden.
///
class ClassPropertyModel {
  /// Fields that are virtual, that is, they must be generated as a property
  /// pair in JavaScript.
  ///
  /// The value property stores the symbol used for the field's storage slot.
  final virtualFields = <FieldElement, JS.TemporaryId>{};

  /// Static fields that are overridden, this does not matter for Dart but in
  /// JS we need to take care initializing these because JS classes inherit
  /// statics.
  final staticFieldOverrides = new HashSet<FieldElement>();

  /// The set of inherited getters, used because JS getters/setters are paired,
  /// so if we're generating a setter we may need to emit a getter that calls
  /// super.
  final inheritedGetters = new HashSet<String>();

  /// The set of inherited setters, used because JS getters/setters are paired,
  /// so if we're generating a getter we may need to emit a setter that calls
  /// super.
  final inheritedSetters = new HashSet<String>();

  ClassPropertyModel.build(
      ClassElement classElem, Iterable<ExecutableElement> extensionMembers) {
    // Visit superclasses to collect information about their fields/accessors.
    // This is expensive so we try to collect everything in one pass.
    for (var base in getSuperclasses(classElem)) {
      for (var accessor in base.accessors) {
        // For getter/setter pairs only process them once.
        if (accessor.correspondingGetter != null) continue;

        var field = accessor.variable;
        var name = field.name;
        // Ignore private names from other libraries.
        if (Identifier.isPrivateName(name) &&
            accessor.library != classElem.library) {
          continue;
        }

        if (field.getter?.isAbstract == false) inheritedGetters.add(name);
        if (field.setter?.isAbstract == false) inheritedSetters.add(name);
      }
    }

    var extensionNames =
        new HashSet<String>.from(extensionMembers.map((e) => e.name));

    // Visit accessors in the current class, and see if they need to be
    // generated differently based on the inherited fields/accessors.
    for (var accessor in classElem.accessors) {
      // For getter/setter pairs only process them once.
      if (accessor.correspondingGetter != null) continue;
      // Also ignore abstract fields.
      if (accessor.isAbstract) continue;

      var field = accessor.variable;
      var name = field.name;
      // Is it a field?
      if (!field.isSynthetic && field is FieldElementImpl) {
        if (inheritedGetters.contains(name) ||
            inheritedSetters.contains(name) ||
            extensionNames.contains(name) ||
            field.isVirtual) {
          if (field.isStatic) {
            staticFieldOverrides.add(field);
          } else {
            virtualFields[field] = new JS.TemporaryId(name);
          }
        }
      }
    }
  }
}
