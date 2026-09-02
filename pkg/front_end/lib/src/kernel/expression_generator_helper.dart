// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/token.dart' show Token;
import 'package:kernel/ast.dart';
import 'package:kernel/type_algebra.dart';
import 'package:kernel/type_environment.dart';

import '../api_prototype/experimental_flags.dart';
import '../base/compiler_context.dart';
import '../base/constant_context.dart' show ConstantContext;
import '../base/extension_scope.dart';
import '../base/lookup_result.dart';
import '../base/messages.dart' show Message, ProblemReporting;
import '../builder/builder.dart';
import '../builder/declaration_builders.dart';
import '../builder/formal_parameter_builder.dart';
import '../builder/library_builder.dart';
import '../builder/named_type_builder.dart';
import '../builder/prefix_builder.dart';
import '../builder/type_builder.dart';
import '../codes/cfe_codes.dart' show LocatedMessage;
import '../source/source_library_builder.dart' show SourceLibraryBuilder;
import 'constness.dart' show Constness;
import 'expression_generator.dart';
import 'internal_ast.dart';

/// Alias for InternalExpression | Generator
typedef Expression_Generator = dynamic;

/// Alias for InternalExpression | Generator | Builder
typedef Expression_Generator_Builder = dynamic;

/// Alias for InternalExpression | Generator | Initializer
typedef Expression_Generator_Initializer = dynamic;

/// Alias for InternalExpression | Initializer
typedef Expression_Initializer = dynamic;

abstract class ExpressionGeneratorHelper {
  InternalVariable? get thisVariable;

  Uri get uri;

  SourceLibraryBuilder get libraryBuilder;

  ConstantContext get constantContext;

  /// Whether instance type parameters can be accessed.
  ///
  /// This is used when creating [NamedTypeBuilder]s within
  /// [ExpressionGenerator]s.
  InstanceTypeParameterAccessState get instanceTypeParameterAccessState;

  ProblemReporting get problemReporting;

  CompilerContext get compilerContext;

  ExtensionScope get extensionScope;

  InternalInvalidExpression buildProblem({
    required Message message,
    required Uri fileUri,
    required int fileOffset,
    required int length,
    List<LocatedMessage>? context,
    bool errorHasBeenReported = false,
    InternalExpression? expression,
  });

  MemberLookupResult? lookupSuperConstructor(
    String name,
    LibraryBuilder accessingLibrary,
  );

  InternalExpression toValue(Object? node);

  String superConstructorNameForDiagnostics(String name);

  String constructorNameForDiagnostics(String name, {String? className});

  Member? lookupSuperMember(Name name, {bool isSetter});

  LibraryFeatures get libraryFeatures;

  bool isDeclaredInEnclosingCase(InternalVariable variable);

  Generator processLookupResult({
    required LookupResult? lookupResult,
    required String name,
    required Token nameToken,
    required int nameOffset,
    PrefixBuilder? prefix,
    Token? prefixToken,
    required bool forStatementScope,
  });

  Expression_Generator_Initializer finishSend(
    Object receiver,
    List<TypeBuilder>? typeArgumentBuilders,
    TypeArguments? typeArguments,
    ActualArguments arguments,
    int offset, {
    bool isTypeArgumentsInForest = false,
  });

  List<InternalInitializer> createFieldInitializer(
    String name,
    int fieldNameOffset,
    InternalExpression expression, {
    FormalParameterBuilder? formal,
  });

  InternalInitializer buildSuperInitializer(
    bool isSynthetic,
    Constructor constructor,
    ActualArguments arguments, [
    int offset = TreeNode.noOffset,
  ]);

  InternalInitializer buildRedirectingInitializer(
    Name name,
    ActualArguments arguments, {
    required int fileOffset,
  });

  InternalExpression buildStaticInvocation({
    required Procedure target,
    required TypeArguments? typeArguments,
    required ActualArguments arguments,
    required int fileOffset,
  });

  InternalInvalidExpression buildUnresolvedError(
    String name,
    int fileOffset, {
    bool isSuper,
    required UnresolvedKind kind,
    int? length,
    bool errorHasBeenReported,
  });

  InternalExpression wrapInDeferredCheck(
    InternalExpression expression,
    PrefixBuilder prefix,
    int charOffset,
  );

  bool isIdentical(Member? member);

  InternalExpression buildMethodInvocation(
    InternalExpression receiver,
    Name name,
    TypeArguments? typeArguments,
    ActualArguments arguments,
    int offset, {
    bool isConstantExpression = false,
    bool isNullAware = false,
    bool isImplicitThis = false,
  });

  InternalExpression buildSuperInvocation(
    Name name,
    TypeArguments? typeArguments,
    ActualArguments arguments,
    int offset, {
    bool isConstantExpression = false,
    bool isNullAware = false,
    bool isImplicitCall = false,
  });

  ConstructorResolutionResult resolveAndBuildConstructorInvocation(
    TypeDeclarationBuilder type,
    Token nameToken,
    Token nameLastToken,
    ActualArguments arguments,
    String name,
    List<TypeBuilder>? typeArgumentBuilders,
    TypeArguments? typeArguments,
    int charOffset,
    Constness constness, {
    required bool isTypeArgumentsInForest,
    TypeAliasBuilder? typeAliasBuilder,
    required UnresolvedKind unresolvedKind,
  });

  TypeBuilder validateTypeParameterUse(
    TypeBuilder typeBuilder, {
    required bool allowPotentiallyConstantType,
  });

  void addProblemErrorIfConst(Message message, int charOffset, int length);

  InternalExpression buildProblemErrorIfConst(
    Message message,
    int charOffset,
    int length,
  );

  InternalExpression evaluateArgumentsBefore(
    ActualArguments arguments,
    InternalExpression expression,
  );

  DartType buildDartType(
    TypeBuilder typeBuilder,
    TypeUse typeUse, {
    required bool allowPotentiallyConstantType,
  });

  List<DartType> buildDartTypeArguments(
    List<TypeBuilder>? typeArguments,
    TypeUse typeUse, {
    required bool allowPotentiallyConstantType,
  });

  void reportDuplicatedDeclaration(
    Builder existing,
    String name,
    int charOffset,
  );

  /// Creates a [VariableGet] of the [variable] using [charOffset] as the file
  /// offset of the created node.
  InternalExpression createVariableGet(
    InternalVariable variable,
    int charOffset,
  );

  /// Registers that [variable] is read from.
  ///
  /// This is needed for type promotion.
  void registerVariableRead(InternalVariable variable);

  /// Registers that [variable] is assigned to.
  ///
  /// This is needed for type promotion.
  void registerVariableAssignment(InternalVariable variable);

  TypeEnvironment get typeEnvironment;

  /// If explicit instantiations are supported in this library, create an
  /// instantiation of the result of [receiverFunction] using
  /// [typeArguments] followed by an invocation of [name] with [arguments].
  /// Otherwise create the errors for the corresponding invalid implicit
  /// creation expression.
  ///
  /// This is used to handle the syntax for implicit creation expression as
  /// an explicit instantiation with and invocation. For instance
  ///
  ///     a.b<c>.d()
  ///
  /// The parser treat the as the constructor invocation of constructor `d` on
  /// class `b` with prefix `a` with type arguments `<c>`, but with explicit
  /// instantiation it could instead be the explicit instantiation of expression
  /// `a.b` with type arguments `<c>` followed by and invocation of `d()`.
  ///
  /// If [inImplicitCreationContext] is `false`, then the expression is
  /// preceded by `new` or `const`, and an error should be reported instead of
  /// creating the instantiation and invocation.
  InternalExpression createInstantiationAndInvocation(
    InternalExpression Function() receiverFunction,
    List<TypeBuilder>? typeArguments,
    String className,
    String constructorName,
    ActualArguments arguments, {
    required int instantiationOffset,
    required int invocationOffset,
    required bool inImplicitCreationContext,
  });

  /// Registers a read of the internal variable representing `this`.
  // TODO(johnniwinther): This should return the [InternalThisExpression].
  void readInternalThisVariable();
}

/// Checks that a generic [typedef] for a generic type declaration.
bool isProperRenameForTypeDeclaration(
  TypeEnvironment typeEnvironment,
  Typedef typedef,
  Library typedefLibrary,
) {
  DartType? rhsType = typedef.type;
  if (rhsType is! TypeDeclarationType) {
    return false;
  }

  List<TypeParameter> fromParameters = typedef.typeParameters;
  List<TypeParameter> toParameters = rhsType.typeDeclaration.typeParameters;
  List<DartType> typeArguments = rhsType.typeArguments;
  if (fromParameters.length != typeArguments.length) {
    return false;
  }
  for (int i = 0; i < fromParameters.length; ++i) {
    if (typeArguments[i] !=
        new TypeParameterType.withDefaultNullability(fromParameters[i])) {
      return false;
    }
  }

  Map<TypeParameter, DartType> substitutionMap = {};
  for (int i = 0; i < fromParameters.length; ++i) {
    substitutionMap[fromParameters[i]] =
        new TypeParameterType.withDefaultNullability(toParameters[i]);
  }
  Substitution substitution = Substitution.fromMap(substitutionMap);
  for (int i = 0; i < fromParameters.length; ++i) {
    if (!typeEnvironment.areMutualSubtypes(
      toParameters[i].bound,
      substitution.substituteType(fromParameters[i].bound),
    )) {
      return false;
    }
  }

  return true;
}

enum UnresolvedKind { Unknown, Member, Method, Getter, Setter, Constructor }

/// Result of [ExpressionGeneratorHelper.resolveAndBuildConstructorInvocation].
///
/// [ConstructorResolutionResult] is the root of the sealed hierarchy of
/// results, which then branches into the successful, the unresolved, and the
/// erroneous cases.
sealed class ConstructorResolutionResult;

class SuccessfulConstructorResolutionResult(
  final InternalExpression constructorInvocation,
) extends ConstructorResolutionResult;

/// Erroneous case of [ConstructorResolutionResult].
class ErroneousConstructorResolutionResult({
  /// The expression signaling the error, typically an [InvalidExpression].
  required final InternalExpression errorExpression,
}) extends ConstructorResolutionResult;

/// Unresolved case of [UnresolvedConstructorResolutionResult].
class UnresolvedConstructorResolutionResult({
  required final String errorName,
  required final int charOffset,
  required final ExpressionGeneratorHelper _helper,
  final UnresolvedKind unresolvedKind = UnresolvedKind.Constructor,
}) extends ConstructorResolutionResult {
  /// Constructs the expression signaling the unresolved error.
  ///
  /// The construction of the expression signaling the error is delayed from
  /// the moment of invoking the constructor of
  /// [UnresolvedConstructorResolutionResult], to allow for other resolution
  /// mechanisms to make their attempts, and only if they are also unsuccessful,
  /// build and signal the unresolved error.
  InternalExpression buildErrorExpression() {
    return _helper.buildUnresolvedError(
      errorName,
      charOffset,
      kind: unresolvedKind,
    );
  }
}
