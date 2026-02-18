// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/parser/parser.dart'
    show FormalParameterKind;
import 'package:_fe_analyzer_shared/src/scanner/token_impl.dart'
    show correspondingPublicName;
import 'package:_fe_analyzer_shared/src/scanner/token.dart' show Token;
import 'package:front_end/src/codes/diagnostic.dart' as diag;
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
import '../builder/compilation_unit.dart';
import '../builder/formal_parameter_builder.dart';
import '../builder/type_builder.dart';
import '../kernel/internal_ast.dart';
import 'source_library_builder.dart';

extension CheckHelper on ProblemReporting {
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
        contextMessage = diag.candidateFoundIsDefaultConstructor.withArguments(
          name: member.enclosingClass.name,
        );
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
        contextMessage = diag.candidateFound;
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

  InvalidExpression buildProblemFromLocatedMessage({
    required CompilerContext compilerContext,
    required LocatedMessage message,
  }) {
    return buildProblem(
      compilerContext: compilerContext,
      message: message.messageObject,
      fileUri: message.uri!,
      fileOffset: message.charOffset,
      length: message.length,
    );
  }

  LocatedMessage? checkArgumentsForFunction({
    required FunctionNode function,
    required TypeArguments? explicitTypeArguments,
    required ActualArguments arguments,
    required int fileOffset,
    required Uri fileUri,
    required List<TypeParameter> typeParameters,
    Extension? extension,
  }) {
    int typeParameterCount = typeParameters.length;
    int requiredParameterCount = function.requiredParameterCount;
    int positionalParameterCount = function.positionalParameters.length;
    int positionalArgumentsCount = arguments.positionalCount;
    if (extension != null) {
      // Extension member invocations have additional synthetic parameter for
      // `this`.
      --requiredParameterCount;
      --positionalParameterCount;
      typeParameterCount -= extension.typeParameters.length;
    }
    if (positionalArgumentsCount < requiredParameterCount) {
      return diag.tooFewArguments
          .withArguments(
            requiredParameterCount: requiredParameterCount,
            actualArgumentCount: positionalArgumentsCount,
          )
          .withLocation(fileUri, arguments.fileOffset, noLength);
    }
    if (positionalArgumentsCount > positionalParameterCount) {
      return diag.tooManyArguments
          .withArguments(
            allowedParameterCount: positionalParameterCount,
            actualArgumentCount: positionalArgumentsCount,
          )
          .withLocation(fileUri, arguments.fileOffset, noLength);
    }
    Set<String> argumentNames = {};
    if (arguments.namedCount > 0) {
      Set<String?> parameterNames = new Set.of(
        function.namedParameters.map((a) => a.name),
      );
      for (Argument argument in arguments.argumentList) {
        switch (argument) {
          case NamedArgument():
            NamedExpression namedExpression = argument.namedExpression;
            String name = namedExpression.name;
            argumentNames.add(name);
            if (!parameterNames.contains(name)) {
              return diag.noSuchNamedParameter
                  .withArguments(name: name)
                  .withLocation(
                    fileUri,
                    namedExpression.fileOffset,
                    name.length,
                  );
            }
          case PositionalArgument():
            break;
        }
      }
    }
    if (function.namedParameters.isNotEmpty) {
      for (int i = 0; i < function.namedParameters.length; i++) {
        VariableDeclaration parameter = function.namedParameters[i];
        if (parameter.isRequired && !argumentNames.contains(parameter.name!)) {
          return diag.valueForRequiredParameterNotProvidedError
              .withArguments(parameterName: parameter.name!)
              .withLocation(fileUri, arguments.fileOffset, noLength);
        }
      }
    }

    if (explicitTypeArguments != null) {
      if (typeParameterCount != explicitTypeArguments.types.length) {
        // A wrong (non-zero) amount of type arguments given. That's an error.
        // TODO(jensj): Position should be on type arguments instead.
        return diag.typeArgumentMismatch
            .withArguments(expectedCount: typeParameterCount)
            .withLocation(fileUri, fileOffset, noLength);
      }
    }

    return null;
  }

  LocatedMessage? checkArgumentsForType({
    required FunctionType function,
    required TypeArguments? explicitTypeArguments,
    required ActualArguments arguments,
    required Uri fileUri,
    required int fileOffset,
  }) {
    int requiredPositionalParameterCountToReport =
        function.requiredParameterCount;
    int positionalParameterCountToReport = function.positionalParameters.length;
    int positionalArgumentCountToReport = arguments.positionalCount;
    if (positionalArgumentCountToReport < function.requiredParameterCount) {
      return diag.tooFewArguments
          .withArguments(
            requiredParameterCount: requiredPositionalParameterCountToReport,
            actualArgumentCount: positionalArgumentCountToReport,
          )
          .withLocation(fileUri, arguments.fileOffset, noLength);
    }
    if (positionalArgumentCountToReport >
        function.positionalParameters.length) {
      return diag.tooManyArguments
          .withArguments(
            allowedParameterCount: positionalParameterCountToReport,
            actualArgumentCount: positionalArgumentCountToReport,
          )
          .withLocation(fileUri, arguments.fileOffset, noLength);
    }
    Set<String> argumentNames = {};
    if (arguments.namedCount > 0) {
      Set<String> names = new Set.of(
        function.namedParameters.map((a) => a.name),
      );
      for (Argument argument in arguments.argumentList) {
        switch (argument) {
          case NamedArgument():
            NamedExpression namedExpression = argument.namedExpression;
            String name = namedExpression.name;
            argumentNames.add(name);
            if (!names.contains(name)) {
              return diag.noSuchNamedParameter
                  .withArguments(name: name)
                  .withLocation(
                    fileUri,
                    namedExpression.fileOffset,
                    name.length,
                  );
            }
          case PositionalArgument():
            break;
        }
      }
    }
    if (function.namedParameters.isNotEmpty) {
      for (int i = 0; i < function.namedParameters.length; i++) {
        NamedType parameter = function.namedParameters[i];
        if (parameter.isRequired && !argumentNames.contains(parameter.name)) {
          return diag.valueForRequiredParameterNotProvidedError
              .withArguments(parameterName: parameter.name)
              .withLocation(fileUri, arguments.fileOffset, noLength);
        }
      }
    }
    List<StructuralParameter> typeParameters = function.typeParameters;
    if (explicitTypeArguments != null &&
        typeParameters.length != explicitTypeArguments.types.length) {
      // A wrong (non-zero) amount of type arguments given. That's an error.
      // TODO(jensj): Position should be on type arguments instead.
      return diag.typeArgumentMismatch
          .withArguments(expectedCount: typeParameters.length)
          .withLocation(fileUri, fileOffset, noLength);
    }

    return null;
  }

  void checkAsyncReturnType({
    required SourceLibraryBuilder libraryBuilder,
    required TypeEnvironment typeEnvironment,
    required AsyncMarker asyncMarker,
    required DartType returnType,
    required TypeBuilder returnTypeBuilder,
    required Uri fileUri,
  }) {
    // For async, async*, and sync* functions with declared return types, we
    // need to determine whether those types are valid.
    // We use the same trick in each case below. For example to decide whether
    // Future<T> <: [returnType] for every T, we rely on Future<Bot> and
    // transitivity of the subtyping relation because Future<Bot> <: Future<T>
    // for every T.

    // We use [problem == null] to signal success.
    Message? problem;
    switch (asyncMarker) {
      case AsyncMarker.Async:
        DartType futureBottomType = libraryBuilder.loader.futureOfBottom;
        if (!typeEnvironment.isSubtypeOf(futureBottomType, returnType)) {
          problem = diag.illegalAsyncReturnType;
        }
        break;

      case AsyncMarker.AsyncStar:
        DartType streamBottomType = libraryBuilder.loader.streamOfBottom;
        if (returnType is VoidType) {
          problem = diag.illegalAsyncGeneratorVoidReturnType;
        } else if (!typeEnvironment.isSubtypeOf(streamBottomType, returnType)) {
          problem = diag.illegalAsyncGeneratorReturnType;
        }
        break;

      case AsyncMarker.SyncStar:
        DartType iterableBottomType = libraryBuilder.loader.iterableOfBottom;
        if (returnType is VoidType) {
          problem = diag.illegalSyncGeneratorVoidReturnType;
        } else if (!typeEnvironment.isSubtypeOf(
          iterableBottomType,
          returnType,
        )) {
          problem = diag.illegalSyncGeneratorReturnType;
        }
        break;

      case AsyncMarker.Sync:
        break; // skip
    }

    if (problem != null) {
      TypeName? typeName = returnTypeBuilder.typeName;
      addProblem(
        problem,
        typeName?.fullNameOffset ?? // Coverage-ignore(suite): Not run.
            returnTypeBuilder.charOffset!,
        typeName?.fullNameLength ?? noLength,
        fileUri,
      );
    }
  }

  void checkBoundsInConstructorInvocation({
    required LibraryFeatures libraryFeatures,
    required Constructor constructor,
    required List<DartType> explicitOrInferredTypeArguments,
    required TypeEnvironment typeEnvironment,
    required Uri fileUri,
    required int fileOffset,
    required bool hasInferredTypeArguments,
  }) {
    if (explicitOrInferredTypeArguments.isEmpty) return;
    Class klass = constructor.enclosingClass;
    DartType constructedType = new InterfaceType(
      klass,
      klass.enclosingLibrary.nonNullable,
      explicitOrInferredTypeArguments,
    );
    checkBoundsInType(
      libraryFeatures: libraryFeatures,
      type: constructedType,
      typeEnvironment: typeEnvironment,
      fileUri: fileUri,
      fileOffset: fileOffset,
      hasInferredTypeArguments: hasInferredTypeArguments,
      allowSuperBounded: false,
    );
  }

  void checkBoundsInFactoryInvocation({
    required LibraryFeatures libraryFeatures,
    required Procedure factory,
    required List<DartType> explicitOrInferredTypeArguments,
    required TypeEnvironment typeEnvironment,
    required Uri fileUri,
    required int fileOffset,
    required bool hasInferredTypeArguments,
  }) {
    if (explicitOrInferredTypeArguments.isEmpty) {
      return;
    }
    assert(factory.isFactory || factory.isExtensionTypeMember);
    DartType constructedType = Substitution.fromPairs(
      factory.function.typeParameters,
      explicitOrInferredTypeArguments,
    ).substituteType(factory.function.returnType);
    checkBoundsInType(
      libraryFeatures: libraryFeatures,
      type: constructedType,
      typeEnvironment: typeEnvironment,
      fileUri: fileUri,
      fileOffset: fileOffset,
      hasInferredTypeArguments: hasInferredTypeArguments,
      allowSuperBounded: false,
    );
  }

  void checkBoundsInFunctionInvocation({
    required ProblemReportingHelper problemReportingHelper,
    required LibraryFeatures libraryFeatures,
    required TypeEnvironment typeEnvironment,
    required FunctionType functionType,
    required String? localName,
    required List<DartType> explicitOrInferredTypeArguments,
    required ActualArguments arguments,
    required Uri fileUri,
    required int fileOffset,
    required bool hasInferredTypeArguments,
  }) {
    if (explicitOrInferredTypeArguments.isEmpty) {
      return;
    }

    if (functionType.typeParameters.length !=
        explicitOrInferredTypeArguments.length) {
      // Coverage-ignore-block(suite): Not run.
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
      explicitOrInferredTypeArguments,
      typeEnvironment,
      bottomType,
      areGenericArgumentsAllowed: libraryFeatures.genericMetadata.isEnabled,
    );
    _reportTypeArgumentIssues(
      issues,
      fileUri,
      fileOffset,
      inferred: hasInferredTypeArguments,
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
    required List<DartType> explicitOrInferredTypeArguments,
    required Uri fileUri,
    required int fileOffset,
    required bool hasInferredTypeArguments,
  }) {
    if (explicitOrInferredTypeArguments.isEmpty) {
      return;
    }

    if (functionType.typeParameters.length !=
        explicitOrInferredTypeArguments.length) {
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
      explicitOrInferredTypeArguments,
      typeEnvironment,
      bottomType,
      areGenericArgumentsAllowed: libraryFeatures.genericMetadata.isEnabled,
    );
    _reportTypeArgumentIssues(
      issues,
      fileUri,
      fileOffset,
      targetReceiver: functionType,
      inferred: hasInferredTypeArguments,
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
    required List<DartType> explicitOrInferredTypeArguments,
    required ActualArguments arguments,
    required Uri fileUri,
    required int fileOffset,
    required bool hasInferredTypeArguments,
  }) {
    if (explicitOrInferredTypeArguments.isEmpty) {
      return;
    }
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
    if (methodParameters.length != explicitOrInferredTypeArguments.length) {
      // Coverage-ignore-block(suite): Not run.
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
      explicitOrInferredTypeArguments,
      typeEnvironment,
      bottomType,
      areGenericArgumentsAllowed: libraryFeatures.genericMetadata.isEnabled,
    );
    _reportTypeArgumentIssues(
      issues,
      fileUri,
      fileOffset,
      inferred: hasInferredTypeArguments,
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
    required List<DartType> explicitOrInferredTypeArguments,
    required bool hasInferredTypeArguments,
    required int fileOffset,
  }) {
    if (explicitOrInferredTypeArguments.isEmpty) return;
    if (typeParameters.length != explicitOrInferredTypeArguments.length) {
      // Coverage-ignore-block(suite): Not run.
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
      explicitOrInferredTypeArguments,
      typeEnvironment,
      bottomType,
      areGenericArgumentsAllowed: libraryFeatures.genericMetadata.isEnabled,
    );
    if (issues.isNotEmpty) {
      _reportTypeArgumentIssues(
        issues,
        fileUri,
        fileOffset,
        inferred: hasInferredTypeArguments,
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
    required bool hasInferredTypeArguments,
    bool allowSuperBounded = true,
  }) {
    List<TypeArgumentIssue> issues = findTypeArgumentIssues(
      type,
      typeEnvironment,
      allowSuperBounded: allowSuperBounded,
      areGenericArgumentsAllowed: libraryFeatures.genericMetadata.isEnabled,
    );
    _reportTypeArgumentIssues(
      issues,
      fileUri,
      fileOffset,
      inferred: hasInferredTypeArguments,
    );
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
          diag.genericFunctionTypeAsTypeArgumentThroughTypedef.withArguments(
            genericFunctionType: unaliased,
            aliasType: type,
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
          diag.invalidGetterSetterType.withArguments(
            getterType: getterType,
            getterName: getterName,
            setterType: setterType,
            setterName: setterName,
          ),
          getterUriOffset,
          context: [
            diag.invalidGetterSetterTypeSetterContext
                .withArguments(setterName: setterName)
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
            diag.optionalNonNullableWithoutInitializerError.withArguments(
              parameterName: formal.name,
              parameterType: formal.variable!.type,
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

  Expression? checkStaticArguments({
    required CompilerContext compilerContext,
    required Member target,
    required TypeArguments? explicitTypeArguments,
    required ActualArguments arguments,
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
      explicitTypeArguments: explicitTypeArguments,
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
        diag.fieldNonNullableWithoutInitializerError.withArguments(
          fieldName: name,
          fieldType: fieldType,
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
        diag.incorrectTypeArgumentVariable.withLocation(
          typeParameter.location!.file,
          typeParameter.fileOffset,
          noLength,
        ),
      );
    }
    if (superBoundedAttemptInverted != null && superBoundedAttempt != null) {
      // Coverage-ignore-block(suite): Not run.
      (context ??= <LocatedMessage>[]).add(
        diag.superBoundedHint
            .withArguments(
              attemptedType: superBoundedAttempt,
              invertedType: superBoundedAttemptInverted,
            )
            .withLocation(fileUri, fileOffset, noLength),
      );
    }
    addProblem(message, fileOffset, noLength, fileUri, context: context);
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
        diag.incorrectTypeArgumentVariable.withLocation(
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
            diag.superBoundedHint
                .withArguments(
                  attemptedType: superBoundedAttempt,
                  invertedType: superBoundedAttemptInverted,
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
    required bool inferred,
    DartType? targetReceiver,
    String? targetName,
  }) {
    for (int i = 0; i < issues.length; i++) {
      TypeArgumentIssue issue = issues[i];
      DartType argument = issue.argument;
      TypeParameter? typeParameter = issue.typeParameter;

      Message message;
      if (issue.isGenericTypeAsArgumentIssue) {
        if (inferred) {
          message = diag.genericFunctionTypeInferredAsActualTypeArgument
              .withArguments(type: argument);
        } else {
          message = diag.genericFunctionTypeUsedAsActualTypeArgument;
        }
        typeParameter = null;
      } else {
        if (issue.enclosingType == null && targetReceiver != null) {
          if (targetName != null) {
            if (inferred) {
              message = diag.incorrectTypeArgumentQualifiedInferred
                  .withArguments(
                    typeArgument: argument,
                    typeParameterBound: typeParameter.bound,
                    typeParameterName: typeParameter.name!,
                    receiverType: targetReceiver,
                    targetName: targetName,
                  );
            } else {
              message = diag.incorrectTypeArgumentQualified.withArguments(
                typeArgument: argument,
                typeParameterBound: typeParameter.bound,
                typeParameterName: typeParameter.name!,
                receiverType: targetReceiver,
                targetName: targetName,
              );
            }
          } else {
            if (inferred) {
              message = diag.incorrectTypeArgumentInstantiationInferred
                  .withArguments(
                    typeArgument: argument,
                    typeParameterBound: typeParameter.bound,
                    typeParameterName: typeParameter.name!,
                    receiverType: targetReceiver,
                  );
            } else {
              message = diag.incorrectTypeArgumentInstantiation.withArguments(
                typeArgument: argument,
                typeParameterBound: typeParameter.bound,
                typeParameterName: typeParameter.name!,
                receiverType: targetReceiver,
              );
            }
          }
        } else {
          String enclosingName = issue.enclosingType == null
              ? targetName!
              : getGenericTypeName(issue.enclosingType!);
          if (inferred) {
            message = diag.incorrectTypeArgumentInferred.withArguments(
              typeArgument: argument,
              typeParameterBound: typeParameter.bound,
              typeParameterName: typeParameter.name!,
              enclosingName: enclosingName,
            );
          } else {
            message = diag.incorrectTypeArgument.withArguments(
              typeArgument: argument,
              typeParameterBound: typeParameter.bound,
              typeParameterName: typeParameter.name!,
              enclosingName: enclosingName,
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

  /// Checks that [parameterName] has a corresponding public name.
  ///
  /// If [parameterName] is private an error is reported if [parameterName]
  /// does not have corresponding public name or if the private named parameter
  /// feature is not enabled.
  ///
  /// If [parameterName] has a corresponding public name, this is returned.
  /// Otherwise `null` is returned, including the case where [parameterName] is
  /// not private.
  String? checkPublicName({
    required SourceCompilationUnit compilationUnit,
    required FormalParameterKind kind,
    required String parameterName,
    required Token nameToken,
    required Token? thisKeyword,
    required bool isDeclaring,
    required LibraryFeatures libraryFeatures,
    required Uri fileUri,
  }) {
    // If we're building a private named parameter, then calculate the
    // corresponding public name. The variable declared by the parameter will
    // use that name instead.
    String? publicName;
    if (kind.isNamed && parameterName.startsWith('_')) {
      // TODO(rnystrom): Also handle declaring field parameters.
      bool refersToField = thisKeyword != null || isDeclaring;

      if (libraryFeatures.privateNamedParameters.isEnabled) {
        if (!refersToField) {
          addProblem(
            diag.privateNamedNonFieldParameter,
            nameToken.charOffset,
            nameToken.length,
            fileUri,
          );
        } else {
          publicName = correspondingPublicName(parameterName);

          // Only report the error for no corresponding public name if this
          // is a parameter that could be private and named.
          if (publicName == null) {
            addProblem(
              diag.privateNamedParameterWithoutPublicName,
              nameToken.charOffset,
              nameToken.length,
              fileUri,
            );
          }
        }
      } else {
        if (refersToField) {
          compilationUnit.reportFeatureNotEnabled(
            libraryFeatures.privateNamedParameters,
            fileUri,
            nameToken.charOffset,
            nameToken.length,
          );
        } else {
          addProblem(
            diag.privateNamedParameter,
            nameToken.charOffset,
            nameToken.length,
            fileUri,
          );
        }
      }
    }
    return publicName;
  }
}
