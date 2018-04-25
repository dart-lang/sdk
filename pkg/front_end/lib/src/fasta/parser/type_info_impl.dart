// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.parser.type_info_impl;

import '../../scanner/token.dart' show Token;

import '../fasta_codes.dart' as fasta;

import '../util/link.dart' show Link;

import 'identifier_context.dart' show IdentifierContext;

import 'member_kind.dart' show MemberKind;

import 'listener.dart' show Listener;

import 'parser.dart' show Parser;

import 'type_info.dart';

import 'util.dart' show optional;

/// See documentation on the [noType] const.
class NoType implements TypeInfo {
  const NoType();

  @override
  bool get couldBeExpression => false;

  @override
  Token ensureTypeNotVoid(Token token, Parser parser) {
    parser.reportRecoverableErrorWithToken(
        token.next, fasta.templateExpectedType);
    insertSyntheticIdentifierAfter(token, parser);
    return simpleType.parseType(token, parser);
  }

  @override
  Token ensureTypeOrVoid(Token token, Parser parser) =>
      ensureTypeNotVoid(token, parser);

  @override
  Token parseTypeNotVoid(Token token, Parser parser) =>
      parseType(token, parser);

  @override
  Token parseType(Token token, Parser parser) {
    parser.listener.handleNoType(token);
    return token;
  }

  @override
  Token skipType(Token token) {
    return token;
  }
}

/// See documentation on the [prefixedType] const.
class PrefixedType implements TypeInfo {
  const PrefixedType();

  @override
  bool get couldBeExpression => true;

  @override
  Token ensureTypeNotVoid(Token token, Parser parser) =>
      parseType(token, parser);

  @override
  Token ensureTypeOrVoid(Token token, Parser parser) =>
      parseType(token, parser);

  @override
  Token parseTypeNotVoid(Token token, Parser parser) =>
      parseType(token, parser);

  @override
  Token parseType(Token token, Parser parser) {
    Token start = token = token.next;
    assert(token.isKeywordOrIdentifier);
    Listener listener = parser.listener;
    listener.handleIdentifier(token, IdentifierContext.prefixedTypeReference);

    Token period = token = token.next;
    assert(optional('.', token));

    token = token.next;
    assert(token.isKeywordOrIdentifier);
    listener.handleIdentifier(
        token, IdentifierContext.typeReferenceContinuation);
    listener.handleQualified(period);

    listener.handleNoTypeArguments(token.next);
    listener.handleType(start, token.next);
    return token;
  }

  @override
  Token skipType(Token token) {
    return token.next.next.next;
  }
}

/// See documentation on the [simpleTypeWith1Argument] const.
class SimpleTypeWith1Argument implements TypeInfo {
  const SimpleTypeWith1Argument();

  @override
  bool get couldBeExpression => false;

  @override
  Token ensureTypeNotVoid(Token token, Parser parser) =>
      parseType(token, parser);

  @override
  Token ensureTypeOrVoid(Token token, Parser parser) =>
      parseType(token, parser);

  @override
  Token parseTypeNotVoid(Token token, Parser parser) =>
      parseType(token, parser);

  @override
  Token parseType(Token token, Parser parser) {
    Token start = token = token.next;
    assert(token.isKeywordOrIdentifier);
    Listener listener = parser.listener;
    listener.handleIdentifier(token, IdentifierContext.typeReference);

    Token begin = token = token.next;
    assert(optional('<', token));
    listener.beginTypeArguments(token);

    token = simpleType.parseTypeNotVoid(token, parser);

    token = token.next;
    assert(optional('>', token));
    assert(begin.endGroup == token);
    listener.endTypeArguments(1, begin, token);

    listener.handleType(start, token.next);
    return token;
  }

  @override
  Token skipType(Token token) {
    return token.next.next.endGroup;
  }
}

/// See documentation on the [simpleType] const.
class SimpleType implements TypeInfo {
  const SimpleType();

  @override
  bool get couldBeExpression => true;

  @override
  Token ensureTypeNotVoid(Token token, Parser parser) =>
      parseType(token, parser);

  @override
  Token ensureTypeOrVoid(Token token, Parser parser) =>
      parseType(token, parser);

  @override
  Token parseTypeNotVoid(Token token, Parser parser) =>
      parseType(token, parser);

  @override
  Token parseType(Token token, Parser parser) {
    token = token.next;
    assert(token.isKeywordOrIdentifier);
    Listener listener = parser.listener;
    listener.handleIdentifier(token, IdentifierContext.typeReference);
    listener.handleNoTypeArguments(token.next);
    listener.handleType(token, token.next);
    return token;
  }

  @override
  Token skipType(Token token) {
    return token.next;
  }
}

/// See documentation on the [voidType] const.
class VoidType implements TypeInfo {
  const VoidType();

  @override
  bool get couldBeExpression => false;

  @override
  Token ensureTypeNotVoid(Token token, Parser parser) {
    // Report an error, then parse `void` as if it were a type name.
    parser.reportRecoverableError(token.next, fasta.messageInvalidVoid);
    return simpleType.parseTypeNotVoid(token, parser);
  }

  @override
  Token ensureTypeOrVoid(Token token, Parser parser) =>
      parseType(token, parser);

  @override
  Token parseTypeNotVoid(Token token, Parser parser) =>
      ensureTypeNotVoid(token, parser);

  @override
  Token parseType(Token token, Parser parser) {
    token = token.next;
    parser.listener.handleVoidKeyword(token);
    return token;
  }

  @override
  Token skipType(Token token) {
    return token.next;
  }
}

bool looksLikeName(Token token) =>
    token.isIdentifier || optional('this', token);

Token skipTypeVariables(Token token) {
  assert(optional('<', token));
  Token endGroup = token.endGroup;
  if (endGroup == null) {
    return null;
  }

  // The scanner sets the endGroup in situations like this: C<T && T>U;
  // Scan the type arguments to assert there are no operators.
  // TODO(danrubel): Fix the scanner to do this scanning.
  token = token.next;
  while (token != endGroup) {
    if (token.isKeywordOrIdentifier ||
        optional(',', token) ||
        optional('.', token) ||
        optional('<', token) ||
        optional('>', token) ||
        optional('>>', token) ||
        optional('@', token)) {
      // ok
    } else if (optional('(', token)) {
      token = token.endGroup;
    } else {
      return null;
    }
    token = token.next;
  }
  return endGroup;
}

/// Instances of [ComplexTypeInfo] are returned by [computeType] to represent
/// type references that cannot be represented by the constants above.
class ComplexTypeInfo implements TypeInfo {
  /// The first token in the type reference.
  Token start;

  /// The last token in the type reference.
  Token end;

  /// Non-null if type arguments were seen during analysis.
  Token typeArguments;

  /// The tokens before the start of type variables of function types seen
  /// during analysis. Notice that the tokens in this list might precede
  /// either `'<'` or `'('` as not all function types have type parameters.
  Link<Token> typeVariableStarters = const Link<Token>();

  /// If the receiver represents a generalized function type then this indicates
  /// whether it has a return type, otherwise this is `null`.
  bool gftHasReturnType;

  ComplexTypeInfo(Token beforeStart) : this.start = beforeStart.next;

  @override
  bool get couldBeExpression => false;

  @override
  Token ensureTypeNotVoid(Token token, Parser parser) =>
      parseType(token, parser);

  @override
  Token ensureTypeOrVoid(Token token, Parser parser) =>
      parseType(token, parser);

  @override
  Token parseTypeNotVoid(Token token, Parser parser) =>
      parseType(token, parser);

  @override
  Token parseType(Token token, Parser parser) {
    assert(identical(token.next, start));

    if (optional('.', start)) {
      // Recovery: Insert missing identifier without sending events
      start = parser.insertSyntheticIdentifier(
          token, IdentifierContext.prefixedTypeReference);
    }

    for (Link<Token> t = typeVariableStarters; t.isNotEmpty; t = t.tail) {
      parser.parseTypeVariablesOpt(t.head);
      parser.listener.beginFunctionType(start);
    }

    if (gftHasReturnType == false) {
      // A function type without return type.
      // Push the non-existing return type first. The loop below will
      // generate the full type.
      noType.parseTypeNotVoid(token, parser);
    } else {
      Token typeRefOrPrefix = token.next;
      if (optional('void', typeRefOrPrefix)) {
        token = voidType.parseType(token, parser);
      } else {
        if (!optional('.', typeRefOrPrefix) &&
            !optional('.', typeRefOrPrefix.next)) {
          token =
              parser.ensureIdentifier(token, IdentifierContext.typeReference);
        } else {
          token = parser.ensureIdentifier(
              token, IdentifierContext.prefixedTypeReference);
          token = parser.parseQualifiedRest(
              token, IdentifierContext.typeReferenceContinuation);
          if (token.isSynthetic && end == typeRefOrPrefix.next) {
            end = token;
          }
        }
        token = parser.parseTypeArgumentsOpt(token);
        parser.listener.handleType(typeRefOrPrefix, token.next);
      }
    }

    for (Link<Token> t = typeVariableStarters; t.isNotEmpty; t = t.tail) {
      token = token.next;
      assert(optional('Function', token));
      Token functionToken = token;
      if (optional("<", token.next)) {
        // Skip type parameters, they were parsed above.
        token = token.next.endGroup;
      }
      token = parser.parseFormalParametersRequiredOpt(
          token, MemberKind.GeneralizedFunctionType);
      parser.listener.endFunctionType(functionToken, token.next);
    }

    // There are two situations in which the [token] != [end]:
    // Valid code:    identifier `<` identifier `<` identifier `>>`
    //    where `>>` is replaced by two tokens.
    // Invalid code:  identifier `<` identifier identifier `>`
    //    where a synthetic `>` is inserted between the identifiers.
    assert(identical(token, end) || optional('>', token));

    // During recovery, [token] may be a synthetic that was inserted in the
    // middle of the type reference. In this situation, return [end] so that it
    // matches [skipType], and so that the next token to be parsed is correct.
    return token.isSynthetic ? end : token;
  }

  @override
  Token skipType(Token token) {
    return end;
  }

  /// Given `Function` non-identifier, compute the type
  /// and return the receiver or one of the [TypeInfo] constants.
  TypeInfo computeNoTypeGFT(bool required) {
    assert(optional('Function', start));
    computeRest(start, required);

    if (gftHasReturnType == null) {
      return required ? simpleType : noType;
    }
    assert(end != null);
    return this;
  }

  /// Given void `Function` non-identifier, compute the type
  /// and return the receiver or one of the [TypeInfo] constants.
  TypeInfo computeVoidGFT(bool required) {
    assert(optional('void', start));
    assert(optional('Function', start.next));
    computeRest(start.next, required);

    if (gftHasReturnType == null) {
      return voidType;
    }
    assert(end != null);
    return this;
  }

  /// Given a builtin, return the receiver so that parseType will report
  /// an error for the builtin used as a type.
  TypeInfo computeBuiltinAsType(bool required) {
    assert(start.type.isBuiltIn);
    end = start;
    Token token = start.next;
    if (optional('<', token)) {
      typeArguments = token;
      token = skipTypeVariables(typeArguments);
      if (token == null) {
        token = typeArguments;
        typeArguments = null;
      } else {
        end = token;
      }
    }
    computeRest(token, required);

    assert(end != null);
    return this;
  }

  /// Given identifier `Function` non-identifier, compute the type
  /// and return the receiver or one of the [TypeInfo] constants.
  TypeInfo computeIdentifierGFT(bool required) {
    assert(isValidTypeReference(start));
    assert(optional('Function', start.next));
    computeRest(start.next, required);

    if (gftHasReturnType == null) {
      return simpleType;
    }
    assert(end != null);
    return this;
  }

  /// Given identifier `<` ... `>`, compute the type
  /// and return the receiver or one of the [TypeInfo] constants.
  TypeInfo computeSimpleWithTypeArguments(bool required) {
    assert(isValidTypeReference(start));
    typeArguments = start.next;
    assert(optional('<', typeArguments));

    Token token = skipTypeVariables(typeArguments);
    if (token == null) {
      return required ? simpleType : noType;
    }
    end = token;
    computeRest(token.next, required);

    if (!required && !looksLikeName(end.next) && gftHasReturnType == null) {
      return noType;
    }
    assert(end != null);
    return this;
  }

  /// Given identifier `.` identifier, compute the type
  /// and return the receiver or one of the [TypeInfo] constants.
  TypeInfo computePrefixedType(bool required) {
    Token token = start;
    if (!optional('.', token)) {
      assert(isValidTypeReference(token));
      token = token.next;
    }
    assert(optional('.', token));
    if (isValidTypeReference(token.next)) {
      token = token.next;
    }

    end = token;
    token = token.next;
    if (optional('<', token)) {
      typeArguments = token;
      token = skipTypeVariables(token);
      if (token == null) {
        return required ? prefixedType : noType;
      }
      end = token;
      token = token.next;
    }
    computeRest(token, required);

    if (!required && !looksLikeName(end.next) && gftHasReturnType == null) {
      return noType;
    }
    assert(end != null);
    return this;
  }

  void computeRest(Token token, bool required) {
    while (optional('Function', token)) {
      Token typeVariableStart = token;
      token = token.next;
      if (optional('<', token)) {
        token = skipTypeVariables(token);
        if (token == null) {
          break; // Not a function type.
        }
        assert(optional('>', token) || optional('>>', token));
        token = token.next;
      }
      if (!optional('(', token)) {
        break; // Not a function type.
      }
      token = token.endGroup;
      if (token == null) {
        break; // Not a function type.
      }
      if (!required && !token.next.isIdentifier) {
        break; // `Function` used as the name in a function declaration.
      }
      assert(optional(')', token));
      gftHasReturnType ??= typeVariableStart != start;
      typeVariableStarters = typeVariableStarters.prepend(typeVariableStart);
      end = token;
      token = token.next;
    }
  }
}
