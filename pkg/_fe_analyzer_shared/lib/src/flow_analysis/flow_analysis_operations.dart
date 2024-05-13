// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Callback API used by flow analysis to query and manipulate the client's
/// representation of variables and types.
abstract interface class FlowAnalysisOperations<Variable extends Object,
    Type extends Object> implements FlowAnalysisTypeOperations<Type> {
  /// Determines whether the given property can be promoted.
  ///
  /// [property] will correspond to a `propertyMember` value passed to
  /// [FlowAnalysis.promotedPropertyType], [FlowAnalysis.propertyGet], or
  /// [FlowAnalysis.pushPropertySubpattern].
  ///
  /// This method will not be called if field promotion is disabled for the
  /// current library.
  bool isPropertyPromotable(Object property);

  /// Returns the static type of the given [variable].
  Type variableType(Variable variable);

  /// Returns additional information about why a given property couldn't be
  /// promoted. [propertyMember] will correspond to a `propertyMember` value
  /// passed to [FlowAnalysis.promotedPropertyType], [FlowAnalysis.propertyGet],
  /// or [FlowAnalysis.pushPropertySubpattern].
  ///
  /// This method is only called if a closure returned by
  /// [FlowAnalysis.whyNotPromoted] is invoked, and the expression being queried
  /// is a reference to a private property that wasn't promoted; this typically
  /// means that an error occurred and the client is attempting to produce a
  /// context message to provide additional information about the error (i.e.,
  /// that the error happened due to failed promotion).
  ///
  /// The client should return `null` if [property] was not promotable due to a
  /// conflict with a field, getter, or noSuchMethod forwarder elsewhere in the
  /// library; if this happens, the closure returned by
  /// [FlowAnalysis.whyNotPromoted] will yield an object of type
  /// [PropertyNotPromotedForNonInherentReason] containing enough information
  /// for the client to be able to generate the appropriate context information.
  ///
  /// If this method is called when analyzing a library for which field
  /// promotion is disabled, and the property in question *would* have been
  /// promotable if field promotion had been enabled, the client should return
  /// `null`; otherwise it should behave as if field promotion were enabled.
  PropertyNonPromotabilityReason? whyPropertyIsNotPromotable(Object property);
}

/// Callback API used by flow analysis to query and manipulate the client's
/// representation of types.
abstract interface class FlowAnalysisTypeOperations<Type extends Object> {
  /// Returns the client's representation of the type `bool`.
  Type get boolType;

  /// Classifies the given type into one of the three categories defined by
  /// the [TypeClassification] enum.
  TypeClassification classifyType(Type type);

  /// If [type] is an extension type, returns the ultimate representation type.
  /// Otherwise returns [type] as is.
  Type extensionTypeErasure(Type type);

  /// Returns the "remainder" of [from] when [what] has been removed from
  /// consideration by an instance check.
  Type factor(Type from, Type what);

  /// Determines whether the given [type] is equivalent to the `Never` type.
  ///
  /// A type is equivalent to `Never` if it:
  /// (a) is the `Never` type itself.
  /// (b) is a type variable that extends `Never`, OR
  /// (c) is a type variable that has been promoted to `Never`
  bool isNever(Type type);

  /// Return `true` if the [leftType] is a subtype of the [rightType].
  bool isSubtypeOf(Type leftType, Type rightType);

  /// Returns `true` if [type] is a reference to a type parameter.
  bool isTypeParameterType(Type type);

  /// Returns the non-null promoted version of [type].
  ///
  /// Note that some types don't have a non-nullable version (e.g.
  /// `FutureOr<int?>`), so [type] may be returned even if it is nullable.
  Type promoteToNonNull(Type type);

  /// Tries to promote to the first type from the second type, and returns the
  /// promoted type if it succeeds, otherwise null.
  Type? tryPromoteToType(Type to, Type from);
}

/// Possible reasons why a property may not be promotable.
///
/// This enum captures the possible non-promotability reasons that are inherent
/// to the property declaration itself. A property may also be non-promotable
/// because field promotion is disabled, or due to a conflict with another
/// declaration; the code that handles those two reasons doesn't use this enum.
///
/// Some of these reasons are distinguished by [FieldPromotability.addField];
/// others must be distinguished by the client.
enum PropertyNonPromotabilityReason {
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

/// Enum representing the different classifications of types that can be
/// returned by [FlowAnalysisTypeOperations.classifyType].
enum TypeClassification {
  /// The type is `Null` or an equivalent type (e.g. `Never?`)
  nullOrEquivalent,

  /// The type is a potentially nullable type, but not equivalent to `Null`
  /// (e.g. `int?`, or a type variable whose bound is potentially nullable)
  potentiallyNullable,

  /// The type is a non-nullable type.
  nonNullable,
}
