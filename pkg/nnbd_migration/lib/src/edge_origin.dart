// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:nnbd_migration/instrumentation.dart';

/// Edge origin resulting from a type in already-migrated code.
///
/// For example, in the Map class in dart:core:
///   V? operator [](Object key);
///
/// this class is used for the edge connecting `always` to the return type of
/// `operator []`, due to the fact that dart:core has already been migrated and
/// the type is explicitly nullable.
///
/// Note that since a single element can have a complex type, it is likely that
/// multiple edges will be created with an [AlreadyMigratedTypeOrigin] pointing
/// to the same type.  To distinguish which edge corresponds to which part of
/// the element's type, use the callbacks
/// [NullabilityMigrationInstrumentation.externalDecoratedType] and
/// [NullabilityMigrationInstrumentation.externalDecoratedTypeParameterBound].
class AlreadyMigratedTypeOrigin extends EdgeOrigin {
  AlreadyMigratedTypeOrigin.forElement(Element element)
      : super.forElement(element);

  @override
  EdgeOriginKind get kind => EdgeOriginKind.alreadyMigratedType;
}

/// Edge origin resulting from the use of a type that is always nullable.
///
/// For example, in the following code snippet:
///   void f(dynamic x) {}
///
/// this class is used for the edge connecting `always` to the type of f's `x`
/// parameter, due to the fact that the `dynamic` type is always considered
/// nullable.
class AlwaysNullableTypeOrigin extends EdgeOrigin {
  AlwaysNullableTypeOrigin(Source source, AstNode node) : super(source, node);

  AlwaysNullableTypeOrigin.forElement(Element element)
      : super.forElement(element);

  @override
  EdgeOriginKind get kind => EdgeOriginKind.alwaysNullableType;
}

/// Edge origin resulting from the use of a value on the LHS of a compound
/// assignment.
class CompoundAssignmentOrigin extends EdgeOrigin {
  CompoundAssignmentOrigin(Source source, AssignmentExpression node)
      : super(source, node);

  @override
  EdgeOriginKind get kind => EdgeOriginKind.compoundAssignment;

  @override
  AssignmentExpression get node => super.node as AssignmentExpression;
}

/// An edge origin used for edges that originated because of a default value on
/// a parameter.
class DefaultValueOrigin extends EdgeOrigin {
  DefaultValueOrigin(Source source, Expression node) : super(source, node);

  @override
  EdgeOriginKind get kind => EdgeOriginKind.defaultValue;
}

/// An edge origin used for edges that originated because of an assignment
/// involving a value with a dynamic type.
class DynamicAssignmentOrigin extends EdgeOrigin {
  DynamicAssignmentOrigin(Source source, AstNode node) : super(source, node);

  @override
  EdgeOriginKind get kind => EdgeOriginKind.dynamicAssignment;
}

/// Common interface for classes providing information about how an edge came
/// to be; that is, what was found in the source code that led the migration
/// tool to create the edge.
abstract class EdgeOrigin extends EdgeOriginInfo {
  @override
  final Source source;

  @override
  final AstNode node;

  @override
  final Element element;

  EdgeOrigin(this.source, this.node) : element = null;

  EdgeOrigin.forElement(this.element)
      : source = null,
        node = null;
}

/// An edge origin used for edges that originated because of a reference to an
/// enum value, which cannot be null.
class EnumValueOrigin extends EdgeOrigin {
  EnumValueOrigin(Source source, AstNode node) : super(source, node);

  @override
  EdgeOriginKind get kind => EdgeOriginKind.enumValue;
}

/// Edge origin resulting from the relationship between a field formal parameter
/// and the corresponding field.
class FieldFormalParameterOrigin extends EdgeOrigin {
  FieldFormalParameterOrigin(Source source, FieldFormalParameter node)
      : super(source, node);

  @override
  EdgeOriginKind get kind => EdgeOriginKind.fieldFormalParameter;
}

/// An edge origin used for edges that originated because a field was not
/// initialized.
///
/// The AST node associated with the edge is the AST node for the constructor
/// that failed to initialize the field (or the class, if the constructor is
/// synthetic).
class FieldNotInitializedOrigin extends EdgeOrigin {
  FieldNotInitializedOrigin(Source source, AstNode node) : super(source, node);

  @override
  EdgeOriginKind get kind => EdgeOriginKind.fieldNotInitialized;
}

/// Edge origin resulting from the use of an iterable type in a for-each loop.
///
/// For example, in the following code snippet:
///   void f(Iterable<int> l) {
///     for (int i in l) {}
///   }
///
/// this class is used for the edge connecting the type of `l`'s `int` type
/// parameter to the type of `i`.
class ForEachVariableOrigin extends EdgeOrigin {
  ForEachVariableOrigin(Source source, ForEachParts node) : super(source, node);

  @override
  EdgeOriginKind get kind => EdgeOriginKind.forEachVariable;
}

/// Edge origin resulting from the use of greatest lower bound.
///
/// For example, in the following code snippet:
///   void Function(int) f(void Function(int) x, void Function(int) y)
///       => x ?? y;
///
/// the `int` in the return type is nullable if both the `int`s in the types of
/// `x` and `y` are nullable, due to the fact that the `int` in the return type
/// is the greatest lower bound of the two other `int`s.
class GreatestLowerBoundOrigin extends EdgeOrigin {
  GreatestLowerBoundOrigin(Source source, AstNode node) : super(source, node);

  @override
  EdgeOriginKind get kind => EdgeOriginKind.greatestLowerBound;
}

/// Edge origin resulting from the presence of a `??` operator.
class IfNullOrigin extends EdgeOrigin {
  IfNullOrigin(Source source, AstNode node) : super(source, node);

  @override
  EdgeOriginKind get kind => EdgeOriginKind.ifNull;
}

/// Edge origin resulting from the implicit call from a mixin application
/// constructor to the corresponding super constructor.
///
/// For example, in the following code snippet:
///   class C {
///     C(int i);
///   }
///   mixin M {}
///   class D = C with M;
///
/// this class is used for the edge connecting the types of the `i` parameters
/// between the implicit constructor for `D` and the explicit constructor for
/// `C`.
class ImplicitMixinSuperCallOrigin extends EdgeOrigin {
  ImplicitMixinSuperCallOrigin(Source source, ClassTypeAlias node)
      : super(source, node);

  @override
  EdgeOriginKind get kind => EdgeOriginKind.implicitMixinSuperCall;
}

/// Edge origin resulting from the implicit assignment of `null` to a top level
/// variable or field that lacks an initializer.
class ImplicitNullInitializerOrigin extends EdgeOrigin {
  ImplicitNullInitializerOrigin(Source source, AstNode node)
      : super(source, node);

  @override
  EdgeOriginKind get kind => EdgeOriginKind.implicitNullInitializer;
}

/// Edge origin resulting from a type that is inferred from its initializer.
class InitializerInferenceOrigin extends EdgeOrigin {
  InitializerInferenceOrigin(Source source, VariableDeclaration node)
      : super(source, node);

  @override
  EdgeOriginKind get kind => EdgeOriginKind.initializerInference;
}

/// An edge origin used for edges that originated because of an instance
/// creation expression.
class InstanceCreationOrigin extends EdgeOrigin {
  InstanceCreationOrigin(Source source, AstNode node) : super(source, node);

  @override
  EdgeOriginKind get kind => EdgeOriginKind.instanceCreation;
}

/// Edge origin resulting from a class that is instantiated to bounds.
///
/// For example, in the following code snippet:
///   class C<T extends Object> {}
///   C x;
///
/// this class is used for the edge connecting the type of x's type parameter
/// with the type bound in the declaration of C.
class InstantiateToBoundsOrigin extends EdgeOrigin {
  InstantiateToBoundsOrigin(Source source, TypeName node) : super(source, node);

  @override
  EdgeOriginKind get kind => EdgeOriginKind.instantiateToBounds;
}

/// Edge origin resulting from the use of a type as the main type in an 'is'
/// check.
///
/// Before the migration, there was no way to say `is int?`, and therefore,
/// `is int` should migrate to non-null int.
class IsCheckMainTypeOrigin extends EdgeOrigin {
  IsCheckMainTypeOrigin(Source source, TypeAnnotation node)
      : super(source, node);

  @override
  EdgeOriginKind get kind => EdgeOriginKind.isCheckMainType;
}

/// An edge origin used for the type argument of a list constructor that
/// specified an initial length, because that type argument must be nullable.
class ListLengthConstructorOrigin extends EdgeOrigin {
  ListLengthConstructorOrigin(Source source, AstNode node)
      : super(source, node);

  @override
  EdgeOriginKind get kind => EdgeOriginKind.listLengthConstructor;
}

/// An edge origin used for edges that originated because a literal expression
/// has a known nullability.
class LiteralOrigin extends EdgeOrigin {
  LiteralOrigin(Source source, AstNode node) : super(source, node);

  @override
  EdgeOriginKind get kind => EdgeOriginKind.literal;
}

/// Edge origin resulting from a call site that does not supply a named
/// parameter.
///
/// For example, in the following code snippet:
///   void f({int i}) {}
///   main() {
///     f();
///   }
///
/// this class is used for the edge connecting `always` to the type of f's `i`
/// parameter, due to the fact that the call to `f` implicitly passes a null
/// value for `i`.
class NamedParameterNotSuppliedOrigin extends EdgeOrigin {
  NamedParameterNotSuppliedOrigin(Source source, AstNode node)
      : super(source, node);

  @override
  EdgeOriginKind get kind => EdgeOriginKind.namedParameterNotSupplied;
}

/// Edge origin for the nullability of an expression that whose type is fixed by
/// the language definition to be non-nullable `bool`.
class NonNullableBoolTypeOrigin extends EdgeOrigin {
  NonNullableBoolTypeOrigin(Source source, AstNode node) : super(source, node);

  @override
  EdgeOriginKind get kind => EdgeOriginKind.nonNullableBoolType;
}

/// Edge origin resulting from the class/superclass relationship for a class
/// whose superclass is implicitly `Object`.
class NonNullableObjectSuperclass extends EdgeOrigin {
  NonNullableObjectSuperclass(Source source, AstNode node)
      : super(source, node);

  @override
  EdgeOriginKind get kind => EdgeOriginKind.nonNullableObjectSuperclass;
}

/// Edge origin resulting from the usage of a value in a circumstance that
/// requires it to be non-nullable
class NonNullableUsageOrigin extends EdgeOrigin {
  NonNullableUsageOrigin(Source source, AstNode node) : super(source, node);

  @override
  EdgeOriginKind get kind => EdgeOriginKind.nonNullableUsage;
}

/// Edge origin resulting from the presence of a non-null assertion.
///
/// For example, in the following code snippet:
///   void f(int i) {
///     assert(i != null);
///   }
///
/// this class is used for the edge connecting the type of f's `i` parameter to
/// `never`, due to the assert statement proclaiming that `i` is not `null`.
class NonNullAssertionOrigin extends EdgeOrigin {
  NonNullAssertionOrigin(Source source, Assertion node) : super(source, node);

  @override
  EdgeOriginKind get kind => EdgeOriginKind.nonNullAssertion;
}

/// Edge origin resulting from the presence of an explicit nullability hint
/// comment.
///
/// For example, in the following code snippet:
///   void f(int/*?*/ i) {}
///
/// this class is used for the edge connecting `always` to the type of f's `i`
/// parameter, due to the presence of the `/*?*/` comment.
class NullabilityCommentOrigin extends EdgeOrigin {
  NullabilityCommentOrigin(Source source, TypeAnnotation node)
      : super(source, node);

  @override
  EdgeOriginKind get kind => EdgeOriginKind.nullabilityComment;
}

/// Edge origin resulting from the presence of an optional formal parameter.
///
/// For example, in the following code snippet:
///   void f({int i}) {}
///
/// this class is used for the edge connecting `always` to the type of f's `i`
/// parameter, due to the fact that `i` is optional and has no initializer.
class OptionalFormalParameterOrigin extends EdgeOrigin {
  OptionalFormalParameterOrigin(Source source, DefaultFormalParameter node)
      : super(source, node);

  @override
  EdgeOriginKind get kind => EdgeOriginKind.optionalFormalParameter;
}

/// Edge origin resulting from an inheritance relationship between two method
/// parameters.
class ParameterInheritanceOrigin extends EdgeOrigin {
  ParameterInheritanceOrigin(Source source, AstNode node) : super(source, node);

  @override
  EdgeOriginKind get kind => EdgeOriginKind.parameterInheritance;
}

/// Edge origin resulting from an inheritance relationship between two method
/// return types.
class ReturnTypeInheritanceOrigin extends EdgeOrigin {
  ReturnTypeInheritanceOrigin(Source source, AstNode node)
      : super(source, node);

  @override
  EdgeOriginKind get kind => EdgeOriginKind.returnTypeInheritance;
}

/// Edge origin resulting from the use of a stacktrace parameter in a catch
/// directive.  The type of such parameters is fixed by the language as
/// non-nullable `StackTrace`.
class StackTraceTypeOrigin extends EdgeOrigin {
  StackTraceTypeOrigin(Source source, AstNode node) : super(source, node);

  @override
  EdgeOriginKind get kind => EdgeOriginKind.stackTraceTypeOrigin;
}

/// Edge origin resulting from the use of `this` or `super`.
class ThisOrSuperOrigin extends EdgeOrigin {
  ThisOrSuperOrigin(Source source, AstNode node) : super(source, node);

  @override
  EdgeOriginKind get kind => EdgeOriginKind.thisOrSuper;
}

/// An edge origin used for edges that originated from the type of a `throw` or
/// `rethrow`.
class ThrowOrigin extends EdgeOrigin {
  ThrowOrigin(Source source, AstNode node) : super(source, node);

  @override
  EdgeOriginKind get kind => EdgeOriginKind.throw_;
}

/// Edge origin resulting from a usage of a typedef.
///
/// Since typedefs require multiple phases to resolve, they are represented by
/// a set of inferred nodes. In the secondary phases of graph build, those get
/// unioned with references to the nodes referring to source code. The origin of
/// those union edges will be [TypedefReferenceOrigin].
class TypedefReferenceOrigin extends EdgeOrigin {
  TypedefReferenceOrigin(Source source, TypeName node) : super(source, node);

  @override
  EdgeOriginKind get kind => EdgeOriginKind.typedefReference;
}

/// Edge origin resulting from the read of a variable that has not been
/// definitely assigned a value.
class UninitializedReadOrigin extends EdgeOrigin {
  UninitializedReadOrigin(Source source, AstNode node) : super(source, node);

  @override
  EdgeOriginKind get kind => EdgeOriginKind.uninitializedRead;
}
