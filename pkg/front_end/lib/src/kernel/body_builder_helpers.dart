// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'body_builder.dart';

// TODO(ahe): Remove this and ensure all nodes have a location.
const int noLocation = TreeNode.noOffset;

enum JumpTargetKind {
  Break,
  Continue,
  Goto, // Continue label in switch.
}

class Operator {
  final Token token;

  String get name => token.stringValue!;

  final int charOffset;

  Operator(this.token, this.charOffset);

  @override
  String toString() => "operator($name)";
}

class JumpTarget {
  final List<Statement> users = <Statement>[];

  final JumpTargetKind kind;

  final int functionNestingLevel;

  final Uri fileUri;

  final int charOffset;

  JumpTarget(
    this.kind,
    this.functionNestingLevel,
    this.fileUri,
    this.charOffset,
  );

  bool get isBreakTarget => kind == JumpTargetKind.Break;

  bool get isContinueTarget => kind == JumpTargetKind.Continue;

  bool get isGotoTarget => kind == JumpTargetKind.Goto;

  bool get hasUsers => users.isNotEmpty;

  void addBreak(Statement statement) {
    assert(isBreakTarget);
    users.add(statement);
  }

  void addContinue(Statement statement) {
    assert(isContinueTarget);
    users.add(statement);
  }

  void addGoto(Statement statement) {
    assert(isGotoTarget);
    users.add(statement);
  }

  void resolveBreaks(
    Forest forest,
    LabeledStatement target,
    Statement targetStatement,
  ) {
    assert(isBreakTarget);
    for (Statement user in users) {
      BreakStatementImpl breakStatement = user as BreakStatementImpl;
      breakStatement.target = target;
      breakStatement.targetStatement = targetStatement;
    }
    users.clear();
  }

  List<BreakStatementImpl>? resolveContinues(
    Forest forest,
    LabeledStatement target,
  ) {
    assert(isContinueTarget);
    List<BreakStatementImpl> statements = <BreakStatementImpl>[];
    for (Statement user in users) {
      BreakStatementImpl breakStatement = user as BreakStatementImpl;
      breakStatement.target = target;
      statements.add(breakStatement);
    }
    users.clear();
    return statements;
  }

  void resolveGotos(Forest forest, SwitchCase target) {
    assert(isGotoTarget);
    for (Statement user in users) {
      ContinueSwitchStatement continueSwitchStatement =
          user as ContinueSwitchStatement;
      continueSwitchStatement.target = target;
    }
    users.clear();
  }
}

class LabelTarget implements JumpTarget {
  final JumpTarget breakTarget;

  final JumpTarget continueTarget;

  @override
  final int functionNestingLevel;

  @override
  final Uri fileUri;

  @override
  final int charOffset;

  LabelTarget(this.functionNestingLevel, this.fileUri, this.charOffset)
    : breakTarget = new JumpTarget(
        JumpTargetKind.Break,
        functionNestingLevel,
        fileUri,
        charOffset,
      ),
      continueTarget = new JumpTarget(
        JumpTargetKind.Continue,
        functionNestingLevel,
        fileUri,
        charOffset,
      );

  @override
  // Coverage-ignore(suite): Not run.
  bool get hasUsers => breakTarget.hasUsers || continueTarget.hasUsers;

  @override
  // Coverage-ignore(suite): Not run.
  List<Statement> get users => unsupported("users", charOffset, fileUri);

  @override
  // Coverage-ignore(suite): Not run.
  JumpTargetKind get kind => unsupported("kind", charOffset, fileUri);

  @override
  bool get isBreakTarget => true;

  @override
  bool get isContinueTarget => true;

  @override
  bool get isGotoTarget => false;

  @override
  void addBreak(Statement statement) {
    breakTarget.addBreak(statement);
  }

  @override
  void addContinue(Statement statement) {
    continueTarget.addContinue(statement);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void addGoto(Statement statement) {
    unsupported("addGoto", charOffset, fileUri);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void resolveBreaks(
    Forest forest,
    LabeledStatement target,
    Statement targetStatement,
  ) {
    breakTarget.resolveBreaks(forest, target, targetStatement);
  }

  @override
  // Coverage-ignore(suite): Not run.
  List<BreakStatementImpl>? resolveContinues(
    Forest forest,
    LabeledStatement target,
  ) {
    return continueTarget.resolveContinues(forest, target);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void resolveGotos(Forest forest, SwitchCase target) {
    unsupported("resolveGotos", charOffset, fileUri);
  }
}

class FunctionTypeParameters {
  final List<ParameterBuilder>? parameters;
  final int charOffset;
  final int length;
  final Uri uri;

  FunctionTypeParameters(
    this.parameters,
    this.charOffset,
    this.length,
    this.uri,
  ) {
    if (parameters?.isEmpty ?? false) {
      throw "Empty parameters should be null";
    }
  }

  TypeBuilder toFunctionType(
    TypeBuilder returnType,
    NullabilityBuilder nullabilityBuilder, {
    List<StructuralParameterBuilder>? structuralVariableBuilders,
    required bool hasFunctionFormalParameterSyntax,
  }) {
    return new FunctionTypeBuilderImpl(
      returnType,
      structuralVariableBuilders,
      parameters,
      nullabilityBuilder,
      uri,
      charOffset,
      hasFunctionFormalParameterSyntax: hasFunctionFormalParameterSyntax,
    );
  }

  @override
  String toString() {
    return "FormalParameters($parameters, $charOffset, $uri)";
  }
}

class FormalParameters {
  final List<FormalParameterBuilder>? parameters;
  final int charOffset;
  final int length;
  final Uri uri;

  FormalParameters(this.parameters, this.charOffset, this.length, this.uri) {
    if (parameters?.isEmpty ?? false) {
      throw "Empty parameters should be null";
    }
  }

  FunctionNode buildFunctionNode(
    SourceLibraryBuilder library,
    TypeBuilder? returnTypeBuilder,
    List<NominalParameterBuilder>? typeParameterBuilders,
    AsyncMarker asyncModifier,
    Statement body,
    int fileEndOffset,
  ) {
    DartType returnType =
        returnTypeBuilder?.build(library, TypeUse.returnType) ??
        const DynamicType();
    int requiredParameterCount = 0;
    List<VariableDeclaration> positionalParameters = <VariableDeclaration>[];
    List<VariableDeclaration> namedParameters = <VariableDeclaration>[];
    if (parameters != null) {
      for (FormalParameterBuilder formal in parameters!) {
        VariableDeclaration parameter = formal.build(library);
        if (formal.isPositional) {
          positionalParameters.add(parameter);
          if (formal.isRequiredPositional) requiredParameterCount++;
        } else if (formal.isNamed) {
          namedParameters.add(parameter);
        }
      }
      namedParameters.sort((VariableDeclaration a, VariableDeclaration b) {
        return a.name!.compareTo(b.name!);
      });
    }

    List<TypeParameter>? typeParameters;
    if (typeParameterBuilders != null) {
      typeParameters = <TypeParameter>[];
      for (NominalParameterBuilder t in typeParameterBuilders) {
        typeParameters.add(t.parameter);
        // Build the bound to detect cycles in typedefs.
        t.bound?.build(library, TypeUse.typeParameterBound);
      }
    }
    return new FunctionNode(
        body,
        typeParameters: typeParameters,
        positionalParameters: positionalParameters,
        namedParameters: namedParameters,
        requiredParameterCount: requiredParameterCount,
        returnType: returnType,
        asyncMarker: asyncModifier,
      )
      ..fileOffset = charOffset
      ..fileEndOffset = fileEndOffset;
  }

  LocalScope computeFormalParameterScope(
    LocalScope parent,
    ExpressionGeneratorHelper helper, {
    bool wildcardVariablesEnabled = false,
  }) {
    if (parameters == null) return parent;
    assert(parameters!.isNotEmpty);
    Map<String, VariableBuilder> local = {};

    for (FormalParameterBuilder parameter in parameters!) {
      // Avoid having wildcard parameters in scope.
      if (wildcardVariablesEnabled && parameter.isWildcard) continue;
      Builder? existing = local[parameter.name];
      if (existing != null) {
        helper.reportDuplicatedDeclaration(
          existing,
          parameter.name,
          parameter.fileOffset,
        );
      } else {
        local[parameter.name] = parameter;
      }
    }
    return parent.createNestedFixedScope(
      kind: LocalScopeKind.formals,
      local: local,
    );
  }

  @override
  String toString() {
    return "FormalParameters($parameters, $charOffset, $uri)";
  }
}

/// Returns a block like this:
///
///     {
///       statement;
///       body;
///     }
///
/// If [body] is a [Block], it's returned with [statement] prepended to it.
Block combineStatements(Statement statement, Statement body) {
  if (body is Block) {
    if (statement is Block) {
      body.statements.insertAll(0, statement.statements);
      setParents(statement.statements, body);
    } else {
      body.statements.insert(0, statement);
      statement.parent = body;
    }
    return body;
  } else {
    return new Block(<Statement>[
      if (statement is Block) ...statement.statements else statement,
      body,
    ])..fileOffset = statement.fileOffset;
  }
}

/// DartDocTest(
///   debugName("myClassName", "myName"),
///   "myClassName.myName"
/// )
/// DartDocTest(
///   debugName("myClassName", ""),
///   "myClassName"
/// )
/// DartDocTest(
///   debugName("", ""),
///   ""
/// )
String debugName(String className, String name) {
  return name.isEmpty ? className : "$className.$name";
}

/// A data holder used to hold the information about a label that is pushed on
/// the stack.
class Label {
  String name;
  int charOffset;

  Label(this.name, this.charOffset);

  @override
  String toString() => "label($name)";
}

class ForInElements {
  ExpressionVariable? explicitVariableDeclaration;
  ExpressionVariable? syntheticVariableDeclaration;
  Expression? syntheticAssignment;
  Expression? expressionProblem;
  Statement? expressionEffects;

  ExpressionVariable get variable =>
      (explicitVariableDeclaration ?? syntheticVariableDeclaration)!;
}

class Condition {
  final Expression expression;
  final PatternGuard? patternGuard;

  Condition(this.expression, [this.patternGuard]);

  @override
  String toString() =>
      'Condition($expression'
      '${patternGuard != null ? ',$patternGuard' : ''})';
}

final ExpressionOrPatternGuardCase dummyExpressionOrPatternGuardCase =
    new ExpressionOrPatternGuardCase.expression(
      TreeNode.noOffset,
      dummyExpression,
    );

class ExpressionOrPatternGuardCase {
  final int caseOffset;
  final Expression? expression;
  final PatternGuard? patternGuard;

  ExpressionOrPatternGuardCase.expression(
    this.caseOffset,
    Expression this.expression,
  ) : patternGuard = null;

  ExpressionOrPatternGuardCase.patternGuard(
    this.caseOffset,
    PatternGuard this.patternGuard,
  ) : expression = null;
}

extension on MemberKind {
  bool get isFunctionType {
    switch (this) {
      case MemberKind.FunctionTypeAlias:
      case MemberKind.FunctionTypedParameter:
      case MemberKind.GeneralizedFunctionType:
        return true;
      case MemberKind.Catch:
      case MemberKind.Factory:
      case MemberKind.Local:
      case MemberKind.AnonymousMethod:
      case MemberKind.NonStaticMethod:
      case MemberKind.StaticMethod:
      case MemberKind.TopLevelMethod:
      case MemberKind.ExtensionNonStaticMethod:
      case MemberKind.ExtensionStaticMethod:
      case MemberKind.ExtensionTypeNonStaticMethod:
      case MemberKind.ExtensionTypeStaticMethod:
      case MemberKind.NonStaticField:
      case MemberKind.StaticField:
      case MemberKind.TopLevelField:
      case MemberKind.PrimaryConstructor:
        return false;
    }
  }
}

/// Annotations that needs to be inferred about the body has been inferred.
class PendingAnnotations {
  final List<SingleTargetAnnotations>? singleTargetAnnotations;
  final List<MultiTargetAnnotations>? multiTargetAnnotations;

  PendingAnnotations(this.singleTargetAnnotations, this.multiTargetAnnotations);
}

/// A single target holding annotations to be inferred.
class SingleTargetAnnotations {
  final Annotatable target;
  final List<int>? indicesOfAnnotationsToBeInferred;

  SingleTargetAnnotations(this.target, [this.indicesOfAnnotationsToBeInferred]);
}

/// A multiple targets holding annotations to be inferred.
///
/// The annotations are on the first target and needs to be cloned to the
/// subsequent targets after inference.
class MultiTargetAnnotations {
  final List<Annotatable> targets;

  MultiTargetAnnotations(this.targets);
}

class BuildInitializersResult {
  final List<Initializer>? initializers;
  final bool needsImplicitSuperInitializer;
  final PendingAnnotations? annotations;

  BuildInitializersResult(
    this.initializers,
    this.needsImplicitSuperInitializer,
    this.annotations,
  );
}

class BuildParameterInitializerResult {
  final Expression initializer;
  final PendingAnnotations? annotations;

  BuildParameterInitializerResult(this.initializer, this.annotations);
}

class BuildRedirectingFactoryMethodResult {
  final PendingAnnotations? annotations;

  BuildRedirectingFactoryMethodResult(this.annotations);
}

class BuildFieldsResult {
  final Map<Identifier, Expression?> fieldInitializers;
  final PendingAnnotations? annotations;

  BuildFieldsResult(this.fieldInitializers, this.annotations);
}

class BuildPrimaryConstructorResult {
  final FormalParameters? formals;
  final PendingAnnotations? annotations;

  BuildPrimaryConstructorResult(this.formals, this.annotations);
}

class BuildFunctionBodyResult {
  final FormalParameters? formals;
  final AsyncMarker asyncModifier;
  final Statement? body;
  final List<Initializer>? initializers;
  final bool needsImplicitSuperInitializer;
  final PendingAnnotations? annotations;

  BuildFunctionBodyResult({
    required this.formals,
    required this.asyncModifier,
    required this.body,
    required this.initializers,
    required this.needsImplicitSuperInitializer,
    required this.annotations,
  });
}

class BuildMetadataListResult {
  final List<Expression> expressions;
  final PendingAnnotations? annotations;

  BuildMetadataListResult(this.expressions, this.annotations);
}

class BuildFieldInitializerResult {
  final Expression initializer;
  final PendingAnnotations? annotations;

  BuildFieldInitializerResult(this.initializer, this.annotations);
}

class BuildEnumConstantResult {
  final ArgumentsImpl arguments;
  final PendingAnnotations? annotations;

  BuildEnumConstantResult(this.arguments, this.annotations);
}

// Coverage-ignore(suite): Not run.
class BuildSingleExpressionResult {
  final Expression expression;
  final PendingAnnotations? annotations;

  BuildSingleExpressionResult(this.expression, this.annotations);
}
