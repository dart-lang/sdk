// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../types/shared_type.dart';
import 'type_analyzer_operations.dart';

/// Tracks a single constraint on a single type parameter.
///
/// We require that `typeParameter <: constraint` if `isUpper` is true, and
/// `constraint <: typeParameter` otherwise.
class GeneratedTypeConstraint<Variable extends Object> {
  /// The type parameter that is constrained by [constraint].
  final SharedTypeParameterView typeParameter;

  /// The type schema constraining the type parameter.
  final SharedTypeSchemaView constraint;

  /// True if `typeParameter <: constraint`, and false otherwise.
  ///
  /// Note that we require that either `typeParameter <: constraint` or
  /// `constraint <: typeParameter`.
  final bool isUpper;

  GeneratedTypeConstraint.lower(this.typeParameter, this.constraint)
    : isUpper = false;

  GeneratedTypeConstraint.upper(this.typeParameter, this.constraint)
    : isUpper = true;

  @override
  String toString() {
    return isUpper ? "<type> <: ${constraint}" : "${constraint} <: <type>";
  }
}

/// A constraint on a type parameter that we're inferring.
class MergedTypeConstraint<
  Variable extends Object,
  TypeDeclarationType extends Object,
  TypeDeclaration extends Object,
  AstNode extends Object
> {
  /// The lower bound of the type being constrained.  This bound must be a
  /// subtype of the type being constrained. In other words, lowerBound <: T.
  ///
  /// This kind of constraint cannot be expressed in Dart, but it applies when
  /// we're doing inference. For example, consider a signature like:
  ///
  ///     T pickAtRandom<T>(T x, T y);
  ///
  /// and a call to it like:
  ///
  ///     pickAtRandom(1, 2.0)
  ///
  /// when we see the first parameter is an `int`, we know that `int <: T`.
  /// When we see `double` this implies `double <: T`.
  /// Combining these constraints results in a lower bound of `num`.
  ///
  /// In the example above `num` is chosen as the greatest upper bound between
  /// `int` and `double`, so the resulting constraint is equal or stronger than
  /// either of the two.
  SharedTypeSchemaView lower;

  /// The upper bound of the type being constrained.  The type being constrained
  /// must be a subtype of this bound. In other words, T <: upperBound.
  ///
  /// In Dart this can be written as `<T extends UpperBoundType>`.
  ///
  /// In inference, this can happen as a result of parameters of function type.
  /// For example, consider a signature like:
  ///
  ///     T reduce<T>(List<T> values, T f(T x, T y));
  ///
  /// and a call to it like:
  ///
  ///     reduce(values, (num x, num y) => ...);
  ///
  /// From the function expression's parameters, we conclude `T <: num`. We may
  /// still be able to conclude a different [lower] based on `values` or
  /// the type of the elided `=> ...` body. For example:
  ///
  ///      reduce(['x'], (num x, num y) => 'hi');
  ///
  /// Here the [lower] will be `String` and the upper bound will be `num`,
  /// which cannot be satisfied, so this is ill typed.
  SharedTypeSchemaView upper;

  /// Where this constraint comes from, used for error messages.
  TypeConstraintOrigin<Variable, TypeDeclarationType, TypeDeclaration, AstNode>
  origin;

  MergedTypeConstraint({
    required this.lower,
    required this.upper,
    required this.origin,
  });

  MergedTypeConstraint.fromExtends({
    required String typeParameterName,
    required SharedTypeView boundType,
    required SharedTypeView extendsType,
    required TypeAnalyzerOperations<
      Variable,
      TypeDeclarationType,
      TypeDeclaration,
      AstNode
    >
    typeAnalyzerOperations,
  }) : this(
         origin: new TypeConstraintFromExtendsClause(
           typeParameterName: typeParameterName,
           boundType: boundType,
           extendsType: extendsType,
         ),
         upper: typeAnalyzerOperations.typeToSchema(extendsType),
         lower: typeAnalyzerOperations.unknownType,
       );

  MergedTypeConstraint<Variable, TypeDeclarationType, TypeDeclaration, AstNode>
  clone() {
    return new MergedTypeConstraint(lower: lower, upper: upper, origin: origin);
  }

  bool isEmpty(
    TypeAnalyzerOperations<
      Variable,
      TypeDeclarationType,
      TypeDeclaration,
      AstNode
    >
    typeAnalyzerOperations,
  ) {
    return lower is SharedUnknownType && upper is SharedUnknownType;
  }

  bool isSatisfiedBy(
    SharedTypeView type,
    TypeAnalyzerOperations<
      Variable,
      TypeDeclarationType,
      TypeDeclaration,
      AstNode
    >
    typeAnalyzerOperations,
  ) {
    return typeAnalyzerOperations.typeIsSubtypeOfTypeSchema(type, upper) &&
        typeAnalyzerOperations.typeSchemaIsSubtypeOfType(lower, type);
  }

  void mergeIn(
    GeneratedTypeConstraint<Variable> generatedTypeConstraint,
    TypeAnalyzerOperations<
      Variable,
      TypeDeclarationType,
      TypeDeclaration,
      AstNode
    >
    typeAnalyzerOperations,
  ) {
    if (generatedTypeConstraint.isUpper) {
      mergeInTypeSchemaUpper(
        generatedTypeConstraint.constraint,
        typeAnalyzerOperations,
      );
    } else {
      mergeInTypeSchemaLower(
        generatedTypeConstraint.constraint,
        typeAnalyzerOperations,
      );
    }
  }

  void mergeInTypeSchemaLower(
    SharedTypeSchemaView constraint,
    TypeAnalyzerOperations<
      Variable,
      TypeDeclarationType,
      TypeDeclaration,
      AstNode
    >
    typeAnalyzerOperations,
  ) {
    lower = typeAnalyzerOperations.typeSchemaLub(lower, constraint);
  }

  void mergeInTypeSchemaUpper(
    SharedTypeSchemaView constraint,
    TypeAnalyzerOperations<
      Variable,
      TypeDeclarationType,
      TypeDeclaration,
      AstNode
    >
    typeAnalyzerOperations,
  ) {
    upper = typeAnalyzerOperations.typeSchemaGlb(upper, constraint);
  }

  @override
  String toString() {
    return '${lower} <: <type> <: ${upper}';
  }
}

class TypeConstraintFromArgument<
  Variable extends Object,
  TypeDeclarationType extends Object,
  TypeDeclaration extends Object,
  AstNode extends Object
>
    extends
        TypeConstraintOrigin<
          Variable,
          TypeDeclarationType,
          TypeDeclaration,
          AstNode
        > {
  final SharedTypeView argumentType;
  final SharedTypeView parameterType;
  final String parameterName;
  final String? genericClassName;
  final bool isGenericClassInDartCore;

  TypeConstraintFromArgument({
    required this.argumentType,
    required this.parameterType,
    required this.parameterName,
    required this.genericClassName,
    this.isGenericClassInDartCore = false,
  });

  @override
  List<String> formatError(
    TypeAnalyzerOperations<
      Variable,
      TypeDeclarationType,
      TypeDeclaration,
      AstNode
    >
    typeAnalyzerOperations,
  ) {
    // TODO(cstefantsova): we should highlight the span. That would be more
    // useful.  However in summary code it doesn't look like the AST node with
    // span is available.
    String prefix;
    if ((genericClassName == "List" || genericClassName == "Map") &&
        isGenericClassInDartCore) {
      // This will become:
      //     "List element"
      //     "Map key"
      //     "Map value"
      prefix = "${genericClassName} $parameterName";
    } else {
      prefix = "Parameter '$parameterName'";
    }

    return [
      prefix,
      "declared as     '${parameterType.getDisplayString()}'",
      "but argument is '${argumentType.getDisplayString()}'.",
    ];
  }
}

class TypeConstraintFromExtendsClause<
  Variable extends Object,
  TypeDeclarationType extends Object,
  TypeDeclaration extends Object,
  AstNode extends Object
>
    extends
        TypeConstraintOrigin<
          Variable,
          TypeDeclarationType,
          TypeDeclaration,
          AstNode
        > {
  /// Name of the type parameter with the extends clause.
  final String typeParameterName;

  /// The declared bound of the type parameter, not `null`, because we create
  /// this clause only when it is not `null`.
  ///
  /// For example `Iterable<T>` for `<T, E extends Iterable<T>>`.
  final SharedTypeView boundType;

  /// [boundType] in which type parameters are substituted with inferred
  /// type arguments.
  ///
  /// For example `Iterable<int>` if `T` inferred to `int`.
  final SharedTypeView extendsType;

  TypeConstraintFromExtendsClause({
    required this.typeParameterName,
    required this.boundType,
    required this.extendsType,
  });

  @override
  List<String> formatError(
    TypeAnalyzerOperations<
      Variable,
      TypeDeclarationType,
      TypeDeclaration,
      AstNode
    >
    typeAnalyzerOperations,
  ) {
    String boundStr = boundType.getDisplayString();
    String extendsStr = extendsType.getDisplayString();
    return [
      "Type parameter '${typeParameterName}'",
      "is declared to extend '${boundStr}' producing '${extendsStr}'.",
    ];
  }
}

class TypeConstraintFromFunctionContext<
  Variable extends Object,
  TypeDeclarationType extends Object,
  TypeDeclaration extends Object,
  AstNode extends Object
>
    extends
        TypeConstraintOrigin<
          Variable,
          TypeDeclarationType,
          TypeDeclaration,
          AstNode
        > {
  final SharedType contextType;
  final SharedType functionType;

  TypeConstraintFromFunctionContext({
    required this.functionType,
    required this.contextType,
  });

  @override
  List<String> formatError(
    TypeAnalyzerOperations<
      Variable,
      TypeDeclarationType,
      TypeDeclaration,
      AstNode
    >
    typeAnalyzerOperations,
  ) {
    return [
      "Function type",
      "declared as '${functionType.getDisplayString()}'",
      "used where  '${contextType.getDisplayString()}' is required.",
    ];
  }
}

class TypeConstraintFromReturnType<
  Variable extends Object,
  TypeDeclarationType extends Object,
  TypeDeclaration extends Object,
  AstNode extends Object
>
    extends
        TypeConstraintOrigin<
          Variable,
          TypeDeclarationType,
          TypeDeclaration,
          AstNode
        > {
  final SharedType contextType;
  final SharedType declaredType;

  TypeConstraintFromReturnType({
    required this.declaredType,
    required this.contextType,
  });

  @override
  List<String> formatError(
    TypeAnalyzerOperations<
      Variable,
      TypeDeclarationType,
      TypeDeclaration,
      AstNode
    >
    typeAnalyzerOperations,
  ) {
    return [
      "Return type",
      "declared as '${declaredType.getDisplayString()}'",
      "used where  '${contextType.getDisplayString()}' is required.",
    ];
  }
}

/// The origin of a type constraint, for the purposes of producing a human
/// readable error message during type inference as well as determining whether
/// the constraint was used to fix the type parameter or not.
abstract class TypeConstraintOrigin<
  Variable extends Object,
  TypeDeclarationType extends Object,
  TypeDeclaration extends Object,
  AstNode extends Object
> {
  const TypeConstraintOrigin();

  List<String> formatError(
    TypeAnalyzerOperations<
      Variable,
      TypeDeclarationType,
      TypeDeclaration,
      AstNode
    >
    typeAnalyzerOperations,
  );
}

class UnknownTypeConstraintOrigin<
  Variable extends Object,
  TypeDeclarationType extends Object,
  TypeDeclaration extends Object,
  AstNode extends Object
>
    extends
        TypeConstraintOrigin<
          Variable,
          TypeDeclarationType,
          TypeDeclaration,
          AstNode
        > {
  const UnknownTypeConstraintOrigin();

  @override
  List<String> formatError(
    TypeAnalyzerOperations<
      Variable,
      TypeDeclarationType,
      TypeDeclaration,
      AstNode
    >
    typeAnalyzerOperations,
  ) {
    return <String>[];
  }
}

/// Data structure maintaining intermediate type inference results, such as
/// type constraints, for testing purposes.  Under normal execution, no
/// instance of this class should be created.
class TypeConstraintGenerationDataForTesting<
  Variable extends Object,
  AstNode extends Object
> {
  /// Map from nodes requiring type inference to the generated type constraints
  /// for the node.
  final Map<AstNode, List<GeneratedTypeConstraint<Variable>>>
  generatedTypeConstraints = {};

  /// Merges [other] into the receiver, combining the constraints.
  ///
  /// The method reuses data structures from [other] whenever possible, to
  /// avoid extra memory allocations. This process is destructive to [other]
  /// because the changes made to the reused structures will be visible to
  /// [other].
  void mergeIn(
    TypeConstraintGenerationDataForTesting<Variable, AstNode> other,
  ) {
    for (AstNode node in other.generatedTypeConstraints.keys) {
      List<GeneratedTypeConstraint>? constraints =
          generatedTypeConstraints[node];
      if (constraints != null) {
        constraints.addAll(other.generatedTypeConstraints[node]!);
      } else {
        generatedTypeConstraints[node] = other.generatedTypeConstraints[node]!;
      }
    }
  }
}
