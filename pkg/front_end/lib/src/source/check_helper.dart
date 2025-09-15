// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' hide Combinator, MapLiteralEntry;
import 'package:kernel/class_hierarchy.dart'
    show ClassHierarchyBase, ClassHierarchyMembers;
import 'package:kernel/src/bounds_checks.dart'
    show
        TypeArgumentIssue,
        findTypeArgumentIssues,
        findTypeArgumentIssuesForInvocation,
        getGenericTypeName,
        hasGenericFunctionTypeAsTypeArgument;
import 'package:kernel/type_algebra.dart';
import 'package:kernel/type_environment.dart' show TypeEnvironment;

import '../api_prototype/experimental_flags.dart';
import '../base/compiler_context.dart';
import '../base/messages.dart';
import '../base/uri_offset.dart';
import '../builder/formal_parameter_builder.dart';
import '../kernel/internal_ast.dart';

extension CheckHelper on ProblemReporting {
  void checkBoundsInConstructorInvocation({
    required LibraryFeatures libraryFeatures,
    required Constructor constructor,
    required List<DartType> typeArguments,
    required TypeEnvironment typeEnvironment,
    required Uri fileUri,
    required int fileOffset,
    bool inferred = false,
  }) {
    if (typeArguments.isEmpty) return;
    Class klass = constructor.enclosingClass;
    DartType constructedType = new InterfaceType(
      klass,
      klass.enclosingLibrary.nonNullable,
      typeArguments,
    );
    checkBoundsInType(
      libraryFeatures: libraryFeatures,
      type: constructedType,
      typeEnvironment: typeEnvironment,
      fileUri: fileUri,
      fileOffset: fileOffset,
      inferred: inferred,
      allowSuperBounded: false,
    );
  }

  void checkBoundsInFactoryInvocation({
    required LibraryFeatures libraryFeatures,
    required Procedure factory,
    required List<DartType> typeArguments,
    required TypeEnvironment typeEnvironment,
    required Uri fileUri,
    required int fileOffset,
    bool inferred = false,
  }) {
    if (typeArguments.isEmpty) return;
    assert(factory.isFactory || factory.isExtensionTypeMember);
    DartType constructedType = Substitution.fromPairs(
      factory.function.typeParameters,
      typeArguments,
    ).substituteType(factory.function.returnType);
    checkBoundsInType(
      libraryFeatures: libraryFeatures,
      type: constructedType,
      typeEnvironment: typeEnvironment,
      fileUri: fileUri,
      fileOffset: fileOffset,
      inferred: inferred,
      allowSuperBounded: false,
    );
  }

  void checkBoundsInFunctionInvocation({
    required ProblemReportingHelper problemReportingHelper,
    required LibraryFeatures libraryFeatures,
    required TypeEnvironment typeEnvironment,
    required FunctionType functionType,
    required String? localName,
    required ArgumentsImpl arguments,
    required Uri fileUri,
    required int fileOffset,
  }) {
    if (arguments.types.isEmpty) return;

    if (functionType.typeParameters.length != arguments.types.length) {
      assert(
        problemReportingHelper.assertProblemReportedElsewhere(
          "SourceLibraryBuilder.checkBoundsInFunctionInvocation: "
          "the numbers of type parameters and type arguments don't match.",
          expectedPhase: CompilationPhaseForProblemReporting.outline,
        ),
      );
      return;
    }
    final DartType bottomType = const NeverType.nonNullable();
    List<TypeArgumentIssue> issues = findTypeArgumentIssuesForInvocation(
      getFreshTypeParametersFromStructuralParameters(
        functionType.typeParameters,
      ).freshTypeParameters,
      arguments.types,
      typeEnvironment,
      bottomType,
      areGenericArgumentsAllowed: libraryFeatures.genericMetadata.isEnabled,
    );
    _reportTypeArgumentIssues(
      issues,
      fileUri,
      fileOffset,
      inferred: !arguments.hasExplicitTypeArguments,
      // TODO(johnniwinther): Special-case messaging on function type
      //  invocation to avoid reference to 'call' and use the function type
      //  instead.
      targetName: localName ?? 'call',
    );
  }

  void checkBoundsInInstantiation({
    required ProblemReportingHelper problemReportingHelper,
    required LibraryFeatures libraryFeatures,
    required TypeEnvironment typeEnvironment,
    required FunctionType functionType,
    required List<DartType> typeArguments,
    required Uri fileUri,
    required int fileOffset,
    required bool inferred,
  }) {
    if (typeArguments.isEmpty) return;

    if (functionType.typeParameters.length != typeArguments.length) {
      // Coverage-ignore-block(suite): Not run.
      assert(
        problemReportingHelper.assertProblemReportedElsewhere(
          "SourceLibraryBuilder.checkBoundsInInstantiation: "
          "the numbers of type parameters and type arguments don't match.",
          expectedPhase: CompilationPhaseForProblemReporting.outline,
        ),
      );
      return;
    }
    final DartType bottomType = const NeverType.nonNullable();
    List<TypeArgumentIssue> issues = findTypeArgumentIssuesForInvocation(
      getFreshTypeParametersFromStructuralParameters(
        functionType.typeParameters,
      ).freshTypeParameters,
      typeArguments,
      typeEnvironment,
      bottomType,
      areGenericArgumentsAllowed: libraryFeatures.genericMetadata.isEnabled,
    );
    _reportTypeArgumentIssues(
      issues,
      fileUri,
      fileOffset,
      targetReceiver: functionType,
      inferred: inferred,
    );
  }

  void checkBoundsInMethodInvocation({
    required ProblemReportingHelper problemReportingHelper,
    required LibraryFeatures libraryFeatures,
    required DartType receiverType,
    required TypeEnvironment typeEnvironment,
    required ClassHierarchyBase classHierarchy,
    required ClassHierarchyMembers membersHierarchy,
    required Name name,
    required Member? interfaceTarget,
    required ArgumentsImpl arguments,
    required Uri fileUri,
    required int fileOffset,
  }) {
    if (arguments.types.isEmpty) return;
    Class klass;
    List<DartType> receiverTypeArguments;
    Map<TypeParameter, DartType> substitutionMap = <TypeParameter, DartType>{};
    if (receiverType is InterfaceType) {
      klass = receiverType.classNode;
      receiverTypeArguments = receiverType.typeArguments;
      for (int i = 0; i < receiverTypeArguments.length; ++i) {
        substitutionMap[klass.typeParameters[i]] = receiverTypeArguments[i];
      }
    } else {
      return;
    }
    // TODO(cstefantsova): Find a better way than relying on [interfaceTarget].
    Member? method =
        membersHierarchy.getDispatchTarget(klass, name) ?? interfaceTarget;
    if (method == null || method is! Procedure) {
      return;
    }
    if (klass != method.enclosingClass) {
      Supertype parent = classHierarchy.getClassAsInstanceOf(
        klass,
        method.enclosingClass!,
      )!;
      klass = method.enclosingClass!;
      receiverTypeArguments = parent.typeArguments;
      Map<TypeParameter, DartType> instanceSubstitutionMap = substitutionMap;
      substitutionMap = <TypeParameter, DartType>{};
      for (int i = 0; i < receiverTypeArguments.length; ++i) {
        substitutionMap[klass.typeParameters[i]] = substitute(
          receiverTypeArguments[i],
          instanceSubstitutionMap,
        );
      }
    }
    List<TypeParameter> methodParameters = method.function.typeParameters;
    if (methodParameters.length != arguments.types.length) {
      assert(
        problemReportingHelper.assertProblemReportedElsewhere(
          "SourceLibraryBuilder.checkBoundsInMethodInvocation: "
          "the numbers of type parameters and type arguments don't match.",
          expectedPhase: CompilationPhaseForProblemReporting.outline,
        ),
      );
      return;
    }
    List<TypeParameter> methodTypeParametersOfInstantiated =
        getFreshTypeParameters(methodParameters).freshTypeParameters;
    for (TypeParameter typeParameter in methodTypeParametersOfInstantiated) {
      typeParameter.bound = substitute(typeParameter.bound, substitutionMap);
      typeParameter.defaultType = substitute(
        typeParameter.defaultType,
        substitutionMap,
      );
    }

    final DartType bottomType = const NeverType.nonNullable();
    List<TypeArgumentIssue> issues = findTypeArgumentIssuesForInvocation(
      methodTypeParametersOfInstantiated,
      arguments.types,
      typeEnvironment,
      bottomType,
      areGenericArgumentsAllowed: libraryFeatures.genericMetadata.isEnabled,
    );
    _reportTypeArgumentIssues(
      issues,
      fileUri,
      fileOffset,
      inferred: !arguments.hasExplicitTypeArguments,
      targetReceiver: receiverType,
      targetName: name.text,
    );
  }

  void checkBoundsInStaticInvocation({
    required ProblemReportingHelper problemReportingHelper,
    required LibraryFeatures libraryFeatures,
    required String targetName,
    required TypeEnvironment typeEnvironment,
    required Uri fileUri,
    required List<TypeParameter> typeParameters,
    required List<DartType> typeArguments,
    required bool explicitTypeArguments,
    required int fileOffset,
  }) {
    if (typeArguments.isEmpty) return;
    if (typeParameters.length != typeArguments.length) {
      assert(
        problemReportingHelper.assertProblemReportedElsewhere(
          "SourceLibraryBuilder.checkBoundsInStaticInvocation: "
          "the numbers of type parameters and type arguments don't match.",
          expectedPhase: CompilationPhaseForProblemReporting.outline,
        ),
      );
      return;
    }

    final DartType bottomType = const NeverType.nonNullable();
    List<TypeArgumentIssue> issues = findTypeArgumentIssuesForInvocation(
      typeParameters,
      typeArguments,
      typeEnvironment,
      bottomType,
      areGenericArgumentsAllowed: libraryFeatures.genericMetadata.isEnabled,
    );
    if (issues.isNotEmpty) {
      _reportTypeArgumentIssues(
        issues,
        fileUri,
        fileOffset,
        inferred: !explicitTypeArguments,
        targetName: targetName,
      );
    }
  }

  void checkBoundsInType({
    required LibraryFeatures libraryFeatures,
    required DartType type,
    required TypeEnvironment typeEnvironment,
    required Uri fileUri,
    required int fileOffset,
    bool? inferred,
    bool allowSuperBounded = true,
  }) {
    List<TypeArgumentIssue> issues = findTypeArgumentIssues(
      type,
      typeEnvironment,
      allowSuperBounded: allowSuperBounded,
      areGenericArgumentsAllowed: libraryFeatures.genericMetadata.isEnabled,
    );
    _reportTypeArgumentIssues(issues, fileUri, fileOffset, inferred: inferred);
  }

  /// Reports an error if [type] contains is a generic function type used as
  /// a type argument through its alias.
  ///
  /// For instance
  ///
  ///   typedef A = B<void Function<T>(T)>;
  ///
  /// here `A` doesn't use a generic function as type argument directly, but
  /// its unaliased value `B<void Function<T>(T)>` does.
  ///
  /// This is used for reporting generic function types used as a type argument,
  /// which was disallowed before the 'generic-metadata' feature was enabled.
  void checkGenericFunctionTypeAsTypeArgumentThroughTypedef({
    required LibraryFeatures libraryFeatures,
    required TypedefType type,
    required Uri fileUri,
    required int fileOffset,
  }) {
    assert(!libraryFeatures.genericMetadata.isEnabled);
    if (!hasGenericFunctionTypeAsTypeArgument(type)) {
      DartType unaliased = type.unalias;
      if (hasGenericFunctionTypeAsTypeArgument(unaliased)) {
        addProblem(
          codeGenericFunctionTypeAsTypeArgumentThroughTypedef.withArgumentsOld(
            unaliased,
            type,
          ),
          fileOffset,
          noLength,
          fileUri,
        );
      }
    }
  }

  void checkGetterSetterTypes({
    required LibraryFeatures libraryFeatures,
    required TypeEnvironment typeEnvironment,
    required DartType getterType,
    required String getterName,
    required UriOffsetLength getterUriOffset,
    required DartType setterType,
    required String setterName,
    required UriOffsetLength setterUriOffset,
  }) {
    if (libraryFeatures.getterSetterError.isEnabled ||
        getterType is InvalidType ||
        setterType is InvalidType) {
      // Don't report a problem because the it isn't considered a problem in the
      // current Dart version or because something else is wrong that has
      // already been reported.
    } else {
      bool isValid = typeEnvironment.isSubtypeOf(getterType, setterType);
      if (!isValid) {
        addProblem2(
          codeInvalidGetterSetterType.withArgumentsOld(
            getterType,
            getterName,
            setterType,
            setterName,
          ),
          getterUriOffset,
          context: [
            codeInvalidGetterSetterTypeSetterContext
                .withArgumentsOld(setterName)
                .withLocation2(setterUriOffset),
          ],
        );
      }
    }
  }

  /// Checks that non-nullable optional parameters have a default value.
  void checkInitializersInFormals({
    required List<FormalParameterBuilder>? formals,
    required TypeEnvironment typeEnvironment,
    required bool isAbstract,
    required bool isExternal,
  }) {
    if (formals != null && !(isAbstract || isExternal)) {
      for (int i = 0; i < formals.length; i++) {
        FormalParameterBuilder formal = formals[i];
        bool isOptionalPositional =
            formal.isOptionalPositional && formal.isPositional;
        bool isOptionalNamed = !formal.isRequiredNamed && formal.isNamed;
        bool isOptional = isOptionalPositional || isOptionalNamed;
        if (isOptional &&
            formal.variable!.type.isPotentiallyNonNullable &&
            !formal.hasDeclaredInitializer) {
          addProblem(
            codeOptionalNonNullableWithoutInitializerError.withArgumentsOld(
              formal.name,
              formal.variable!.type,
            ),
            formal.fileOffset,
            formal.name.length,
            formal.fileUri,
          );
          formal.variable?.isErroneouslyInitialized = true;
        }
      }
    }
  }

  void checkTypesInField({
    required TypeEnvironment typeEnvironment,
    required bool isInstanceMember,
    required bool isLate,
    required bool isExternal,
    required bool hasInitializer,
    required DartType fieldType,
    required String name,
    required int nameLength,
    required int nameOffset,
    required Uri fileUri,
  }) {
    // Check that the field has an initializer if its type is potentially
    // non-nullable.

    // Only static and top-level fields are checked here.  Instance fields are
    // checked elsewhere.
    if (!isInstanceMember &&
        !isLate &&
        !isExternal &&
        fieldType is! InvalidType &&
        fieldType.isPotentiallyNonNullable &&
        !hasInitializer) {
      addProblem(
        codeFieldNonNullableWithoutInitializerError.withArgumentsOld(
          name,
          fieldType,
        ),
        nameOffset,
        nameLength,
        fileUri,
      );
    }
  }

  void reportTypeArgumentIssue({
    required Message message,
    required Uri fileUri,
    required int fileOffset,
    TypeParameter? typeParameter,
    DartType? superBoundedAttempt,
    DartType? superBoundedAttemptInverted,
  }) {
    List<LocatedMessage>? context;
    // Skip reporting location for function-type type parameters as it's a
    // limitation of Kernel.
    if (typeParameter != null &&
        typeParameter.fileOffset != -1 &&
        typeParameter.location?.file != null) {
      // It looks like when parameters come from augmentation libraries, they
      // don't have a reportable location.
      (context ??= <LocatedMessage>[]).add(
        codeIncorrectTypeArgumentVariable.withLocation(
          typeParameter.location!.file,
          typeParameter.fileOffset,
          noLength,
        ),
      );
    }
    if (superBoundedAttemptInverted != null && superBoundedAttempt != null) {
      // Coverage-ignore-block(suite): Not run.
      (context ??= <LocatedMessage>[]).add(
        codeSuperBoundedHint
            .withArgumentsOld(superBoundedAttempt, superBoundedAttemptInverted)
            .withLocation(fileUri, fileOffset, noLength),
      );
    }
    addProblem(message, fileOffset, noLength, fileUri, context: context);
  }

  void _reportTypeArgumentIssueForStructuralParameter(
    Message message,
    Uri fileUri,
    int fileOffset, {
    TypeParameter? typeParameter,
    DartType? superBoundedAttempt,
    DartType? superBoundedAttemptInverted,
  }) {
    List<LocatedMessage>? context;
    // Skip reporting location for function-type type parameters as it's a
    // limitation of Kernel.
    if (typeParameter != null && typeParameter.location != null) {
      // It looks like when parameters come from augmentation libraries, they
      // don't have a reportable location.
      (context ??= <LocatedMessage>[]).add(
        codeIncorrectTypeArgumentVariable.withLocation(
          typeParameter.location!.file,
          typeParameter.fileOffset,
          noLength,
        ),
      );
    }
    if (superBoundedAttemptInverted != null && superBoundedAttempt != null) {
      (context ??= // Coverage-ignore(suite): Not run.
              <LocatedMessage>[])
          .add(
            codeSuperBoundedHint
                .withArgumentsOld(
                  superBoundedAttempt,
                  superBoundedAttemptInverted,
                )
                .withLocation(fileUri, fileOffset, noLength),
          );
    }
    addProblem(message, fileOffset, noLength, fileUri, context: context);
  }

  void _reportTypeArgumentIssues(
    List<TypeArgumentIssue> issues,
    Uri fileUri,
    int offset, {
    bool? inferred,
    DartType? targetReceiver,
    String? targetName,
  }) {
    for (int i = 0; i < issues.length; i++) {
      TypeArgumentIssue issue = issues[i];
      DartType argument = issue.argument;
      TypeParameter? typeParameter = issue.typeParameter;

      Message message;
      bool issueInferred = inferred ?? false;
      if (issue.isGenericTypeAsArgumentIssue) {
        if (issueInferred) {
          message = codeGenericFunctionTypeInferredAsActualTypeArgument
              .withArgumentsOld(argument);
        } else {
          message = codeGenericFunctionTypeUsedAsActualTypeArgument;
        }
        typeParameter = null;
      } else {
        if (issue.enclosingType == null && targetReceiver != null) {
          if (targetName != null) {
            if (issueInferred) {
              message = codeIncorrectTypeArgumentQualifiedInferred
                  .withArgumentsOld(
                    argument,
                    typeParameter.bound,
                    typeParameter.name!,
                    targetReceiver,
                    targetName,
                  );
            } else {
              message = codeIncorrectTypeArgumentQualified.withArgumentsOld(
                argument,
                typeParameter.bound,
                typeParameter.name!,
                targetReceiver,
                targetName,
              );
            }
          } else {
            if (issueInferred) {
              message = codeIncorrectTypeArgumentInstantiationInferred
                  .withArgumentsOld(
                    argument,
                    typeParameter.bound,
                    typeParameter.name!,
                    targetReceiver,
                  );
            } else {
              message = codeIncorrectTypeArgumentInstantiation.withArgumentsOld(
                argument,
                typeParameter.bound,
                typeParameter.name!,
                targetReceiver,
              );
            }
          }
        } else {
          String enclosingName = issue.enclosingType == null
              ? targetName!
              : getGenericTypeName(issue.enclosingType!);
          if (issueInferred) {
            message = codeIncorrectTypeArgumentInferred.withArgumentsOld(
              argument,
              typeParameter.bound,
              typeParameter.name!,
              enclosingName,
            );
          } else {
            message = codeIncorrectTypeArgument.withArgumentsOld(
              argument,
              typeParameter.bound,
              typeParameter.name!,
              enclosingName,
            );
          }
        }
      }

      // Don't show the hint about an attempted super-bounded type if the issue
      // with the argument is that it's generic.
      _reportTypeArgumentIssueForStructuralParameter(
        message,
        fileUri,
        offset,
        typeParameter: typeParameter,
        superBoundedAttempt: issue.isGenericTypeAsArgumentIssue
            ? null
            : issue.enclosingType,
        superBoundedAttemptInverted: issue.isGenericTypeAsArgumentIssue
            ? null
            : issue.invertedType,
      );
    }
  }

  LocatedMessage? checkArgumentsForType({
    required FunctionType function,
    required Arguments arguments,
    required Uri fileUri,
    required int fileOffset,
  }) {
    int requiredPositionalParameterCountToReport =
        function.requiredParameterCount;
    int positionalParameterCountToReport = function.positionalParameters.length;
    int positionalArgumentCountToReport = arguments.positional.length;
    if (arguments.positional.length < function.requiredParameterCount) {
      return codeTooFewArguments
          .withArgumentsOld(
            requiredPositionalParameterCountToReport,
            positionalArgumentCountToReport,
          )
          .withLocation(fileUri, arguments.fileOffset, noLength);
    }
    if (arguments.positional.length > function.positionalParameters.length) {
      return codeTooManyArguments
          .withArgumentsOld(
            positionalParameterCountToReport,
            positionalArgumentCountToReport,
          )
          .withLocation(fileUri, arguments.fileOffset, noLength);
    }
    List<NamedExpression> named = arguments.named;
    if (named.isNotEmpty) {
      Set<String> names = new Set.of(
        function.namedParameters.map((a) => a.name),
      );
      for (int i = 0; i < named.length; i++) {
        NamedExpression argument = named[i];
        if (!names.contains(argument.name)) {
          return codeNoSuchNamedParameter
              .withArgumentsOld(argument.name)
              .withLocation(fileUri, argument.fileOffset, argument.name.length);
        }
      }
    }
    if (function.namedParameters.isNotEmpty) {
      Set<String> argumentNames = new Set.of(named.map((a) => a.name));
      for (int i = 0; i < function.namedParameters.length; i++) {
        NamedType parameter = function.namedParameters[i];
        if (parameter.isRequired && !argumentNames.contains(parameter.name)) {
          return codeValueForRequiredParameterNotProvidedError
              .withArgumentsOld(parameter.name)
              .withLocation(fileUri, arguments.fileOffset, noLength);
        }
      }
    }
    List<Object> types = arguments.types;
    List<StructuralParameter> typeParameters = function.typeParameters;
    if (typeParameters.length != types.length && types.length != 0) {
      // A wrong (non-zero) amount of type arguments given. That's an error.
      // TODO(jensj): Position should be on type arguments instead.
      return codeTypeArgumentMismatch
          .withArgumentsOld(typeParameters.length)
          .withLocation(fileUri, fileOffset, noLength);
    }

    return null;
  }

  Expression buildProblemWithContextFromMember({
    required CompilerContext compilerContext,
    required String name,
    required Member member,
    required LocatedMessage message,
    required Uri fileUri,
  }) {
    List<LocatedMessage>? context;
    Location? location = member.location;
    if (location != null) {
      Uri uri = location.file;
      int offset = member.fileOffset;
      Message contextMessage;
      int length = noLength;
      if (member is Constructor && member.isSynthetic) {
        offset = member.enclosingClass.fileOffset;
        contextMessage = codeCandidateFoundIsDefaultConstructor
            .withArgumentsOld(member.enclosingClass.name);
      } else {
        if (member is Constructor) {
          if (member.name.text == '') {
            length = member.enclosingClass.name.length;
          } else {
            // Assume no spaces around the dot. Not perfect, but probably the
            // best we can do with the information available.
            length = member.enclosingClass.name.length + 1 + name.length;
          }
        } else {
          length = name.length;
        }
        contextMessage = codeCandidateFound;
      }
      context = [contextMessage.withLocation(uri, offset, length)];
    }
    return buildProblem(
      compilerContext: compilerContext,
      message: message.messageObject,
      fileUri: fileUri,
      fileOffset: message.charOffset,
      length: message.length,
      context: context,
    );
  }

  InvalidExpression buildProblem({
    required CompilerContext compilerContext,
    required Message message,
    required Uri fileUri,
    required int fileOffset,
    required int length,
    List<LocatedMessage>? context,
    bool errorHasBeenReported = false,
    Expression? expression,
  }) {
    if (!errorHasBeenReported) {
      addProblem(
        message,
        fileOffset,
        length,
        fileUri,
        wasHandled: true,
        context: context,
      );
    }
    String text = compilerContext
        .format(
          message.withLocation(fileUri, fileOffset, length),
          CfeSeverity.error,
        )
        .plain;
    return new InvalidExpression(text, expression)..fileOffset = fileOffset;
  }

  LocatedMessage? checkArgumentsForFunction({
    required FunctionNode function,
    required Arguments arguments,
    required int fileOffset,
    required Uri fileUri,
    required List<TypeParameter> typeParameters,
    Extension? extension,
  }) {
    int typeParameterCount = typeParameters.length;
    int requiredParameterCount = function.requiredParameterCount;
    int positionalParameterCount = function.positionalParameters.length;
    int positionalArgumentsCount = arguments.positional.length;
    if (extension != null) {
      // Extension member invocations have additional synthetic parameter for
      // `this`.
      --requiredParameterCount;
      --positionalParameterCount;
      typeParameterCount -= extension.typeParameters.length;
    }
    if (positionalArgumentsCount < requiredParameterCount) {
      return codeTooFewArguments
          .withArgumentsOld(requiredParameterCount, positionalArgumentsCount)
          .withLocation(fileUri, arguments.fileOffset, noLength);
    }
    if (positionalArgumentsCount > positionalParameterCount) {
      return codeTooManyArguments
          .withArgumentsOld(positionalParameterCount, positionalArgumentsCount)
          .withLocation(fileUri, arguments.fileOffset, noLength);
    }
    List<NamedExpression> named = arguments.named;
    if (named.isNotEmpty) {
      Set<String?> parameterNames = new Set.of(
        function.namedParameters.map((a) => a.name),
      );
      for (int i = 0; i < named.length; i++) {
        NamedExpression argument = named[i];
        if (!parameterNames.contains(argument.name)) {
          return codeNoSuchNamedParameter
              .withArgumentsOld(argument.name)
              .withLocation(fileUri, argument.fileOffset, argument.name.length);
        }
      }
    }
    if (function.namedParameters.isNotEmpty) {
      Set<String> argumentNames = new Set.of(named.map((a) => a.name));
      for (int i = 0; i < function.namedParameters.length; i++) {
        VariableDeclaration parameter = function.namedParameters[i];
        if (parameter.isRequired && !argumentNames.contains(parameter.name)) {
          return codeValueForRequiredParameterNotProvidedError
              .withArgumentsOld(parameter.name!)
              .withLocation(fileUri, arguments.fileOffset, noLength);
        }
      }
    }

    List<DartType> types = arguments.types;
    if (typeParameterCount != types.length) {
      if (types.length == 0) {
        // Expected `typeParameters.length` type arguments, but none given, so
        // we use type inference.
      } else {
        // A wrong (non-zero) amount of type arguments given. That's an error.
        // TODO(jensj): Position should be on type arguments instead.
        return codeTypeArgumentMismatch
            .withArgumentsOld(typeParameterCount)
            .withLocation(fileUri, fileOffset, noLength);
      }
    }

    return null;
  }

  Expression? checkStaticArguments({
    required CompilerContext compilerContext,
    required Member target,
    required Arguments arguments,
    required int fileOffset,
    required Uri fileUri,
  }) {
    List<TypeParameter> typeParameters = target.function!.typeParameters;
    if (target is Constructor) {
      assert(!target.enclosingClass.isAbstract);
      typeParameters = target.enclosingClass.typeParameters;
    }
    LocatedMessage? argMessage = checkArgumentsForFunction(
      function: target.function!,
      arguments: arguments,
      fileOffset: fileOffset,
      fileUri: fileUri,
      typeParameters: typeParameters,
    );
    if (argMessage != null) {
      return buildProblemWithContextFromMember(
        compilerContext: compilerContext,
        name: target.name.text,
        member: target,
        message: argMessage,
        fileUri: fileUri,
      );
    }
    return null;
  }

  Expression wrapInProblem({
    required CompilerContext compilerContext,
    required Expression expression,
    required Message message,
    required Uri fileUri,
    required int fileOffset,
    required int length,
    List<LocatedMessage>? context,
    bool? errorHasBeenReported,
    bool includeExpression = true,
  }) {
    CfeSeverity severity = message.code.severity;
    if (severity == CfeSeverity.error) {
      return wrapInLocatedProblem(
        compilerContext: compilerContext,
        expression: expression,
        message: message.withLocation(fileUri, fileOffset, length),
        context: context,
        errorHasBeenReported:
            errorHasBeenReported ?? expression is InvalidExpression,
        includeExpression: includeExpression,
      );
    } else {
      // Coverage-ignore-block(suite): Not run.
      if (expression is! InvalidExpression) {
        addProblem(message, fileOffset, length, fileUri, context: context);
      }
      return expression;
    }
  }

  Expression wrapInLocatedProblem({
    required CompilerContext compilerContext,
    required Expression expression,
    required LocatedMessage message,
    List<LocatedMessage>? context,
    bool errorHasBeenReported = false,
    bool includeExpression = true,
  }) {
    // TODO(askesc): Produce explicit error expression wrapping the original.
    // See [issue 29717](https://github.com/dart-lang/sdk/issues/29717)
    int offset = expression.fileOffset;
    if (offset == -1) {
      offset = message.charOffset;
    }
    return buildProblem(
      compilerContext: compilerContext,
      message: message.messageObject,
      fileUri: message.uri!,
      fileOffset: message.charOffset,
      length: message.length,
      context: context,
      expression: includeExpression ? expression : null,
      errorHasBeenReported: errorHasBeenReported,
    );
  }
}
