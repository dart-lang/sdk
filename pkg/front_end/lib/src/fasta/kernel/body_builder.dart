// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.body_builder;

import 'dart:core' hide MapEntry;

import '../constant_context.dart' show ConstantContext;

import '../fasta_codes.dart' as fasta;

import '../fasta_codes.dart' show LocatedMessage, Message, noLength, Template;

import 'forest.dart' show Forest;

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

import '../parser/class_member_parser.dart' show ClassMemberParser;

import '../parser/formal_parameter_kind.dart'
    show isOptionalPositionalFormalParameterKind;

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

import '../scanner/token.dart' show isBinaryOperator, isMinusOperator;

import '../scope.dart' show ProblemBuilder;

import '../source/outline_builder.dart' show OutlineBuilder;

import '../source/scope_listener.dart'
    show JumpTargetKind, NullValue, ScopeListener;

import '../type_inference/type_inferrer.dart' show TypeInferrer;

import '../type_inference/type_promotion.dart'
    show TypePromoter, TypePromotionFact, TypePromotionScope;

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
        LargeIntAccessGenerator,
        LoadLibraryGenerator,
        ParenthesizedExpressionGenerator,
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

import 'redirecting_factory_body.dart'
    show
        RedirectingFactoryBody,
        RedirectionTarget,
        getRedirectingFactoryBody,
        getRedirectionTarget;

import 'kernel_api.dart';

import 'kernel_ast_api.dart';

import 'kernel_builder.dart';

import 'kernel_factory.dart' show KernelFactory;

import 'type_algorithms.dart' show calculateBounds;

// TODO(ahe): Remove this and ensure all nodes have a location.
const noLocation = null;

abstract class BodyBuilder extends ScopeListener<JumpTarget>
    implements ExpressionGeneratorHelper {
  // TODO(ahe): Rename [library] to 'part'.
  @override
  final KernelLibraryBuilder library;

  final ModifierBuilder member;

  final KernelClassBuilder classBuilder;

  final ClassHierarchy hierarchy;

  final CoreTypes coreTypes;

  final bool isInstanceMember;

  final Scope enclosingScope;

  final bool enableNative;

  final bool stringExpectedAfterNative;

  final bool errorOnUnexactWebIntLiterals;

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

  /// The factory used to construct body expressions, statements, and
  /// initializers.
  ///
  /// TODO(paulberry): when the analyzer's diet parser is in use, this should
  /// point to the analyzer's factory.  Note that type arguments will have to be
  /// added to BodyBuilder to make this happen.
  final KernelFactory factory = new KernelFactory();

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

  bool inCatchClause = false;

  bool inCatchBlock = false;

  int functionNestingLevel = 0;

  Statement compileTimeErrorInTry;

  Statement compileTimeErrorInLoopOrSwitch;

  Scope switchScope;

  CloneVisitor cloner;

  ConstantContext constantContext = ConstantContext.none;

  DartType currentLocalVariableType;

  // Using non-null value to initialize this field based on performance advice
  // from VM engineers. TODO(ahe): Does this still apply?
  int currentLocalVariableModifiers = -1;

  /// If non-null, records instance fields which have already been initialized
  /// and where that was.
  Map<String, int> initializedFields;

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
        errorOnUnexactWebIntLiterals =
            library.loader.target.backendTarget.errorOnUnexactWebIntLiterals,
        ignoreMainInGetMainClosure = library.uri.scheme == 'dart' &&
            (library.uri.path == "_builtin" || library.uri.path == "ui"),
        needsImplicitSuperInitializer =
            coreTypes?.objectClass != classBuilder?.cls,
        typePromoter = _typeInferrer?.typePromoter,
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

  @override
  void push(Object node) {
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
      return new SyntheticExpressionJudgment(buildCompileTimeError(
          fasta.messageSuperAsExpression, node.fileOffset, noLength));
    } else if (node is ProblemBuilder) {
      return buildProblemExpression(node, -1, noLength);
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
    List<Statement> statements =
        new List<Statement>.filled(count, null, growable: true);
    popList(count, statements);
    return forest.block(openBrace, statements, closeBrace);
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
                wrapInCompileTimeErrorStatement(statement,
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
      variable.initializer = new SyntheticExpressionJudgment(
          buildCompileTimeError(message, offset, name.length, context: context))
        ..parent = variable;
    } else {
      variable.initializer = wrapInLocatedCompileTimeError(
          variable.initializer, message.withLocation(uri, offset, name.length),
          context: context)
        ..parent = variable;
    }
  }

  void declareVariable(Object variable, Scope scope) {
    String name = forest.getVariableDeclarationName(variable);
    Declaration existing = scope.local[name];
    if (existing != null) {
      // This reports an error for duplicated declarations in the same scope:
      // `{ var x; var x; }`
      wrapVariableInitializerInError(
          variable, fasta.templateDuplicatedName, <LocatedMessage>[
        fasta.templateDuplicatedNameCause
            .withArguments(name)
            .withLocation(uri, existing.charOffset, name.length)
      ]);
      return;
    }
    LocatedMessage context = scope.declare(
        forest.getVariableDeclarationName(variable),
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

  @override
  void beginMetadata(Token token) {
    debugEvent("beginMetadata");
    super.push(constantContext);
    constantContext = ConstantContext.inferred;
  }

  @override
  void endMetadata(Token beginToken, Token periodBeforeName, Token endToken) {
    debugEvent("Metadata");
    Object arguments = pop();
    pushQualifiedReference(beginToken.next, periodBeforeName);
    if (arguments != null) {
      push(arguments);
      buildConstructorReferenceInvocation(
          beginToken.next, beginToken.offset, Constness.explicitConst);
      push(popForValue());
    } else {
      String name = pop();
      pop(); // Type arguments (ignored, already reported by parser).
      Object expression = pop();
      if (expression is Identifier) {
        Identifier identifier = expression;
        expression = new UnresolvedNameGenerator(
            this, identifier.token, new Name(identifier.name, library.library));
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
        push(wrapInCompileTimeError(
            toValue(expression), fasta.messageExpressionNotMetadata));
      } else {
        push(toValue(expression));
      }
      constantContext = savedConstantContext;
    }
  }

  @override
  void endMetadataStar(int count) {
    debugEvent("MetadataStar");
    push(popList(
            count, new List<Expression>.filled(count, null, growable: true)) ??
        NullValue.Metadata);
  }

  @override
  void endTopLevelFields(Token staticToken, Token covariantToken,
      Token varFinalOrConst, int count, Token beginToken, Token endToken) {
    debugEvent("TopLevelFields");
    push(count);
  }

  @override
  void endFields(Token staticToken, Token covariantToken, Token varFinalOrConst,
      int count, Token beginToken, Token endToken) {
    debugEvent("Fields");
    push(count);
  }

  @override
  void finishFields() {
    debugEvent("finishFields");
    int count = pop();
    List<FieldBuilder<Object>> fields = <FieldBuilder<Object>>[];
    for (int i = 0; i < count; i++) {
      Expression initializer = pop();
      Identifier identifier = pop();
      String name = identifier.name;
      FieldBuilder<Object> field;
      if (classBuilder != null) {
        field = classBuilder[name];
      } else {
        field = library[name];
      }
      fields.add(field);
      if (initializer != null) {
        if (field.next != null) {
          // TODO(ahe): This can happen, for example, if a final field is
          // combined with a setter.
          unhandled("field with more than one declaration", field.name,
              field.charOffset, field.fileUri);
        }
        field.initializer = initializer;
        _typeInferrer.inferFieldInitializer(
            this,
            factory,
            field.hasTypeInferredFromInitializer ? null : field.builtType,
            initializer);
      }
    }
    pop(); // Type.
    List<Object> annotations = pop();
    if (annotations != null) {
      _typeInferrer.inferMetadata(this, factory, annotations);
      Field field = fields.first.target;
      // The first (and often only field) will not get a clone.
      annotations.forEach((annotation) => field.addAnnotation(annotation));
      for (int i = 1; i < fields.length; i++) {
        // We have to clone the annotations on the remaining fields.
        field = fields[i].target;
        cloner ??= new CloneVisitor();
        for (Expression annotation in annotations) {
          field.addAnnotation(cloner.clone(annotation));
        }
      }
    }
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
      if (member.isConst &&
          (classBuilder.cls.superclass?.isMixinApplication ?? false)) {
        deprecated_addCompileTimeError(member.charOffset,
            "Can't extend a mixin application and be 'const'.");
      }
      if (member.formals != null) {
        for (KernelFormalParameterBuilder formal in member.formals) {
          if (formal.hasThis) {
            Initializer initializer;
            if (member.isExternal) {
              initializer = buildInvalidInitializer(
                  deprecated_buildCompileTimeError(
                      "An external constructor can't initialize fields.",
                      formal.charOffset),
                  formal.charOffset);
            } else {
              initializer = buildFieldInitializer(true, formal.name,
                  formal.charOffset, new VariableGet(formal.declaration),
                  formalType: formal.declaration.type);
            }
            member.addInitializer(initializer, _typeInferrer);
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
  }

  @override
  void endInitializer(Token token) {
    debugEvent("endInitializer");
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
      if (node is! Throw) {
        value =
            wrapInCompileTimeError(value, fasta.messageExpectedAnInitializer);
      }
      initializer = buildInvalidInitializer(node, token.charOffset);
    }
    _typeInferrer.inferInitializer(this, factory, initializer);
    if (member is KernelConstructorBuilder && !member.isExternal) {
      member.addInitializer(initializer, _typeInferrer);
    } else {
      deprecated_addCompileTimeError(
          token.charOffset, "Can't have initializers: ${member.name}");
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
  void finishFunction(
      List<Object> annotations,
      FormalParameters<Expression, Statement, Arguments> formals,
      AsyncMarker asyncModifier,
      Statement body) {
    debugEvent("finishFunction");
    typePromoter.finished();

    KernelFunctionBuilder builder = member;
    if (formals?.optional != null) {
      Iterator<FormalParameterBuilder<TypeBuilder>> formalBuilders =
          builder.formals.skip(formals.required.length).iterator;
      for (VariableDeclaration parameter in formals.optional.formals) {
        bool hasMore = formalBuilders.moveNext();
        assert(hasMore);
        VariableDeclaration realParameter = formalBuilders.current.target;
        Expression initializer = parameter.initializer ?? forest.literalNull(
            // TODO(ahe): Should store: realParameter.fileOffset
            // https://github.com/dart-lang/sdk/issues/32289
            null);
        realParameter.initializer = initializer..parent = realParameter;
        _typeInferrer.inferParameterInitializer(
            this, factory, initializer, realParameter.type);
      }
    }

    _typeInferrer.inferFunctionBody(
        this, factory, _computeReturnTypeContext(member), asyncModifier, body);
    if (builder.kind == ProcedureKind.Setter) {
      bool oneParameter = formals != null &&
          formals.required.length == 1 &&
          (formals.optional == null || formals.optional.formals.length == 0);
      if (!oneParameter) {
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
        body = wrapInCompileTimeErrorStatement(
            body, fasta.messageSetterWithWrongNumberOfFormals);
      }
    }
    // No-such-method forwarders get their bodies injected during outline
    // buliding, so we should skip them here.
    bool isNoSuchMethodForwarder = (builder.function.parent is Procedure &&
        (builder.function.parent as Procedure).isNoSuchMethodForwarder);
    if (!builder.isExternal && !isNoSuchMethodForwarder) {
      builder.body = body;
    } else {
      if (body != null) {
        builder.body = wrapInCompileTimeErrorStatement(
            body, fasta.messageExternalMethodWithBody);
      }
    }
    Member target = builder.target;
    _typeInferrer.inferMetadata(this, factory, annotations);
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
  }

  @override
  List<Expression> finishMetadata(TreeNode parent) {
    List<Expression> expressions = pop();
    _typeInferrer.inferMetadata(this, factory, expressions);
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
    }
    return expressions;
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

    enterLocalScope(
        null,
        new FormalParameters<Expression, Statement, Arguments>(
                parameters.positionalParameters, null, -1)
            .computeFormalParameterScope(scope, member, this));

    token = parser.parseExpression(parser.syntheticPreviousToken(token));

    Expression expression = popForValue();
    Token eof = token.next;

    if (!eof.isEof) {
      expression = wrapInLocatedCompileTimeError(
          expression,
          fasta.messageExpectedOneExpression
              .withLocation(uri, eof.charOffset, eof.length));
    }

    ReturnJudgment fakeReturn = new ReturnJudgment(null, null, expression);

    _typeInferrer.inferFunctionBody(
        this, factory, const DynamicType(), AsyncMarker.Sync, fakeReturn);

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
          deprecated_buildCompileTimeError(
              "A constructor can't be '${asyncModifier}'.", offset),
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
        String message = superTarget == null
            ? "'$superclass' doesn't have an unnamed constructor."
            : "The unnamed constructor in '$superclass' requires arguments.";
        initializer = buildInvalidInitializer(
            deprecated_buildCompileTimeError(message, builder.charOffset),
            builder.charOffset);
      } else {
        initializer = buildSuperInitializer(
            true, superTarget, arguments, builder.charOffset);
      }
      constructor.initializers.add(initializer);
    }
    setParents(constructor.initializers, constructor);
    if (constructor.function.body == null) {
      /// >If a generative constructor c is not a redirecting constructor
      /// >and no body is provided, then c implicitly has an empty body {}.
      /// We use an empty statement instead.
      constructor.function.body = new EmptyStatement();
      constructor.function.body.parent = constructor.function;
    }
  }

  @override
  void endExpressionStatement(Token token) {
    debugEvent("ExpressionStatement");
    push(forest.expressionStatement(popForEffect(), token));
  }

  @override
  void endArguments(int count, Token beginToken, Token endToken) {
    debugEvent("Arguments");
    List<Object> arguments =
        new List<Object>.filled(count, null, growable: true);
    popList(count, arguments);
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
              deprecated_buildCompileTimeError(
                  "Expected named argument.", forest.readOffset(argument)))
            ..fileOffset = beginToken.charOffset;
        }
      }
    }
    if (firstNamedArgumentIndex < arguments.length) {
      List<Expression> positional = new List<Expression>.from(
          arguments.getRange(0, firstNamedArgumentIndex));
      List<NamedExpression> named = new List<NamedExpression>.from(
          arguments.getRange(firstNamedArgumentIndex, arguments.length));
      if (named.length == 2) {
        if (named[0].name == named[1].name) {
          named = <NamedExpression>[
            new NamedExpression(
                named[1].name,
                deprecated_buildCompileTimeError(
                    "Duplicated named argument '${named[1].name}'.",
                    named[1].fileOffset))
          ];
        }
      } else if (named.length > 2) {
        Map<String, NamedExpression> seenNames = <String, NamedExpression>{};
        bool hasProblem = false;
        for (NamedExpression expression in named) {
          if (seenNames.containsKey(expression.name)) {
            hasProblem = true;
            NamedExpression prevNamedExpression = seenNames[expression.name];
            prevNamedExpression.value = deprecated_buildCompileTimeError(
                "Duplicated named argument '${expression.name}'.",
                expression.fileOffset)
              ..parent = prevNamedExpression;
          } else {
            seenNames[expression.name] = expression;
          }
        }
        if (hasProblem) {
          named = new List<NamedExpression>.from(seenNames.values);
        }
      }
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
    push(new ParenthesizedExpressionGenerator(
        this, token.endGroup, popForValue()));
  }

  @override
  void handleSend(Token beginToken, Token endToken) {
    debugEvent("Send");
    Arguments arguments = pop();
    List<DartType> typeArguments = pop();
    Object receiver = pop();
    if (arguments != null && typeArguments != null) {
      assert(forest.argumentsTypeArguments(arguments).isEmpty);
      forest.argumentsSetTypeArguments(arguments, typeArguments);
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
          expression, functionNestingLevel);
      push(new CascadeJudgment(variable));
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
      typePromoter.enterLogicalExpression(lhs, token.stringValue);
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
      return deprecated_buildCompileTimeError(
          "Not an operator: '$operator'.", token.charOffset);
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
    typePromoter.exitLogicalExpression(argument, logicalExpression);
    push(logicalExpression);
  }

  /// Handle `a ?? b`.
  void doIfNull(Token token) {
    Expression b = popForValue();
    Expression a = popForValue();
    VariableDeclaration variable = new VariableDeclaration.forValue(a);
    push(new IfNullJudgment(
        variable,
        token,
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
      Message message = fasta.templateExpectedIdentifier.withArguments(token);
      push(new SyntheticExpressionJudgment(buildCompileTimeError(
          message, offsetForToken(token), lengthForToken(token))));
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
      Message message = fasta.templateExpectedIdentifier.withArguments(token);
      push(new SyntheticExpressionJudgment(buildCompileTimeError(
          message, offsetForToken(token), lengthForToken(token))));
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
      LocatedMessage argMessage}) {
    Message message;
    Name kernelName = new Name(name, library.library);
    List<LocatedMessage> context;
    if (candidate != null) {
      Uri uri = candidate.location.file;
      int offset = candidate.fileOffset;
      Message message;
      int length = noLength;
      if (offset == -1 && candidate is Constructor) {
        offset = candidate.enclosingClass.fileOffset;
        message = fasta.templateCandidateFoundIsDefaultConstructor
            .withArguments(candidate.enclosingClass.name);
      } else {
        length = name.length;
        message = fasta.messageCandidateFound;
      }
      context = [message.withLocation(uri, offset, length)];
    }

    if (isGetter) {
      message = warnUnresolvedGet(kernelName, charOffset,
          isSuper: isSuper,
          reportWarning: constantContext == ConstantContext.none,
          context: context);
    } else if (isSetter) {
      message = warnUnresolvedSet(kernelName, charOffset,
          isSuper: isSuper,
          reportWarning: constantContext == ConstantContext.none,
          context: context);
    } else {
      if (argMessage != null) {
        message = argMessage.messageObject;
        charOffset = argMessage.charOffset;
        addProblemErrorIfConst(message, charOffset, argMessage.length,
            context: context);
      } else {
        message = warnUnresolvedMethod(kernelName, charOffset,
            isSuper: isSuper,
            reportWarning: constantContext == ConstantContext.none,
            context: context);
      }
    }
    if (constantContext != ConstantContext.none) {
      // TODO(ahe): Use [error] below instead of building a compile-time error,
      // should be:
      //    return library.loader.throwCompileConstantError(error, charOffset);
      return buildCompileTimeError(message, charOffset, noLength,
          context: context);
    } else {
      Expression error = library.loader.instantiateNoSuchMethodError(
          receiver, name, forest.castArguments(arguments), charOffset,
          isMethod: !isGetter && !isSetter,
          isGetter: isGetter,
          isSetter: isSetter,
          isStatic: isStatic,
          isTopLevel: !isStatic && !isSuper);
      return new Throw(error);
    }
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
        fasta.templateTypeArgumentMismatch.withArguments(name, expected),
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
    if (isSuper &&
        target == null &&
        library.loader.target.backendTarget.enableSuperMixins &&
        classBuilder.isAbstract) {
      target = hierarchy.getInterfaceMember(cls, name, setter: isSetter);
    }
    return target;
  }

  @override
  Constructor lookupConstructor(Name name, {bool isSuper}) {
    Class cls = classBuilder.cls;
    if (isSuper) {
      cls = cls.superclass;
      while (cls.isMixinApplication) {
        cls = cls.superclass;
      }
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
        while (builder?.isMixinApplication ?? false) {
          builder = getSuperclass(builder)?.origin;
        }
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
        constantContext =
            member.isConst ? ConstantContext.inferred : ConstantContext.none;
      }
    } else if (constantContext != ConstantContext.none &&
        !context.allowedInConstantExpression) {
      deprecated_addCompileTimeError(
          token.charOffset, "Not a constant expression: $context");
    }
    push(new Identifier(token));
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
    if (declaration != null && member.isField && declaration.isInstanceMember) {
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
      if (constantContext != ConstantContext.none &&
          declaration.isTypeVariable &&
          !member.isConstructor) {
        deprecated_addCompileTimeError(
            charOffset, "Not a constant expression.");
      }
      return new TypeUseGenerator(this, token, declaration, name);
    } else if (declaration.isLocal) {
      if (constantContext != ConstantContext.none &&
          !declaration.isConst &&
          !member.isConstructor) {
        deprecated_addCompileTimeError(
            charOffset, "Not a constant expression.");
      }
      // An initializing formal parameter might be final without its
      // VariableDeclaration being final. See
      // [ProcedureBuilder.computeFormalParameterInitializerScope]. If that
      // wasn't the case, we could always use [VariableUseGenerator].
      if (declaration.isFinal) {
        Object fact = typePromoter.getFactForAccess(
            declaration.target, functionNestingLevel);
        Object scope = typePromoter.currentScope;
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
        deprecated_addCompileTimeError(
            charOffset, "Not a constant expression.");
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
      _typeInferrer.storePrefix(token, declaration);
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
          deprecated_addCompileTimeError(
              charOffset, "Not a constant expression.");
        }
      }
      return generator;
    }
  }

  @override
  void handleQualified(Token period) {
    debugEvent("Qualified");
    Identifier name = pop();
    Object receiver = pop();
    push([receiver, name]);
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
      Object count = 1 + interpolationCount * 2;
      List<Object> parts =
          popList(count, new List<Object>.filled(count, null, growable: true));
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
        String value = unescapeLastStringPart(last.lexeme, quote, last, this);
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
    int value = int.parse(token.lexeme, onError: (_) => null);
    if (value == null) {
      push(new LargeIntAccessGenerator(this, token));
    } else {
      if (errorOnUnexactWebIntLiterals) {
        checkWebIntLiteralsErrorIfUnexact(value, token);
      }
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
      push(deprecated_buildCompileTimeErrorStatement(
          "Can't return from a constructor.", beginToken.charOffset));
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
    typePromoter.enterElse();
    super.endThenStatement(token);
  }

  @override
  void endIfStatement(Token ifToken, Token elseToken) {
    Statement elsePart = popStatementIfNotNull(elseToken);
    Statement thenPart = popStatement();
    Expression condition = pop();
    typePromoter.exitConditional();
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
        initializer = deprecated_buildCompileTimeError(
            "A 'const' variable must be initialized.", token.charOffset);
      } else if (isFinal) {
        initializer = deprecated_buildCompileTimeError(
            "A 'final' variable must be initialized.", token.charOffset);
      }
    }
    pushNewLocalVariable(initializer);
  }

  void pushNewLocalVariable(Expression initializer, {Token equalsToken}) {
    Identifier identifier = pop();
    assert(currentLocalVariableModifiers != -1);
    bool isConst = (currentLocalVariableModifiers & constMask) != 0;
    bool isFinal = (currentLocalVariableModifiers & finalMask) != 0;
    assert(isConst == (constantContext == ConstantContext.inferred));
    push(new VariableDeclarationJudgment(identifier.name, functionNestingLevel,
        initializer: initializer,
        type: currentLocalVariableType,
        isFinal: isFinal,
        isConst: isConst)
      ..fileOffset = offsetForToken(identifier.token)
      ..fileEqualsOffset = offsetForToken(equalsToken));
  }

  @override
  void endFieldInitializer(Token assignmentOperator, Token token) {
    debugEvent("FieldInitializer");
    assert(assignmentOperator.stringValue == "=");
    push(popForValue());
  }

  @override
  void handleNoFieldInitializer(Token token) {
    debugEvent("NoFieldInitializer");
    if (constantContext != ConstantContext.none) {
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
    VariableDeclaration variable = pop();
    variable.fileOffset = nameToken.charOffset;
    push(variable);
    declareVariable(variable, scope);
  }

  @override
  void beginVariablesDeclaration(Token token, Token varFinalOrConst) {
    debugEvent("beginVariablesDeclaration");
    DartType type = pop();
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
      VariableDeclaration variable = pop();
      constantContext = pop();
      currentLocalVariableType = pop();
      currentLocalVariableModifiers = pop();
      List<Expression> annotations = pop();
      if (annotations != null) {
        for (Expression annotation in annotations) {
          variable.addAnnotation(annotation);
        }
      }
      push(variable);
    } else {
      List<VariableDeclaration> variables = popList(count,
          new List<VariableDeclaration>.filled(count, null, growable: true));
      constantContext = pop();
      currentLocalVariableType = pop();
      currentLocalVariableModifiers = pop();
      List<Expression> annotations = pop();
      if (annotations != null) {
        for (VariableDeclaration variable in variables) {
          for (Expression annotation in annotations) {
            variable.addAnnotation(annotation);
          }
        }
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
      push(new SyntheticExpressionJudgment(buildCompileTimeError(
          fasta.messageNotAnLvalue,
          offsetForToken(token),
          lengthForToken(token))));
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
    if (compileTimeErrorInLoopOrSwitch != null) {
      push(compileTimeErrorInLoopOrSwitch);
      compileTimeErrorInLoopOrSwitch = null;
    } else {
      push(statement);
    }
  }

  List<VariableDeclaration> buildForInitVariableDeclarations(
      variableOrExpression) {
    if (variableOrExpression is VariableDeclaration) {
      return <VariableDeclaration>[variableOrExpression];
    } else if (forest.isVariablesDeclaration(variableOrExpression)) {
      return forest
          .variablesDeclarationExtractDeclarations(variableOrExpression);
    } else if (variableOrExpression is List<Object>) {
      List<VariableDeclaration> variables = <VariableDeclaration>[];
      for (Object v in variableOrExpression) {
        variables.addAll(buildForInitVariableDeclarations(v));
      }
      return variables;
    } else if (variableOrExpression == null) {
      return <VariableDeclaration>[];
    }
    return null;
  }

  List<ExpressionJudgment> buildForInitExpressions(variableOrExpression) {
    if (variableOrExpression is ExpressionJudgment) {
      return <ExpressionJudgment>[variableOrExpression];
    } else if (variableOrExpression is ExpressionStatementJudgment) {
      return <ExpressionJudgment>[variableOrExpression.expression];
    }
    return null;
  }

  @override
  void endForStatement(Token forKeyword, Token leftParen, Token leftSeparator,
      int updateExpressionCount, Token endToken) {
    debugEvent("ForStatement");
    Statement body = popStatement();
    List<Expression> updates = popListForEffect(updateExpressionCount);
    Statement conditionStatement = popStatement();
    Object variableOrExpression = pop();

    variableOrExpression = variableOrExpression is Generator
        ? variableOrExpression.buildForEffect()
        : variableOrExpression;
    List<ExpressionJudgment> initializers =
        buildForInitExpressions(variableOrExpression);
    List<VariableDeclaration> variableList = initializers == null
        ? buildForInitVariableDeclarations(variableOrExpression)
        : null;

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
        variableList,
        initializers,
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
    List<Expression> expressions = popListForValue(count);
    Object typeArguments = pop();
    DartType typeArgument;
    if (typeArguments != null) {
      if (forest.getTypeCount(typeArguments) > 1) {
        addProblem(
            fasta.messageListLiteralTooManyTypeArguments,
            offsetForToken(leftBracket),
            lengthOfSpan(leftBracket, leftBracket.endGroup));
      } else {
        typeArgument = forest.getTypeAt(typeArguments, 0);
        if (library.loader.target.strongMode) {
          typeArgument =
              instantiateToBounds(typeArgument, coreTypes.objectClass);
        }
      }
    }
    push(forest.literalList(
        constKeyword,
        constKeyword != null || constantContext == ConstantContext.inferred,
        typeArgument,
        typeArguments,
        leftBracket,
        expressions,
        rightBracket));
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

  @override
  void handleLiteralMap(
      int count, Token leftBrace, Token constKeyword, Token rightBrace) {
    debugEvent("LiteralMap");
    List<Object> entries = forest.mapEntryList(count);
    popList(count, entries);
    Object typeArguments = pop();
    DartType keyType;
    DartType valueType;
    if (typeArguments != null) {
      if (forest.getTypeCount(typeArguments) != 2) {
        addProblem(
            fasta.messageListLiteralTypeArgumentMismatch,
            offsetForToken(leftBrace),
            lengthOfSpan(leftBrace, leftBrace.endGroup));
      } else {
        keyType = forest.getTypeAt(typeArguments, 0);
        valueType = forest.getTypeAt(typeArguments, 1);
        if (library.loader.target.strongMode) {
          keyType = instantiateToBounds(keyType, coreTypes.objectClass);
          valueType = instantiateToBounds(valueType, coreTypes.objectClass);
        }
      }
    }

    push(forest.literalMap(
        constKeyword,
        constKeyword != null || constantContext == ConstantContext.inferred,
        keyType,
        valueType,
        typeArguments,
        leftBrace,
        entries,
        rightBrace));
  }

  @override
  void endLiteralMapEntry(Token colon, Token endToken) {
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
    String value;
    if (identifierCount == 1) {
      Object part = pop();
      value = symbolPartToString(part);
      push(forest.literalSymbolSingluar(value, hashToken, part));
    } else {
      List<Identifier> parts = popList(identifierCount,
          new List<Identifier>.filled(identifierCount, null, growable: true));
      value = symbolPartToString(parts.first);
      for (int i = 1; i < parts.length; i++) {
        value += ".${symbolPartToString(parts[i])}";
      }
      push(forest.literalSymbolMultiple(value, hashToken, parts));
    }
  }

  @override
  void handleType(Token beginToken, Token endToken) {
    // TODO(ahe): The scope is wrong for return types of generic functions.
    debugEvent("Type");
    List<DartType> arguments = pop();
    Object name = pop();
    if (name is List<Object>) {
      List<Object> list = name;
      if (list.length != 2) {
        unexpected("${list.length}", "2", beginToken.charOffset, uri);
      }
      Object prefix = list[0];
      Identifier suffix = list[1];
      if (prefix is Generator) {
        name = prefix.prefixedLookup(suffix.token);
      } else {
        String displayName = debugName(getNodeName(prefix), suffix.name);
        addProblem(fasta.templateNotAType.withArguments(displayName),
            offsetForToken(beginToken), lengthOfSpan(beginToken, suffix.token));
        push(const InvalidType());
        return;
      }
    }
    if (name is Generator) {
      push(name.buildTypeWithBuiltArguments(arguments));
    } else if (name is TypeBuilder) {
      push(name.build(library));
    } else {
      unhandled(
          "${name.runtimeType}", "handleType", beginToken.charOffset, uri);
    }
  }

  @override
  void beginFunctionType(Token beginToken) {
    debugEvent("beginFunctionType");
  }

  void enterFunctionTypeScope(List<Object> typeVariables) {
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
          deprecated_addCompileTimeError(
              builder.charOffset, "'$name' already declared in this scope.");
          deprecated_addCompileTimeError(
              existing.charOffset, "Previous definition of '$name'.");
        }
      }
    }
  }

  @override
  void endFunctionType(Token functionToken, Token endToken) {
    debugEvent("FunctionType");
    FormalParameters<Expression, Statement, Arguments> formals = pop();
    DartType returnType = pop();
    List<TypeParameter> typeVariables = typeVariableBuildersToKernel(pop());
    FunctionType type = formals.toFunctionType(returnType, typeVariables);
    exitLocalScope();
    push(type);
  }

  @override
  void handleVoidKeyword(Token token) {
    debugEvent("VoidKeyword");
    push(const VoidType());
  }

  @override
  void handleAsOperator(Token operator) {
    debugEvent("AsOperator");
    DartType type = pop();
    Expression expression = popForValue();
    if (constantContext != ConstantContext.none) {
      push(deprecated_buildCompileTimeError(
          "Not a constant expression.", operator.charOffset));
    } else {
      push(forest.asExpression(expression, type, operator));
    }
  }

  @override
  void handleIsOperator(Token isOperator, Token not) {
    debugEvent("IsOperator");
    DartType type = pop();
    Expression operand = popForValue();
    bool isInverted = not != null;
    Expression isExpression =
        forest.isExpression(operand, isOperator, not, type);
    if (operand is VariableGet) {
      typePromoter.handleIsCheck(isExpression, isInverted, operand.variable,
          type, functionNestingLevel);
    }
    if (constantContext != ConstantContext.none) {
      push(deprecated_buildCompileTimeError(
          "Not a constant expression.", isOperator.charOffset));
    } else {
      push(isExpression);
    }
  }

  @override
  void beginConditionalExpression(Token question) {
    Expression condition = popForValue();
    typePromoter.enterThen(condition);
    push(condition);
    super.beginConditionalExpression(question);
  }

  @override
  void handleConditionalExpressionColon() {
    Expression then = popForValue();
    typePromoter.enterElse();
    push(then);
    super.handleConditionalExpressionColon();
  }

  @override
  void endConditionalExpression(Token question, Token colon) {
    debugEvent("ConditionalExpression");
    Expression elseExpression = popForValue();
    Expression thenExpression = pop();
    Expression condition = pop();
    typePromoter.exitConditional();
    push(forest.conditionalExpression(
        condition, question, thenExpression, colon, elseExpression));
  }

  @override
  void handleThrowExpression(Token throwToken, Token endToken) {
    debugEvent("ThrowExpression");
    Expression expression = popForValue();
    if (constantContext != ConstantContext.none) {
      push(deprecated_buildCompileTimeError(
          "Not a constant expression.", throwToken.charOffset));
      // TODO(brianwilkerson): For analyzer, we need to produce the error above
      // but then we need to produce the AST as in the `else` clause below.
    } else {
      push(forest.throwExpression(throwToken, expression));
    }
  }

  @override
  void beginFormalParameter(Token token, MemberKind kind, Token covariantToken,
      Token varFinalOrConst) {
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
    Identifier name = pop();
    DartType type = pop();
    int modifiers = pop();
    if (inCatchClause) {
      modifiers |= finalMask;
    }
    bool isConst = (modifiers & constMask) != 0;
    bool isFinal = (modifiers & finalMask) != 0;
    List<Expression> annotations = pop();
    VariableDeclaration variable;
    if (!inCatchClause &&
        functionNestingLevel == 0 &&
        memberKind != MemberKind.GeneralizedFunctionType) {
      ProcedureBuilder<TypeBuilder> member = this.member;
      KernelFormalParameterBuilder formal = member.getFormal(name.name);
      if (formal == null) {
        internalProblem(
            fasta.templateInternalProblemNotFoundIn
                .withArguments(name.name, "formals"),
            member.charOffset,
            member.fileUri);
      } else {
        variable = formal.build(library);
        variable.initializer = name.initializer;
      }
    } else {
      variable = new VariableDeclarationJudgment(
          name?.name, functionNestingLevel,
          type: type,
          initializer: name?.initializer,
          isFinal: isFinal,
          isConst: isConst);
      if (name != null) {
        // TODO(ahe): Need an offset when name is null.
        variable.fileOffset = offsetForToken(name.token);
      }
    }
    if (annotations != null) {
      if (functionNestingLevel == 0) {
        _typeInferrer.inferMetadata(this, factory, annotations);
      }
      for (Expression annotation in annotations) {
        variable.addAnnotation(annotation);
      }
    }
    push(variable);
  }

  @override
  void endOptionalFormalParameters(
      int count, Token beginToken, Token endToken) {
    debugEvent("OptionalFormalParameters");
    FormalParameterKind kind = optional("{", beginToken)
        ? FormalParameterKind.optionalNamed
        : FormalParameterKind.optionalPositional;
    Object variables =
        new List<VariableDeclaration>.filled(count, null, growable: true);
    popList(count, variables);
    push(new OptionalFormals(kind, variables));
  }

  @override
  void beginFunctionTypedFormalParameter(Token token) {
    debugEvent("beginFunctionTypedFormalParameter");
    functionNestingLevel++;
  }

  @override
  void endFunctionTypedFormalParameter() {
    debugEvent("FunctionTypedFormalParameter");
    if (inCatchClause || functionNestingLevel != 0) {
      exitLocalScope();
    }
    FormalParameters<Expression, Statement, Arguments> formals = pop();
    DartType returnType = pop();
    List<TypeParameter> typeVariables = typeVariableBuildersToKernel(pop());
    FunctionType type = formals.toFunctionType(returnType, typeVariables);
    exitLocalScope();
    push(type);
    functionNestingLevel--;
  }

  @override
  void beginFormalParameterDefaultValueExpression() {
    super.push(constantContext);
    constantContext = ConstantContext.none;
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
    Identifier name = pop();
    push(new InitializedIdentifier(name.token, initializer));
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
    OptionalFormals optional;
    if (count > 0 && peek() is OptionalFormals) {
      optional = pop();
      count--;
    }
    List<VariableDeclaration> variables =
        new List<VariableDeclaration>.filled(count, null, growable: true);
    popList(count, variables);
    FormalParameters<Expression, Statement, Arguments> formals =
        new FormalParameters<Expression, Statement, Arguments>(
            variables, optional, beginToken.charOffset);
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
    FormalParameters<Expression, Statement, Arguments> catchParameters =
        popIfNotNull(catchKeyword);
    Object type = popIfNotNull(onKeyword);
    Object exception;
    Object stackTrace;
    if (catchParameters != null) {
      int requiredCount = catchParameters.required.length;
      if ((requiredCount == 1 || requiredCount == 2) &&
          catchParameters.optional == null) {
        exception = catchParameters.required[0];
        forest.setParameterType(exception, type);
        if (requiredCount == 2) {
          stackTrace = catchParameters.required[1];
          forest.setParameterType(
              stackTrace, coreTypes.stackTraceClass.rawType);
        }
      } else {
        body = forest.block(
            catchKeyword,
            <Statement>[
              compileTimeErrorInTry ??=
                  deprecated_buildCompileTimeErrorStatement(
                      "Invalid catch arguments.", catchKeyword.next.charOffset)
            ],
            null);
      }
    }
    push(forest.catchClause(onKeyword, type, catchKeyword, exception,
        stackTrace, coreTypes.stackTraceClass.rawType, body));
  }

  @override
  void endTryStatement(int catchCount, Token tryKeyword, Token finallyKeyword) {
    Statement finallyBlock = popStatementIfNotNull(finallyKeyword);
    Object catches = popList(
        catchCount, new List<Catch>.filled(catchCount, null, growable: true));
    Statement tryBlock = popStatement();
    if (compileTimeErrorInTry == null) {
      push(forest.tryStatement(
          tryKeyword, tryBlock, catches, finallyKeyword, finallyBlock));
    } else {
      push(compileTimeErrorInTry);
      compileTimeErrorInTry = null;
    }
  }

  @override
  void handleNoExpression(Token token) {
    debugEvent("NoExpression");
    push(NullValue.Expression);
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

        if (receiver is LargeIntAccessGenerator) {
          int value = int.tryParse("-" + receiver.token.lexeme);
          if (value != null) {
            receiverValue = forest.literalInt(value, receiver.token);
            if (errorOnUnexactWebIntLiterals) {
              checkWebIntLiteralsErrorIfUnexact(value, token);
            }
          }
        }
      }
      bool isSuper = false;
      if (receiverValue == null) {
        if (receiver is ThisAccessGenerator && receiver.isSuper) {
          isSuper = true;
          receiverValue = forest.thisExpression(receiver.token);
        } else {
          receiverValue = toValue(receiver);
        }
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
      push(
          wrapInCompileTimeError(toValue(generator), fasta.messageNotAnLvalue));
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
      push(
          wrapInCompileTimeError(toValue(generator), fasta.messageNotAnLvalue));
    }
  }

  @override
  void endConstructorReference(
      Token start, Token periodBeforeName, Token endToken) {
    debugEvent("ConstructorReference");
    pushQualifiedReference(start, periodBeforeName);
  }

  /// A qualfied reference is something that matches one of:
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
    List<DartType> typeArguments = pop();
    Object type = pop();
    if (type is List<Object>) {
      List<Object> list = type;
      Object prefix = list[0];
      identifier = list[1];
      if (prefix is TypeUseGenerator) {
        type = prefix;
      } else if (prefix is Generator) {
        type = prefix.prefixedLookup(identifier.token);
        identifier = null;
      } else {
        unhandled("${prefix.runtimeType}", "pushQualifiedReference",
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
  }

  @override
  Expression buildStaticInvocation(Member target, Arguments arguments,
      {Constness constness: Constness.implicit,
      int charOffset: -1,
      Member initialTarget,
      List<DartType> targetTypeArguments}) {
    bool isConst = constness == Constness.explicitConst;
    initialTarget ??= target;
    List<TypeParameter> typeParameters = target.function.typeParameters;
    if (target is Constructor) {
      assert(!target.enclosingClass.isAbstract);
      typeParameters = target.enclosingClass.typeParameters;
    }
    LocatedMessage argMessage = checkArgumentsForFunction(
        target.function, arguments, charOffset, typeParameters);
    if (argMessage != null) {
      return new SyntheticExpressionJudgment(throwNoSuchMethodError(
          forest.literalNull(null)..fileOffset = charOffset,
          target.name.name,
          arguments,
          charOffset,
          candidate: target,
          argMessage: argMessage));
    }
    if (target is Constructor) {
      isConst =
          isConst || constantContext != ConstantContext.none && target.isConst;
      if ((isConst || constantContext == ConstantContext.inferred) &&
          !target.isConst) {
        return deprecated_buildCompileTimeError(
            "Not a const constructor.", charOffset);
      }
      return new ConstructorInvocationJudgment(target, targetTypeArguments,
          initialTarget, forest.castArguments(arguments),
          isConst: isConst)
        ..fileOffset = charOffset;
    } else {
      Procedure procedure = target;
      if (procedure.isFactory) {
        isConst = isConst ||
            constantContext != ConstantContext.none && procedure.isConst;
        if ((isConst || constantContext == ConstantContext.inferred) &&
            !procedure.isConst) {
          return deprecated_buildCompileTimeError(
              "Not a const factory.", charOffset);
        }
        return new FactoryConstructorInvocationJudgment(target,
            targetTypeArguments, initialTarget, forest.castArguments(arguments),
            isConst: isConst)
          ..fileOffset = charOffset;
      } else {
        return new StaticInvocationJudgment(
            target, forest.castArguments(arguments),
            isConst: isConst)
          ..fileOffset = charOffset;
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
          .withLocation(uri, offset, noLength);
    }
    if (forest.argumentsPositional(arguments).length >
        function.positionalParameters.length) {
      return fasta.templateTooManyArguments
          .withArguments(function.positionalParameters.length,
              forest.argumentsPositional(arguments).length)
          .withLocation(uri, offset, noLength);
    }
    List<Object> named = forest.argumentsNamed(arguments);
    if (named.isNotEmpty) {
      Set<String> names =
          new Set.from(function.namedParameters.map((a) => a.name));
      for (NamedExpression argument in named) {
        if (!names.remove(argument.name)) {
          return fasta.templateNoSuchNamedParameter
              .withArguments(argument.name)
              .withLocation(uri, argument.fileOffset, argument.name.length);
        }
      }
    }

    List<Object> types = forest.argumentsTypeArguments(arguments);
    if (typeParameters.length != types.length) {
      // TODO(paulberry): Report error in this case as well,
      // after https://github.com/dart-lang/sdk/issues/32130 is fixed.
      types.clear();
      for (int i = 0; i < typeParameters.length; i++) {
        types.add(const DynamicType());
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
          .withLocation(uri, offset, noLength);
    }
    if (forest.argumentsPositional(arguments).length >
        function.positionalParameters.length) {
      return fasta.templateTooManyArguments
          .withArguments(function.positionalParameters.length,
              forest.argumentsPositional(arguments).length)
          .withLocation(uri, offset, noLength);
    }
    List<Object> named = forest.argumentsNamed(arguments);
    if (named.isNotEmpty) {
      Set<String> names =
          new Set.from(function.namedParameters.map((a) => a.name));
      for (NamedExpression argument in named) {
        if (!names.remove(argument.name)) {
          return fasta.templateNoSuchNamedParameter
              .withArguments(argument.name)
              .withLocation(uri, argument.fileOffset, argument.name.length);
        }
      }
    }

    return null;
  }

  @override
  void beginNewExpression(Token token) {
    debugEvent("beginNewExpression");
    super.push(constantContext);
    if (constantContext != ConstantContext.none) {
      deprecated_addCompileTimeError(
          token.charOffset, "Not a constant expression.");
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
    String name = pop();
    List<DartType> typeArguments = pop();

    Object type = pop();

    ConstantContext savedConstantContext = pop();
    if (type is Generator) {
      push(type.invokeConstructor(
          typeArguments, name, arguments, nameToken, constness));
    } else {
      push(new SyntheticExpressionJudgment(throwNoSuchMethodError(
          forest.literalNull(null)..fileOffset = offset,
          debugName(getNodeName(type), name),
          arguments,
          nameToken.charOffset)));
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
      Arguments arguments,
      String name,
      List<DartType> typeArguments,
      int charOffset,
      Constness constness) {
    if (arguments == null) {
      return deprecated_buildCompileTimeError(
          "No arguments.", nameToken.charOffset);
    }

    if (typeArguments != null) {
      assert(forest.argumentsTypeArguments(arguments).isEmpty);
      forest.argumentsSetTypeArguments(arguments, typeArguments);
    }

    String errorName;
    if (type is ClassBuilder<TypeBuilder, Object>) {
      if (type is EnumBuilder<TypeBuilder, Object>) {
        return deprecated_buildCompileTimeError(
            "An enum class can't be instantiated.", nameToken.charOffset);
      }
      Declaration b =
          type.findConstructorOrFactory(name, charOffset, uri, library);
      Member target;
      Member initialTarget;
      List<DartType> targetTypeArguments;
      if (b == null) {
        // Not found. Reported below.
      } else if (b.isConstructor) {
        initialTarget = b.target;
        if (type.isAbstract) {
          return new InvalidConstructorInvocationJudgment(
              evaluateArgumentsBefore(
                  arguments,
                  buildAbstractClassInstantiationError(
                      fasta.templateAbstractClassInstantiation
                          .withArguments(type.name),
                      type.name,
                      nameToken.charOffset)),
              b.target,
              arguments);
        } else {
          target = initialTarget;
        }
      } else if (b.isFactory) {
        initialTarget = b.target;
        RedirectionTarget redirectionTarget = getRedirectionTarget(
            initialTarget,
            strongMode: library.loader.target.strongMode);
        target = redirectionTarget?.target;
        targetTypeArguments = redirectionTarget?.typeArguments;
        if (target == null) {
          return deprecated_buildCompileTimeError(
              "Cyclic definition of factory '${name}'.", nameToken.charOffset);
        }
        if (target is Constructor && target.enclosingClass.isAbstract) {
          return new SyntheticExpressionJudgment(evaluateArgumentsBefore(
              arguments,
              buildAbstractClassInstantiationError(
                  fasta.templateAbstractRedirectedClassInstantiation
                      .withArguments(target.enclosingClass.name),
                  target.enclosingClass.name,
                  nameToken.charOffset)));
        }
        RedirectingFactoryBody body = getRedirectingFactoryBody(target);
        if (body != null) {
          // If the redirection target is itself a redirecting factory, it
          // means that it is unresolved. So we set target to null so we
          // can generate a no-such-method error below.
          assert(body.isUnresolved);
          target = null;
          errorName = body.unresolvedName;
        }
      }
      if (target is Constructor ||
          (target is Procedure && target.kind == ProcedureKind.Factory)) {
        return buildStaticInvocation(target, arguments,
            constness: constness,
            charOffset: nameToken.charOffset,
            initialTarget: initialTarget,
            targetTypeArguments: targetTypeArguments);
      } else {
        errorName ??= debugName(type.name, name);
      }
    } else {
      errorName = debugName(getNodeName(type), name);
    }
    errorName ??= name;
    if (nameToken.lexeme == type.name && name.isNotEmpty) {
      nameToken = nameToken.next.next;
    }

    return new UnresolvedTargetInvocationJudgment(
        throwNoSuchMethodError(
            forest.literalNull(null)..fileOffset = charOffset,
            errorName,
            arguments,
            nameToken.charOffset),
        arguments)
      ..fileOffset = arguments.fileOffset;
  }

  @override
  void endConstExpression(Token token) {
    debugEvent("endConstExpression");
    buildConstructorReferenceInvocation(
        token.next, token.offset, Constness.explicitConst);
  }

  @override
  void endTypeArguments(int count, Token beginToken, Token endToken) {
    debugEvent("TypeArguments");
    push(
        popList(count, new List<DartType>.filled(count, null, growable: true)));
  }

  @override
  void handleThisExpression(Token token, IdentifierContext context) {
    debugEvent("ThisExpression");
    if (context.isScopeReference && isInstanceContext) {
      push(new ThisAccessGenerator(this, token, inInitializer));
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
      push(new ThisAccessGenerator(this, token, inInitializer, isSuper: true));
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
    push(new NamedExpressionJudgment(identifier.token, colon, value)
      ..fileOffset = offsetForToken(identifier.token));
  }

  @override
  void endFunctionName(Token beginToken, Token token) {
    debugEvent("FunctionName");
    Identifier name = pop();
    VariableDeclaration variable = new VariableDeclarationJudgment(
        name.name, functionNestingLevel,
        isFinal: true, isLocalFunction: true)
      ..fileOffset = offsetForToken(name.token);
    if (scope.local[variable.name] != null) {
      deprecated_addCompileTimeError(offsetForToken(name.token),
          "'${variable.name}' already declared in this scope.");
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
    List<Object> typeVariables = pop();
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
    List<Object> typeVariables = pop();
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
    FormalParameters<Expression, Statement, Arguments> formals = pop();
    Object declaration = pop();
    Object returnType = pop();
    Object hasImplicitReturnType = returnType == null;
    returnType ??= const DynamicType();
    exitFunction();
    List<TypeParameter> typeParameters = typeVariableBuildersToKernel(pop());
    List<Expression> annotations;
    if (!isFunctionExpression) {
      annotations = pop(); // Metadata.
    }
    FunctionNode function = formals.addToFunction(new FunctionNodeJudgment(body,
        typeParameters: typeParameters,
        asyncMarker: asyncModifier,
        returnType: returnType)
      ..fileOffset = formals.charOffset
      ..fileEndOffset = token.charOffset);

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
        variable.initializer = new FunctionExpressionJudgment(function)
          ..parent = variable
          ..fileOffset = formals.charOffset;
        exitLocalScope();
        Expression expression = new NamedFunctionExpressionJudgment(variable);
        if (oldInitializer != null) {
          // This must have been a compile-time error.
          assert(isErroneousNode(oldInitializer));

          push(new SyntheticExpressionJudgment(new Let(
              new VariableDeclaration.forValue(oldInitializer)
                ..fileOffset = forest.readOffset(expression),
              expression)
            ..fileOffset = forest.readOffset(expression)));
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
    FormalParameters<Expression, Statement, Arguments> formals = pop();
    exitFunction();
    List<TypeParameter> typeParameters = typeVariableBuildersToKernel(pop());
    FunctionNode function = formals.addToFunction(new FunctionNodeJudgment(body,
        typeParameters: typeParameters, asyncMarker: asyncModifier)
      ..fileOffset = beginToken.charOffset
      ..fileEndOffset = token.charOffset);
    if (constantContext != ConstantContext.none) {
      push(deprecated_buildCompileTimeError(
          "Not a constant expression.", formals.charOffset));
    } else {
      push(new FunctionExpressionJudgment(function)
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
  void endForIn(Token awaitToken, Token forToken, Token leftParenthesis,
      Token inKeyword, Token endToken) {
    debugEvent("ForIn");
    Statement body = popStatement();
    Expression expression = popForValue();
    Object lvalue = pop();
    exitLocalScope();
    JumpTarget continueTarget = exitContinueTarget();
    JumpTarget breakTarget = exitBreakTarget();
    Statement kernelBody = body;
    if (continueTarget.hasUsers) {
      kernelBody = new LabeledStatementJudgment(kernelBody);
      continueTarget.resolveContinues(forest, kernelBody);
    }
    VariableDeclaration variable;
    bool declaresVariable = false;
    SyntheticExpressionJudgment syntheticAssignment;
    if (lvalue is VariableDeclaration) {
      declaresVariable = true;
      variable = lvalue;
      if (variable.isConst) {
        deprecated_addCompileTimeError(
            variable.fileOffset, "A for-in loop-variable can't be 'const'.");
      }
    } else if (lvalue is Generator) {
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
      variable =
          new VariableDeclarationJudgment.forValue(null, functionNestingLevel);
      TypePromotionFact fact =
          typePromoter.getFactForAccess(variable, functionNestingLevel);
      TypePromotionScope scope = typePromoter.currentScope;
      syntheticAssignment = lvalue.buildAssignment(
          new VariableGetJudgment(variable, fact, scope)
            ..fileOffset = inKeyword.offset,
          voidContext: true);
    } else {
      Message message = forest.isVariablesDeclaration(lvalue)
          ? fasta.messageForInLoopExactlyOneVariable
          : fasta.messageForInLoopNotAssignable;
      Token token = forToken.next.next;
      variable = new VariableDeclaration.forValue(
          new SyntheticExpressionJudgment(buildCompileTimeError(
              message, offsetForToken(token), lengthForToken(token))));
    }
    Statement result = new ForInJudgment(
        awaitToken,
        forToken,
        leftParenthesis,
        variable,
        inKeyword,
        expression,
        leftParenthesis.endGroup,
        kernelBody,
        declaresVariable,
        syntheticAssignment,
        isAsync: awaitToken != null)
      ..fileOffset = awaitToken?.charOffset ?? forToken.charOffset
      ..bodyOffset = kernelBody.fileOffset;
    if (breakTarget.hasUsers) {
      result = new LabeledStatementJudgment(result);
      breakTarget.resolveBreaks(forest, result);
    }
    exitLoopOrSwitch(result);
  }

  @override
  void handleLabel(Token token) {
    debugEvent("Label");
    Identifier identifier = pop();
    push(forest.label(identifier.token, token));
  }

  @override
  void beginLabeledStatement(Token token, int labelCount) {
    debugEvent("beginLabeledStatement");
    List<Object> labels =
        new List<Object>.filled(labelCount, null, growable: true);
    popList(labelCount, labels);
    enterLocalScope(null, scope.createNestedLabelScope());
    LabelTarget target =
        new LabelTarget(labels, member, functionNestingLevel, token.charOffset);
    for (Object label in labels) {
      scope.declareLabel(forest.getLabelName(label), target);
    }
    push(target);
  }

  @override
  void endLabeledStatement(int labelCount) {
    debugEvent("LabeledStatement");
    Statement statement = popStatement();
    LabelTarget target = pop();
    exitLocalScope();
    if (target.breakTarget.hasUsers) {
      if (statement is! LabeledStatement) {
        statement = forest.syntheticLabeledStatement(statement);
      }
      target.breakTarget.resolveBreaks(forest, statement);
    }
    statement = forest.labeledStatement(target, statement);
    if (target.continueTarget.hasUsers) {
      if (statement is! LabeledStatement) {
        statement = forest.syntheticLabeledStatement(statement);
      }
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
      push(deprecated_buildCompileTimeErrorStatement(
          "'rethrow' can only be used in catch clauses.",
          rethrowToken.charOffset));
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
        push(deprecated_buildCompileTimeError(
            "`assert` can't be used as an expression."));
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
    Object count = labelCount + expressionCount;
    List<Object> labelsAndExpressions =
        popList(count, new List<Object>.filled(count, null, growable: true));
    List<Object> labels = <Object>[];
    List<Expression> expressions = <Expression>[];
    if (labelsAndExpressions != null) {
      for (Object labelOrExpression in labelsAndExpressions) {
        if (forest.isLabel(labelOrExpression)) {
          labels.add(labelOrExpression);
        } else {
          expressions.add(labelOrExpression);
        }
      }
    }
    assert(scope == switchScope);
    for (Object label in labels) {
      String labelName = forest.getLabelName(label);
      if (scope.hasLocalLabel(labelName)) {
        // TODO(ahe): Should validate this is a goto target.
        if (!scope.claimLabel(labelName)) {
          addCompileTimeError(
              fasta.templateDuplicateLabelInSwitchStatement
                  .withArguments(labelName),
              forest.getLabelOffset(label),
              labelName.length);
        }
      } else {
        scope.declareLabel(labelName, createGotoTarget(firstToken.charOffset));
      }
    }
    push(expressions);
    push(labels);
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
    List<Object> labels = pop();
    List<Expression> expressions = pop();
    List<int> expressionOffsets = <int>[];
    for (Expression expression in expressions) {
      expressionOffsets.add(forest.readOffset(expression));
    }
    push(new SwitchCaseJudgment(defaultKeyword, expressions, expressionOffsets,
        colonAfterDefault, block,
        isDefault: defaultKeyword != null)
      ..fileOffset = firstToken.charOffset);
    push(labels);
  }

  @override
  void endSwitchStatement(Token switchKeyword, Token endToken) {
    debugEvent("SwitchStatement");

    List<SwitchCase> cases = pop();
    JumpTarget target = exitBreakTarget();
    exitSwitchScope();
    exitLocalScope();
    Expression expression = popForValue();
    // TODO(brianwilkerson): Plumb through the left and right parentheses and
    // the left and right curly braces.
    Statement result = new SwitchStatementJudgment(
        switchKeyword, null, expression, null, null, cases, null)
      ..fileOffset = switchKeyword.charOffset;
    if (target.hasUsers) {
      result = new LabeledStatementJudgment(result);
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
      List<Object> labels = pop();
      SwitchCase current = cases[i] = pop();
      for (Object label in labels) {
        JumpTarget target = switchScope.lookupLabel(forest.getLabelName(label));
        if (target != null) {
          target.resolveGotos(forest, current);
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
          lastNode is! Throw) {
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
      push(compileTimeErrorInLoopOrSwitch =
          deprecated_buildCompileTimeErrorStatement(
              "No target of break.", breakKeyword.charOffset));
    } else if (target == null ||
        target is! JumpTarget ||
        !target.isBreakTarget) {
      push(compileTimeErrorInLoopOrSwitch =
          deprecated_buildCompileTimeErrorStatement(
              "Can't break to '$name'.", breakKeyword.next.charOffset));
    } else if (target.functionNestingLevel != functionNestingLevel) {
      push(compileTimeErrorInLoopOrSwitch =
          deprecated_buildCompileTimeErrorStatement(
              "Can't break to '$name' in a different function.",
              breakKeyword.next.charOffset));
    } else {
      Statement statement =
          forest.breakStatement(breakKeyword, identifier, endToken);
      target.addBreak(statement);
      push(statement);
    }
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
        push(compileTimeErrorInLoopOrSwitch =
            deprecated_buildCompileTimeErrorStatement(
                "Target of continue must be a label.",
                continueKeyword.charOffset));
        return;
      }
      target = namedTarget;
      if (target == null) {
        if (switchScope == null) {
          push(deprecated_buildCompileTimeErrorStatement(
              "Can't find label '$name'.", continueKeyword.next.charOffset));
          return;
        }
        switchScope.forwardDeclareLabel(identifier.name,
            target = createGotoTarget(offsetForToken(identifier.token)));
      }
      if (target.isGotoTarget &&
          target.functionNestingLevel == functionNestingLevel) {
        ContinueSwitchStatement statement =
            new ContinueSwitchJudgment(continueKeyword, null, endToken)
              ..fileOffset = continueKeyword.charOffset;
        target.addGoto(statement);
        push(statement);
        return;
      }
    }
    if (target == null) {
      push(compileTimeErrorInLoopOrSwitch =
          deprecated_buildCompileTimeErrorStatement(
              "No target of continue.", continueKeyword.charOffset));
    } else if (!target.isContinueTarget) {
      push(compileTimeErrorInLoopOrSwitch =
          deprecated_buildCompileTimeErrorStatement(
              "Can't continue at '$name'.", continueKeyword.next.charOffset));
    } else if (target.functionNestingLevel != functionNestingLevel) {
      push(compileTimeErrorInLoopOrSwitch =
          deprecated_buildCompileTimeErrorStatement(
              "Can't continue at '$name' in a different function.",
              continueKeyword.next.charOffset));
    } else {
      Statement statement =
          forest.continueStatement(continueKeyword, identifier, endToken);
      target.addContinue(statement);
      push(statement);
    }
  }

  @override
  void beginTypeVariables(Token token) {
    debugEvent("beginTypeVariables");

    // TODO(danrubel): Now that the type variable events have been reordered,
    // we should be able to cleanup body builder type variable declaration
    // handling and remove this hack.

    OutlineBuilder listener = new OutlineBuilder(library);
    // TODO(dmitryas):  [ClassMemberParser] shouldn't be used to parse and build
    // the type variables for the local function.  It also causes the unresolved
    // types from the bounds of the type variables to appear in [library.types].
    // See the code that resolves them below.
    new ClassMemberParser(listener)
        .parseTypeVariablesOpt(new Token.eof(-1)..next = token);
    enterFunctionTypeScope(listener.pop());

    // The invocation of [enterFunctionTypeScope] above has put the type
    // variables into the scope, and now the possibly unresolved types from
    // the bounds of the variables can be resolved.  This is needed to apply
    // instantiate-to-bound later.
    // TODO(dmitryas):  Move the resolution to the appropriate place once
    // [ClassMemberParser] is not used to build the type variables for the local
    // function.  See the comment above.
    for (UnresolvedType<TypeBuilder> t in library.types) {
      t.resolveIn(scope, library);
    }
    library.types.clear();
  }

  @override
  void beginTypeVariable(Token token) {
    debugEvent("beginTypeVariable");
    Identifier name = pop();
    List<Expression> annotations = pop();

    KernelTypeVariableBuilder variable;
    Object inScope = scopeLookup(scope, name.name, token);
    if (inScope is TypeUseGenerator) {
      variable = inScope.declaration;
    } else {
      // Something went wrong when pre-parsing the type variables.
      // Assume an error is reported elsewhere.
      variable = new KernelTypeVariableBuilder(
          name.name, library, offsetForToken(name.token), null);
    }
    storeTypeUse(offsetForToken(token), variable.target);
    if (annotations != null) {
      _typeInferrer.inferMetadata(this, factory, annotations);
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
        popList(count, new List<KernelTypeVariableBuilder>(count));

    // TODO(danrubel): Call enterFunctionScope here
    // once the hack in beginTypeVariables has been removed.
    //enterFunctionTypeScope(typeVariables);
    push(typeVariables);
  }

  @override
  void endTypeVariable(Token token, int index, Token extendsOrSuper) {
    debugEvent("TypeVariable");
    DartType bound = pop();
    // Peek to leave type parameters on top of stack.
    List<KernelTypeVariableBuilder> typeVariables = peek();

    KernelTypeVariableBuilder variable = typeVariables[index];
    variable.parameter.bound = bound;
  }

  @override
  void endTypeVariables(Token beginToken, Token endToken) {
    debugEvent("TypeVariables");
    // Peek to leave type parameters on top of stack.
    List<KernelTypeVariableBuilder> typeVariables = peek();

    if (library.loader.target.strongMode) {
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
      List<Object> typeVariableBuilders) {
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
    push(wrapInCompileTimeErrorStatement(statement, message));
  }

  @override
  Expression deprecated_buildCompileTimeError(String error,
      [int charOffset = -1]) {
    return new SyntheticExpressionJudgment(buildCompileTimeError(
        fasta.templateUnspecified.withArguments(error), charOffset, noLength));
  }

  @override
  Expression buildCompileTimeError(Message message, int charOffset, int length,
      {List<LocatedMessage> context}) {
    library.addCompileTimeError(message, charOffset, length, uri,
        wasHandled: true, context: context);
    return library.loader.throwCompileConstantError(
        library.loader.buildCompileTimeError(message, charOffset, length, uri));
  }

  Expression wrapInCompileTimeError(Expression expression, Message message,
      {List<LocatedMessage> context}) {
    return wrapInLocatedCompileTimeError(expression,
        message.withLocation(uri, forest.readOffset(expression), noLength),
        context: context);
  }

  @override
  Expression wrapInLocatedCompileTimeError(
      Expression expression, LocatedMessage message,
      {List<LocatedMessage> context}) {
    // TODO(askesc): Produce explicit error expression wrapping the original.
    // See [issue 29717](https://github.com/dart-lang/sdk/issues/29717)
    return new SyntheticExpressionJudgment(new Let(
        new VariableDeclaration.forValue(new SyntheticExpressionJudgment(
            buildCompileTimeError(
                message.messageObject, message.charOffset, message.length,
                context: context)))
          ..fileOffset = forest.readOffset(expression),
        new Let(
            new VariableDeclaration.forValue(expression)
              ..fileOffset = forest.readOffset(expression),
            forest.literalNull(null)
              ..fileOffset = forest.readOffset(expression))
          ..fileOffset = forest.readOffset(expression))
      ..fileOffset = forest.readOffset(expression));
  }

  Expression buildFallThroughError(int charOffset) {
    addProblem(fasta.messageSwitchCaseFallThrough, charOffset, noLength);

    // TODO(ahe): The following doesn't make sense for the Analyzer. It should
    // be moved to [Forest] or conditional on `forest is Fangorn`.

    // TODO(ahe): Compute a LocatedMessage above instead?
    Location location = messages.getLocationFromUri(uri, charOffset);

    return new Throw(buildStaticInvocation(
        library.loader.coreTypes.fallThroughErrorUrlAndLineConstructor,
        forest.arguments(<Expression>[
          forest.literalString("${location?.file ?? uri}", null)
            ..fileOffset = charOffset,
          forest.literalInt(location?.line ?? 0, null)..fileOffset = charOffset,
        ], noLocation),
        charOffset: charOffset));
  }

  Expression buildAbstractClassInstantiationError(
      Message message, String className,
      [int charOffset = -1]) {
    addProblemErrorIfConst(message, charOffset, className.length);
    // TODO(ahe): The following doesn't make sense to Analyzer AST.
    Declaration constructor =
        library.loader.getAbstractClassInstantiationError();
    return new Throw(buildStaticInvocation(
        constructor.target,
        forest.arguments(<Expression>[
          forest.literalString(className, null)..fileOffset = charOffset
        ], noLocation)));
  }

  Statement deprecated_buildCompileTimeErrorStatement(error,
      [int charOffset = -1]) {
    return new ExpressionStatementJudgment(
        deprecated_buildCompileTimeError(error, charOffset), null);
  }

  Statement buildCompileTimeErrorStatement(Message message, int charOffset,
      {List<LocatedMessage> context}) {
    return new ExpressionStatementJudgment(
        new SyntheticExpressionJudgment(buildCompileTimeError(
            message, charOffset, noLength,
            context: context)),
        null);
  }

  Statement wrapInCompileTimeErrorStatement(
      Statement statement, Message message) {
    // TODO(askesc): Produce explicit error statement wrapping the original.
    // See [issue 29717](https://github.com/dart-lang/sdk/issues/29717)
    return buildCompileTimeErrorStatement(message, statement.fileOffset);
  }

  @override
  Initializer buildInvalidInitializer(Expression expression,
      [int charOffset = -1]) {
    needsImplicitSuperInitializer = false;
    return new ShadowInvalidInitializer(
        new VariableDeclaration.forValue(expression))
      ..fileOffset = charOffset;
  }

  Initializer buildDuplicatedInitializer(
      String name, int offset, int previousInitializerOffset) {
    Initializer initializer = buildInvalidInitializer(
        deprecated_buildCompileTimeError(
            "'$name' has already been initialized.", offset),
        offset);
    deprecated_addCompileTimeError(
        initializedFields[name], "'$name' was initialized here.");
    return initializer;
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
  Initializer buildFieldInitializer(
      bool isSynthetic, String name, int offset, Expression expression,
      {DartType formalType}) {
    Declaration builder =
        classBuilder.scope.local[name] ?? classBuilder.origin.scope.local[name];
    if (builder is KernelFieldBuilder && builder.isInstanceMember) {
      initializedFields ??= <String, int>{};
      if (initializedFields.containsKey(name)) {
        return buildDuplicatedInitializer(
            name, offset, initializedFields[name]);
      }
      initializedFields[name] = offset;
      if (builder.isFinal && builder.hasInitializer) {
        // TODO(ahe): If CL 2843733002 is landed, this becomes a compile-time
        // error. Also, this is a compile-time error in strong mode.
        addProblem(
            fasta.templateFinalInstanceVariableAlreadyInitialized
                .withArguments(name),
            offset,
            noLength,
            context: [
              fasta.templateFinalInstanceVariableAlreadyInitializedCause
                  .withArguments(name)
                  .withLocation(uri, builder.charOffset, noLength)
            ]);
        Declaration constructor =
            library.loader.getDuplicatedFieldInitializerError();
        return buildInvalidInitializer(
            new Throw(buildStaticInvocation(
                constructor.target,
                forest.arguments(<Expression>[
                  forest.literalString(name, null)..fileOffset = offset
                ], noLocation),
                charOffset: offset)),
            offset);
      } else {
        if (library.loader.target.strongMode &&
            formalType != null &&
            !_typeInferrer.typeSchemaEnvironment
                .isSubtypeOf(formalType, builder.field.type)) {
          library.addProblem(
              fasta.templateInitializingFormalTypeMismatch
                  .withArguments(name, formalType, builder.field.type),
              offset,
              noLength,
              uri,
              context: [
                fasta.messageInitializingFormalTypeMismatchField
                    .withLocation(builder.fileUri, builder.charOffset, noLength)
              ]);
        }
        return new ShadowFieldInitializer(builder.field, expression)
          ..fileOffset = offset
          ..isSynthetic = isSynthetic;
      }
    } else {
      return buildInvalidInitializer(
          deprecated_buildCompileTimeError(
              "'$name' isn't an instance field of this class.", offset),
          offset);
    }
  }

  @override
  Initializer buildSuperInitializer(
      bool isSynthetic, Constructor constructor, Arguments arguments,
      [int charOffset = -1]) {
    if (member.isConst && !constructor.isConst) {
      return buildInvalidInitializer(
          deprecated_buildCompileTimeError(
              "Super constructor isn't const.", charOffset),
          charOffset);
    }
    needsImplicitSuperInitializer = false;
    // TODO(brianwilkerson): Plumb through the `super`, period, and constructor
    // name tokens.
    return new SuperInitializerJudgment(
        null, null, null, constructor, forest.castArguments(arguments))
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
  Expression buildProblemExpression(
      ProblemBuilder builder, int charOffset, int length) {
    return new SyntheticExpressionJudgment(
        buildCompileTimeError(builder.message, charOffset, length));
  }

  @override
  void handleOperator(Token token) {
    debugEvent("Operator");
    push(new Operator(token, token.charOffset));
  }

  @override
  void handleSymbolVoid(Token token) {
    debugEvent("SymbolVoid");
    push(new Identifier(token));
  }

  @override
  void deprecated_addCompileTimeError(int charOffset, String message,
      {bool wasHandled: false}) {
    // TODO(ahe): Consider setting [constantContext] to `ConstantContext.none`
    // to avoid a long list of errors.
    return library.addCompileTimeError(
        fasta.templateUnspecified.withArguments(message),
        charOffset,
        noLength,
        uri,
        wasHandled: wasHandled);
  }

  @override
  void handleInvalidFunctionBody(Token token) {
    if (member.isNative) {
      push(NullValue.FunctionBody);
    } else {
      push(forest.block(
          token,
          <Statement>[
            deprecated_buildCompileTimeErrorStatement(
                "Expected '{'.", token.charOffset)
          ],
          null));
    }
  }

  @override
  DartType validatedTypeVariableUse(
      TypeParameterType type, int offset, bool nonInstanceAccessIsError) {
    if (!isInstanceContext && type.parameter.parent is Class) {
      Message message = fasta.messageTypeVariableInStaticContext;
      int length = type.parameter.name.length;
      if (nonInstanceAccessIsError) {
        addCompileTimeError(message, offset, length);
      } else {
        addProblemErrorIfConst(message, offset, length);
      }
      return const InvalidType();
    } else if (constantContext != ConstantContext.none) {
      deprecated_addCompileTimeError(
          offset,
          "Type variable '${type.parameter.name}' can't be used as a constant "
          "expression $type.");
    }
    return type;
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
          new VariableDeclaration.forValue(argument, isFinal: true),
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
      return deprecated_buildCompileTimeError(
          "Not a constant expression.", offset);
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
            name, forest.castArguments(arguments), target)
          ..fileOffset = offset;
      }

      receiver = new SuperPropertyGetJudgment(name, target)
        ..fileOffset = offset;
      return new MethodInvocationJudgment(
          receiver, callName, forest.castArguments(arguments),
          isImplicitCall: true)
        ..fileOffset = forest.readOffset(arguments);
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
      return new MethodInvocationJudgment(
          receiver, name, forest.castArguments(arguments),
          isImplicitCall: isImplicitCall, interfaceTarget: interfaceTarget)
        ..fileOffset = offset;
    }
  }

  @override
  void addCompileTimeError(Message message, int charOffset, int length,
      {List<LocatedMessage> context}) {
    library.addCompileTimeError(message, charOffset, length, uri,
        context: context);
  }

  @override
  void addProblem(Message message, int charOffset, int length,
      {List<LocatedMessage> context}) {
    library.addProblem(message, charOffset, length, uri, context: context);
  }

  @override
  void addProblemErrorIfConst(Message message, int charOffset, int length,
      {List<LocatedMessage> context}) {
    // TODO(askesc): Instead of deciding on the severity, this method should
    // take two messages: one to use when a constant expression is
    // required and one to use otherwise.
    if (constantContext != ConstantContext.none) {
      addCompileTimeError(message, charOffset, length, context: context);
    } else {
      library.addProblem(message, charOffset, length, uri, context: context);
    }
  }

  @override
  void debugEvent(String name) {
    // printEvent('BodyBuilder: $name');
  }

  @override
  StaticGet makeStaticGet(Member readTarget, Token token) {
    return new StaticGetJudgment(readTarget)
      ..fileOffset = offsetForToken(token);
  }

  @override
  Expression wrapInDeferredCheck(
      Expression expression, KernelPrefixBuilder prefix, int charOffset) {
    Object check = new VariableDeclaration.forValue(
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

  void checkWebIntLiteralsErrorIfUnexact(int value, Token token) {
    BigInt asInt = new BigInt.from(value).toUnsigned(64);
    BigInt asDouble = new BigInt.from(asInt.toDouble());
    if (asInt != asDouble) {
      String nearest;
      if (token.lexeme.startsWith("0x") || token.lexeme.startsWith("0X")) {
        nearest = '0x${asDouble.toRadixString(16)}';
      } else {
        nearest = '$asDouble';
      }
      library.addCompileTimeError(
          fasta.templateWebLiteralCannotBeRepresentedExactly
              .withArguments(token.lexeme, nearest),
          token.charOffset,
          token.charCount,
          uri,
          wasHandled: true);
    }
  }

  @override
  void storeTypeUse(int offset, Node node) {
    _typeInferrer.storeTypeUse(offset, node);
  }
}

class Identifier {
  final Token token;
  String get name => token.lexeme;

  Identifier(this.token);

  Expression get initializer => null;

  String toString() => "identifier($name)";
}

class Operator {
  final Token token;
  String get name => token.stringValue;

  final int charOffset;

  Operator(this.token, this.charOffset);

  String toString() => "operator($name)";
}

class InitializedIdentifier extends Identifier {
  final Expression initializer;

  InitializedIdentifier(Token token, this.initializer) : super(token);

  String toString() => "initialized-identifier($name, $initializer)";
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
    for (Statement user in users) {
      forest.resolveBreak(target, user);
    }
    users.clear();
  }

  void resolveContinues(Forest forest, Statement target) {
    assert(isContinueTarget);
    for (Statement user in users) {
      forest.resolveContinue(target, user);
    }
    users.clear();
  }

  void resolveGotos(Forest forest, Object target) {
    assert(isGotoTarget);
    for (Statement user in users) {
      forest.resolveContinueInSwitch(target, user);
    }
    users.clear();
  }

  @override
  String get fullNameForErrors => "<jump-target>";
}

class LabelTarget extends Declaration implements JumpTarget {
  final List<Object> labels;

  @override
  final MemberBuilder parent;

  final JumpTarget breakTarget;

  final JumpTarget continueTarget;

  final int functionNestingLevel;

  @override
  final int charOffset;

  LabelTarget(
      this.labels, this.parent, this.functionNestingLevel, this.charOffset)
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

  void resolveGotos(Forest forest, Object target) {
    unsupported("resolveGotos", charOffset, fileUri);
  }

  @override
  String get fullNameForErrors => "<label-target>";
}

class OptionalFormals {
  final FormalParameterKind kind;

  final List<VariableDeclaration> formals;

  OptionalFormals(this.kind, this.formals);
}

class FormalParameters<Expression, Statement, Arguments> {
  final List<VariableDeclaration> required;
  final OptionalFormals optional;
  final int charOffset;

  FormalParameters(this.required, this.optional, this.charOffset);

  FunctionNode addToFunction(FunctionNode function) {
    function.requiredParameterCount = required.length;
    function.positionalParameters.addAll(required);
    if (optional != null) {
      if (isOptionalPositionalFormalParameterKind(optional.kind)) {
        function.positionalParameters.addAll(optional.formals);
      } else {
        function.namedParameters.addAll(optional.formals);
        setParents(function.namedParameters, function);
      }
    }
    setParents(function.positionalParameters, function);
    return function;
  }

  FunctionType toFunctionType(DartType returnType,
      [List<TypeParameter> typeParameters]) {
    returnType ??= const DynamicType();
    typeParameters ??= const <TypeParameter>[];
    int requiredParameterCount = required.length;
    List<DartType> positionalParameters = <DartType>[];
    List<NamedType> namedParameters = const <NamedType>[];
    for (VariableDeclaration parameter in required) {
      positionalParameters.add(parameter.type);
    }
    if (optional != null) {
      if (isOptionalPositionalFormalParameterKind(optional.kind)) {
        for (VariableDeclaration parameter in optional.formals) {
          positionalParameters.add(parameter.type);
        }
      } else {
        namedParameters = <NamedType>[];
        for (VariableDeclaration parameter in optional.formals) {
          namedParameters.add(new NamedType(parameter.name, parameter.type));
        }
        namedParameters.sort();
      }
    }
    return new FunctionType(positionalParameters, returnType,
        namedParameters: namedParameters,
        requiredParameterCount: requiredParameterCount,
        typeParameters: typeParameters);
  }

  Scope computeFormalParameterScope(
      Scope parent, Declaration declaration, ExpressionGeneratorHelper helper) {
    if (required.length == 0 && optional == null) return parent;
    Map<String, Declaration> local = <String, Declaration>{};

    for (VariableDeclaration parameter in required) {
      if (local[parameter.name] != null) {
        helper.deprecated_addCompileTimeError(
            parameter.fileOffset, "Duplicated name.");
      }
      local[parameter.name] = new KernelVariableBuilder(
          parameter, declaration, declaration.fileUri);
    }
    if (optional != null) {
      for (VariableDeclaration parameter in optional.formals) {
        if (local[parameter.name] != null) {
          helper.deprecated_addCompileTimeError(
              parameter.fileOffset, "Duplicated name.");
        }
        local[parameter.name] = new KernelVariableBuilder(
            parameter, declaration, declaration.fileUri);
      }
    }
    return new Scope(local, null, parent, "formals", isModifiable: false);
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
    return new Block(<Statement>[statement, body]);
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
