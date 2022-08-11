// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Enum representing the different classifications of types that can be
/// returned by [TypeOperations.classifyType].
enum TypeClassification {
  /// The type is `Null` or an equivalent type (e.g. `Never?`)
  nullOrEquivalent,

  /// The type is a potentially nullable type, but not equivalent to `Null`
  /// (e.g. `int?`, or a type variable whose bound is potentially nullable)
  potentiallyNullable,

  /// The type is a non-nullable type.
  nonNullable,
}

/// Operations on types, abstracted from concrete type interfaces.
///
/// This mixin provides default implementations for some members that won't need
/// to be overridden very frequently.
mixin TypeOperations<Type extends Object> {
  /// Classifies the given type into one of the three categories defined by
  /// the [TypeClassification] enum.
  TypeClassification classifyType(Type type);

  /// Returns the "remainder" of [from] when [what] has been removed from
  /// consideration by an instance check.
  Type factor(Type from, Type what);

  /// Whether the possible promotion from [from] to [to] should be forced, given
  /// the current [promotedTypes], and [newPromotedTypes] resulting from
  /// possible demotion.
  ///
  /// It is not expected that any implementation would override this except for
  /// the migration engine.
  bool forcePromotion(Type to, Type from, List<Type>? promotedTypes,
          List<Type>? newPromotedTypes) =>
      false;

  /// Determines whether the given [type] is equivalent to the `Never` type.
  ///
  /// A type is equivalent to `Never` if it:
  /// (a) is the `Never` type itself.
  /// (b) is a type variable that extends `Never`, OR
  /// (c) is a type variable that has been promoted to `Never`
  bool isNever(Type type);

  /// Returns `true` if [type1] and [type2] are the same type.
  bool isSameType(Type type1, Type type2);

  /// Return `true` if the [leftType] is a subtype of the [rightType].
  bool isSubtypeOf(Type leftType, Type rightType);

  /// Returns `true` if [type] is a reference to a type parameter.
  bool isTypeParameterType(Type type);

  /// Returns the non-null promoted version of [type].
  ///
  /// Note that some types don't have a non-nullable version (e.g.
  /// `FutureOr<int?>`), so [type] may be returned even if it is nullable.
  Type /*!*/ promoteToNonNull(Type type);

  /// Performs refinements on the [promotedTypes] chain which resulted in
  /// intersecting [chain1] and [chain2].
  ///
  /// It is not expected that any implementation would override this except for
  /// the migration engine.
  List<Type>? refinePromotedTypes(
          List<Type>? chain1, List<Type>? chain2, List<Type>? promotedTypes) =>
      promotedTypes;

  /// Tries to promote to the first type from the second type, and returns the
  /// promoted type if it succeeds, otherwise null.
  Type? tryPromoteToType(Type to, Type from);
}
