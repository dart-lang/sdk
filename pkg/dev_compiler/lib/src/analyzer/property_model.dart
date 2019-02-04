// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection' show HashMap, HashSet, Queue;

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart' show InterfaceType;
import 'package:analyzer/src/dart/element/element.dart' show FieldElementImpl;

import '../compiler/js_names.dart' as JS;
import '../js_ast/js_ast.dart' as JS;
import 'element_helpers.dart';
import 'extension_types.dart';

/// Dart allows all fields to be overridden.
///
/// To prevent a performance/code size penalty for allowing this, we analyze
/// private classes within each library that is being compiled to determine
/// if those fields should be virtual or not. In effect, we devirtualize fields
/// when possible by analyzing the class hierarchy and using knowledge of
/// which members are private and thus, could not be overridden outside of the
/// current library.
class VirtualFieldModel {
  final _modelForLibrary = HashMap<LibraryElement, _LibraryVirtualFieldModel>();

  _LibraryVirtualFieldModel _getModel(LibraryElement library) =>
      _modelForLibrary.putIfAbsent(
          library, () => _LibraryVirtualFieldModel.build(library));

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
  final _overriddenPrivateFields = HashSet<FieldElement>();

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
  final _extensiblePrivateClasses = HashSet<ClassElement>();

  _LibraryVirtualFieldModel.build(LibraryElement library) {
    var allClasses = Set<ClassElement>();
    for (var libraryPart in library.units) {
      allClasses.addAll(libraryPart.types);
      allClasses.addAll(libraryPart.mixins);
    }

    // The set of public types is our initial extensible type set.
    // From there, visit all immediate private types in this library, and so on
    // from those private types, marking them as extensible.
    var classesToVisit =
        Queue<ClassElement>.from(allClasses.where((t) => t.isPublic));
    while (classesToVisit.isNotEmpty) {
      var extensibleClass = classesToVisit.removeFirst();

      // For each supertype of a public type in this library,
      // if we encounter a private class, we mark it as being extended, and
      // add it to our work set if this is the first time we've visited it.
      for (var superclass in getImmediateSuperclasses(extensibleClass)) {
        if (!superclass.isPublic && superclass.library == library) {
          if (_extensiblePrivateClasses.add(superclass))
            classesToVisit.add(superclass);
        }
      }
    }

    // ClassElement can only look up inherited members with an O(N) scan through
    // the class, so we build up a mapping of all fields in the library ahead of
    // time.
    Map<String, FieldElement> getInstanceFieldMap(ClassElement c) {
      var instanceFields = c.fields.where((f) => !f.isStatic);
      return HashMap.fromIterables(
          instanceFields.map((f) => f.name), instanceFields);
    }

    var allFields =
        HashMap.fromIterables(allClasses, allClasses.map(getInstanceFieldMap));

    for (var class_ in allClasses) {
      Set<ClassElement> superclasses;

      // Visit accessors in the current class, and see if they override an
      // otherwise private field.
      for (var accessor in class_.accessors) {
        // For getter/setter pairs only process them once.
        if (accessor.correspondingGetter != null) continue;
        // Ignore abstract or static accessors.
        if (accessor.isAbstract || accessor.isStatic) continue;
        // Ignore public accessors in extensible classes.
        if (accessor.isPublic &&
            (class_.isPublic || _extensiblePrivateClasses.contains(class_))) {
          continue;
        }

        if (superclasses == null) {
          superclasses = Set();
          void collectSuperclasses(ClassElement cls) {
            if (!superclasses.add(cls)) return;
            var s = cls.supertype?.element;
            if (s != null) collectSuperclasses(s);
            cls.mixins.forEach((m) => collectSuperclasses(m.element));
          }

          collectSuperclasses(class_);
          superclasses.remove(class_);
          superclasses.removeWhere((c) => c.library != library);
        }

        // Look in all super classes to see if we're overriding a field in our
        // library, if so mark that field as overridden.
        var name = accessor.variable.name;
        _overriddenPrivateFields.addAll(superclasses
            .map((c) => allFields[c][name])
            .where((f) => f != null));
      }
    }
  }

  /// Returns true if a field inside this library is virtual.
  bool isVirtual(FieldElement field) {
    if (field.isStatic) return false;

    var type = field.enclosingElement;
    var uri = type.source.uri;
    if (uri.scheme == 'dart' && uri.path.startsWith('_')) {
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

  /// The set of inherited getters, used because JS getters/setters are paired,
  /// so if we're generating a setter we may need to emit a getter that calls
  /// super.
  final inheritedGetters = HashSet<String>();

  /// The set of inherited setters, used because JS getters/setters are paired,
  /// so if we're generating a getter we may need to emit a setter that calls
  /// super.
  final inheritedSetters = HashSet<String>();

  final mockMembers = <String, ExecutableElement>{};

  final extensionMethods = Set<String>();

  final extensionAccessors = Set<String>();

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

    var virtualAccessorNames = HashSet<String>()
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
      if (accessor.isAbstract || accessor.isStatic) continue;

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
          virtualFields[field] = JS.TemporaryId(name);
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
    if (element.isMixin || !hasNoSuchMethod(element)) return;

    // Collect all unimplemented members.
    //
    // Initially, we track abstract and concrete members separately, then
    // remove concrete from the abstract set. This is done because abstract
    // members are allowed to "override" concrete ones in Dart.
    // (In that case, it will still be treated as a concrete member and can be
    // called at runtime.)
    var concreteMembers = HashSet<String>();

    void visit(InterfaceType type, bool isAbstract) {
      if (type == null) return;
      visit(type.superclass, isAbstract);
      for (var m in type.mixins) visit(m, isAbstract);
      for (var i in type.interfaces) visit(i, true);

      for (var m in [type.methods, type.accessors].expand((m) => m)) {
        if (m.isStatic) continue;
        if (isAbstract || m.isAbstract) {
          mockMembers[m.name] = m;
        } else {
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
    var allNatives = HashSet<String>();
    _collectNativeMembers(element.type, allNatives);
    if (allNatives.isEmpty) return;

    // For members on this class, check them against all generic interfaces.
    var seenConcreteMembers = HashSet<String>();
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

    var visited = HashSet<ClassElement>()..add(element);
    var existingMembers = HashSet<String>();

    void visitImmediateSuper(InterfaceType type) {
      // For members of mixins/supertypes, check them against new interfaces,
      // and also record any existing checks they already had.
      var oldCovariant = HashSet<String>();
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
    var supertype = element.supertype;
    if (supertype != null) {
      _collectNativeMembers(element.supertype, members);
    }
    if (element.isEnum) {
      // TODO(jmesserly): analyzer does not create the synthetic element
      // for the enum's `toString()` method, so we'll use the one on Object.
      members.add('toString');
    }
  }
}
