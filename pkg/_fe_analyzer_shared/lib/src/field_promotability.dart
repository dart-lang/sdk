// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/util/dependency_walker.dart';

/// Information about a [Class] that is necessary for computing the set of
/// private `noSuchMethod` forwarding getters the compiler will generate.
///
/// The type parameter [Class] has the same meaning as in [FieldPromotability].
class ClassInfo<Class extends Object> {
  final _InterfaceNode<Class> _interfaceNode;

  final _ImplementedNode<Class> _implementedNode;

  ClassInfo(this._interfaceNode, this._implementedNode);

  Class get _class => _interfaceNode._class;
}

/// Reasons why property accesses having a given field name are non-promotable.
///
/// This class is part of the data structure output by
/// [FieldPromotability.computeNonPromotabilityInfo].
///
/// The type parameters [Class], [Field], and [Getter] have the same meaning as
/// in [FieldPromotability].
class FieldNameNonPromotabilityInfo<Class extends Object, Field, Getter> {
  /// The fields with the given name that are not promotable (either because
  /// they are not final or because they are external).
  ///
  /// (This list is initially empty and
  /// [FieldPromotability.computeNonPromotabilityInfo] accumulates entries into
  /// it.)
  final List<Field> conflictingFields = [];

  /// The explicit concrete getters with the given name.
  ///
  /// (This list is initially empty and
  /// [FieldPromotability.computeNonPromotabilityInfo] accumulates entries into
  /// it.)
  final List<Getter> conflictingGetters = [];

  /// The classes that implicitly forward a getter with the given name to
  /// `noSuchMethod`.
  ///
  /// The purpose of this list is so that the client can generate error messages
  /// that clarify to the user that field promotion was not possible due to
  /// `noSuchMethod` forwarding getters. It is a list of [Class] rather than
  /// [Getter] because `noSuchMethod` forwarding getters are always implicit;
  /// hence the error messages should be associated with the class.
  ///
  /// (This list is initially empty and
  /// [FieldPromotability.computeNonPromotabilityInfo] accumulates entries into
  /// it.)
  final List<Class> conflictingNsmClasses = [];

  FieldNameNonPromotabilityInfo._();
}

/// This class examines all the [Class]es in a library and determines which
/// fields are promotable within that library.
///
/// The type parameters [Class], [Field] and [Getter] should be the data
/// structures used by the client to represent classes, fields, and getters in
/// the user's program. This class treats these types abstractly, so that each
/// concrete Dart implementation can use their own representation of the user's
/// code.
///
/// Note: the term [Class] is used in a general sense here; it can represent any
/// class, mixin, or enum declared in the user's program.
///
/// A field is considered promotable if all of the following are true:
/// - It is final
/// - Its name is private
/// - The library doesn't contain any non-final fields, concrete getters, or
///   `noSuchMethod` getters with the same name.
///
/// These rules were chosen because they are sufficient to determine that all
/// reads of the field that complete normally will either throw an exception,
/// return a single stable object, or return objects with a single stable
/// runtime type; this ensures that type promotion is safe.
///
/// The reason the field must be private is because if it isn't, then at
/// runtime, a read of the field might resolve to a getter or a non-final field
/// in a subclass that's implemented in some other library, and hence the result
/// of the read won't be stable.
///
/// Note that as a result of the third bullet item, any private name that's
/// associated with a non-final field, concrete getter, or `noSuchMethod` getter
/// renders all fields with the same name unpromotable within the library. The
/// reason for this is that since most Dart classes can also be used as
/// interfaces (via an `implements` clause), a read that statically resolves to
/// a private final field might not actually resolve to that field at runtime;
/// it might resolve to some other field or getter with the same name. (In
/// principle it would be possible to narrow the set of possible resolution
/// targets through whole-program analysis, or by careful consideration of class
/// modifiers and public vs. private class names; however that would make the
/// analysis much more complex, and also make it difficult to explain to users
/// when to expect field promotion to work; so we've elected to simply assume
/// that all fields and getters with the same name might potentially alias to
/// one another).
///
/// Since all fields with the same name within the library have the same
/// promotability, this class doesn't attempt to assign a promotability boolean
/// to each field; instead it computes the set of private names for which field
/// promotion is not allowed.
///
/// A word about `noSuchMethod` getters: a `noSuchMethod` getter is a
/// `noSuchMethod` forwarder that implements a getter. The compiler generates
/// `noSuchMethod` forwarders when a concrete [Class] inherits a member into its
/// interface (via an `implements` clause), but it doesn't contain or inherit a
/// concrete implementation of that member. (Note that this is only legal if the
/// class contains or inherits an implementation of `noSuchMethod`). If the name
/// of the inherited member is accessible in the [Class]'s library (i.e. it's
/// either a public name or it's a private name that belongs to the [Class]'s
/// library), then the synthetic `noSuchMethod` forwarder calls `noSuchMethod`
/// and passes along the return value (casting it to the proper type). If the
/// name of the inherited member *isn't* accessible in the [Class]'s library,
/// then the synthetic `noSuchMethod` forwarder throws an exception.
///
/// `noSuchMethod` getters that forward to `noSuchMethod` defeat field promotion
/// for the same reason that ordinary getters do (they aren't guaranteed to
/// return a stable value). However, `noSuchMethod` getters that simply throw an
/// exception do not defeat field promotion, because the exception prevents any
/// code that relies on field promotion soundness from being reachable. Since
/// only private fields are eligible from promotion in the first place, this
/// means that it's only necessary to search the current library for
/// `noSuchMethod` getters that might defeat field promotion (because a
/// `noSuchMethod` getter in another library that's associated with a private
/// name in *this* library will always throw).
///
/// Note that it's possible that one class will have a final field with a given
/// private name, while another class will have a method with the same name (or
/// a `noSuchMethod` forwarder for such a method). If this happens, then an
/// attempt to read the field might at runtime resolve to a tear-off of the
/// corresponding method. This is ok (it's not necessary to suppress promotion
/// of the field), because even though the resulting tear-offs might not be
/// stable in the sense of always being identical, they will nonetheless always
/// have the same runtime type. Hence, we can completely ignore methods when
/// computing which fields in the library are promotable.
abstract class FieldPromotability<Class extends Object, Field, Getter> {
  /// Map whose keys are the field names in the library that have been
  /// determined to be unsafe to promote, and whose values are an instance of
  /// `FieldNameNonPromotabilityInfo` describing why.
  final Map<String, FieldNameNonPromotabilityInfo<Class, Field, Getter>>
      _nonPromotabilityInfo = {};

  /// Map from a [Class] object to the [_ImplementedNode] that records the names
  /// of concrete fields and getters declared in or inherited by the [Class].
  final Map<Class, _ImplementedNode<Class>> _implementedNodes =
      new Map.identity();

  /// Map from a [Class] object to the [_InterfaceNode] that records the names
  /// of getters in the interface for a [Class].
  final Map<Class, _InterfaceNode<Class>> _interfaceNodes = new Map.identity();

  /// List of information about concrete [Class]es in the library.
  final List<ClassInfo<Class>> _concreteInfoList = [];

  /// Records the presence of [class_] in the library. The client should call
  /// this method once for each class, mixin, and enum declared in the library.
  ///
  /// Returns a [ClassInfo] object describing the class. After calling this
  /// method, the client should call [addField] and [addGetter] to record all
  /// the non-synthetic instance fields and getters in the class.
  ClassInfo<Class> addClass(Class class_, {required bool isAbstract}) {
    ClassInfo<Class> classInfo = new ClassInfo<Class>(
        _getInterfaceNode(class_), _getImplementedNode(class_));

    if (!isAbstract) {
      _concreteInfoList.add(classInfo);
    }

    return classInfo;
  }

  /// Records that the [Class] described by [classInfo] contains non-synthetic
  /// instance [field] with the given [name].
  ///
  /// [isFinal] indicates whether the field is a final field. [isAbstract]
  /// indicates whether the field is abstract. [isExternal] indicates whether
  /// the field is external.
  ///
  /// A return value of `null` indicates that this field *might* wind up being
  /// promotable; any other return value indicates the reason why it
  /// *definitely* isn't promotable.
  PropertyNonPromotabilityReason? addField(
      ClassInfo<Class> classInfo, Field field, String name,
      {required bool isFinal,
      required bool isAbstract,
      required bool isExternal}) {
    // Public fields are never promotable, so we may safely ignore fields with
    // public names.
    if (!name.startsWith('_')) {
      return PropertyNonPromotabilityReason.isNotPrivate;
    }

    // Record the field name for later use in computation of `noSuchMethod`
    // getters.
    classInfo._interfaceNode._directNames.add(name);
    if (!isAbstract) {
      classInfo._implementedNode._directNames.add(name);
    }

    if (isExternal || !isFinal) {
      // The field isn't promotable, nor is any other field in the library with
      // the same name.
      _fieldNonPromoInfo(name).conflictingFields.add(field);
      return isExternal
          ? PropertyNonPromotabilityReason.isExternal
          : PropertyNonPromotabilityReason.isNotFinal;
    }

    // The field is final and not external, so it might wind up being
    // promotable.
    return null;
  }

  /// Records that the [Class] described by [classInfo] contains a non-synthetic
  /// instance [getter] with the given [name].
  ///
  /// [isAbstract] indicates whether the getter is abstract.
  ///
  /// Note that unlike [addField], this method does not return a
  /// [PropertyNonPromotabilityReason]. The caller may safely assume that the
  /// reason that getters are not promotable is
  /// [PropertyNonPromotabilityReason.isNotField].
  void addGetter(ClassInfo<Class> classInfo, Getter getter, String name,
      {required bool isAbstract}) {
    // Public fields are never promotable, so we may safely ignore getters with
    // public names.
    if (!name.startsWith('_')) {
      return;
    }

    // Record the getter name for later use in computation of `noSuchMethod`
    // getters.
    classInfo._interfaceNode._directNames.add(name);
    if (!isAbstract) {
      classInfo._implementedNode._directNames.add(name);

      // The getter is concrete, so no fields with the same name are promotable.
      _fieldNonPromoInfo(name).conflictingGetters.add(getter);
    }
  }

  /// Computes the set of private field names which are not safe to promote in
  /// the library, along with the reasons why.
  ///
  /// The client should call this method once after all [Class]es, fields, and
  /// getters have been recorded using [addClass], [addField], and [addGetter].
  Map<String, FieldNameNonPromotabilityInfo<Class, Field, Getter>>
      computeNonPromotabilityInfo() {
    // The names of private non-final fields and private getters have already
    // been added to [_unpromotableFieldNames] by [addField] and [addGetter]. So
    // all that remains to do is figure out which field names are unpromotable
    // due to the presence of `noSuchMethod` getters. To do this, we'll need to
    // walk the class hierarchy and gather (a) the names of private instance
    // getters in each class's interface, and (b) the names of private instance
    // fields and getters in each class's implementation.
    _ClassHierarchyWalker<Class> interfaceWalker =
        new _ClassHierarchyWalker<Class>();
    _ClassHierarchyWalker<Class> implementedWalker =
        new _ClassHierarchyWalker<Class>();

    // For each concrete class in the library,
    for (ClassInfo<Class> info in _concreteInfoList) {
      // Compute names of getters in the interface.
      _InterfaceNode<Class> interfaceNode = info._interfaceNode;
      interfaceWalker.walk(interfaceNode);
      Set<String> interfaceNames = interfaceNode._transitiveNames!;

      // Compute names of actually implemented getters.
      _ImplementedNode<Class> implementedNode = info._implementedNode;
      implementedWalker.walk(implementedNode);
      Set<String> implementedNames = implementedNode._transitiveNames!;

      // `noSuchMethod`-forwarding getters will be generated for getters that
      // are in the interface, but not actually implemented; consequently,
      // fields with these names are not safe to promote.
      for (String name in interfaceNames) {
        if (!implementedNames.contains(name)) {
          _fieldNonPromoInfo(name).conflictingNsmClasses.add(info._class);
        }
      }
    }

    return _nonPromotabilityInfo;
  }

  /// Returns an iterable of the direct superclasses of [class_]. If
  /// [ignoreImplements] is `true`, then superclasses reached through an
  /// `implements` clause are ignored.
  ///
  /// This is used to gather the transitive closure of fields and getters
  /// present in a class's interface and implementation. Therefore, it does not
  /// matter whether the client uses a fully sugared model of mixins (in which
  /// `class C extends B with M1, M2 {}` is represented as a single class with
  /// direct superclasses `B`, `M1`, and `M2`) or a fully desugared model (in
  /// which `class C extends B with M1, M2` represents a class `C` with
  /// superclass `B&M1&M2`, which in turn has supertypes `B&M1` and `M2`, etc.)
  Iterable<Class> getSuperclasses(Class class_,
      {required bool ignoreImplements});

  /// Gets the [FieldNameNonPromotabilityInfo] object corresponding to [name]
  /// from [_nonPromotabilityInfo], creating it if necessary.
  FieldNameNonPromotabilityInfo<Class, Field, Getter> _fieldNonPromoInfo(
          String name) =>
      _nonPromotabilityInfo.putIfAbsent(name, FieldNameNonPromotabilityInfo._);

  /// Gets or creates the [_ImplementedNode] for [class_].
  _ImplementedNode<Class> _getImplementedNode(Class class_) =>
      _implementedNodes[class_] ??= new _ImplementedNode<Class>(this, class_);

  /// Gets or creates the [_InterfaceNode] for [class_].
  _InterfaceNode<Class> _getInterfaceNode(Class class_) =>
      _interfaceNodes[class_] ??= new _InterfaceNode<Class>(this, class_);
}

/// Possible reasons why a field property may not be promotable.
///
/// Some of these reasons are distinguished by [FieldPromotability.addField];
/// others must be distinguished by the client.
enum PropertyNonPromotabilityReason {
  /// The property is not promotable because field promotion is not enabled for
  /// the enclosing library.
  isNotEnabled,

  /// The property is not promotable because it's not a field (it's either a
  /// getter or a tear-off of a method).
  isNotField,

  /// The property is not promotable because its name is public.
  isNotPrivate,

  /// The property is not promotable because it's an external field.
  isExternal,

  /// The property is not promotable because it's a non-final field.
  isNotFinal,
}

/// Dependency walker that traverses the graph of a class's type hierarchy,
/// gathering the transitive closure of field and getter names.
///
/// This is based on the [DependencyWalker] class, which implements Tarjan's
/// strongly connected component's algorithm in order to efficiently handle
/// cycles in the class hierarchy (which the analyzer tolerates).
class _ClassHierarchyWalker<Class extends Object>
    extends DependencyWalker<_Node<Class>> {
  @override
  void evaluate(_Node<Class> v) => evaluateScc([v]);

  @override
  void evaluateScc(List<_Node<Class>> scc) {
    // Gather the names directly declared in all the classes in this strongly
    // connected component, plus all the names in the transitive closure of the
    // strongly connected components this component depends on.
    Set<String> transitiveNames = <String>{};
    for (_Node<Class> node in scc) {
      transitiveNames.addAll(node._directNames);
      for (_Node<Class> dependency in Node.getDependencies(node)) {
        Set<String>? namesFromDependency = dependency._transitiveNames;
        if (namesFromDependency != null) {
          transitiveNames.addAll(namesFromDependency);
        }
      }
    }
    // Store this list of names in all the nodes of this strongly connected
    // component.
    for (_Node<Class> node in scc) {
      node._transitiveNames = transitiveNames;
    }
  }
}

/// Data structure tracking the set of private fields and getters a [Class]
/// concretely implements.
///
/// This data structure extends [_Node] so that we can efficiently walk the
/// superclass chain (without having to worry about circularities) in order to
/// include getters concretely implemented in superclasses and mixins.
class _ImplementedNode<Class extends Object> extends _Node<Class> {
  _ImplementedNode(super.fieldPromotability, super.element);

  @override
  List<_Node<Class>> computeDependencies() {
    // We need to gather field and getter names from the transitive closure of
    // superclasses, following `with` and `extends` edges but not `implements`
    // edges. So the set of dependencies of this node is the set of immediate
    // superclasses, ignoring `implements`.
    List<_Node<Class>> dependencies = [];
    for (Class supertype in _fieldPromotability.getSuperclasses(_class,
        ignoreImplements: true)) {
      dependencies.add(_fieldPromotability._getImplementedNode(supertype));
    }
    return dependencies;
  }
}

/// Data structure tracking the set of getters in a [Class]'s interface.
///
/// This data structure extends [_Node] so that we can efficiently walk the
/// class hierarchy (without having to worry about circularities) in order to
/// include getters defined in superclasses, mixins, and interfaces.
class _InterfaceNode<Class extends Object> extends _Node<Class> {
  _InterfaceNode(super.fieldPromotability, super.element);

  @override
  List<_Node<Class>> computeDependencies() {
    // We need to gather field and getter names from the transitive closure of
    // superclasses, following `with`, `extends`, `implements`, and `on` edges.
    // So the set of dependencies of this node is the set of immediate
    // superclasses, including `implements`.
    List<_Node<Class>> dependencies = [];
    for (Class supertype in _fieldPromotability.getSuperclasses(_class,
        ignoreImplements: false)) {
      dependencies.add(_fieldPromotability._getInterfaceNode(supertype));
    }
    return dependencies;
  }
}

/// A node in either the graph of a class's type hierarchy, recording the
/// information necessary for computing the set of private `noSuchMethod`
/// getters the compiler will generate.
abstract class _Node<Class extends Object> extends Node<_Node<Class>> {
  /// A reference back to the [FieldPromotability] object.
  final FieldPromotability<Class, Object?, Object?> _fieldPromotability;

  /// The [Class] represented by this node.
  final Class _class;

  /// The names of getters declared by [_class] directly.
  final Set<String> _directNames = {};

  /// The names of getters declared by [_class] and its superinterfaces.
  ///
  /// Populated when [_ClassHierarchyWalker] encounters a strongly connected
  /// component.
  Set<String>? _transitiveNames;

  _Node(this._fieldPromotability, this._class);

  @override
  bool get isEvaluated => _transitiveNames != null;
}
