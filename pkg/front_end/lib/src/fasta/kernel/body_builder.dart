// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.body_builder;

import 'dart:core' hide MapEntry;

import '../constant_context.dart' show ConstantContext;

import '../fasta_codes.dart' as fasta;

import '../fasta_codes.dart' show LocatedMessage, Message, noLength, Template;

import '../messages.dart' as messages show getLocationFromUri;

import '../modifier.dart' show Modifier, constMask, covariantMask, finalMask;

import '../names.dart'
    show callName, emptyName, indexGetName, indexSetName, minusName, plusName;

import '../parser.dart'
    show
        Assert,
        Parser,
        FormalParameterKind,
        IdentifierContext,
        MemberKind,
        lengthForToken,
        lengthOfSpan,
        offsetForToken,
        optional;

import '../problems.dart'
    show internalProblem, unexpected, unhandled, unsupported;

import '../quote.dart'
    show
        Quote,
        analyzeQuote,
        unescape,
        unescapeFirstStringPart,
        unescapeLastStringPart,
        unescapeString;

import '../scanner.dart' show Token;

import '../scanner/token.dart'
    show isBinaryOperator, isMinusOperator, isUserDefinableOperator;

import '../scope.dart' show ProblemBuilder;

import '../severity.dart' show Severity;

import '../source/scope_listener.dart'
    show
        FixedNullableList,
        GrowableList,
        JumpTargetKind,
        NullValue,
        ParserRecovery,
        ScopeListener;

import '../type_inference/type_inferrer.dart' show TypeInferrer;

import '../type_inference/type_promotion.dart'
    show TypePromoter, TypePromotionFact, TypePromotionScope;

import 'collections.dart'
    show
        SpreadElement,
        SpreadMapEntry,
        convertToMapEntry,
        isConvertibleToMapEntry;

import 'constness.dart' show Constness;

import 'expression_generator.dart'
    show
        DelayedAssignment,
        DelayedPostfixIncrement,
        Generator,
        IncompleteErrorGenerator,
        IncompletePropertyAccessGenerator,
        IncompleteSendGenerator,
        IndexedAccessGenerator,
        LoadLibraryGenerator,
        ParenthesizedExpressionGenerator,
        ParserErrorGenerator,
        PrefixUseGenerator,
        ReadOnlyAccessGenerator,
        SendAccessGenerator,
        StaticAccessGenerator,
        SuperIndexedAccessGenerator,
        ThisAccessGenerator,
        ThisPropertyAccessGenerator,
        TypeUseGenerator,
        UnlinkedGenerator,
        UnresolvedNameGenerator,
        VariableUseGenerator,
        buildIsNull;

import 'expression_generator_helper.dart' show ExpressionGeneratorHelper;

import 'forest.dart' show Forest;

import 'implicit_type_argument.dart' show ImplicitTypeArgument;

import 'kernel_shadow_ast.dart' as shadow
    show SyntheticExpressionJudgment, SyntheticWrapper;

import 'redirecting_factory_body.dart'
    show
        RedirectingFactoryBody,
        RedirectionTarget,
        getRedirectingFactoryBody,
        getRedirectionTarget,
        isRedirectingFactory;

import 'type_algorithms.dart' show calculateBounds;

import 'kernel_api.dart';

import 'kernel_ast_api.dart';

import 'kernel_builder.dart';

// TODO(ahe): Remove this and ensure all nodes have a location.
const noLocation = null;

// TODO(danrubel): Remove this once control flow and spread collection support
// has been enabled by default.
const invalidCollectionElement = const Object();

abstract class BodyBuilder extends ScopeListener<JumpTarget>
    implements ExpressionGeneratorHelper {
  // TODO(ahe): Rename [library] to 'part'.
  @override
  final KernelLibraryBuilder library;

  final ModifierBuilder member;

  final KernelClassBuilder classBuilder;

  final ClassHierarchy hierarchy;

  @override
  final CoreTypes coreTypes;

  final bool isInstanceMember;

  final Scope enclosingScope;

  final bool enableNative;

  final bool stringExpectedAfterNative;

  /// Whether to ignore an unresolved reference to `main` within the body of
  /// `_getMainClosure` when compiling the current library.
  ///
  /// This as a temporary workaround. The standalone VM and flutter have
  /// special logic to resolve `main` in `_getMainClosure`, this flag is used to
  /// ignore that reference to `main`, but only on libraries where we expect to
  /// see it (today that is dart:_builtin and dart:ui).
  ///
  // TODO(ahe,sigmund): remove when the VM gets rid of the special rule, see
  // https://github.com/dart-lang/sdk/issues/28989.
  final bool ignoreMainInGetMainClosure;

  // TODO(ahe): Consider renaming [uri] to 'partUri'.
  @override
  final Uri uri;

  final TypeInferrer _typeInferrer;

  @override
  final TypePromoter typePromoter;

  @override
  final bool legacyMode;

  /// Only used when [member] is a constructor. It tracks if an implicit super
  /// initializer is needed.
  ///
  /// An implicit super initializer isn't needed
  ///
  /// 1. if the current class is Object,
  /// 2. if there is an explicit super initializer,
  /// 3. if there is a redirecting (this) initializer, or
  /// 4. if a compile-time error prevented us from generating code for an
  ///    initializer. This avoids cascading errors.
  bool needsImplicitSuperInitializer;

  Scope formalParameterScope;

  /// This is set to true when we start parsing an initializer. We use this to
  /// find the correct scope for initializers like in this example:
  ///
  ///     class C {
  ///       final x;
  ///       C(x) : x = x;
  ///     }
  ///
  /// When parsing this initializer `x = x`, `x` must be resolved in two
  /// different scopes. The first `x` must be resolved in the class' scope, the
  /// second in the formal parameter scope.
  bool inInitializer = false;

  bool inFieldInitializer = false;

  bool inCatchClause = false;

  bool inCatchBlock = false;

  int functionNestingLevel = 0;

  // Set when a spread element is encountered in a collection so the collection
  // needs to be desugared after type inference.
  bool transformCollections = false;

  // Set by type inference when a set literal is encountered that needs to be
  // transformed because the backend target does not support set literals.
  bool transformSetLiterals = false;

  Statement problemInLoopOrSwitch;

  Scope switchScope;

  CloneVisitor cloner;

  ConstantContext constantContext = ConstantContext.none;

  UnresolvedType<KernelTypeBuilder> currentLocalVariableType;

  // Using non-null value to initialize this field based on performance advice
  // from VM engineers. TODO(ahe): Does this still apply?
  int currentLocalVariableModifiers = -1;

  /// If non-null, records instance fields which have already been initialized
  /// and where that was.
  Map<String, int> initializedFields;

  /// List of built redirecting factory invocations.  The targets of the
  /// invocations are to be resolved in a separate step.
  final List<Expression> redirectingFactoryInvocations = <Expression>[];

  /// Variables with metadata.  Their types need to be inferred late, for
  /// example, in [finishFunction].
  List<VariableDeclaration> variablesWithMetadata;

  /// More than one variable declared in a single statement that has metadata.
  /// Their types need to be inferred late, for example, in [finishFunction].
  List<List<VariableDeclaration>> multiVariablesWithMetadata;

  BodyBuilder(
      this.library,
      this.member,
      this.enclosingScope,
      this.formalParameterScope,
      this.hierarchy,
      this.coreTypes,
      this.classBuilder,
      this.isInstanceMember,
      this.uri,
      this._typeInferrer)
      : enableNative =
            library.loader.target.backendTarget.enableNative(library.uri),
        stringExpectedAfterNative =
            library.loader.target.backendTarget.nativeExtensionExpectsString,
        ignoreMainInGetMainClosure = library.uri.scheme == 'dart' &&
            (library.uri.path == "_builtin" || library.uri.path == "ui"),
        needsImplicitSuperInitializer =
            coreTypes?.objectClass != classBuilder?.cls,
        typePromoter = _typeInferrer?.typePromoter,
        legacyMode = library.legacyMode,
        super(enclosingScope);

  BodyBuilder.withParents(KernelFieldBuilder field, KernelLibraryBuilder part,
      KernelClassBuilder classBuilder, TypeInferrer typeInferrer)
      : this(
            part,
            field,
            classBuilder?.scope ?? field.library.scope,
            null,
            part.loader.hierarchy,
            part.loader.coreTypes,
            classBuilder,
            field.isInstanceMember,
            field.fileUri,
            typeInferrer);

  BodyBuilder.forField(KernelFieldBuilder field, TypeInferrer typeInferrer)
      : this.withParents(
            field,
            field.parent is KernelClassBuilder
                ? field.parent.parent
                : field.parent,
            field.parent is KernelClassBuilder ? field.parent : null,
            typeInferrer);

  bool get inConstructor {
    return functionNestingLevel == 0 && member is KernelConstructorBuilder;
  }

  bool get isInstanceContext {
    return isInstanceMember || member is KernelConstructorBuilder;
  }

  TypeEnvironment get typeEnvironment => _typeInferrer?.typeSchemaEnvironment;

  DartType get implicitTypeArgument =>
      legacyMode ? const DynamicType() : const ImplicitTypeArgument();

  @override
  void push(Object node) {
    if (node is DartType) {
      unhandled("DartType", "push", -1, uri);
    }
    inInitializer = false;
    super.push(node);
  }

  Expression popForValue() => toValue(pop());

  Expression popForEffect() => toEffect(pop());

  Expression popForValueIfNotNull(Object value) {
    return value == null ? null : popForValue();
  }

  @override
  Expression toValue(Object node) {
    if (node is Generator) {
      return node.buildSimpleRead();
    } else if (node is Expression) {
      return node;
    } else if (node is SuperInitializer) {
      return buildProblem(
          fasta.messageSuperAsExpression, node.fileOffset, noLength);
    } else if (node is ProblemBuilder) {
      return buildProblem(node.message, node.charOffset, noLength);
    } else {
      return unhandled("${node.runtimeType}", "toValue", -1, uri);
    }
  }

  Expression toEffect(Object node) {
    if (node is Generator) return node.buildForEffect();
    return toValue(node);
  }

  List<Expression> popListForValue(int n) {
    List<Expression> list =
        new List<Expression>.filled(n, null, growable: true);
    for (int i = n - 1; i >= 0; i--) {
      list[i] = popForValue();
    }
    return list;
  }

  List<Expression> popListForEffect(int n) {
    List<Expression> list =
        new List<Expression>.filled(n, null, growable: true);
    for (int i = n - 1; i >= 0; i--) {
      list[i] = popForEffect();
    }
    return list;
  }

  Statement popBlock(int count, Token openBrace, Token closeBrace) {
    return forest.block(
        openBrace,
        const GrowableList<Statement>().pop(stack, count) ?? <Statement>[],
        closeBrace);
  }

  Statement popStatementIfNotNull(Object value) {
    return value == null ? null : popStatement();
  }

  Statement popStatement() => forest.wrapVariables(pop());

  void enterSwitchScope() {
    push(switchScope ?? NullValue.SwitchScope);
    switchScope = scope;
  }

  void exitSwitchScope() {
    Scope outerSwitchScope = pop();
    if (switchScope.unclaimedForwardDeclarations != null) {
      switchScope.unclaimedForwardDeclarations
          .forEach((String name, Declaration declaration) {
        if (outerSwitchScope == null) {
          JumpTarget target = declaration;
          for (Statement statement in target.users) {
            statement.parent.replaceChild(
                statement,
                wrapInProblemStatement(statement,
                    fasta.templateLabelNotFound.withArguments(name)));
          }
        } else {
          outerSwitchScope.forwardDeclareLabel(name, declaration);
        }
      });
    }
    switchScope = outerSwitchScope;
  }

  void wrapVariableInitializerInError(
      VariableDeclaration variable,
      Template<Message Function(String name)> template,
      List<LocatedMessage> context) {
    String name = variable.name;
    int offset = variable.fileOffset;
    Message message = template.withArguments(name);
    if (variable.initializer == null) {
      variable.initializer =
          buildProblem(message, offset, name.length, context: context)
            ..parent = variable;
    } else {
      variable.initializer = wrapInLocatedProblem(
          variable.initializer, message.withLocation(uri, offset, name.length),
          context: context)
        ..parent = variable;
    }
  }

  void declareVariable(VariableDeclaration variable, Scope scope) {
    String name = variable.name;
    Declaration existing = scope.local[name];
    if (existing != null) {
      // This reports an error for duplicated declarations in the same scope:
      // `{ var x; var x; }`
      wrapVariableInitializerInError(
          variable, fasta.templateDuplicatedDeclaration, <LocatedMessage>[
        fasta.templateDuplicatedDeclarationCause
            .withArguments(name)
            .withLocation(uri, existing.charOffset, name.length)
      ]);
      return;
    }
    LocatedMessage context = scope.declare(
        variable.name,
        new KernelVariableBuilder(
            variable, member ?? classBuilder ?? library, uri),
        uri);
    if (context != null) {
      // This case is different from the above error. In this case, the problem
      // is using `x` before it's declared: `{ var x; { print(x); var x;
      // }}`. In this case, we want two errors, the `x` in `print(x)` and the
      // second (or innermost declaration) of `x`.
      wrapVariableInitializerInError(
          variable,
          fasta.templateDuplicatedNamePreviouslyUsed,
          <LocatedMessage>[context]);
    }
  }

  @override
  JumpTarget createJumpTarget(JumpTargetKind kind, int charOffset) {
    return new JumpTarget(kind, functionNestingLevel, member, charOffset);
  }

  void inferAnnotations(List<Expression> annotations) {
    if (annotations != null) {
      _typeInferrer?.inferMetadata(this, annotations);
      library.loader.transformListPostInference(
          annotations, transformSetLiterals, transformCollections);
    }
  }

  @override
  void beginMetadata(Token token) {
    debugEvent("beginMetadata");
    super.push(constantContext);
    constantContext = ConstantContext.inferred;
  }

  @override
  void endMetadata(Token beginToken, Token periodBeforeName, Token endToken) {
    debugEvent("Metadata");
    Arguments arguments = pop();
    pushQualifiedReference(beginToken.next, periodBeforeName);
    if (arguments != null) {
      push(arguments);
      buildConstructorReferenceInvocation(
          beginToken.next, beginToken.offset, Constness.explicitConst);
      push(popForValue());
    } else {
      pop(); // Name last identifier
      String name = pop();
      pop(); // Type arguments (ignored, already reported by parser).
      Object expression = pop();
      if (expression is Identifier) {
        Identifier identifier = expression;
        expression = new UnresolvedNameGenerator(
            this,
            deprecated_extractToken(identifier),
            new Name(identifier.name, library.library));
      }
      if (name?.isNotEmpty ?? false) {
        Token period = periodBeforeName ?? beginToken.next.next;
        Generator generator = expression;
        expression = generator.buildPropertyAccess(
            new IncompletePropertyAccessGenerator(
                this, period.next, new Name(name, library.library)),
            period.next.offset,
            false);
      }

      ConstantContext savedConstantContext = pop();
      if (expression is! StaticAccessGenerator) {
        push(wrapInProblem(
            toValue(expression), fasta.messageExpressionNotMetadata, noLength));
      } else {
        push(toValue(expression));
      }
      constantContext = savedConstantContext;
    }
  }

  @override
  void endMetadataStar(int count) {
    debugEvent("MetadataStar");
    if (count == 0) {
      push(NullValue.Metadata);
    } else {
      push(const GrowableList<Expression>().pop(stack, count) ??
          NullValue.Metadata /* Ignore parser recovery */);
    }
  }

  @override
  void endTopLevelFields(
      Token staticToken,
      Token covariantToken,
      Token lateToken,
      Token varFinalOrConst,
      int count,
      Token beginToken,
      Token endToken) {
    debugEvent("TopLevelFields");
    // TODO(danrubel): handle NNBD 'late' modifier
    reportNonNullableModifierError(lateToken);
    push(count);
  }

  @override
  void endFields(Token staticToken, Token covariantToken, Token lateToken,
      Token varFinalOrConst, int count, Token beginToken, Token endToken) {
    debugEvent("Fields");
    // TODO(danrubel): handle NNBD 'late' modifier
    reportNonNullableModifierError(lateToken);
    push(count);
  }

  @override
  void finishFields() {
    debugEvent("finishFields");
    int count = pop();
    List<KernelFieldBuilder> fields = <KernelFieldBuilder>[];
    for (int i = 0; i < count; i++) {
      Expression initializer = pop();
      Identifier identifier = pop();
      String name = identifier.name;
      Declaration declaration;
      if (classBuilder != null) {
        declaration = classBuilder[name];
      } else {
        declaration = library[name];
      }
      KernelFieldBuilder field;
      if (declaration.isField && declaration.next == null) {
        field = declaration;
      } else {
        continue;
      }
      fields.add(field);
      if (initializer != null) {
        if (field.next != null) {
          // Duplicate definition. The field might not be the correct one,
          // so we skip inference of the initializer.
          // Error reporting and recovery is handled elsewhere.
        } else {
          field.initializer = initializer;
          _typeInferrer?.inferFieldInitializer(
              this, field.builtType, initializer);
          library.loader.transformPostInference(
              field.target, transformSetLiterals, transformCollections);
        }
      }
    }
    {
      // TODO(ahe): The type we compute here may be different from what is
      // computed in the outline phase. We should make sure that the outline
      // phase computes the same type. See
      // pkg/front_end/testcases/regress/issue_32200.dart for an example where
      // not calling [buildDartType] leads to a missing compile-time
      // error. Also, notice that the type of the problematic field isn't
      // `invalid-type`.
      buildDartType(pop()); // Type.
    }
    List<Expression> annotations = pop();
    // Fields with duplicate names are sorted out in the else branch of the
    // `declaration.next == null` above.
    if (annotations != null && fields.isNotEmpty) {
      inferAnnotations(annotations);
      Field field = fields.first.target;
      // The first (and often only field) will not get a clone.
      for (int i = 0; i < annotations.length; i++) {
        field.addAnnotation(annotations[i]);
      }
      for (int i = 1; i < fields.length; i++) {
        // We have to clone the annotations on the remaining fields.
        field = fields[i].target;
        cloner ??= new CloneVisitor();
        for (Expression annotation in annotations) {
          field.addAnnotation(cloner.clone(annotation));
        }
      }
    }

    resolveRedirectingFactoryTargets();
    finishVariableMetadata();
  }

  @override
  void endMember() {
    debugEvent("Member");
  }

  @override
  void endBlockFunctionBody(int count, Token openBrace, Token closeBrace) {
    debugEvent("BlockFunctionBody");
    if (openBrace == null) {
      assert(count == 0);
      push(NullValue.Block);
    } else {
      Statement block = popBlock(count, openBrace, closeBrace);
      exitLocalScope();
      push(block);
    }
  }

  void prepareInitializers() {
    ProcedureBuilder<TypeBuilder> member = this.member;
    scope = member.computeFormalParameterInitializerScope(scope);
    if (member is KernelConstructorBuilder) {
      if (member.formals != null) {
        for (KernelFormalParameterBuilder formal in member.formals) {
          if (formal.isInitializingFormal) {
            Initializer initializer;
            if (member.isExternal) {
              initializer = buildInvalidInitializer(
                  desugarSyntheticExpression(buildProblem(
                      fasta.messageExternalConstructorWithFieldInitializers,
                      formal.charOffset,
                      formal.name.length)),
                  formal.charOffset);
            } else {
              initializer = buildFieldInitializer(
                  true,
                  formal.name,
                  formal.charOffset,
                  formal.charOffset,
                  new VariableGet(formal.declaration),
                  formalType: formal.declaration.type);
            }
            member.addInitializer(initializer, this);
          }
        }
      }
    }
  }

  @override
  void handleNoInitializers() {
    debugEvent("NoInitializers");
    if (functionNestingLevel == 0) {
      prepareInitializers();
      scope = formalParameterScope;
    }
  }

  @override
  void beginInitializers(Token token) {
    debugEvent("beginInitializers");
    if (functionNestingLevel == 0) {
      prepareInitializers();
    }
  }

  @override
  void endInitializers(int count, Token beginToken, Token endToken) {
    debugEvent("Initializers");
    if (functionNestingLevel == 0) {
      scope = formalParameterScope;
    }
  }

  @override
  void beginInitializer(Token token) {
    debugEvent("beginInitializer");
    inInitializer = true;
    inFieldInitializer = true;
  }

  @override
  void endInitializer(Token token) {
    debugEvent("endInitializer");
    inFieldInitializer = false;
    assert(!inInitializer);
    final member = this.member;
    Object node = pop();
    Initializer initializer;
    if (node is Initializer) {
      initializer = node;
    } else if (node is Generator) {
      initializer = node.buildFieldInitializer(initializedFields);
    } else if (node is ConstructorInvocation) {
      initializer = buildSuperInitializer(
          false, node.target, node.arguments, token.charOffset);
    } else {
      Expression value = toValue(node);
      if (!forest.isThrow(node)) {
        value =
            wrapInProblem(value, fasta.messageExpectedAnInitializer, noLength);
      }
      initializer = buildInvalidInitializer(node, token.charOffset);
    }
    _typeInferrer?.inferInitializer(this, initializer);
    if (member is KernelConstructorBuilder && !member.isExternal) {
      member.addInitializer(initializer, this);
    } else {
      addProblem(
          fasta.templateInitializerOutsideConstructor
              .withArguments(member.name),
          token.charOffset,
          member.name.length);
    }
  }

  DartType _computeReturnTypeContext(MemberBuilder member) {
    if (member is KernelProcedureBuilder) {
      return member.procedure.function.returnType;
    } else {
      assert(member is KernelConstructorBuilder);
      return const DynamicType();
    }
  }

  @override
  void finishFunction(List<Expression> annotations, FormalParameters formals,
      AsyncMarker asyncModifier, Statement body) {
    debugEvent("finishFunction");
    typePromoter?.finished();

    KernelFunctionBuilder builder = member;
    if (formals?.parameters != null) {
      for (int i = 0; i < formals.parameters.length; i++) {
        KernelFormalParameterBuilder parameter = formals.parameters[i];
        Expression initializer = parameter.target.initializer;
        if (parameter.isOptional || initializer != null) {
          VariableDeclaration realParameter = builder.formals[i].target;
          if (parameter.isOptional) {
            initializer ??= forest.literalNull(
                // TODO(ahe): Should store: realParameter.fileOffset
                // https://github.com/dart-lang/sdk/issues/32289
                null);
          }
          realParameter.initializer = initializer..parent = realParameter;
          _typeInferrer?.inferParameterInitializer(
              this, initializer, realParameter.type);
          library.loader.transformPostInference(
              realParameter, transformSetLiterals, transformCollections);
        }
      }
    }

    _typeInferrer?.inferFunctionBody(
        this, _computeReturnTypeContext(member), asyncModifier, body);
    if (body != null) {
      library.loader.transformPostInference(
          body, transformSetLiterals, transformCollections);
    }

    // For async, async*, and sync* functions with declared return types, we
    // need to determine whether those types are valid.
    // TODO(hillerstrom): currently, we need to check whether [legacyMode] is
    // enabled for two reasons:
    // 1) the [isSubtypeOf] predicate produces false-negatives when
    // [legacyMode] is enabled.
    // 2) the member [typeEnvironment] might be null when [legacyMode] is
    // enabled.
    // This particular behaviour can be observed when running the fasta perf
    // benchmarks.
    if (!legacyMode && builder.returnType != null) {
      DartType returnType = builder.function.returnType;
      // We use the same trick in each case below. For example to decide whether
      // Future<T> <: [returnType] for every T, we rely on Future<Bot> and
      // transitivity of the subtyping relation because Future<Bot> <: Future<T>
      // for every T.

      // We use [problem == null] to signal success.
      Message problem;
      switch (asyncModifier) {
        case AsyncMarker.Async:
          DartType futureBottomType = library.loader.futureOfBottom;
          if (!typeEnvironment.isSubtypeOf(futureBottomType, returnType)) {
            problem = fasta.messageIllegalAsyncReturnType;
          }
          break;

        case AsyncMarker.AsyncStar:
          DartType streamBottomType = library.loader.streamOfBottom;
          if (returnType is VoidType) {
            problem = fasta.messageIllegalAsyncGeneratorVoidReturnType;
          } else if (!typeEnvironment.isSubtypeOf(
              streamBottomType, returnType)) {
            problem = fasta.messageIllegalAsyncGeneratorReturnType;
          }
          break;

        case AsyncMarker.SyncStar:
          DartType iterableBottomType = library.loader.iterableOfBottom;
          if (returnType is VoidType) {
            problem = fasta.messageIllegalSyncGeneratorVoidReturnType;
          } else if (!typeEnvironment.isSubtypeOf(
              iterableBottomType, returnType)) {
            problem = fasta.messageIllegalSyncGeneratorReturnType;
          }
          break;

        case AsyncMarker.Sync:
          break; // skip
        case AsyncMarker.SyncYielding:
          unexpected("async, async*, sync, or sync*", "$asyncModifier",
              member.charOffset, uri);
          break;
      }

      if (problem != null) {
        // TODO(hillerstrom): once types get annotated with location
        // information, we can improve the quality of the error message by
        // using the offset of [returnType] (and the length of its name).
        addProblem(problem, member.charOffset, member.name.length);
      }
    }

    if (builder.kind == ProcedureKind.Setter) {
      if (formals?.parameters == null ||
          formals.parameters.length != 1 ||
          formals.parameters.single.isOptional) {
        int charOffset = formals?.charOffset ??
            body?.fileOffset ??
            builder.target.fileOffset;
        if (body == null) {
          body = new EmptyStatement()..fileOffset = charOffset;
        }
        if (builder.formals != null) {
          // Illegal parameters were removed by the function builder.
          // Add them as local variable to put them in scope of the body.
          List<Statement> statements = <Statement>[];
          for (KernelFormalParameterBuilder parameter in builder.formals) {
            statements.add(parameter.target);
          }
          statements.add(body);
          body = forest.block(null, statements, null)..fileOffset = charOffset;
        }
        body = forest.block(
            null,
            <Statement>[
              forest.expressionStatement(
                  // This error is added after type inference is done, so we
                  // don't need to wrap errors in SyntheticExpressionJudgment.
                  desugarSyntheticExpression(buildProblem(
                      fasta.messageSetterWithWrongNumberOfFormals,
                      charOffset,
                      noLength)),
                  null),
              body,
            ],
            null)
          ..fileOffset = charOffset;
      }
    }
    // No-such-method forwarders get their bodies injected during outline
    // building, so we should skip them here.
    bool isNoSuchMethodForwarder = (builder.function.parent is Procedure &&
        (builder.function.parent as Procedure).isNoSuchMethodForwarder);
    if (!builder.isExternal && !isNoSuchMethodForwarder) {
      builder.body = body;
    } else {
      if (body != null) {
        builder.body = new Block(<Statement>[
          new ExpressionStatementJudgment(desugarSyntheticExpression(
              buildProblem(fasta.messageExternalMethodWithBody, body.fileOffset,
                  noLength)))
            ..fileOffset = body.fileOffset,
          body,
        ])
          ..fileOffset = body.fileOffset;
      }
    }
    Member target = builder.target;
    inferAnnotations(annotations);
    for (Expression annotation in annotations ?? const []) {
      target.addAnnotation(annotation);
    }
    if (builder is KernelConstructorBuilder) {
      finishConstructor(builder, asyncModifier);
    } else if (builder is KernelProcedureBuilder) {
      builder.asyncModifier = asyncModifier;
    } else {
      unhandled("${builder.runtimeType}", "finishFunction", builder.charOffset,
          builder.fileUri);
    }

    resolveRedirectingFactoryTargets();
    finishVariableMetadata();
  }

  void resolveRedirectingFactoryTargets() {
    for (StaticInvocation invocation in redirectingFactoryInvocations) {
      // If the invocation was invalid, it or its parent has already been
      // desugared into an exception throwing expression.  There is nothing to
      // resolve anymore.  Note that in the case where the invocation's parent
      // was invalid, type inference won't reach the invocation node and won't
      // set its inferredType field.  If type inference is disabled, reach to
      // the outtermost parent to check if the node is a dead code.
      if (invocation.parent == null) continue;
      if (_typeInferrer != null) {
        if (invocation is FactoryConstructorInvocationJudgment &&
            invocation.inferredType == null) {
          continue;
        }
      } else {
        TreeNode parent = invocation.parent;
        while (parent is! Component && parent != null) parent = parent.parent;
        if (parent == null) continue;
      }

      Procedure initialTarget = invocation.target;
      Expression replacementNode;

      RedirectionTarget redirectionTarget =
          getRedirectionTarget(initialTarget, legacyMode: legacyMode);
      Member resolvedTarget = redirectionTarget?.target;

      if (resolvedTarget == null) {
        String name = constructorNameForDiagnostics(initialTarget.name.name,
            className: initialTarget.enclosingClass.name);
        // TODO(dmitryas): Report this error earlier.
        replacementNode = desugarSyntheticExpression(buildProblem(
            fasta.templateCyclicRedirectingFactoryConstructors
                .withArguments(name),
            initialTarget.fileOffset,
            name.length));
      } else if (resolvedTarget is Constructor &&
          resolvedTarget.enclosingClass.isAbstract) {
        replacementNode = evaluateArgumentsBefore(
            forest.arguments(invocation.arguments.positional, null,
                types: invocation.arguments.types,
                named: invocation.arguments.named),
            buildAbstractClassInstantiationError(
                fasta.templateAbstractRedirectedClassInstantiation
                    .withArguments(resolvedTarget.enclosingClass.name),
                resolvedTarget.enclosingClass.name,
                initialTarget.fileOffset));
      } else {
        RedirectingFactoryBody redirectingFactoryBody =
            getRedirectingFactoryBody(resolvedTarget);
        if (redirectingFactoryBody != null) {
          // If the redirection target is itself a redirecting factory, it means
          // that it is unresolved.
          assert(redirectingFactoryBody.isUnresolved);
          String errorName = redirectingFactoryBody.unresolvedName;

          replacementNode = throwNoSuchMethodError(
              forest.literalNull(null)..fileOffset = invocation.fileOffset,
              errorName,
              forest.arguments(invocation.arguments.positional, null,
                  types: invocation.arguments.types,
                  named: invocation.arguments.named),
              initialTarget.fileOffset);
        } else {
          Substitution substitution = Substitution.fromPairs(
              initialTarget.function.typeParameters,
              invocation.arguments.types);
          invocation.arguments.types.clear();
          invocation.arguments.types.length =
              redirectionTarget.typeArguments.length;
          for (int i = 0; i < invocation.arguments.types.length; i++) {
            invocation.arguments.types[i] =
                substitution.substituteType(redirectionTarget.typeArguments[i]);
          }

          replacementNode = buildStaticInvocation(
              resolvedTarget,
              forest.arguments(invocation.arguments.positional, null,
                  types: invocation.arguments.types,
                  named: invocation.arguments.named),
              constness: invocation.isConst
                  ? Constness.explicitConst
                  : Constness.explicitNew,
              charOffset: invocation.fileOffset);
          // TODO(dmitryas): Find a better way to unwrap
          // [SyntheticExpressionJudgment] or not to build it in the first place
          // when it's not needed.
          if (replacementNode is shadow.SyntheticExpressionJudgment) {
            replacementNode = desugarSyntheticExpression(replacementNode);
          }
        }
      }

      invocation.replaceWith(replacementNode);
    }
    redirectingFactoryInvocations.clear();
  }

  void finishVariableMetadata() {
    List<VariableDeclaration> variablesWithMetadata =
        this.variablesWithMetadata;
    this.variablesWithMetadata = null;
    List<List<VariableDeclaration>> multiVariablesWithMetadata =
        this.multiVariablesWithMetadata;
    this.multiVariablesWithMetadata = null;

    if (variablesWithMetadata != null) {
      for (int i = 0; i < variablesWithMetadata.length; i++) {
        inferAnnotations(variablesWithMetadata[i].annotations);
      }
    }
    if (multiVariablesWithMetadata != null) {
      for (int i = 0; i < multiVariablesWithMetadata.length; i++) {
        List<VariableDeclaration> variables = multiVariablesWithMetadata[i];
        List<Expression> annotations = variables.first.annotations;
        inferAnnotations(annotations);
        for (int i = 1; i < variables.length; i++) {
          cloner ??= new CloneVisitor();
          VariableDeclaration variable = variables[i];
          for (int i = 0; i < annotations.length; i++) {
            variable.addAnnotation(cloner.clone(annotations[i]));
          }
        }
      }
    }
  }

  @override
  List<Expression> finishMetadata(TreeNode parent) {
    List<Expression> expressions = pop();
    inferAnnotations(expressions);

    // The invocation of [resolveRedirectingFactoryTargets] below may change the
    // root nodes of the annotation expressions.  We need to have a parent of
    // the annotation nodes before the resolution is performed, to collect and
    // return them later.  If [parent] is not provided, [temporaryParent] is
    // used.
    ListLiteral temporaryParent;

    if (parent is Class) {
      for (Expression expression in expressions) {
        parent.addAnnotation(expression);
      }
    } else if (parent is Library) {
      for (Expression expression in expressions) {
        parent.addAnnotation(expression);
      }
    } else if (parent is LibraryDependency) {
      for (Expression expression in expressions) {
        parent.addAnnotation(expression);
      }
    } else if (parent is LibraryPart) {
      for (Expression expression in expressions) {
        parent.addAnnotation(expression);
      }
    } else if (parent is Member) {
      for (Expression expression in expressions) {
        parent.addAnnotation(expression);
      }
    } else if (parent is Typedef) {
      for (Expression expression in expressions) {
        parent.addAnnotation(expression);
      }
    } else if (parent is TypeParameter) {
      for (Expression expression in expressions) {
        parent.addAnnotation(expression);
      }
    } else if (parent is VariableDeclaration) {
      for (Expression expression in expressions) {
        parent.addAnnotation(expression);
      }
    } else {
      temporaryParent = new ListLiteral(expressions);
    }
    resolveRedirectingFactoryTargets();
    finishVariableMetadata();
    return temporaryParent != null ? temporaryParent.expressions : expressions;
  }

  @override
  Expression parseSingleExpression(
      Parser parser, Token token, FunctionNode parameters) {
    List<KernelTypeVariableBuilder> typeParameterBuilders;
    for (TypeParameter typeParameter in parameters.typeParameters) {
      typeParameterBuilders ??= <KernelTypeVariableBuilder>[];
      typeParameterBuilders.add(
          new KernelTypeVariableBuilder.fromKernel(typeParameter, library));
    }
    enterFunctionTypeScope(typeParameterBuilders);

    List<KernelFormalParameterBuilder> formals =
        parameters.positionalParameters.length == 0
            ? null
            : new List<KernelFormalParameterBuilder>(
                parameters.positionalParameters.length);
    for (int i = 0; i < parameters.positionalParameters.length; i++) {
      VariableDeclaration formal = parameters.positionalParameters[i];
      formals[i] = new KernelFormalParameterBuilder(
          null, 0, null, formal.name, library, formal.fileOffset)
        ..declaration = formal;
    }
    enterLocalScope(
        null,
        new FormalParameters(formals, offsetForToken(token), noLength, uri)
            .computeFormalParameterScope(scope, member, this));

    token = parser.parseExpression(parser.syntheticPreviousToken(token));

    Expression expression = popForValue();
    Token eof = token.next;

    if (!eof.isEof) {
      expression = wrapInLocatedProblem(
          expression,
          fasta.messageExpectedOneExpression
              .withLocation(uri, eof.charOffset, eof.length));
    }

    ReturnJudgment fakeReturn = new ReturnJudgment(null, expression);

    _typeInferrer?.inferFunctionBody(
        this, const DynamicType(), AsyncMarker.Sync, fakeReturn);

    return fakeReturn.expression;
  }

  Expression parseFieldInitializer(Token token) {
    Parser parser = new Parser(this);
    token = parser.parseExpression(parser.syntheticPreviousToken(token));
    Expression expression = popForValue();
    checkEmpty(token.charOffset);
    return expression;
  }

  void finishConstructor(
      KernelConstructorBuilder builder, AsyncMarker asyncModifier) {
    /// Quotes below are from [Dart Programming Language Specification, 4th
    /// Edition](
    /// https://ecma-international.org/publications/files/ECMA-ST/ECMA-408.pdf).
    assert(builder == member);
    Constructor constructor = builder.constructor;
    if (asyncModifier != AsyncMarker.Sync) {
      // TODO(ahe): Change this to a null check.
      int offset = builder.body?.fileOffset ?? builder.charOffset;
      constructor.initializers.add(buildInvalidInitializer(
          desugarSyntheticExpression(
              buildProblem(fasta.messageConstructorNotSync, offset, noLength)),
          offset));
    }
    if (needsImplicitSuperInitializer) {
      /// >If no superinitializer is provided, an implicit superinitializer
      /// >of the form super() is added at the end of k’s initializer list,
      /// >unless the enclosing class is class Object.
      Constructor superTarget = lookupConstructor(emptyName, isSuper: true);
      Initializer initializer;
      Arguments arguments = forest.argumentsEmpty(noLocation);
      if (superTarget == null ||
          checkArgumentsForFunction(superTarget.function, arguments,
                  builder.charOffset, const <TypeParameter>[]) !=
              null) {
        String superclass = classBuilder.supertype.fullNameForErrors;
        int length = constructor.name.name.length;
        if (length == 0) {
          length = (constructor.parent as Class).name.length;
        }
        initializer = buildInvalidInitializer(
            desugarSyntheticExpression(buildProblem(
                fasta.templateSuperclassHasNoDefaultConstructor
                    .withArguments(superclass),
                builder.charOffset,
                length)),
            builder.charOffset);
      } else {
        initializer = buildSuperInitializer(
            true, superTarget, arguments, builder.charOffset);
      }
      constructor.initializers.add(initializer);
    }
    setParents(constructor.initializers, constructor);
    library.loader.transformListPostInference(
        constructor.initializers, transformSetLiterals, transformCollections);
    if (constructor.function.body == null) {
      /// >If a generative constructor c is not a redirecting constructor
      /// >and no body is provided, then c implicitly has an empty body {}.
      /// We use an empty statement instead.
      constructor.function.body = new EmptyStatement();
      constructor.function.body.parent = constructor.function;
    }
  }

  @override
  void handleExpressionStatement(Token token) {
    debugEvent("ExpressionStatement");
    push(forest.expressionStatement(popForEffect(), token));
  }

  @override
  void endArguments(int count, Token beginToken, Token endToken) {
    debugEvent("Arguments");
    List<Object> arguments = count == 0
        ? <Object>[]
        : const FixedNullableList<Object>().pop(stack, count);
    if (arguments == null) {
      push(new ParserRecovery(beginToken.charOffset));
      return;
    }
    int firstNamedArgumentIndex = arguments.length;
    for (int i = 0; i < arguments.length; i++) {
      Object node = arguments[i];
      if (node is NamedExpression) {
        firstNamedArgumentIndex =
            i < firstNamedArgumentIndex ? i : firstNamedArgumentIndex;
      } else {
        Expression argument = toValue(node);
        arguments[i] = argument;
        if (i > firstNamedArgumentIndex) {
          arguments[i] = new NamedExpression(
              "#$i",
              buildProblem(fasta.messageExpectedNamedArgument,
                  forest.readOffset(argument), noLength))
            ..fileOffset = beginToken.charOffset;
        }
      }
    }
    if (firstNamedArgumentIndex < arguments.length) {
      List<Expression> positional = new List<Expression>.from(
          arguments.getRange(0, firstNamedArgumentIndex));
      List<NamedExpression> named = new List<NamedExpression>.from(
          arguments.getRange(firstNamedArgumentIndex, arguments.length));
      push(forest.arguments(positional, beginToken, named: named));
    } else {
      // TODO(kmillikin): Find a way to avoid allocating a second list in the
      // case where there were no named arguments, which is a common one.
      push(forest.arguments(new List<Expression>.from(arguments), beginToken));
    }
  }

  @override
  void handleParenthesizedCondition(Token token) {
    debugEvent("ParenthesizedCondition");
    push(forest.parenthesizedCondition(token, popForValue(), token.endGroup));
  }

  @override
  void handleParenthesizedExpression(Token token) {
    debugEvent("ParenthesizedExpression");
    Expression value = popForValue();
    if (value is ShadowLargeIntLiteral) {
      // We need to know that the expression was parenthesized because we will
      // treat -n differently from -(n).  If the expression occurs in a double
      // context, -n is a double literal and -(n) is an application of unary- to
      // an integer literal.  And in any other context, '-' is part of the
      // syntax of -n, i.e., -9223372036854775808 is OK and it is the minimum
      // 64-bit integer, and '-' is an application of unary- in -(n), i.e.,
      // -(9223372036854775808) is an error because the literal does not fit in
      // 64-bits.
      push(value..isParenthesized = true);
    } else {
      push(new ParenthesizedExpressionGenerator(this, token.endGroup, value));
    }
  }

  @override
  void handleSend(Token beginToken, Token endToken) {
    debugEvent("Send");
    Arguments arguments = pop();
    List<UnresolvedType<KernelTypeBuilder>> typeArguments = pop();
    Object receiver = pop();
    if (arguments != null && typeArguments != null) {
      assert(forest.argumentsTypeArguments(arguments).isEmpty);
      forest.argumentsSetTypeArguments(
          arguments, buildDartTypeArguments(typeArguments));
    } else {
      assert(typeArguments == null);
    }
    if (receiver is Identifier) {
      Name name = new Name(receiver.name, library.library);
      if (arguments == null) {
        push(new IncompletePropertyAccessGenerator(this, beginToken, name));
      } else {
        push(new SendAccessGenerator(
            this, beginToken, name, forest.castArguments(arguments)));
      }
    } else if (arguments == null) {
      push(receiver);
    } else {
      push(finishSend(receiver, arguments, beginToken.charOffset));
    }
  }

  @override
  finishSend(Object receiver, Arguments arguments, int charOffset) {
    if (receiver is Generator) {
      return receiver.doInvocation(charOffset, arguments);
    } else if (receiver is ParserRecovery) {
      return new ParserErrorGenerator(this, null, fasta.messageSyntheticToken);
    } else {
      return buildMethodInvocation(
          toValue(receiver), callName, arguments, charOffset,
          isImplicitCall: true);
    }
  }

  @override
  void beginCascade(Token token) {
    debugEvent("beginCascade");
    Expression expression = popForValue();
    if (expression is CascadeJudgment) {
      push(expression);
      push(new VariableUseGenerator(this, token, expression.variable));
      expression.extend();
    } else {
      VariableDeclaration variable = new VariableDeclarationJudgment.forValue(
          expression, functionNestingLevel)
        ..fileOffset = expression.fileOffset;
      push(new CascadeJudgment(variable)..fileOffset = expression.fileOffset);
      push(new VariableUseGenerator(this, token, variable));
    }
  }

  @override
  void endCascade() {
    debugEvent("endCascade");
    Expression expression = popForEffect();
    CascadeJudgment cascadeReceiver = pop();
    cascadeReceiver.finalize(expression);
    push(cascadeReceiver);
  }

  @override
  void beginCaseExpression(Token caseKeyword) {
    debugEvent("beginCaseExpression");
    super.push(constantContext);
    constantContext = ConstantContext.inferred;
  }

  @override
  void endCaseExpression(Token colon) {
    debugEvent("endCaseExpression");
    Expression expression = popForValue();
    constantContext = pop();
    super.push(expression);
  }

  @override
  void beginBinaryExpression(Token token) {
    if (optional("&&", token) || optional("||", token)) {
      Expression lhs = popForValue();
      typePromoter?.enterLogicalExpression(lhs, token.stringValue);
      push(lhs);
    }
  }

  @override
  void endBinaryExpression(Token token) {
    debugEvent("BinaryExpression");
    if (optional(".", token) || optional("..", token)) {
      return doDotOrCascadeExpression(token);
    }
    if (optional("&&", token) || optional("||", token)) {
      return doLogicalExpression(token);
    }
    if (optional("??", token)) return doIfNull(token);
    if (optional("?.", token)) return doIfNotNull(token);
    Expression argument = popForValue();
    Object receiver = pop();
    bool isSuper = false;
    if (receiver is ThisAccessGenerator && receiver.isSuper) {
      ThisAccessGenerator thisAccessorReceiver = receiver;
      isSuper = true;
      receiver = forest.thisExpression(thisAccessorReceiver.token);
    }
    push(buildBinaryOperator(toValue(receiver), token, argument, isSuper));
  }

  Expression buildBinaryOperator(
      Expression a, Token token, Expression b, bool isSuper) {
    bool negate = false;
    String operator = token.stringValue;
    if (identical("!=", operator)) {
      operator = "==";
      negate = true;
    }
    if (!isBinaryOperator(operator) && !isMinusOperator(operator)) {
      if (isUserDefinableOperator(operator)) {
        return buildProblem(
            fasta.templateNotBinaryOperator.withArguments(token),
            token.charOffset,
            token.length);
      } else {
        return buildProblem(fasta.templateInvalidOperator.withArguments(token),
            token.charOffset, token.length);
      }
    } else {
      Expression result = buildMethodInvocation(a, new Name(operator),
          forest.arguments(<Expression>[b], noLocation), token.charOffset,
          // This *could* be a constant expression, we can't know without
          // evaluating [a] and [b].
          isConstantExpression: !isSuper,
          isSuper: isSuper);
      return negate ? forest.notExpression(result, null, true) : result;
    }
  }

  void doLogicalExpression(Token token) {
    Expression argument = popForValue();
    Expression receiver = pop();
    Expression logicalExpression =
        forest.logicalExpression(receiver, token, argument);
    typePromoter?.exitLogicalExpression(argument, logicalExpression);
    push(logicalExpression);
  }

  /// Handle `a ?? b`.
  void doIfNull(Token token) {
    Expression b = popForValue();
    Expression a = popForValue();
    VariableDeclaration variable = new VariableDeclaration.forValue(a);
    push(new IfNullJudgment(
        variable,
        forest.conditionalExpression(
            buildIsNull(new VariableGet(variable), offsetForToken(token), this),
            token,
            b,
            null,
            new VariableGet(variable)))
      ..fileOffset = offsetForToken(token));
  }

  /// Handle `a?.b(...)`.
  void doIfNotNull(Token token) {
    Object send = pop();
    if (send is IncompleteSendGenerator) {
      push(send.withReceiver(pop(), token.charOffset, isNullAware: true));
    } else {
      pop();
      token = token.next;
      push(buildProblem(fasta.templateExpectedIdentifier.withArguments(token),
          offsetForToken(token), lengthForToken(token)));
    }
  }

  void doDotOrCascadeExpression(Token token) {
    Object send = pop();
    if (send is IncompleteSendGenerator) {
      Object receiver = optional(".", token) ? pop() : popForValue();
      push(send.withReceiver(receiver, token.charOffset));
    } else {
      pop();
      token = token.next;
      push(buildProblem(fasta.templateExpectedIdentifier.withArguments(token),
          offsetForToken(token), lengthForToken(token)));
    }
  }

  bool areArgumentsCompatible(FunctionNode function, Arguments arguments) {
    // TODO(ahe): Implement this.
    return true;
  }

  @override
  Expression throwNoSuchMethodError(
      Expression receiver, String name, Arguments arguments, int charOffset,
      {Member candidate,
      bool isSuper: false,
      bool isGetter: false,
      bool isSetter: false,
      bool isStatic: false,
      LocatedMessage message}) {
    int length = name.length;
    int periodIndex = name.lastIndexOf(".");
    if (periodIndex != -1) {
      length -= periodIndex + 1;
    }
    Name kernelName = new Name(name, library.library);
    List<LocatedMessage> context;
    if (candidate != null) {
      Uri uri = candidate.location.file;
      int offset = candidate.fileOffset;
      Message contextMessage;
      int length = noLength;
      if (candidate is Constructor && candidate.isSynthetic) {
        offset = candidate.enclosingClass.fileOffset;
        contextMessage = fasta.templateCandidateFoundIsDefaultConstructor
            .withArguments(candidate.enclosingClass.name);
      } else {
        length = name.length;
        contextMessage = fasta.messageCandidateFound;
      }
      context = [contextMessage.withLocation(uri, offset, length)];
    }
    if (message == null) {
      if (isGetter) {
        message = warnUnresolvedGet(kernelName, charOffset,
                isSuper: isSuper, reportWarning: false, context: context)
            .withLocation(uri, charOffset, length);
      } else if (isSetter) {
        message = warnUnresolvedSet(kernelName, charOffset,
                isSuper: isSuper, reportWarning: false, context: context)
            .withLocation(uri, charOffset, length);
      } else {
        message = warnUnresolvedMethod(kernelName, charOffset,
                isSuper: isSuper, reportWarning: false, context: context)
            .withLocation(uri, charOffset, length);
      }
    }
    if (legacyMode && constantContext == ConstantContext.none) {
      addProblem(message.messageObject, message.charOffset, message.length,
          wasHandled: true, context: context);
      return forest.throwExpression(
          null,
          library.loader.instantiateNoSuchMethodError(
              receiver, name, forest.castArguments(arguments), charOffset,
              isMethod: !isGetter && !isSetter,
              isGetter: isGetter,
              isSetter: isSetter,
              isStatic: isStatic,
              isTopLevel: !isStatic && !isSuper))
        ..fileOffset = charOffset;
    }
    return desugarSyntheticExpression(buildProblem(
        message.messageObject, message.charOffset, message.length,
        context: context));
  }

  @override
  Message warnUnresolvedGet(Name name, int charOffset,
      {bool isSuper: false,
      bool reportWarning: true,
      List<LocatedMessage> context}) {
    Message message = isSuper
        ? fasta.templateSuperclassHasNoGetter.withArguments(name.name)
        : fasta.templateGetterNotFound.withArguments(name.name);
    if (reportWarning) {
      addProblemErrorIfConst(message, charOffset, name.name.length,
          context: context);
    }
    return message;
  }

  @override
  Message warnUnresolvedSet(Name name, int charOffset,
      {bool isSuper: false,
      bool reportWarning: true,
      List<LocatedMessage> context}) {
    Message message = isSuper
        ? fasta.templateSuperclassHasNoSetter.withArguments(name.name)
        : fasta.templateSetterNotFound.withArguments(name.name);
    if (reportWarning) {
      addProblemErrorIfConst(message, charOffset, name.name.length,
          context: context);
    }
    return message;
  }

  @override
  Message warnUnresolvedMethod(Name name, int charOffset,
      {bool isSuper: false,
      bool reportWarning: true,
      List<LocatedMessage> context}) {
    String plainName = name.name;
    int dotIndex = plainName.lastIndexOf(".");
    if (dotIndex != -1) {
      plainName = plainName.substring(dotIndex + 1);
    }
    // TODO(ahe): This is rather brittle. We would probably be better off with
    // more precise location information in this case.
    int length = plainName.length;
    if (plainName.startsWith("[")) {
      length = 1;
    }
    Message message = isSuper
        ? fasta.templateSuperclassHasNoMethod.withArguments(name.name)
        : fasta.templateMethodNotFound.withArguments(name.name);
    if (reportWarning) {
      addProblemErrorIfConst(message, charOffset, length, context: context);
    }
    return message;
  }

  @override
  void warnTypeArgumentsMismatch(String name, int expected, int charOffset) {
    addProblemErrorIfConst(
        fasta.templateTypeArgumentMismatch.withArguments(expected),
        charOffset,
        name.length);
  }

  @override
  Member lookupInstanceMember(Name name,
      {bool isSetter: false, bool isSuper: false}) {
    Class cls = classBuilder.cls;
    if (classBuilder.isPatch) {
      if (isSuper) {
        // The super class is only correctly found through the origin class.
        cls = classBuilder.origin.cls;
      } else {
        Member member =
            hierarchy.getInterfaceMember(cls, name, setter: isSetter);
        if (member?.parent == cls) {
          // Only if the member is found in the patch can we use it.
          return member;
        } else {
          // Otherwise, we need to keep searching in the origin class.
          cls = classBuilder.origin.cls;
        }
      }
    }

    if (isSuper) {
      cls = cls.superclass;
      if (cls == null) return null;
    }
    Member target = isSuper
        ? hierarchy.getDispatchTarget(cls, name, setter: isSetter)
        : hierarchy.getInterfaceMember(cls, name, setter: isSetter);
    if (isSuper && target == null) {
      if (classBuilder.cls.isMixinDeclaration ||
          (library.loader.target.backendTarget.enableSuperMixins &&
              classBuilder.isAbstract)) {
        target = hierarchy.getInterfaceMember(cls, name, setter: isSetter);
      }
    }
    return target;
  }

  @override
  Constructor lookupConstructor(Name name, {bool isSuper}) {
    Class cls = classBuilder.cls;
    if (isSuper) {
      cls = cls.superclass;
    }
    if (cls != null) {
      for (Constructor constructor in cls.constructors) {
        if (constructor.name == name) return constructor;
      }
    }

    /// Performs a similar lookup to [lookupConstructor], but using a slower
    /// implementation.
    Constructor lookupConstructorWithPatches(Name name, bool isSuper) {
      ClassBuilder<TypeBuilder, Object> builder = classBuilder.origin;

      ClassBuilder<TypeBuilder, Object> getSuperclass(
          ClassBuilder<TypeBuilder, Object> builder) {
        // This way of computing the superclass is slower than using the kernel
        // objects directly.
        Object supertype = builder.supertype;
        if (supertype is NamedTypeBuilder<TypeBuilder, Object>) {
          Object builder = supertype.declaration;
          if (builder is ClassBuilder<TypeBuilder, Object>) return builder;
        }
        return null;
      }

      if (isSuper) {
        builder = getSuperclass(builder)?.origin;
      }
      if (builder != null) {
        Class target = builder.target;
        for (Constructor constructor in target.constructors) {
          if (constructor.name == name) return constructor;
        }
      }
      return null;
    }

    return lookupConstructorWithPatches(name, isSuper);
  }

  @override
  void handleIdentifier(Token token, IdentifierContext context) {
    debugEvent("handleIdentifier");
    String name = token.lexeme;
    if (name.startsWith("deprecated") &&
        // Note that the previous check is redundant, but faster in the common
        // case (when [name] isn't deprecated).
        (name == "deprecated" || name.startsWith("deprecated_"))) {
      addProblem(fasta.templateUseOfDeprecatedIdentifier.withArguments(name),
          offsetForToken(token), lengthForToken(token));
    }
    if (context.isScopeReference) {
      assert(!inInitializer ||
          this.scope == enclosingScope ||
          this.scope.parent == enclosingScope);
      // This deals with this kind of initializer: `C(a) : a = a;`
      Scope scope = inInitializer ? enclosingScope : this.scope;
      push(scopeLookup(scope, name, token));
      return;
    } else if (context.inDeclaration) {
      if (context == IdentifierContext.topLevelVariableDeclaration ||
          context == IdentifierContext.fieldDeclaration) {
        constantContext = member.isConst
            ? ConstantContext.inferred
            : !member.isStatic &&
                    classBuilder != null &&
                    classBuilder.hasConstConstructor
                ? ConstantContext.required
                : ConstantContext.none;
      }
    } else if (constantContext != ConstantContext.none &&
        !context.allowedInConstantExpression) {
      addProblem(
          fasta.messageNotAConstantExpression, token.charOffset, token.length);
    }
    if (token.isSynthetic) {
      push(new ParserRecovery(offsetForToken(token)));
    } else {
      push(new Identifier.preserveToken(token));
    }
  }

  /// Look up [name] in [scope] using [token] as location information (both to
  /// report problems and as the file offset in the generated kernel code).
  /// [isQualified] should be true if [name] is a qualified access (which
  /// implies that it shouldn't be turned into a [ThisPropertyAccessGenerator]
  /// if the name doesn't resolve in the scope).
  @override
  scopeLookup(Scope scope, String name, Token token,
      {bool isQualified: false, PrefixBuilder prefix}) {
    int charOffset = offsetForToken(token);
    if (token.isSynthetic) {
      return new ParserErrorGenerator(this, token, fasta.messageSyntheticToken);
    }
    Declaration declaration = scope.lookup(name, charOffset, uri);
    if (declaration is UnlinkedDeclaration) {
      return new UnlinkedGenerator(this, token, declaration);
    }
    if (declaration == null &&
        prefix == null &&
        (classBuilder?.isPatch ?? false)) {
      // The scope of a patched method includes the origin class.
      declaration =
          classBuilder.origin.findStaticBuilder(name, charOffset, uri, library);
    }
    if (declaration != null &&
        declaration.isInstanceMember &&
        inFieldInitializer &&
        !inInitializer) {
      return new IncompleteErrorGenerator(this, token,
          fasta.templateThisAccessInFieldInitializer.withArguments(name));
    }
    if (declaration == null ||
        (!isInstanceContext && declaration.isInstanceMember)) {
      Name n = new Name(name, library.library);
      if (!isQualified && isInstanceContext) {
        assert(declaration == null);
        if (constantContext != ConstantContext.none || member.isField) {
          return new UnresolvedNameGenerator(this, token, n);
        }
        return new ThisPropertyAccessGenerator(this, token, n,
            lookupInstanceMember(n), lookupInstanceMember(n, isSetter: true));
      } else if (ignoreMainInGetMainClosure &&
          name == "main" &&
          member?.name == "_getMainClosure") {
        return forest.literalNull(null)..fileOffset = charOffset;
      } else {
        return new UnresolvedNameGenerator(this, token, n);
      }
    } else if (declaration.isTypeDeclaration) {
      return new TypeUseGenerator(this, token, declaration, name);
    } else if (declaration.isLocal) {
      if (constantContext != ConstantContext.none &&
          !declaration.isConst &&
          !member.isConstructor) {
        return new IncompleteErrorGenerator(
            this, token, fasta.messageNotAConstantExpression);
      }
      // An initializing formal parameter might be final without its
      // VariableDeclaration being final. See
      // [ProcedureBuilder.computeFormalParameterInitializerScope]. If that
      // wasn't the case, we could always use [VariableUseGenerator].
      if (declaration.isFinal) {
        Object fact = typePromoter?.getFactForAccess(
            declaration.target, functionNestingLevel);
        Object scope = typePromoter?.currentScope;
        return new ReadOnlyAccessGenerator(
            this,
            token,
            new VariableGetJudgment(declaration.target, fact, scope)
              ..fileOffset = charOffset,
            name);
      } else {
        return new VariableUseGenerator(this, token, declaration.target);
      }
    } else if (declaration.isInstanceMember) {
      if (constantContext != ConstantContext.none &&
          !inInitializer &&
          // TODO(ahe): This is a hack because Fasta sets up the scope
          // "this.field" parameters according to old semantics. Under the new
          // semantics, such parameters introduces a new parameter with that
          // name that should be resolved here.
          !member.isConstructor) {
        addProblem(
            fasta.messageNotAConstantExpression, charOffset, token.length);
      }
      Name n = new Name(name, library.library);
      Member getter;
      Member setter;
      if (declaration is AccessErrorBuilder) {
        setter = declaration.parent.target;
        getter = lookupInstanceMember(n);
      } else {
        getter = declaration.target;
        setter = lookupInstanceMember(n, isSetter: true);
      }
      return new ThisPropertyAccessGenerator(this, token, n, getter, setter);
    } else if (declaration.isRegularMethod) {
      assert(declaration.isStatic || declaration.isTopLevel);
      return new StaticAccessGenerator(this, token, declaration.target, null);
    } else if (declaration is PrefixBuilder) {
      assert(prefix == null);
      return new PrefixUseGenerator(this, token, declaration);
    } else if (declaration is LoadLibraryBuilder) {
      return new LoadLibraryGenerator(this, token, declaration);
    } else {
      if (declaration.hasProblem && declaration is! AccessErrorBuilder)
        return declaration;
      Declaration setter;
      if (declaration.isSetter) {
        setter = declaration;
      } else if (declaration.isGetter) {
        setter = scope.lookupSetter(name, charOffset, uri);
      } else if (declaration.isField && !declaration.isFinal) {
        setter = declaration;
      }
      StaticAccessGenerator generator = new StaticAccessGenerator.fromBuilder(
          this, declaration, token, setter);
      if (constantContext != ConstantContext.none) {
        Member readTarget = generator.readTarget;
        if (!(readTarget is Field && readTarget.isConst ||
            // Static tear-offs are also compile time constants.
            readTarget is Procedure)) {
          addProblem(
              fasta.messageNotAConstantExpression, charOffset, token.length);
        }
      }
      return generator;
    }
  }

  @override
  void handleQualified(Token period) {
    debugEvent("Qualified");
    Object node = pop();
    Object qualifier = pop();
    if (qualifier is ParserRecovery) {
      push(qualifier);
    } else if (node is ParserRecovery) {
      push(node);
    } else {
      Identifier identifier = node;
      push(identifier.withQualifier(qualifier));
    }
  }

  @override
  void beginLiteralString(Token token) {
    debugEvent("beginLiteralString");
    push(token);
  }

  @override
  void handleStringPart(Token token) {
    debugEvent("StringPart");
    push(token);
  }

  @override
  void endLiteralString(int interpolationCount, Token endToken) {
    debugEvent("endLiteralString");
    if (interpolationCount == 0) {
      Token token = pop();
      String value = unescapeString(token.lexeme, token, this);
      push(forest.literalString(value, token));
    } else {
      int count = 1 + interpolationCount * 2;
      List<Object> parts = const FixedNullableList<Object>().pop(stack, count);
      if (parts == null) {
        push(new ParserRecovery(endToken.charOffset));
        return;
      }
      Token first = parts.first;
      Token last = parts.last;
      Quote quote = analyzeQuote(first.lexeme);
      List<Expression> expressions = <Expression>[];
      // Contains more than just \' or \".
      if (first.lexeme.length > 1) {
        String value =
            unescapeFirstStringPart(first.lexeme, quote, first, this);
        if (value.isNotEmpty) {
          expressions.add(forest.literalString(value, first));
        }
      }
      for (int i = 1; i < parts.length - 1; i++) {
        Object part = parts[i];
        if (part is Token) {
          if (part.lexeme.length != 0) {
            String value = unescape(part.lexeme, quote, part, this);
            expressions.add(forest.literalString(value, part));
          }
        } else {
          expressions.add(toValue(part));
        }
      }
      // Contains more than just \' or \".
      if (last.lexeme.length > 1) {
        String value = unescapeLastStringPart(
            last.lexeme, quote, last, last.isSynthetic, this);
        if (value.isNotEmpty) {
          expressions.add(forest.literalString(value, last));
        }
      }
      push(forest.stringConcatenationExpression(expressions, endToken));
    }
  }

  @override
  void handleNativeClause(Token nativeToken, bool hasName) {
    debugEvent("NativeClause");
    if (hasName) {
      forest.asLiteralString(pop());
    }
  }

  @override
  void handleScript(Token token) {
    debugEvent("Script");
  }

  @override
  void handleStringJuxtaposition(int literalCount) {
    debugEvent("StringJuxtaposition");
    List<Expression> parts = popListForValue(literalCount);
    List<Expression> expressions;
    // Flatten string juxtapositions of string interpolation.
    for (int i = 0; i < parts.length; i++) {
      Expression part = parts[i];
      if (part is StringConcatenation) {
        if (expressions == null) {
          expressions = parts.sublist(0, i);
        }
        for (Expression expression in part.expressions) {
          expressions.add(expression);
        }
      } else {
        if (expressions != null) {
          expressions.add(part);
        }
      }
    }
    push(forest.stringConcatenationExpression(expressions ?? parts, null));
  }

  @override
  void handleLiteralInt(Token token) {
    debugEvent("LiteralInt");
    int value = int.tryParse(token.lexeme);
    if (legacyMode) {
      if (value == null) {
        push(unhandled(
            'large integer', 'handleLiteralInt', token.charOffset, uri));
      } else {
        push(forest.literalInt(value, token));
      }
      return;
    }
    // Postpone parsing of literals resulting in a negative value
    // (hex literals >= 2^63). These are only allowed when not negated.
    if (value == null || value < 0) {
      push(forest.literalLargeInt(token.lexeme, token));
    } else {
      push(forest.literalInt(value, token));
    }
  }

  @override
  void handleEmptyFunctionBody(Token semicolon) {
    debugEvent("ExpressionFunctionBody");
    endBlockFunctionBody(0, null, semicolon);
  }

  @override
  void handleExpressionFunctionBody(Token arrowToken, Token endToken) {
    debugEvent("ExpressionFunctionBody");
    endReturnStatement(true, arrowToken.next, endToken);
  }

  @override
  void endReturnStatement(
      bool hasExpression, Token beginToken, Token endToken) {
    debugEvent("ReturnStatement");
    Expression expression = hasExpression ? popForValue() : null;
    if (expression != null && inConstructor) {
      push(buildProblemStatement(
          fasta.messageConstructorWithReturnType, beginToken.charOffset));
    } else {
      push(forest.returnStatement(beginToken, expression, endToken));
    }
  }

  @override
  void beginThenStatement(Token token) {
    Expression condition = popForValue();
    enterThenForTypePromotion(condition);
    push(condition);
    super.beginThenStatement(token);
  }

  @override
  void endThenStatement(Token token) {
    typePromoter?.enterElse();
    super.endThenStatement(token);
  }

  @override
  void endIfStatement(Token ifToken, Token elseToken) {
    Statement elsePart = popStatementIfNotNull(elseToken);
    Statement thenPart = popStatement();
    Expression condition = pop();
    typePromoter?.exitConditional();
    push(forest.ifStatement(ifToken, condition, thenPart, elseToken, elsePart));
  }

  @override
  void endVariableInitializer(Token assignmentOperator) {
    debugEvent("VariableInitializer");
    assert(assignmentOperator.stringValue == "=");
    pushNewLocalVariable(popForValue(), equalsToken: assignmentOperator);
  }

  @override
  void handleNoVariableInitializer(Token token) {
    debugEvent("NoVariableInitializer");
    bool isConst = (currentLocalVariableModifiers & constMask) != 0;
    bool isFinal = (currentLocalVariableModifiers & finalMask) != 0;
    Expression initializer;
    if (!optional("in", token)) {
      // A for-in loop-variable can't have an initializer. So let's remain
      // silent if the next token is `in`. Since a for-in loop can only have
      // one variable it must be followed by `in`.
      if (isConst) {
        initializer = buildProblem(
            fasta.templateConstFieldWithoutInitializer
                .withArguments(token.lexeme),
            token.charOffset,
            token.length);
      } else if (isFinal) {
        initializer = buildProblem(
            fasta.templateFinalFieldWithoutInitializer
                .withArguments(token.lexeme),
            token.charOffset,
            token.length);
      }
    }
    pushNewLocalVariable(initializer);
  }

  void pushNewLocalVariable(Expression initializer, {Token equalsToken}) {
    Object node = pop();
    if (node is ParserRecovery) {
      push(node);
      return;
    }
    Identifier identifier = node;
    assert(currentLocalVariableModifiers != -1);
    bool isConst = (currentLocalVariableModifiers & constMask) != 0;
    bool isFinal = (currentLocalVariableModifiers & finalMask) != 0;
    assert(isConst == (constantContext == ConstantContext.inferred));
    VariableDeclaration variable = new VariableDeclarationJudgment(
        identifier.name, functionNestingLevel,
        forSyntheticToken: deprecated_extractToken(identifier).isSynthetic,
        initializer: initializer,
        type: buildDartType(currentLocalVariableType),
        isFinal: isFinal,
        isConst: isConst)
      ..fileOffset = identifier.charOffset
      ..fileEqualsOffset = offsetForToken(equalsToken);
    library.checkBoundsInVariableDeclaration(variable, typeEnvironment);
    push(variable);
  }

  @override
  void beginFieldInitializer(Token token) {
    inFieldInitializer = true;
  }

  @override
  void endFieldInitializer(Token assignmentOperator, Token token) {
    debugEvent("FieldInitializer");
    inFieldInitializer = false;
    assert(assignmentOperator.stringValue == "=");
    push(popForValue());
  }

  @override
  void handleNoFieldInitializer(Token token) {
    debugEvent("NoFieldInitializer");
    if (constantContext == ConstantContext.inferred) {
      // Creating a null value to prevent the Dart VM from crashing.
      push(forest.literalNull(token));
    } else {
      push(NullValue.FieldInitializer);
    }
  }

  @override
  void endInitializedIdentifier(Token nameToken) {
    // TODO(ahe): Use [InitializedIdentifier] here?
    debugEvent("InitializedIdentifier");
    Object node = pop();
    if (node is ParserRecovery) {
      push(node);
      return;
    }
    VariableDeclaration variable = node;
    variable.fileOffset = nameToken.charOffset;
    push(variable);
    declareVariable(variable, scope);
  }

  @override
  void beginVariablesDeclaration(
      Token token, Token lateToken, Token varFinalOrConst) {
    debugEvent("beginVariablesDeclaration");
    // TODO(danrubel): handle NNBD 'late' modifier
    reportNonNullableModifierError(lateToken);
    UnresolvedType<KernelTypeBuilder> type = pop();
    int modifiers = Modifier.validateVarFinalOrConst(varFinalOrConst?.lexeme);
    super.push(currentLocalVariableModifiers);
    super.push(currentLocalVariableType ?? NullValue.Type);
    currentLocalVariableType = type;
    currentLocalVariableModifiers = modifiers;
    super.push(constantContext);
    constantContext = ((modifiers & constMask) != 0)
        ? ConstantContext.inferred
        : ConstantContext.none;
  }

  @override
  void endVariablesDeclaration(int count, Token endToken) {
    debugEvent("VariablesDeclaration");
    if (count == 1) {
      Object node = pop();
      constantContext = pop();
      currentLocalVariableType = pop();
      currentLocalVariableModifiers = pop();
      List<Expression> annotations = pop();
      if (node is ParserRecovery) {
        push(node);
        return;
      }
      VariableDeclaration variable = node;
      if (annotations != null) {
        for (int i = 0; i < annotations.length; i++) {
          variable.addAnnotation(annotations[i]);
        }
        (variablesWithMetadata ??= <VariableDeclaration>[]).add(variable);
      }
      push(variable);
    } else {
      List<VariableDeclaration> variables =
          const FixedNullableList<VariableDeclaration>().pop(stack, count);
      constantContext = pop();
      currentLocalVariableType = pop();
      currentLocalVariableModifiers = pop();
      List<Expression> annotations = pop();
      if (variables == null) {
        push(new ParserRecovery(offsetForToken(endToken)));
        return;
      }
      if (annotations != null) {
        VariableDeclaration first = variables.first;
        for (int i = 0; i < annotations.length; i++) {
          first.addAnnotation(annotations[i]);
        }
        (multiVariablesWithMetadata ??= <List<VariableDeclaration>>[])
            .add(variables);
      }
      push(forest.variablesDeclaration(variables, uri));
    }
  }

  @override
  void endBlock(int count, Token openBrace, Token closeBrace) {
    debugEvent("Block");
    Statement block = popBlock(count, openBrace, closeBrace);
    exitLocalScope();
    push(block);
  }

  void handleInvalidTopLevelBlock(Token token) {
    // TODO(danrubel): Consider improved recovery by adding this block
    // as part of a synthetic top level function.
    pop(); // block
  }

  @override
  void handleAssignmentExpression(Token token) {
    debugEvent("AssignmentExpression");
    Expression value = popForValue();
    Object generator = pop();
    if (generator is! Generator) {
      push(buildProblem(fasta.messageNotAnLvalue, offsetForToken(token),
          lengthForToken(token)));
    } else {
      push(new DelayedAssignment(
          this, token, generator, value, token.stringValue));
    }
  }

  @override
  void enterLoop(int charOffset) {
    if (peek() is LabelTarget) {
      LabelTarget target = peek();
      enterBreakTarget(charOffset, target.breakTarget);
      enterContinueTarget(charOffset, target.continueTarget);
    } else {
      enterBreakTarget(charOffset);
      enterContinueTarget(charOffset);
    }
  }

  void exitLoopOrSwitch(Statement statement) {
    if (problemInLoopOrSwitch != null) {
      push(problemInLoopOrSwitch);
      problemInLoopOrSwitch = null;
    } else {
      push(statement);
    }
  }

  List<VariableDeclaration> buildVariableDeclarations(variableOrExpression) {
    // TODO(ahe): This can be simplified now that we have the events
    // `handleForInitializer...` events.
    if (variableOrExpression is Generator) {
      variableOrExpression = variableOrExpression.buildForEffect();
    }
    if (variableOrExpression is VariableDeclaration) {
      return <VariableDeclaration>[variableOrExpression];
    } else if (variableOrExpression is Expression) {
      VariableDeclaration variable = new VariableDeclarationJudgment.forEffect(
          variableOrExpression, functionNestingLevel);
      return <VariableDeclaration>[variable];
    } else if (variableOrExpression is ExpressionStatement) {
      VariableDeclaration variable = new VariableDeclarationJudgment.forEffect(
          variableOrExpression.expression, functionNestingLevel);
      return <VariableDeclaration>[variable];
    } else if (forest.isVariablesDeclaration(variableOrExpression)) {
      return forest
          .variablesDeclarationExtractDeclarations(variableOrExpression);
    } else if (variableOrExpression is List<Object>) {
      List<VariableDeclaration> variables = <VariableDeclaration>[];
      for (Object v in variableOrExpression) {
        variables.addAll(buildVariableDeclarations(v));
      }
      return variables;
    } else if (variableOrExpression == null) {
      return <VariableDeclaration>[];
    }
    return null;
  }

  @override
  void handleForInitializerEmptyStatement(Token token) {
    debugEvent("ForInitializerEmptyStatement");
    push(NullValue.Expression);
  }

  @override
  void handleForInitializerExpressionStatement(Token token) {
    debugEvent("ForInitializerExpressionStatement");
  }

  @override
  void handleForInitializerLocalVariableDeclaration(Token token) {
    debugEvent("ForInitializerLocalVariableDeclaration");
  }

  @override
  void handleForLoopParts(Token forKeyword, Token leftParen,
      Token leftSeparator, int updateExpressionCount) {
    push(forKeyword);
    push(leftParen);
    push(leftSeparator);
    push(updateExpressionCount);
  }

  @override
  void endForControlFlow(Token token) {
    debugEvent("ForControlFlow");
    var entry = pop();
    int updateExpressionCount = pop();
    pop(); // left separator
    pop(); // left parenthesis
    Token forToken = pop();
    List<Expression> updates = popListForEffect(updateExpressionCount);
    Statement conditionStatement = popStatement(); // condition
    Object variableOrExpression = pop();
    exitLocalScope();

    if (!library.loader.target.enableControlFlowCollections) {
      // TODO(danrubel): Report a more user friendly error message
      // when an experiment is not enabled
      handleRecoverableError(
          fasta.templateUnexpectedToken.withArguments(forToken),
          forToken,
          forToken);
      push(invalidCollectionElement);
      return;
    }

    if (constantContext != ConstantContext.none &&
        !library.loader.target.enableConstantUpdate2018) {
      handleRecoverableError(
          fasta.templateCantUseControlFlowOrSpreadAsConstant
              .withArguments(forToken),
          forToken,
          forToken);
      push(invalidCollectionElement);
      return;
    }

    transformCollections = true;
    List<VariableDeclaration> variables =
        buildVariableDeclarations(variableOrExpression);
    Expression condition;
    if (forest.isExpressionStatement(conditionStatement)) {
      condition =
          forest.getExpressionFromExpressionStatement(conditionStatement);
    } else {
      assert(forest.isEmptyStatement(conditionStatement));
    }
    if (entry is MapEntry) {
      push(forest.forMapEntry(variables, condition, updates, entry, forToken));
    } else {
      push(forest.forElement(
          variables, condition, updates, toValue(entry), forToken));
    }
  }

  @override
  void endForStatement(Token endToken) {
    debugEvent("ForStatement");
    Statement body = popStatement();

    int updateExpressionCount = pop();
    Token leftSeparator = pop();
    Token leftParen = pop();
    Token forKeyword = pop();

    List<Expression> updates = popListForEffect(updateExpressionCount);
    Statement conditionStatement = popStatement();
    Object variableOrExpression = pop();
    List<VariableDeclaration> variables =
        buildVariableDeclarations(variableOrExpression);
    exitLocalScope();
    JumpTarget continueTarget = exitContinueTarget();
    JumpTarget breakTarget = exitBreakTarget();
    if (continueTarget.hasUsers) {
      body = forest.syntheticLabeledStatement(body);
      continueTarget.resolveContinues(forest, body);
    }
    Expression condition;
    if (forest.isExpressionStatement(conditionStatement)) {
      condition =
          forest.getExpressionFromExpressionStatement(conditionStatement);
    } else {
      assert(forest.isEmptyStatement(conditionStatement));
    }
    Statement result = forest.forStatement(
        forKeyword,
        leftParen,
        variables,
        leftSeparator,
        condition,
        conditionStatement,
        updates,
        leftParen.endGroup,
        body);
    if (breakTarget.hasUsers) {
      result = forest.syntheticLabeledStatement(result);
      breakTarget.resolveBreaks(forest, result);
    }
    if (variableOrExpression is ParserRecovery) {
      problemInLoopOrSwitch ??= buildProblemStatement(
          fasta.messageSyntheticToken, variableOrExpression.charOffset,
          suppressMessage: true);
    }
    exitLoopOrSwitch(result);
  }

  @override
  void endAwaitExpression(Token keyword, Token endToken) {
    debugEvent("AwaitExpression");
    push(forest.awaitExpression(popForValue(), keyword));
  }

  @override
  void handleAsyncModifier(Token asyncToken, Token starToken) {
    debugEvent("AsyncModifier");
    push(asyncMarkerFromTokens(asyncToken, starToken));
  }

  @override
  void handleLiteralList(
      int count, Token leftBracket, Token constKeyword, Token rightBracket) {
    debugEvent("LiteralList");

    // TODO(danrubel): Replace this with popListForValue
    // when control flow and spread collections have been enabled by default
    List<Expression> expressions =
        new List<Expression>.filled(count, null, growable: true);
    for (int i = count - 1; i >= 0; i--) {
      var elem = pop();
      if (elem != invalidCollectionElement) {
        expressions[i] = toValue(elem);
      } else {
        expressions.removeAt(i);
      }
    }

    List<UnresolvedType<KernelTypeBuilder>> typeArguments = pop();

    DartType typeArgument;
    if (typeArguments != null) {
      if (typeArguments.length > 1) {
        addProblem(
            fasta.messageListLiteralTooManyTypeArguments,
            offsetForToken(leftBracket),
            lengthOfSpan(leftBracket, leftBracket.endGroup));
        typeArgument = const InvalidType();
      } else {
        typeArgument = buildDartType(typeArguments.single);
        if (!legacyMode) {
          typeArgument =
              instantiateToBounds(typeArgument, coreTypes.objectClass);
        }
      }
    } else {
      typeArgument = implicitTypeArgument;
    }

    Expression node = forest.literalList(
        constKeyword,
        constKeyword != null || constantContext == ConstantContext.inferred,
        typeArgument,
        typeArguments,
        leftBracket,
        expressions,
        rightBracket);
    library.checkBoundsInListLiteral(node, typeEnvironment);
    push(node);
  }

  void buildLiteralSet(List<UnresolvedType<KernelTypeBuilder>> typeArguments,
      Token constKeyword, Token leftBrace, List<dynamic> setOrMapEntries) {
    DartType typeArgument;
    if (typeArguments != null) {
      typeArgument = buildDartType(typeArguments.single);
      if (!library.loader.target.legacyMode) {
        typeArgument = instantiateToBounds(typeArgument, coreTypes.objectClass);
      }
    } else {
      typeArgument = implicitTypeArgument;
    }

    var expressions = <Expression>[];
    if (setOrMapEntries != null) {
      for (var entry in setOrMapEntries) {
        if (entry is MapEntry) {
          // TODO(danrubel): report the error on the colon
          addProblem(fasta.templateExpectedButGot.withArguments(','),
              entry.fileOffset, 1);
        } else {
          // TODO(danrubel): Revise once control flow and spread
          //  collection entries are supported.
          expressions.add(entry as Expression);
        }
      }
    }

    Expression node = forest.literalSet(
        constKeyword,
        constKeyword != null || constantContext == ConstantContext.inferred,
        typeArgument,
        typeArguments,
        leftBrace,
        expressions,
        leftBrace.endGroup);
    library.checkBoundsInSetLiteral(node, typeEnvironment);
    if (!library.loader.target.enableSetLiterals) {
      internalProblem(
          fasta.messageSetLiteralsNotSupported, node.fileOffset, uri);
      return;
    }
    push(node);
  }

  @override
  void handleLiteralSetOrMap(
    int count,
    Token leftBrace,
    Token constKeyword,
    Token rightBrace,
    // TODO(danrubel): hasSetEntry parameter exists for replicating existing
    // behavior and will be removed once unified collection has been enabled
    bool hasSetEntry,
  ) {
    debugEvent("LiteralSetOrMap");

    var setOrMapEntries = new List<dynamic>.filled(count, null, growable: true);
    for (int i = count - 1; i >= 0; i--) {
      var elem = pop();
      // TODO(danrubel): Revise this to handle control flow and spread
      if (elem == invalidCollectionElement) {
        setOrMapEntries.removeAt(i);
      } else if (elem is MapEntry) {
        setOrMapEntries[i] = elem;
      } else {
        setOrMapEntries[i] = toValue(elem);
      }
    }
    List<UnresolvedType<KernelTypeBuilder>> typeArguments = pop();

    // Replicate existing behavior that has been removed from the parser.
    // This will be removed once unified collections is implemented.

    // Determine if this is a set or map based on type args and content
    // TODO(danrubel): Since type resolution is needed to disambiguate
    // set or map in some situations, consider always deferring determination
    // until the type resolution phase.
    final typeArgCount = typeArguments?.length;
    bool isSet = typeArgCount == 1 ? true : typeArgCount != null ? false : null;

    for (int i = 0; i < setOrMapEntries.length; ++i) {
      if (setOrMapEntries[i] is! MapEntry &&
          !isConvertibleToMapEntry(setOrMapEntries[i])) {
        hasSetEntry = true;
      }
    }

    // TODO(danrubel): If the type arguments are not known (null) then
    // defer set/map determination until after type resolution as per the
    // unified collection spec: https://github.com/dart-lang/language/pull/200
    // rather than trying to guess as done below.
    isSet ??= hasSetEntry;

    if (isSet) {
      buildLiteralSet(typeArguments, constKeyword, leftBrace, setOrMapEntries);
    } else {
      List<MapEntry> mapEntries = new List<MapEntry>(setOrMapEntries.length);
      for (int i = 0; i < setOrMapEntries.length; ++i) {
        if (setOrMapEntries[i] is MapEntry) {
          mapEntries[i] = setOrMapEntries[i];
        } else {
          mapEntries[i] = convertToMapEntry(setOrMapEntries[i], this);
        }
      }
      buildLiteralMap(typeArguments, constKeyword, leftBrace, mapEntries);
    }
  }

  @override
  void handleLiteralBool(Token token) {
    debugEvent("LiteralBool");
    bool value = optional("true", token);
    assert(value || optional("false", token));
    push(forest.literalBool(value, token));
  }

  @override
  void handleLiteralDouble(Token token) {
    debugEvent("LiteralDouble");
    push(forest.literalDouble(double.parse(token.lexeme), token));
  }

  @override
  void handleLiteralNull(Token token) {
    debugEvent("LiteralNull");
    push(forest.literalNull(token));
  }

  void buildLiteralMap(List<UnresolvedType<KernelTypeBuilder>> typeArguments,
      Token constKeyword, Token leftBrace, List<MapEntry> entries) {
    DartType keyType;
    DartType valueType;
    if (typeArguments != null) {
      if (typeArguments.length != 2) {
        keyType = const InvalidType();
        valueType = const InvalidType();
      } else {
        keyType = buildDartType(typeArguments[0]);
        valueType = buildDartType(typeArguments[1]);
        if (!legacyMode) {
          keyType = instantiateToBounds(keyType, coreTypes.objectClass);
          valueType = instantiateToBounds(valueType, coreTypes.objectClass);
        }
      }
    } else {
      DartType implicitTypeArgument = this.implicitTypeArgument;
      keyType = implicitTypeArgument;
      valueType = implicitTypeArgument;
    }

    Expression node = forest.literalMap(
        constKeyword,
        constKeyword != null || constantContext == ConstantContext.inferred,
        keyType,
        valueType,
        typeArguments,
        leftBrace,
        entries,
        leftBrace.endGroup);
    library.checkBoundsInMapLiteral(node, typeEnvironment);
    push(node);
  }

  @override
  void handleLiteralMapEntry(Token colon, Token endToken) {
    debugEvent("LiteralMapEntry");
    Expression value = popForValue();
    Expression key = popForValue();
    push(forest.mapEntry(key, colon, value));
  }

  String symbolPartToString(name) {
    if (name is Identifier) {
      return name.name;
    } else if (name is Operator) {
      return name.name;
    } else {
      return unhandled("${name.runtimeType}", "symbolPartToString", -1, uri);
    }
  }

  @override
  void endLiteralSymbol(Token hashToken, int identifierCount) {
    debugEvent("LiteralSymbol");
    if (identifierCount == 1) {
      Object part = pop();
      if (part is ParserRecovery) {
        push(new ParserErrorGenerator(
            this, hashToken, fasta.messageSyntheticToken));
      } else {
        push(forest.literalSymbolSingluar(
            symbolPartToString(part), hashToken, part));
      }
    } else {
      List<Identifier> parts =
          const FixedNullableList<Identifier>().pop(stack, identifierCount);
      if (parts == null) {
        push(new ParserErrorGenerator(
            this, hashToken, fasta.messageSyntheticToken));
        return;
      }
      String value = symbolPartToString(parts.first);
      for (int i = 1; i < parts.length; i++) {
        value += ".${symbolPartToString(parts[i])}";
      }
      push(forest.literalSymbolMultiple(value, hashToken, parts));
    }
  }

  @override
  void handleNonNullAssertExpression(Token bang) {
    reportNonNullAssertExpressionNotEnabled(bang);
  }

  @override
  void handleType(Token beginToken, Token questionMark) {
    // TODO(ahe): The scope is wrong for return types of generic functions.
    debugEvent("Type");
    reportErrorIfNullableType(questionMark);
    List<UnresolvedType<KernelTypeBuilder>> arguments = pop();
    Object name = pop();
    if (name is QualifiedName) {
      QualifiedName qualified = name;
      Object prefix = qualified.qualifier;
      Token suffix = deprecated_extractToken(qualified);
      if (prefix is Generator) {
        name = prefix.qualifiedLookup(suffix);
      } else {
        String name = getNodeName(prefix);
        String displayName = debugName(name, suffix.lexeme);
        int offset = offsetForToken(beginToken);
        push(new UnresolvedType<KernelTypeBuilder>(
            new KernelNamedTypeBuilder(name, null)
              ..bind(new KernelInvalidTypeBuilder(
                  name,
                  fasta.templateNotAType
                      .withArguments(displayName)
                      .withLocation(
                          uri, offset, lengthOfSpan(beginToken, suffix)))),
            offset,
            uri));
        return;
      }
    }
    KernelTypeBuilder result;
    if (name is Generator) {
      result = name.buildTypeWithResolvedArguments(arguments);
      if (result == null) {
        unhandled("null", "result", beginToken.charOffset, uri);
      }
    } else if (name is TypeBuilder) {
      result = name.build(library);
      if (result == null) {
        unhandled("null", "result", beginToken.charOffset, uri);
      }
    } else if (name is ProblemBuilder) {
      // TODO(ahe): Arguments could be passed here.
      result = new KernelNamedTypeBuilder(name.name, null)
        ..bind(new KernelInvalidTypeBuilder(
            name.name,
            name.message.withLocation(
                name.fileUri, name.charOffset, name.name.length)));
    } else {
      unhandled(
          "${name.runtimeType}", "handleType", beginToken.charOffset, uri);
    }
    push(new UnresolvedType<KernelTypeBuilder>(
        result, beginToken.charOffset, uri));
  }

  @override
  void beginFunctionType(Token beginToken) {
    debugEvent("beginFunctionType");
  }

  void enterFunctionTypeScope(List<KernelTypeVariableBuilder> typeVariables) {
    debugEvent("enterFunctionTypeScope");
    enterLocalScope(null,
        scope.createNestedScope("function-type scope", isModifiable: true));
    if (typeVariables != null) {
      ScopeBuilder scopeBuilder = new ScopeBuilder(scope);
      for (KernelTypeVariableBuilder builder in typeVariables) {
        String name = builder.name;
        KernelTypeVariableBuilder existing = scopeBuilder[name];
        if (existing == null) {
          scopeBuilder.addMember(name, builder);
        } else {
          reportDuplicatedDeclaration(existing, name, builder.charOffset);
        }
      }
    }
  }

  @override
  void endFunctionType(Token functionToken, Token questionMark) {
    debugEvent("FunctionType");
    reportErrorIfNullableType(questionMark);
    FormalParameters formals = pop();
    UnresolvedType<KernelTypeBuilder> returnType = pop();
    List<KernelTypeVariableBuilder> typeVariables = pop();
    UnresolvedType<KernelTypeBuilder> type =
        formals.toFunctionType(returnType, typeVariables);
    exitLocalScope();
    push(type);
  }

  @override
  void handleVoidKeyword(Token token) {
    debugEvent("VoidKeyword");
    int offset = offsetForToken(token);
    push(new UnresolvedType<KernelTypeBuilder>(
        new KernelNamedTypeBuilder("void", null)
          ..bind(new VoidTypeBuilder<KernelTypeBuilder, VoidType>(
              const VoidType(), library, offset)),
        offset,
        uri));
  }

  @override
  void handleAsOperator(Token operator) {
    debugEvent("AsOperator");
    DartType type = buildDartType(pop());
    library.checkBoundsInType(type, typeEnvironment, operator.charOffset);
    Expression expression = popForValue();
    if (!library.loader.target.enableConstantUpdate2018 &&
        constantContext != ConstantContext.none) {
      push(desugarSyntheticExpression(buildProblem(
          fasta.templateNotConstantExpression.withArguments('As expression'),
          operator.charOffset,
          operator.length)));
    } else {
      Expression node = forest.asExpression(expression, type, operator);
      push(node);
    }
  }

  @override
  void handleIsOperator(Token isOperator, Token not) {
    debugEvent("IsOperator");
    DartType type = buildDartType(pop());
    Expression operand = popForValue();
    bool isInverted = not != null;
    Expression isExpression =
        forest.isExpression(operand, isOperator, not, type);
    library.checkBoundsInType(type, typeEnvironment, isOperator.charOffset);
    if (operand is VariableGet) {
      typePromoter?.handleIsCheck(isExpression, isInverted, operand.variable,
          type, functionNestingLevel);
    }
    if (!library.loader.target.enableConstantUpdate2018 &&
        constantContext != ConstantContext.none) {
      push(desugarSyntheticExpression(buildProblem(
          fasta.templateNotConstantExpression.withArguments('Is expression'),
          isOperator.charOffset,
          isOperator.length)));
    } else {
      push(isExpression);
    }
  }

  @override
  void beginConditionalExpression(Token question) {
    Expression condition = popForValue();
    typePromoter?.enterThen(condition);
    push(condition);
    super.beginConditionalExpression(question);
  }

  @override
  void handleConditionalExpressionColon() {
    Expression then = popForValue();
    typePromoter?.enterElse();
    push(then);
    super.handleConditionalExpressionColon();
  }

  @override
  void endConditionalExpression(Token question, Token colon) {
    debugEvent("ConditionalExpression");
    Expression elseExpression = popForValue();
    Expression thenExpression = pop();
    Expression condition = pop();
    typePromoter?.exitConditional();
    push(forest.conditionalExpression(
        condition, question, thenExpression, colon, elseExpression));
  }

  @override
  void handleThrowExpression(Token throwToken, Token endToken) {
    debugEvent("ThrowExpression");
    Expression expression = popForValue();
    if (constantContext != ConstantContext.none) {
      push(buildProblem(
          fasta.templateNotConstantExpression.withArguments('Throw'),
          throwToken.offset,
          throwToken.length));
    } else {
      push(forest.throwExpression(throwToken, expression));
    }
  }

  @override
  void beginFormalParameter(Token token, MemberKind kind, Token requiredToken,
      Token covariantToken, Token varFinalOrConst) {
    // TODO(danrubel): handle required token
    reportNonNullableModifierError(requiredToken);
    push((covariantToken != null ? covariantMask : 0) |
        Modifier.validateVarFinalOrConst(varFinalOrConst?.lexeme));
  }

  @override
  void endFormalParameter(Token thisKeyword, Token periodAfterThis,
      Token nameToken, FormalParameterKind kind, MemberKind memberKind) {
    debugEvent("FormalParameter");
    if (thisKeyword != null) {
      if (!inConstructor) {
        handleRecoverableError(fasta.messageFieldInitializerOutsideConstructor,
            thisKeyword, thisKeyword);
        thisKeyword = null;
      }
    }
    Object nameNode = pop();
    UnresolvedType<KernelTypeBuilder> type = pop();
    if (functionNestingLevel == 0) {
      // TODO(ahe): The type we compute here may be different from what is
      // computed in the outline phase. We should make sure that the outline
      // phase computes the same type. See
      // pkg/front_end/testcases/deferred_type_annotation.dart for an example
      // where not calling [buildDartType] leads to a missing compile-time
      // error. Also, notice that the type of the problematic parameter isn't
      // `invalid-type`.
      buildDartType(type);
    }
    int modifiers = pop();
    if (inCatchClause) {
      modifiers |= finalMask;
    }
    List<Expression> annotations = pop();
    if (nameNode is ParserRecovery) {
      push(nameNode);
      return;
    }
    Identifier name = nameNode;
    KernelFormalParameterBuilder parameter;
    if (!inCatchClause &&
        functionNestingLevel == 0 &&
        memberKind != MemberKind.GeneralizedFunctionType) {
      ProcedureBuilder<TypeBuilder> member = this.member;
      parameter = member.getFormal(name.name);
      if (parameter == null) {
        push(new ParserRecovery(nameToken.charOffset));
        return;
      }
    } else {
      parameter = new KernelFormalParameterBuilder(null, modifiers,
          type?.builder, name?.name, library, offsetForToken(nameToken));
    }
    VariableDeclaration variable =
        parameter.build(library, functionNestingLevel);
    Expression initializer = name?.initializer;
    if (initializer != null) {
      if (member is KernelRedirectingFactoryBuilder) {
        KernelRedirectingFactoryBuilder factory = member;
        addProblem(
            fasta.templateDefaultValueInRedirectingFactoryConstructor
                .withArguments(factory.redirectionTarget.fullNameForErrors),
            initializer.fileOffset,
            noLength);
      } else {
        variable.initializer = initializer..parent = variable;
      }
    } else if (kind != FormalParameterKind.mandatory) {
      variable.initializer ??= forest.literalNull(null)..parent = variable;
    }
    if (annotations != null) {
      if (functionNestingLevel == 0) {
        inferAnnotations(annotations);
      }
      for (Expression annotation in annotations) {
        variable.addAnnotation(annotation);
      }
    }
    push(parameter);
  }

  @override
  void endOptionalFormalParameters(
      int count, Token beginToken, Token endToken) {
    debugEvent("OptionalFormalParameters");
    FormalParameterKind kind = optional("{", beginToken)
        ? FormalParameterKind.optionalNamed
        : FormalParameterKind.optionalPositional;
    // When recovering from an empty list of optional arguments, count may be
    // 0. It might be simpler if the parser didn't call this method in that
    // case, however, then [beginOptionalFormalParameters] wouldn't always be
    // matched by this method.
    List<KernelFormalParameterBuilder> parameters =
        const FixedNullableList<KernelFormalParameterBuilder>()
            .pop(stack, count);
    if (parameters == null) {
      push(new ParserRecovery(offsetForToken(beginToken)));
    } else {
      for (KernelFormalParameterBuilder parameter in parameters) {
        parameter.kind = kind;
      }
      push(parameters);
    }
  }

  @override
  void beginFunctionTypedFormalParameter(Token token) {
    debugEvent("beginFunctionTypedFormalParameter");
    functionNestingLevel++;
  }

  @override
  void endFunctionTypedFormalParameter(Token nameToken) {
    debugEvent("FunctionTypedFormalParameter");
    if (inCatchClause || functionNestingLevel != 0) {
      exitLocalScope();
    }
    FormalParameters formals = pop();
    UnresolvedType<KernelTypeBuilder> returnType = pop();
    List<KernelTypeVariableBuilder> typeVariables = pop();
    UnresolvedType<KernelTypeBuilder> type =
        formals.toFunctionType(returnType, typeVariables);
    exitLocalScope();
    push(type);
    functionNestingLevel--;
  }

  @override
  void beginFormalParameterDefaultValueExpression() {
    super.push(constantContext);
    constantContext = ConstantContext.required;
  }

  @override
  void endFormalParameterDefaultValueExpression() {
    debugEvent("FormalParameterDefaultValueExpression");
    Object defaultValueExpression = pop();
    constantContext = pop();
    push(defaultValueExpression);
  }

  @override
  void handleValuedFormalParameter(Token equals, Token token) {
    debugEvent("ValuedFormalParameter");
    Expression initializer = popForValue();
    Object name = pop();
    if (name is ParserRecovery) {
      push(name);
    } else {
      push(new InitializedIdentifier(name, initializer));
    }
  }

  @override
  void handleFormalParameterWithoutValue(Token token) {
    debugEvent("FormalParameterWithoutValue");
  }

  @override
  void beginFormalParameters(Token token, MemberKind kind) {
    super.push(constantContext);
    constantContext = ConstantContext.none;
  }

  @override
  void endFormalParameters(
      int count, Token beginToken, Token endToken, MemberKind kind) {
    debugEvent("FormalParameters");
    List<KernelFormalParameterBuilder> optionals;
    int optionalsCount = 0;
    if (count > 0 && peek() is List<KernelFormalParameterBuilder>) {
      optionals = pop();
      count--;
      optionalsCount = optionals.length;
    }
    List<KernelFormalParameterBuilder> parameters =
        const FixedNullableList<KernelFormalParameterBuilder>()
            .popPadded(stack, count, optionalsCount);
    if (optionals != null && parameters != null) {
      parameters.setRange(count, count + optionalsCount, optionals);
    }
    assert(parameters?.isNotEmpty ?? true);
    FormalParameters formals = new FormalParameters(parameters,
        offsetForToken(beginToken), lengthOfSpan(beginToken, endToken), uri);
    constantContext = pop();
    push(formals);
    if ((inCatchClause || functionNestingLevel != 0) &&
        kind != MemberKind.GeneralizedFunctionType) {
      enterLocalScope(
          null,
          formals.computeFormalParameterScope(
              scope, member ?? classBuilder ?? library, this));
    }
  }

  @override
  void beginCatchClause(Token token) {
    debugEvent("beginCatchClause");
    inCatchClause = true;
  }

  @override
  void endCatchClause(Token token) {
    debugEvent("CatchClause");
    inCatchClause = false;
    push(inCatchBlock);
    inCatchBlock = true;
  }

  @override
  void handleCatchBlock(Token onKeyword, Token catchKeyword, Token comma) {
    debugEvent("CatchBlock");
    Statement body = pop();
    inCatchBlock = pop();
    if (catchKeyword != null) {
      exitLocalScope();
    }
    FormalParameters catchParameters = popIfNotNull(catchKeyword);
    DartType exceptionType =
        buildDartType(popIfNotNull(onKeyword)) ?? const DynamicType();
    KernelFormalParameterBuilder exception;
    KernelFormalParameterBuilder stackTrace;
    List<Statement> compileTimeErrors;
    if (catchParameters?.parameters != null) {
      int parameterCount = catchParameters.parameters.length;
      if (parameterCount > 0) {
        exception = catchParameters.parameters[0];
        exception.build(library, functionNestingLevel).type = exceptionType;
        if (parameterCount > 1) {
          stackTrace = catchParameters.parameters[1];
          stackTrace.build(library, functionNestingLevel).type =
              coreTypes.stackTraceClass.rawType;
        }
      }
      if (parameterCount > 2) {
        // If parameterCount is 0, the parser reported an error already.
        if (parameterCount != 0) {
          for (int i = 2; i < parameterCount; i++) {
            KernelFormalParameterBuilder parameter =
                catchParameters.parameters[i];
            compileTimeErrors ??= <Statement>[];
            compileTimeErrors.add(buildProblemStatement(
                fasta.messageCatchSyntaxExtraParameters, parameter.charOffset,
                length: parameter.name.length));
          }
        }
      }
    }
    push(forest.catchClause(
        onKeyword,
        exceptionType,
        catchKeyword,
        exception?.target,
        stackTrace?.target,
        coreTypes.stackTraceClass.rawType,
        body));
    if (compileTimeErrors == null) {
      push(NullValue.Block);
    } else {
      push(forest.block(null, compileTimeErrors, null));
    }
  }

  @override
  void endTryStatement(int catchCount, Token tryKeyword, Token finallyKeyword) {
    Statement finallyBlock = popStatementIfNotNull(finallyKeyword);
    List<Catch> catchBlocks;
    List<Statement> compileTimeErrors;
    if (catchCount != 0) {
      List<Object> catchBlocksAndErrors =
          const FixedNullableList<Object>().pop(stack, catchCount * 2);
      catchBlocks = new List<Catch>.filled(catchCount, null, growable: true);
      for (int i = 0; i < catchCount; i++) {
        catchBlocks[i] = catchBlocksAndErrors[i * 2];
        Statement error = catchBlocksAndErrors[i * 2 + 1];
        if (error != null) {
          compileTimeErrors ??= <Statement>[];
          compileTimeErrors.add(error);
        }
      }
    }
    Statement tryBlock = popStatement();
    Statement tryStatement = forest.tryStatement(
        tryKeyword, tryBlock, catchBlocks, finallyKeyword, finallyBlock);
    if (compileTimeErrors != null) {
      compileTimeErrors.add(tryStatement);
      push(forest.block(null, compileTimeErrors, null));
    } else {
      push(tryStatement);
    }
  }

  @override
  void handleIndexedExpression(
      Token openSquareBracket, Token closeSquareBracket) {
    debugEvent("IndexedExpression");
    Expression index = popForValue();
    Object receiver = pop();
    if (receiver is ThisAccessGenerator && receiver.isSuper) {
      push(new SuperIndexedAccessGenerator(
          this,
          openSquareBracket,
          index,
          lookupInstanceMember(indexGetName, isSuper: true),
          lookupInstanceMember(indexSetName, isSuper: true)));
    } else {
      push(IndexedAccessGenerator.make(
          this, openSquareBracket, toValue(receiver), index, null, null));
    }
  }

  @override
  void handleUnaryPrefixExpression(Token token) {
    debugEvent("UnaryPrefixExpression");
    Object receiver = pop();
    if (optional("!", token)) {
      push(forest.notExpression(toValue(receiver), token, false));
    } else {
      String operator = token.stringValue;
      Expression receiverValue;
      if (optional("-", token)) {
        operator = "unary-";
      }
      bool isSuper = false;
      if (receiver is ThisAccessGenerator && receiver.isSuper) {
        isSuper = true;
        receiverValue = forest.thisExpression(receiver.token);
      } else {
        receiverValue = toValue(receiver);
      }
      push(buildMethodInvocation(receiverValue, new Name(operator),
          forest.argumentsEmpty(noLocation), token.charOffset,
          // This *could* be a constant expression, we can't know without
          // evaluating [receiver].
          isConstantExpression: !isSuper,
          isSuper: isSuper));
    }
  }

  Name incrementOperator(Token token) {
    if (optional("++", token)) return plusName;
    if (optional("--", token)) return minusName;
    return unhandled(token.lexeme, "incrementOperator", token.charOffset, uri);
  }

  @override
  void handleUnaryPrefixAssignmentExpression(Token token) {
    debugEvent("UnaryPrefixAssignmentExpression");
    Object generator = pop();
    if (generator is Generator) {
      push(generator.buildPrefixIncrement(incrementOperator(token),
          offset: token.charOffset));
    } else {
      push(wrapInProblem(
          toValue(generator), fasta.messageNotAnLvalue, noLength));
    }
  }

  @override
  void handleUnaryPostfixAssignmentExpression(Token token) {
    debugEvent("UnaryPostfixAssignmentExpression");
    Object generator = pop();
    if (generator is Generator) {
      push(new DelayedPostfixIncrement(
          this, token, generator, incrementOperator(token), null));
    } else {
      push(wrapInProblem(
          toValue(generator), fasta.messageNotAnLvalue, noLength));
    }
  }

  @override
  void endConstructorReference(
      Token start, Token periodBeforeName, Token endToken) {
    debugEvent("ConstructorReference");
    pushQualifiedReference(start, periodBeforeName);
  }

  /// A qualified reference is something that matches one of:
  ///
  ///     identifier
  ///     identifier typeArguments? '.' identifier
  ///     identifier '.' identifier typeArguments? '.' identifier
  ///
  /// That is, one to three identifiers separated by periods and optionally one
  /// list of type arguments.
  ///
  /// A qualified reference can be used to represent both a reference to
  /// compile-time constant variable (metadata) or a constructor reference
  /// (used by metadata, new/const expression, and redirecting factories).
  ///
  /// Note that the parser will report errors if metadata includes type
  /// arguments, but will other preserve them for error recovery.
  ///
  /// A constructor reference can contain up to three identifiers:
  ///
  ///     a) type typeArguments?
  ///     b) type typeArguments? '.' name
  ///     c) prefix '.' type typeArguments?
  ///     d) prefix '.' type typeArguments? '.' name
  ///
  /// This isn't a legal constructor reference:
  ///
  ///     type '.' name typeArguments?
  ///
  /// But the parser can't tell this from type c) above.
  ///
  /// This method pops 2 (or 3 if `periodBeforeName != null`) values from the
  /// stack and pushes 3 values: a generator (the type in a constructor
  /// reference, or an expression in metadata), a list of type arguments, and a
  /// name.
  void pushQualifiedReference(Token start, Token periodBeforeName) {
    Identifier suffix = popIfNotNull(periodBeforeName);
    Identifier identifier;
    List<UnresolvedType<KernelTypeBuilder>> typeArguments = pop();
    Object type = pop();
    if (type is QualifiedName) {
      identifier = type;
      QualifiedName qualified = type;
      Object qualifier = qualified.qualifier;
      if (qualifier is TypeUseGenerator) {
        type = qualifier;
        if (typeArguments != null) {
          // TODO(ahe): Point to the type arguments instead.
          addProblem(fasta.messageConstructorWithTypeArguments,
              identifier.charOffset, identifier.name.length);
        }
      } else if (qualifier is Generator) {
        type = qualifier.qualifiedLookup(deprecated_extractToken(identifier));
        identifier = null;
      } else {
        unhandled("${qualifier.runtimeType}", "pushQualifiedReference",
            start.charOffset, uri);
      }
    }
    String name;
    if (identifier != null && suffix != null) {
      name = "${identifier.name}.${suffix.name}";
    } else if (identifier != null) {
      name = identifier.name;
    } else if (suffix != null) {
      name = suffix.name;
    } else {
      name = "";
    }
    push(type);
    push(typeArguments ?? NullValue.TypeArguments);
    push(name);
    push(suffix ?? identifier ?? NullValue.Identifier);
  }

  @override
  Expression buildStaticInvocation(Member target, Arguments arguments,
      {Constness constness: Constness.implicit,
      int charOffset: -1,
      int charLength: noLength}) {
    // The argument checks for the initial target of redirecting factories
    // invocations are skipped in Dart 1.
    if (!legacyMode || !isRedirectingFactory(target)) {
      List<TypeParameter> typeParameters = target.function.typeParameters;
      if (target is Constructor) {
        assert(!target.enclosingClass.isAbstract);
        typeParameters = target.enclosingClass.typeParameters;
      }
      LocatedMessage argMessage = checkArgumentsForFunction(
          target.function, arguments, charOffset, typeParameters);
      if (argMessage != null) {
        return wrapSyntheticExpression(
            throwNoSuchMethodError(
                forest.literalNull(null)..fileOffset = charOffset,
                target.name.name,
                arguments,
                charOffset,
                candidate: target,
                message: argMessage),
            charOffset);
      }
    }

    bool isConst = constness == Constness.explicitConst;
    if (target is Constructor) {
      isConst =
          isConst || constantContext != ConstantContext.none && target.isConst;
      if ((isConst || constantContext == ConstantContext.inferred) &&
          !target.isConst) {
        return wrapInvalidConstructorInvocation(
            desugarSyntheticExpression(buildProblem(
                fasta.messageNonConstConstructor, charOffset, charLength)),
            target,
            arguments,
            charOffset);
      }
      ConstructorInvocation node = new ConstructorInvocation(
          target, forest.castArguments(arguments),
          isConst: isConst)
        ..fileOffset = charOffset;
      library.checkBoundsInConstructorInvocation(node, typeEnvironment);
      return node;
    } else {
      Procedure procedure = target;
      if (procedure.isFactory) {
        isConst = isConst ||
            constantContext != ConstantContext.none && procedure.isConst;
        if ((isConst || constantContext == ConstantContext.inferred) &&
            !procedure.isConst) {
          return wrapInvalidConstructorInvocation(
              desugarSyntheticExpression(buildProblem(
                  fasta.messageNonConstFactory, charOffset, charLength)),
              target,
              arguments,
              charOffset);
        }
        StaticInvocation node = FactoryConstructorInvocationJudgment(
            target, forest.castArguments(arguments),
            isConst: isConst)
          ..fileOffset = charOffset;
        library.checkBoundsInFactoryInvocation(node, typeEnvironment);
        return node;
      } else {
        StaticInvocation node = new StaticInvocation(
            target, forest.castArguments(arguments),
            isConst: isConst)
          ..fileOffset = charOffset;
        library.checkBoundsInStaticInvocation(node, typeEnvironment);
        return node;
      }
    }
  }

  @override
  LocatedMessage checkArgumentsForFunction(FunctionNode function,
      Arguments arguments, int offset, List<TypeParameter> typeParameters) {
    if (forest.argumentsPositional(arguments).length <
        function.requiredParameterCount) {
      return fasta.templateTooFewArguments
          .withArguments(function.requiredParameterCount,
              forest.argumentsPositional(arguments).length)
          .withLocation(uri, arguments.fileOffset, noLength);
    }
    if (forest.argumentsPositional(arguments).length >
        function.positionalParameters.length) {
      return fasta.templateTooManyArguments
          .withArguments(function.positionalParameters.length,
              forest.argumentsPositional(arguments).length)
          .withLocation(uri, arguments.fileOffset, noLength);
    }
    List<Object> named = forest.argumentsNamed(arguments);
    if (named.isNotEmpty) {
      Set<String> names =
          new Set.from(function.namedParameters.map((a) => a.name));
      for (NamedExpression argument in named) {
        if (!names.contains(argument.name)) {
          return fasta.templateNoSuchNamedParameter
              .withArguments(argument.name)
              .withLocation(uri, argument.fileOffset, argument.name.length);
        }
      }
    }

    List<DartType> types = forest.argumentsTypeArguments(arguments);
    if (typeParameters.length != types.length) {
      if (types.length == 0) {
        // Expected `typeParameters.length` type arguments, but none given, so
        // we fill in dynamic in legacy mode, and use type inference otherwise.
        if (legacyMode) {
          for (int i = 0; i < typeParameters.length; i++) {
            types.add(const DynamicType());
          }
        }
      } else {
        // A wrong (non-zero) amount of type arguments given. That's an error.
        // TODO(jensj): Position should be on type arguments instead.
        return fasta.templateTypeArgumentMismatch
            .withArguments(typeParameters.length)
            .withLocation(uri, offset, noLength);
      }
    }

    return null;
  }

  @override
  LocatedMessage checkArgumentsForType(
      FunctionType function, Arguments arguments, int offset) {
    if (forest.argumentsPositional(arguments).length <
        function.requiredParameterCount) {
      return fasta.templateTooFewArguments
          .withArguments(function.requiredParameterCount,
              forest.argumentsPositional(arguments).length)
          .withLocation(uri, arguments.fileOffset, noLength);
    }
    if (forest.argumentsPositional(arguments).length >
        function.positionalParameters.length) {
      return fasta.templateTooManyArguments
          .withArguments(function.positionalParameters.length,
              forest.argumentsPositional(arguments).length)
          .withLocation(uri, arguments.fileOffset, noLength);
    }
    List<Object> named = forest.argumentsNamed(arguments);
    if (named.isNotEmpty) {
      Set<String> names =
          new Set.from(function.namedParameters.map((a) => a.name));
      for (NamedExpression argument in named) {
        if (!names.contains(argument.name)) {
          return fasta.templateNoSuchNamedParameter
              .withArguments(argument.name)
              .withLocation(uri, argument.fileOffset, argument.name.length);
        }
      }
    }
    List<Object> types = forest.argumentsTypeArguments(arguments);
    List<TypeParameter> typeParameters = function.typeParameters;
    if (typeParameters.length != types.length && types.length != 0) {
      // A wrong (non-zero) amount of type arguments given. That's an error.
      // TODO(jensj): Position should be on type arguments instead.
      return fasta.templateTypeArgumentMismatch
          .withArguments(typeParameters.length)
          .withLocation(uri, offset, noLength);
    }

    return null;
  }

  @override
  void beginNewExpression(Token token) {
    debugEvent("beginNewExpression");
    super.push(constantContext);
    if (constantContext != ConstantContext.none) {
      addProblem(
          fasta.templateNotConstantExpression.withArguments('New expression'),
          token.charOffset,
          token.length);
    }
    constantContext = ConstantContext.none;
  }

  @override
  void beginConstExpression(Token token) {
    debugEvent("beginConstExpression");
    super.push(constantContext);
    constantContext = ConstantContext.inferred;
  }

  @override
  void beginConstLiteral(Token token) {
    debugEvent("beginConstLiteral");
    super.push(constantContext);
    constantContext = ConstantContext.inferred;
  }

  @override
  void beginImplicitCreationExpression(Token token) {
    debugEvent("beginImplicitCreationExpression");
    super.push(constantContext);
  }

  @override
  void endConstLiteral(Token token) {
    debugEvent("endConstLiteral");
    Object literal = pop();
    constantContext = pop();
    push(literal);
  }

  @override
  void endNewExpression(Token token) {
    debugEvent("NewExpression");
    buildConstructorReferenceInvocation(
        token.next, token.offset, Constness.explicitNew);
  }

  void buildConstructorReferenceInvocation(
      Token nameToken, int offset, Constness constness) {
    Arguments arguments = pop();
    Identifier nameLastIdentifier = pop(NullValue.Identifier);
    Token nameLastToken =
        deprecated_extractToken(nameLastIdentifier) ?? nameToken;
    String name = pop();
    List<UnresolvedType<KernelTypeBuilder>> typeArguments = pop();

    Object type = pop();

    ConstantContext savedConstantContext = pop();
    if (type is Generator) {
      push(type.invokeConstructor(
          typeArguments, name, arguments, nameToken, nameLastToken, constness));
    } else if (type is ParserRecovery) {
      push(new ParserErrorGenerator(
          this, nameToken, fasta.messageSyntheticToken));
    } else {
      push(wrapSyntheticExpression(
          throwNoSuchMethodError(
              forest.literalNull(null)..fileOffset = offset,
              debugName(getNodeName(type), name),
              arguments,
              nameToken.charOffset),
          offset));
    }
    constantContext = savedConstantContext;
  }

  @override
  void endImplicitCreationExpression(Token token) {
    debugEvent("ImplicitCreationExpression");
    buildConstructorReferenceInvocation(
        token, token.offset, Constness.implicit);
  }

  @override
  Expression buildConstructorInvocation(
      TypeDeclarationBuilder<TypeBuilder, Object> type,
      Token nameToken,
      Token nameLastToken,
      Arguments arguments,
      String name,
      List<UnresolvedType<KernelTypeBuilder>> typeArguments,
      int charOffset,
      Constness constness) {
    if (arguments == null) {
      return buildProblem(fasta.messageMissingArgumentList,
          nameToken.charOffset, nameToken.length);
    }
    if (name.isNotEmpty && arguments.types.isNotEmpty) {
      // TODO(ahe): Point to the type arguments instead.
      addProblem(fasta.messageConstructorWithTypeArguments,
          nameToken.charOffset, nameToken.length);
    }

    if (typeArguments != null) {
      assert(forest.argumentsTypeArguments(arguments).isEmpty);
      forest.argumentsSetTypeArguments(
          arguments, buildDartTypeArguments(typeArguments));
    }

    String errorName;
    LocatedMessage message;
    if (type is ClassBuilder<TypeBuilder, Object>) {
      if (type is EnumBuilder<TypeBuilder, Object>) {
        return buildProblem(fasta.messageEnumInstantiation,
            nameToken.charOffset, nameToken.length);
      }
      Declaration b =
          type.findConstructorOrFactory(name, charOffset, uri, library);
      Member target = b?.target;
      if (b == null) {
        // Not found. Reported below.
      } else if (b is ProblemBuilder) {
        message = b.message.withLocation(uri, charOffset, noLength);
      } else if (b.isConstructor) {
        if (type.isAbstract) {
          return wrapInvalidConstructorInvocation(
              evaluateArgumentsBefore(
                  arguments,
                  buildAbstractClassInstantiationError(
                      fasta.templateAbstractClassInstantiation
                          .withArguments(type.name),
                      type.name,
                      nameToken.charOffset)),
              target,
              arguments,
              charOffset);
        }
      }
      if (target is Constructor ||
          (target is Procedure && target.kind == ProcedureKind.Factory)) {
        Expression invocation;

        if (legacyMode && isRedirectingFactory(target)) {
          // In legacy mode the checks that are done in [buildStaticInvocation]
          // on the initial target of a redirecting factory invocation should
          // be skipped. So we build the invocation nodes directly here without
          // doing any checks.
          if (target.function.typeParameters != null &&
              target.function.typeParameters.length !=
                  forest.argumentsTypeArguments(arguments).length) {
            arguments = forest.arguments(
                forest.argumentsPositional(arguments), null,
                named: forest.argumentsNamed(arguments),
                types: new List<DartType>.filled(
                    target.function.typeParameters.length, const DynamicType(),
                    growable: true));
          }
          invocation = new FactoryConstructorInvocationJudgment(
              target, forest.castArguments(arguments),
              isConst: constness == Constness.explicitConst)
            ..fileOffset = nameToken.charOffset;
        } else {
          invocation = buildStaticInvocation(target, arguments,
              constness: constness,
              charOffset: nameToken.charOffset,
              charLength: nameToken.length);
        }

        if (invocation is StaticInvocation && isRedirectingFactory(target)) {
          redirectingFactoryInvocations.add(invocation);
        }

        return invocation;
      } else {
        errorName ??= debugName(type.name, name);
      }
    } else if (type is InvalidTypeBuilder<TypeBuilder, Object>) {
      LocatedMessage message = type.message;
      return evaluateArgumentsBefore(
          arguments,
          buildProblem(message.messageObject, nameToken.charOffset,
              nameToken.lexeme.length));
    } else {
      errorName = debugName(getNodeName(type), name);
    }
    errorName ??= name;

    return wrapUnresolvedTargetInvocation(
        throwNoSuchMethodError(
            forest.literalNull(null)..fileOffset = charOffset,
            errorName,
            arguments,
            nameLastToken.charOffset,
            message: message),
        arguments,
        arguments.fileOffset);
  }

  @override
  void endConstExpression(Token token) {
    debugEvent("endConstExpression");
    buildConstructorReferenceInvocation(
        token.next, token.offset, Constness.explicitConst);
  }

  @override
  void beginIfControlFlow(Token ifToken) {
    // TODO(danrubel): consider removing this when control flow support is added
    // if the ifToken is not needed for error reporting
    push(ifToken);
  }

  @override
  void beginThenControlFlow(Token token) {
    Expression condition = popForValue();
    enterThenForTypePromotion(condition);
    push(condition);
    super.beginThenControlFlow(token);
  }

  @override
  void handleElseControlFlow(Token elseToken) {
    typePromoter?.enterElse();
  }

  @override
  void endIfControlFlow(Token token) {
    debugEvent("endIfControlFlow");
    var entry = pop();
    var condition = pop(); // parenthesized expression
    Token ifToken = pop();
    typePromoter?.enterElse();
    typePromoter?.exitConditional();
    if (!library.loader.target.enableControlFlowCollections) {
      // TODO(danrubel): Report a more user friendly error message
      // when an experiment is not enabled
      handleRecoverableError(
          fasta.templateUnexpectedToken.withArguments(ifToken),
          ifToken,
          ifToken);
      push(invalidCollectionElement);
      return;
    }

    if (constantContext != ConstantContext.none &&
        !library.loader.target.enableConstantUpdate2018) {
      handleRecoverableError(
          fasta.templateCantUseControlFlowOrSpreadAsConstant
              .withArguments(ifToken),
          ifToken,
          ifToken);
      push(invalidCollectionElement);
      return;
    }

    transformCollections = true;
    if (entry is MapEntry) {
      push(forest.ifMapEntry(toValue(condition), entry, null, ifToken));
    } else {
      push(forest.ifElement(toValue(condition), toValue(entry), null, ifToken));
    }
  }

  @override
  void endIfElseControlFlow(Token token) {
    debugEvent("endIfElseControlFlow");
    var elseEntry = pop(); // else entry
    var thenEntry = pop(); // then entry
    var condition = pop(); // parenthesized expression
    Token ifToken = pop();
    typePromoter?.exitConditional();
    if (!library.loader.target.enableControlFlowCollections) {
      // TODO(danrubel): Report a more user friendly error message
      // when an experiment is not enabled
      handleRecoverableError(
          fasta.templateUnexpectedToken.withArguments(ifToken),
          ifToken,
          ifToken);
      push(invalidCollectionElement);
      return;
    }

    if (constantContext != ConstantContext.none &&
        !library.loader.target.enableConstantUpdate2018) {
      handleRecoverableError(
          fasta.templateCantUseControlFlowOrSpreadAsConstant
              .withArguments(ifToken),
          ifToken,
          ifToken);
      push(invalidCollectionElement);
      return;
    }

    transformCollections = true;
    if (thenEntry is MapEntry) {
      if (elseEntry is MapEntry) {
        push(forest.ifMapEntry(
            toValue(condition), thenEntry, elseEntry, ifToken));
      } else if (elseEntry is SpreadElement) {
        push(forest.ifMapEntry(
            toValue(condition),
            thenEntry,
            new SpreadMapEntry(elseEntry.expression, elseEntry.isNullAware),
            ifToken));
      } else {
        int offset = elseEntry is Expression
            ? elseEntry.fileOffset
            : offsetForToken(ifToken);
        push(new MapEntry(
            desugarSyntheticExpression(buildProblem(
                fasta.templateExpectedAfterButGot.withArguments(':'),
                offset,
                1)),
            new NullLiteral())
          ..fileOffset = offsetForToken(ifToken));
      }
    } else if (elseEntry is MapEntry) {
      if (thenEntry is SpreadElement) {
        push(forest.ifMapEntry(
            toValue(condition),
            new SpreadMapEntry(thenEntry.expression, thenEntry.isNullAware),
            elseEntry,
            ifToken));
      } else {
        int offset = thenEntry is Expression
            ? thenEntry.fileOffset
            : offsetForToken(ifToken);
        push(new MapEntry(
            desugarSyntheticExpression(buildProblem(
                fasta.templateExpectedAfterButGot.withArguments(':'),
                offset,
                1)),
            new NullLiteral())
          ..fileOffset = offsetForToken(ifToken));
      }
    } else {
      push(forest.ifElement(
          toValue(condition), toValue(thenEntry), toValue(elseEntry), ifToken));
    }
  }

  @override
  void handleSpreadExpression(Token spreadToken) {
    debugEvent("SpreadExpression");
    var expression = pop();
    if (!library.loader.target.enableSpreadCollections) {
      handleRecoverableError(
          fasta.templateUnexpectedToken.withArguments(spreadToken),
          spreadToken,
          spreadToken);
      push(invalidCollectionElement);
      return;
    }

    if (constantContext != ConstantContext.none &&
        !library.loader.target.enableConstantUpdate2018) {
      handleRecoverableError(
          fasta.templateCantUseControlFlowOrSpreadAsConstant
              .withArguments(spreadToken),
          spreadToken,
          spreadToken);
      push(invalidCollectionElement);
      return;
    }

    transformCollections = true;
    push(forest.spreadElement(toValue(expression), spreadToken));
  }

  @override
  void endTypeArguments(int count, Token beginToken, Token endToken) {
    debugEvent("TypeArguments");
    push(const FixedNullableList<UnresolvedType<KernelTypeBuilder>>()
            .pop(stack, count) ??
        NullValue.TypeArguments);
  }

  @override
  void handleInvalidTypeArguments(Token token) {
    debugEvent("InvalidTypeArguments");
    pop(NullValue.TypeArguments);
  }

  @override
  void handleThisExpression(Token token, IdentifierContext context) {
    debugEvent("ThisExpression");
    if (context.isScopeReference && isInstanceContext) {
      push(new ThisAccessGenerator(
          this, token, inInitializer, inFieldInitializer));
    } else {
      push(new IncompleteErrorGenerator(
          this, token, fasta.messageThisAsIdentifier));
    }
  }

  @override
  void handleSuperExpression(Token token, IdentifierContext context) {
    debugEvent("SuperExpression");
    if (context.isScopeReference && isInstanceContext) {
      Member member = this.member.target;
      member.transformerFlags |= TransformerFlag.superCalls;
      push(new ThisAccessGenerator(
          this, token, inInitializer, inFieldInitializer,
          isSuper: true));
    } else {
      push(new IncompleteErrorGenerator(
          this, token, fasta.messageSuperAsIdentifier));
    }
  }

  @override
  void handleNamedArgument(Token colon) {
    debugEvent("NamedArgument");
    Expression value = popForValue();
    Identifier identifier = pop();
    push(new NamedExpression(identifier.name, value)
      ..fileOffset = identifier.charOffset);
  }

  @override
  void endFunctionName(Token beginToken, Token token) {
    debugEvent("FunctionName");
    Identifier name = pop();
    Token nameToken = deprecated_extractToken(name);
    VariableDeclaration variable = new VariableDeclarationJudgment(
        name.name, functionNestingLevel,
        forSyntheticToken: nameToken.isSynthetic,
        isFinal: true,
        isLocalFunction: true)
      ..fileOffset = name.charOffset;
    // TODO(ahe): Why are we looking up in local scope, but declaring in parent
    // scope?
    Declaration existing = scope.local[name.name];
    if (existing != null) {
      reportDuplicatedDeclaration(existing, name.name, name.charOffset);
    }
    push(new FunctionDeclarationJudgment(
        variable,
        // The function node is created later.
        null)
      ..fileOffset = beginToken.charOffset);
    declareVariable(variable, scope.parent);
  }

  void enterFunction() {
    debugEvent("enterFunction");
    functionNestingLevel++;
    push(switchScope ?? NullValue.SwitchScope);
    switchScope = null;
    push(inCatchBlock);
    inCatchBlock = false;
  }

  void exitFunction() {
    debugEvent("exitFunction");
    functionNestingLevel--;
    inCatchBlock = pop();
    switchScope = pop();
    List<KernelTypeVariableBuilder> typeVariables = pop();
    exitLocalScope();
    push(typeVariables ?? NullValue.TypeVariables);
  }

  @override
  void beginLocalFunctionDeclaration(Token token) {
    debugEvent("beginLocalFunctionDeclaration");
    enterFunction();
  }

  @override
  void beginNamedFunctionExpression(Token token) {
    debugEvent("beginNamedFunctionExpression");
    List<KernelTypeVariableBuilder> typeVariables = pop();
    // Create an additional scope in which the named function expression is
    // declared.
    enterLocalScope("named function");
    push(typeVariables ?? NullValue.TypeVariables);
    enterFunction();
  }

  @override
  void beginFunctionExpression(Token token) {
    debugEvent("beginFunctionExpression");
    enterFunction();
  }

  void pushNamedFunction(Token token, bool isFunctionExpression) {
    Statement body = popStatement();
    AsyncMarker asyncModifier = pop();
    exitLocalScope();
    FormalParameters formals = pop();
    Object declaration = pop();
    UnresolvedType<KernelTypeBuilder> returnType = pop();
    bool hasImplicitReturnType = returnType == null;
    exitFunction();
    List<KernelTypeVariableBuilder> typeParameters = pop();
    List<Expression> annotations;
    if (!isFunctionExpression) {
      annotations = pop(); // Metadata.
    }
    FunctionNode function = formals.buildFunctionNode(library, returnType,
        typeParameters, asyncModifier, body, token.charOffset);

    if (declaration is FunctionDeclaration) {
      VariableDeclaration variable = declaration.variable;
      if (annotations != null) {
        for (Expression annotation in annotations) {
          variable.addAnnotation(annotation);
        }
      }
      FunctionDeclarationJudgment.setHasImplicitReturnType(
          declaration, hasImplicitReturnType);

      variable.type = function.functionType;
      if (isFunctionExpression) {
        Expression oldInitializer = variable.initializer;
        variable.initializer = new FunctionExpression(function)
          ..parent = variable
          ..fileOffset = formals.charOffset;
        exitLocalScope();
        Expression expression = new NamedFunctionExpressionJudgment(variable);
        if (oldInitializer != null) {
          // This must have been a compile-time error.
          Expression error = desugarSyntheticExpression(oldInitializer);
          assert(isErroneousNode(error));
          int offset = forest.readOffset(expression);
          push(wrapSyntheticExpression(
              new Let(
                  new VariableDeclaration.forValue(error)..fileOffset = offset,
                  expression)
                ..fileOffset = offset,
              offset));
        } else {
          push(expression);
        }
      } else {
        declaration.function = function;
        function.parent = declaration;
        if (variable.initializer != null) {
          // This must have been a compile-time error.
          assert(isErroneousNode(variable.initializer));

          push(forest.block(
              null,
              <Statement>[
                forest.expressionStatement(variable.initializer, token),
                declaration
              ],
              null)
            ..fileOffset = declaration.fileOffset);
          variable.initializer = null;
        } else {
          push(declaration);
        }
      }
    } else {
      return unhandled("${declaration.runtimeType}", "pushNamedFunction",
          token.charOffset, uri);
    }
  }

  @override
  void endNamedFunctionExpression(Token endToken) {
    debugEvent("NamedFunctionExpression");
    pushNamedFunction(endToken, true);
  }

  @override
  void endLocalFunctionDeclaration(Token token) {
    debugEvent("LocalFunctionDeclaration");
    pushNamedFunction(token, false);
  }

  @override
  void endFunctionExpression(Token beginToken, Token token) {
    debugEvent("FunctionExpression");
    Statement body = popStatement();
    AsyncMarker asyncModifier = pop();
    exitLocalScope();
    FormalParameters formals = pop();
    exitFunction();
    List<KernelTypeVariableBuilder> typeParameters = pop();
    FunctionNode function = formals.buildFunctionNode(
        library, null, typeParameters, asyncModifier, body, token.charOffset)
      ..fileOffset = beginToken.charOffset;

    if (library.legacyMode && asyncModifier != AsyncMarker.Sync) {
      DartType returnType;
      switch (asyncModifier) {
        case AsyncMarker.Async:
          returnType = coreTypes.futureClass.rawType;
          break;
        case AsyncMarker.AsyncStar:
          returnType = coreTypes.streamClass.rawType;
          break;
        case AsyncMarker.SyncStar:
          returnType = coreTypes.iterableClass.rawType;
          break;
        default:
          returnType = const DynamicType();
          break;
      }
      function.returnType = returnType;
    }
    if (constantContext != ConstantContext.none) {
      push(buildProblem(fasta.messageNotAConstantExpression, formals.charOffset,
          formals.length));
    } else {
      push(new FunctionExpression(function)
        ..fileOffset = offsetForToken(beginToken));
    }
  }

  @override
  void endDoWhileStatement(
      Token doKeyword, Token whileKeyword, Token endToken) {
    debugEvent("DoWhileStatement");
    Expression condition = popForValue();
    Statement body = popStatement();
    JumpTarget continueTarget = exitContinueTarget();
    JumpTarget breakTarget = exitBreakTarget();
    if (continueTarget.hasUsers) {
      body = forest.syntheticLabeledStatement(body);
      continueTarget.resolveContinues(forest, body);
    }
    Statement result =
        forest.doStatement(doKeyword, body, whileKeyword, condition, endToken);
    if (breakTarget.hasUsers) {
      result = forest.syntheticLabeledStatement(result);
      breakTarget.resolveBreaks(forest, result);
    }
    exitLoopOrSwitch(result);
  }

  @override
  void beginForInExpression(Token token) {
    enterLocalScope(null, scope.parent);
  }

  @override
  void endForInExpression(Token token) {
    debugEvent("ForInExpression");
    Expression expression = popForValue();
    exitLocalScope();
    push(expression ?? NullValue.Expression);
  }

  @override
  void handleForInLoopParts(Token awaitToken, Token forToken,
      Token leftParenthesis, Token inKeyword) {
    push(awaitToken ?? NullValue.AwaitToken);
    push(forToken);
    push(inKeyword);
  }

  @override
  void endForInControlFlow(Token token) {
    debugEvent("ForInControlFlow");
    var entry = pop();
    Token inToken = pop();
    Token forToken = pop();
    Token awaitToken = pop(NullValue.AwaitToken);
    Expression iterable = popForValue();
    Object lvalue = pop(); // lvalue
    exitLocalScope();

    if (!library.loader.target.enableControlFlowCollections) {
      // TODO(danrubel): Report a more user friendly error message
      // when an experiment is not enabled
      handleRecoverableError(
          fasta.templateUnexpectedToken.withArguments(forToken),
          forToken,
          forToken);
      push(invalidCollectionElement);
      return;
    }

    if (constantContext != ConstantContext.none &&
        !library.loader.target.enableConstantUpdate2018) {
      handleRecoverableError(
          fasta.templateCantUseControlFlowOrSpreadAsConstant
              .withArguments(forToken),
          forToken,
          forToken);
      push(invalidCollectionElement);
      return;
    }

    transformCollections = true;
    VariableDeclaration variable = buildForInVariable(lvalue);
    Expression problem = checkForInVariable(lvalue, variable, forToken);
    Statement prologue = buildForInBody(lvalue, variable, forToken, inToken);
    if (entry is MapEntry) {
      push(forest.forInMapEntry(
          variable, iterable, prologue, entry, problem, forToken,
          isAsync: awaitToken != null));
    } else {
      push(forest.forInElement(
          variable, iterable, prologue, toValue(entry), problem, forToken,
          isAsync: awaitToken != null));
    }
  }

  VariableDeclaration buildForInVariable(Object lvalue) {
    if (lvalue is VariableDeclaration) return lvalue;
    return new VariableDeclarationJudgment.forValue(null, functionNestingLevel);
  }

  Expression checkForInVariable(
      Object lvalue, VariableDeclaration variable, Token forToken) {
    if (lvalue is VariableDeclaration) {
      if (variable.isConst) {
        return buildProblem(fasta.messageForInLoopWithConstVariable,
            variable.fileOffset, variable.name.length);
      }
    } else if (lvalue is! Generator) {
      Message message = forest.isVariablesDeclaration(lvalue)
          ? fasta.messageForInLoopExactlyOneVariable
          : fasta.messageForInLoopNotAssignable;
      Token token = forToken.next.next;
      return buildProblem(
          message, offsetForToken(token), lengthForToken(token));
    }
    return null;
  }

  Statement buildForInBody(Object lvalue, VariableDeclaration variable,
      Token forToken, Token inKeyword) {
    if (lvalue is VariableDeclaration) return null;
    if (lvalue is Generator) {
      /// We are in this case, where `lvalue` isn't a [VariableDeclaration]:
      ///
      ///     for (lvalue in expression) body
      ///
      /// This is normalized to:
      ///
      ///     for (final #t in expression) {
      ///       lvalue = #t;
      ///       body;
      ///     }
      TypePromotionFact fact =
          typePromoter?.getFactForAccess(variable, functionNestingLevel);
      TypePromotionScope scope = typePromoter?.currentScope;
      Expression syntheticAssignment = lvalue.buildAssignment(
          new VariableGetJudgment(variable, fact, scope)
            ..fileOffset = inKeyword.offset,
          voidContext: true);
      if (syntheticAssignment is shadow.SyntheticExpressionJudgment) {
        syntheticAssignment = wrapSyntheticExpression(
            desugarSyntheticExpression(syntheticAssignment),
            offsetForToken(lvalue.token));
      }
      return forest.expressionStatement(syntheticAssignment, null);
    }
    Message message = forest.isVariablesDeclaration(lvalue)
        ? fasta.messageForInLoopExactlyOneVariable
        : fasta.messageForInLoopNotAssignable;
    Token token = forToken.next.next;
    Statement body;
    if (forest.isVariablesDeclaration(lvalue)) {
      body = forest.block(
          null,
          // New list because the declarations are not a growable list.
          new List<Statement>.from(
              forest.variablesDeclarationExtractDeclarations(lvalue)),
          null);
    } else {
      body = forest.expressionStatement(lvalue, null);
    }
    return combineStatements(
        forest.expressionStatement(
            buildProblem(message, offsetForToken(token), lengthForToken(token)),
            null),
        body);
  }

  @override
  void endForIn(Token endToken) {
    debugEvent("ForIn");
    Statement body = popStatement();

    Token inKeyword = pop();
    Token forToken = pop();
    Token awaitToken = pop(NullValue.AwaitToken);

    Expression expression = popForValue();
    Object lvalue = pop();
    exitLocalScope();
    JumpTarget continueTarget = exitContinueTarget();
    JumpTarget breakTarget = exitBreakTarget();
    if (continueTarget.hasUsers) {
      body = forest.syntheticLabeledStatement(body);
      continueTarget.resolveContinues(forest, body);
    }
    VariableDeclaration variable = buildForInVariable(lvalue);
    Expression problem = checkForInVariable(lvalue, variable, forToken);
    Statement prologue = buildForInBody(lvalue, variable, forToken, inKeyword);
    if (prologue != null) {
      if (prologue is Block) {
        if (body is Block) {
          for (Statement statement in body.statements) {
            prologue.addStatement(statement);
          }
        } else {
          prologue.addStatement(body);
        }
        body = prologue;
      } else {
        body = combineStatements(prologue, body);
      }
    }
    Statement result = new ForInStatement(variable, expression, body,
        isAsync: awaitToken != null)
      ..fileOffset = awaitToken?.charOffset ?? forToken.charOffset
      ..bodyOffset = body.fileOffset; // TODO(ahe): Isn't this redundant?
    if (breakTarget.hasUsers) {
      result = forest.syntheticLabeledStatement(result);
      breakTarget.resolveBreaks(forest, result);
    }
    if (problem != null) {
      result =
          combineStatements(forest.expressionStatement(problem, null), result);
    }
    exitLoopOrSwitch(result);
  }

  @override
  void handleLabel(Token token) {
    debugEvent("Label");
    Identifier identifier = pop();
    push(new Label(identifier.name, identifier.charOffset));
  }

  @override
  void beginLabeledStatement(Token token, int labelCount) {
    debugEvent("beginLabeledStatement");
    List<Label> labels =
        const FixedNullableList<Label>().pop(stack, labelCount);
    enterLocalScope(null, scope.createNestedLabelScope());
    LabelTarget target =
        new LabelTarget(member, functionNestingLevel, token.charOffset);
    if (labels != null) {
      for (Label label in labels) {
        scope.declareLabel(label.name, target);
      }
    }
    push(target);
  }

  @override
  void endLabeledStatement(int labelCount) {
    debugEvent("LabeledStatement");
    Statement statement = pop();
    LabelTarget target = pop();
    exitLocalScope();
    if (target.breakTarget.hasUsers || target.continueTarget.hasUsers) {
      if (forest.isVariablesDeclaration(statement)) {
        internalProblem(
            fasta.messageInternalProblemLabelUsageInVariablesDeclaration,
            statement.fileOffset,
            uri);
      }
      if (statement is! LabeledStatement) {
        statement = forest.syntheticLabeledStatement(statement);
      }
      target.breakTarget.resolveBreaks(forest, statement);
      target.continueTarget.resolveContinues(forest, statement);
    }
    push(statement);
  }

  @override
  void endRethrowStatement(Token rethrowToken, Token endToken) {
    debugEvent("RethrowStatement");
    if (inCatchBlock) {
      push(forest.rethrowStatement(rethrowToken, endToken));
    } else {
      push(new ExpressionStatementJudgment(buildProblem(
          fasta.messageRethrowNotCatch,
          offsetForToken(rethrowToken),
          lengthForToken(rethrowToken)))
        ..fileOffset = offsetForToken(rethrowToken));
    }
  }

  @override
  void handleFinallyBlock(Token finallyKeyword) {
    debugEvent("FinallyBlock");
    // Do nothing, handled by [endTryStatement].
  }

  @override
  void endWhileStatement(Token whileKeyword, Token endToken) {
    debugEvent("WhileStatement");
    Statement body = popStatement();
    Expression condition = popForValue();
    JumpTarget continueTarget = exitContinueTarget();
    JumpTarget breakTarget = exitBreakTarget();
    if (continueTarget.hasUsers) {
      body = forest.syntheticLabeledStatement(body);
      continueTarget.resolveContinues(forest, body);
    }
    Statement result = forest.whileStatement(whileKeyword, condition, body);
    if (breakTarget.hasUsers) {
      result = forest.syntheticLabeledStatement(result);
      breakTarget.resolveBreaks(forest, result);
    }
    exitLoopOrSwitch(result);
  }

  @override
  void handleEmptyStatement(Token token) {
    debugEvent("EmptyStatement");
    push(forest.emptyStatement(token));
  }

  @override
  void beginAssert(Token assertKeyword, Assert kind) {
    debugEvent("beginAssert");
    // If in an assert initializer, make sure [inInitializer] is false so we
    // use the formal parameter scope. If this is any other kind of assert,
    // inInitializer should be false anyway.
    inInitializer = false;
  }

  @override
  void endAssert(Token assertKeyword, Assert kind, Token leftParenthesis,
      Token commaToken, Token semicolonToken) {
    debugEvent("Assert");
    Expression message = popForValueIfNotNull(commaToken);
    Expression condition = popForValue();

    switch (kind) {
      case Assert.Statement:
        push(forest.assertStatement(assertKeyword, leftParenthesis, condition,
            commaToken, message, semicolonToken));
        break;

      case Assert.Expression:
        // The parser has already reported an error indicating that assert
        // cannot be used in an expression.
        push(buildProblem(fasta.messageAssertAsExpression, assertKeyword.offset,
            assertKeyword.length));
        break;

      case Assert.Initializer:
        push(forest.assertInitializer(
            assertKeyword, leftParenthesis, condition, commaToken, message));
        break;
    }
  }

  @override
  void endYieldStatement(Token yieldToken, Token starToken, Token endToken) {
    debugEvent("YieldStatement");
    push(forest.yieldStatement(yieldToken, starToken, popForValue(), endToken));
  }

  @override
  void beginSwitchBlock(Token token) {
    debugEvent("beginSwitchBlock");
    enterLocalScope("switch block");
    enterSwitchScope();
    enterBreakTarget(token.charOffset);
  }

  @override
  void beginSwitchCase(int labelCount, int expressionCount, Token firstToken) {
    debugEvent("beginSwitchCase");
    int count = labelCount + expressionCount;
    List<Object> labelsAndExpressions =
        const FixedNullableList<Object>().pop(stack, count);
    List<Label> labels = labelCount == 0 ? null : new List<Label>(labelCount);
    List<Expression> expressions =
        new List<Expression>.filled(expressionCount, null, growable: true);
    int labelIndex = 0;
    int expressionIndex = 0;
    if (labelsAndExpressions != null) {
      for (Object labelOrExpression in labelsAndExpressions) {
        if (labelOrExpression is Label) {
          labels[labelIndex++] = labelOrExpression;
        } else {
          expressions[expressionIndex++] = labelOrExpression;
        }
      }
    }
    assert(scope == switchScope);
    if (labels != null) {
      for (Label label in labels) {
        String labelName = label.name;
        if (scope.hasLocalLabel(labelName)) {
          // TODO(ahe): Should validate this is a goto target.
          if (!scope.claimLabel(labelName)) {
            addProblem(
                fasta.templateDuplicateLabelInSwitchStatement
                    .withArguments(labelName),
                label.charOffset,
                labelName.length);
          }
        } else {
          scope.declareLabel(
              labelName, createGotoTarget(firstToken.charOffset));
        }
      }
    }
    push(expressions);
    push(labels ?? NullValue.Labels);
    enterLocalScope("switch case");
  }

  @override
  void endSwitchCase(
      int labelCount,
      int expressionCount,
      Token defaultKeyword,
      Token colonAfterDefault,
      int statementCount,
      Token firstToken,
      Token endToken) {
    debugEvent("SwitchCase");
    // We always create a block here so that we later know that there's always
    // one synthetic block when we finish compiling the switch statement and
    // check this switch case to see if it falls through to the next case.
    Statement block = popBlock(statementCount, firstToken, null);
    exitLocalScope();
    List<Label> labels = pop();
    List<Expression> expressions = pop();
    List<int> expressionOffsets = <int>[];
    for (Expression expression in expressions) {
      expressionOffsets.add(forest.readOffset(expression));
    }
    push(new SwitchCaseJudgment(expressions, expressionOffsets, block,
        isDefault: defaultKeyword != null)
      ..fileOffset = firstToken.charOffset);
    push(labels ?? NullValue.Labels);
  }

  @override
  void endSwitchStatement(Token switchKeyword, Token endToken) {
    debugEvent("SwitchStatement");

    List<SwitchCase> cases = pop();
    JumpTarget target = exitBreakTarget();
    exitSwitchScope();
    exitLocalScope();
    Expression expression = popForValue();
    Statement result = new SwitchStatementJudgment(expression, cases)
      ..fileOffset = switchKeyword.charOffset;
    if (target.hasUsers) {
      result = forest.syntheticLabeledStatement(result);
      target.resolveBreaks(forest, result);
    }
    exitLoopOrSwitch(result);
  }

  @override
  void endSwitchBlock(int caseCount, Token beginToken, Token endToken) {
    debugEvent("SwitchBlock");
    List<SwitchCase> cases =
        new List<SwitchCase>.filled(caseCount, null, growable: true);
    for (int i = caseCount - 1; i >= 0; i--) {
      List<Label> labels = pop();
      SwitchCase current = cases[i] = pop();
      if (labels != null) {
        for (Label label in labels) {
          JumpTarget target = switchScope.lookupLabel(label.name);
          if (target != null) {
            target.resolveGotos(forest, current);
          }
        }
      }
    }
    for (int i = 0; i < caseCount - 1; i++) {
      SwitchCase current = cases[i];
      Block block = current.body;
      // [block] is a synthetic block that is added to handle variable
      // declarations in the switch case.
      TreeNode lastNode =
          block.statements.isEmpty ? null : block.statements.last;
      if (forest.isBlock(lastNode)) {
        // This is a non-synthetic block.
        Block block = lastNode;
        lastNode = block.statements.isEmpty ? null : block.statements.last;
      }
      if (lastNode is ExpressionStatement) {
        ExpressionStatement statement = lastNode;
        lastNode = statement.expression;
      }
      if (lastNode is! BreakStatement &&
          lastNode is! ContinueSwitchStatement &&
          lastNode is! Rethrow &&
          lastNode is! ReturnStatement &&
          !forest.isThrow(lastNode)) {
        block.addStatement(
            new ExpressionStatement(buildFallThroughError(current.fileOffset)));
      }
    }

    push(cases);
  }

  @override
  void handleCaseMatch(Token caseKeyword, Token colon) {
    debugEvent("CaseMatch");
    // Do nothing. Handled by [handleSwitchCase].
  }

  @override
  void handleBreakStatement(
      bool hasTarget, Token breakKeyword, Token endToken) {
    debugEvent("BreakStatement");
    JumpTarget target = breakTarget;
    Identifier identifier;
    String name;
    if (hasTarget) {
      identifier = pop();
      name = identifier.name;
      target = scope.lookupLabel(name);
    }
    if (target == null && name == null) {
      push(problemInLoopOrSwitch = buildProblemStatement(
          fasta.messageBreakOutsideOfLoop, breakKeyword.charOffset));
    } else if (target == null ||
        target is! JumpTarget ||
        !target.isBreakTarget) {
      Token labelToken = breakKeyword.next;
      push(problemInLoopOrSwitch = buildProblemStatement(
          fasta.templateInvalidBreakTarget.withArguments(name),
          labelToken.charOffset,
          length: labelToken.length));
    } else if (target.functionNestingLevel != functionNestingLevel) {
      push(buildProblemTargetOutsideLocalFunction(name, breakKeyword));
    } else {
      Statement statement =
          forest.breakStatement(breakKeyword, identifier, endToken);
      target.addBreak(statement);
      push(statement);
    }
  }

  Statement buildProblemTargetOutsideLocalFunction(String name, Token keyword) {
    Statement problem;
    bool isBreak = optional("break", keyword);
    if (name != null) {
      Template<Message Function(String)> template = isBreak
          ? fasta.templateBreakTargetOutsideFunction
          : fasta.templateContinueTargetOutsideFunction;
      problem = buildProblemStatement(
          template.withArguments(name), offsetForToken(keyword),
          length: lengthOfSpan(keyword, keyword.next));
    } else {
      Message message = isBreak
          ? fasta.messageAnonymousBreakTargetOutsideFunction
          : fasta.messageAnonymousContinueTargetOutsideFunction;
      problem = buildProblemStatement(message, offsetForToken(keyword),
          length: lengthForToken(keyword));
    }
    problemInLoopOrSwitch ??= problem;
    return problem;
  }

  @override
  void handleContinueStatement(
      bool hasTarget, Token continueKeyword, Token endToken) {
    debugEvent("ContinueStatement");
    JumpTarget target = continueTarget;
    Identifier identifier;
    String name;
    if (hasTarget) {
      identifier = pop();
      name = identifier.name;
      Declaration namedTarget = scope.lookupLabel(identifier.name);
      if (namedTarget != null && namedTarget is! JumpTarget) {
        Token labelToken = continueKeyword.next;
        push(problemInLoopOrSwitch = buildProblemStatement(
            fasta.messageContinueLabelNotTarget, labelToken.charOffset,
            length: labelToken.length));
        return;
      }
      target = namedTarget;
      if (target == null) {
        if (switchScope == null) {
          push(buildProblemStatement(
              fasta.templateLabelNotFound.withArguments(name),
              continueKeyword.next.charOffset));
          return;
        }
        switchScope.forwardDeclareLabel(
            identifier.name, target = createGotoTarget(identifier.charOffset));
      }
      if (target.isGotoTarget &&
          target.functionNestingLevel == functionNestingLevel) {
        ContinueSwitchStatement statement = new ContinueSwitchJudgment(null)
          ..fileOffset = continueKeyword.charOffset;
        target.addGoto(statement);
        push(statement);
        return;
      }
    }
    if (target == null) {
      push(problemInLoopOrSwitch = buildProblemStatement(
          fasta.messageContinueWithoutLabelInCase, continueKeyword.charOffset,
          length: continueKeyword.length));
    } else if (!target.isContinueTarget) {
      Token labelToken = continueKeyword.next;
      push(problemInLoopOrSwitch = buildProblemStatement(
          fasta.templateInvalidContinueTarget.withArguments(name),
          labelToken.charOffset,
          length: labelToken.length));
    } else if (target.functionNestingLevel != functionNestingLevel) {
      push(buildProblemTargetOutsideLocalFunction(name, continueKeyword));
    } else {
      Statement statement =
          forest.continueStatement(continueKeyword, identifier, endToken);
      target.addContinue(statement);
      push(statement);
    }
  }

  @override
  void beginTypeVariable(Token token) {
    debugEvent("beginTypeVariable");
    Identifier name = pop();
    List<Expression> annotations = pop();
    KernelTypeVariableBuilder variable = new KernelTypeVariableBuilder(
        name.name, library, name.charOffset, null);
    if (annotations != null) {
      inferAnnotations(annotations);
      for (Expression annotation in annotations) {
        variable.parameter.addAnnotation(annotation);
      }
    }
    push(variable);
  }

  @override
  void handleTypeVariablesDefined(Token token, int count) {
    debugEvent("handleTypeVariablesDefined");
    assert(count > 0);
    List<KernelTypeVariableBuilder> typeVariables =
        const FixedNullableList<KernelTypeVariableBuilder>().pop(stack, count);
    enterFunctionTypeScope(typeVariables);
    push(typeVariables);
  }

  @override
  void endTypeVariable(Token token, int index, Token extendsOrSuper) {
    debugEvent("TypeVariable");
    UnresolvedType<KernelTypeBuilder> bound = pop();
    // Peek to leave type parameters on top of stack.
    List<KernelTypeVariableBuilder> typeVariables = peek();

    KernelTypeVariableBuilder variable = typeVariables[index];
    variable.bound = bound?.builder;
  }

  @override
  void endTypeVariables(Token beginToken, Token endToken) {
    debugEvent("TypeVariables");
    // Peek to leave type parameters on top of stack.
    List<KernelTypeVariableBuilder> typeVariables = peek();

    if (!legacyMode) {
      List<KernelTypeBuilder> calculatedBounds = calculateBounds(
          typeVariables,
          library.loader.target.dynamicType,
          library.loader.target.bottomType,
          library.loader.target.objectClassBuilder);
      for (int i = 0; i < typeVariables.length; ++i) {
        typeVariables[i].defaultType = calculatedBounds[i];
        typeVariables[i].defaultType.resolveIn(scope,
            typeVariables[i].charOffset, typeVariables[i].fileUri, library);
        typeVariables[i].finish(
            library,
            library.loader.target.objectClassBuilder,
            library.loader.target.dynamicType);
      }
    } else {
      for (int i = 0; i < typeVariables.length; ++i) {
        typeVariables[i].defaultType = library.loader.target.dynamicType;
        typeVariables[i].finish(
            library,
            library.loader.target.objectClassBuilder,
            library.loader.target.dynamicType);
      }
    }
  }

  @override
  void handleNoTypeVariables(Token token) {
    debugEvent("NoTypeVariables");
    enterFunctionTypeScope(null);
    push(NullValue.TypeVariables);
  }

  List<TypeParameter> typeVariableBuildersToKernel(
      List<KernelTypeVariableBuilder> typeVariableBuilders) {
    if (typeVariableBuilders == null) return null;
    List<TypeParameter> typeParameters = new List<TypeParameter>.filled(
        typeVariableBuilders.length, null,
        growable: true);
    int i = 0;
    for (KernelTypeVariableBuilder builder in typeVariableBuilders) {
      typeParameters[i++] = builder.target;
    }
    return typeParameters;
  }

  @override
  void handleInvalidStatement(Token token, Message message) {
    Statement statement = pop();
    push(new ExpressionStatement(desugarSyntheticExpression(
        buildProblem(message, statement.fileOffset, noLength))));
  }

  @override
  Expression buildProblem(Message message, int charOffset, int length,
      {List<LocatedMessage> context, bool suppressMessage: false}) {
    if (!suppressMessage) {
      addProblem(message, charOffset, length,
          wasHandled: true, context: context);
    }
    String text = library.loader.target.context
        .format(message.withLocation(uri, charOffset, length), Severity.error);
    return wrapSyntheticExpression(
        new InvalidExpression(text)..fileOffset = charOffset, charOffset);
  }

  @override
  Expression wrapInProblem(Expression expression, Message message, int length,
      {List<LocatedMessage> context}) {
    int charOffset = forest.readOffset(expression);
    Severity severity = message.code.severity;
    if (severity == Severity.error ||
        severity == Severity.errorLegacyWarning && !legacyMode) {
      return wrapInLocatedProblem(
          expression, message.withLocation(uri, charOffset, length),
          context: context);
    } else {
      addProblem(message, charOffset, length, context: context);
      return expression;
    }
  }

  @override
  Expression wrapInLocatedProblem(Expression expression, LocatedMessage message,
      {List<LocatedMessage> context}) {
    // TODO(askesc): Produce explicit error expression wrapping the original.
    // See [issue 29717](https://github.com/dart-lang/sdk/issues/29717)
    int offset = forest.readOffset(expression);
    if (offset == -1) {
      offset = message.charOffset;
    }
    return new Let(
        new VariableDeclaration.forValue(
            desugarSyntheticExpression(buildProblem(
                message.messageObject, message.charOffset, message.length,
                context: context)),
            type: const BottomType())
          ..fileOffset = offset,
        expression);
  }

  Expression buildFallThroughError(int charOffset) {
    addProblem(fasta.messageSwitchCaseFallThrough, charOffset, noLength);

    // TODO(ahe): The following doesn't make sense for the Analyzer. It should
    // be moved to [Forest] or conditional on `forest is Fangorn`.

    // TODO(ahe): Compute a LocatedMessage above instead?
    Location location = messages.getLocationFromUri(uri, charOffset);

    return forest.throwExpression(
        null,
        buildStaticInvocation(
            library.loader.coreTypes.fallThroughErrorUrlAndLineConstructor,
            forest.arguments(<Expression>[
              forest.literalString("${location?.file ?? uri}", null)
                ..fileOffset = charOffset,
              forest.literalInt(location?.line ?? 0, null)
                ..fileOffset = charOffset,
            ], noLocation),
            charOffset: charOffset))
      ..fileOffset = charOffset;
  }

  Expression buildAbstractClassInstantiationError(
      Message message, String className,
      [int charOffset = -1]) {
    addProblemErrorIfConst(message, charOffset, className.length);
    // TODO(ahe): The following doesn't make sense to Analyzer AST.
    Declaration constructor =
        library.loader.getAbstractClassInstantiationError();
    Expression invocation = buildStaticInvocation(
        constructor.target,
        forest.arguments(<Expression>[
          forest.literalString(className, null)..fileOffset = charOffset
        ], noLocation)
          ..fileOffset = charOffset,
        charOffset: charOffset);
    if (invocation is shadow.SyntheticExpressionJudgment) {
      invocation = desugarSyntheticExpression(invocation);
    }
    return forest.throwExpression(null, invocation)..fileOffset = charOffset;
  }

  Statement buildProblemStatement(Message message, int charOffset,
      {List<LocatedMessage> context, int length, bool suppressMessage: false}) {
    length ??= noLength;
    return new ExpressionStatementJudgment(buildProblem(
        message, charOffset, length,
        context: context, suppressMessage: suppressMessage));
  }

  Statement wrapInProblemStatement(Statement statement, Message message) {
    // TODO(askesc): Produce explicit error statement wrapping the original.
    // See [issue 29717](https://github.com/dart-lang/sdk/issues/29717)
    return buildProblemStatement(message, statement.fileOffset);
  }

  @override
  Initializer buildInvalidInitializer(Expression expression,
      [int charOffset = -1]) {
    needsImplicitSuperInitializer = false;
    return new ShadowInvalidInitializer(
        new VariableDeclaration.forValue(expression))
      ..fileOffset = charOffset;
  }

  Initializer buildInvalidSuperInitializer(
      Constructor target, ArgumentsJudgment arguments, Expression expression,
      [int charOffset = -1]) {
    needsImplicitSuperInitializer = false;
    return new InvalidSuperInitializerJudgment(
        target, arguments, new VariableDeclaration.forValue(expression))
      ..fileOffset = charOffset;
  }

  Initializer buildDuplicatedInitializer(Field field, Expression value,
      String name, int offset, int previousInitializerOffset) {
    return new ShadowInvalidFieldInitializer(
        field,
        value,
        new VariableDeclaration.forValue(desugarSyntheticExpression(
            buildProblem(
                fasta.templateFinalInstanceVariableAlreadyInitialized
                    .withArguments(name),
                offset,
                noLength))))
      ..fileOffset = offset;
  }

  /// Parameter [formalType] should only be passed in the special case of
  /// building a field initializer as a desugaring of an initializing formal
  /// parameter.  The spec says the following:
  ///
  /// "If an explicit type is attached to the initializing formal, that is its
  /// static type.  Otherwise, the type of an initializing formal named _id_ is
  /// _Tid_, where _Tid_ is the type of the instance variable named _id_ in the
  /// immediately enclosing class.  It is a static warning if the static type of
  /// _id_ is not a subtype of _Tid_."
  @override
  Initializer buildFieldInitializer(bool isSynthetic, String name,
      int fieldNameOffset, int assignmentOffset, Expression expression,
      {DartType formalType}) {
    Declaration builder =
        classBuilder.scope.local[name] ?? classBuilder.origin.scope.local[name];
    if (builder?.next != null) {
      // Duplicated name, already reported.
      return new LocalInitializer(
          new VariableDeclaration.forValue(
              desugarSyntheticExpression(buildProblem(
                  fasta.templateDuplicatedDeclarationUse.withArguments(name),
                  fieldNameOffset,
                  name.length))
                ..fileOffset = fieldNameOffset)
            ..fileOffset = fieldNameOffset)
        ..fileOffset = fieldNameOffset;
    } else if (builder is KernelFieldBuilder && builder.isInstanceMember) {
      initializedFields ??= <String, int>{};
      if (initializedFields.containsKey(name)) {
        return buildDuplicatedInitializer(builder.field, expression, name,
            assignmentOffset, initializedFields[name]);
      }
      initializedFields[name] = assignmentOffset;
      if (builder.isFinal && builder.hasInitializer) {
        addProblem(
            fasta.templateFinalInstanceVariableAlreadyInitialized
                .withArguments(name),
            assignmentOffset,
            noLength,
            context: [
              fasta.templateFinalInstanceVariableAlreadyInitializedCause
                  .withArguments(name)
                  .withLocation(uri, builder.charOffset, name.length)
            ]);
        Declaration constructor =
            library.loader.getDuplicatedFieldInitializerError();
        Expression invocation = buildStaticInvocation(
            constructor.target,
            forest.arguments(<Expression>[
              forest.literalString(name, null)..fileOffset = assignmentOffset
            ], noLocation)
              ..fileOffset = assignmentOffset,
            charOffset: assignmentOffset);
        if (invocation is shadow.SyntheticExpressionJudgment) {
          invocation = desugarSyntheticExpression(invocation);
        }
        return new ShadowInvalidFieldInitializer(
            builder.field,
            expression,
            new VariableDeclaration.forValue(
                forest.throwExpression(null, invocation)
                  ..fileOffset = assignmentOffset))
          ..fileOffset = assignmentOffset;
      } else {
        if (!legacyMode &&
            formalType != null &&
            !typeEnvironment.isSubtypeOf(formalType, builder.field.type)) {
          library.addProblem(
              fasta.templateInitializingFormalTypeMismatch
                  .withArguments(name, formalType, builder.field.type),
              assignmentOffset,
              noLength,
              uri,
              context: [
                fasta.messageInitializingFormalTypeMismatchField
                    .withLocation(builder.fileUri, builder.charOffset, noLength)
              ]);
        }
        return new ShadowFieldInitializer(builder.field, expression)
          ..fileOffset = assignmentOffset
          ..isSynthetic = isSynthetic;
      }
    } else {
      return buildInvalidInitializer(
          desugarSyntheticExpression(buildProblem(
              fasta.templateInitializerForStaticField.withArguments(name),
              fieldNameOffset,
              name.length)),
          fieldNameOffset);
    }
  }

  @override
  Initializer buildSuperInitializer(
      bool isSynthetic, Constructor constructor, Arguments arguments,
      [int charOffset = -1]) {
    if (member.isConst && !constructor.isConst) {
      return buildInvalidSuperInitializer(
          constructor,
          forest.castArguments(arguments),
          desugarSyntheticExpression(buildProblem(
              fasta.messageConstConstructorWithNonConstSuper,
              charOffset,
              constructor.name.name.length)),
          charOffset);
    }
    needsImplicitSuperInitializer = false;
    return new SuperInitializerJudgment(
        constructor, forest.castArguments(arguments))
      ..fileOffset = charOffset
      ..isSynthetic = isSynthetic;
  }

  @override
  Initializer buildRedirectingInitializer(
      Constructor constructor, Arguments arguments,
      [int charOffset = -1]) {
    if (classBuilder.checkConstructorCyclic(
        member.name, constructor.name.name)) {
      int length = constructor.name.name.length;
      if (length == 0) length = "this".length;
      addProblem(fasta.messageConstructorCyclic, charOffset, length);
      // TODO(askesc): Produce invalid initializer.
    }
    needsImplicitSuperInitializer = false;
    return new RedirectingInitializerJudgment(
        constructor, forest.castArguments(arguments))
      ..fileOffset = charOffset;
  }

  @override
  void handleOperator(Token token) {
    debugEvent("Operator");
    push(new Operator(token, token.charOffset));
  }

  @override
  void handleSymbolVoid(Token token) {
    debugEvent("SymbolVoid");
    push(new Identifier.preserveToken(token));
  }

  @override
  void handleInvalidFunctionBody(Token token) {
    if (member.isNative) {
      push(NullValue.FunctionBody);
    } else {
      push(forest.block(
          token,
          <Statement>[
            buildProblemStatement(
                fasta.templateExpectedFunctionBody.withArguments(token),
                token.charOffset,
                length: token.length)
          ],
          null));
    }
  }

  @override
  UnresolvedType<KernelTypeBuilder> validateTypeUse(
      UnresolvedType<KernelTypeBuilder> unresolved,
      bool nonInstanceAccessIsError) {
    KernelTypeBuilder builder = unresolved.builder;
    if (builder is KernelNamedTypeBuilder &&
        builder.declaration.isTypeVariable) {
      TypeParameter typeParameter = builder.declaration.target;
      bool isConstant = constantContext != ConstantContext.none;
      LocatedMessage message;
      bool suppressMessage = false;
      if (!isInstanceContext && typeParameter.parent is Class) {
        message = fasta.messageTypeVariableInStaticContext.withLocation(
            unresolved.fileUri,
            unresolved.charOffset,
            typeParameter.name.length);
        if (!nonInstanceAccessIsError && !isConstant && legacyMode) {
          // This is a warning in legacy mode.
          addProblem(message.messageObject, message.charOffset, message.length);
          suppressMessage = true;
        }
      } else if (constantContext == ConstantContext.inferred) {
        message = fasta.messageTypeVariableInConstantContext.withLocation(
            unresolved.fileUri,
            unresolved.charOffset,
            typeParameter.name.length);
      } else {
        return unresolved;
      }
      return new UnresolvedType<KernelTypeBuilder>(
          new KernelNamedTypeBuilder(typeParameter.name, null)
            ..bind(new KernelInvalidTypeBuilder(typeParameter.name, message,
                suppressMessage: suppressMessage)),
          unresolved.charOffset,
          unresolved.fileUri);
    }
    return unresolved;
  }

  @override
  Expression evaluateArgumentsBefore(
      Arguments arguments, Expression expression) {
    if (arguments == null) return expression;
    List<Expression> expressions =
        new List<Expression>.from(forest.argumentsPositional(arguments));
    for (NamedExpression named in forest.argumentsNamed(arguments)) {
      expressions.add(named.value);
    }
    for (Expression argument in expressions.reversed) {
      expression = new Let(
          new VariableDeclaration.forValue(argument,
              isFinal: true, type: coreTypes.objectClass.rawType),
          expression);
    }
    return expression;
  }

  @override
  bool isIdentical(Member member) => member == coreTypes.identicalProcedure;

  @override
  Expression buildMethodInvocation(
      Expression receiver, Name name, Arguments arguments, int offset,
      {bool isConstantExpression: false,
      bool isNullAware: false,
      bool isImplicitCall: false,
      bool isSuper: false,
      Member interfaceTarget}) {
    if (constantContext != ConstantContext.none && !isConstantExpression) {
      return buildProblem(
          fasta.templateNotConstantExpression
              .withArguments('Method invocation'),
          offset,
          name.name.length);
    }
    if (isSuper) {
      // We can ignore [isNullAware] on super sends.
      assert(forest.isThisExpression(receiver));
      Member target = lookupInstanceMember(name, isSuper: true);

      if (target == null || (target is Procedure && !target.isAccessor)) {
        if (target == null) {
          warnUnresolvedMethod(name, offset, isSuper: true);
        } else if (!areArgumentsCompatible(target.function, arguments)) {
          target = null;
          addProblemErrorIfConst(
              fasta.templateSuperclassMethodArgumentMismatch
                  .withArguments(name.name),
              offset,
              name.name.length);
        }
        return new SuperMethodInvocationJudgment(
            name, forest.castArguments(arguments),
            interfaceTarget: target)
          ..fileOffset = offset;
      }

      receiver = new SuperPropertyGetJudgment(name, interfaceTarget: target)
        ..fileOffset = offset;
      MethodInvocation node = new MethodInvocationJudgment(
          receiver, callName, forest.castArguments(arguments),
          isImplicitCall: true)
        ..fileOffset = forest.readOffset(arguments);
      return node;
    }

    if (isNullAware) {
      VariableDeclaration variable = new VariableDeclaration.forValue(receiver);
      return new NullAwareMethodInvocationJudgment(
          variable,
          forest.conditionalExpression(
              buildIsNull(new VariableGet(variable), offset, this),
              null,
              forest.literalNull(null)..fileOffset = offset,
              null,
              new MethodInvocation(new VariableGet(variable), name,
                  forest.castArguments(arguments), interfaceTarget)
                ..fileOffset = offset)
            ..fileOffset = offset)
        ..fileOffset = offset;
    } else {
      MethodInvocation node = new MethodInvocationJudgment(
          receiver, name, forest.castArguments(arguments),
          isImplicitCall: isImplicitCall, interfaceTarget: interfaceTarget)
        ..fileOffset = offset;
      return node;
    }
  }

  @override
  void addProblem(Message message, int charOffset, int length,
      {bool wasHandled: false,
      List<LocatedMessage> context,
      Severity severity}) {
    library.addProblem(message, charOffset, length, uri,
        wasHandled: wasHandled, context: context, severity: severity);
  }

  @override
  void addProblemErrorIfConst(Message message, int charOffset, int length,
      {bool wasHandled: false, List<LocatedMessage> context}) {
    // TODO(askesc): Instead of deciding on the severity, this method should
    // take two messages: one to use when a constant expression is
    // required and one to use otherwise.
    Severity severity = message.code.severity;
    if (constantContext != ConstantContext.none) {
      severity = Severity.error;
    }
    addProblem(message, charOffset, length,
        wasHandled: wasHandled, context: context, severity: severity);
  }

  @override
  void reportDuplicatedDeclaration(
      Declaration existing, String name, int charOffset) {
    List<LocatedMessage> context = existing.isSynthetic
        ? null
        : <LocatedMessage>[
            fasta.templateDuplicatedDeclarationCause
                .withArguments(name)
                .withLocation(
                    existing.fileUri, existing.charOffset, name.length)
          ];
    addProblem(fasta.templateDuplicatedDeclaration.withArguments(name),
        charOffset, name.length,
        context: context);
  }

  @override
  void debugEvent(String name) {
    // printEvent('BodyBuilder: $name');
  }

  @override
  StaticGet makeStaticGet(Member readTarget, Token token) {
    return new StaticGet(readTarget)..fileOffset = offsetForToken(token);
  }

  @override
  Expression wrapInDeferredCheck(
      Expression expression, KernelPrefixBuilder prefix, int charOffset) {
    VariableDeclaration check = new VariableDeclaration.forValue(
        forest.checkLibraryIsLoaded(prefix.dependency))
      ..fileOffset = charOffset;
    return new DeferredCheckJudgment(check, expression);
  }

  /// TODO(ahe): This method is temporarily implemented by subclasses. Once type
  /// promotion is independent of shadow nodes, remove this method.
  void enterThenForTypePromotion(Expression condition);

  bool isErroneousNode(TreeNode node) {
    return library.loader.handledErrors.isNotEmpty &&
        forest.isErroneousNode(node);
  }

  @override
  DartType buildDartType(UnresolvedType<KernelTypeBuilder> unresolvedType,
      {bool nonInstanceAccessIsError: false}) {
    if (unresolvedType == null) return null;
    return validateTypeUse(unresolvedType, nonInstanceAccessIsError)
        .builder
        ?.build(library);
  }

  @override
  List<DartType> buildDartTypeArguments(
      List<UnresolvedType<KernelTypeBuilder>> unresolvedTypes) {
    if (unresolvedTypes == null) return <DartType>[];
    List<DartType> types =
        new List<DartType>.filled(unresolvedTypes.length, null, growable: true);
    for (int i = 0; i < types.length; i++) {
      types[i] = buildDartType(unresolvedTypes[i]);
    }
    return types;
  }

  @override
  String constructorNameForDiagnostics(String name,
      {String className, bool isSuper: false}) {
    if (className == null) {
      Class cls = classBuilder.cls;
      if (isSuper) {
        cls = cls.superclass;
        while (cls.isMixinApplication) {
          cls = cls.superclass;
        }
      }
      className = cls.name;
    }
    return name.isEmpty ? className : "$className.$name";
  }

  @override
  Expression wrapSyntheticExpression(Expression desugared, int charOffset) {
    if (legacyMode) return desugared;
    return shadow.SyntheticWrapper.wrapSyntheticExpression(desugared)
      ..fileOffset = charOffset;
  }

  @override
  Expression desugarSyntheticExpression(Expression node) {
    if (legacyMode) return node;
    shadow.SyntheticExpressionJudgment shadowNode = node;
    return shadowNode.desugared;
  }

  @override
  Expression wrapInvalidConstructorInvocation(Expression desugared,
      Member constructor, Arguments arguments, int charOffset) {
    if (legacyMode) return desugared;
    return shadow.SyntheticWrapper.wrapInvalidConstructorInvocation(
        desugared, constructor, arguments)
      ..fileOffset = charOffset;
  }

  @override
  Expression wrapInvalidWrite(
      Expression desugared, Expression expression, int charOffset) {
    if (legacyMode) return desugared;
    return shadow.SyntheticWrapper.wrapInvalidWrite(desugared, expression)
      ..fileOffset = charOffset;
  }

  @override
  Expression wrapUnresolvedTargetInvocation(
      Expression desugared, Arguments arguments, int charOffset) {
    if (legacyMode) return desugared;
    return shadow.SyntheticWrapper.wrapUnresolvedTargetInvocation(
        desugared, arguments)
      ..fileOffset = charOffset;
  }

  @override
  Expression wrapUnresolvedVariableAssignment(
      Expression desugared, bool isCompound, Expression rhs, int charOffset) {
    if (legacyMode) return desugared;
    return shadow.SyntheticWrapper.wrapUnresolvedVariableAssignment(
        desugared, isCompound, rhs)
      ..fileOffset = charOffset;
  }
}

class Operator {
  final Token token;
  String get name => token.stringValue;

  final int charOffset;

  Operator(this.token, this.charOffset);

  String toString() => "operator($name)";
}

class JumpTarget extends Declaration {
  final List<Statement> users = <Statement>[];

  final JumpTargetKind kind;

  final int functionNestingLevel;

  @override
  final MemberBuilder parent;

  @override
  final int charOffset;

  JumpTarget(
      this.kind, this.functionNestingLevel, this.parent, this.charOffset);

  @override
  Uri get fileUri => parent.fileUri;

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

  void resolveBreaks(Forest forest, Statement target) {
    assert(isBreakTarget);
    for (BreakStatement user in users) {
      user.target = target;
    }
    users.clear();
  }

  void resolveContinues(Forest forest, Statement target) {
    assert(isContinueTarget);
    for (BreakStatement user in users) {
      user.target = target;
    }
    users.clear();
  }

  void resolveGotos(Forest forest, SwitchCase target) {
    assert(isGotoTarget);
    for (ContinueSwitchStatement user in users) {
      user.target = target;
    }
    users.clear();
  }

  @override
  String get fullNameForErrors => "<jump-target>";
}

class LabelTarget extends Declaration implements JumpTarget {
  @override
  final MemberBuilder parent;

  final JumpTarget breakTarget;

  final JumpTarget continueTarget;

  final int functionNestingLevel;

  @override
  final int charOffset;

  LabelTarget(this.parent, this.functionNestingLevel, this.charOffset)
      : breakTarget = new JumpTarget(
            JumpTargetKind.Break, functionNestingLevel, parent, charOffset),
        continueTarget = new JumpTarget(
            JumpTargetKind.Continue, functionNestingLevel, parent, charOffset);

  @override
  Uri get fileUri => parent.fileUri;

  bool get hasUsers => breakTarget.hasUsers || continueTarget.hasUsers;

  List<Statement> get users => unsupported("users", charOffset, fileUri);

  JumpTargetKind get kind => unsupported("kind", charOffset, fileUri);

  bool get isBreakTarget => true;

  bool get isContinueTarget => true;

  bool get isGotoTarget => false;

  void addBreak(Statement statement) {
    breakTarget.addBreak(statement);
  }

  void addContinue(Statement statement) {
    continueTarget.addContinue(statement);
  }

  void addGoto(Statement statement) {
    unsupported("addGoto", charOffset, fileUri);
  }

  void resolveBreaks(Forest forest, Statement target) {
    breakTarget.resolveBreaks(forest, target);
  }

  void resolveContinues(Forest forest, Statement target) {
    continueTarget.resolveContinues(forest, target);
  }

  void resolveGotos(Forest forest, SwitchCase target) {
    unsupported("resolveGotos", charOffset, fileUri);
  }

  @override
  String get fullNameForErrors => "<label-target>";
}

class FormalParameters {
  final List<KernelFormalParameterBuilder> parameters;
  final int charOffset;
  final int length;
  final Uri uri;

  FormalParameters(this.parameters, this.charOffset, this.length, this.uri) {
    if (parameters?.isEmpty ?? false) {
      throw "Empty parameters should be null";
    }
  }

  FunctionNode buildFunctionNode(
      KernelLibraryBuilder library,
      UnresolvedType<KernelTypeBuilder> returnType,
      List<KernelTypeVariableBuilder> typeParameters,
      AsyncMarker asyncModifier,
      Statement body,
      int fileEndOffset) {
    FunctionType type =
        toFunctionType(returnType, typeParameters).builder.build(library);
    List<VariableDeclaration> positionalParameters = <VariableDeclaration>[];
    List<VariableDeclaration> namedParameters = <VariableDeclaration>[];
    if (parameters != null) {
      for (KernelFormalParameterBuilder parameter in parameters) {
        if (parameter.isNamed) {
          namedParameters.add(parameter.target);
        } else {
          positionalParameters.add(parameter.target);
        }
      }
      namedParameters.sort((VariableDeclaration a, VariableDeclaration b) {
        return a.name.compareTo(b.name);
      });
    }
    return new FunctionNodeJudgment(body,
        typeParameters: type.typeParameters,
        positionalParameters: positionalParameters,
        namedParameters: namedParameters,
        requiredParameterCount: type.requiredParameterCount,
        returnType: type.returnType,
        asyncMarker: asyncModifier)
      ..fileOffset = charOffset
      ..fileEndOffset = fileEndOffset;
  }

  UnresolvedType<KernelTypeBuilder> toFunctionType(
      UnresolvedType<KernelTypeBuilder> returnType,
      [List<KernelTypeVariableBuilder> typeParameters]) {
    return new UnresolvedType(
        new KernelFunctionTypeBuilder(
            returnType?.builder, typeParameters, parameters),
        charOffset,
        uri);
  }

  Scope computeFormalParameterScope(
      Scope parent, Declaration declaration, ExpressionGeneratorHelper helper) {
    if (parameters == null) return parent;
    assert(parameters.isNotEmpty);
    Map<String, Declaration> local = <String, Declaration>{};

    for (KernelFormalParameterBuilder parameter in parameters) {
      Declaration existing = local[parameter.name];
      if (existing != null) {
        helper.reportDuplicatedDeclaration(
            existing, parameter.name, parameter.charOffset);
      } else {
        local[parameter.name] = parameter;
      }
    }
    return new Scope(local, null, parent, "formals", isModifiable: false);
  }

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
    body.statements.insert(0, statement);
    statement.parent = body;
    return body;
  } else {
    return new BlockJudgment(<Statement>[statement, body])
      ..fileOffset = statement.fileOffset;
  }
}

String debugName(String className, String name, [String prefix]) {
  String result = name.isEmpty ? className : "$className.$name";
  return prefix == null ? result : "$prefix.result";
}

String getNodeName(Object node) {
  if (node is Identifier) {
    return node.name;
  } else if (node is Declaration) {
    return node.fullNameForErrors;
  } else if (node is ThisAccessGenerator) {
    return node.isSuper ? "super" : "this";
  } else if (node is Generator) {
    return node.plainNameForRead;
  } else if (node is QualifiedName) {
    return flattenName(node, node.charOffset, null);
  } else {
    return unhandled("${node.runtimeType}", "getNodeName", -1, null);
  }
}

AsyncMarker asyncMarkerFromTokens(Token asyncToken, Token starToken) {
  if (asyncToken == null || identical(asyncToken.stringValue, "sync")) {
    if (starToken == null) {
      return AsyncMarker.Sync;
    } else {
      assert(identical(starToken.stringValue, "*"));
      return AsyncMarker.SyncStar;
    }
  } else if (identical(asyncToken.stringValue, "async")) {
    if (starToken == null) {
      return AsyncMarker.Async;
    } else {
      assert(identical(starToken.stringValue, "*"));
      return AsyncMarker.AsyncStar;
    }
  } else {
    return unhandled(asyncToken.lexeme, "asyncMarkerFromTokens",
        asyncToken.charOffset, null);
  }
}

/// A data holder used to hold the information about a label that is pushed on
/// the stack.
class Label {
  String name;
  int charOffset;

  Label(this.name, this.charOffset);

  String toString() => "label($name)";
}
