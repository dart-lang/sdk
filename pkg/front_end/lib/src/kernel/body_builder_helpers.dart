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

  new(this.token, this.charOffset);

  @override
  String toString() => "operator($name)";
}

class JumpTarget {
  final List<Statement> users = <Statement>[];

  final JumpTargetKind kind;

  final int functionNestingLevel;

  final Uri fileUri;

  final int charOffset;

  new(this.kind, this.functionNestingLevel, this.fileUri, this.charOffset);

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

  void resolveBreaks(LabeledStatement target, Statement targetStatement) {
    assert(isBreakTarget);
    for (Statement user in users) {
      InternalBreakStatement breakStatement = user as InternalBreakStatement;
      breakStatement.target = target;
      breakStatement.targetStatement = targetStatement;
    }
    users.clear();
  }

  List<InternalContinueStatement>? resolveContinues(LabeledStatement target) {
    assert(isContinueTarget);
    List<InternalContinueStatement> statements = <InternalContinueStatement>[];
    for (Statement user in users) {
      InternalContinueStatement breakStatement =
          user as InternalContinueStatement;
      breakStatement.target = target;
      statements.add(breakStatement);
    }
    users.clear();
    return statements;
  }

  void resolveGotos(InternalSwitchCase target) {
    assert(isGotoTarget);
    for (Statement user in users) {
      InternalContinueSwitchStatement continueSwitchStatement =
          user as InternalContinueSwitchStatement;
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

  new(this.functionNestingLevel, this.fileUri, this.charOffset)
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
  void resolveBreaks(LabeledStatement target, Statement targetStatement) {
    breakTarget.resolveBreaks(target, targetStatement);
  }

  @override
  // Coverage-ignore(suite): Not run.
  List<InternalContinueStatement>? resolveContinues(LabeledStatement target) {
    return continueTarget.resolveContinues(target);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void resolveGotos(InternalSwitchCase target) {
    unsupported("resolveGotos", charOffset, fileUri);
  }
}

class FunctionTypeParameters {
  final List<ParameterBuilder>? parameters;
  final int charOffset;
  final int length;
  final Uri uri;

  new(this.parameters, this.charOffset, this.length, this.uri) {
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

abstract class Parameters {
  List<ParameterVariableBuilder>? get parameters;
  int get charOffset;
  int get length;
  Uri get uri;

  LocalScope computeFormalParameterScope(
    LocalScope parent,
    ExpressionGeneratorHelper helper, {
    bool wildcardVariablesEnabled = false,
  }) {
    if (parameters == null) return parent;
    assert(parameters!.isNotEmpty);
    Map<String, VariableBuilder> local = {};

    for (ParameterVariableBuilder parameter in parameters!) {
      // Avoid having wildcard parameters in scope.
      if (wildcardVariablesEnabled && parameter.isWildcard) continue;
      String parameterName = parameter.name!;
      Builder? existing = local[parameterName];
      if (existing != null) {
        helper.reportDuplicatedDeclaration(
          existing,
          parameterName,
          parameter.fileOffset,
        );
      } else {
        local[parameterName] = parameter;
      }
    }
    return parent.createNestedFixedScope(
      kind: LocalScopeKind.formals,
      local: local,
    );
  }
}

class FormalParameters extends Parameters {
  @override
  final List<FormalParameterBuilder>? parameters;

  @override
  final int charOffset;

  @override
  final int length;

  @override
  final Uri uri;

  new(this.parameters, this.charOffset, this.length, this.uri) {
    if (parameters?.isEmpty ?? false) {
      throw "Empty parameters should be null";
    }
  }

  InternalFunctionNode buildFunctionNode({
    required SourceLibraryBuilder libraryBuilder,
    required TypeBuilder? returnTypeBuilder,
    required List<NominalParameterBuilder>? typeParameterBuilders,
    required AsyncModifier asyncModifier,
    required Statement body,
    required int fileOffset,
    required int fileEndOffset,
  }) {
    DartType? returnType = returnTypeBuilder?.build(
      libraryBuilder,
      TypeUse.returnType,
    );
    int requiredParameterCount = 0;
    List<InternalVariable> positionalParameters = [];
    List<InternalVariable> namedParameters = [];
    if (parameters != null) {
      for (FormalParameterBuilder formal in parameters!) {
        InternalVariable parameter = formal.build(libraryBuilder);
        if (formal.isPositional) {
          positionalParameters.add(parameter);
          if (formal.isRequiredPositional) requiredParameterCount++;
        } else if (formal.isNamed) {
          namedParameters.add(parameter);
        }
      }
      namedParameters.sort((InternalVariable a, InternalVariable b) {
        return a.cosmeticName!.compareTo(b.cosmeticName!);
      });
    }

    List<TypeParameter>? typeParameters;
    if (typeParameterBuilders != null) {
      typeParameters = <TypeParameter>[];
      for (NominalParameterBuilder t in typeParameterBuilders) {
        typeParameters.add(t.parameter);
        // Build the bound to detect cycles in typedefs.
        t.bound?.build(libraryBuilder, TypeUse.typeParameterBound);
      }
    }
    return intern.createFunctionNode(
      body: body,
      typeParameters: typeParameters,
      positionalParameters: positionalParameters,
      namedParameters: namedParameters,
      requiredParameterCount: requiredParameterCount,
      returnType: returnType,
      asyncMarker: asyncModifier.kind,
      fileOffset: charOffset,
      fileEndOffset: fileEndOffset,
    );
  }

  @override
  String toString() {
    return "FormalParameters($parameters, $charOffset, $uri)";
  }
}

class CatchParameters extends Parameters {
  @override
  final List<CatchParameterBuilder>? parameters;

  @override
  final int charOffset;

  @override
  final int length;

  @override
  final Uri uri;

  new(this.parameters, this.charOffset, this.length, this.uri) {
    if (parameters?.isEmpty ?? false) {
      throw "Empty parameters should be null";
    }
  }

  @override
  String toString() {
    return "CatchParameters($parameters, $charOffset, $uri)";
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

  new(this.name, this.charOffset);

  @override
  String toString() => "label($name)";
}

class Condition {
  final Expression expression;
  final InternalPatternGuard? patternGuard;

  new(this.expression, [this.patternGuard]);

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
  final InternalPatternGuard? patternGuard;

  new expression(this.caseOffset, Expression this.expression)
    : patternGuard = null;

  new patternGuard(this.caseOffset, InternalPatternGuard this.patternGuard)
    : expression = null;
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

  new(this.singleTargetAnnotations, this.multiTargetAnnotations);
}

/// A single target holding annotations to be inferred.
class SingleTargetAnnotations {
  final Annotatable target;
  final List<int>? indicesOfAnnotationsToBeInferred;

  new(this.target, [this.indicesOfAnnotationsToBeInferred]);
}

/// A multiple targets holding annotations to be inferred.
///
/// The annotations are on the first target and needs to be cloned to the
/// subsequent targets after inference.
class MultiTargetAnnotations {
  final List<Annotatable> targets;

  new(this.targets);
}

class BuildInitializersResult {
  final List<Initializer> initializers;
  final PendingAnnotations? annotations;

  new(this.initializers, this.annotations);
}

class BuildParameterInitializerResult {
  final Expression initializer;
  final PendingAnnotations? annotations;

  new(this.initializer, this.annotations);
}

class BuildRedirectingFactoryMethodResult {
  final PendingAnnotations? annotations;

  new(this.annotations);
}

class BuildFieldsResult {
  final Map<Identifier, Expression?> fieldInitializers;
  final PendingAnnotations? annotations;

  new(this.fieldInitializers, this.annotations);
}

class BuildPrimaryConstructorResult {
  final List<Initializer> initializers;
  final PendingAnnotations? annotations;

  new(this.initializers, this.annotations);
}

class BuildFunctionBodyResult {
  final AsyncModifier asyncModifier;
  final Statement? body;
  final List<Initializer> initializers;
  final PendingAnnotations? annotations;

  new({
    required this.asyncModifier,
    required this.body,
    required this.initializers,
    required this.annotations,
  });
}

class BuildPrimaryConstructorBodyResult {
  final AsyncModifier asyncModifier;
  final Statement? body;
  final List<Initializer> initializers;
  final PendingAnnotations? annotations;

  new({
    required this.asyncModifier,
    required this.body,
    required this.initializers,
    required this.annotations,
  });
}

class BuildMetadataListResult {
  final List<Expression> expressions;
  final PendingAnnotations? annotations;

  new(this.expressions, this.annotations);
}

class BuildFieldInitializerResult {
  final Expression initializer;
  final PendingAnnotations? annotations;

  new(this.initializer, this.annotations);
}

class BuildEnumConstantResult {
  final ActualArguments arguments;
  final PendingAnnotations? annotations;

  new(this.arguments, this.annotations);
}

// Coverage-ignore(suite): Not run.
class BuildSingleExpressionResult {
  final Expression expression;
  final PendingAnnotations? annotations;

  new(this.expression, this.annotations);
}
