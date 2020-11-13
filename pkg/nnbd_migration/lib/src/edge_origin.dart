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
  /// Indicates whether the already-migrated type is nullable or not.
  final bool isNullable;

  AlreadyMigratedTypeOrigin.forElement(Element element, this.isNullable)
      : super.forElement(element);

  @override
  String get description => '${isNullable ? 'nullable' : 'non-nullable'}'
      ' type in already-migrated code';

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
  /// Indicates whether the always-nullable type is the `void` type (if `false`,
  /// it is the `dynamic` type).
  final bool isVoid;

  AlwaysNullableTypeOrigin(Source source, AstNode node, this.isVoid)
      : super(source, node);

  AlwaysNullableTypeOrigin.forElement(Element element, this.isVoid)
      : super.forElement(element);

  @override
  String get description =>
      '${isVoid ? 'void' : 'dynamic'} type is nullable by definition';

  @override
  EdgeOriginKind get kind => EdgeOriginKind.alwaysNullableType;
}

/// Edge origin resulting from the presence of a call to
/// `ArgumentError.checkNotNull`.
///
/// For example, in the following code snippet:
///   void f(int i) {
///     ArgumentError.checkNotNull(i);
///   }
///
/// this class is used for the edge connecting the type of f's `i` parameter to
/// `never`, due to the `checkNotNull` call proclaiming that `i` is not `null`.
class ArgumentErrorCheckNotNullOrigin extends EdgeOrigin {
  ArgumentErrorCheckNotNullOrigin(Source source, SimpleIdentifier node)
      : super(source, node);

  @override
  String get description => 'value checked to be non-null';

  @override
  EdgeOriginKind get kind => EdgeOriginKind.argumentErrorCheckNotNull;
}

/// Edge origin resulting from the use of a value on the LHS of a compound
/// assignment.
class CompoundAssignmentOrigin extends EdgeOrigin {
  CompoundAssignmentOrigin(Source source, AssignmentExpression node)
      : super(source, node);

  @override
  String get description => 'compound assignment';

  @override
  EdgeOriginKind get kind => EdgeOriginKind.compoundAssignment;

  @override
  AssignmentExpression get node => super.node as AssignmentExpression;
}

/// Edge origin resulting from the use of an element which does not affect the
/// nullability graph in other ways.
class DummyOrigin extends EdgeOrigin {
  DummyOrigin(Source source, AstNode node) : super(source, node);

  @override
  String get description => 'dummy';

  @override
  EdgeOriginKind get kind => EdgeOriginKind.dummy;
}

/// An edge origin used for edges that originated because of an assignment
/// involving a value with a dynamic type.
class DynamicAssignmentOrigin extends EdgeOrigin {
  DynamicAssignmentOrigin(Source source, AstNode node) : super(source, node);

  @override
  String get description => 'assignment of dynamic value';

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

  /// Retrieves the location in the source code that caused this edge to be
  /// created, or `null` if unknown.
  CodeReference get codeReference {
    if (node != null) {
      return CodeReference.fromAstNode(node);
    }
    return null;
  }

  /// User-friendly description of the edge.
  String get description;
}

/// An edge origin used for edges that originated because of a reference to an
/// enum value, which cannot be null.
class EnumValueOrigin extends EdgeOrigin {
  EnumValueOrigin(Source source, AstNode node) : super(source, node);

  @override
  String get description => 'non-nullable enum value';

  @override
  EdgeOriginKind get kind => EdgeOriginKind.enumValue;
}

/// Edge origin resulting from the relationship between a field formal parameter
/// and the corresponding field.
class FieldFormalParameterOrigin extends EdgeOrigin {
  FieldFormalParameterOrigin(Source source, FieldFormalParameter node)
      : super(source, node);

  @override
  String get description => 'field formal parameter';

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
  String get description => 'field not initialized';

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
  String get description => 'variable in "for each" loop';

  @override
  EdgeOriginKind get kind => EdgeOriginKind.forEachVariable;
}

/// Edge origin resulting from the relationship between a getter and a setter.
class GetterSetterCorrespondenceOrigin extends EdgeOrigin {
  GetterSetterCorrespondenceOrigin(Source source, AstNode node)
      : super(source, node);

  @override
  String get description => 'getter/setter correspondence';

  @override
  EdgeOriginKind get kind => EdgeOriginKind.getterSetterCorrespondence;
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
  String get description => 'greatest lower bound';

  @override
  EdgeOriginKind get kind => EdgeOriginKind.greatestLowerBound;
}

/// Edge origin resulting from the presence of a `??` operator.
class IfNullOrigin extends EdgeOrigin {
  IfNullOrigin(Source source, AstNode node) : super(source, node);

  @override
  String get description => 'if-null operator';

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
  String get description => 'implicit super call in mixin constructor';

  @override
  EdgeOriginKind get kind => EdgeOriginKind.implicitMixinSuperCall;
}

/// Edge origin resulting from the implicit assignment of `null` to a top level
/// variable or field that lacks an initializer.
class ImplicitNullInitializerOrigin extends EdgeOrigin {
  ImplicitNullInitializerOrigin(Source source, AstNode node)
      : super(source, node);

  @override
  String get description => 'uninitialized variable';

  @override
  EdgeOriginKind get kind => EdgeOriginKind.implicitNullInitializer;
}

/// Edge origin resulting from a `return;` statement which implicitly returns
/// `null`.
class ImplicitNullReturnOrigin extends EdgeOrigin {
  ImplicitNullReturnOrigin(Source source, ReturnStatement node)
      : super(source, node);

  @override
  String get description => 'implicit return of null';

  @override
  EdgeOriginKind get kind => EdgeOriginKind.implicitNullReturn;

  @override
  ReturnStatement get node => super.node as ReturnStatement;
}

/// Edge origin resulting from the inference of a type parameter, which
/// can affects the nullability of that type parameter's bound.
class InferredTypeParameterInstantiationOrigin extends EdgeOrigin {
  InferredTypeParameterInstantiationOrigin(Source source, AstNode node)
      : super(source, node);

  @override
  String get description => 'inferred type parameter';

  @override
  EdgeOriginKind get kind => EdgeOriginKind.inferredTypeParameterInstantiation;
}

/// An edge origin used for edges that originated because of an instance
/// creation expression.
class InstanceCreationOrigin extends EdgeOrigin {
  InstanceCreationOrigin(Source source, AstNode node) : super(source, node);

  @override
  String get description => 'instance creation';

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
  String get description => 'type instantiated to bounds';

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
  String get description => '"is" check does not accept null';

  @override
  EdgeOriginKind get kind => EdgeOriginKind.isCheckMainType;
}

/// An edge origin used for the return type of an iterator method that might be
/// changed into an extension method from package:collection.
class IteratorMethodReturnOrigin extends EdgeOrigin {
  IteratorMethodReturnOrigin(Source source, AstNode node) : super(source, node);

  @override
  String get description =>
      'Call to iterator method with orElse that returns null';

  @override
  EdgeOriginKind get kind => EdgeOriginKind.iteratorMethodReturn;
}

/// An edge origin used for the type argument of a list constructor that
/// specified an initial length, because that type argument must be nullable.
class ListLengthConstructorOrigin extends EdgeOrigin {
  ListLengthConstructorOrigin(Source source, AstNode node)
      : super(source, node);

  @override
  String get description => 'construction of list via a length';

  @override
  EdgeOriginKind get kind => EdgeOriginKind.listLengthConstructor;
}

/// An edge origin used for edges that originated because of a tear-off of
/// `call` on a function type.
class CallTearOffOrigin extends EdgeOrigin {
  CallTearOffOrigin(Source source, AstNode node) : super(source, node);

  @override
  String get description => 'tear-off of .call';

  @override
  EdgeOriginKind get kind => EdgeOriginKind.callTearOff;
}

/// An edge origin used for edges that originated because a literal expression
/// has a known nullability.
class LiteralOrigin extends EdgeOrigin {
  LiteralOrigin(Source source, AstNode node) : super(source, node);

  @override
  String get description => 'literal expression';

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
  String get description => 'named parameter not supplied';

  @override
  EdgeOriginKind get kind => EdgeOriginKind.namedParameterNotSupplied;
}

/// Edge origin for the nullability of an expression that whose type is fixed by
/// the language definition to be non-nullable `bool`.
class NonNullableBoolTypeOrigin extends EdgeOrigin {
  NonNullableBoolTypeOrigin(Source source, AstNode node) : super(source, node);

  @override
  String get description => 'non-null boolean expression';

  @override
  EdgeOriginKind get kind => EdgeOriginKind.nonNullableBoolType;
}

/// Edge origin resulting from the class/superclass relationship for a class
/// whose superclass is implicitly `Object`.
class NonNullableObjectSuperclass extends EdgeOrigin {
  NonNullableObjectSuperclass(Source source, AstNode node)
      : super(source, node);

  @override
  String get description => 'implicit supertype of Object';

  @override
  EdgeOriginKind get kind => EdgeOriginKind.nonNullableObjectSuperclass;
}

/// Edge origin resulting from the usage of a value in a circumstance that
/// requires it to be non-nullable
class NonNullableUsageOrigin extends EdgeOrigin {
  NonNullableUsageOrigin(Source source, AstNode node) : super(source, node);

  @override
  String get description => 'value cannot be null';

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
  String get description => 'value asserted to be non-null';

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
  /// Indicates whether the nullability comment makes the type nullable or
  /// non-nullable.
  final bool isNullable;

  NullabilityCommentOrigin(Source source, AstNode node, this.isNullable)
      : assert(node is TypeAnnotation ||
            node is FunctionTypedFormalParameter ||
            (node is FieldFormalParameter && node.parameters != null)),
        super(source, node);

  @override
  String get description =>
      'explicitly hinted to be ${isNullable ? 'nullable' : 'non-nullable'}';

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
  String get description => 'optional formal parameter must be nullable';

  @override
  EdgeOriginKind get kind => EdgeOriginKind.optionalFormalParameter;
}

/// Edge origin resulting from an inheritance relationship between two method
/// parameters.
class ParameterInheritanceOrigin extends EdgeOrigin {
  ParameterInheritanceOrigin(Source source, AstNode node) : super(source, node);

  @override
  String get description => 'function parameter override';

  @override
  EdgeOriginKind get kind => EdgeOriginKind.parameterInheritance;
}

/// Edge origin resulting from the presence of a call to quiver's
/// `checkNotNull`.
///
/// For example, in the following code snippet:
///   import 'package:quiver/check.dart';
///   void f(int i) {
///     checkNotNull(i);
///   }
///
/// this class is used for the edge connecting the type of f's `i` parameter to
/// `never`, due to the `checkNotNull` call proclaiming that `i` is not `null`.
class QuiverCheckNotNullOrigin extends EdgeOrigin {
  QuiverCheckNotNullOrigin(Source source, SimpleIdentifier node)
      : super(source, node);

  @override
  String get description => 'value checked to be non-null';

  @override
  EdgeOriginKind get kind => EdgeOriginKind.quiverCheckNotNull;
}

/// Edge origin resulting from an inheritance relationship between two method
/// return types.
class ReturnTypeInheritanceOrigin extends EdgeOrigin {
  ReturnTypeInheritanceOrigin(Source source, AstNode node)
      : super(source, node);

  @override
  String get description => 'function return type override';

  @override
  EdgeOriginKind get kind => EdgeOriginKind.returnTypeInheritance;
}

/// Edge origin resulting from the use of a stacktrace parameter in a catch
/// directive.  The type of such parameters is fixed by the language as
/// non-nullable `StackTrace`.
class StackTraceTypeOrigin extends EdgeOrigin {
  StackTraceTypeOrigin(Source source, AstNode node) : super(source, node);

  @override
  String get description => 'stack trace variable is nullable';

  @override
  EdgeOriginKind get kind => EdgeOriginKind.stackTraceTypeOrigin;
}

/// Edge origin resulting from the use of `this` or `super`.
class ThisOrSuperOrigin extends EdgeOrigin {
  /// Indicates whether the expression in question is `this`.  If `false`, the
  /// expression in question is `super`.
  final bool isThis;

  ThisOrSuperOrigin(Source source, AstNode node, this.isThis)
      : super(source, node);

  @override
  String get description =>
      'type of "${isThis ? 'this' : 'super'}" is non-nullable';

  @override
  EdgeOriginKind get kind => EdgeOriginKind.thisOrSuper;
}

/// An edge origin used for edges that originated from the type of a `throw` or
/// `rethrow`.
class ThrowOrigin extends EdgeOrigin {
  ThrowOrigin(Source source, AstNode node) : super(source, node);

  @override
  String get description =>
      'type of thrown expression is presumed non-nullable';

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
  String get description => 'reference to typedef';

  @override
  EdgeOriginKind get kind => EdgeOriginKind.typedefReference;
}

/// Edge origin resulting from the instantiation of a type parameter, which
/// affects the nullability of that type parameter's bound.
class TypeParameterInstantiationOrigin extends EdgeOrigin {
  TypeParameterInstantiationOrigin(Source source, TypeAnnotation node)
      : super(source, node);

  @override
  String get description => 'type parameter instantiation';

  @override
  EdgeOriginKind get kind => EdgeOriginKind.typeParameterInstantiation;

  @override
  TypeAnnotation get node => super.node as TypeAnnotation;
}

/// Edge origin resulting from the read of a variable that has not been
/// definitely assigned a value.
class UninitializedReadOrigin extends EdgeOrigin {
  UninitializedReadOrigin(Source source, AstNode node) : super(source, node);

  @override
  String get description => 'local variable might not be initialized';

  @override
  EdgeOriginKind get kind => EdgeOriginKind.uninitializedRead;
}
