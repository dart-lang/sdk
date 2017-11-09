// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection' show HashMap, HashSet, Queue;

import 'package:kernel/core_types.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/type_environment.dart';
import '../compiler/js_names.dart' as JS;
import '../js_ast/js_ast.dart' as JS;
import 'kernel_helpers.dart';
import 'native_types.dart';

/// Dart allows all fields to be overridden.
///
/// To prevent a performance/code size penalty for allowing this, we analyze
/// private classes within each library that is being compiled to determine
/// if those fields should be virtual or not. In effect, we devirtualize fields
/// when possible by analyzing the class hierarchy and using knowledge of
/// which members are private and thus, could not be overridden outside of the
/// current library.
class VirtualFieldModel {
  final _modelForLibrary = new HashMap<Library, _LibraryVirtualFieldModel>();

  _LibraryVirtualFieldModel _getModel(Library library) => _modelForLibrary
      .putIfAbsent(library, () => new _LibraryVirtualFieldModel.build(library));

  /// Returns true if a field is virtual.
  bool isVirtual(Field field) =>
      _getModel(field.enclosingLibrary).isVirtual(field);
}

/// This is a building block of [VirtualFieldModel], used to track information
/// about a single library that has been analyzed.
class _LibraryVirtualFieldModel {
  /// Fields that are private (or public fields of a private class) and
  /// overridden in this library.
  ///
  /// This means we must generate them as virtual fields using a property pair
  /// in JavaScript.
  final _overriddenPrivateFields = new HashSet<Field>();

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
  final _extensiblePrivateClasses = new HashSet<Class>();

  _LibraryVirtualFieldModel.build(Library library) {
    var allClasses = library.classes;

    // The set of public types is our initial extensible type set.
    // From there, visit all immediate private types in this library, and so on
    // from those private types, marking them as extensible.
    var classesToVisit =
        new Queue<Class>.from(allClasses.where((c) => !c.name.startsWith('_')));
    while (classesToVisit.isNotEmpty) {
      var c = classesToVisit.removeFirst();

      // For each supertype of a public type in this library,
      // if we encounter a private class, we mark it as being extended, and
      // add it to our work set if this is the first time we've visited it.
      for (var superclass in getImmediateSuperclasses(c)) {
        if (superclass.name.startsWith('_') &&
            superclass.enclosingLibrary == library) {
          if (_extensiblePrivateClasses.add(superclass)) {
            classesToVisit.add(superclass);
          }
        }
      }
    }

    // Class can only look up inherited members with an O(N) scan through
    // the class, so we build up a mapping of all fields in the library ahead of
    // time.
    var allFields = new HashMap<Class, HashMap<String, Field>>.fromIterable(
        allClasses,
        value: (t) => new HashMap.fromIterable(
            t.fields.where((f) => !f.isStatic),
            key: (f) => f.name));

    for (var class_ in allClasses) {
      Set<Class> superclasses = null;

      // Visit accessors in the current class, and see if they override an
      // otherwise private field.
      for (var member in class_.members) {
        // Ignore abstract/static accessors, methods, constructors.
        if (member.isAbstract ||
            member is Procedure && (!member.isAccessor || member.isStatic) ||
            member is Constructor) {
          continue;
        }
        assert(member is Field || member is Procedure && member.isAccessor);

        // Ignore public accessors in extensible classes.
        if (!member.name.isPrivate &&
            (!class_.name.startsWith('_') ||
                _extensiblePrivateClasses.contains(class_))) {
          continue;
        }

        if (superclasses == null) {
          superclasses = new Set();
          void collectSupertypes(Class c) {
            if (!superclasses.add(c)) return;
            var s = c.superclass;
            if (s != null) collectSupertypes(s);
            var m = c.mixedInClass;
            if (m != null) collectSupertypes(m);
          }

          collectSupertypes(class_);
          superclasses.remove(class_);
          superclasses.removeWhere(
              (s) => s.enclosingLibrary != class_.enclosingLibrary);
        }

        // Look in all super classes to see if we're overriding a field in our
        // library, if so mark that field as overridden.
        var name = member.name.name;
        _overriddenPrivateFields.addAll(superclasses
            .map((c) => allFields[c][name])
            .where((f) => f != null));
      }
    }
  }

  /// Returns true if a field inside this library is virtual.
  bool isVirtual(Field field) {
    // If the field was marked non-virtual, we know for sure.
    if (field.isStatic) return false;

    var class_ = field.enclosingClass;
    var libraryUri = class_.enclosingLibrary.importUri;
    if (libraryUri.scheme == 'dart' && libraryUri.path.startsWith('_')) {
      // There should be no extensible fields in private SDK libraries.
      return false;
    }

    if (!field.name.isPrivate) {
      // Public fields in public classes (or extensible private classes)
      // are always virtual.
      // They could be overridden by someone using our library.
      if (!class_.name.startsWith('_')) return true;
      if (_extensiblePrivateClasses.contains(class_)) return true;
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
  final NativeTypeSet extensionTypes;
  final TypeEnvironment types;

  /// Fields that are virtual, that is, they must be generated as a property
  /// pair in JavaScript.
  ///
  /// The value property stores the symbol used for the field's storage slot.
  final virtualFields = <Field, JS.TemporaryId>{};

  /// The set of inherited getters, used because JS getters/setters are paired,
  /// so if we're generating a setter we may need to emit a getter that calls
  /// super.
  final inheritedGetters = new HashSet<String>();

  /// The set of inherited setters, used because JS getters/setters are paired,
  /// so if we're generating a getter we may need to emit a setter that calls
  /// super.
  final inheritedSetters = new HashSet<String>();

  final mockMembers = <String, Member>{};

  final extensionMethods = new Set<String>();

  final extensionAccessors = new Set<String>();

  ClassPropertyModel.build(this.types, this.extensionTypes,
      VirtualFieldModel fieldModel, Class class_) {
    // Visit superclasses to collect information about their fields/accessors.
    // This is expensive so we try to collect everything in one pass.
    for (var base in getSuperclasses(class_)) {
      for (var member in base.members) {
        if (member is Constructor ||
            member is Procedure && (!member.isAccessor || member.isStatic)) {
          continue;
        }

        // Ignore private names from other libraries.
        if (member.name.isPrivate &&
            member.enclosingLibrary != class_.enclosingLibrary) {
          continue;
        }

        var name = member.name.name;
        if (member is Field) {
          inheritedGetters.add(name);
          if (!member.isFinal) inheritedSetters.add(name);
        } else {
          var accessor = member as Procedure;
          assert(accessor.isAccessor);
          (accessor.isGetter ? inheritedGetters : inheritedSetters).add(name);
        }
      }
    }

    _collectMockMembers(class_);
    _collectExtensionMembers(class_);

    var virtualAccessorNames = new HashSet<String>()
      ..addAll(inheritedGetters)
      ..addAll(inheritedSetters)
      ..addAll(extensionAccessors)
      ..addAll(mockMembers.values.map((m) => m.name.name));

    // Visit accessors in the current class, and see if they need to be
    // generated differently based on the inherited fields/accessors.
    for (var field in class_.fields) {
      // Also ignore abstract fields.
      if (field.isAbstract || field.isStatic) continue;

      var name = field.name.name;
      if (virtualAccessorNames.contains(name) ||
          fieldModel.isVirtual(field) ||
          field.isCovariant ||
          field.isGenericCovariantImpl) {
        virtualFields[field] = new JS.TemporaryId(name);
      }
    }
  }

  CoreTypes get coreTypes => extensionTypes.coreTypes;

  void _collectMockMembers(Class class_) {
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
    if (!_hasNoSuchMethod(class_)) return;

    // Collect all unimplemented members.
    //
    // Initially, we track abstract and concrete members separately, then
    // remove concrete from the abstract set. This is done because abstract
    // members are allowed to "override" concrete ones in Dart.
    // (In that case, it will still be treated as a concrete member and can be
    // called at runtime.)
    var concreteMembers = new HashSet<String>();

    void visit(Class c, bool classIsAbstract) {
      if (c == null) return;
      visit(c.superclass, classIsAbstract);
      visit(c.mixedInClass, classIsAbstract);
      for (var i in c.implementedTypes) visit(i.classNode, true);

      for (var m in c.members) {
        if (m is Constructor) continue;

        var isAbstract = classIsAbstract || m.isAbstract;
        addMember(bool setter) {
          var name = m.name.name;
          if (setter) name += '=';
          if (isAbstract) {
            mockMembers[name] = m;
          } else {
            concreteMembers.add(name);
          }
        }

        var name = m.name.name;
        if (m is Field) {
          addMember(false);
          if (!m.isFinal) addMember(true);
        } else {
          var p = m as Procedure;
          if (!p.isStatic) addMember(p.isSetter);
        }
      }
    }

    visit(class_, false);

    concreteMembers.forEach(mockMembers.remove);
  }

  void _collectExtensionMembers(Class class_) {
    if (extensionTypes.isNativeClass(class_)) return;

    // Find all generic interfaces that could be used to call into members of
    // this class. This will help us identify which parameters need checks
    // for soundness.
    var allNatives = new HashSet<String>();
    _collectNativeMembers(class_, allNatives);
    if (allNatives.isEmpty) return;

    // For members on this class, check them against all generic interfaces.
    var seenConcreteMembers = new HashSet<String>();
    _findExtensionMembers(class_, seenConcreteMembers, allNatives);
    // Add mock members. These are compiler-generated concrete members that
    // forward to `noSuchMethod`.
    for (var m in mockMembers.values) {
      var name = m.name.name;
      if (seenConcreteMembers.add(name) && allNatives.contains(name)) {
        var extMembers = m is Procedure && !m.isAccessor
            ? extensionMethods
            : extensionAccessors;
        extMembers.add(name);
      }
    }

    // For members of the superclass, we may need to add checks because this
    // class adds a new unsafe interface. Collect those checks.
    var visited = new HashSet<Class>()..add(class_);
    var existingMembers = new HashSet<String>();

    void visitImmediateSuper(Class c) {
      // For members of mixins/supertypes, check them against new interfaces,
      // and also record any existing checks they already had.
      var oldCovariant = new HashSet<String>();
      _collectNativeMembers(c, oldCovariant);
      var newCovariant = allNatives.difference(oldCovariant);
      if (newCovariant.isEmpty) return;

      existingMembers.addAll(oldCovariant);

      void visitSuper(Class c) {
        if (visited.add(c)) {
          _findExtensionMembers(c, seenConcreteMembers, newCovariant);
          var m = c.mixedInClass;
          if (m != null) visitSuper(m);
          var s = c.superclass;
          if (s != null) visitSuper(s);
        }
      }

      visitSuper(c);
    }

    var m = class_.mixedInClass;
    if (m != null) visitImmediateSuper(m);
    var s = class_.superclass;
    if (s != null) visitImmediateSuper(s);
  }

  /// Searches all concrete instance members declared on this type, skipping
  /// already [seenConcreteMembers], and adds them to [extensionMembers] if
  /// needed.
  ///
  /// By tracking the set of seen members, we can visit superclasses and mixins
  /// and ultimately collect every most-derived member exposed by a given type.
  void _findExtensionMembers(Class class_, HashSet<String> seenConcreteMembers,
      Set<String> allNatives) {
    // We only visit each most derived concrete member.
    // To avoid visiting an overridden superclass member, we skip members
    // we've seen, and visit starting from the class, then mixins in
    // reverse order, then superclasses.
    for (var m in class_.members) {
      var name = m.name.name;
      if (m.isAbstract || m is Constructor) continue;
      if (m is Procedure) {
        if (m.isStatic) continue;
        if (seenConcreteMembers.add(name) && allNatives.contains(name)) {
          (m.isAccessor ? extensionAccessors : extensionMethods).add(name);
        }
      } else if (m is Field) {
        if (m.isStatic) continue;
        if (seenConcreteMembers.add(name) && allNatives.contains(name)) {
          extensionAccessors.add(name);
        }
      }
    }
  }

  /// Collects all supertypes that may themselves contain native subtypes,
  /// excluding [Object], for example `List` is implemented by several native
  /// types.
  void _collectNativeMembers(Class c, Set<String> members) {
    if (extensionTypes.hasNativeSubtype(c)) {
      for (var m in c.procedures) {
        if (!m.name.isPrivate && !m.isStatic) members.add(m.name.name);
      }
    }
    var m = c.mixedInClass;
    if (m != null) _collectNativeMembers(m, members);
    for (var i in c.implementedTypes) {
      _collectNativeMembers(i.classNode, members);
    }
    var s = c.superclass;
    if (s != null) _collectNativeMembers(s, members);
  }

  /// Return `true` if the given [classElement] has a noSuchMethod() method
  /// distinct from the one declared in class Object, as per the Dart Language
  /// Specification (section 10.4).
  // TODO(jmesserly): this was taken from error_verifier.dart
  bool _hasNoSuchMethod(Class c) {
    // TODO(jmesserly): is this lookup fast in Kernel?
    // TODO(jmesserly): our old code may have matched an abstract nSM, but
    // that seems incorrect. So we now look for a dispatch target.
    var method = types.hierarchy.getDispatchTarget(c, new Name('noSuchMethod'));
    var definingClass = method?.enclosingClass;
    return definingClass != null && definingClass != coreTypes.objectClass;
  }
}
