// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/messages/codes.dart';
import 'package:_fe_analyzer_shared/src/parser/parser.dart';
import 'package:_fe_analyzer_shared/src/parser/quote.dart';
import 'package:_fe_analyzer_shared/src/parser/stack_listener.dart';
import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:_fe_analyzer_shared/src/util/null_value.dart';
import 'package:_fe_analyzer_shared/src/util/value_kind.dart';

import 'arguments.dart';
import 'elements.dart';
import 'expressions.dart';
import 'formal_parameters.dart';
import 'proto.dart';
import 'record_fields.dart';
import 'references.dart';
import 'scope.dart';
import 'string_literal_parts.dart';
import 'type_annotations.dart';

/// Parser listener that can create [Expression] node for metadata annotations
/// and constant expressions.
class AnnotationsListener extends StackListener {
  @override
  final bool isDartLibrary;

  @override
  final Uri uri;

  final Scope _initialScope;

  final References _references;

  final bool delayLookup;

  AnnotationsListener(
    this.uri,
    this._initialScope,
    this._references, {
    required this.delayLookup,
    required this.isDartLibrary,
  });

  final List<FunctionTypeParameterScope> _typeParameterScopes = [];

  Scope get _scope =>
      _typeParameterScopes.isEmpty ? _initialScope : _typeParameterScopes.last;

  @override
  void beginMetadata(Token token) {}

  @override
  void endMetadata(Token beginToken, Token? periodBeforeName, Token endToken) {
    assert(
      checkState(beginToken, [
        /*arguments*/ _ValueKinds._ArgumentsOrNull,
        /*suffix*/ if (periodBeforeName != null) _ValueKinds._IdentifierProto,
        /*type arguments*/ _ValueKinds._TypeAnnotationsOrNull,
        /*type*/ _ValueKinds._Proto,
      ]),
    );
    List<Argument>? arguments = pop(_NullValues.Arguments) as List<Argument>?;
    IdentifierProto? identifier = periodBeforeName != null
        ? pop() as IdentifierProto
        : null;
    List<TypeAnnotation>? typeArguments =
        pop(_NullValues.TypeAnnotations) as List<TypeAnnotation>?;
    Proto proto = pop() as Proto;
    push(
      proto
          .instantiate(typeArguments)
          .apply(identifier)
          .invoke(arguments)
          .toExpression(),
    );
  }

  @override
  void endMetadataStar(int count) {
    assert(checkState(null, repeatedKind(_ValueKinds._Expression, count)));
    List<Expression> expressions = new List.filled(count, _dummyExpression);
    while (--count >= 0) {
      expressions[count] = pop() as Expression;
    }
    push(expressions);
  }

  @override
  void handleIdentifier(Token token, IdentifierContext context) {
    switch (context) {
      case IdentifierContext.metadataReference:
      case IdentifierContext.typeReference:
      case IdentifierContext.prefixedTypeReference:
      case IdentifierContext.expression:
      case IdentifierContext.constructorReference:
        String name = token.lexeme;
        if (delayLookup) {
          push(new UnresolvedIdentifier(_scope, name));
        } else {
          push(_scope.lookup(name));
        }
      case IdentifierContext.typeVariableDeclaration:
        String name = token.lexeme;
        push(_typeParameterScopes.last.declareTypeParameter(name));
      case IdentifierContext.metadataContinuation:
      case IdentifierContext.metadataContinuationAfterTypeArguments:
      case IdentifierContext.typeReferenceContinuation:
      case IdentifierContext.literalSymbol:
      case IdentifierContext.expressionContinuation:
      case IdentifierContext.constructorReferenceContinuation:
      case IdentifierContext.constructorReferenceContinuationAfterTypeArguments:
      case IdentifierContext.namedRecordFieldReference:
      case IdentifierContext.namedArgumentReference:
      case IdentifierContext.formalParameterDeclaration:
      case IdentifierContext.recordFieldDeclaration:
        push(new IdentifierProto(token.lexeme));
      default:
        throw new UnsupportedError("Unsupported context $context");
    }
  }

  @override
  void endConstructorReference(
    Token start,
    Token? periodBeforeName,
    Token endToken,
    ConstructorReferenceContext constructorReferenceContext,
  ) {
    assert(
      checkState(start, [
        if (periodBeforeName != null)
          /* constructor name */ _ValueKinds._IdentifierProto,
        /* type arguments */ _ValueKinds._TypeAnnotationsOrNull,
        /* (qualified) name before type arguments */ _ValueKinds._Proto,
      ]),
    );
    IdentifierProto? constructorName = periodBeforeName != null
        ? pop() as IdentifierProto
        : null;
    List<TypeAnnotation>? typeArguments =
        pop(_NullValues.TypeAnnotations) as List<TypeAnnotation>?;
    Proto className = pop() as Proto;
    push(className.instantiate(typeArguments).apply(constructorName));
  }

  @override
  void endConstExpression(Token token) {
    assert(
      checkState(token, [
        /* arguments */ _ValueKinds._Arguments,
        /* constructor reference */ _ValueKinds._Proto,
      ]),
    );
    List<Argument> arguments = pop() as List<Argument>;
    Proto constructorReference = pop() as Proto;
    push(constructorReference.invoke(arguments));
  }

  @override
  void handleLiteralList(
    int count,
    Token leftBracket,
    Token? constKeyword,
    Token rightBracket,
  ) {
    assert(
      checkState(leftBracket, [
        ...repeatedKind(_ValueKinds._ElementOrProto, count),
        _ValueKinds._TypeAnnotationsOrNull,
      ]),
    );
    List<Element> elements = new List.filled(count, _dummyElement);
    while (--count >= 0) {
      elements[count] = _popElementOrProto();
    }
    List<TypeAnnotation>? typeArguments =
        pop(_NullValues.TypeAnnotations) as List<TypeAnnotation>?;
    push(
      new ExpressionProto(new ListLiteral(typeArguments ?? const [], elements)),
    );
  }

  Element _popElementOrProto() {
    Object? element = pop();
    if (element is Element) {
      return element;
    } else {
      return new ExpressionElement(
        (element as Proto).toExpression(),
        isNullAware: false,
      );
    }
  }

  Expression _popExpression() {
    return (pop() as Proto).toExpression();
  }

  Argument _popArgument() {
    Object? argument = pop();
    if (argument is Argument) {
      return argument;
    } else {
      return new PositionalArgument((argument as Proto).toExpression());
    }
  }

  RecordField _popRecordField() {
    Object? field = pop();
    if (field is RecordField) {
      return field;
    } else {
      return new RecordPositionalField((field as Proto).toExpression());
    }
  }

  @override
  void handleLiteralSetOrMap(
    int count,
    Token leftBrace,
    Token? constKeyword,
    Token rightBrace,
    bool hasSetEntry,
  ) {
    assert(
      checkState(leftBrace, [
        ...repeatedKind(_ValueKinds._ElementOrProto, count),
        _ValueKinds._TypeAnnotationsOrNull,
      ]),
    );
    List<Element> elements = new List.filled(count, _dummyElement);
    while (--count >= 0) {
      elements[count] = _popElementOrProto();
    }
    List<TypeAnnotation>? typeArguments =
        pop(_NullValues.TypeAnnotations) as List<TypeAnnotation>?;
    push(
      new ExpressionProto(
        new SetOrMapLiteral(typeArguments ?? const [], elements),
      ),
    );
  }

  @override
  void handleLiteralMapEntry(
    Token colon,
    Token endToken, {
    Token? nullAwareKeyToken,
    Token? nullAwareValueToken,
  }) {
    assert(
      checkState(colon, [
        /* value */ _ValueKinds._Proto,
        /* key */ _ValueKinds._Proto,
      ]),
    );
    Expression value = _popExpression();
    Expression key = _popExpression();
    push(
      new MapEntryElement(
        key,
        value,
        isNullAwareKey: nullAwareKeyToken != null,
        isNullAwareValue: nullAwareValueToken != null,
      ),
    );
  }

  @override
  void handleSpreadExpression(Token spreadToken) {
    assert(checkState(spreadToken, [/* expression */ _ValueKinds._Proto]));
    Proto expression = pop() as Proto;
    push(
      new SpreadElement(
        expression.toExpression(),
        isNullAware: spreadToken.lexeme == '...?',
      ),
    );
  }

  @override
  void handleNullAwareElement(Token nullAwareToken) {
    assert(checkState(nullAwareToken, [/* expression */ _ValueKinds._Proto]));
    Proto expression = pop() as Proto;
    push(new ExpressionElement(expression.toExpression(), isNullAware: true));
  }

  @override
  void handleParenthesizedCondition(Token token, Token? case_, Token? when) {
    if (case_ != null) {
      throw new UnsupportedError(
        "handleParenthesizedCondition($token,$case_,$when",
      );
    } else {
      assert(checkState(token, [_ValueKinds._Proto]));
    }
  }

  @override
  void endIfControlFlow(Token token) {
    assert(
      checkState(token, [
        /* then */ _ValueKinds._ElementOrProto,
        /* condition */ _ValueKinds._Proto,
      ]),
    );
    Element then = _popElementOrProto();
    Expression condition = _popExpression();
    push(new IfElement(condition, then));
  }

  @override
  void handleElseControlFlow(Token elseToken) {
    assert(
      checkState(elseToken, [
        /* otherwise */ unionOfKinds([
          _ValueKinds._Element,
          _ValueKinds._Proto,
        ]),
      ]),
    );
  }

  @override
  void endIfElseControlFlow(Token token) {
    assert(
      checkState(token, [
        /* otherwise */ unionOfKinds([
          _ValueKinds._Element,
          _ValueKinds._Proto,
        ]),
        /* then */ unionOfKinds([_ValueKinds._Element, _ValueKinds._Proto]),
        /* condition */ _ValueKinds._Proto,
      ]),
    );
    Element otherwise = _popElementOrProto();
    Element then = _popElementOrProto();
    Expression condition = _popExpression();
    push(new IfElement(condition, then, otherwise));
  }

  @override
  void endConstLiteral(Token token) {
    assert(checkState(token, [_ValueKinds._Proto]));
  }

  @override
  void handleNamedRecordField(Token colon) {
    assert(
      checkState(colon, [
        /* expression */ _ValueKinds._Proto,
        /* name */ _ValueKinds._IdentifierProto,
      ]),
    );
    Expression expression = _popExpression();
    IdentifierProto name = pop() as IdentifierProto;
    push(new RecordNamedField(name.text, expression));
  }

  @override
  void endRecordLiteral(Token token, int count, Token? constKeyword) {
    assert(
      checkState(
        token,
        /* fields */ repeatedKind(_ValueKinds._RecordFieldOrProto, count),
      ),
    );
    List<RecordField> fields = new List.filled(count, _dummyRecordField);
    while (--count >= 0) {
      fields[count] = _popRecordField();
    }
    push(new ExpressionProto(new RecordLiteral(fields)));
  }

  @override
  void handleDotAccess(Token token, Token endToken, bool isNullAware) {
    assert(
      checkState(token, [
        /* right */ _ValueKinds._Proto,
        /* left */ _ValueKinds._Proto,
      ]),
    );
    Proto right = pop() as Proto;
    Proto left = pop() as Proto;
    IdentifierProto identifierProto = right as IdentifierProto;
    push(left.apply(identifierProto, isNullAware: isNullAware));
  }

  @override
  void endBinaryExpression(Token token, Token endToken) {
    assert(
      checkState(token, [
        /* right */ _ValueKinds._Proto,
        /* left */ _ValueKinds._Proto,
      ]),
    );
    Proto right = pop() as Proto;
    Proto left = pop() as Proto;
    switch (token.lexeme) {
      case '??':
        push(
          new ExpressionProto(
            new IfNull(left.toExpression(), right.toExpression()),
          ),
        );
      case '||':
        push(
          new ExpressionProto(
            new LogicalExpression(
              left.toExpression(),
              LogicalOperator.or,
              right.toExpression(),
            ),
          ),
        );
      case '&&':
        push(
          new ExpressionProto(
            new LogicalExpression(
              left.toExpression(),
              LogicalOperator.and,
              right.toExpression(),
            ),
          ),
        );
      case '==':
        push(
          new ExpressionProto(
            new EqualityExpression(
              left.toExpression(),
              right.toExpression(),
              isNotEquals: false,
            ),
          ),
        );
      case '!=':
        push(
          new ExpressionProto(
            new EqualityExpression(
              left.toExpression(),
              right.toExpression(),
              isNotEquals: true,
            ),
          ),
        );
      case '>':
        push(
          new ExpressionProto(
            new BinaryExpression(
              left.toExpression(),
              BinaryOperator.greaterThan,
              right.toExpression(),
            ),
          ),
        );
      case '>=':
        push(
          new ExpressionProto(
            new BinaryExpression(
              left.toExpression(),
              BinaryOperator.greaterThanOrEqual,
              right.toExpression(),
            ),
          ),
        );
      case '<':
        push(
          new ExpressionProto(
            new BinaryExpression(
              left.toExpression(),
              BinaryOperator.lessThan,
              right.toExpression(),
            ),
          ),
        );
      case '<=':
        push(
          new ExpressionProto(
            new BinaryExpression(
              left.toExpression(),
              BinaryOperator.lessThanOrEqual,
              right.toExpression(),
            ),
          ),
        );
      case '<<':
        push(
          new ExpressionProto(
            new BinaryExpression(
              left.toExpression(),
              BinaryOperator.shiftLeft,
              right.toExpression(),
            ),
          ),
        );
      case '>>':
        push(
          new ExpressionProto(
            new BinaryExpression(
              left.toExpression(),
              BinaryOperator.signedShiftRight,
              right.toExpression(),
            ),
          ),
        );
      case '>>>':
        push(
          new ExpressionProto(
            new BinaryExpression(
              left.toExpression(),
              BinaryOperator.unsignedShiftRight,
              right.toExpression(),
            ),
          ),
        );
      case '+':
        push(
          new ExpressionProto(
            new BinaryExpression(
              left.toExpression(),
              BinaryOperator.plus,
              right.toExpression(),
            ),
          ),
        );
      case '-':
        push(
          new ExpressionProto(
            new BinaryExpression(
              left.toExpression(),
              BinaryOperator.minus,
              right.toExpression(),
            ),
          ),
        );
      case '*':
        push(
          new ExpressionProto(
            new BinaryExpression(
              left.toExpression(),
              BinaryOperator.times,
              right.toExpression(),
            ),
          ),
        );
      case '/':
        push(
          new ExpressionProto(
            new BinaryExpression(
              left.toExpression(),
              BinaryOperator.divide,
              right.toExpression(),
            ),
          ),
        );
      case '~/':
        push(
          new ExpressionProto(
            new BinaryExpression(
              left.toExpression(),
              BinaryOperator.integerDivide,
              right.toExpression(),
            ),
          ),
        );
      case '%':
        push(
          new ExpressionProto(
            new BinaryExpression(
              left.toExpression(),
              BinaryOperator.modulo,
              right.toExpression(),
            ),
          ),
        );
      case '|':
        push(
          new ExpressionProto(
            new BinaryExpression(
              left.toExpression(),
              BinaryOperator.bitwiseOr,
              right.toExpression(),
            ),
          ),
        );
      case '&':
        push(
          new ExpressionProto(
            new BinaryExpression(
              left.toExpression(),
              BinaryOperator.bitwiseAnd,
              right.toExpression(),
            ),
          ),
        );
      case '^':
        push(
          new ExpressionProto(
            new BinaryExpression(
              left.toExpression(),
              BinaryOperator.bitwiseXor,
              right.toExpression(),
            ),
          ),
        );
      default:
        throw new UnimplementedError("Binary operator '${token.lexeme}'.");
    }
  }

  @override
  void handleIsOperator(Token isOperator, Token? not) {
    assert(
      checkState(isOperator, [
        /* type */ _ValueKinds._TypeAnnotation,
        /* expression */ _ValueKinds._Proto,
      ]),
    );
    TypeAnnotation type = pop() as TypeAnnotation;
    Expression expression = _popExpression();
    push(new ExpressionProto(new IsTest(expression, type, isNot: not != null)));
  }

  @override
  void handleAsOperator(Token operator) {
    assert(
      checkState(operator, [
        /* type */ _ValueKinds._TypeAnnotation,
        /* expression */ _ValueKinds._Proto,
      ]),
    );
    TypeAnnotation type = pop() as TypeAnnotation;
    Expression expression = _popExpression();
    push(new ExpressionProto(new AsExpression(expression, type)));
  }

  @override
  void endIsOperatorType(Token operator) {
    // Do nothing.
  }

  @override
  void endAsOperatorType(Token operator) {
    // Do nothing.
  }

  @override
  void handleUnaryPrefixExpression(Token token) {
    assert(checkState(token, [/* expression */ _ValueKinds._Proto]));
    Expression expression = _popExpression();
    switch (token.lexeme) {
      case '-':
        push(
          new ExpressionProto(
            new UnaryExpression(UnaryOperator.minus, expression),
          ),
        );
      case '!':
        push(
          new ExpressionProto(
            new UnaryExpression(UnaryOperator.bang, expression),
          ),
        );
      case '~':
        push(
          new ExpressionProto(
            new UnaryExpression(UnaryOperator.tilde, expression),
          ),
        );
      default:
        throw new UnimplementedError("Unary operator '${token.lexeme}'.");
    }
  }

  @override
  void handleNonNullAssertExpression(Token bang) {
    assert(checkState(bang, [/* expression */ _ValueKinds._Proto]));
    Expression expression = _popExpression();
    push(new ExpressionProto(new NullCheck(expression)));
  }

  @override
  void handleQualified(Token period) {
    assert(
      checkState(period, [
        /* suffix */ _ValueKinds._IdentifierProto,
        /* prefix */ _ValueKinds._Proto,
      ]),
    );
    IdentifierProto suffix = pop() as IdentifierProto;
    Proto prefix = pop() as Proto;
    push(prefix.apply(suffix));
  }

  @override
  void handleSend(Token beginToken, Token endToken) {
    assert(
      checkState(beginToken, [
        _ValueKinds._ArgumentsOrNull,
        _ValueKinds._TypeAnnotationsOrNull,
        _ValueKinds._Proto,
      ]),
    );
    List<Argument>? arguments = pop(_NullValues.Arguments) as List<Argument>?;
    List<TypeAnnotation>? typeArguments =
        pop(_NullValues.TypeAnnotations) as List<TypeAnnotation>?;
    Proto proto = pop() as Proto;
    assert(
      typeArguments == null || arguments != null,
      'Unexpected type argument application as send.',
    );
    push(proto.instantiate(typeArguments).invoke(arguments));
  }

  @override
  void handleNoArguments(Token token) {
    push(_NullValues.Arguments);
  }

  @override
  void handleNamedArgument(Token colon) {
    assert(
      checkState(colon, [
        /* expression */ _ValueKinds._Proto,
        /* name */ _ValueKinds._IdentifierProto,
      ]),
    );
    Expression expression = _popExpression();
    IdentifierProto name = pop() as IdentifierProto;
    push(new NamedArgument(name.text, expression));
  }

  @override
  void endArguments(int count, Token beginToken, Token endToken) {
    assert(
      checkState(
        beginToken,
        /* arguments */ repeatedKind(_ValueKinds._ArgumentOrProto, count),
      ),
    );
    List<Argument> arguments = new List.filled(count, _dummyArgument);
    while (--count >= 0) {
      arguments[count] = _popArgument();
    }
    push(arguments);
  }

  @override
  void handleNoTypeArguments(Token token) {
    push(_NullValues.TypeAnnotations);
  }

  @override
  void endTypeArguments(int count, Token beginToken, Token endToken) {
    assert(
      checkState(
        beginToken,
        /* type arguments */ repeatedKind(_ValueKinds._TypeAnnotation, count),
      ),
    );
    List<TypeAnnotation> typeArguments = new List.filled(
      count,
      _dummyTypeAnnotation,
    );
    while (--count >= 0) {
      typeArguments[count] = pop() as TypeAnnotation;
    }
    push(typeArguments);
  }

  @override
  void handleType(Token beginToken, Token? questionMark) {
    assert(
      checkState(beginToken, [
        _ValueKinds._TypeAnnotationsOrNull,
        _ValueKinds._Proto,
      ]),
    );
    List<TypeAnnotation>? typeArguments =
        pop(_NullValues.TypeAnnotations) as List<TypeAnnotation>?;
    Proto type = pop() as Proto;
    TypeAnnotation typeAnnotation = type
        .instantiate(typeArguments)
        .toTypeAnnotation();
    if (questionMark != null) {
      typeAnnotation = new NullableTypeAnnotation(typeAnnotation);
    }
    push(typeAnnotation);
  }

  @override
  void handleVoidKeywordWithTypeArguments(Token token) {
    assert(checkState(token, [_ValueKinds._TypeAnnotationsOrNull]));
    List<TypeAnnotation>? typeArguments =
        pop(_NullValues.TypeAnnotations) as List<TypeAnnotation>?;
    push(
      new VoidProto(
        _references.voidReference,
      ).instantiate(typeArguments).toTypeAnnotation(),
    );
  }

  @override
  void handleVoidKeyword(Token token) {
    push(new VoidProto(_references.voidReference).toTypeAnnotation());
  }

  @override
  void handleLiteralInt(Token token) {
    int? value = intFromToken(token, hasSeparators: false);
    push(new ExpressionProto(new IntegerLiteral.fromText(token.lexeme, value)));
  }

  @override
  void handleLiteralIntWithSeparators(Token token) {
    int? value = intFromToken(token, hasSeparators: true);
    push(new ExpressionProto(new IntegerLiteral.fromText(token.lexeme, value)));
  }

  @override
  void handleLiteralDouble(Token token) {
    push(
      new ExpressionProto(
        new DoubleLiteral(
          token.lexeme,
          doubleFromToken(token, hasSeparators: false),
        ),
      ),
    );
  }

  @override
  void handleLiteralDoubleWithSeparators(Token token) {
    push(
      new ExpressionProto(
        new DoubleLiteral(
          token.lexeme,
          doubleFromToken(token, hasSeparators: true),
        ),
      ),
    );
  }

  @override
  void handleLiteralBool(Token token) {
    push(new ExpressionProto(new BooleanLiteral(boolFromToken(token))));
  }

  @override
  void handleLiteralNull(Token token) {
    push(new ExpressionProto(new NullLiteral()));
  }

  @override
  void beginLiteralString(Token token) {
    push(new StringPart(token.lexeme));
  }

  @override
  void handleStringPart(Token token) {
    push(new StringPart(token.lexeme));
  }

  @override
  void endLiteralString(int interpolationCount, Token endToken) {
    int count = 1 + interpolationCount * 2;
    assert(
      checkState(
        endToken,
        repeatedKind(
          unionOfKinds([_ValueKinds._StringPart, _ValueKinds._Proto]),
          count,
        ),
      ),
    );
    if (interpolationCount == 0) {
      // TODO(johnniwinther): Use the token corresponding to [part].
      Token token = endToken;
      StringPart part = pop() as StringPart;
      String value = unescapeString(part.text, token, this);
      push(new ExpressionProto(new StringLiteral([new StringPart(value)])));
    } else {
      List<Object?> objects = new List.filled(count, /* dummyValue */ null);
      int index = count;
      while (--index >= 0) {
        objects[index] = pop();
      }
      StringPart first = objects.first as StringPart;
      StringPart last = objects.last as StringPart;
      Quote quote = analyzeQuote(first.text);
      List<StringLiteralPart> parts = [];
      // Contains more than just \' or \".
      if (first.text.length > 1) {
        // TODO(johnniwinther): Use the token corresponding to [first].
        Token token = endToken;
        String value = unescapeFirstStringPart(first.text, quote, token, this);
        if (value.isNotEmpty) {
          parts.add(new StringPart(value));
        }
      }
      for (int i = 1; i < objects.length - 1; i++) {
        Object? object = objects[i];
        if (object is StringPart) {
          if (object.text.length != 0) {
            // TODO(johnniwinther): Use the token corresponding to [object].
            Token token = endToken;
            String value = unescape(object.text, quote, token, this);
            parts.add(new StringPart(value));
          }
        } else {
          parts.add(new InterpolationPart((object as Proto).toExpression()));
        }
      }
      // Contains more than just \' or \".
      if (last.text.length > 1) {
        // TODO(johnniwinther): Use the token corresponding to [last].
        Token token = endToken;
        String value = unescapeLastStringPart(
          last.text,
          quote,
          token,
          token.isSynthetic,
          this,
        );
        if (value.isNotEmpty) {
          parts.add(new StringPart(value));
        }
      }
      push(new ExpressionProto(new StringLiteral(parts)));
    }
  }

  @override
  void handleAdjacentStringLiterals(Token startToken, int literalCount) {
    assert(
      checkState(startToken, repeatedKind(_ValueKinds._Proto, literalCount)),
    );
    List<Expression> expressions = new List.filled(
      literalCount,
      _dummyExpression,
    );
    while (--literalCount >= 0) {
      expressions[literalCount] = _popExpression();
    }
    push(new ExpressionProto(new AdjacentStringLiterals(expressions)));
  }

  @override
  void endLiteralSymbol(Token hashToken, int identifierCount) {
    assert(
      checkState(
        hashToken,
        repeatedKind(_ValueKinds._IdentifierProto, identifierCount),
      ),
    );
    List<String> parts = new List.filled(identifierCount, /* dummy value */ '');
    while (--identifierCount >= 0) {
      parts[identifierCount] = (pop() as IdentifierProto).text;
    }
    push(new ExpressionProto(new SymbolLiteral(parts)));
  }

  @override
  void handleTypeArgumentApplication(Token openAngleBracket) {
    assert(
      checkState(openAngleBracket, [
        _ValueKinds._TypeAnnotations,
        _ValueKinds._Proto,
      ]),
    );
    List<TypeAnnotation> typeArguments = pop() as List<TypeAnnotation>;
    Proto receiver = pop() as Proto;
    push(receiver.instantiate(typeArguments));
  }

  @override
  void endParenthesizedExpression(Token token) {
    assert(checkState(token, [_ValueKinds._Proto]));
    Expression expression = _popExpression();
    push(new ExpressionProto(new ParenthesizedExpression(expression)));
  }

  @override
  void endConditionalExpression(Token question, Token colon, Token endToken) {
    assert(
      checkState(question, [
        /* otherwise */ _ValueKinds._Proto,
        /* then */ _ValueKinds._Proto,
        /* condition */ _ValueKinds._Proto,
      ]),
    );
    Expression otherwise = _popExpression();
    Expression then = _popExpression();
    Expression condition = _popExpression();
    push(
      new ExpressionProto(
        new ConditionalExpression(condition, then, otherwise),
      ),
    );
  }

  @override
  void handleValuedFormalParameter(
    Token equals,
    Token token,
    FormalParameterKind kind,
  ) {
    assert(checkState(token, [_ValueKinds._Proto]));
    push(_popExpression());
  }

  @override
  void handleFormalParameterWithoutValue(Token token) {
    push(_NullValues.Expression);
  }

  @override
  void endFormalParameter(
    Token? thisKeyword,
    Token? superKeyword,
    Token? periodAfterThisOrSuper,
    Token nameToken,
    Token? initializerStart,
    Token? initializerEnd,
    FormalParameterKind kind,
    MemberKind memberKind,
  ) {
    assert(
      checkState(nameToken, [
        _ValueKinds._ExpressionOrNull,
        _ValueKinds._IdentifierProtoOrNull,
        _ValueKinds._TypeAnnotationOrNull,
        _ValueKinds._Expressions,
      ]),
    );
    Expression? defaultValue = pop() as Expression?;
    IdentifierProto? name = pop() as IdentifierProto?;
    TypeAnnotation? typeAnnotation = pop() as TypeAnnotation?;
    List<Expression> metadata = pop() as List<Expression>;
    push(
      new FormalParameter(
        metadata,
        typeAnnotation,
        name?.text,
        defaultValue,
        isNamed: kind.isNamed,
        isRequired: kind.isRequired,
      ),
    );
  }

  @override
  void handleNoName(Token token) {
    push(_NullValues.Identifier);
  }

  @override
  void endOptionalFormalParameters(
    int count,
    Token beginToken,
    Token endToken,
    MemberKind kind,
  ) {
    assert(
      checkState(beginToken, repeatedKind(_ValueKinds._FormalParameter, count)),
    );
    List<FormalParameter> formalParameters = new List.filled(
      count,
      _dummyFormalParameter,
    );
    while (--count >= 0) {
      formalParameters[count] = pop() as FormalParameter;
    }
    push(new FormalParameterGroup(formalParameters));
  }

  @override
  void endFormalParameters(
    int count,
    Token beginToken,
    Token endToken,
    MemberKind kind,
  ) {
    assert(
      checkState(
        beginToken,
        repeatedKind(
          unionOfKinds([
            _ValueKinds._FormalParameter,
            _ValueKinds._FormalParameterGroup,
          ]),
          count,
        ),
      ),
    );
    List<Object?> objects = new List.filled(count, /* dummy value */ null);
    while (--count >= 0) {
      objects[count] = pop();
    }
    List<FormalParameter> formalParameters = [];
    for (Object? object in objects) {
      if (object is FormalParameter) {
        formalParameters.add(object);
      } else {
        formalParameters.addAll(
          (object as FormalParameterGroup).formalParameters,
        );
      }
    }
    push(formalParameters);
  }

  @override
  void endTypeVariable(
    Token token,
    int index,
    Token? extendsOrSuper,
    Token? variance,
  ) {
    assert(
      checkState(token, [
        _ValueKinds._TypeAnnotationOrNull,
        _ValueKinds._FunctionTypeParameters,
      ]),
    );
    TypeAnnotation? bound = pop(_NullValues.TypeAnnotation) as TypeAnnotation?;
    List<FunctionTypeParameter> functionTypeParameters =
        pop() as List<FunctionTypeParameter>;
    FunctionTypeParameter functionTypeParameter = functionTypeParameters[index];
    functionTypeParameter.bound = bound;
    push(functionTypeParameters);
  }

  @override
  void handleTypeVariablesDefined(Token token, int count) {
    assert(
      checkState(
        token,
        repeatedKinds([
          _ValueKinds._FunctionTypeParameter,
          _ValueKinds._Expressions,
        ], count),
      ),
    );
    List<FunctionTypeParameter> functionTypeParameters = new List.filled(
      count,
      _dummyFunctionTypeParameter,
    );
    while (--count >= 0) {
      FunctionTypeParameter functionTypeParameter =
          functionTypeParameters[count] = pop() as FunctionTypeParameter;
      functionTypeParameter.metadata = pop() as List<Expression>;
    }
    push(functionTypeParameters);
  }

  @override
  void endTypeVariables(Token beginToken, Token endToken) {
    assert(checkState(beginToken, [_ValueKinds._FunctionTypeParameters]));
  }

  @override
  void beginFunctionType(Token beginToken) {
    _typeParameterScopes.add(new FunctionTypeParameterScope(_scope));
  }

  @override
  void endFunctionType(Token functionToken, Token? questionMark) {
    assert(
      checkState(functionToken, [
        _ValueKinds._FormalParameters,
        _ValueKinds._TypeAnnotationOrNull,
        _ValueKinds._FunctionTypeParametersOrNull,
      ]),
    );
    _typeParameterScopes.removeLast();

    List<FormalParameter> formalParameters = pop() as List<FormalParameter>;
    TypeAnnotation? returnType =
        pop(_NullValues.TypeAnnotation) as TypeAnnotation?;
    List<FunctionTypeParameter>? typeParameters =
        pop(_NullValues.FunctionTypeParameters) as List<FunctionTypeParameter>?;
    push(
      new FunctionTypeAnnotation(
        returnType,
        typeParameters ?? const [],
        formalParameters,
      ),
    );
  }

  @override
  void endRecordType(
    Token leftBracket,
    Token? questionMark,
    int count,
    bool hasNamedFields,
  ) {
    assert(
      checkState(
        leftBracket,
        hasNamedFields
            ? [
                _ValueKinds._RecordTypeEntries,
                ...repeatedKind(_ValueKinds._RecordTypeEntry, count - 1),
              ]
            : repeatedKind(_ValueKinds._RecordTypeEntry, count),
      ),
    );
    List<RecordTypeEntry>? named;
    if (hasNamedFields) {
      named = pop() as List<RecordTypeEntry>;
      count--;
    }
    List<RecordTypeEntry> positional = new List.filled(
      count,
      _dummyRecordTypeEntry,
    );
    while (--count >= 0) {
      positional[count] = pop() as RecordTypeEntry;
    }
    push(new RecordTypeAnnotation(positional, named ?? const []));
  }

  @override
  void endRecordTypeEntry() {
    assert(
      checkState(null, [
        _ValueKinds._IdentifierProtoOrNull,
        _ValueKinds._TypeAnnotation,
        _ValueKinds._Expressions,
      ]),
    );
    IdentifierProto? name = pop() as IdentifierProto?;
    TypeAnnotation type = pop() as TypeAnnotation;
    List<Expression> metadata = pop() as List<Expression>;
    push(new RecordTypeEntry(metadata, type, name?.text));
  }

  @override
  void endRecordTypeNamedFields(int count, Token leftBracket) {
    assert(
      checkState(
        leftBracket,
        repeatedKind(_ValueKinds._RecordTypeEntry, count),
      ),
    );
    List<RecordTypeEntry> entries = new List.filled(
      count,
      _dummyRecordTypeEntry,
    );
    while (--count >= 0) {
      entries[count] = pop() as RecordTypeEntry;
    }
    push(entries);
  }

  @override
  void handleNoType(Token lastConsumed) {
    push(_NullValues.TypeAnnotation);
  }

  @override
  void handleNoTypeVariables(Token token) {
    push(_NullValues.FunctionTypeParameters);
  }

  @override
  void addProblem(
    Message message,
    int charOffset,
    int length, {
    bool wasHandled = false,
    List<LocatedMessage> context = const [],
  }) {
    // Don't report errors.
  }

  @override
  Never internalProblem(Message message, int charOffset, Uri uri) {
    throw new UnimplementedError(message.problemMessage);
  }
}

class _NullValues {
  static const NullValue Arguments = const NullValue("Argument");
  static const NullValue Expression = const NullValue("Expression");
  static const NullValue FunctionTypeParameters = const NullValue(
    "FunctionTypeParameter",
  );
  static const NullValue Identifier = const NullValue("Identifier");
  static const NullValue TypeAnnotation = const NullValue("TypeAnnotation");
  static const NullValue TypeAnnotations = const NullValue("TypeAnnotations");
}

final Argument _dummyArgument = new PositionalArgument(
  new IntegerLiteral.fromText('0'),
);

final RecordField _dummyRecordField = new RecordPositionalField(
  _dummyExpression,
);

final TypeAnnotation _dummyTypeAnnotation = new InvalidTypeAnnotation();

final Expression _dummyExpression = new NullLiteral();

final Element _dummyElement = new ExpressionElement(
  _dummyExpression,
  isNullAware: false,
);

final FormalParameter _dummyFormalParameter = new FormalParameter(
  const [],
  null,
  null,
  null,
  isNamed: false,
  isRequired: false,
);

final FunctionTypeParameter _dummyFunctionTypeParameter =
    new FunctionTypeParameter('');

final RecordTypeEntry _dummyRecordTypeEntry = new RecordTypeEntry(
  const [],
  _dummyTypeAnnotation,
  null,
);

class _ValueKinds {
  static const ValueKind _Proto = const SingleValueKind<Proto>();
  static const ValueKind _IdentifierProto =
      const SingleValueKind<IdentifierProto>();
  static const ValueKind _IdentifierProtoOrNull =
      const SingleValueKind<IdentifierProto>(_NullValues.Identifier);
  static const ValueKind _Expression = const SingleValueKind<Expression>();
  static const ValueKind _ExpressionOrNull = const SingleValueKind<Expression>(
    _NullValues.Expression,
  );
  static const ValueKind _Expressions =
      const SingleValueKind<List<Expression>>();
  static const ValueKind _Element = const SingleValueKind<Element>();
  static final ValueKind _ElementOrProto = unionOfKinds([
    _ValueKinds._Element,
    _ValueKinds._Proto,
  ]);
  static const ValueKind _Argument = const SingleValueKind<Argument>();
  static final ValueKind _ArgumentOrProto = unionOfKinds([
    _ValueKinds._Argument,
    _ValueKinds._Proto,
  ]);
  static const ValueKind _RecordField = const SingleValueKind<RecordField>();
  static final ValueKind _RecordFieldOrProto = unionOfKinds([
    _ValueKinds._RecordField,
    _ValueKinds._Proto,
  ]);
  static final ValueKind _RecordTypeEntry =
      const SingleValueKind<RecordTypeEntry>();
  static final ValueKind _RecordTypeEntries =
      const SingleValueKind<List<RecordTypeEntry>>();
  static const ValueKind _Arguments = const SingleValueKind<List<Argument>>();
  static const ValueKind _ArgumentsOrNull =
      const SingleValueKind<List<Argument>>(_NullValues.Arguments);
  static const ValueKind _TypeAnnotation =
      const SingleValueKind<TypeAnnotation>();
  static const ValueKind _TypeAnnotationOrNull =
      const SingleValueKind<TypeAnnotation>(_NullValues.TypeAnnotation);
  static const ValueKind _TypeAnnotations =
      const SingleValueKind<List<TypeAnnotation>>();
  static const ValueKind _TypeAnnotationsOrNull =
      const SingleValueKind<List<TypeAnnotation>>(_NullValues.TypeAnnotations);
  static const ValueKind _StringPart = const SingleValueKind<StringPart>();
  static const ValueKind _FormalParameter =
      const SingleValueKind<FormalParameter>();
  static const ValueKind _FormalParameters =
      const SingleValueKind<List<FormalParameter>>();
  static const ValueKind _FormalParameterGroup =
      const SingleValueKind<FormalParameterGroup>();
  static const ValueKind _FunctionTypeParameter =
      const SingleValueKind<FunctionTypeParameter>();
  static const ValueKind _FunctionTypeParameters =
      const SingleValueKind<List<FunctionTypeParameter>>();
  static const ValueKind _FunctionTypeParametersOrNull =
      const SingleValueKind<List<FunctionTypeParameter>>(
        _NullValues.FunctionTypeParameters,
      );
}

/// Parses the metadata annotation beginning at [atToken].
Expression parseAnnotation(
  Token atToken,
  Uri fileUri,
  Scope scope,
  References references, {
  required bool isDartLibrary,
  bool delayLookupForTesting = false,
}) {
  AnnotationsListener listener = new AnnotationsListener(
    fileUri,
    scope,
    references,
    delayLookup: delayLookupForTesting,
    isDartLibrary: isDartLibrary,
  );
  Parser parser = new Parser(listener, useImplicitCreationExpression: false);
  parser.parseMetadata(parser.syntheticPreviousToken(atToken));
  return listener.pop() as Expression;
}

/// Parses the expression beginning at [initializerToken].
Expression parseExpression(
  Token initializerToken,
  Uri fileUri,
  Scope scope,
  References references, {
  required bool isDartLibrary,
  bool delayLookupForTesting = false,
}) {
  AnnotationsListener listener = new AnnotationsListener(
    fileUri,
    scope,
    references,
    delayLookup: delayLookupForTesting,
    isDartLibrary: isDartLibrary,
  );
  Parser parser = new Parser(listener, useImplicitCreationExpression: false);
  parser.parseExpression(parser.syntheticPreviousToken(initializerToken));
  return listener._popExpression();
}

/// A [Scope] extended to include function type parameters.
class FunctionTypeParameterScope implements Scope {
  final Scope parentScope;
  final Map<String, FunctionTypeParameter> functionTypeParameterMap = {};

  FunctionTypeParameterScope(this.parentScope);

  FunctionTypeParameter declareTypeParameter(String name) {
    return functionTypeParameterMap[name] = new FunctionTypeParameter(name);
  }

  @override
  Proto lookup(String name) {
    FunctionTypeParameter? functionTypeParameter =
        functionTypeParameterMap[name];
    if (functionTypeParameter != null) {
      return new FunctionTypeParameterProto(functionTypeParameter);
    }
    return parentScope.lookup(name);
  }
}
