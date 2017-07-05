// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Logic to build unlinked summaries.
library summary.src.summary_builder;

import 'package:front_end/src/fasta/parser.dart'
    show
        ClassMemberParser,
        FormalParameterType,
        IdentifierContext,
        MemberKind,
        Parser;

import 'package:front_end/src/fasta/scanner.dart' show Token, scan;

import 'package:front_end/src/fasta/scanner/token_constants.dart';

import 'expression_serializer.dart';
import 'model.dart';
import 'stack_listener.dart';

const _abstract_flag = 1 << 2;

const _async_flag = 1;

const _const_flag = 1 << 1;

const _external_flag = 1 << 4;

const _final_flag = 1;

/// Maps modifier names to their bit-mask.
const _modifierFlag = const {
  'const': _const_flag,
  'abstract': _abstract_flag,
  'static': _static_flag,
  'external': _external_flag,
  'final': _final_flag,
  'var': _var_flag,
};

// bit-masks to encode modifiers as bits on an int.

const _star_flag = 1 << 2;

const _static_flag = 1 << 3;
const _sync_flag = 1 << 1;
const _var_flag = 0;

/// Retrieve the operator from an assignment operator (e.g. + from +=).
/// Operators are encoded using the scanner token kind id.
int opForAssignOp(int kind) {
  switch (kind) {
    case AMPERSAND_EQ_TOKEN:
      return AMPERSAND_TOKEN;
    // TODO(paulberry): add support for &&=
    // case AMPERSAND_AMPERSAND_EQ_TOKEN: return AMPERSAND_AMPERSAND_TOKEN;
    case BAR_EQ_TOKEN:
      return BAR_TOKEN;
    // TODO(paulberry): add support for ||=
    // case BAR_BAR_EQ_TOKEN: return BAR_BAR_TOKEN;
    case CARET_EQ_TOKEN:
      return CARET_TOKEN;
    case GT_GT_EQ_TOKEN:
      return GT_GT_TOKEN;
    case LT_LT_EQ_TOKEN:
      return LT_LT_TOKEN;
    case MINUS_EQ_TOKEN:
      return MINUS_TOKEN;
    case PERCENT_EQ_TOKEN:
      return PERCENT_TOKEN;
    case PLUS_EQ_TOKEN:
      return PLUS_TOKEN;
    case QUESTION_QUESTION_EQ_TOKEN:
      return QUESTION_QUESTION_TOKEN;
    case SLASH_EQ_TOKEN:
      return SLASH_TOKEN;
    case STAR_EQ_TOKEN:
      return STAR_TOKEN;
    case TILDE_SLASH_EQ_TOKEN:
      return TILDE_SLASH_TOKEN;
    case PLUS_EQ_TOKEN:
      return PLUS_TOKEN;
    default:
      throw "Unhandled kind $kind";
  }
}

/// Create an unlinked summary given a null-terminated byte buffer with the
/// contents of a file.
UnlinkedUnit summarize(Uri uri, List<int> contents) {
  var listener = new SummaryBuilder(uri);
  var parser = new ClassMemberParser(listener);
  parser.parseUnit(scan(contents).tokens);
  return listener.topScope.unit;
}

/// Builder for constant expressions.
///
/// Any invalid subexpression is denoted with [Invalid].
class ConstExpressionBuilder extends ExpressionListener {
  final Uri uri;
  Parser parser;
  ConstExpressionBuilder(this.uri) {
    parser = new Parser(this);
  }
  bool get forConst => true;

  void endArguments(int count, Token begin, Token end) {
    debugEvent("Arguments");
    if (ignore) return;
    push(popList(count) ?? const []);
  }

  void handleAsOperator(Token op, Token next) {
    debugEvent("As");
    if (ignore) return;
    push(new As(pop(), pop()));
  }

  void handleAssignmentExpression(Token operator) {
    pop(); // lhs
    pop(); // rhs
    push(new Invalid(hint: "assign"));
  }

  void handleIndexedExpression(
      Token openSquareBracket, Token closeSquareBracket) {
    debugEvent("Index");
    if (ignore) return;
    pop(); // receiver
    pop(); // index
    push(new Invalid(hint: "index"));
  }

  void handleNamedArgument(colon) {
    debugEvent("NamedArg");
    if (ignore) return;
    var value = pop();
    Ref name = pop();
    push(new NamedArg(name.name, value));
  }

  void endNewExpression(Token token) {
    debugEvent("NewExpression");
    if (ignore) return;
    pop(); // args
    pop(); // ctor
    push(new Invalid(hint: "new"));
  }

  void handleNoConstructorReferenceContinuationAfterTypeArguments(Token token) {
    debugEvent("NoConstructorReferenceContinuationAfterTypeArguments");
  }

  void handleUnaryPostfixAssignmentExpression(Token operator) {
    pop();
    push(new Invalid(hint: "postfixOp"));
  }

  void handleUnaryPrefixAssignmentExpression(Token operator) {
    pop();
    push(new Invalid(hint: "prefixOp"));
  }

  void _endFunction() {
    assert(_withinFunction >= 0);
    push(new Invalid(hint: 'function'));
  }

  // TODO(paulberry): is this needed?
  //void _endCascade() {
  //  push(new Invalid(hint: 'cascades'));
  //}

  void _unhandledSend() {
    push(new Invalid(hint: "call"));
  }
}

// bit-masks to encode async modifiers as bits on an int.

/// Parser listener to build simplified AST expressions.
///
/// The parser produces different trees depending on whether it is used for
/// constants or initializers, so subclasses specialize the logic accordingly.
abstract class ExpressionListener extends StackListener {
  // Underlying parser that invokes this listener.
  static const _invariantCheckToken = "invariant check: starting a function";

  int _withinFunction = 0;

  int _withinCascades = 0;

  /// Whether this listener is used to build const expressions.
  bool get forConst => false;

  /// Whether to ignore the next reduction. Used to ignore nested expressions
  /// that are either invalid (in constants) or unnecessary (for initializers).
  bool get ignore => _withinFunction > 0 || _withinCascades > 0;

  Parser get parser;

  void beginCascade(Token token) {
    _withinCascades++;
  }

  void beginFunctionDeclaration(token) {
    debugEvent("BeginFunctionDeclaration");
    _withinFunction++;
  }

  void beginLiteralString(Token token) {
    debugEvent("beginLiteralString");
    if (ignore) return;
    push(new StringLiteral(token.lexeme));
  }

  void beginUnnamedFunction(token) {
    debugEvent("BeginUnnamedFunction");
    var check = pop();
    assert(check == _invariantCheckToken);
    _withinFunction++;
  }

  UnlinkedExprBuilder computeExpression(Token token, Scope scope) {
    debugStart(token);
    parser.parseExpression(token);
    debugEvent('---- END ---');
    Expression node = pop();
    checkEmpty();
    return new Serializer(scope, forConst).run(node);
  }

  void debugEvent(String name) {
    if (const bool.fromEnvironment('CDEBUG', defaultValue: false)) {
      var s = stack.join(' :: ');
      if (s == '') s = '<empty>';
      var bits = '$_withinFunction,$_withinCascades';
      var prefix = ignore ? "ignore $name on:" : "do $name on:";
      prefix = '$prefix${" " * (30 - prefix.length)}';
      print('$prefix $bits $s');
    }
  }

  void debugStart(Token token) {
    debugEvent('\n---- START: $runtimeType ---');
    if (const bool.fromEnvironment('CDEBUG', defaultValue: false)) {
      _printExpression(token);
    }
  }

  void endCascade() {
    _withinCascades--;
    throw new UnimplementedError(); // TODO(paulberry): fix the code below.
    // _endCascade();
  }

  void endConstructorReference(
      Token start, Token periodBeforeName, Token endToken) {
    debugEvent("ConstructorReference $start $periodBeforeName");
    Ref ctorName = popIfNotNull(periodBeforeName);
    assert(ctorName?.prefix == null);
    List<TypeRef> typeArgs = pop();
    Ref type = pop();
    push(new ConstructorName(new TypeRef(type, typeArgs), ctorName?.name));
  }

  void endFormalParameter(Token thisKeyword, Token nameToken,
      FormalParameterType kind, MemberKind memberKind) {
    debugEvent("FormalParameter");
    assert(ignore);
  }

  void endFormalParameters(
      int count, Token beginToken, Token endToken, MemberKind kind) {
    debugEvent("FormalParameters");
    assert(ignore);
  }

  void endBlockFunctionBody(int count, Token begin, Token end) {
    debugEvent("BlockFunctionBody");
    assert(ignore);
  }

  void endFunctionDeclaration(token) {
    debugEvent("FunctionDeclaration");
    _withinFunction--;
    if (ignore) return;
    _endFunction();
  }

  void endFunctionName(Token beginToken, Token token) {
    debugEvent("FunctionName");
    assert(ignore);
  }

  void endLiteralMapEntry(colon, token) {
    debugEvent('MapEntry');
    if (ignore) return;
    var value = pop();
    var key = pop();
    push(new KeyValuePair(key, value));
  }

  void endLiteralString(int interpolationCount, Token endToken) {
    debugEvent("endLiteralString");
    if (interpolationCount != 0) {
      popList(2 * interpolationCount + 1);
      push(new StringLiteral("<interpolate $interpolationCount>"));
    }
  }

  void endLiteralSymbol(token, int dots) {
    debugEvent('LiteralSymbol');
    if (ignore) return;
    push(new SymbolLiteral(popList(dots).join('.')));
  }

  void endReturnStatement(hasValue, Token begin, Token end) {
    debugEvent("ReturnStatement");
    assert(ignore);
  }

  // type-arguments are expected to be type references passed to constructors
  // and generic methods, we need them to model instantiations.
  void endSend(Token beginToken, Token endToken) {
    debugEvent("EndSend");
    if (ignore) return;
    List<Expression> args = pop();
    if (args != null) {
      /* var typeArgs = */ pop();
      var receiver = pop();
      // TODO(sigmund): consider making identical a binary operator.
      if (receiver is Ref && receiver.name == 'identical') {
        assert(receiver.prefix == null);
        assert(args.length == 2);
        push(new Identical(args[0], args[1]));
        return;
      }
      _unhandledSend();
    }
  }

  void endThrowExpression(throwToken, token) {
    debugEvent("Throw");
    assert(ignore);
  }

  void endTypeArguments(int count, Token beginToken, Token endToken) {
    debugEvent("TypeArguments");
    if (ignore) return;
    push(popList(count) ?? const <TypeRef>[]);
  }

  void endTypeList(int count) {
    debugEvent("TypeList");
    push(popList(count) ?? const <TypeRef>[]);
  }

  void endTypeVariable(Token token, Token extendsOrSuper) {
    debugEvent("endTypeVariable");
    assert(ignore);
  }

  void endTypeVariables(int count, Token beginToken, Token endToken) {
    debugEvent("TypeVariables");
    assert(ignore);
  }

  void endUnnamedFunction(Token beginToken, Token token) {
    debugEvent("UnnamedFunction");
    _withinFunction--;
    if (ignore) return;
    _endFunction();
  }

  void handleAsyncModifier(Token asyncToken, Token starToken) {
    debugEvent("AsyncModifier");
    assert(ignore);
  }

  void handleBinaryExpression(Token operator) {
    debugEvent("BinaryExpression");
    if (ignore) return;
    Expression right = pop();
    Expression left = pop();
    var kind = operator.kind;
    if (kind == PERIOD_TOKEN) {
      if (left is Ref &&
          right is Ref &&
          right.prefix == null &&
          left.prefixDepth < 2) {
        push(new Ref(right.name, left));
        return;
      }
      if (right is Ref) {
        push(new Load(left, right.name));
        return;
      }
    }
    push(new Binary(left, right, kind));
  }

  void handleConditionalExpression(Token question, Token colon) {
    debugEvent("ConditionalExpression");
    if (ignore) return;
    var falseBranch = pop();
    var trueBranch = pop();
    var cond = pop();
    push(new Conditional(cond, trueBranch, falseBranch));
  }

  @override
  void endConstExpression(Token token) {
    debugEvent("ConstExpression");
    if (ignore) return;
    List args = pop();
    var constructorName = pop();
    var positional = args.where((a) => a is! NamedArg).toList();
    var named = args.where((a) => a is NamedArg).toList();
    push(new ConstCreation(constructorName, positional, named));
  }

  void handleIdentifier(Token token, IdentifierContext context) {
    debugEvent("Identifier");
    if (ignore) return;
    push(new Ref(token.lexeme));
  }

  void handleIsOperator(Token operator, Token not, Token endToken) {
    debugEvent("Is");
    if (ignore) return;
    push(new Is(pop(), pop()));
  }

  void handleLiteralBool(Token token) {
    debugEvent("LiteralBool");
    if (ignore) return;
    push(new BoolLiteral(token.lexeme == 'true'));
  }

  void handleLiteralDouble(Token token) {
    debugEvent("LiteralDouble");
    if (ignore) return;
    push(new DoubleLiteral(double.parse(token.lexeme)));
  }

  void handleLiteralInt(Token token) {
    debugEvent("LiteralInt");
    if (ignore) return;
    push(new IntLiteral(int.parse(token.lexeme)));
  }

  void handleLiteralList(count, begin, constKeyword, end) {
    debugEvent("LiteralList");
    if (ignore) return;
    var values = popList(count) ?? const <Expression>[];
    List<TypeRef> typeArguments = pop();
    var type = typeArguments?.single;
    push(new ListLiteral(type, values, constKeyword != null));
  }

  void handleLiteralMap(count, begin, constKeyword, end) {
    debugEvent('LiteralMap');
    if (ignore) return;
    var values = popList(count) ?? const <KeyValuePair>[];
    var typeArgs = pop() ?? const <TypeRef>[];
    push(new MapLiteral(typeArgs, values, constKeyword != null));
  }

  void handleLiteralNull(Token token) {
    debugEvent("LiteralNull");
    if (ignore) return;
    push(new NullLiteral());
  }

  void handleModifier(Token token) {
    debugEvent("Modifier");
    assert(ignore);
  }

  // TODO(sigmund): remove
  void handleModifiers(int count) {
    debugEvent("Modifiers");
    assert(ignore);
  }

  // type-variables are the declared parameters on declarations.
  void handleNoArguments(Token token) {
    debugEvent("NoArguments");
    if (ignore) return;
    var typeArguments = pop();
    assert(typeArguments == null);
    push(NullValue.Arguments);
  }

  void handleNoFormalParameters(Token token, MemberKind kind) {
    debugEvent("NoFormalParameters");
    assert(ignore);
  }

  void handleNoFunctionBody(Token token) {
    debugEvent("NoFunctionBody");
    assert(ignore);
  }

  void handleNoInitializer() {}

  void handleNoInitializers() {
    debugEvent("NoInitializers");
    assert(ignore);
  }

  void handleNoType(Token token) {
    debugEvent("NoType");
    if (ignore) return;
    push(NullValue.Type);
  }

  void handleNoTypeArguments(Token token) {
    debugEvent("NoTypeArguments");
    if (ignore) return;
    push(NullValue.TypeArguments);
  }

  void handleNoTypeVariables(Token token) {
    debugEvent("NoTypeVariables");
    if (ignore) return;
    push(_invariantCheckToken);
  }

  void handleQualified(period) {
    debugEvent('Qualified');
    if (ignore) return;
    Ref name = pop();
    Ref prefix = pop();
    assert(name.prefix == null);
    assert(prefix.prefix == null);
    push(new Ref(name.name, prefix));
  }

  void handleStringJuxtaposition(int count) {
    debugEvent("StringJuxtaposition");
    if (ignore) return;
    popList(count);
    push(new StringLiteral('<juxtapose $count>'));
  }

  void handleStringPart(token) {
    debugEvent("handleStringPart");
    if (ignore) return;
    push(new StringLiteral(token.lexeme));
  }

  void handleType(Token beginToken, Token endToken) {
    debugEvent("Type");
    if (ignore) return;
    List<TypeRef> arguments = pop();
    Ref name = pop();
    push(new TypeRef(name, arguments));
  }

  void handleUnaryPrefixExpression(Token operator) {
    debugEvent("UnaryPrefix");
    if (ignore) return;
    push(new Unary(pop(), operator.kind));
  }

  void handleVoidKeyword(Token token) {
    debugEvent("VoidKeyword");
    assert(ignore);
  }

  /// Overriden: the base class throws when something is not handled, we avoid
  /// implementing a few handlers when we know we can ignore them.
  @override
  void logEvent(e) {
    if (ignore) return;
    super.logEvent(e);
  }

  void push(Object o);

  // debug helpers

  void _endFunction();

  void _printExpression(Token token) {
    var current = token;
    var end = new ClassMemberParser(this).skipExpression(current);
    var str = new StringBuffer();
    while (current != end) {
      if (!["(", ",", ")"].contains(current.lexeme)) str.write(' ');
      str.write(current.lexeme);
      current = current.next;
    }
    print('exp: $str');
  }

  void _unhandledSend();
}

/// Builder for initializer expressions. These expressions exclude any nested
/// expression that is not needed to infer strong mode types.
class InitializerBuilder extends ExpressionListener {
  final Uri uri;
  Parser parser;

  int _inArguments = 0;

  InitializerBuilder(this.uri) {
    parser = new Parser(this);
  }

  bool get ignore => super.ignore || _inArguments > 0;

  void beginArguments(Token token) {
    // TODO(sigmund): determine if we can ignore arguments.
    //_inArguments++;
  }

  // Not necessary, but we don't use the value, so we can abstract it:
  void endArguments(int count, Token begin, Token end) {
    debugEvent("Arguments");
    //_inArguments--;
    if (ignore) return;
    push(popList(count) ?? const []);
    //push([new Opaque(hint: "arguments")]);
  }

  void handleAsOperator(Token op, Token next) {
    debugEvent("As");
    if (ignore) return;
    TypeRef type = pop();
    pop();
    push(new Opaque(type: type));
  }

  void handleAssignmentExpression(Token operator) {
    debugEvent("Assign");
    if (ignore) return;
    var left = pop();
    var right = pop();
    var kind = operator.kind;
    if (kind == EQ_TOKEN) {
      push(new OpaqueOp(right));
    } else {
      push(new OpaqueOp(new Binary(left, right, opForAssignOp(kind))));
    }
  }

  void handleIndexedExpression(
      Token openSquareBracket, Token closeSquareBracket) {
    debugEvent("Index");
    if (ignore) return;
    pop();
    pop();
    push(new Opaque());
  }

  void handleIsOperator(Token operator, Token not, Token endToken) {
    debugEvent("Is");
    if (ignore) return;
    throw new UnimplementedError(); // TODO(paulberry): fix the code below.
    // push(new Opaque(type: new TypeRef(new Ref('bool'))));
  }

  void handleNamedArgument(colon) {
    debugEvent("NamedArg");
    if (ignore) return;
    pop();
    pop();
    push(NullValue.Arguments);
  }

  void endNewExpression(Token token) {
    debugEvent("NewExpression");
    if (ignore) return;
    pop(); // args
    /* var ctor = */ pop(); // ctor
    throw new UnimplementedError(); // TODO(paulberry): fix the code below.
    // push(new Opaque(type: ctor.type, hint: "new"));
  }

  void handleNoConstructorReferenceContinuationAfterTypeArguments(Token token) {
    debugEvent("NoConstructorReferenceContinuationAfterTypeArguments");
  }

  void handleUnaryPostfixAssignmentExpression(Token operator) {
    debugEvent("PostFix");
    if (ignore) return;
    // the post-fix effect is not visible to the enclosing expression
    push(new OpaqueOp(pop()));
  }

  void handleUnaryPrefixAssignmentExpression(Token operator) {
    debugEvent("Prefix");
    if (ignore) return;
    var kind = operator.kind == PLUS_PLUS_TOKEN ? PLUS_TOKEN : MINUS_TOKEN;
    push(new OpaqueOp(new Binary(pop(), new IntLiteral(1), kind)));
  }

  void _endFunction() {
    push(new Opaque(hint: "function"));
  }

  // TODO(paulberry): is this needed?
  //void _endCascade() {
  //  push(new OpaqueOp(pop(), hint: 'cascades'));
  //}

  void _unhandledSend() {
    push(new Opaque(hint: "call"));
  }
}

/// A listener of parser events that builds summary information as parsing
/// progresses.
class SummaryBuilder extends StackListener {
  static int parsed = 0;

  static int total = 0;

  /// Whether 'dart:core' was imported explicitly by the current unit.
  bool isDartCoreImported = false;

  /// Whether the current unit is part of 'dart:core'.
  bool isCoreLibrary = false;

  /// Topmost scope.
  TopScope topScope;

  /// Current scope where name references are resolved from.
  Scope scope;

  /// Helper to build constant expressions.
  final ConstExpressionBuilder constBuilder;

  /// Helper to build initializer expressions.
  final InitializerBuilder initializerBuilder;

  /// Whether the current initializer has a type declared.
  ///
  /// Because initializers are only used for strong-mode inference, we can skip
  /// parsing and building initializer expressions when a type is declared.
  bool typeSeen = false;

  /// Whether we are currently in the context of a const expression.
  bool inConstContext = false;

  /// Uri of the file currently being processed, used for error reporting only.
  final Uri uri;

  /// Summaries preassign slots for computed information, this is the next
  /// available slot.
  int _slots = 0;

  UnlinkedParamKind _nextParamKind;

  SummaryBuilder(Uri uri)
      : uri = uri,
        constBuilder = new ConstExpressionBuilder(uri),
        initializerBuilder = new InitializerBuilder(uri);

  /// Whether we need to parse the initializer of a declaration.
  bool get needInitializer => !typeSeen || inConstContext;

  // Directives: imports, exports, parts

  /// Assign the next slot.
  int assignSlot() => ++_slots;

  void beginClassDeclaration(Token beginToken, Token name) {
    debugEvent("beginClass");
    var classScope = scope = new ClassScope(scope);
    classScope.className = name.lexeme;
  }

  void beginCompilationUnit(Token token) {
    scope = topScope = new TopScope();
  }

  void beginEnum(Token token) {
    debugEvent("beginEnum");
    scope = new EnumScope(scope);
  }

  beginFieldInitializer(Token token) {
    debugEvent("beginFieldInitializer");
    total++;
    if (needInitializer) {
      parsed++;
      if (inConstContext) {
        push(constBuilder.computeExpression(token.next, scope));
      } else {
        push(initializerBuilder.computeExpression(token.next, scope));
      }
    }
  }

  void beginFormalParameters(Token token, MemberKind kind) {
    _nextParamKind = UnlinkedParamKind.required;
  }

  void beginFunctionTypeAlias(Token token) {
    debugEvent('beginFunctionTypeAlias');
    // TODO: use a single scope
    scope = new TypeParameterScope(scope);
  }

  beginInitializer(Token token) {
    // TODO(paulberry): Add support for this.
  }

  void beginLiteralString(Token token) {
    debugEvent("beginLiteralString");
    push(token.lexeme.substring(1, token.lexeme.length - 1));
  }

  void beginMember(Token token) {
    typeSeen = false;
    inConstContext = false;
  }

  // classes, enums, mixins, and typedefs.

  void beginNamedMixinApplication(Token beginToken, Token name) {
    debugEvent('beginNamedMixinApplication');
    scope = new ClassScope(scope);
  }

  void beginOptionalFormalParameters(Token begin) {
    _nextParamKind =
        begin == '{' ? UnlinkedParamKind.named : UnlinkedParamKind.positional;
  }

  void beginTopLevelMember(Token token) {
    typeSeen = false;
    inConstContext = false;
  }

  /// If enabled, show a debug message.
  void debugEvent(String name) {
    if (const bool.fromEnvironment('DEBUG', defaultValue: false)) {
      var s = stack.join(' :: ');
      if (s == '') s = '<empty>';
      var bits = 'type?: $typeSeen, const?: $inConstContext';
      var prefix = "do $name on:";
      prefix = '$prefix${" " * (30 - prefix.length)}';
      print('$prefix $bits $s');
    }
  }

  void endClassBody(int memberCount, Token beginToken, Token endToken) {
    debugEvent("ClassBody");
  }

  void endClassDeclaration(
      int interfacesCount,
      Token beginToken,
      Token classKeyword,
      Token extendsKeyword,
      Token implementsKeyword,
      Token endToken) {
    debugEvent("endClassDeclaration");
    List<EntityRefBuilder> interfaces = popList(interfacesCount);
    EntityRef supertype = pop();
    List<UnlinkedTypeParamBuilder> typeVariables = pop();
    String name = pop();
    int modifiers = pop();
    List metadata = pop();
    checkEmpty();

    ClassScope s = scope;
    s.className = name;
    s.currentClass
      ..name = name
      ..isAbstract = modifiers & _abstract_flag != 0
      ..annotations = metadata
      ..typeParameters = typeVariables
      ..interfaces = interfaces;
    if (supertype != null) {
      s.currentClass.supertype = supertype;
    } else {
      s.currentClass.hasNoSupertype = isCoreLibrary && name == 'Object';
    }
    scope = scope.parent;
    topScope.unit.classes.add(s.currentClass);
    if (_isPrivate(name)) return;
    s.publicName
      ..name = name
      ..kind = ReferenceKind.classOrEnum
      ..numTypeParameters = typeVariables?.length;
    topScope.publicNamespace.names.add(s.publicName);
  }

  void endCombinators(int count) {
    debugEvent("Combinators");
    push(popList(count) ?? NullValue.Combinators);
  }

  void endCompilationUnit(int count, Token token) {
    if (!isDartCoreImported) {
      topScope.unit.imports.add(new UnlinkedImportBuilder(isImplicit: true));
    }

    topScope.expandLazyReferences();

    // TODO(sigmund): could this be be optional: done by whoever consumes it?
    if (const bool.fromEnvironment('SKIP_API')) return;
    var apiSignature = new ApiSignature();
    topScope.unit.collectApiSignature(apiSignature);
    topScope.unit.apiSignature = apiSignature.toByteList();
  }

  void endConditionalUri(Token ifKeyword, Token equalitySign) {
    String dottedName = pop();
    String value = pop();
    String uri = pop();
    uri = uri.substring(1, uri.length - 1);
    push(new UnlinkedConfigurationBuilder(
        name: dottedName, value: value, uri: uri));
  }

  void endConditionalUris(int count) {
    push(popList(count) ?? const <UnlinkedConfigurationBuilder>[]);
  }

  // members: fields, methods.

  void endConstructorReference(
      Token start, Token periodBeforeName, Token endToken) {
    var ctorName = popIfNotNull(periodBeforeName);
    var typeArguments = pop();
    var className = pop();
    push(['ctor-ref:', className, typeArguments, ctorName]);
  }

  void endDottedName(count, firstIdentifier) {
    push(popList(count).join('.'));
  }

  void endEnum(Token enumKeyword, Token endBrace, int count) {
    debugEvent("Enum");
    List<String> constants = popList(count);
    String name = pop();
    List metadata = pop();
    checkEmpty();
    EnumScope s = scope;
    scope = s.parent;
    s.currentEnum
      ..name = name
      ..annotations = metadata;
    s.top.unit.enums.add(s.currentEnum);

    // public namespace:
    var e = new UnlinkedPublicNameBuilder(
        name: name, kind: ReferenceKind.classOrEnum, numTypeParameters: 0);
    for (var s in constants) {
      e.members.add(new UnlinkedPublicNameBuilder(
          name: s, kind: ReferenceKind.propertyAccessor, numTypeParameters: 0));
    }
    topScope.publicNamespace.names.add(e);
  }

  void endExport(Token exportKeyword, Token semicolon) {
    debugEvent("Export");
    List<UnlinkedCombinator> combinators = pop();
    List<UnlinkedConfiguration> conditionalUris = pop();
    String uri = pop();
    List<UnlinkedExpr> metadata = pop();
    topScope.unit.exports
        .add(new UnlinkedExportNonPublicBuilder(annotations: metadata));
    topScope.publicNamespace.exports.add(new UnlinkedExportPublicBuilder(
        uri: uri, combinators: combinators, configurations: conditionalUris));
    checkEmpty();
  }

  void endFactoryMethod(
      Token beginToken, Token factoryKeyword, Token endToken) {
    debugEvent("FactoryMethod");
    throw new UnimplementedError(); // TODO(paulberry)
    // pop(); // async-modifiers
    // /* List<FormalParameterBuilder> formals = */ pop();
    // var name = pop();
    // /* List<MetadataBuilder> metadata = */ pop();
  }

  void endFieldInitializer(Token assignmentOperator, Token token) {
    debugEvent("FieldInitializer $typeSeen $assignmentOperator");
    // This is a variable initializer and it's ignored for now. May also be
    // constructor initializer.
    var initializer =
        needInitializer && assignmentOperator != null ? pop() : null;
    var name = pop();
    push(new _InitializedName(
        name, new UnlinkedExecutableBuilder(bodyExpr: initializer)));
  }

  void endFields(int count, Token beginToken, Token endToken) {
    debugEvent("Fields");
    var s = scope;
    if (s is ClassScope) {
      _endFields(count, s.currentClass.fields, false);
    } else {
      throw new UnimplementedError(); // TODO(paulberry): does this ever occur?
      // _endFields(count, s.currentEnum.values, false);
    }
  }

  void endFormalParameter(Token thisKeyword, Token nameToken,
      FormalParameterType kind, MemberKind memberKind) {
    debugEvent("FormalParameter");
    // TODO(sigmund): clean up?
    var nameOrFormal = pop();
    if (nameOrFormal is String) {
      EntityRef type = pop();
      pop(); // Modifiers
      List metadata = pop();
      push(new UnlinkedParamBuilder(
          name: nameOrFormal,
          kind: _nextParamKind,
          inheritsCovariantSlot: slotIf(type == null),
          annotations: metadata,
          isInitializingFormal: thisKeyword != null,
          type: type));
    } else {
      push(nameOrFormal);
    }
  }

  void endFormalParameters(
      int count, Token beginToken, Token endToken, MemberKind kind) {
    debugEvent("FormalParameters");
    List formals = popList(count);
    if (formals != null && formals.isNotEmpty) {
      var last = formals.last;
      if (last is List) {
        var newList = new List(formals.length - 1 + last.length);
        newList.setRange(0, formals.length - 1, formals);
        newList.setRange(formals.length - 1, newList.length, last);
        for (int i = 0; i < last.length; i++) {
          newList[i + formals.length - 1] = last[i];
        }
        formals = newList;
      }
    }
    push(formals ?? NullValue.FormalParameters);
  }

  void endFunctionTypeAlias(
      Token typedefKeyword, Token equals, Token endToken) {
    debugEvent("endFunctionTypeAlias");
    List formals = pop();
    List typeVariables = pop();
    String name = pop();
    EntityRef returnType = pop();
    List metadata = pop();
    // print('TODO: type alias $name');
    checkEmpty();

    scope = scope.parent;
    topScope.unit.typedefs.add(new UnlinkedTypedefBuilder(
        name: name,
        typeParameters: typeVariables,
        returnType: returnType,
        parameters: formals,
        annotations: metadata));

    _addNameIfPublic(name, ReferenceKind.typedef, typeVariables.length);
  }

  void endFunctionTypedFormalParameter() {
    debugEvent("FunctionTypedFormalParameter");
    List<UnlinkedParamBuilder> formals = pop();
    if (formals != null) formals.forEach((p) => p.inheritsCovariantSlot = null);

    String name = pop();
    EntityRef returnType = pop();
    /* List typeVariables = */ pop();
    /* int modifiers = */ pop();
    List metadata = pop();

    push(new UnlinkedParamBuilder(
        name: name,
        kind: _nextParamKind,
        isFunctionTyped: true,
        parameters: formals,
        annotations: metadata,
        type: returnType));
  }

  void endHide(_) {
    push(new UnlinkedCombinatorBuilder(hides: pop()));
  }

  void endIdentifierList(int count) {
    debugEvent("endIdentifierList");
    push(popList(count) ?? NullValue.IdentifierList);
  }

  void endImport(Token importKeyword, Token deferredKeyword, Token asKeyword,
      Token semicolon) {
    debugEvent("endImport");
    List<UnlinkedCombinator> combinators = pop();
    String prefix = popIfNotNull(asKeyword);
    int prefixIndex =
        prefix == null ? null : topScope.serializeReference(null, prefix);
    List<UnlinkedConfiguration> conditionalUris = pop();
    String uri = pop();
    List<UnlinkedExpr> metadata = pop(); // metadata

    topScope.unit.imports.add(new UnlinkedImportBuilder(
      uri: uri,
      prefixReference: prefixIndex,
      combinators: combinators,
      configurations: conditionalUris,
      isDeferred: deferredKeyword != null,
      annotations: metadata,
    ));
    if (uri == 'dart:core') isDartCoreImported = true;
    checkEmpty();
  }

  void endInitializer(Token assignmentOperator) {
    // TODO(paulberry): add support for this.
    debugEvent("Initializer $typeSeen $assignmentOperator");
  }

  void endInitializers(int count, Token beginToken, Token endToken) {
    debugEvent("Initializers");
    // TODO(sigmund): include const-constructor initializers
  }

  void endLibraryName(Token libraryKeyword, Token semicolon) {
    debugEvent("endLibraryName");
    String name = pop();
    List<UnlinkedExpr> metadata = pop(); // metadata

    topScope.unit.libraryName = name;
    topScope.unit.libraryAnnotations = metadata;
    if (name == 'dart.core') isCoreLibrary = true;
  }

  void endLiteralString(int interpolationCount, Token endToken) {
    assert(interpolationCount == 0); // TODO(sigmund): handle interpolation
  }

  void endMember() {
    debugEvent("Member");
  }

  // TODO(sigmund): handle metadata (this code is incomplete).
  void endMetadata(Token beginToken, Token periodBeforeName, Token endToken) {
    debugEvent("Metadata");
    List arguments = pop();
    var result = new UnlinkedExprBuilder();
    // If arguments are null, this is an expression, otherwise a constructor
    // reference.
    if (arguments == null) {
      /* String postfix = */ popIfNotNull(periodBeforeName);
      /* String expression = */ pop();
      //push([expression, postfix]); // @x or @p.x
    } else {
      /* String name = */ popIfNotNull(periodBeforeName);
      // TODO(ahe): Type arguments are missing, eventually they should be
      // available as part of [arguments].
      // List<String> typeArguments = null;
      /* EntityRef typeName = */ pop();
      //push([typeName, typeArguments, name, arguments]);
    }
    push(result);
  }

  void endMetadataStar(int count, bool forParameter) {
    debugEvent("MetadataStar");
    push(popList(count) ?? NullValue.Metadata);
  }

  void endMethod(Token getOrSet, Token beginToken, Token endToken) {
    debugEvent("Method");
    int asyncModifier = pop();
    List<UnlinkedParam> formals = pop();
    List<UnlinkedTypeParamBuilder> typeVariables = pop();
    String name = pop();
    EntityRef returnType = pop();
    int modifiers = pop();
    List metadata = pop();

    ClassScope s = scope;
    bool isStatic = modifiers & _static_flag != 0;
    bool isConst = modifiers & _const_flag != 0;
    bool isGetter = getOrSet == 'get';
    bool isSetter = getOrSet == 'set';
    bool isOperator = name == "operator"; // TODO
    bool isConstructor =
        name == s.className || name.startsWith('${s.className}.');

    if (isConstructor) {
      name = name == s.className ? '' : name.substring(name.indexOf('.') + 1);
    }

    name = isSetter ? '$name=' : name;
    // Note: we don't include bodies for any method.
    s.currentClass.executables.add(new UnlinkedExecutableBuilder(
        name: name,
        kind: isGetter
            ? UnlinkedExecutableKind.getter
            : (isSetter
                ? UnlinkedExecutableKind.setter
                : (isConstructor
                    ? UnlinkedExecutableKind.constructor
                    : UnlinkedExecutableKind.functionOrMethod)),
        isExternal: modifiers & _external_flag != 0,
        isAbstract: modifiers & _abstract_flag != 0,
        isAsynchronous: asyncModifier & _async_flag != 0,
        isGenerator: asyncModifier & _star_flag != 0,
        isStatic: isStatic,
        isConst: isConst,
        constCycleSlot: slotIf(isConst),
        typeParameters: typeVariables,
        returnType: returnType,
        parameters: formals, // TODO: add inferred slot to args
        annotations: metadata,
        inferredReturnTypeSlot:
            slotIf(returnType == null && !isStatic && !isConstructor)));

    if (isConstructor && name == '') return;
    if (_isPrivate(name)) return;
    if (isSetter || isOperator) return;
    if (!isStatic && !isConstructor) return;
    s.publicName.members.add(new UnlinkedPublicNameBuilder(
        name: name,
        kind: isGetter
            ? ReferenceKind.propertyAccessor
            : (isConstructor
                ? ReferenceKind.constructor
                : ReferenceKind.method),
        numTypeParameters: typeVariables.length));
  }

  void endMixinApplication(Token withKeyword) {
    debugEvent("MixinApplication");
    ClassScope s = scope;
    s.currentClass.mixins = pop();
  }

  void endNamedMixinApplication(Token begin, Token classKeyword, Token equals,
      Token implementsKeyword, Token endToken) {
    debugEvent("endNamedMixinApplication");
    List<EntityRef> interfaces = popIfNotNull(implementsKeyword);
    EntityRef supertype = pop();
    List typeVariables = pop();
    String name = pop();
    int modifiers = pop();
    List metadata = pop();
    // print('TODO: end mix, $name');
    checkEmpty();

    ClassScope s = scope;
    s.currentClass
      ..name = name
      ..isAbstract = modifiers & _abstract_flag != 0
      ..isMixinApplication = true
      ..annotations = metadata
      ..typeParameters = typeVariables
      ..interfaces = interfaces;
    if (supertype != null) {
      s.currentClass.supertype = supertype;
    } else {
      s.currentClass.hasNoSupertype = isCoreLibrary && name == 'Object';
    }
    scope = scope.parent;
    topScope.unit.classes.add(s.currentClass);

    _addNameIfPublic(name, ReferenceKind.classOrEnum, typeVariables.length);
  }

  void endOptionalFormalParameters(
      int count, Token beginToken, Token endToken) {
    debugEvent("OptionalFormalParameters");
    push(popList(count));
  }

  void endPart(Token partKeyword, Token semicolon) {
    debugEvent("Part");
    String uri = pop();
    List<UnlinkedExpr> metadata = pop();
    topScope.unit.parts.add(new UnlinkedPartBuilder(annotations: metadata));
    topScope.publicNamespace.parts.add(uri);
    checkEmpty();
  }

  void endPartOf(Token partKeyword, Token semicolon, bool hasName) {
    debugEvent("endPartOf");
    String name = pop();
    pop(); // metadata
    topScope.unit.isPartOf = true;
    if (name == 'dart.core') isCoreLibrary = true;
  }

  void endRedirectingFactoryBody(Token beginToken, Token endToken) {
    debugEvent("RedirectingFactoryBody");
    pop(); // Discard ConstructorReferenceBuilder.
  }

  void endShow(_) {
    push(new UnlinkedCombinatorBuilder(shows: pop()));
  }

  void endTopLevelFields(int count, Token beginToken, Token endToken) {
    debugEvent("endTopLevelFields");
    _endFields(count, topScope.unit.variables, true);
    checkEmpty();
  }

  void endTopLevelMethod(Token beginToken, Token getOrSet, Token endToken) {
    debugEvent("endTopLevelMethod");
    int asyncModifier = pop();
    List formals = pop();
    List typeVariables = pop();
    String name = pop();
    EntityRef returnType = pop();
    int modifiers = pop();
    List metadata = pop();
    checkEmpty();

    topScope.unit.executables.add(new UnlinkedExecutableBuilder(
      name: getOrSet == 'set' ? '$name=' : name,
      kind: getOrSet == 'get'
          ? UnlinkedExecutableKind.getter
          : (getOrSet == 'set'
              ? UnlinkedExecutableKind.setter
              : UnlinkedExecutableKind.functionOrMethod),
      isExternal: modifiers & _external_flag != 0,
      isAbstract: modifiers & _abstract_flag != 0,
      isAsynchronous: asyncModifier & _async_flag != 0,
      isGenerator: asyncModifier & _star_flag != 0,
      isStatic: modifiers & _static_flag != 0,
      typeParameters: [], // TODO
      returnType: returnType,
      parameters: formals,
      annotations: metadata,
      inferredReturnTypeSlot: null, // not needed for top-levels
      // skip body.
    ));

    String normalizedName = getOrSet == 'set' ? '$name=' : name;
    _addNameIfPublic(
        normalizedName,
        getOrSet != null
            ? ReferenceKind.topLevelPropertyAccessor
            : ReferenceKind.topLevelFunction,
        typeVariables?.length ?? 0 /* todo */);
  }

  void endTypeArguments(int count, Token beginToken, Token endToken) {
    debugEvent("TypeArguments");
    push(popList(count) ?? const []);
  }

  void endTypeList(int count) {
    debugEvent("TypeList");
    push(popList(count) ?? NullValue.TypeList);
  }

  void endTypeVariable(Token token, Token extendsOrSuper) {
    debugEvent("endTypeVariable");
    EntityRef bound = pop();
    String name = pop();

    var s = scope;
    if (s is TypeParameterScope) {
      s.typeParameters.add(name);
    } else {
      throw new UnimplementedError(); // TODO(paulberry)
    }
    push(new UnlinkedTypeParamBuilder(name: name, bound: bound));
  }

  void endTypeVariables(int count, Token beginToken, Token endToken) {
    debugEvent("TypeVariables");
    push(popList(count) ?? const []);
  }

  void handleAsyncModifier(Token asyncToken, Token starToken) {
    debugEvent("AsyncModifier");
    int asyncModifier = 0;
    if (asyncToken == "async") asyncModifier |= _async_flag;
    if (asyncToken == "sync") asyncModifier |= _sync_flag;
    if (starToken != null) asyncModifier |= _star_flag;
    push(asyncModifier);
  }

  void handleFormalParameterWithoutValue(Token token) {
    debugEvent("FormalParameterWithoutValue");
  }

  void handleModifier(Token token) {
    debugEvent("Modifier");
    var modifier = _modifierFlag[token.stringValue];
    if (modifier & _const_flag != 0) inConstContext = true;
    push(modifier);
  }

  void handleModifiers(int count) {
    debugEvent("Modifiers");
    push((popList(count) ?? const []).fold/*<int>*/(0, (a, b) => a | b));
  }

  void handleNoConstructorReferenceContinuationAfterTypeArguments(Token token) {
    debugEvent("NoConstructorReferenceContinuationAfterTypeArguments");
  }

  void handleNoFieldInitializer(Token token) {
    debugEvent("NoFieldInitializer");
    push(new _InitializedName(pop(), null));
  }

  void handleNoFunctionBody(Token token) {
    debugEvent("NoFunctionBody");
    // Ignored for now. We shouldn't see any function bodies.
  }

  void handleNoInitializers() {
    debugEvent("NoInitializers");
    // This is a constructor initializer and it's ignored for now.
  }

  void handleNoTypeVariables(Token token) {
    debugEvent("NoTypeVariables");
    push(const []);
  }

  void handleOperatorName(Token operatorKeyword, Token token) {
    // TODO(sigmund): convert operator names to name used by summaries.
    debugEvent("OperatorName");
    push(operatorKeyword.lexeme);
  }

  void handleQualified(Token period) {
    debugEvent("handleQualified");
    String name = pop();
    String receiver = pop();
    push("$receiver.$name");
  }

  void handleStringPart(token) {
    debugEvent("handleStringPart");
    push(token.lexeme.substring(1, token.lexeme.length - 1));
  }

  void handleType(Token beginToken, Token endToken) {
    debugEvent("Type");
    List<EntityRef> arguments = pop();
    String name = pop();

    var type;
    if (name.contains('.')) {
      var parts = name.split('.');
      for (var p in parts) {
        type = type == null
            ? new LazyEntityRef(p, scope)
            : new NestedLazyEntityRef(type, p, scope);
      }
    } else {
      type = new LazyEntityRef(name, scope);
    }
    type.typeArguments = arguments;
    push(type);
    typeSeen = true;
  }

  // helpers to work with the summary format.

  void handleValuedFormalParameter(Token equals, Token token) {
    debugEvent("ValuedFormalParameter");
    // TODO(sigmund): include default value on optional args.
  }

  void handleVoidKeyword(Token token) {
    debugEvent("VoidKeyword");
    // TODO: skip the lazy mechanism
    push(new LazyEntityRef("void", scope.top));
  }

  /// Assign the next slot if [condition] is true.
  int slotIf(bool condition) => condition ? assignSlot() : 0;

  /// Add [name] to the public namespace.
  void _addName(String name, ReferenceKind kind, {int numTypeParameters: 0}) {
    topScope.publicNamespace.names.add(new UnlinkedPublicNameBuilder(
        name: name, kind: kind, numTypeParameters: numTypeParameters));
  }

  /// Add [name] to the public namespace if it's public.
  void _addNameIfPublic(
      String name, ReferenceKind kind, int numTypeParameters) {
    if (_isPrivate(name)) return null;
    _addName(name, kind, numTypeParameters: numTypeParameters);
  }

  /// Add `name` and, if requested, `name=` to the public namespace.
  void _addPropertyName(String name, {bool includeSetter: false}) {
    _addName(name, ReferenceKind.topLevelPropertyAccessor);
    if (includeSetter) {
      _addName('$name=', ReferenceKind.topLevelPropertyAccessor);
    }
  }

  void _endFields(int count, List result, bool isTopLevel) {
    debugEvent('EndFields: $count $isTopLevel');
    List<_InitializedName> fields = popList(count);
    EntityRef type = pop();
    int modifiers = pop();
    List metadata = pop();

    bool isStatic = modifiers & _static_flag != 0;
    bool isFinal = modifiers & _final_flag != 0;
    bool isConst = modifiers & _const_flag != 0;
    bool isInstance = !isStatic && !isTopLevel;
    for (var field in fields) {
      var name = field.name;
      var initializer = field.initializer;
      bool needsPropagatedType = initializer != null && (isFinal || isConst);
      bool needsInferredType =
          type == null && (initializer != null || isInstance);
      result.add(new UnlinkedVariableBuilder(
          isFinal: isFinal,
          isConst: isConst,
          isStatic: isStatic,
          name: name,
          type: type,
          annotations: metadata,
          initializer: initializer,
          propagatedTypeSlot: slotIf(needsPropagatedType),
          inferredTypeSlot: slotIf(needsInferredType)));

      if (_isPrivate(name)) continue;
      if (isTopLevel) {
        _addPropertyName(name, includeSetter: !isFinal && !isConst);
      } else if (isStatic) {
        // Any reason setters are not added as well?
        (scope as ClassScope).publicName.members.add(
            new UnlinkedPublicNameBuilder(
                name: name,
                kind: ReferenceKind.propertyAccessor,
                numTypeParameters: 0));
      }
    }
  }

  /// Whether a name is private and should be excluded from the public
  /// namespace.
  bool _isPrivate(String name) => name.startsWith('_');
}

/// Internal representation of an initialized name.
class _InitializedName {
  final String name;
  final UnlinkedExecutableBuilder initializer;
  _InitializedName(this.name, this.initializer);

  toString() => "II:" + (initializer != null ? "$name = $initializer" : name);
}
