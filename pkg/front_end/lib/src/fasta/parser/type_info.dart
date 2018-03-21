// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.parser.type_info;

import '../../scanner/token.dart' show Token, TokenType;

import '../scanner/token_constants.dart' show IDENTIFIER_TOKEN, KEYWORD_TOKEN;

import '../util/link.dart' show Link;

import 'identifier_context.dart' show IdentifierContext;

import 'listener.dart' show Listener;

import 'member_kind.dart' show MemberKind;

import 'parser.dart' show Parser;

import 'type_info_impl.dart'
    show
        NoTypeInfo,
        PrefixedTypeInfo,
        SimpleTypeArgumentsInfo,
        SimpleTypeInfo,
        VoidTypeInfo,
        looksLikeName,
        skipTypeArguments;

import 'util.dart' show optional;

/// [TypeInfo] provides information that has collected by [computeType]
/// about a particular type reference.
abstract class TypeInfo {
  /// Return `true` if the tokens comprising the type represented by the
  /// receiver could be interpreted as a valid standalone expression.
  /// For example, `A` or `A.b` could be interpreted as a type references
  /// or as expressions, while `A<T>` only looks like a type reference.
  bool get couldBeExpression;

  /// Call this function when it's known that the token after [token] is a type.
  /// This function will call the appropriate event methods on the [Parser]'s
  /// listener to handle the type. This may modify the token stream
  /// when parsing `>>` in valid code or during recovery.
  Token parseType(Token token, Parser parser);

  /// Call this function with the [token] before the type to obtain
  /// the last token in the type. If there is no type, then this method
  /// will return [token]. This does not modify the token stream.
  Token skipType(Token token);
}

/// [NoTypeInfo] is a specialized [TypeInfo] returned by [computeType] when
/// there is no type information in the source.
const TypeInfo noTypeInfo = const NoTypeInfo();

/// [VoidTypeInfo] is a specialized [TypeInfo] returned by [computeType] when
/// there is a single identifier as the type reference.
const TypeInfo voidTypeInfo = const VoidTypeInfo();

/// [SimpleTypeInfo] is a specialized [TypeInfo] returned by [computeType]
/// when there is a single identifier as the type reference.
const TypeInfo simpleTypeInfo = const SimpleTypeInfo();

/// [PrefixedTypeInfo] is a specialized [TypeInfo] returned by [computeType]
/// when the type reference is of the form: identifier `.` identifier.
const TypeInfo prefixedTypeInfo = const PrefixedTypeInfo();

/// [SimpleTypeArgumentsInfo] is a specialized [TypeInfo] returned by
/// [computeType] when the type reference is of the form:
/// identifier `<` identifier `>`.
const TypeInfo simpleTypeArgumentsInfo = const SimpleTypeArgumentsInfo();

bool isGeneralizedFunctionType(Token token) {
  return optional('Function', token) &&
      (optional('<', token.next) || optional('(', token.next));
}

bool isValidTypeReference(Token token) {
  int kind = token.kind;
  if (IDENTIFIER_TOKEN == kind) return true;
  if (KEYWORD_TOKEN == kind) {
    TokenType type = token.type;
    String value = type.lexeme;
    return type.isPseudo ||
        (type.isBuiltIn && optional('.', token.next)) ||
        (identical(value, 'dynamic')) ||
        (identical(value, 'void'));
  }
  return false;
}

/// Called by the parser to obtain information about a possible type reference
/// that follows [token]. This does not modify the token stream.
TypeInfo computeType(final Token token, bool required) {
  Token next = token.next;
  if (!isValidTypeReference(next)) {
    return noTypeInfo;
  }

  if (optional('void', next)) {
    next = next.next;
    if (isGeneralizedFunctionType(next)) {
      // `void` `Function` ...
      return new ComplexTypeInfo(token).computeVoidGFT(required);
    }
    // `void`
    return voidTypeInfo;
  }

  if (isGeneralizedFunctionType(next)) {
    // `Function` ...
    return new ComplexTypeInfo(token).computeNoTypeGFT(required);
  }

  // We've seen an identifier.
  next = next.next;

  if (optional('<', next)) {
    if (next.endGroup != null) {
      next = next.next;
      // identifier `<` `void` `>` is handled by ComplexTypeInfo.
      if (isValidTypeReference(next) && !identical('void', next.stringValue)) {
        next = next.next;
        if (optional('>', next)) {
          // We've seen identifier `<` identifier `>`
          next = next.next;
          if (!isGeneralizedFunctionType(next)) {
            if (required || looksLikeName(next)) {
              // identifier `<` identifier `>` identifier
              return simpleTypeArgumentsInfo;
            } else {
              // identifier `<` identifier `>` non-identifier
              return noTypeInfo;
            }
          }
        }
        // TODO(danrubel): Consider adding a const for
        // identifier `<` identifier `,` identifier `>`
        // if that proves to be a common case.
      }

      // identifier `<` ... `>`
      return new ComplexTypeInfo(token)
          .computeSimpleWithTypeArguments(required);
    }
    // identifier `<`
    return required ? simpleTypeInfo : noTypeInfo;
  }

  if (optional('.', next)) {
    next = next.next;
    if (isValidTypeReference(next)) {
      next = next.next;
      // We've seen identifier `.` identifier
      if (!optional('<', next) && !isGeneralizedFunctionType(next)) {
        if (required || looksLikeName(next)) {
          // identifier `.` identifier identifier
          return prefixedTypeInfo;
        } else {
          // identifier `.` identifier non-identifier
          return noTypeInfo;
        }
      }
      // identifier `.` identifier
      return new ComplexTypeInfo(token).computePrefixedType(required);
    }
    // identifier `.` non-identifier
    return required ? simpleTypeInfo : noTypeInfo;
  }

  if (isGeneralizedFunctionType(next)) {
    // `Function`
    return new ComplexTypeInfo(token).computeIdentifierGFT(required);
  }

  if (required || looksLikeName(next)) {
    // identifier identifier
    return simpleTypeInfo;
  }
  return noTypeInfo;
}

/// Instances of [ComplexTypeInfo] are returned by [computeType] to represent
/// type references that cannot be represented by the constants above.
class ComplexTypeInfo implements TypeInfo {
  final Token start;
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
  Token parseType(Token token, Parser parser) {
    assert(identical(token.next, start));
    Listener listener = parser.listener;

    for (Link<Token> t = typeVariableStarters; t.isNotEmpty; t = t.tail) {
      parser.parseTypeVariablesOpt(t.head);
      listener.beginFunctionType(start);
    }

    if (gftHasReturnType == false) {
      // A function type without return type.
      // Push the non-existing return type first. The loop below will
      // generate the full type.
      noTypeInfo.parseType(token, parser);
    } else if (optional('void', token.next)) {
      token = voidTypeInfo.parseType(token, parser);
    } else {
      if (!optional('.', token.next.next)) {
        token = parser.ensureIdentifier(token, IdentifierContext.typeReference);
      } else {
        token = parser.ensureIdentifier(
            token, IdentifierContext.prefixedTypeReference);
        token = parser.parseQualifiedRest(
            token, IdentifierContext.typeReferenceContinuation);
      }
      token = parser.parseTypeArgumentsOpt(token);
      listener.handleType(start, token.next);
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
      listener.endFunctionType(functionToken, token.next);
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

    return gftHasReturnType != null
        ? this
        : required ? simpleTypeInfo : noTypeInfo;
  }

  /// Given void `Function` non-identifier, compute the type
  /// and return the receiver or one of the [TypeInfo] constants.
  TypeInfo computeVoidGFT(bool required) {
    assert(optional('void', start));
    assert(optional('Function', start.next));
    computeRest(start.next, required);

    return gftHasReturnType != null ? this : voidTypeInfo;
  }

  /// Given identifier `Function` non-identifier, compute the type
  /// and return the receiver or one of the [TypeInfo] constants.
  TypeInfo computeIdentifierGFT(bool required) {
    assert(isValidTypeReference(start));
    assert(optional('Function', start.next));
    computeRest(start.next, required);

    return gftHasReturnType != null ? this : simpleTypeInfo;
  }

  /// Given identifier `<` ... `>`, compute the type
  /// and return the receiver or one of the [TypeInfo] constants.
  TypeInfo computeSimpleWithTypeArguments(bool required) {
    assert(isValidTypeReference(start));
    typeArguments = start.next;
    assert(optional('<', typeArguments));

    Token token = skipTypeArguments(typeArguments);
    if (token == null) {
      return required ? simpleTypeInfo : noTypeInfo;
    }
    end = token;
    computeRest(token.next, required);

    return required || looksLikeName(end.next) || gftHasReturnType != null
        ? this
        : noTypeInfo;
  }

  /// Given identifier `.` identifier, compute the type
  /// and return the receiver or one of the [TypeInfo] constants.
  TypeInfo computePrefixedType(bool required) {
    assert(isValidTypeReference(start));
    Token token = start.next;
    assert(optional('.', token));
    token = token.next;
    assert(isValidTypeReference(token));

    end = token;
    token = token.next;
    if (optional('<', token)) {
      typeArguments = token;
      token = skipTypeArguments(token);
      if (token == null) {
        return required ? prefixedTypeInfo : noTypeInfo;
      }
      end = token;
      token = token.next;
    }
    computeRest(token, required);

    return required || looksLikeName(end.next) || gftHasReturnType != null
        ? this
        : noTypeInfo;
  }

  void computeRest(Token token, bool required) {
    while (optional('Function', token)) {
      Token typeVariableStart = token;
      token = token.next;
      if (optional('<', token)) {
        token = token.endGroup;
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
      assert(optional(')', token));
      gftHasReturnType ??= typeVariableStart != start;
      typeVariableStarters = typeVariableStarters.prepend(typeVariableStart);
      end = token;
      token = token.next;
    }
  }
}
