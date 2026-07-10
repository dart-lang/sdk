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

class Operator(final Token token, final int charOffset) {
  String get name => token.stringValue!;

  @override
  String toString() => "operator($name)";
}

class JumpTarget {
  final List<InternalGotoStatement> users = [];

  final JumpTargetKind kind;

  final int functionNestingLevel;

  final Uri fileUri;

  final int charOffset;

  new(this.kind, this.functionNestingLevel, this.fileUri, this.charOffset);

  bool get isBreakTarget => kind == JumpTargetKind.Break;

  bool get isContinueTarget => kind == JumpTargetKind.Continue;

  bool get isGotoTarget => kind == JumpTargetKind.Goto;

  bool get hasUsers => users.isNotEmpty;

  void addBreak(InternalBreakStatement statement) {
    assert(isBreakTarget);
    users.add(statement);
  }

  void addContinue(InternalContinueStatement statement) {
    assert(isContinueTarget);
    users.add(statement);
  }

  void addGoto(InternalContinueSwitchStatement statement) {
    assert(isGotoTarget);
    users.add(statement);
  }

  void resolveBreaks(
    InternalLabeledStatement target,
    InternalStatement targetStatement,
  ) {
    assert(isBreakTarget);
    for (InternalStatement user in users) {
      InternalBreakStatement breakStatement = user as InternalBreakStatement;
      breakStatement.target = target;
      breakStatement.targetStatement = targetStatement;
    }
    users.clear();
  }

  List<InternalContinueStatement>? resolveContinues(
    InternalLabeledStatement target,
  ) {
    assert(isContinueTarget);
    List<InternalContinueStatement> statements = [];
    for (InternalGotoStatement user in users) {
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
    for (InternalGotoStatement user in users) {
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
  List<InternalGotoStatement> get users =>
      unsupported("users", charOffset, fileUri);

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
  void addBreak(InternalBreakStatement statement) {
    breakTarget.addBreak(statement);
  }

  @override
  void addContinue(InternalContinueStatement statement) {
    continueTarget.addContinue(statement);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void addGoto(InternalContinueSwitchStatement statement) {
    unsupported("addGoto", charOffset, fileUri);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void resolveBreaks(
    InternalLabeledStatement target,
    InternalStatement targetStatement,
  ) {
    breakTarget.resolveBreaks(target, targetStatement);
  }

  @override
  // Coverage-ignore(suite): Not run.
  List<InternalContinueStatement>? resolveContinues(
    InternalLabeledStatement target,
  ) {
    return continueTarget.resolveContinues(target);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void resolveGotos(InternalSwitchCase target) {
    unsupported("resolveGotos", charOffset, fileUri);
  }
}

class FunctionTypeParameters(
  final List<ParameterBuilder>? parameters,
  final int charOffset,
  final int length,
  final Uri uri,
) {
  this {
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

class FormalParameters(
  @override final List<FormalParameterBuilder>? parameters,
  @override final int charOffset,
  @override final int length,
  @override final Uri uri,
) extends Parameters {
  this {
    if (parameters?.isEmpty ?? false) {
      throw "Empty parameters should be null";
    }
  }

  InternalFunctionNode buildFunctionNode({
    required SourceLibraryBuilder libraryBuilder,
    required TypeBuilder? returnTypeBuilder,
    required List<NominalParameterBuilder>? typeParameterBuilders,
    required AsyncModifier asyncModifier,
    required InternalStatement body,
    required int fileOffset,
    required int fileEndOffset,
  }) {
    DartType? returnType = returnTypeBuilder?.build(
      libraryBuilder,
      TypeUse.returnType,
    );
    int requiredParameterCount = 0;
    List<InternalPositionalParameter> positionalParameters = [];
    List<InternalNamedParameter> namedParameters = [];
    if (parameters != null) {
      for (FormalParameterBuilder formal in parameters!) {
        InternalFunctionParameter parameter = formal.build(libraryBuilder);
        switch (parameter) {
          case InternalPositionalParameter():
            positionalParameters.add(parameter);
            if (formal.isRequiredPositional) requiredParameterCount++;
          case InternalNamedParameter():
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

class CatchParameters(
  @override final List<CatchParameterBuilder>? parameters,
  @override final int charOffset,
  @override final int length,
  @override final Uri uri,
) extends Parameters {
  this {
    if (parameters?.isEmpty ?? false) {
      throw "Empty parameters should be null";
    }
  }

  @override
  String toString() {
    return "CatchParameters($parameters, $charOffset, $uri)";
  }
}

class AnonymousMethodParameters extends Parameters {
  @override
  final List<AnonymousMethodParameterBuilder>? parameters;

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
    return "AnonymousMethodParameters($parameters, $charOffset, $uri)";
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
class Label(final String name, final int charOffset) {
  @override
  String toString() => "label($name)";
}

class Condition(
  final InternalExpression expression, [
  final InternalPatternGuard? patternGuard,
]) {
  @override
  String toString() =>
      'Condition($expression'
      '${patternGuard != null ? ',$patternGuard' : ''})';
}

final ExpressionOrPatternGuardCase dummyExpressionOrPatternGuardCase =
    new ExpressionOrPatternGuardCase.expression(
      TreeNode.noOffset,
      dummyInternalExpression,
    );

class ExpressionOrPatternGuardCase._(
  final int caseOffset,
  final InternalExpression? expression,
  final InternalPatternGuard? patternGuard,
) {
  new expression(int caseOffset, InternalExpression expression)
    : this._(caseOffset, expression, null);

  new patternGuard(int caseOffset, InternalPatternGuard patternGuard)
    : this._(caseOffset, null, patternGuard);
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
class PendingAnnotations(
  final List<SingleTargetAnnotations>? singleTargetAnnotations,
  final List<MultiTargetAnnotations>? multiTargetAnnotations,
);

/// A single target holding annotations to be inferred.
class SingleTargetAnnotations(
  final Annotatable target,
  final List<InternalExpression> annotations,
);

/// A multiple targets holding annotations to be inferred.
///
/// The annotations are on the first target and needs to be cloned to the
/// subsequent targets after inference.
class MultiTargetAnnotations(
  final List<Annotatable> targets,
  final List<InternalExpression> annotations,
);

class BuildInitializersResult(
  final List<InternalInitializer> initializers,
  final PendingAnnotations? annotations,
);

class BuildParameterDefaultValueResult(
  final InternalExpression defaultValue,
  final PendingAnnotations? annotations,
);

class BuildRedirectingFactoryMethodResult(
  final PendingAnnotations? annotations,
);

class BuildFieldsResult(
  final Map<Identifier, InternalExpression?> fieldInitializers,
  final PendingAnnotations? annotations,
);

class BuildPrimaryConstructorResult(
  final List<InternalInitializer> initializers,
  final PendingAnnotations? annotations,
);

class BuildFunctionBodyResult({
  required final AsyncModifier asyncModifier,
  required final InternalStatement? body,
  required final List<InternalInitializer> initializers,
  required final PendingAnnotations? annotations,
});

class BuildPrimaryConstructorBodyResult({
  required final AsyncModifier asyncModifier,
  required final InternalStatement? body,
  required final List<InternalInitializer> initializers,
  required final PendingAnnotations? annotations,
});

class BuildMetadataListResult(
  final List<InternalExpression> expressions,
  final PendingAnnotations? annotations,
);

class BuildFieldInitializerResult(
  final InternalExpression initializer,
  final PendingAnnotations? annotations,
);

class BuildEnumConstantResult(
  final ActualArguments arguments,
  final PendingAnnotations? annotations,
);

// Coverage-ignore(suite): Not run.
class BuildSingleExpressionResult(
  final InternalExpression expression,
  final PendingAnnotations? annotations,
);
