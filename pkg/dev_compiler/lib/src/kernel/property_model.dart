// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'dart:collection' show HashMap, HashSet, Queue;

import 'package:kernel/core_types.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/type_environment.dart';

import '../compiler/js_names.dart' as js_ast;
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
  final _modelForLibrary = HashMap<Library, _LibraryVirtualFieldModel>();

  _LibraryVirtualFieldModel _getModel(Library library) => _modelForLibrary
      .putIfAbsent(library, () => _LibraryVirtualFieldModel.build(library));

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
  final _overriddenPrivateFields = HashSet<Field>();

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
  final _extensiblePrivateClasses = HashSet<Class>();

  _LibraryVirtualFieldModel.build(Library library) {
    var allClasses = library.classes;

    // The set of public types is our initial extensible type set.
    // From there, visit all immediate private types in this library, and so on
    // from those private types, marking them as extensible.
    var classesToVisit =
        Queue<Class>.from(allClasses.where((c) => !c.name.startsWith('_')));
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
    Map<String, Field> getInstanceFieldMap(Class c) {
      var instanceFields = c.fields.where((f) => !f.isStatic);
      return HashMap.fromIterables(
          instanceFields.map((f) => f.name.text), instanceFields);
    }

    var allFields =
        HashMap.fromIterables(allClasses, allClasses.map(getInstanceFieldMap));

    for (var class_ in allClasses) {
      Set<Class> superclasses;

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
          superclasses = <Class>{};
          void collectSupertypes(Class c) {
            if (!superclasses.add(c)) return;
            var s = c.superclass;
            if (s != null) collectSupertypes(s);
            var m = c.mixedInClass;
            if (m != null) collectSupertypes(m);
          }

          collectSupertypes(class_);
          superclasses.remove(class_);
          superclasses.removeWhere((s) => s.enclosingLibrary != library);
        }

        // Look in all super classes to see if we're overriding a field in our
        // library, if so mark that field as overridden.
        var name = member.name.text;
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
    if (class_.isEnum) {
      // Enums are not extensible.
      return false;
    }

    if (!field.name.isPrivate) {
      // Public fields in public classes (or extensible private classes)
      // are always virtual.
      // They could be overridden by someone using our library.
      if (!class_.name.startsWith('_')) return true;
      if (_extensiblePrivateClasses.contains(class_)) return true;
    }

    if (class_.constructors.any((c) => c.isConst)) {
      // Always virtualize fields of a (might be) non-enum (see above) const
      // class.  The way these are lowered by the CFE, they need to be
      // writable from different modules even if overridden.
      return true;
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
  final virtualFields = <Field, js_ast.TemporaryId>{};

  /// The set of inherited getters, used because JS getters/setters are paired,
  /// so if we're generating a setter we may need to emit a getter that calls
  /// super.
  final inheritedGetters = HashSet<String>();

  /// The set of inherited setters, used because JS getters/setters are paired,
  /// so if we're generating a getter we may need to emit a setter that calls
  /// super.
  final inheritedSetters = HashSet<String>();

  final extensionMethods = <String>{};

  final extensionAccessors = <String>{};

  ClassPropertyModel.build(this.types, this.extensionTypes,
      VirtualFieldModel fieldModel, Class class_) {
    // Visit superclasses to collect information about their fields/accessors.
    // This is expensive so we try to collect everything in one pass.
    var superclasses = [class_, ...getSuperclasses(class_)];
    for (var base in superclasses) {
      for (var member in base.members) {
        // Note, we treat noSuchMethodForwarders in the current class as
        // inherited / potentially virtual.  Skip all other members of the
        // current class.
        if (base == class_ &&
            (member is Field ||
                (member is Procedure && !member.isNoSuchMethodForwarder))) {
          continue;
        }

        if (member is Constructor ||
            member is Procedure && (!member.isAccessor || member.isStatic)) {
          continue;
        }

        // Ignore private names from other libraries.
        if (member.name.isPrivate &&
            member.enclosingLibrary != class_.enclosingLibrary) {
          continue;
        }

        var name = member.name.text;
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

    _collectExtensionMembers(class_);

    var virtualAccessorNames = HashSet<String>()
      ..addAll(inheritedGetters)
      ..addAll(inheritedSetters)
      ..addAll(extensionAccessors);

    // Visit accessors in the current class, and see if they need to be
    // generated differently based on the inherited fields/accessors.
    for (var field in class_.fields) {
      // Also ignore abstract fields.
      if (field.isAbstract || field.isStatic) continue;

      var name = field.name.text;
      if (virtualAccessorNames.contains(name) ||
          fieldModel.isVirtual(field) ||
          field.isCovariant ||
          field.isGenericCovariantImpl) {
        virtualFields[field] = js_ast.TemporaryId(name);
      }
    }
  }

  CoreTypes get coreTypes => extensionTypes.coreTypes;

  void _collectExtensionMembers(Class class_) {
    if (extensionTypes.isNativeClass(class_)) return;

    // Find all generic interfaces that could be used to call into members of
    // this class. This will help us identify which parameters need checks
    // for soundness.
    var allNatives = HashSet<String>();
    _collectNativeMembers(class_, allNatives);
    if (allNatives.isEmpty) return;

    // For members on this class, check them against all generic interfaces.
    var seenConcreteMembers = HashSet<String>();
    _findExtensionMembers(class_, seenConcreteMembers, allNatives);

    // For members of the superclass, we may need to add checks because this
    // class adds a new unsafe interface. Collect those checks.
    var visited = HashSet<Class>()..add(class_);
    var existingMembers = HashSet<String>();

    void visitImmediateSuper(Class c) {
      // For members of mixins/supertypes, check them against new interfaces,
      // and also record any existing checks they already had.
      var oldCovariant = HashSet<String>();
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

    if (class_.superclass != null) {
      var mixins = <Class>[];
      var superclass = getSuperclassAndMixins(class_, mixins);
      mixins.forEach(visitImmediateSuper);
      visitImmediateSuper(superclass);
    }
  }

  /// Searches all concrete instance members declared on this type, skipping
  /// already [seenConcreteMembers], and adds them to [extensionMembers] if
  /// needed.
  ///
  /// By tracking the set of seen members, we can visit superclasses and mixins
  /// and ultimately collect every most-derived member exposed by a given type.
  void _findExtensionMembers(
      Class c, HashSet<String> seenConcreteMembers, Set<String> allNatives) {
    // We only visit each most derived concrete member.
    // To avoid visiting an overridden superclass member, we skip members
    // we've seen, and visit starting from the class, then mixins in
    // reverse order, then superclasses.
    for (var m in c.members) {
      var name = m.name.text;
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
      for (var m in c.members) {
        if (!m.name.isPrivate &&
            (m is Procedure && !m.isStatic || m is Field && !m.isStatic)) {
          members.add(m.name.text);
        }
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
}
