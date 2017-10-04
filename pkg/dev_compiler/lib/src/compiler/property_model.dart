// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection' show HashMap, HashSet, Queue;

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart' show InterfaceType;
import 'package:analyzer/src/dart/element/element.dart' show FieldElementImpl;

import '../js_ast/js_ast.dart' as JS;
import 'element_helpers.dart';
import 'extension_types.dart';
import 'js_names.dart' as JS;

/// Dart allows all fields to be overridden.
///
/// To prevent a performance/code size penalty for allowing this, we analyze
/// private classes within each library that is being compiled to determine
/// if those fields should be virtual or not. In effect, we devirtualize fields
/// when possible by analyzing the class hierarchy and using knowledge of
/// which members are private and thus, could not be overridden outside of the
/// current library.
class VirtualFieldModel {
  final _modelForLibrary =
      new HashMap<LibraryElement, _LibraryVirtualFieldModel>();

  _LibraryVirtualFieldModel _getModel(LibraryElement library) =>
      _modelForLibrary.putIfAbsent(
          library, () => new _LibraryVirtualFieldModel.build(library));

  /// Returns true if a field is virtual.
  bool isVirtual(FieldElement field) =>
      _getModel(field.library).isVirtual(field);
}

/// This is a building block of [VirtualFieldModel], used to track information
/// about a single library that has been analyzed.
class _LibraryVirtualFieldModel {
  /// Fields that are private (or public fields of a private class) and
  /// overridden in this library.
  ///
  /// This means we must generate them as virtual fields using a property pair
  /// in JavaScript.
  final _overriddenPrivateFields = new HashSet<FieldElement>();

  /// Private classes that can be extended outside of this library.
  ///
  /// Normally private classes cannot be accessed outside this library, however,
  /// this can happen if they are extended by a public class, for example:
  ///
  ///     class _A { int x = 42; }
  ///     class _B { int x = 42; }
  ///
  ///     // _A is now effectively public for the purpose of overrides.
  ///     class C extends _A {}
  ///
  /// The class _A must treat is "x" as virtual, however _B does not.
  final _extensiblePrivateClasses = new HashSet<ClassElement>();

  _LibraryVirtualFieldModel.build(LibraryElement library) {
    var allTypes = library.units.expand((u) => u.types).toList();

    // The set of public types is our initial extensible type set.
    // From there, visit all immediate private types in this library, and so on
    // from those private types, marking them as extensible.
    var typesToVisit =
        new Queue<ClassElement>.from(allTypes.where((t) => t.isPublic));
    while (typesToVisit.isNotEmpty) {
      var extensibleType = typesToVisit.removeFirst();

      // For each supertype of a public type in this library,
      // if we encounter a private class, we mark it as being extended, and
      // add it to our work set if this is the first time we've visited it.
      for (var type in getImmediateSuperclasses(extensibleType)) {
        if (!type.isPublic && type.library == library) {
          if (_extensiblePrivateClasses.add(type)) typesToVisit.add(type);
        }
      }
    }

    // ClassElement can only look up inherited members with an O(N) scan through
    // the class, so we build up a mapping of all fields in the library ahead of
    // time.
    var allFields =
        new HashMap<ClassElement, HashMap<String, FieldElement>>.fromIterable(
            allTypes,
            value: (t) => new HashMap.fromIterable(
                t.fields.where((f) => !f.isStatic),
                key: (f) => f.name));

    for (var type in allTypes) {
      Set<ClassElement> supertypes = null;

      // Visit accessors in the current class, and see if they override an
      // otherwise private field.
      for (var accessor in type.accessors) {
        // For getter/setter pairs only process them once.
        if (accessor.correspondingGetter != null) continue;
        // Ignore abstract or static accessors.
        if (accessor.isAbstract || accessor.isStatic) continue;
        // Ignore public accessors in extensible classes.
        if (accessor.isPublic &&
            (type.isPublic || _extensiblePrivateClasses.contains(type))) {
          continue;
        }

        if (supertypes == null) {
          supertypes = new Set();
          void collectSupertypes(ClassElement cls) {
            if (!supertypes.add(cls)) return;
            var s = cls.supertype?.element;
            if (s != null) collectSupertypes(s);
            cls.mixins.forEach((m) => collectSupertypes(m.element));
          }

          collectSupertypes(type);
          supertypes.remove(type);
          supertypes.removeWhere((c) => c.library != type.library);
        }

        // Look in all super classes to see if we're overriding a field in our
        // library, if so mark that field as overridden.
        var name = accessor.variable.name;
        _overriddenPrivateFields.addAll(
            supertypes.map((c) => allFields[c][name]).where((f) => f != null));
      }
    }
  }

  /// Returns true if a field inside this library is virtual.
  bool isVirtual(FieldElement field) {
    // If the field was marked non-virtual, we know for sure.
    if (!field.isVirtual) return false;
    if (field.isStatic) return false;

    var type = field.enclosingElement;
    var library = type.library;
    if (library.isInSdk && library.source.uri.toString().startsWith('dart:_')) {
      // There should be no extensible fields in private SDK libraries.
      return false;
    }

    if (field.isPublic) {
      // Public fields in public classes (or extensible private classes)
      // are always virtual.
      // They could be overridden by someone using our library.
      if (type.isPublic) return true;
      if (_extensiblePrivateClasses.contains(type)) return true;
    }

    // Otherwise, the field is effectively private and we only need to make it
    // virtual if it's overridden.
    return _overriddenPrivateFields.contains(field);
  }
}

/// Tracks how fields, getters and setters are represented when emitting JS.
///
/// Dart classes have implicit features that must be made explicit:
///
/// - virtual fields induce a getter and setter pair.
/// - getters and setters are independent.
/// - getters and setters can be overridden.
///
class ClassPropertyModel {
  final ExtensionTypeSet extensionTypes;

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

  final mockMembers = <String, ExecutableElement>{};

  final extensionMethods = new Set<String>();

  final extensionAccessors = new Set<String>();

  /// Parameters that are covariant due to covariant generics.
  final Set<Element> covariantParameters;

  ClassPropertyModel.build(
      this.extensionTypes,
      VirtualFieldModel fieldModel,
      ClassElement classElem,
      this.covariantParameters,
      Set<ExecutableElement> covariantPrivateMembers) {
    // Visit superclasses to collect information about their fields/accessors.
    // This is expensive so we try to collect everything in one pass.
    for (var base in getSuperclasses(classElem)) {
      for (var accessor in base.accessors) {
        // For getter/setter pairs only process them once.
        if (accessor.correspondingGetter != null) continue;

        var field = accessor.variable;
        // Ignore private names from other libraries.
        if (field.isPrivate && accessor.library != classElem.library) {
          continue;
        }

        if (field.getter?.isAbstract == false) inheritedGetters.add(field.name);
        if (field.setter?.isAbstract == false) inheritedSetters.add(field.name);
      }
    }

    _collectMockMembers(classElem.type);
    _collectExtensionMembers(classElem);

    var virtualAccessorNames = new HashSet<String>()
      ..addAll(inheritedGetters)
      ..addAll(inheritedSetters)
      ..addAll(extensionAccessors)
      ..addAll(mockMembers.values
          .map((m) => m is PropertyAccessorElement ? m.variable.name : m.name));

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
        var setter = field.setter;
        if (virtualAccessorNames.contains(name) ||
            fieldModel.isVirtual(field) ||
            setter != null &&
                covariantParameters != null &&
                covariantParameters.contains(setter.parameters[0]) &&
                covariantPrivateMembers.contains(setter)) {
          if (field.isStatic) {
            staticFieldOverrides.add(field);
          } else {
            virtualFields[field] = new JS.TemporaryId(name);
          }
        }
      }
    }
  }

  void _collectMockMembers(InterfaceType type) {
    // TODO(jmesserly): every type with nSM will generate new stubs for all
    // abstract members. For example:
    //
    //     class C { m(); noSuchMethod(...) { ... } }
    //     class D extends C { m(); noSuchMethod(...) { ... } }
    //
    // We'll generate D.m even though it is not necessary.
    //
    // Doing better is a bit tricky, as our current codegen strategy for the
    // mock methods encodes information about the number of arguments (and type
    // arguments) that D expects.
    var element = type.element;
    if (!hasNoSuchMethod(element)) return;

    // Collect all unimplemented members.
    //
    // Initially, we track abstract and concrete members separately, then
    // remove concrete from the abstract set. This is done because abstract
    // members are allowed to "override" concrete ones in Dart.
    // (In that case, it will still be treated as a concrete member and can be
    // called at runtime.)
    var concreteMembers = new HashSet<String>();

    void visit(InterfaceType type, bool isAbstract) {
      if (type == null) return;
      visit(type.superclass, isAbstract);
      for (var m in type.mixins) visit(m, isAbstract);
      for (var i in type.interfaces) visit(i, true);

      for (var m in [type.methods, type.accessors].expand((m) => m)) {
        if (isAbstract || m.isAbstract) {
          mockMembers[m.name] = m;
        } else if (!m.isStatic) {
          concreteMembers.add(m.name);
        }
      }
    }

    visit(type, false);

    concreteMembers.forEach(mockMembers.remove);
  }

  void _collectExtensionMembers(ClassElement element) {
    if (extensionTypes.isNativeClass(element)) return;

    // Find all generic interfaces that could be used to call into members of
    // this class. This will help us identify which parameters need checks
    // for soundness.
    var allNatives = new HashSet<String>();
    _collectNativeMembers(element.type, allNatives);
    if (allNatives.isEmpty) return;

    // For members on this class, check them against all generic interfaces.
    var seenConcreteMembers = new HashSet<String>();
    _findExtensionMembers(element.type, seenConcreteMembers, allNatives);
    // Add mock members. These are compiler-generated concrete members that
    // forward to `noSuchMethod`.
    for (var m in mockMembers.values) {
      var name = m is PropertyAccessorElement ? m.variable.name : m.name;
      if (seenConcreteMembers.add(name) && allNatives.contains(name)) {
        var extMembers = m is PropertyAccessorElement
            ? extensionAccessors
            : extensionMethods;
        extMembers.add(name);
      }
    }

    // For members of the superclass, we may need to add checks because this
    // class adds a new unsafe interface. Collect those checks.

    var visited = new HashSet<ClassElement>()..add(element);
    var existingMembers = new HashSet<String>();

    void visitImmediateSuper(InterfaceType type) {
      // For members of mixins/supertypes, check them against new interfaces,
      // and also record any existing checks they already had.
      var oldCovariant = new HashSet<String>();
      _collectNativeMembers(type, oldCovariant);
      var newCovariant = allNatives.difference(oldCovariant);
      if (newCovariant.isEmpty) return;

      existingMembers.addAll(oldCovariant);

      void visitSuper(InterfaceType type) {
        var element = type.element;
        if (visited.add(element)) {
          _findExtensionMembers(type, seenConcreteMembers, newCovariant);
          element.mixins.reversed.forEach(visitSuper);
          var s = element.supertype;
          if (s != null) visitSuper(s);
        }
      }

      visitSuper(type);
    }

    element.mixins.reversed.forEach(visitImmediateSuper);
    var s = element.supertype;
    if (s != null) visitImmediateSuper(s);
  }

  /// Searches all concrete instance members declared on this type, skipping
  /// already [seenConcreteMembers], and adds them to [extensionMembers] if
  /// needed.
  ///
  /// By tracking the set of seen members, we can visit superclasses and mixins
  /// and ultimately collect every most-derived member exposed by a given type.
  void _findExtensionMembers(InterfaceType type,
      HashSet<String> seenConcreteMembers, Set<String> allNatives) {
    // We only visit each most derived concrete member.
    // To avoid visiting an overridden superclass member, we skip members
    // we've seen, and visit starting from the class, then mixins in
    // reverse order, then superclasses.
    for (var m in type.methods) {
      var name = m.name;
      if (!m.isStatic &&
          !m.isAbstract &&
          seenConcreteMembers.add(name) &&
          allNatives.contains(name)) {
        extensionMethods.add(name);
      }
    }
    for (var m in type.accessors) {
      var name = m.variable.name;
      if (!m.isStatic &&
          !m.isAbstract &&
          seenConcreteMembers.add(name) &&
          allNatives.contains(name)) {
        extensionAccessors.add(name);
      }
    }
    if (type.element.isEnum) {
      extensionMethods.add('toString');
    }
  }

  /// Collects all supertypes that may themselves contain native subtypes,
  /// excluding [Object], for example `List` is implemented by several native
  /// types.
  void _collectNativeMembers(InterfaceType type, Set<String> members) {
    var element = type.element;
    if (extensionTypes.hasNativeSubtype(type)) {
      for (var m in type.methods) {
        if (m.isPublic && !m.isStatic) members.add(m.name);
      }
      for (var m in type.accessors) {
        if (m.isPublic && !m.isStatic) members.add(m.variable.name);
      }
    }
    for (var m in element.mixins.reversed) {
      _collectNativeMembers(m, members);
    }
    for (var i in element.interfaces) {
      _collectNativeMembers(i, members);
    }
    if (!type.isObject) {
      _collectNativeMembers(element.supertype, members);
    }
  }
}
