// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.body_builder;

import '../fasta_codes.dart'
    show FastaMessage, codeExpectedButGot, codeExpectedFunctionBody;

import '../parser/parser.dart' show FormalParameterType, MemberKind, optional;

import '../parser/identifier_context.dart' show IdentifierContext;

import 'package:front_end/src/fasta/builder/ast_factory.dart' show AstFactory;

import 'package:front_end/src/fasta/kernel/kernel_shadow_ast.dart'
    show
        KernelArguments,
        KernelField,
        KernelFunctionDeclaration,
        KernelReturnStatement,
        KernelYieldStatement;

import 'package:front_end/src/fasta/kernel/utils.dart' show offsetForToken;

import 'package:front_end/src/fasta/type_inference/type_inference_engine.dart'
    show FieldNode;

import 'package:front_end/src/fasta/type_inference/type_inferrer.dart'
    show TypeInferrer;

import 'package:front_end/src/fasta/type_inference/type_promotion.dart'
    show TypePromoter;

import 'package:kernel/ast.dart';

import 'package:kernel/clone.dart' show CloneVisitor;

import 'package:kernel/transformations/flags.dart' show TransformerFlag;

import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;

import 'package:kernel/core_types.dart' show CoreTypes;

import 'frontend_accessors.dart' show buildIsNull, makeBinary, makeLet;

import '../../scanner/token.dart' show Token;

import '../scanner/token.dart'
    show BeginGroupToken, isBinaryOperator, isMinusOperator;

import '../errors.dart' show formatUnexpected, internalError;

import '../source/scope_listener.dart'
    show JumpTargetKind, NullValue, ScopeListener;

import '../scope.dart' show ProblemBuilder;

import 'fasta_accessors.dart';

import '../quote.dart'
    show
        Quote,
        analyzeQuote,
        unescape,
        unescapeFirstStringPart,
        unescapeLastStringPart,
        unescapeString;

import '../modifier.dart' show Modifier, constMask, finalMask;

import 'redirecting_factory_body.dart' show getRedirectionTarget;

import 'kernel_builder.dart';

import '../names.dart';

class BodyBuilder extends ScopeListener<JumpTarget> implements BuilderHelper {
  final KernelLibraryBuilder library;

  final MemberBuilder member;

  final KernelClassBuilder classBuilder;

  final ClassHierarchy hierarchy;

  final CoreTypes coreTypes;

  final bool isInstanceMember;

  final Map<String, FieldInitializer> fieldInitializers =
      <String, FieldInitializer>{};

  final Scope enclosingScope;

  final bool isDartLibrary;

  @override
  final Uri uri;

  final TypeInferrer _typeInferrer;

  @override
  final AstFactory astFactory;

  @override
  final TypePromoter<Expression, VariableDeclaration> typePromoter;

  /// If not `null`, dependencies on fields are accumulated into this list.
  ///
  /// If `null`, no dependency information is recorded.
  final List<FieldNode> fieldDependencies;

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

  bool inInitializer = false;

  bool inCatchClause = false;

  bool inCatchBlock = false;

  int functionNestingLevel = 0;

  Statement compileTimeErrorInTry;

  Statement compileTimeErrorInLoopOrSwitch;

  Scope switchScope;

  CloneVisitor cloner;

  bool constantExpressionRequired = false;

  DartType currentLocalVariableType;

  // Using non-null value to initialize this field based on performance advice
  // from VM engineers. TODO(ahe): Does this still apply?
  int currentLocalVariableModifiers = -1;

  BodyBuilder(
      KernelLibraryBuilder library,
      this.member,
      Scope scope,
      this.formalParameterScope,
      this.hierarchy,
      this.coreTypes,
      this.classBuilder,
      this.isInstanceMember,
      this.uri,
      this._typeInferrer,
      this.astFactory,
      {this.fieldDependencies})
      : enclosingScope = scope,
        library = library,
        isDartLibrary = library.uri.scheme == "dart",
        needsImplicitSuperInitializer =
            coreTypes.objectClass != classBuilder?.cls,
        typePromoter = _typeInferrer.typePromoter,
        super(scope);

  bool get hasParserError => recoverableErrors.isNotEmpty;

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
    if (node is FastaAccessor) {
      return node.buildSimpleRead();
    } else if (node is TypeVariableBuilder) {
      TypeParameterType type = node.buildTypesWithBuiltArguments(library, null);
      if (!isInstanceContext && type.parameter.parent is Class) {
        return buildCompileTimeError(
            "Type variables can only be used in instance methods.");
      } else {
        if (constantExpressionRequired) {
          addCompileTimeError(-1,
              "Type variable can't be used as a constant expression $type.");
        }
        return new TypeLiteral(type);
      }
    } else if (node is TypeDeclarationBuilder) {
      return new TypeLiteral(node.buildTypesWithBuiltArguments(library, null));
    } else if (node is KernelTypeBuilder) {
      return new TypeLiteral(node.build(library));
    } else if (node is Expression) {
      return node;
    } else if (node is PrefixBuilder) {
      return buildCompileTimeError("A library can't be used as an expression.");
    } else if (node is ProblemBuilder) {
      return buildProblemExpression(node, -1);
    } else {
      return internalError("Unhandled: ${node.runtimeType}");
    }
  }

  Expression toEffect(Object node) {
    if (node is FastaAccessor) return node.buildForEffect();
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

  Block popBlock(int count, Token beginToken) {
    List<dynamic /*Statement | List<Statement>*/ > statements =
        popList(count) ?? <Statement>[];
    List<Statement> copy;
    for (int i = 0; i < statements.length; i++) {
      var statement = statements[i];
      if (statement is List) {
        copy ??= new List<Statement>.from(statements.getRange(0, i));
        // TODO(sigmund): remove this assignment (issue #28651)
        Iterable subStatements = statement;
        copy.addAll(subStatements);
      } else if (copy != null) {
        copy.add(statement);
      }
    }
    return astFactory.block(copy ?? statements, beginToken);
  }

  Statement popStatementIfNotNull(Object value) {
    return value == null ? null : popStatement();
  }

  Statement popStatement() {
    var statement = pop();
    if (statement is List) {
      return new Block(new List<Statement>.from(statement));
    } else if (statement is VariableDeclaration) {
      return new Block(<Statement>[statement]);
    } else {
      return statement;
    }
  }

  void ignore(Unhandled value) {
    pop();
  }

  void enterSwitchScope() {
    push(switchScope ?? NullValue.SwitchScope);
    switchScope = scope;
  }

  void exitSwitchScope() {
    Scope outerSwitchScope = pop();
    if (switchScope.unclaimedForwardDeclarations != null) {
      switchScope.unclaimedForwardDeclarations
          .forEach((String name, Builder builder) {
        if (outerSwitchScope == null) {
          addCompileTimeError(-1, "Label not found: '$name'.");
        } else {
          outerSwitchScope.forwardDeclareLabel(name, builder);
        }
      });
    }
    switchScope = outerSwitchScope;
  }

  @override
  JumpTarget createJumpTarget(JumpTargetKind kind, int charOffset) {
    return new JumpTarget(kind, functionNestingLevel, member, charOffset);
  }

  @override
  void endMetadata(Token beginToken, Token periodBeforeName, Token endToken) {
    debugEvent("Metadata");
    pop(); // Arguments.
    popIfNotNull(periodBeforeName); // Postfix.
    pop(); // Type arguments.
    pop(); // Expression or type name (depends on arguments).
    // TODO(ahe): Implement metadata on local declarations.
  }

  @override
  void endMetadataStar(int count, bool forParameter) {
    debugEvent("MetadataStar");
    push(NullValue.Metadata);
  }

  @override
  void endTopLevelFields(int count, Token beginToken, Token endToken) {
    debugEvent("TopLevelFields");
    doFields(count);
    // There's no metadata here because of a slight asymmetry between
    // [parseTopLevelMember] and [parseMember]. This asymmetry leads to
    // DietListener discarding top-level member metadata.
  }

  @override
  void endFields(int count, Token beginToken, Token endToken) {
    debugEvent("Fields");
    doFields(count);
    pop(); // Metadata.
  }

  void doFields(int count) {
    for (int i = 0; i < count; i++) {
      Expression initializer = pop();
      Identifier identifier = pop();
      if (initializer != null) {
        String name = identifier.name;
        FieldBuilder field;
        if (classBuilder != null) {
          field = classBuilder[name];
        } else {
          field = library[name];
        }
        if (field.next != null) {
          // TODO(ahe): This can happen, for example, if a final field is
          // combined with a setter.
          internalError(
              "Unhandled: '${field.name}' has more than one declaration.");
        }
        field.initializer = initializer;
      }
    }
    pop(); // Type.
    pop(); // Modifiers.
  }

  @override
  void endMember() {
    debugEvent("Member");
    checkEmpty(-1);
  }

  @override
  void endBlockFunctionBody(int count, Token beginToken, Token endToken) {
    debugEvent("BlockFunctionBody");
    if (beginToken == null) {
      assert(count == 0);
      push(NullValue.Block);
    } else {
      Block block = popBlock(count, beginToken);
      exitLocalScope();
      push(block);
    }
  }

  @override
  void prepareInitializers() {
    scope = formalParameterScope;
    assert(fieldInitializers.isEmpty);
    final member = this.member;
    if (member is KernelConstructorBuilder) {
      Constructor constructor = member.constructor;
      classBuilder.forEach((String name, Builder builder) {
        if (builder is KernelFieldBuilder && builder.isInstanceMember) {
          // TODO(ahe): Compute initializers (as in `field = initializer`).
          fieldInitializers[name] = new FieldInitializer(builder.field, null)
            ..parent = constructor;
        }
      });
      if (member.formals != null) {
        for (KernelFormalParameterBuilder formal in member.formals) {
          if (formal.hasThis) {
            FieldInitializer initializer = fieldInitializers[formal.name];
            if (initializer != null) {
              fieldInitializers.remove(formal.name);
              initializer.value = new VariableGet(formal.declaration)
                ..parent = initializer;
              member.addInitializer(initializer);
            }
          }
        }
      }
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
    var node = pop();
    Initializer initializer;
    if (node is Initializer) {
      initializer = node;
    } else if (node is FastaAccessor) {
      initializer = node.buildFieldInitializer(fieldInitializers);
    } else if (node is ConstructorInvocation) {
      initializer =
          buildSuperInitializer(node.target, node.arguments, token.charOffset);
    } else {
      if (node is! Throw) {
        // TODO(ahe): This is probably an internal error.
        needsImplicitSuperInitializer = false;
        node = wrapInvalid(node);
      }
      initializer = buildInvalidIntializer(node, token.charOffset);
    }
    if (member is KernelConstructorBuilder) {
      member.addInitializer(initializer);
    } else {
      addCompileTimeError(
          token.charOffset, "Can't have initializers: ${member.name}");
    }
  }

  @override
  void handleNoInitializers() {
    debugEvent("NoInitializers");
  }

  @override
  void endInitializers(int count, Token beginToken, Token endToken) {
    debugEvent("Initializers");
  }

  @override
  void finishFunction(
      FormalParameters formals, AsyncMarker asyncModifier, Statement body) {
    debugEvent("finishFunction");
    typePromoter.finished();
    // TODO(paulberry): get function return type from the outline.
    _typeInferrer.inferFunctionBody(null, asyncModifier, body);
    KernelFunctionBuilder builder = member;
    builder.body = body;
    if (formals?.optional != null) {
      Iterator<FormalParameterBuilder> formalBuilders =
          builder.formals.skip(formals.required.length).iterator;
      for (VariableDeclaration parameter in formals.optional.formals) {
        bool hasMore = formalBuilders.moveNext();
        assert(hasMore);
        VariableDeclaration realParameter = formalBuilders.current.target;
        Expression initializer =
            parameter.initializer ?? astFactory.nullLiteral(null);
        realParameter.initializer = initializer..parent = realParameter;
      }
    }
    if (builder is KernelConstructorBuilder) {
      finishConstructor(builder, asyncModifier);
    } else if (builder is KernelProcedureBuilder) {
      builder.asyncModifier = asyncModifier;
    } else {
      internalError("Unhandled: ${builder.runtimeType}");
    }
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
      constructor.initializers.add(buildInvalidIntializer(
          buildCompileTimeError(
              "A constructor can't be '${asyncModifier}'.", offset),
          offset));
    }
    if (needsImplicitSuperInitializer) {
      /// >If no superinitializer is provided, an implicit superinitializer
      /// >of the form super() is added at the end of k’s initializer list,
      /// >unless the enclosing class is class Object.
      Constructor superTarget = lookupConstructor(emptyName, isSuper: true);
      Initializer initializer;
      Arguments arguments = new Arguments.empty();
      if (superTarget == null ||
          !checkArguments(
              superTarget.function, arguments, const <TypeParameter>[])) {
        String superclass = classBuilder.supertype.fullNameForErrors;
        String message = superTarget == null
            ? "'$superclass' doesn't have an unnamed constructor."
            : "The unnamed constructor in '$superclass' requires arguments.";
        initializer = buildInvalidIntializer(
            buildCompileTimeError(message, builder.charOffset),
            builder.charOffset);
      } else {
        initializer =
            buildSuperInitializer(superTarget, arguments, builder.charOffset);
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
    push(astFactory.expressionStatement(popForEffect()));
  }

  @override
  void endArguments(int count, Token beginToken, Token endToken) {
    debugEvent("Arguments");
    List arguments = popList(count) ?? <Expression>[];
    int firstNamedArgumentIndex = arguments.length;
    for (int i = 0; i < arguments.length; i++) {
      var node = arguments[i];
      if (node is NamedExpression) {
        firstNamedArgumentIndex =
            i < firstNamedArgumentIndex ? i : firstNamedArgumentIndex;
      } else {
        arguments[i] = toValue(node);
        if (i > firstNamedArgumentIndex) {
          arguments[i] = new NamedExpression(
              "#$i",
              buildCompileTimeError(
                  "Expected named argument.", arguments[i].fileOffset));
        }
      }
    }
    if (firstNamedArgumentIndex < arguments.length) {
      List<Expression> positional = new List<Expression>.from(
          arguments.getRange(0, firstNamedArgumentIndex));
      List<NamedExpression> named = new List<NamedExpression>.from(
          arguments.getRange(firstNamedArgumentIndex, arguments.length));
      push(astFactory.arguments(positional, named: named));
    } else {
      push(astFactory.arguments(arguments));
    }
  }

  @override
  void handleParenthesizedExpression(BeginGroupToken token) {
    debugEvent("ParenthesizedExpression");
    push(new ParenthesizedExpression(this, popForValue(), token.endGroup));
  }

  @override
  void endSend(Token beginToken, Token endToken) {
    debugEvent("Send");
    Arguments arguments = pop();
    List<DartType> typeArguments = pop();
    Object receiver = pop();
    if (arguments != null && typeArguments != null) {
      assert(arguments.types.isEmpty);
      astFactory.setExplicitArgumentTypes(arguments, typeArguments);
    } else {
      assert(typeArguments == null);
    }
    if (receiver is Identifier) {
      Name name = new Name(receiver.name, library.library);
      if (arguments == null) {
        push(new IncompletePropertyAccessor(this, beginToken, name));
      } else {
        push(new SendAccessor(this, beginToken, name, arguments));
      }
    } else if (arguments == null) {
      push(receiver);
    } else {
      push(finishSend(receiver, arguments, beginToken.charOffset));
    }
  }

  @override
  finishSend(Object receiver, Arguments arguments, int charOffset) {
    bool isIdentical(Object receiver) {
      return receiver is StaticAccessor &&
          receiver.readTarget == coreTypes.identicalProcedure;
    }

    if (receiver is FastaAccessor) {
      if (constantExpressionRequired &&
          !isIdentical(receiver) &&
          !receiver.isInitializer) {
        addCompileTimeError(charOffset, "Not a constant expression.");
      }
      return receiver.doInvocation(charOffset, arguments);
    } else {
      return buildMethodInvocation(
          astFactory, toValue(receiver), callName, arguments, charOffset);
    }
  }

  @override
  void beginCascade(Token token) {
    debugEvent("beginCascade");
    Expression expression = popForValue();
    if (expression is CascadeReceiver) {
      push(expression);
      push(new VariableAccessor(this, token, expression.variable));
      expression.extend();
    } else {
      VariableDeclaration variable =
          new VariableDeclaration.forValue(expression);
      push(new CascadeReceiver(variable));
      push(new VariableAccessor(this, token, variable));
    }
  }

  @override
  void endCascade() {
    debugEvent("endCascade");
    Expression expression = popForEffect();
    CascadeReceiver cascadeReceiver = pop();
    cascadeReceiver.finalize(expression);
    push(cascadeReceiver);
  }

  @override
  void handleBinaryExpression(Token token) {
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
    var receiver = pop();
    bool isSuper = false;
    if (receiver is ThisAccessor && receiver.isSuper) {
      ThisAccessor thisAccessorReceiver = receiver;
      isSuper = true;
      receiver = astFactory.thisExpression(thisAccessorReceiver.token);
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
      return buildCompileTimeError(
          "Not an operator: '$operator'.", token.charOffset);
    } else {
      Expression result = makeBinary(astFactory, a, new Name(operator), null, b,
          offset: token.charOffset);
      if (isSuper) {
        result = toSuperMethodInvocation(result);
      }
      return negate ? astFactory.not(null, result) : result;
    }
  }

  void doLogicalExpression(Token token) {
    Expression argument = popForValue();
    Expression receiver = popForValue();
    push(astFactory.logicalExpression(receiver, token.stringValue, argument));
  }

  /// Handle `a ?? b`.
  void doIfNull(Token token) {
    Expression b = popForValue();
    Expression a = popForValue();
    VariableDeclaration variable = new VariableDeclaration.forValue(a);
    push(makeLet(
        variable,
        new ConditionalExpression(
            buildIsNull(astFactory, new VariableGet(variable)),
            b,
            new VariableGet(variable),
            const DynamicType())));
  }

  /// Handle `a?.b(...)`.
  void doIfNotNull(Token token) {
    IncompleteSend send = pop();
    push(send.withReceiver(pop(), isNullAware: true));
  }

  void doDotOrCascadeExpression(Token token) {
    // TODO(ahe): Handle null-aware.
    IncompleteSend send = pop();
    Object receiver = optional(".", token) ? pop() : popForValue();
    push(send.withReceiver(receiver));
  }

  @override
  Expression toSuperMethodInvocation(MethodInvocation node) {
    Member target = lookupSuperMember(node.name);
    bool isNoSuchMethod = target == null;
    if (target is Procedure) {
      if (!target.isAccessor) {
        if (areArgumentsCompatible(target.function, node.arguments)) {
          // TODO(ahe): Use [DirectMethodInvocation] when possible.
          Expression result = astFactory.directMethodInvocation(
              new ThisExpression(), target, node.arguments);
          result = astFactory.superMethodInvocation(
              null, node.name, node.arguments, null);
          return result;
        } else {
          isNoSuchMethod = true;
        }
      }
    }
    if (isNoSuchMethod) {
      return throwNoSuchMethodError(
          node.name.name, node.arguments, node.fileOffset,
          isSuper: true);
    }
    // TODO(ahe): Use [DirectPropertyGet] when possible.
    Expression receiver =
        astFactory.directPropertyGet(new ThisExpression(), target);
    receiver = astFactory.superPropertyGet(node.name, target);
    return buildMethodInvocation(
        astFactory, receiver, callName, node.arguments, node.fileOffset);
  }

  bool areArgumentsCompatible(FunctionNode function, Arguments arguments) {
    // TODO(ahe): Implement this.
    return true;
  }

  @override
  Expression throwNoSuchMethodError(
      String name, Arguments arguments, int charOffset,
      {bool isSuper: false, isGetter: false, isSetter: false}) {
    String errorName = isSuper ? "super.$name" : name;
    String message;
    if (isGetter) {
      message = "Getter not found: '$errorName'.";
    } else if (isSetter) {
      message = "Setter not found: '$errorName'.";
    } else {
      message = "Method not found: '$errorName'.";
    }
    if (constantExpressionRequired) {
      return buildCompileTimeError(message, charOffset);
    }
    warning(message, charOffset);
    Constructor constructor =
        coreTypes.noSuchMethodErrorClass.constructors.first;
    return new Throw(new ConstructorInvocation(
        constructor,
        astFactory.arguments(<Expression>[
          astFactory.nullLiteral(null),
          new SymbolLiteral(name),
          new ListLiteral(arguments.positional),
          new MapLiteral(arguments.named.map((arg) {
            return new MapEntry(new SymbolLiteral(arg.name), arg.value);
          }).toList()),
          astFactory.nullLiteral(null)
        ])));
  }

  @override
  Member lookupSuperMember(Name name, {bool isSetter: false}) {
    Class superclass = classBuilder.cls.superclass;
    return superclass == null
        ? null
        : hierarchy.getDispatchTarget(superclass, name, setter: isSetter);
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
    return null;
  }

  @override
  void handleIdentifier(Token token, IdentifierContext context) {
    debugEvent("handleIdentifier");
    String name = token.lexeme;
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
        constantExpressionRequired = member.isConst;
      }
    } else if (constantExpressionRequired &&
        !context.allowedInConstantExpression) {
      addCompileTimeError(
          token.charOffset, "Not a constant expression: $context");
    }
    push(new Identifier(token));
  }

  /// Look up [name] in [scope] using [token] as location information (both to
  /// report problems and as the file offset in the generated kernel code).
  /// [isQualified] should be true if [name] is a qualified access
  /// (which implies that it shouldn't be turned into a [ThisPropertyAccessor]
  /// if the name doesn't resolve in the scope).
  @override
  scopeLookup(Scope scope, String name, Token token,
      {bool isQualified: false, PrefixBuilder prefix}) {
    Builder builder = scope.lookup(name, offsetForToken(token), uri);
    if (builder == null || (!isInstanceContext && builder.isInstanceMember)) {
      Name n = new Name(name, library.library);
      if (prefix != null &&
          prefix.deferred &&
          builder == null &&
          "loadLibrary" == name) {
        return buildCompileTimeError(
            "Deferred loading isn't implemented yet.", offsetForToken(token));
      } else if (!isQualified && isInstanceContext) {
        assert(builder == null);
        if (constantExpressionRequired) {
          return new UnresolvedAccessor(this, n, token);
        }
        return new ThisPropertyAccessor(this, token, n, null, null);
      } else if (isDartLibrary &&
          name == "main" &&
          library.uri.path == "_builtin" &&
          member?.name == "_getMainClosure") {
        // TODO(ahe): https://github.com/dart-lang/sdk/issues/28989
        return astFactory.nullLiteral(token);
      } else {
        return new UnresolvedAccessor(this, n, token);
      }
    } else if (builder.isTypeDeclaration) {
      if (constantExpressionRequired &&
          builder.isTypeVariable &&
          !member.isConstructor) {
        addCompileTimeError(
            offsetForToken(token), "Not a constant expression.");
      }
      return builder;
    } else if (builder.isLocal) {
      if (constantExpressionRequired &&
          !builder.isConst &&
          !member.isConstructor) {
        addCompileTimeError(
            offsetForToken(token), "Not a constant expression.");
      }
      return new VariableAccessor(this, token, builder.target);
    } else if (builder.isInstanceMember) {
      if (constantExpressionRequired &&
          !inInitializer &&
          // TODO(ahe): This is a hack because Fasta sets up the scope
          // "this.field" parameters according to old semantics. Under the new
          // semantics, such parameters introduces a new parameter with that
          // name that should be resolved here.
          !member.isConstructor) {
        addCompileTimeError(
            offsetForToken(token), "Not a constant expression.");
      }
      return new ThisPropertyAccessor(
          this, token, new Name(name, library.library), null, null);
    } else if (builder.isRegularMethod) {
      assert(builder.isStatic || builder.isTopLevel);
      return new StaticAccessor(this, token, builder.target, null);
    } else if (builder is PrefixBuilder) {
      if (constantExpressionRequired && builder.deferred) {
        addCompileTimeError(
            offsetForToken(token),
            "'$name' can't be used in a constant expression because it's "
            "marked as 'deferred' which means it isn't available until "
            "loaded.\n"
            "You might try moving the constant to the deferred library, "
            "or removing 'deferred' from the import.");
      }
      return builder;
    } else {
      if (builder.hasProblem && builder is! AccessErrorBuilder) return builder;
      Builder setter;
      if (builder.isSetter) {
        setter = builder;
      } else if (builder.isGetter) {
        setter = scope.lookupSetter(name, offsetForToken(token), uri);
      } else if (builder.isField && !builder.isFinal) {
        setter = builder;
      }
      StaticAccessor accessor =
          new StaticAccessor.fromBuilder(this, builder, token, setter);
      if (constantExpressionRequired) {
        Member readTarget = accessor.readTarget;
        if (!(readTarget is Field && readTarget.isConst ||
            // Static tear-offs are also compile time constants.
            readTarget is Procedure)) {
          addCompileTimeError(
              offsetForToken(token), "Not a constant expression.");
        }
      }
      return accessor;
    }
  }

  @override
  void handleQualified(Token period) {
    debugEvent("Qualified");
    Identifier name = pop();
    var receiver = pop();
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
      String value = unescapeString(token.lexeme);
      push(astFactory.stringLiteral(value, token));
    } else {
      List parts = popList(1 + interpolationCount * 2);
      Token first = parts.first;
      Token last = parts.last;
      Quote quote = analyzeQuote(first.lexeme);
      List<Expression> expressions = <Expression>[];
      // Contains more than just \' or \".
      if (first.lexeme.length > 1) {
        String value = unescapeFirstStringPart(first.lexeme, quote);
        expressions.add(astFactory.stringLiteral(value, first));
      }
      for (int i = 1; i < parts.length - 1; i++) {
        var part = parts[i];
        if (part is Token) {
          if (part.lexeme.length != 0) {
            String value = unescape(part.lexeme, quote);
            expressions.add(astFactory.stringLiteral(value, part));
          }
        } else {
          expressions.add(toValue(part));
        }
      }
      // Contains more than just \' or \".
      if (last.lexeme.length > 1) {
        String value = unescapeLastStringPart(last.lexeme, quote);
        expressions.add(astFactory.stringLiteral(value, last));
      }
      push(astFactory.stringConcatenation(expressions, endToken));
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
        expressions.addAll(part.expressions);
      } else {
        if (expressions != null) {
          expressions.add(part);
        }
      }
    }
    push(astFactory.stringConcatenation(expressions ?? parts, null));
  }

  @override
  void handleLiteralInt(Token token) {
    debugEvent("LiteralInt");
    push(astFactory.intLiteral(int.parse(token.lexeme), token));
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
      push(buildCompileTimeErrorStatement(
          "Can't return from a constructor.", beginToken.charOffset));
    } else {
      push(new KernelReturnStatement(expression)
        ..fileOffset = beginToken.charOffset);
    }
  }

  @override
  void beginThenStatement(Token token) {
    Expression condition = popForValue();
    typePromoter.enterThen(condition);
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
    Expression condition = popForValue();
    typePromoter.exitConditional();
    push(astFactory.ifStatement(condition, thenPart, elsePart));
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
    pushNewLocalVariable(null);
  }

  void pushNewLocalVariable(Expression initializer, {Token equalsToken}) {
    Identifier identifier = pop();
    assert(currentLocalVariableModifiers != -1);
    bool isConst = (currentLocalVariableModifiers & constMask) != 0;
    bool isFinal = (currentLocalVariableModifiers & finalMask) != 0;
    assert(isConst == constantExpressionRequired);
    push(astFactory.variableDeclaration(
        identifier.name, identifier.token, functionNestingLevel,
        initializer: initializer,
        type: currentLocalVariableType,
        isFinal: isFinal,
        isConst: isConst,
        equalsToken: equalsToken));
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
    if (constantExpressionRequired) {
      addCompileTimeError(
          token.charOffset, "const field must have initializer.");
      // Creating a null value to prevent the Dart VM from crashing.
      push(astFactory.nullLiteral(token));
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
    scope[variable.name] = new KernelVariableBuilder(
        variable, member ?? classBuilder ?? library, uri);
  }

  @override
  void beginVariablesDeclaration(Token token) {
    debugEvent("beginVariablesDeclaration");
    DartType type = pop();
    int modifiers = Modifier.validate(pop());
    super.push(currentLocalVariableModifiers);
    super.push(currentLocalVariableType ?? NullValue.Type);
    currentLocalVariableType = type;
    currentLocalVariableModifiers = modifiers;
    super.push(constantExpressionRequired);
    constantExpressionRequired = (modifiers & constMask) != 0;
  }

  @override
  void endVariablesDeclaration(int count, Token endToken) {
    debugEvent("VariablesDeclaration");
    List<VariableDeclaration> variables = popList(count);
    constantExpressionRequired = pop();
    currentLocalVariableType = pop();
    currentLocalVariableModifiers = pop();
    pop(); // Metadata.
    if (variables.length != 1) {
      push(variables);
    } else {
      push(variables.single);
    }
  }

  @override
  void endBlock(int count, Token beginToken, Token endToken) {
    debugEvent("Block");
    Block block = popBlock(count, beginToken);
    exitLocalScope();
    push(block);
  }

  @override
  void handleAssignmentExpression(Token token) {
    debugEvent("AssignmentExpression");
    Expression value = popForValue();
    var accessor = pop();
    if (accessor is TypeDeclarationBuilder) {
      push(wrapInvalid(astFactory
          .typeLiteral(accessor.buildTypesWithBuiltArguments(library, null))));
    } else if (accessor is! FastaAccessor) {
      push(buildCompileTimeError("Can't assign to this.", token.charOffset));
    } else {
      push(new DelayedAssignment(
          this, token, accessor, value, token.stringValue));
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

  @override
  void endForStatement(Token forKeyword, Token leftSeparator,
      int updateExpressionCount, Token endToken) {
    debugEvent("ForStatement");
    Statement body = popStatement();
    List<Expression> updates = popListForEffect(updateExpressionCount);
    Statement conditionStatement = popStatement();
    Expression condition = null;
    if (conditionStatement is ExpressionStatement) {
      condition = conditionStatement.expression;
    } else {
      assert(conditionStatement is EmptyStatement);
    }
    List<VariableDeclaration> variables = <VariableDeclaration>[];
    dynamic variableOrExpression = pop();
    Statement begin;
    if (variableOrExpression is FastaAccessor) {
      variableOrExpression = variableOrExpression.buildForEffect();
    }
    if (variableOrExpression is VariableDeclaration) {
      variables.add(variableOrExpression);
    } else if (variableOrExpression is List) {
      // TODO(sigmund): remove this assignment (see issue #28651)
      Iterable vars = variableOrExpression;
      variables.addAll(vars);
    } else if (variableOrExpression == null) {
      // Do nothing.
    } else if (variableOrExpression is Expression) {
      begin = astFactory.expressionStatement(variableOrExpression);
    } else {
      return internalError("Unhandled: ${variableOrExpression.runtimeType}");
    }
    exitLocalScope();
    JumpTarget continueTarget = exitContinueTarget();
    JumpTarget breakTarget = exitBreakTarget();
    if (continueTarget.hasUsers) {
      body = new LabeledStatement(body);
      continueTarget.resolveContinues(body);
    }
    Statement result = new ForStatement(variables, condition, updates, body);
    if (begin != null) {
      result = new Block(<Statement>[begin, result]);
    }
    if (breakTarget.hasUsers) {
      result = new LabeledStatement(result);
      breakTarget.resolveBreaks(result);
    }
    exitLoopOrSwitch(result);
  }

  @override
  void endAwaitExpression(Token keyword, Token endToken) {
    debugEvent("AwaitExpression");
    push(astFactory.awaitExpression(keyword, popForValue()));
  }

  @override
  void handleAsyncModifier(Token asyncToken, Token starToken) {
    debugEvent("AsyncModifier");
    push(asyncMarkerFromTokens(asyncToken, starToken));
  }

  @override
  void handleLiteralList(
      int count, Token beginToken, Token constKeyword, Token endToken) {
    debugEvent("LiteralList");
    List<Expression> expressions = popListForValue(count);
    List<DartType> typeArguments = pop();
    DartType typeArgument;
    if (typeArguments != null) {
      typeArgument = typeArguments.first;
      if (typeArguments.length > 1) {
        typeArgument = null;
        warningNotError(
            "Too many type arguments on List literal.", beginToken.charOffset);
      }
    }
    push(astFactory.listLiteral(expressions, typeArgument, constKeyword != null,
        constKeyword ?? beginToken));
  }

  @override
  void handleLiteralBool(Token token) {
    debugEvent("LiteralBool");
    bool value = optional("true", token);
    assert(value || optional("false", token));
    push(astFactory.boolLiteral(value, token));
  }

  @override
  void handleLiteralDouble(Token token) {
    debugEvent("LiteralDouble");
    push(astFactory.doubleLiteral(double.parse(token.lexeme), token));
  }

  @override
  void handleLiteralNull(Token token) {
    debugEvent("LiteralNull");
    push(astFactory.nullLiteral(token));
  }

  @override
  void handleLiteralMap(
      int count, Token beginToken, Token constKeyword, Token endToken) {
    debugEvent("LiteralMap");
    List<MapEntry> entries = popList(count) ?? <MapEntry>[];
    List<DartType> typeArguments = pop();
    DartType keyType = const DynamicType();
    DartType valueType = const DynamicType();
    if (typeArguments != null) {
      if (typeArguments.length != 2) {
        keyType = const DynamicType();
        valueType = const DynamicType();
        warningNotError(
            "Map literal requires two type arguments.", beginToken.charOffset);
      } else {
        keyType = typeArguments[0];
        valueType = typeArguments[1];
      }
    }
    push(astFactory.mapLiteral(beginToken, constKeyword, entries,
        keyType: keyType, valueType: valueType));
  }

  @override
  void endLiteralMapEntry(Token colon, Token endToken) {
    debugEvent("LiteralMapEntry");
    Expression value = popForValue();
    Expression key = popForValue();
    push(new MapEntry(key, value));
  }

  String symbolPartToString(name) {
    if (name is Identifier) {
      return name.name;
    } else if (name is Operator) {
      return name.name;
    } else {
      return internalError("Unhandled: ${name.runtimeType}");
    }
  }

  @override
  void endLiteralSymbol(Token hashToken, int identifierCount) {
    debugEvent("LiteralSymbol");
    String value;
    if (identifierCount == 1) {
      value = symbolPartToString(pop());
    } else {
      List parts = popList(identifierCount);
      value = symbolPartToString(parts.first);
      for (int i = 1; i < parts.length; i++) {
        value += ".${symbolPartToString(parts[i])}";
      }
    }
    push(astFactory.symbolLiteral(hashToken, value));
  }

  DartType kernelTypeFromString(
      String name, List<DartType> arguments, int charOffset) {
    Builder builder = scope.lookup(name, charOffset, uri);
    if (builder == null) {
      warning("Type not found: '$name'.", charOffset);
      return const DynamicType();
    } else {
      return kernelTypeFromBuilder(builder, arguments, charOffset);
    }
  }

  DartType kernelTypeFromBuilder(
      Builder builder, List<DartType> arguments, int charOffset) {
    if (constantExpressionRequired && builder is TypeVariableBuilder) {
      addCompileTimeError(charOffset, "Not a constant expression.");
    }
    if (builder is TypeDeclarationBuilder) {
      return builder.buildTypesWithBuiltArguments(library, arguments);
    } else if (builder.hasProblem) {
      ProblemBuilder problem = builder;
      addCompileTimeError(charOffset, problem.message);
    } else {
      warningNotError(
          "Not a type: '${builder.fullNameForErrors}'.", charOffset);
    }
    // TODO(ahe): Create an error somehow.
    return const DynamicType();
  }

  @override
  void handleType(Token beginToken, Token endToken) {
    // TODO(ahe): The scope is wrong for return types of generic functions.
    debugEvent("Type");
    List<DartType> arguments = pop();
    dynamic name = pop();
    if (name is List) {
      if (name.length != 2) {
        internalError("Unexpected: $name.length");
      }
      var prefix = name[0];
      if (prefix is Identifier) {
        prefix = prefix.name;
      }
      var suffix = name[1];
      if (suffix is Identifier) {
        suffix = suffix.name;
      }
      Builder builder;
      if (prefix is Builder) {
        builder = prefix;
      } else {
        builder = scope.lookup(prefix, beginToken.charOffset, uri);
      }
      if (builder is PrefixBuilder) {
        name = scopeLookup(builder.exports, suffix, beginToken,
            isQualified: true, prefix: builder);
      } else {
        push(const DynamicType());
        addCompileTimeError(beginToken.charOffset,
            "Can't be used as a type: '${debugName(prefix, suffix)}'.");
        return;
      }
    }
    if (name is Identifier) {
      name = name.name;
    }
    if (name is FastaAccessor) {
      warningNotError(
          "'${beginToken.lexeme}' isn't a type.", beginToken.charOffset);
      push(const DynamicType());
    } else if (name is TypeVariableBuilder && !member.isConstructor) {
      if (constantExpressionRequired) {
        addCompileTimeError(
            beginToken.charOffset, "Not a constant expression.");
      }
      push(name.buildTypesWithBuiltArguments(library, arguments));
    } else if (name is TypeDeclarationBuilder) {
      push(name.buildTypesWithBuiltArguments(library, arguments));
    } else if (name is TypeBuilder) {
      push(name.build(library));
    } else if (name is Builder) {
      push(kernelTypeFromBuilder(name, arguments, beginToken.charOffset));
    } else if (name is String) {
      push(kernelTypeFromString(name, arguments, beginToken.charOffset));
    } else {
      internalError("Unhandled: '${name.runtimeType}'.");
    }
    if (peek() is TypeParameterType) {
      TypeParameterType type = peek();
      if (!isInstanceContext && type.parameter.parent is Class) {
        pop();
        warning("Type variables can only be used in instance methods.",
            beginToken.charOffset);
        push(const DynamicType());
      }
    }
  }

  @override
  void handleFunctionType(Token functionToken, Token endToken) {
    debugEvent("FunctionType");
    FormalParameters formals = pop();
    ignore(Unhandled.TypeVariables);
    DartType returnType = pop();
    push(formals.toFunctionType(returnType));
  }

  @override
  void handleVoidKeyword(Token token) {
    debugEvent("VoidKeyword");
    push(const VoidType());
  }

  @override
  void handleAsOperator(Token operator, Token endToken) {
    debugEvent("AsOperator");
    DartType type = pop();
    Expression expression = popForValue();
    push(astFactory.asExpression(expression, operator, type));
  }

  @override
  void handleIsOperator(Token operator, Token not, Token endToken) {
    debugEvent("IsOperator");
    DartType type = pop();
    Expression operand = popForValue();
    bool isInverted = not != null;
    Expression isExpression =
        astFactory.isExpression(operand, type, operator, isInverted);
    if (operand is VariableGet) {
      typePromoter.handleIsCheck(isExpression, isInverted, operand.variable,
          type, functionNestingLevel);
    }
    push(isExpression);
  }

  @override
  void handleConditionalExpression(Token question, Token colon) {
    debugEvent("ConditionalExpression");
    Expression elseExpression = popForValue();
    Expression thenExpression = popForValue();
    Expression condition = popForValue();
    push(astFactory.conditionalExpression(
        condition, thenExpression, elseExpression));
  }

  @override
  void endThrowExpression(Token throwToken, Token endToken) {
    debugEvent("ThrowExpression");
    Expression expression = popForValue();
    if (constantExpressionRequired) {
      push(buildCompileTimeError(
          "Not a constant expression.", throwToken.charOffset));
    } else {
      push(astFactory.throwExpression(throwToken, expression));
    }
  }

  @override
  void endFormalParameter(Token thisKeyword, Token nameToken,
      FormalParameterType kind, MemberKind memberKind) {
    debugEvent("FormalParameter");
    if (thisKeyword != null) {
      if (!inConstructor) {
        addCompileTimeError(thisKeyword.charOffset,
            "'this' parameters can only be used on constructors.");
        thisKeyword = null;
      }
    }
    Identifier name = pop();
    DartType type = pop();
    int modifiers = Modifier.validate(pop());
    if (inCatchClause) {
      modifiers |= finalMask;
    }
    bool isConst = (modifiers & constMask) != 0;
    bool isFinal = (modifiers & finalMask) != 0;
    ignore(Unhandled.Metadata);
    VariableDeclaration variable;
    if (!inCatchClause &&
        functionNestingLevel == 0 &&
        memberKind != MemberKind.GeneralizedFunctionType) {
      dynamic builder = formalParameterScope.lookup(
          name.name, offsetForToken(name.token), uri);
      if (builder == null) {
        if (thisKeyword == null) {
          internalError("Internal error: formal missing for '${name.name}'");
        } else {
          addCompileTimeError(thisKeyword.charOffset,
              "'${name.name}' isn't a field in this class.");
          thisKeyword = null;
        }
      } else if (thisKeyword == null) {
        variable = builder.build(library);
        variable.initializer = name.initializer;
      } else if (builder.isField && builder.parent == classBuilder) {
        FieldBuilder field = builder;
        if (type != null) {
          nit("Ignoring type on 'this' parameter '${name.name}'.",
              thisKeyword.charOffset);
        }
        type = field.target.type;
        variable = astFactory.variableDeclaration(
            name.name, name.token, functionNestingLevel,
            type: type,
            initializer: name.initializer,
            isFinal: isFinal,
            isConst: isConst);
      } else {
        addCompileTimeError(offsetForToken(name.token),
            "'${name.name}' isn't a field in this class.");
      }
    }
    variable ??= astFactory.variableDeclaration(
        name?.name, name?.token, functionNestingLevel,
        type: type,
        initializer: name?.initializer,
        isFinal: isFinal,
        isConst: isConst);
    push(variable);
  }

  @override
  void endOptionalFormalParameters(
      int count, Token beginToken, Token endToken) {
    debugEvent("OptionalFormalParameters");
    FormalParameterType kind = optional("{", beginToken)
        ? FormalParameterType.NAMED
        : FormalParameterType.POSITIONAL;
    push(new OptionalFormals(kind, popList(count) ?? []));
  }

  @override
  void beginFunctionTypedFormalParameter(Token token) {
    debugEvent("beginFunctionTypedFormalParameter");
    functionNestingLevel++;
  }

  @override
  void endFunctionTypedFormalParameter(
      Token thisKeyword, FormalParameterType kind) {
    debugEvent("FunctionTypedFormalParameter");
    if (inCatchClause || functionNestingLevel != 0) {
      exitLocalScope();
    }
    FormalParameters formals = pop();
    ignore(Unhandled.TypeVariables);
    Identifier name = pop();
    DartType returnType = pop();
    push(formals.toFunctionType(returnType));
    push(name);
    functionNestingLevel--;
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
  void endFormalParameters(
      int count, Token beginToken, Token endToken, MemberKind kind) {
    debugEvent("FormalParameters");
    OptionalFormals optional;
    if (count > 0 && peek() is OptionalFormals) {
      optional = pop();
      count--;
    }
    FormalParameters formals = new FormalParameters(
        popList(count) ?? <VariableDeclaration>[],
        optional,
        beginToken.charOffset);
    push(formals);
    if ((inCatchClause || functionNestingLevel != 0) &&
        kind != MemberKind.GeneralizedFunctionType) {
      enterLocalScope(formals.computeFormalParameterScope(
          scope, member ?? classBuilder ?? library));
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
  void handleCatchBlock(Token onKeyword, Token catchKeyword) {
    debugEvent("CatchBlock");
    Block body = pop();
    inCatchBlock = pop();
    if (catchKeyword != null) {
      exitLocalScope();
    }
    FormalParameters catchParameters = popIfNotNull(catchKeyword);
    DartType type = popIfNotNull(onKeyword) ?? const DynamicType();
    VariableDeclaration exception;
    VariableDeclaration stackTrace;
    if (catchParameters != null) {
      if (catchParameters.required.length > 0) {
        exception = catchParameters.required[0];
      }
      if (catchParameters.required.length > 1) {
        stackTrace = catchParameters.required[1];
      }
      if (catchParameters.required.length > 2 ||
          catchParameters.optional != null) {
        body = new Block(<Statement>[new InvalidStatement()]);
        compileTimeErrorInTry ??= buildCompileTimeErrorStatement(
            "Invalid catch arguments.", catchKeyword.next.charOffset);
      }
    }
    push(new Catch(exception, body, guard: type, stackTrace: stackTrace));
  }

  @override
  void endTryStatement(int catchCount, Token tryKeyword, Token finallyKeyword) {
    Statement finallyBlock = popStatementIfNotNull(finallyKeyword);
    List<Catch> catches = popList(catchCount);
    Statement tryBlock = popStatement();
    if (compileTimeErrorInTry == null) {
      if (catches != null) {
        tryBlock = new TryCatch(tryBlock, catches);
      }
      if (finallyBlock != null) {
        tryBlock = new TryFinally(tryBlock, finallyBlock);
      }
      push(tryBlock);
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
      Token openCurlyBracket, Token closeCurlyBracket) {
    debugEvent("IndexedExpression");
    Expression index = popForValue();
    var receiver = pop();
    if (receiver is ThisAccessor && receiver.isSuper) {
      push(new SuperIndexAccessor(this, receiver.token, index,
          lookupSuperMember(indexGetName), lookupSuperMember(indexSetName)));
    } else {
      push(IndexAccessor.make(
          this, openCurlyBracket, toValue(receiver), index, null, null));
    }
  }

  @override
  void handleUnaryPrefixExpression(Token token) {
    debugEvent("UnaryPrefixExpression");
    var receiver = pop();
    if (optional("!", token)) {
      push(astFactory.not(token, toValue(receiver)));
    } else {
      String operator = token.stringValue;
      if (optional("-", token)) {
        operator = "unary-";
      }
      if (receiver is ThisAccessor && receiver.isSuper) {
        push(toSuperMethodInvocation(buildMethodInvocation(
            astFactory,
            astFactory.thisExpression(receiver.token),
            new Name(operator),
            new Arguments.empty(),
            token.charOffset)));
      } else {
        push(buildMethodInvocation(astFactory, toValue(receiver),
            new Name(operator), new Arguments.empty(), token.charOffset));
      }
    }
  }

  Name incrementOperator(Token token) {
    if (optional("++", token)) return plusName;
    if (optional("--", token)) return minusName;
    return internalError("Unknown increment operator: ${token.lexeme}");
  }

  @override
  void handleUnaryPrefixAssignmentExpression(Token token) {
    debugEvent("UnaryPrefixAssignmentExpression");
    var accessor = pop();
    if (accessor is FastaAccessor) {
      push(accessor.buildPrefixIncrement(incrementOperator(token),
          offset: token.charOffset));
    } else {
      push(wrapInvalid(toValue(accessor)));
    }
  }

  @override
  void handleUnaryPostfixAssignmentExpression(Token token) {
    debugEvent("UnaryPostfixAssignmentExpression");
    var accessor = pop();
    if (accessor is FastaAccessor) {
      push(new DelayedPostfixIncrement(
          this, token, accessor, incrementOperator(token), null));
    } else {
      push(wrapInvalid(toValue(accessor)));
    }
  }

  @override
  void endConstructorReference(
      Token start, Token periodBeforeName, Token endToken) {
    debugEvent("ConstructorReference");
    // A constructor reference can contain up to three identifiers:
    //
    //     a) type <type-arguments>?
    //     b) type <type-arguments>? . name
    //     c) prefix . type <type-arguments>?
    //     d) prefix . type <type-arguments>? . name
    //
    // This isn't a legal constructor reference:
    //
    //     type . name <type-arguments>
    //
    // But the parser can't tell this from type c) above.
    //
    // This method pops 2 (or 3 if periodBeforeName != null) values from the
    // stack and pushes 3 values: a type, a list of type arguments, and a name.
    //
    // If the constructor reference can be resolved, type is either a
    // ClassBuilder, or a ThisPropertyAccessor. Otherwise, it's an error that
    // should be handled later.
    Identifier suffix = popIfNotNull(periodBeforeName);
    Identifier identifier;
    List<DartType> typeArguments = pop();
    dynamic type = pop();
    if (type is List) {
      var prefix = type[0];
      identifier = type[1];
      if (prefix is PrefixBuilder) {
        type = scopeLookup(prefix.exports, identifier.name, start,
            isQualified: true, prefix: prefix);
        identifier = null;
      } else if (prefix is ClassBuilder) {
        type = prefix;
      } else {
        type = new Identifier(start);
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
      {bool isConst: false, int charOffset: -1}) {
    List<TypeParameter> typeParameters = target.function.typeParameters;
    if (target is Constructor) {
      assert(!target.enclosingClass.isAbstract);
      typeParameters = target.enclosingClass.typeParameters;
    }
    if (!checkArguments(target.function, arguments, typeParameters)) {
      return throwNoSuchMethodError(target.name.name, arguments, charOffset);
    }
    if (target is Constructor) {
      return astFactory.constructorInvocation(target, arguments,
          isConst: isConst)
        ..fileOffset = charOffset;
    } else {
      return astFactory.staticInvocation(target, arguments, isConst: isConst)
        ..fileOffset = charOffset;
    }
  }

  @override
  bool checkArguments(FunctionNode function, Arguments arguments,
      List<TypeParameter> typeParameters) {
    if (arguments.positional.length < function.requiredParameterCount ||
        arguments.positional.length > function.positionalParameters.length) {
      return false;
    }
    Map<String, VariableDeclaration> names;
    if (function.namedParameters.isNotEmpty) {
      names = <String, VariableDeclaration>{};
      for (VariableDeclaration parameter in function.namedParameters) {
        names[parameter.name] = parameter;
      }
    }
    if (arguments.named.isNotEmpty) {
      if (names == null) return false;
      for (NamedExpression argument in arguments.named) {
        VariableDeclaration parameter = names.remove(argument.name);
        if (parameter == null) {
          return false;
        }
      }
    }
    if (typeParameters.length != arguments.types.length) {
      arguments.types.clear();
      for (int i = 0; i < typeParameters.length; i++) {
        arguments.types.add(const DynamicType());
      }
    }

    return true;
  }

  @override
  void beginNewExpression(Token token) {
    debugEvent("beginNewExpression");
    super.push(constantExpressionRequired);
    if (constantExpressionRequired) {
      addCompileTimeError(token.charOffset, "Not a constant expression.");
    }
    constantExpressionRequired = false;
  }

  @override
  void beginConstExpression(Token token) {
    debugEvent("beginConstExpression");
    super.push(constantExpressionRequired);
    constantExpressionRequired = true;
  }

  @override
  void beginConstLiteral(Token token) {
    debugEvent("beginConstLiteral");
    super.push(constantExpressionRequired);
    constantExpressionRequired = true;
  }

  @override
  void endConstLiteral(Token token) {
    debugEvent("endConstLiteral");
    var literal = pop();
    constantExpressionRequired = pop();
    push(literal);
  }

  @override
  void endNewExpression(Token token) {
    debugEvent("NewExpression");
    Token nameToken = token.next;
    KernelArguments arguments = pop();
    String name = pop();
    List<DartType> typeArguments = pop();
    var type = pop();
    bool savedConstantExpressionRequired = pop();
    () {
      if (arguments == null) {
        push(buildCompileTimeError("No arguments.", nameToken.charOffset));
        return;
      }

      if (typeArguments != null) {
        assert(arguments.types.isEmpty);
        astFactory.setExplicitArgumentTypes(arguments, typeArguments);
      }

      String errorName;
      if (type is ClassBuilder) {
        Builder b = type.findConstructorOrFactory(name, token.charOffset, uri);
        Member target;
        if (b == null) {
          // Not found. Reported below.
        } else if (b.isConstructor) {
          if (type.isAbstract) {
            push(evaluateArgumentsBefore(
                arguments,
                buildAbstractClassInstantiationError(
                    type.name, nameToken.charOffset)));
            return;
          } else {
            target = b.target;
          }
        } else if (b.isFactory) {
          target = getRedirectionTarget(b.target);
          if (target == null) {
            push(buildCompileTimeError(
                "Cyclic definition of factory '${name}'.",
                nameToken.charOffset));
            return;
          }
        }
        if (target is Constructor ||
            (target is Procedure && target.kind == ProcedureKind.Factory)) {
          push(buildStaticInvocation(target, arguments,
              isConst: optional("const", token),
              charOffset: nameToken.charOffset));
          return;
        } else {
          errorName = debugName(type.name, name);
        }
      } else {
        errorName = debugName(getNodeName(type), name);
      }
      errorName ??= name;
      push(throwNoSuchMethodError(errorName, arguments, nameToken.charOffset));
    }();
    constantExpressionRequired = savedConstantExpressionRequired;
  }

  @override
  void endConstExpression(Token token) {
    debugEvent("endConstExpression");
    endNewExpression(token);
  }

  @override
  void endTypeArguments(int count, Token beginToken, Token endToken) {
    debugEvent("TypeArguments");
    push(popList(count));
  }

  @override
  void handleThisExpression(Token token, IdentifierContext context) {
    debugEvent("ThisExpression");
    if (context.isScopeReference && isInstanceContext) {
      push(new ThisAccessor(this, token, inInitializer));
    } else {
      push(new IncompleteError(
          this, token, "Expected identifier, but got 'this'."));
    }
  }

  @override
  void handleSuperExpression(Token token, IdentifierContext context) {
    debugEvent("SuperExpression");
    if (context.isScopeReference && isInstanceContext) {
      Member member = this.member.target;
      member.transformerFlags |= TransformerFlag.superCalls;
      push(new ThisAccessor(this, token, inInitializer, isSuper: true));
    } else {
      push(new IncompleteError(
          this, token, "Expected identifier, but got 'super'."));
    }
  }

  @override
  void handleNamedArgument(Token colon) {
    debugEvent("NamedArgument");
    Expression value = popForValue();
    Identifier identifier = pop();
    push(new NamedExpression(identifier.name, value));
  }

  @override
  void endFunctionName(Token beginToken, Token token) {
    debugEvent("FunctionName");
    Identifier name = pop();
    VariableDeclaration variable = astFactory.variableDeclaration(
        name.name, name.token, functionNestingLevel,
        isFinal: true, isLocalFunction: true);
    push(new KernelFunctionDeclaration(
        variable, new FunctionNode(new InvalidStatement()))
      ..fileOffset = beginToken.charOffset);
    scope[variable.name] = new KernelVariableBuilder(
        variable, member ?? classBuilder ?? library, uri);
    enterLocalScope();
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
  }

  @override
  void beginFunction(Token token) {
    debugEvent("beginFunction");
    enterFunction();
  }

  @override
  void beginUnnamedFunction(Token token) {
    debugEvent("beginUnnamedFunction");
    enterFunction();
  }

  @override
  void endFunction(Token getOrSet, Token endToken) {
    debugEvent("Function");
    Statement body = popStatement();
    AsyncMarker asyncModifier = pop();
    if (functionNestingLevel != 0) {
      exitLocalScope();
    }
    FormalParameters formals = pop();
    List<TypeParameter> typeParameters = pop();
    push(formals.addToFunction(new FunctionNode(body,
        typeParameters: typeParameters, asyncMarker: asyncModifier)
      ..fileOffset = formals.charOffset
      ..fileEndOffset = endToken.charOffset));
  }

  @override
  void endFunctionDeclaration(Token token) {
    debugEvent("FunctionDeclaration");
    FunctionNode function = pop();
    exitLocalScope();
    FunctionDeclaration declaration = pop();
    function.returnType = pop() ?? const DynamicType();
    declaration.variable.type = function.functionType;
    pop(); // Modifiers.
    exitFunction();
    declaration.function = function;
    function.parent = declaration;
    push(declaration);
  }

  @override
  void endUnnamedFunction(Token beginToken, Token token) {
    debugEvent("UnnamedFunction");
    Statement body = popStatement();
    AsyncMarker asyncModifier = pop();
    exitLocalScope();
    FormalParameters formals = pop();
    exitFunction();
    List<TypeParameter> typeParameters = pop();
    FunctionNode function = formals.addToFunction(new FunctionNode(body,
        typeParameters: typeParameters, asyncMarker: asyncModifier)
      ..fileOffset = beginToken.charOffset
      ..fileEndOffset = token.charOffset);
    push(astFactory.functionExpression(function, beginToken));
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
      body = new LabeledStatement(body);
      continueTarget.resolveContinues(body);
    }
    Statement result = new DoStatement(body, condition);
    if (breakTarget.hasUsers) {
      result = new LabeledStatement(result);
      breakTarget.resolveBreaks(result);
    }
    exitLoopOrSwitch(result);
  }

  @override
  void beginForInExpression(Token token) {
    enterLocalScope(scope.parent);
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
      Token inKeyword, Token rightParenthesis, Token endToken) {
    debugEvent("ForIn");
    Statement body = popStatement();
    Expression expression = popForValue();
    var lvalue = pop();
    exitLocalScope();
    JumpTarget continueTarget = exitContinueTarget();
    JumpTarget breakTarget = exitBreakTarget();
    if (continueTarget.hasUsers) {
      body = new LabeledStatement(body);
      continueTarget.resolveContinues(body);
    }
    VariableDeclaration variable;
    if (lvalue is VariableDeclaration) {
      variable = lvalue;
    } else if (lvalue is FastaAccessor) {
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
      variable = new VariableDeclaration.forValue(null);
      body = combineStatements(
          astFactory.expressionStatement(lvalue
              .buildAssignment(new VariableGet(variable), voidContext: true)),
          body);
    } else {
      variable = new VariableDeclaration.forValue(buildCompileTimeError(
          "Expected lvalue, but got ${lvalue}", forToken.next.next.charOffset));
    }
    Statement result = new ForInStatement(variable, expression, body,
        isAsync: awaitToken != null)
      ..fileOffset = body.fileOffset;
    if (breakTarget.hasUsers) {
      result = new LabeledStatement(result);
      breakTarget.resolveBreaks(result);
    }
    exitLoopOrSwitch(result);
  }

  @override
  void handleLabel(Token token) {
    debugEvent("Label");
    Identifier identifier = pop();
    push(new Label(identifier.name));
  }

  @override
  void beginLabeledStatement(Token token, int labelCount) {
    debugEvent("beginLabeledStatement");
    List<Label> labels = popList(labelCount);
    enterLocalScope(scope.createNestedLabelScope());
    LabelTarget target =
        new LabelTarget(member, functionNestingLevel, token.charOffset);
    for (Label label in labels) {
      scope.declareLabel(label.name, target);
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
        statement = new LabeledStatement(statement);
      }
      target.breakTarget.resolveBreaks(statement);
    }
    if (target.continueTarget.hasUsers) {
      if (statement is! LabeledStatement) {
        statement = new LabeledStatement(statement);
      }
      target.continueTarget.resolveContinues(statement);
    }
    push(statement);
  }

  @override
  void endRethrowStatement(Token rethrowToken, Token endToken) {
    debugEvent("RethrowStatement");
    if (inCatchBlock) {
      push(astFactory
          .expressionStatement(astFactory.rethrowExpression(rethrowToken)));
    } else {
      push(buildCompileTimeErrorStatement(
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
      body = new LabeledStatement(body);
      continueTarget.resolveContinues(body);
    }
    Statement result = new WhileStatement(condition, body);
    if (breakTarget.hasUsers) {
      result = new LabeledStatement(result);
      breakTarget.resolveBreaks(result);
    }
    exitLoopOrSwitch(result);
  }

  @override
  void handleEmptyStatement(Token token) {
    debugEvent("EmptyStatement");
    push(new EmptyStatement());
  }

  @override
  void handleAssertStatement(Token assertKeyword, Token leftParenthesis,
      Token commaToken, Token rightParenthesis, Token semicolonToken) {
    debugEvent("AssertStatement");
    Expression message = popForValueIfNotNull(commaToken);
    Expression condition = popForValue();
    push(new AssertStatement(condition, message));
  }

  @override
  void endYieldStatement(Token yieldToken, Token starToken, Token endToken) {
    debugEvent("YieldStatement");
    push(new KernelYieldStatement(popForValue(), isYieldStar: starToken != null)
      ..fileOffset = yieldToken.charOffset);
  }

  @override
  void beginSwitchBlock(Token token) {
    debugEvent("beginSwitchBlock");
    enterLocalScope();
    enterSwitchScope();
    enterBreakTarget(token.charOffset);
  }

  @override
  void beginSwitchCase(int labelCount, int expressionCount, Token firstToken) {
    debugEvent("beginSwitchCase");
    List labelsAndExpressions = popList(labelCount + expressionCount);
    List<Label> labels = <Label>[];
    List<Expression> expressions = <Expression>[];
    if (labelsAndExpressions != null) {
      for (var labelOrExpression in labelsAndExpressions) {
        if (labelOrExpression is Label) {
          labels.add(labelOrExpression);
        } else {
          expressions.add(toValue(labelOrExpression));
        }
      }
    }
    assert(scope == switchScope);
    for (Label label in labels) {
      if (scope.hasLocalLabel(label.name)) {
        // TODO(ahe): Should validate this is a goto target and not duplicated.
        scope.claimLabel(label.name);
      } else {
        scope.declareLabel(label.name, createGotoTarget(firstToken.charOffset));
      }
    }
    push(expressions);
    push(labels);
    enterLocalScope();
  }

  @override
  void handleSwitchCase(
      int labelCount,
      int expressionCount,
      Token defaultKeyword,
      int statementCount,
      Token firstToken,
      Token endToken) {
    debugEvent("SwitchCase");
    Block block = popBlock(statementCount, firstToken);
    exitLocalScope();
    List<Label> labels = pop();
    List<Expression> expressions = pop();
    List<int> expressionOffsets = <int>[];
    for (Expression expression in expressions) {
      expressionOffsets.add(expression.fileOffset);
    }
    push(new SwitchCase(expressions, expressionOffsets, block,
        isDefault: defaultKeyword != null)
      ..fileOffset = firstToken.charOffset);
    push(labels);
  }

  @override
  void endSwitchStatement(Token switchKeyword, Token endToken) {
    debugEvent("SwitchStatement");
    // Do nothing. Handled by [endSwitchBlock].
  }

  @override
  void endSwitchBlock(int caseCount, Token beginToken, Token endToken) {
    debugEvent("SwitchBlock");
    List<SwitchCase> cases =
        new List<SwitchCase>.filled(caseCount, null, growable: true);
    for (int i = caseCount - 1; i >= 0; i--) {
      List<Label> labels = pop();
      SwitchCase current = cases[i] = pop();
      for (Label label in labels) {
        JumpTarget target = switchScope.lookupLabel(label.name);
        if (target != null) {
          target.resolveGotos(current);
        }
      }
      // TODO(ahe): Validate that there's only one default and it's last.
    }
    JumpTarget target = exitBreakTarget();
    exitSwitchScope();
    exitLocalScope();
    Expression expression = popForValue();
    Statement result = new SwitchStatement(expression, cases);
    if (target.hasUsers) {
      result = new LabeledStatement(result);
      target.resolveBreaks(result);
    }
    exitLoopOrSwitch(result);
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
    var target = breakTarget;
    String name;
    if (hasTarget) {
      Identifier identifier = pop();
      name = identifier.name;
      target = scope.lookupLabel(identifier.name);
    }
    if (target == null && name == null) {
      push(compileTimeErrorInLoopOrSwitch = buildCompileTimeErrorStatement(
          "No target of break.", breakKeyword.charOffset));
    } else if (target == null ||
        target is! JumpTarget ||
        !target.isBreakTarget) {
      push(compileTimeErrorInLoopOrSwitch = buildCompileTimeErrorStatement(
          "Can't break to '$name'.", breakKeyword.next.charOffset));
    } else if (target.functionNestingLevel != functionNestingLevel) {
      push(compileTimeErrorInLoopOrSwitch = buildCompileTimeErrorStatement(
          "Can't break to '$name' in a different function.",
          breakKeyword.next.charOffset));
    } else {
      BreakStatement statement = new BreakStatement(null)
        ..fileOffset = breakKeyword.charOffset;
      target.addBreak(statement);
      push(statement);
    }
  }

  @override
  void handleContinueStatement(
      bool hasTarget, Token continueKeyword, Token endToken) {
    debugEvent("ContinueStatement");
    var target = continueTarget;
    String name;
    if (hasTarget) {
      Identifier identifier = pop();
      name = identifier.name;
      target = scope.lookupLabel(identifier.name);
      if (target != null && target is! JumpTarget) {
        push(compileTimeErrorInLoopOrSwitch = buildCompileTimeErrorStatement(
            "Target of continue must be a label.", continueKeyword.charOffset));
        return;
      }
      if (target == null) {
        if (switchScope == null) {
          push(buildCompileTimeErrorStatement(
              "Can't find label '$name'.", continueKeyword.next.charOffset));
          return;
        }
        switchScope.forwardDeclareLabel(identifier.name,
            target = createGotoTarget(offsetForToken(identifier.token)));
      }
      if (target.isGotoTarget &&
          target.functionNestingLevel == functionNestingLevel) {
        ContinueSwitchStatement statement = new ContinueSwitchStatement(null);
        target.addGoto(statement);
        push(statement);
        return;
      }
    }
    if (target == null) {
      push(compileTimeErrorInLoopOrSwitch = buildCompileTimeErrorStatement(
          "No target of continue.", continueKeyword.charOffset));
    } else if (!target.isContinueTarget) {
      push(compileTimeErrorInLoopOrSwitch = buildCompileTimeErrorStatement(
          "Can't continue at '$name'.", continueKeyword.next.charOffset));
    } else if (target.functionNestingLevel != functionNestingLevel) {
      push(compileTimeErrorInLoopOrSwitch = buildCompileTimeErrorStatement(
          "Can't continue at '$name' in a different function.",
          continueKeyword.next.charOffset));
    } else {
      BreakStatement statement = new BreakStatement(null)
        ..fileOffset = continueKeyword.charOffset;
      target.addContinue(statement);
      push(statement);
    }
  }

  @override
  void endTypeVariable(Token token, Token extendsOrSuper) {
    debugEvent("TypeVariable");
    // TODO(ahe): Do not discard these when enabling generic method syntax.
    pop(); // Bound.
    pop(); // Name.
    pop(); // Metadata.
  }

  @override
  void endTypeVariables(int count, Token beginToken, Token endToken) {
    debugEvent("TypeVariables");
    // TODO(ahe): Implement this when enabling generic method syntax.
    push(NullValue.TypeVariables);
  }

  @override
  void handleModifier(Token token) {
    debugEvent("Modifier");
    // TODO(ahe): Copied from outline_builder.dart.
    push(new Modifier.fromString(token.stringValue));
  }

  @override
  void handleModifiers(int count) {
    debugEvent("Modifiers");
    // TODO(ahe): Copied from outline_builder.dart.
    push(popList(count) ?? NullValue.Modifiers);
  }

  @override
  void handleRecoverableError(Token token, FastaMessage message) {
    bool silent = hasParserError;
    addCompileTimeError(message.charOffset, message.message, silent: silent);
  }

  @override
  Token handleUnrecoverableError(Token token, FastaMessage message) {
    if (isDartLibrary && message.code == codeExpectedFunctionBody) {
      Token recover = library.loader.target.skipNativeClause(token);
      if (recover != null) return recover;
    } else if (message.code == codeExpectedButGot) {
      String expected = message.arguments["string"];
      const List<String> trailing = const <String>[")", "}", ";", ","];
      if (trailing.contains(token.stringValue) && trailing.contains(expected)) {
        handleRecoverableError(token, message);
        return newSyntheticToken(token);
      }
    }
    return super.handleUnrecoverableError(token, message);
  }

  @override
  Expression buildCompileTimeError(error, [int charOffset = -1]) {
    addCompileTimeError(charOffset, error);
    String message = formatUnexpected(uri, charOffset, error);
    Builder constructor = library.loader.getCompileTimeError();
    return new Throw(buildStaticInvocation(constructor.target,
        astFactory.arguments(<Expression>[new StringLiteral(message)])));
  }

  Expression buildAbstractClassInstantiationError(String className,
      [int charOffset = -1]) {
    warning("The class '$className' is abstract and can't be instantiated.",
        charOffset);
    Builder constructor = library.loader.getAbstractClassInstantiationError();
    return new Throw(buildStaticInvocation(constructor.target,
        astFactory.arguments(<Expression>[new StringLiteral(className)])));
  }

  Statement buildCompileTimeErrorStatement(error, [int charOffset = -1]) {
    return astFactory
        .expressionStatement(buildCompileTimeError(error, charOffset));
  }

  @override
  Initializer buildInvalidIntializer(Expression expression,
      [int charOffset = -1]) {
    needsImplicitSuperInitializer = false;
    return new LocalInitializer(new VariableDeclaration.forValue(expression))
      ..fileOffset = charOffset;
  }

  @override
  Initializer buildSuperInitializer(
      Constructor constructor, Arguments arguments,
      [int charOffset = -1]) {
    needsImplicitSuperInitializer = false;
    return new SuperInitializer(constructor, arguments)
      ..fileOffset = charOffset;
  }

  @override
  Initializer buildRedirectingInitializer(
      Constructor constructor, Arguments arguments,
      [int charOffset = -1]) {
    needsImplicitSuperInitializer = false;
    return new RedirectingInitializer(constructor, arguments)
      ..fileOffset = charOffset;
  }

  @override
  Expression buildProblemExpression(ProblemBuilder builder, int charOffset) {
    return buildCompileTimeError(builder.message, charOffset);
  }

  @override
  void handleOperator(Token token) {
    debugEvent("Operator");
    push(new Operator(token.stringValue)..fileOffset = token.charOffset);
  }

  @override
  void handleSymbolVoid(Token token) {
    debugEvent("SymbolVoid");
    push(new Identifier(token));
  }

  dynamic addCompileTimeError(int charOffset, String message,
      {bool silent: false}) {
    // TODO(ahe): If constantExpressionRequired is set, set it to false to
    // avoid a long list of errors.
    return library.addCompileTimeError(charOffset, message, fileUri: uri);
  }

  @override
  void handleInvalidFunctionBody(Token token) {
    if (member.isNative) {
      push(NullValue.FunctionBody);
    } else {
      push(new Block(<Statement>[new InvalidStatement()]));
    }
  }

  @override
  void warning(String message, [int charOffset = -1]) {
    if (constantExpressionRequired) {
      addCompileTimeError(charOffset, message);
    } else {
      super.warning(message, charOffset);
    }
  }

  void warningNotError(String message, [int charOffset = -1]) {
    super.warning(message, charOffset);
  }

  Expression evaluateArgumentsBefore(
      Arguments arguments, Expression expression) {
    if (arguments == null) return expression;
    List<Expression> expressions =
        new List<Expression>.from(arguments.positional);
    for (NamedExpression named in arguments.named) {
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
  void debugEvent(String name) {
    // printEvent(name);
  }

  @override
  StaticGet makeStaticGet(Member readTarget, Token token) {
    // TODO(paulberry): only record the dependencies mandated by the top level
    // type inference spec.
    if (fieldDependencies != null && readTarget is KernelField) {
      var fieldNode = _typeInferrer.getFieldNodeForReadTarget(readTarget);
      if (fieldNode != null) {
        fieldDependencies.add(fieldNode);
      }
    }
    return astFactory.staticGet(readTarget, token);
  }
}

class Identifier {
  final Token token;
  String get name => token.lexeme;

  Identifier(this.token);

  Expression get initializer => null;

  String toString() => "identifier($name)";
}

// TODO(ahe): Shouldn't need to be an expression.
class Operator extends InvalidExpression {
  final String name;

  Operator(this.name);

  String toString() => "operator($name)";
}

class InitializedIdentifier extends Identifier {
  final Expression initializer;

  InitializedIdentifier(Token token, this.initializer) : super(token);

  String toString() => "initialized-identifier($name, $initializer)";
}

// TODO(ahe): Shouldn't need to be an expression.
class Label extends InvalidExpression {
  String name;

  Label(this.name);

  String toString() => "label($name)";
}

class CascadeReceiver extends Let {
  Let nextCascade;

  CascadeReceiver(VariableDeclaration variable)
      : super(
            variable,
            makeLet(new VariableDeclaration.forValue(new InvalidExpression()),
                new VariableGet(variable))) {
    nextCascade = body;
  }

  void extend() {
    assert(nextCascade.variable.initializer is! InvalidExpression);
    Let newCascade = makeLet(
        new VariableDeclaration.forValue(new InvalidExpression()),
        nextCascade.body);
    nextCascade.body = newCascade;
    newCascade.parent = nextCascade;
    nextCascade = newCascade;
  }

  void finalize(Expression expression) {
    assert(nextCascade.variable.initializer is InvalidExpression);
    nextCascade.variable.initializer = expression;
    expression.parent = nextCascade.variable;
  }
}

abstract class ContextAccessor extends FastaAccessor {
  final BuilderHelper helper;

  final FastaAccessor accessor;

  final Token token;

  ContextAccessor(this.helper, this.token, this.accessor);

  @override
  Expression get builtBinary => internalError("Unsupported operation.");

  @override
  void set builtBinary(Expression expression) {
    internalError("Unsupported operation.");
  }

  @override
  Expression get builtGetter => internalError("Unsupported operation.");

  @override
  void set builtGetter(Expression expression) {
    internalError("Unsupported operation.");
  }

  String get plainNameForRead => internalError("Unsupported operation.");

  Expression doInvocation(int charOffset, Arguments arguments) {
    return internalError("Unhandled: ${runtimeType}", uri, charOffset);
  }

  Expression buildSimpleRead();

  Expression buildForEffect();

  Expression buildAssignment(Expression value, {bool voidContext: false}) {
    return makeInvalidWrite(value);
  }

  Expression buildNullAwareAssignment(Expression value, DartType type,
      {bool voidContext: false}) {
    return makeInvalidWrite(value);
  }

  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      Procedure interfaceTarget}) {
    return makeInvalidWrite(value);
  }

  Expression buildPrefixIncrement(Name binaryOperator,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      Procedure interfaceTarget}) {
    return makeInvalidWrite(null);
  }

  Expression buildPostfixIncrement(Name binaryOperator,
      {int offset: TreeNode.noOffset,
      bool voidContext: false,
      Procedure interfaceTarget}) {
    return makeInvalidWrite(null);
  }

  makeInvalidRead() => internalError("not supported");

  Expression makeInvalidWrite(Expression value) {
    return helper.buildCompileTimeError(
        "Can't be used as left-hand side of assignment.",
        offsetForToken(token));
  }
}

class DelayedAssignment extends ContextAccessor {
  final Expression value;

  final String assignmentOperator;

  DelayedAssignment(BuilderHelper helper, Token token, FastaAccessor accessor,
      this.value, this.assignmentOperator)
      : super(helper, token, accessor);

  Expression buildSimpleRead() {
    return handleAssignment(false);
  }

  Expression buildForEffect() {
    return handleAssignment(true);
  }

  Expression handleAssignment(bool voidContext) {
    if (identical("=", assignmentOperator)) {
      return accessor.buildAssignment(value, voidContext: voidContext);
    } else if (identical("+=", assignmentOperator)) {
      return accessor.buildCompoundAssignment(plusName, value,
          offset: offsetForToken(token), voidContext: voidContext);
    } else if (identical("-=", assignmentOperator)) {
      return accessor.buildCompoundAssignment(minusName, value,
          offset: offsetForToken(token), voidContext: voidContext);
    } else if (identical("*=", assignmentOperator)) {
      return accessor.buildCompoundAssignment(multiplyName, value,
          offset: offsetForToken(token), voidContext: voidContext);
    } else if (identical("%=", assignmentOperator)) {
      return accessor.buildCompoundAssignment(percentName, value,
          offset: offsetForToken(token), voidContext: voidContext);
    } else if (identical("&=", assignmentOperator)) {
      return accessor.buildCompoundAssignment(ampersandName, value,
          offset: offsetForToken(token), voidContext: voidContext);
    } else if (identical("/=", assignmentOperator)) {
      return accessor.buildCompoundAssignment(divisionName, value,
          offset: offsetForToken(token), voidContext: voidContext);
    } else if (identical("<<=", assignmentOperator)) {
      return accessor.buildCompoundAssignment(leftShiftName, value,
          offset: offsetForToken(token), voidContext: voidContext);
    } else if (identical(">>=", assignmentOperator)) {
      return accessor.buildCompoundAssignment(rightShiftName, value,
          offset: offsetForToken(token), voidContext: voidContext);
    } else if (identical("??=", assignmentOperator)) {
      return accessor.buildNullAwareAssignment(value, const DynamicType(),
          voidContext: voidContext);
    } else if (identical("^=", assignmentOperator)) {
      return accessor.buildCompoundAssignment(caretName, value,
          offset: offsetForToken(token), voidContext: voidContext);
    } else if (identical("|=", assignmentOperator)) {
      return accessor.buildCompoundAssignment(barName, value,
          offset: offsetForToken(token), voidContext: voidContext);
    } else if (identical("~/=", assignmentOperator)) {
      return accessor.buildCompoundAssignment(mustacheName, value,
          offset: offsetForToken(token), voidContext: voidContext);
    } else {
      return internalError("Unhandled: $assignmentOperator");
    }
  }

  Initializer buildFieldInitializer(
      Map<String, FieldInitializer> initializers) {
    if (!identical("=", assignmentOperator) ||
        !accessor.isThisPropertyAccessor) {
      return accessor.buildFieldInitializer(initializers);
    }
    String name = accessor.plainNameForRead;
    FieldInitializer initializer = initializers[name];
    if (initializer != null && initializer.value == null) {
      initializers.remove(name);
      initializer.value = value..parent = initializer;
      return initializer;
    }
    return accessor.buildFieldInitializer(initializers);
  }
}

class DelayedPostfixIncrement extends ContextAccessor {
  final Name binaryOperator;

  final Procedure interfaceTarget;

  DelayedPostfixIncrement(BuilderHelper helper, Token token,
      FastaAccessor accessor, this.binaryOperator, this.interfaceTarget)
      : super(helper, token, accessor);

  Expression buildSimpleRead() {
    return accessor.buildPostfixIncrement(binaryOperator,
        offset: offsetForToken(token),
        voidContext: false,
        interfaceTarget: interfaceTarget);
  }

  Expression buildForEffect() {
    return accessor.buildPostfixIncrement(binaryOperator,
        offset: offsetForToken(token),
        voidContext: true,
        interfaceTarget: interfaceTarget);
  }
}

class JumpTarget extends Builder {
  final List<Statement> users = <Statement>[];

  final JumpTargetKind kind;

  final int functionNestingLevel;

  JumpTarget(this.kind, this.functionNestingLevel, MemberBuilder member,
      int charOffset)
      : super(member, charOffset, member.fileUri);

  bool get isBreakTarget => kind == JumpTargetKind.Break;

  bool get isContinueTarget => kind == JumpTargetKind.Continue;

  bool get isGotoTarget => kind == JumpTargetKind.Goto;

  bool get hasUsers => users.isNotEmpty;

  void addBreak(BreakStatement statement) {
    assert(isBreakTarget);
    users.add(statement);
  }

  void addContinue(BreakStatement statement) {
    assert(isContinueTarget);
    users.add(statement);
  }

  void addGoto(ContinueSwitchStatement statement) {
    assert(isGotoTarget);
    users.add(statement);
  }

  void resolveBreaks(LabeledStatement target) {
    assert(isBreakTarget);
    for (BreakStatement user in users) {
      user.target = target;
    }
    users.clear();
  }

  void resolveContinues(LabeledStatement target) {
    assert(isContinueTarget);
    for (BreakStatement user in users) {
      user.target = target;
    }
    users.clear();
  }

  void resolveGotos(SwitchCase target) {
    assert(isGotoTarget);
    for (ContinueSwitchStatement user in users) {
      user.target = target;
    }
    users.clear();
  }

  @override
  String get fullNameForErrors => "<jump-target>";
}

class LabelTarget extends Builder implements JumpTarget {
  final JumpTarget breakTarget;

  final JumpTarget continueTarget;

  final int functionNestingLevel;

  LabelTarget(MemberBuilder member, this.functionNestingLevel, int charOffset)
      : breakTarget = new JumpTarget(
            JumpTargetKind.Break, functionNestingLevel, member, charOffset),
        continueTarget = new JumpTarget(
            JumpTargetKind.Continue, functionNestingLevel, member, charOffset),
        super(member, charOffset, member.fileUri);

  bool get hasUsers => breakTarget.hasUsers || continueTarget.hasUsers;

  List<Statement> get users => internalError("Unsupported operation.");

  JumpTargetKind get kind => internalError("Unsupported operation.");

  bool get isBreakTarget => true;

  bool get isContinueTarget => true;

  bool get isGotoTarget => false;

  void addBreak(BreakStatement statement) {
    breakTarget.addBreak(statement);
  }

  void addContinue(BreakStatement statement) {
    continueTarget.addContinue(statement);
  }

  void addGoto(ContinueSwitchStatement statement) {
    internalError("Unsupported operation.");
  }

  void resolveBreaks(LabeledStatement target) {
    breakTarget.resolveBreaks(target);
  }

  void resolveContinues(LabeledStatement target) {
    continueTarget.resolveContinues(target);
  }

  void resolveGotos(SwitchCase target) {
    internalError("Unsupported operation.");
  }

  @override
  String get fullNameForErrors => "<label-target>";
}

class OptionalFormals {
  final FormalParameterType kind;

  final List<VariableDeclaration> formals;

  OptionalFormals(this.kind, this.formals);
}

class FormalParameters {
  final List<VariableDeclaration> required;
  final OptionalFormals optional;
  final int charOffset;

  FormalParameters(this.required, this.optional, this.charOffset);

  FunctionNode addToFunction(FunctionNode function) {
    function.requiredParameterCount = required.length;
    function.positionalParameters.addAll(required);
    if (optional != null) {
      if (optional.kind.isPositional) {
        function.positionalParameters.addAll(optional.formals);
      } else {
        function.namedParameters.addAll(optional.formals);
        setParents(function.namedParameters, function);
      }
    }
    setParents(function.positionalParameters, function);
    return function;
  }

  FunctionType toFunctionType(DartType returnType) {
    returnType ??= const DynamicType();
    int requiredParameterCount = required.length;
    List<DartType> positionalParameters = <DartType>[];
    List<NamedType> namedParameters = const <NamedType>[];
    for (VariableDeclaration parameter in required) {
      positionalParameters.add(parameter.type);
    }
    if (optional != null) {
      if (optional.kind.isPositional) {
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
        requiredParameterCount: requiredParameterCount);
  }

  Scope computeFormalParameterScope(Scope parent, Builder builder) {
    if (required.length == 0 && optional == null) return parent;
    Map<String, Builder> local = <String, Builder>{};
    for (VariableDeclaration parameter in required) {
      local[parameter.name] =
          new KernelVariableBuilder(parameter, builder, builder.fileUri);
    }
    if (optional != null) {
      for (VariableDeclaration parameter in optional.formals) {
        local[parameter.name] =
            new KernelVariableBuilder(parameter, builder, builder.fileUri);
      }
    }
    return new Scope(local, null, parent, isModifiable: false);
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
  } else if (node is TypeDeclarationBuilder) {
    return node.name;
  } else if (node is PrefixBuilder) {
    return node.name;
  } else if (node is ThisAccessor) {
    return node.isSuper ? "super" : "this";
  } else if (node is FastaAccessor) {
    return node.plainNameForRead;
  } else {
    return internalError("Unhandled: ${node.runtimeType}");
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
    return internalError("Unknown async modifier: $asyncToken");
  }
}
