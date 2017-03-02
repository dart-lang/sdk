// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.body_builder;

import '../parser/parser.dart' show FormalParameterType, optional;

import '../parser/error_kind.dart' show ErrorKind;

import '../parser/identifier_context.dart' show IdentifierContext;

import 'package:kernel/ast.dart';

import 'package:kernel/clone.dart' show CloneVisitor;

import 'package:kernel/transformations/flags.dart' show TransformerFlag;

import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;

import 'package:kernel/core_types.dart' show CoreTypes;

import '../parser/dart_vm_native.dart' show skipNativeClause;

import '../scanner/token.dart'
    show BeginGroupToken, Token, isBinaryOperator, isMinusOperator;

import '../errors.dart' show internalError, printUnexpected;

import '../source/scope_listener.dart'
    show JumpTargetKind, NullValue, ScopeListener;

import '../builder/scope.dart' show AccessErrorBuilder, AmbiguousBuilder, Scope;

import '../source/outline_builder.dart' show asyncMarkerFromTokens;

import 'builder_accessors.dart';

import 'frontend_accessors.dart' show buildIsNull, makeBinary, makeLet;

import 'builder_accessors.dart' as builder_accessors
    show throwNoSuchMethodError;

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

final Name callName = new Name("call");

final Name plusName = new Name("+");

final Name minusName = new Name("-");

final Name multiplyName = new Name("*");

final Name divisionName = new Name("/");

final Name percentName = new Name("%");

final Name ampersandName = new Name("&");

final Name leftShiftName = new Name("<<");

final Name rightShiftName = new Name(">>");

final Name caretName = new Name("^");

final Name barName = new Name("|");

final Name mustacheName = new Name("~/");

final Name indexGetName = new Name("[]");

final Name indexSetName = new Name("[]=");

class BodyBuilder extends ScopeListener<JumpTarget> implements BuilderHelper {
  final KernelLibraryBuilder library;

  final MemberBuilder member;

  final KernelClassBuilder classBuilder;

  final ClassHierarchy hierarchy;

  @override
  final CoreTypes coreTypes;

  final bool isInstanceMember;

  final Map<String, FieldInitializer> fieldInitializers =
      <String, FieldInitializer>{};

  final Scope enclosingScope;

  final bool isDartLibrary;

  @override
  final Uri uri;

  Scope formalParameterScope;

  bool isFirstIdentifier = false;

  bool hasParserError = false;

  bool inInitializer = false;

  bool inCatchClause = false;

  int functionNestingLevel = 0;

  Statement compileTimeErrorInTry;

  Statement compileTimeErrorInLoopOrSwitch;

  Scope switchScope;

  CloneVisitor cloner;

  BodyBuilder(
      KernelLibraryBuilder library,
      this.member,
      Scope scope,
      this.formalParameterScope,
      this.hierarchy,
      this.coreTypes,
      this.classBuilder,
      this.isInstanceMember,
      this.uri)
      : enclosingScope = scope,
        library = library,
        isDartLibrary = library.uri.scheme == "dart",
        super(scope);

  bool get inConstructor {
    return functionNestingLevel == 0 && member is KernelConstructorBuilder;
  }

  bool get isInstanceContext {
    return isInstanceMember || member is KernelConstructorBuilder;
  }

  @override
  void push(Object node) {
    isFirstIdentifier = false;
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
    if (node is UnresolvedIdentifier) {
      return throwNoSuchMethodError(
          node.name.name, new Arguments.empty(), node.fileOffset,
          isGetter: true);
    } else if (node is BuilderAccessor) {
      return node.buildSimpleRead();
    } else if (node is TypeVariableBuilder) {
      TypeParameterType type = node.buildTypesWithBuiltArguments(null);
      if (!isInstanceContext && type.parameter.parent is Class) {
        return buildCompileTimeError(
            "Type variables can only be used in instance methods.");
      } else {
        return new TypeLiteral(type);
      }
    } else if (node is TypeDeclarationBuilder) {
      return new TypeLiteral(node.buildTypesWithBuiltArguments(null));
    } else if (node is KernelTypeBuilder) {
      return new TypeLiteral(node.build());
    } else if (node is Expression) {
      return node;
    } else if (node is PrefixBuilder) {
      return buildCompileTimeError("A library can't be used as an expression.");
    } else {
      return internalError("Unhandled: ${node.runtimeType}");
    }
  }

  Expression toEffect(Object node) {
    if (node is BuilderAccessor) return node.buildForEffect();
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

  Block popBlock(int count) {
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
    return new Block(copy ?? statements);
  }

  Statement popStatementIfNotNull(Object value) {
    return value == null ? null : popStatement();
  }

  Statement popStatement() {
    var statement = pop();
    if (statement is List) {
      return new Block(new List<Statement>.from(statement));
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
    switchScope = pop();
  }

  @override
  JumpTarget createJumpTarget(JumpTargetKind kind, int charOffset) {
    return new JumpTarget(kind, member, charOffset);
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
    // There's no metadata here because of a slight assymetry between
    // [parseTopLevelMember] and [parseMember]. This assymetry leads to
    // DietListener discarding top-level member metadata.
  }

  @override
  void endFields(
      int count, Token covariantKeyword, Token beginToken, Token endToken) {
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
          field = classBuilder.members[name];
        } else {
          field = library.members[name];
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
  void endFunctionBody(int count, Token beginToken, Token endToken) {
    debugEvent("FunctionBody");
    if (beginToken == null) {
      assert(count == 0);
      push(NullValue.Block);
    } else {
      Block block = popBlock(count);
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
      classBuilder.members.forEach((String name, Builder builder) {
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
    } else if (node is BuilderAccessor) {
      initializer = node.buildFieldInitializer(fieldInitializers);
    } else if (node is ConstructorInvocation) {
      initializer = new SuperInitializer(node.target, node.arguments);
    } else {
      if (node is! Throw) {
        node = wrapInvalid(node);
      }
      initializer =
          new LocalInitializer(new VariableDeclaration.forValue(node));
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
    KernelFunctionBuilder builder = member;
    if (builder is KernelConstructorBuilder) {
      if (asyncModifier != AsyncMarker.Sync) {
        // TODO(ahe): Change this to a null check.
        addCompileTimeError(body?.fileOffset,
            "Can't be marked as ${asyncModifier}: ${builder.name}");
      }
    } else if (builder is KernelProcedureBuilder) {
      builder.asyncModifier = asyncModifier;
    } else {
      internalError("Unhandled: ${builder.runtimeType}");
    }
    builder.body = body;
    if (formals?.optional != null) {
      Iterator<FormalParameterBuilder> formalBuilders =
          builder.formals.skip(formals.required.length).iterator;
      for (VariableDeclaration parameter in formals.optional.formals) {
        bool hasMore = formalBuilders.moveNext();
        assert(hasMore);
        VariableDeclaration realParameter = formalBuilders.current.target;
        Expression initializer = parameter.initializer ?? new NullLiteral();
        realParameter.initializer = initializer..parent = realParameter;
      }
    }
  }

  @override
  void endExpressionStatement(Token token) {
    debugEvent("ExpressionStatement");
    push(new ExpressionStatement(popForEffect()));
  }

  @override
  void endArguments(int count, Token beginToken, Token endToken) {
    debugEvent("Arguments");
    List arguments = popList(count) ?? <Expression>[];
    int firstNamedArgument = arguments.length;
    for (int i = 0; i < arguments.length; i++) {
      var node = arguments[i];
      if (node is NamedExpression) {
        firstNamedArgument = i < firstNamedArgument ? i : firstNamedArgument;
      } else {
        arguments[i] = node = toValue(node);
        if (i > firstNamedArgument) {
          internalError("Expected named argument: $node");
        }
      }
    }
    if (firstNamedArgument < arguments.length) {
      List<Expression> positional =
          new List<Expression>.from(arguments.getRange(0, firstNamedArgument));
      List<NamedExpression> named = new List<NamedExpression>.from(
          arguments.getRange(firstNamedArgument, arguments.length));
      push(new Arguments(positional, named: named));
    } else {
      push(new Arguments(arguments));
    }
  }

  @override
  void handleParenthesizedExpression(BeginGroupToken token) {
    debugEvent("ParenthesizedExpression");
    push(popForValue());
  }

  @override
  void endSend(Token token) {
    debugEvent("Send");
    Arguments arguments = pop();
    List<DartType> typeArguments = pop();
    Object receiver = pop();
    if (arguments != null && typeArguments != null) {
      arguments.types.addAll(typeArguments);
    } else {
      assert(typeArguments == null);
    }
    if (receiver is Identifier) {
      Name name = new Name(receiver.name, library.library);
      if (arguments == null) {
        push(new IncompletePropertyAccessor(this, token.charOffset, name));
      } else {
        push(new SendAccessor(this, token.charOffset, name, arguments));
      }
    } else if (arguments == null) {
      push(receiver);
    } else {
      push(finishSend(receiver, arguments, token.charOffset));
    }
  }

  @override
  finishSend(Object receiver, Arguments arguments, int charOffset) {
    if (receiver is BuilderAccessor) {
      return receiver.doInvocation(charOffset, arguments);
    } else if (receiver is UnresolvedIdentifier) {
      return throwNoSuchMethodError(
          receiver.name.name, arguments, receiver.fileOffset);
    } else {
      return buildMethodInvocation(
          toValue(receiver), callName, arguments, charOffset);
    }
  }

  @override
  void beginCascade(Token token) {
    debugEvent("beginCascade");
    Expression expression = popForValue();
    if (expression is CascadeReceiver) {
      push(expression);
      push(new VariableAccessor(
          this, expression.fileOffset, expression.variable));
      expression.extend();
    } else {
      VariableDeclaration variable =
          new VariableDeclaration.forValue(expression);
      push(new CascadeReceiver(variable));
      push(new VariableAccessor(this, expression.fileOffset, variable));
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
      isSuper = true;
      receiver = new ThisExpression();
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
      Expression result = makeBinary(a, new Name(operator), null, b);
      if (isSuper) {
        result = toSuperMethodInvocation(result);
      }
      return negate ? new Not(result) : result;
    }
  }

  void doLogicalExpression(Token token) {
    Expression argument = popForValue();
    Expression receiver = popForValue();
    push(new LogicalExpression(receiver, token.stringValue, argument));
  }

  /// Handle `a ?? b`.
  void doIfNull(Token token) {
    Expression b = popForValue();
    Expression a = popForValue();
    VariableDeclaration variable = new VariableDeclaration.forValue(a);
    push(makeLet(
        variable,
        new ConditionalExpression(buildIsNull(new VariableGet(variable)), b,
            new VariableGet(variable), const DynamicType())));
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
          Expression result = new DirectMethodInvocation(
              new ThisExpression(), target, node.arguments);
          result = new SuperMethodInvocation(node.name, node.arguments, null);
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
    Expression receiver = new DirectPropertyGet(new ThisExpression(), target);
    receiver = new SuperPropertyGet(node.name, target);
    return buildMethodInvocation(
        receiver, callName, node.arguments, node.fileOffset);
  }

  bool areArgumentsCompatible(FunctionNode function, Arguments arguments) {
    // TODO(ahe): Implement this.
    return true;
  }

  Expression throwNoSuchMethodError(
      String name, Arguments arguments, int charOffset,
      {bool isSuper: false, isGetter: false, isSetter: false}) {
    return builder_accessors.throwNoSuchMethodError(
        name, arguments, uri, charOffset, coreTypes,
        isSuper: isSuper, isGetter: isGetter, isSetter: isSetter);
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
  void beginExpression(Token token) {
    debugEvent("beginExpression");
    isFirstIdentifier = true;
  }

  Builder computeSetter(
      Builder builder, Scope scope, String name, int charOffset) {
    if (builder.isSetter) return builder;
    if (builder.isGetter) return scope.lookupSetter(name, charOffset, uri);
    return builder.isField ? (builder.isFinal ? null : builder) : null;
  }

  @override
  void handleIdentifier(Token token, IdentifierContext context) {
    debugEvent("handleIdentifier");
    String name = token.value;
    if (isFirstIdentifier) {
      assert(!inInitializer ||
          this.scope == enclosingScope ||
          this.scope.parent == enclosingScope);
      // This deals with this kind of initializer: `C(a) : a = a;`
      Scope scope = inInitializer ? enclosingScope : this.scope;
      Builder builder = scope.lookup(name, token.charOffset, uri);
      push(builderToFirstExpression(builder, name, token.charOffset));
    } else {
      push(new Identifier(name)..fileOffset = token.charOffset);
    }
  }

  @override
  builderToFirstExpression(Builder builder, String name, int charOffset,
      {bool isPrefix: false}) {
    if (builder == null || (!isInstanceContext && builder.isInstanceMember)) {
      if (!isPrefix && identical(name, "dynamic") && builder == null) {
        return new KernelNamedTypeBuilder(name, null, charOffset, uri);
      }
      Name n = new Name(name, library.library);
      if (!isPrefix && isInstanceContext) {
        assert(builder == null);
        return new ThisPropertyAccessor(this, charOffset, n, null, null);
      } else {
        return new UnresolvedIdentifier(n)..fileOffset = charOffset;
      }
    } else if (builder.isTypeDeclaration) {
      return builder;
    } else if (builder.isLocal) {
      return new VariableAccessor(this, charOffset, builder.target);
    } else if (builder.isInstanceMember) {
      return new ThisPropertyAccessor(
          this, charOffset, new Name(name, library.library), null, null);
    } else if (builder.isRegularMethod) {
      assert(builder.isStatic || builder.isTopLevel);
      return new StaticAccessor(this, charOffset, builder.target, null);
    } else if (builder is PrefixBuilder) {
      return builder;
    } else if (builder is MixedAccessor) {
      return new StaticAccessor(
          this, charOffset, builder.getter.target, builder.setter.target);
    } else {
      if (builder is AccessErrorBuilder) {
        AccessErrorBuilder error = builder;
        builder = error.builder;
      }
      if (builder.target == null) {
        return internalError("Unhandled: ${builder}");
      }
      Member getter = builder.target.hasGetter ? builder.target : null;
      Member setter = builder.target.hasSetter ? builder.target : null;
      setter ??= computeSetter(builder, scope, name, charOffset)?.target;
      return new StaticAccessor(this, charOffset, getter, setter);
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
  void endLiteralString(int interpolationCount) {
    debugEvent("endLiteralString");
    if (interpolationCount == 0) {
      Token token = pop();
      push(new StringLiteral(unescapeString(token.value)));
    } else {
      List parts = popList(1 + interpolationCount * 2);
      Token first = parts.first;
      Token last = parts.last;
      Quote quote = analyzeQuote(first.value);
      List<Expression> expressions = <Expression>[];
      expressions
          .add(new StringLiteral(unescapeFirstStringPart(first.value, quote)));
      for (int i = 1; i < parts.length - 1; i++) {
        var part = parts[i];
        if (part is Token) {
          expressions.add(new StringLiteral(unescape(part.value, quote)));
        } else {
          expressions.add(toValue(part));
        }
      }
      expressions
          .add(new StringLiteral(unescapeLastStringPart(last.value, quote)));
      push(new StringConcatenation(expressions));
    }
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
    push(new StringConcatenation(expressions ?? parts));
  }

  @override
  void handleLiteralInt(Token token) {
    debugEvent("LiteralInt");
    push(new IntLiteral(int.parse(token.value)));
  }

  @override
  void endExpressionFunctionBody(Token arrowToken, Token endToken) {
    debugEvent("ExpressionFunctionBody");
    endReturnStatement(true, arrowToken, endToken);
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
      push(new ReturnStatement(expression));
    }
  }

  @override
  void endIfStatement(Token ifToken, Token elseToken) {
    Statement elsePart = popStatementIfNotNull(elseToken);
    Statement thenPart = popStatement();
    Expression condition = popForValue();
    push(new IfStatement(condition, thenPart, elsePart));
  }

  @override
  void endVariableInitializer(Token assignmentOperator) {
    debugEvent("VariableInitializer");
    assert(assignmentOperator.stringValue == "=");
    Expression initializer = popForValue();
    Identifier identifier = pop();
    push(new VariableDeclaration(identifier.name, initializer: initializer));
  }

  @override
  void handleNoVariableInitializer(Token token) {
    debugEvent("NoVariableInitializer");
  }

  @override
  void endFieldInitializer(Token assignmentOperator) {
    debugEvent("FieldInitializer");
    assert(assignmentOperator.stringValue == "=");
    push(popForValue());
  }

  @override
  void handleNoFieldInitializer(Token token) {
    debugEvent("NoFieldInitializer");
    push(NullValue.FieldInitializer);
  }

  @override
  void endInitializedIdentifier() {
    // TODO(ahe): Use [InitializedIdentifier] here?
    debugEvent("InitializedIdentifier");
    TreeNode node = pop();
    VariableDeclaration variable;
    if (node is VariableDeclaration) {
      variable = node;
    } else if (node is Identifier) {
      variable = new VariableDeclaration(node.name);
    } else {
      internalError("unhandled identifier: ${node.runtimeType}");
    }
    push(variable);
    scope[variable.name] = new KernelVariableBuilder(
        variable, member ?? classBuilder ?? library, uri);
  }

  @override
  void endVariablesDeclaration(int count, Token endToken) {
    debugEvent("VariablesDeclaration");
    List<VariableDeclaration> variables = popList(count);
    DartType type = pop();
    int modifiers = Modifier.validate(pop());
    bool isConst = (modifiers & constMask) != 0;
    bool isFinal = (modifiers & finalMask) != 0;
    if (type != null || isConst || isFinal) {
      type ??= const DynamicType();
      for (VariableDeclaration variable in variables) {
        variable
          ..type = type
          ..isConst = isConst
          ..isFinal = isFinal;
      }
    }
    if (variables.length != 1) {
      push(variables);
    } else {
      push(variables.single);
    }
  }

  @override
  void endBlock(int count, Token beginToken, Token endToken) {
    debugEvent("Block");
    Block block = popBlock(count);
    exitLocalScope();
    push(block);
  }

  @override
  void handleAssignmentExpression(Token token) {
    debugEvent("AssignmentExpression");
    Expression value = popForValue();
    var accessor = pop();
    if (accessor is TypeDeclarationBuilder) {
      push(wrapInvalid(
          new TypeLiteral(accessor.buildTypesWithBuiltArguments(null))));
    } else if (accessor is! BuilderAccessor) {
      push(buildCompileTimeError("Can't assign to this.", token.charOffset));
    } else {
      push(new DelayedAssignment(
          this, token.charOffset, accessor, value, token.stringValue));
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
  void endForStatement(
      int updateExpressionCount, Token beginToken, Token endToken) {
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
    if (variableOrExpression is BuilderAccessor) {
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
      begin = new ExpressionStatement(variableOrExpression);
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
  void endAwaitExpression(Token beginToken, Token endToken) {
    debugEvent("AwaitExpression");
    push(new AwaitExpression(popForValue()));
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
    DartType typeArgument = const DynamicType();
    if (typeArguments != null) {
      typeArgument = typeArguments.first;
      if (typeArguments.length > 1) {
        typeArgument = const DynamicType();
        warning(
            "Too many type arguments on List literal.", beginToken.charOffset);
      }
    }
    push(new ListLiteral(expressions,
        typeArgument: typeArgument, isConst: constKeyword != null));
  }

  @override
  void handleLiteralBool(Token token) {
    debugEvent("LiteralBool");
    bool value = optional("true", token);
    assert(value || optional("false", token));
    push(new BoolLiteral(value));
  }

  @override
  void handleLiteralDouble(Token token) {
    debugEvent("LiteralDouble");
    push(new DoubleLiteral(double.parse(token.value)));
  }

  @override
  void handleLiteralNull(Token token) {
    debugEvent("LiteralNull");
    push(new NullLiteral());
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
        warning(
            "Map literal requires two type arguments.", beginToken.charOffset);
      } else {
        keyType = typeArguments[0];
        valueType = typeArguments[1];
      }
    }
    push(new MapLiteral(entries,
        keyType: keyType, valueType: valueType, isConst: constKeyword != null));
  }

  @override
  void endLiteralMapEntry(Token colon, Token endToken) {
    debugEvent("LiteralMapEntry");
    Expression value = popForValue();
    Expression key = popForValue();
    push(new MapEntry(key, value));
  }

  @override
  void beginLiteralSymbol(Token token) {
    isFirstIdentifier = false;
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
      value = symbolPartToString(popForValue());
    } else {
      List parts = popList(identifierCount);
      value = symbolPartToString(parts.first);
      for (int i = 1; i < parts.length; i++) {
        value += ".${symbolPartToString(parts[i])}";
      }
    }
    push(new SymbolLiteral(value));
  }

  DartType toKernelType(String name, List<DartType> arguments, int charOffset) {
    if (identical(name, "void")) return const VoidType();
    if (identical(name, "dynamic")) return const DynamicType();
    Builder builder = scope.lookup(name, charOffset, uri);
    if (builder is TypeDeclarationBuilder) {
      return builder.buildTypesWithBuiltArguments(arguments);
    }
    if (builder == null) {
      warning("Type not found: '$name'.", charOffset);
    } else {
      warning("Not a type: '$name'.", charOffset);
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
        name = builder.exports[suffix];
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
    if (name is BuilderAccessor) {
      warning("'${beginToken.value}' isn't a type.", beginToken.charOffset);
      push(const DynamicType());
    } else if (name is UnresolvedIdentifier) {
      warning("'${name.name}' isn't a type.", beginToken.charOffset);
      push(const DynamicType());
    } else if (name is TypeVariableBuilder) {
      push(name.buildTypesWithBuiltArguments(arguments));
    } else if (name is TypeDeclarationBuilder) {
      push(name.buildTypesWithBuiltArguments(arguments));
    } else if (name is TypeBuilder) {
      push(name.build());
    } else {
      push(toKernelType(name, arguments, beginToken.charOffset));
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
  void handleVoidKeyword(Token token) {
    debugEvent("VoidKeyword");
    push(const VoidType());
  }

  @override
  void handleAsOperator(Token operator, Token endToken) {
    debugEvent("AsOperator");
    DartType type = pop();
    Expression expression = popForValue();
    push(new AsExpression(expression, type));
  }

  @override
  void handleIsOperator(Token operator, Token not, Token endToken) {
    debugEvent("IsOperator");
    DartType type = pop();
    Expression expression = popForValue();
    expression = new IsExpression(expression, type);
    if (not != null) {
      expression = new Not(expression);
    }
    push(expression);
  }

  @override
  void handleConditionalExpression(Token question, Token colon) {
    debugEvent("ConditionalExpression");
    Expression elseExpression = popForValue();
    Expression thenExpression = popForValue();
    Expression condition = popForValue();
    push(new ConditionalExpression(
        condition, thenExpression, elseExpression, const DynamicType()));
  }

  @override
  void endThrowExpression(Token throwToken, Token endToken) {
    debugEvent("ThrowExpression");
    Expression expression = popForValue();
    push(new Throw(expression));
  }

  @override
  void endFormalParameter(
      Token covariantKeyword, Token thisKeyword, FormalParameterType kind) {
    debugEvent("FormalParameter");
    // TODO(ahe): Need beginToken here.
    int charOffset = thisKeyword?.charOffset;
    if (thisKeyword != null) {
      if (!inConstructor) {
        addCompileTimeError(thisKeyword.charOffset,
            "'this' parameters can only be used on constructors.");
        thisKeyword = null;
      }
    }
    Identifier name = pop();
    DartType type = pop();
    pop(); // Modifiers.
    ignore(Unhandled.Metadata);
    VariableDeclaration variable;
    if (!inCatchClause && functionNestingLevel == 0) {
      dynamic builder = formalParameterScope.lookup(name.name, charOffset, uri);
      if (builder == null) {
        if (thisKeyword == null) {
          internalError("Internal error: formal missing for '${name.name}'");
        } else {
          addCompileTimeError(thisKeyword.charOffset,
              "'${name.name}' isn't a field in this class.");
          thisKeyword = null;
        }
      } else if (thisKeyword == null) {
        variable = builder.build();
        variable.initializer = name.initializer;
      } else if (builder.isField && builder.parent == classBuilder) {
        FieldBuilder field = builder;
        if (type != null) {
          nit("Ignoring type on 'this' parameter '${name.name}'.",
              thisKeyword.charOffset);
        }
        type = field.target.type ?? const DynamicType();
        variable = new VariableDeclaration(name.name,
            type: type, initializer: name.initializer);
      } else {
        addCompileTimeError(
            name.fileOffset, "'${name.name}' isn't a field in this class.");
      }
    }
    variable ??= new VariableDeclaration(name.name,
        type: type ?? const DynamicType(), initializer: name.initializer);
    push(variable);
  }

  @override
  void endOptionalFormalParameters(
      int count, Token beginToken, Token endToken) {
    debugEvent("OptionalFormalParameters");
    FormalParameterType kind = optional("{", beginToken)
        ? FormalParameterType.NAMED
        : FormalParameterType.POSITIONAL;
    push(new OptionalFormals(kind, popList(count)));
  }

  @override
  void beginFunctionTypedFormalParameter(Token token) {
    debugEvent("beginFunctionTypedFormalParameter");
    functionNestingLevel++;
  }

  @override
  void endFunctionTypedFormalParameter(
      Token covariantKeyword, Token thisKeyword, FormalParameterType kind) {
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
    push(new InitializedIdentifier(name.name, initializer));
  }

  @override
  void handleFormalParameterWithoutValue(Token token) {
    debugEvent("FormalParameterWithoutValue");
  }

  @override
  void endFormalParameters(int count, Token beginToken, Token endToken) {
    debugEvent("FormalParameters");
    OptionalFormals optional;
    if (count > 0 && peek() is OptionalFormals) {
      optional = pop();
      count--;
    }
    FormalParameters formals = new FormalParameters(
        popList(count) ?? <VariableDeclaration>[], optional);
    push(formals);
    if (inCatchClause || functionNestingLevel != 0) {
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
  }

  @override
  void handleCatchBlock(Token onKeyword, Token catchKeyword) {
    debugEvent("CatchBlock");
    Block body = pop();
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
      push(new SuperIndexAccessor(this, receiver.charOffset, index,
          lookupSuperMember(indexGetName), lookupSuperMember(indexSetName)));
    } else {
      push(IndexAccessor.make(this, openCurlyBracket.charOffset,
          toValue(receiver), index, null, null));
    }
  }

  @override
  void handleUnaryPrefixExpression(Token token) {
    debugEvent("UnaryPrefixExpression");
    var receiver = pop();
    if (optional("!", token)) {
      push(new Not(toValue(receiver)));
    } else {
      String operator = token.stringValue;
      if (optional("-", token)) {
        operator = "unary-";
      }
      if (receiver is ThisAccessor && receiver.isSuper) {
        push(toSuperMethodInvocation(buildMethodInvocation(
            new ThisExpression()..fileOffset = receiver.charOffset,
            new Name(operator),
            new Arguments.empty(),
            token.charOffset)));
      } else {
        push(buildMethodInvocation(toValue(receiver), new Name(operator),
            new Arguments.empty(), token.charOffset));
      }
    }
  }

  Name incrementOperator(Token token) {
    if (optional("++", token)) return plusName;
    if (optional("--", token)) return minusName;
    return internalError("Unknown increment operator: ${token.value}");
  }

  @override
  void handleUnaryPrefixAssignmentExpression(Token token) {
    debugEvent("UnaryPrefixAssignmentExpression");
    var accessor = pop();
    if (accessor is BuilderAccessor) {
      push(accessor.buildPrefixIncrement(incrementOperator(token)));
    } else {
      push(wrapInvalid(toValue(accessor)));
    }
  }

  @override
  void handleUnaryPostfixAssignmentExpression(Token token) {
    debugEvent("UnaryPostfixAssignmentExpression");
    var accessor = pop();
    if (accessor is BuilderAccessor) {
      push(new DelayedPostfixIncrement(
          this, token.charOffset, accessor, incrementOperator(token), null));
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
        // TODO(ahe): Handle privacy in prefix.exports.
        type = builderToFirstExpression(
            prefix.exports[identifier.name], identifier.name, start.charOffset);
        identifier = null;
      } else if (prefix is ClassBuilder) {
        type = prefix;
      } else {
        type = new Identifier(start.value)..fileOffset = start.charOffset;
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
      typeParameters = target.enclosingClass.typeParameters;
    }
    if (!addDefaultArguments(target.function, arguments, typeParameters)) {
      return throwNoSuchMethodError(target.name.name, arguments, charOffset);
    }
    if (target is Constructor) {
      return new ConstructorInvocation(target, arguments)..isConst = isConst;
    } else {
      return new StaticInvocation(target, arguments)..isConst = isConst;
    }
  }

  bool addDefaultArguments(FunctionNode function, Arguments arguments,
      List<TypeParameter> typeParameters) {
    bool missingInitializers = false;

    Expression defaultArgumentFrom(Expression expression) {
      if (expression == null) {
        missingInitializers = true;
        return null;
      }
      cloner ??= new CloneVisitor();
      return cloner.clone(expression);
    }

    if (arguments.positional.length < function.requiredParameterCount ||
        arguments.positional.length > function.positionalParameters.length) {
      return false;
    }
    for (int i = arguments.positional.length;
        i < function.positionalParameters.length;
        i++) {
      var expression =
          defaultArgumentFrom(function.positionalParameters[i].initializer);
      expression?.parent = arguments;
      arguments.positional.add(expression);
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
    if (names != null) {
      for (String name in names.keys) {
        VariableDeclaration parameter = names[name];
        arguments.named.add(new NamedExpression(
            name, defaultArgumentFrom(parameter.initializer))
          ..parent = arguments);
      }
    }
    if (typeParameters.length != arguments.types.length) {
      arguments.types.clear();
      for (int i = 0; i < typeParameters.length; i++) {
        arguments.types.add(const DynamicType());
      }
    }

    if (missingInitializers) {
      library.addArgumentsWithMissingDefaultValues(arguments, function);
    }
    return true;
  }

  @override
  void handleNewExpression(Token token) {
    debugEvent("NewExpression");
    Arguments arguments = pop();
    String name = pop();
    List<DartType> typeArguments = pop();
    var type = pop();

    if (typeArguments != null) {
      assert(arguments.types.isEmpty);
      arguments.types.addAll(typeArguments);
    }

    String errorName;
    if (type is ClassBuilder) {
      Builder b = type.findConstructorOrFactory(name);
      Member target;
      if (b == null) {
        // Not found. Reported below.
      } else if (b.isConstructor) {
        if (type.isAbstract) {
          // TODO(ahe): Generate abstract instantiation error.
        } else {
          target = b.target;
        }
      } else if (b.isFactory) {
        target = getRedirectionTarget(b.target);
        if (target == null) {
          push(buildCompileTimeError(
              "Cyclic definition of factory '${name}'.", token.charOffset));
          return;
        }
      }
      if (target is Constructor ||
          (target is Procedure && target.kind == ProcedureKind.Factory)) {
        push(buildStaticInvocation(target, arguments,
            isConst: optional("const", token), charOffset: token.charOffset));
        return;
      } else {
        errorName = debugName(type.name, name);
      }
    } else {
      errorName = debugName(getNodeName(type), name);
    }
    errorName ??= name;
    push(throwNoSuchMethodError(errorName, arguments, token.charOffset));
  }

  @override
  void handleConstExpression(Token token) {
    debugEvent("ConstExpression");
    handleNewExpression(token);
  }

  @override
  void endTypeArguments(int count, Token beginToken, Token endToken) {
    debugEvent("TypeArguments");
    push(popList(count));
  }

  @override
  void handleThisExpression(Token token) {
    debugEvent("ThisExpression");
    if (isFirstIdentifier && isInstanceContext) {
      push(new ThisAccessor(this, token.charOffset, inInitializer));
    } else {
      push(new IncompleteError(
          this, token.charOffset, "Expected identifier, but got 'this'."));
    }
  }

  @override
  void handleSuperExpression(Token token) {
    debugEvent("SuperExpression");
    if (isFirstIdentifier && isInstanceContext) {
      Member member = this.member.target;
      member.transformerFlags |= TransformerFlag.superCalls;
      push(new ThisAccessor(this, token.charOffset, inInitializer,
          isSuper: true));
    } else {
      push(new IncompleteError(
          this, token.charOffset, "Expected identifier, but got 'super'."));
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
  void endFunctionName(Token token) {
    debugEvent("FunctionName");
    Identifier name = pop();
    VariableDeclaration variable =
        new VariableDeclaration(name.name, isFinal: true);
    push(new FunctionDeclaration(
        variable, new FunctionNode(new InvalidStatement())));
    scope[variable.name] = new KernelVariableBuilder(
        variable, member ?? classBuilder ?? library, uri);
    enterLocalScope();
  }

  @override
  void beginFunction(Token token) {
    debugEvent("beginFunction");
    functionNestingLevel++;
  }

  @override
  void beginUnnamedFunction(Token token) {
    debugEvent("beginUnnamedFunction");
    functionNestingLevel++;
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
        typeParameters: typeParameters, asyncMarker: asyncModifier)));
    functionNestingLevel--;
  }

  @override
  void endFunctionDeclaration(Token token) {
    debugEvent("FunctionDeclaration");
    FunctionNode function = pop();
    exitLocalScope();
    FunctionDeclaration declaration = pop();
    function.returnType = pop() ?? const DynamicType();
    pop(); // Modifiers.
    declaration.function = function;
    function.parent = declaration;
    push(declaration);
  }

  @override
  void endUnnamedFunction(Token token) {
    debugEvent("UnnamedFunction");
    Statement body = popStatement();
    AsyncMarker asyncModifier = pop();
    exitLocalScope();
    FormalParameters formals = pop();
    List<TypeParameter> typeParameters = pop();
    FunctionNode function = formals.addToFunction(new FunctionNode(body,
        typeParameters: typeParameters, asyncMarker: asyncModifier));
    push(new FunctionExpression(function));
    functionNestingLevel--;
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
  void endForIn(
      Token awaitToken, Token forToken, Token inKeyword, Token endToken) {
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
    } else if (lvalue is BuilderAccessor) {
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
          new ExpressionStatement(lvalue
              .buildAssignment(new VariableGet(variable), voidContext: true)),
          body);
    } else {
      variable = new VariableDeclaration.forValue(buildCompileTimeError(
          "Expected lvalue, but got ${lvalue}", forToken.next.next.charOffset));
    }
    Statement result = new ForInStatement(variable, expression, body,
        isAsync: awaitToken != null);
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
    enterLocalScope();
    LabelTarget target = new LabelTarget(member, token.charOffset);
    for (Label label in labels) {
      scope[label.name] = target;
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
  void endRethrowStatement(Token throwToken, Token endToken) {
    debugEvent("RethrowStatement");
    push(new ExpressionStatement(new Rethrow()));
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
  void handleAssertStatement(
      Token assertKeyword, Token commaToken, Token semicolonToken) {
    debugEvent("AssertStatement");
    Expression message = popForValueIfNotNull(commaToken);
    Expression condition = popForValue();
    push(new AssertStatement(condition, message));
  }

  @override
  void endYieldStatement(Token yieldToken, Token starToken, Token endToken) {
    debugEvent("YieldStatement");
    push(new YieldStatement(popForValue(), isYieldStar: starToken != null));
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
      Builder existing = scope.local[label.name];
      if (existing == null) {
        scope[label.name] = createGotoTarget(firstToken.charOffset);
      } else {
        // TODO(ahe): Should validate this is a goto target and not duplicated.
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
    Block block = popBlock(statementCount);
    exitLocalScope();
    List<Label> labels = pop();
    List<Expression> expressions = pop();
    push(new SwitchCase(expressions, block, isDefault: defaultKeyword != null));
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
        JumpTarget target =
            switchScope.lookup(label.name, label.fileOffset, uri);
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
      target = scope.lookup(identifier.name, breakKeyword.next.charOffset, uri);
    }
    if (target == null && name == null) {
      push(compileTimeErrorInLoopOrSwitch = buildCompileTimeErrorStatement(
          "No target of break.", breakKeyword.charOffset));
    } else if (target == null ||
        target is! JumpTarget ||
        !target.isBreakTarget) {
      push(compileTimeErrorInLoopOrSwitch = buildCompileTimeErrorStatement(
          "Can't break to '$name'.", breakKeyword.next.charOffset));
    } else {
      BreakStatement statement = new BreakStatement(null);
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
      target =
          scope.lookup(identifier.name, continueKeyword.next.charOffset, uri);
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
        switchScope[identifier.name] =
            target = createGotoTarget(identifier.fileOffset);
      }
      if (target.isGotoTarget) {
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
    } else {
      BreakStatement statement = new BreakStatement(null);
      target.addContinue(statement);
      push(statement);
    }
  }

  @override
  void endTypeVariable(Token token, Token extendsOrSuper) {
    logEvent("TypeVariable");
    // TODO(ahe): Implement this when enabling generic method syntax.
  }

  @override
  void endTypeVariables(int count, Token beginToken, Token endToken) {
    logEvent("TypeVariables");
    // TODO(ahe): Implement this when enabling generic method syntax.
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
  void handleRecoverableError(Token token, ErrorKind kind, Map arguments) {
    super.handleRecoverableError(token, kind, arguments);
    if (!hasParserError) {
      printUnexpected(uri, recoverableErrors.last.beginOffset,
          '${recoverableErrors.last.kind}');
    }
    hasParserError = true;
  }

  @override
  Token handleUnrecoverableError(Token token, ErrorKind kind, Map arguments) {
    if (isDartLibrary && kind == ErrorKind.ExpectedFunctionBody) {
      Token recover = skipNativeClause(token);
      if (recover != null) return recover;
    } else if (kind == ErrorKind.UnexpectedToken) {
      String expected = arguments["expected"];
      const List<String> trailing = const <String>[")", "}", ";", ","];
      if (trailing.contains(token.stringValue) && trailing.contains(expected)) {
        arguments.putIfAbsent("actual", () => token.value);
        handleRecoverableError(token, ErrorKind.ExpectedButGot, arguments);
      }
      return token;
    }
    return super.handleUnrecoverableError(token, kind, arguments);
  }

  @override
  Expression buildCompileTimeError(error, [int charOffset = -1]) {
    String message = printUnexpected(uri, charOffset, error);
    Builder constructor = library.loader.getCompileTimeError();
    return new Throw(buildStaticInvocation(constructor.target,
        new Arguments(<Expression>[new StringLiteral(message)]),
        isConst: false)); // TODO(ahe): Make this const.
  }

  Statement buildCompileTimeErrorStatement(error, [int charOffset = -1]) {
    return new ExpressionStatement(buildCompileTimeError(error, charOffset));
  }

  @override
  Initializer buildCompileTimeErrorIntializer(error, [int charOffset = -1]) {
    return new LocalInitializer(new VariableDeclaration.forValue(
        buildCompileTimeError(error, charOffset)));
  }

  @override
  Expression buildProblemExpression(Builder builder, String name) {
    if (builder is AmbiguousBuilder) {
      return buildCompileTimeError("Duplicated named: '$name'.");
    } else if (builder is AccessErrorBuilder) {
      return buildCompileTimeError("Access error: '$name'.");
    } else {
      return internalError("Unhandled: ${builder.runtimeType}");
    }
  }

  @override
  void handleOperator(Token token) {
    debugEvent("Operator");
    push(new Operator(token.stringValue)..fileOffset = token.charOffset);
  }

  dynamic addCompileTimeError(int charOffset, String message) {
    return library.addCompileTimeError(charOffset, message, uri);
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
  void debugEvent(String name) {
    // printEvent(name);
  }
}

// TODO(ahe): Shouldn't need to be an expression.
class UnresolvedIdentifier extends InvalidExpression {
  final Name name;

  UnresolvedIdentifier(this.name);

  String toString() => "unresolved-identifier($name)";
}

// TODO(ahe): Shouldn't need to be an expression.
class Identifier extends InvalidExpression {
  final String name;

  Identifier(this.name);

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

  InitializedIdentifier(String name, this.initializer) : super(name);

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

abstract class ContextAccessor extends BuilderAccessor {
  final BuilderHelper helper;

  final int charOffset;

  final BuilderAccessor accessor;

  ContextAccessor(this.helper, this.charOffset, this.accessor);

  String get plainNameForRead => internalError("Unsupported operation.");

  Expression doInvocation(int charOffset, Arguments arguments) {
    print("$uri:$charOffset: Internal error: Unhandled: ${runtimeType}");
    return internalError("Unhandled: ${runtimeType}");
  }

  Expression buildSimpleRead();

  Expression buildForEffect();

  Expression buildAssignment(Expression value, {bool voidContext: false}) {
    return internalError("not supported");
  }

  Expression buildNullAwareAssignment(Expression value, DartType type,
      {bool voidContext: false}) {
    return internalError("not supported");
  }

  Expression buildCompoundAssignment(Name binaryOperator, Expression value,
      {bool voidContext: false, Procedure interfaceTarget}) {
    return internalError("not supported");
  }

  Expression buildPrefixIncrement(Name binaryOperator,
      {bool voidContext: false, Procedure interfaceTarget}) {
    return internalError("not supported");
  }

  Expression buildPostfixIncrement(Name binaryOperator,
      {bool voidContext: false, Procedure interfaceTarget}) {
    return internalError("not supported");
  }

  makeInvalidRead() => internalError("not supported");

  makeInvalidWrite(Expression value) => internalError("not supported");
}

class DelayedAssignment extends ContextAccessor {
  final Expression value;

  final String assignmentOperator;

  DelayedAssignment(BuilderHelper helper, int charOffset,
      BuilderAccessor accessor, this.value, this.assignmentOperator)
      : super(helper, charOffset, accessor);

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
          voidContext: voidContext);
    } else if (identical("-=", assignmentOperator)) {
      return accessor.buildCompoundAssignment(minusName, value,
          voidContext: voidContext);
    } else if (identical("*=", assignmentOperator)) {
      return accessor.buildCompoundAssignment(multiplyName, value,
          voidContext: voidContext);
    } else if (identical("%=", assignmentOperator)) {
      return accessor.buildCompoundAssignment(percentName, value,
          voidContext: voidContext);
    } else if (identical("&=", assignmentOperator)) {
      return accessor.buildCompoundAssignment(ampersandName, value,
          voidContext: voidContext);
    } else if (identical("/=", assignmentOperator)) {
      return accessor.buildCompoundAssignment(divisionName, value,
          voidContext: voidContext);
    } else if (identical("<<=", assignmentOperator)) {
      return accessor.buildCompoundAssignment(leftShiftName, value,
          voidContext: voidContext);
    } else if (identical(">>=", assignmentOperator)) {
      return accessor.buildCompoundAssignment(rightShiftName, value,
          voidContext: voidContext);
    } else if (identical("??=", assignmentOperator)) {
      return accessor.buildNullAwareAssignment(value, const DynamicType(),
          voidContext: voidContext);
    } else if (identical("^=", assignmentOperator)) {
      return accessor.buildCompoundAssignment(caretName, value,
          voidContext: voidContext);
    } else if (identical("|=", assignmentOperator)) {
      return accessor.buildCompoundAssignment(barName, value,
          voidContext: voidContext);
    } else if (identical("~/=", assignmentOperator)) {
      return accessor.buildCompoundAssignment(mustacheName, value,
          voidContext: voidContext);
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

  DelayedPostfixIncrement(BuilderHelper helper, int charOffset,
      BuilderAccessor accessor, this.binaryOperator, this.interfaceTarget)
      : super(helper, charOffset, accessor);

  Expression buildSimpleRead() {
    return accessor.buildPostfixIncrement(binaryOperator,
        voidContext: false, interfaceTarget: interfaceTarget);
  }

  Expression buildForEffect() {
    return accessor.buildPostfixIncrement(binaryOperator,
        voidContext: true, interfaceTarget: interfaceTarget);
  }
}

class JumpTarget extends Builder {
  final List<Statement> users = <Statement>[];

  final JumpTargetKind kind;

  JumpTarget(this.kind, MemberBuilder member, int charOffset)
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
}

class LabelTarget extends Builder implements JumpTarget {
  final JumpTarget breakTarget;

  final JumpTarget continueTarget;

  LabelTarget(MemberBuilder member, int charOffset)
      : breakTarget = new JumpTarget(JumpTargetKind.Break, member, charOffset),
        continueTarget =
            new JumpTarget(JumpTargetKind.Continue, member, charOffset),
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
}

class OptionalFormals {
  final FormalParameterType kind;

  final List<VariableDeclaration> formals;

  OptionalFormals(this.kind, this.formals);
}

class FormalParameters {
  final List<VariableDeclaration> required;
  final OptionalFormals optional;

  FormalParameters(this.required, this.optional);

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
    return new Scope(local, parent, isModifiable: false);
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
  } else if (node is UnresolvedIdentifier) {
    return node.name.name;
  } else if (node is TypeDeclarationBuilder) {
    return node.name;
  } else if (node is PrefixBuilder) {
    return node.name;
  } else if (node is ThisPropertyAccessor) {
    return node.name.name;
  } else {
    return internalError("Unhandled: ${node.runtimeType}");
  }
}
