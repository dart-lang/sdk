// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../types.dart';

/// Interface implemented by analyzer/CFE to support [StaticType]s for sealed
/// classes.
abstract class SealedClassOperations<Type extends Object,
    Class extends Object> {
  /// Returns the sealed class declaration for [type] or `null` if [type] is not
  /// a sealed class type.
  Class? getSealedClass(Type type);

  /// Returns the direct subclasses of [sealedClass] that either extend,
  /// implement or mix it in.
  List<Class> getDirectSubclasses(Class sealedClass);

  /// Returns the instance of [subClass] that implements [sealedClassType].
  ///
  /// `null` might be returned if [subClass] cannot implement [sealedClassType].
  /// For instance
  ///
  ///     sealed class A<T> {}
  ///     class B<T> extends A<T> {}
  ///     class C extends A<int> {}
  ///
  /// here `C` has no implementation of `A<String>`.
  ///
  /// It is assumed that `TypeOperations.isSealedClass` is `true` for
  /// [sealedClassType] and that [subClass] is in `getDirectSubclasses` for
  /// `getSealedClass` of [sealedClassType].
  Type? getSubclassAsInstanceOf(Class subClass, Type sealedClassType);
}

/// [SealedClassInfo] stores information to compute the static type for a
/// sealed class.
class SealedClassInfo<Type extends Object, Class extends Object> {
  final SealedClassOperations<Type, Class> _sealedClassOperations;
  final Class _sealedClass;
  List<Class>? _subClasses;

  SealedClassInfo(this._sealedClassOperations, this._sealedClass);

  /// Returns the classes that directly extends, implements or mix in
  /// [_sealedClass].
  Iterable<Class> get subClasses =>
      _subClasses ??= _sealedClassOperations.getDirectSubclasses(_sealedClass);
}

/// [StaticType] for a sealed class type.
class SealedClassStaticType<Type extends Object, Class extends Object>
    extends TypeBasedStaticType<Type> {
  final ExhaustivenessCache<Type, dynamic, dynamic, dynamic, Class> _cache;
  final SealedClassOperations<Type, Class> _sealedClassOperations;
  final SealedClassInfo<Type, Class> _sealedInfo;
  Iterable<StaticType>? _subtypes;

  SealedClassStaticType(super.typeOperations, super.fieldLookup, super.type,
      this._cache, this._sealedClassOperations, this._sealedInfo)
      : super(isImplicitlyNullable: false);

  @override
  bool get isSealed => true;

  @override
  Iterable<StaticType> getSubtypes(Set<Key> keysOfInterest) =>
      _subtypes ??= _createSubtypes();

  List<StaticType> _createSubtypes() {
    List<StaticType> subtypes = [];
    for (Class subClass in _sealedInfo.subClasses) {
      Type? subtype =
          _sealedClassOperations.getSubclassAsInstanceOf(subClass, _type);
      if (subtype != null) {
        if (!_typeOperations.isGeneric(subtype)) {
          // If the subtype is not generic, we can test whether it can be an
          // actual value of [_type] by testing whether it is a subtype of the
          // overapproximation of [_type].
          //
          // For instance
          //
          //     sealed class A<T> {}
          //     class B extends A<num> {}
          //     class C<T extends num> A<T> {}
          //
          //     method<T extends String>(A<T> a) {
          //       switch (a) {
          //         case B: // Not needed, B cannot inhabit A<T>.
          //         case C: // Needed, C<Never> inhabits A<T>.
          //       }
          //     }
          if (!_typeOperations.isSubtypeOf(
              subtype, _typeOperations.overapproximate(_type))) {
            continue;
          }
        }
        StaticType staticType = _cache.getStaticType(subtype);
        // Since the type of the [subtype] might not itself be a subtype of
        // [_type], for instance in the example above the type of `case C:`,
        // `C<num>`, is not a subtype of `A<T>`, we wrap the static type
        // to establish the subtype relation between the [StaticType] for the
        // enum element and this [StaticType].
        subtypes.add(new WrappedStaticType(staticType, this));
      }
    }
    return subtypes;
  }
}
