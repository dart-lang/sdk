// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.parser.type_info;

import '../../scanner/token.dart' show SyntheticStringToken, Token, TokenType;

import '../scanner/token_constants.dart' show IDENTIFIER_TOKEN, KEYWORD_TOKEN;

import 'parser.dart' show Parser;

import 'type_info_impl.dart';

import 'util.dart' show optional;

/// [TypeInfo] provides information that has collected by [computeType]
/// about a particular type reference.
abstract class TypeInfo {
  /// Return `true` if the tokens comprising the type represented by the
  /// receiver could be interpreted as a valid standalone expression.
  /// For example, `A` or `A.b` could be interpreted as a type references
  /// or as expressions, while `A<T>` only looks like a type reference.
  bool get couldBeExpression;

  /// Call this function when the token after [token] must be a type (not void).
  /// This function will call the appropriate event methods on the [Parser]'s
  /// listener to handle the type, inserting a synthetic type reference if
  /// necessary. This may modify the token stream when parsing `>>` in valid
  /// code or during recovery.
  Token ensureTypeNotVoid(Token token, Parser parser);

  /// Call this function when the token after [token] must be a type or void.
  /// This function will call the appropriate event methods on the [Parser]'s
  /// listener to handle the type, inserting a synthetic type reference if
  /// necessary. This may modify the token stream when parsing `>>` in valid
  /// code or during recovery.
  Token ensureTypeOrVoid(Token token, Parser parser);

  /// Call this function to parse an optional type (not void) after [token].
  /// This function will call the appropriate event methods on the [Parser]'s
  /// listener to handle the type. This may modify the token stream
  /// when parsing `>>` in valid code or during recovery.
  Token parseTypeNotVoid(Token token, Parser parser);

  /// Call this function to parse an optional type or void after [token].
  /// This function will call the appropriate event methods on the [Parser]'s
  /// listener to handle the type. This may modify the token stream
  /// when parsing `>>` in valid code or during recovery.
  Token parseType(Token token, Parser parser);

  /// Call this function with the [token] before the type to obtain
  /// the last token in the type. If there is no type, then this method
  /// will return [token]. This does not modify the token stream.
  Token skipType(Token token);
}

/// [NoType] is a specialized [TypeInfo] returned by [computeType] when
/// there is no type information in the source.
const TypeInfo noType = const NoType();

/// [VoidType] is a specialized [TypeInfo] returned by [computeType] when
/// there is a single identifier as the type reference.
const TypeInfo voidType = const VoidType();

/// [SimpleType] is a specialized [TypeInfo] returned by [computeType]
/// when there is a single identifier as the type reference.
const TypeInfo simpleType = const SimpleType();

/// [PrefixedType] is a specialized [TypeInfo] returned by [computeType]
/// when the type reference is of the form: identifier `.` identifier.
const TypeInfo prefixedType = const PrefixedType();

/// [SimpleTypeWith1Argument] is a specialized [TypeInfo] returned by
/// [computeType] when the type reference is of the form:
/// identifier `<` identifier `>`.
const TypeInfo simpleTypeWith1Argument = const SimpleTypeWith1Argument();

Token insertSyntheticIdentifierAfter(Token token, Parser parser) {
  Token identifier = new SyntheticStringToken(
      TokenType.IDENTIFIER, '', token.next.charOffset, 0);
  parser.rewriter.insertTokenAfter(token, identifier);
  return identifier;
}

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
    if (next.type.isBuiltIn) {
      Token afterType = next.next;
      if (optional('<', afterType)) {
        Token endGroup = afterType.endGroup;
        if (endGroup != null && looksLikeName(endGroup.next)) {
          // Recovery: built-in used as a type
          return new ComplexTypeInfo(token).computeBuiltinAsType(required);
        }
      } else {
        String value = next.stringValue;
        if (!identical('get', value) &&
            !identical('set', value) &&
            !identical('factory', value) &&
            !identical('operator', value)) {
          if (isGeneralizedFunctionType(afterType)) {
            // Recovery: built-in used as a type
            return new ComplexTypeInfo(token).computeBuiltinAsType(required);
          } else if (required) {
            // Recovery: built-in used as a type
            return new ComplexTypeInfo(token).computeBuiltinAsType(required);
          }
        }
      }
    } else if (required && optional('.', next)) {
      // Recovery: looks like prefixed type missing the prefix
      return new ComplexTypeInfo(token).computePrefixedType(required);
    }
    return noType;
  }

  if (optional('void', next)) {
    next = next.next;
    if (isGeneralizedFunctionType(next)) {
      // `void` `Function` ...
      return new ComplexTypeInfo(token).computeVoidGFT(required);
    }
    // `void`
    return voidType;
  }

  if (isGeneralizedFunctionType(next)) {
    // `Function` ...
    return new ComplexTypeInfo(token).computeNoTypeGFT(required);
  }

  // We've seen an identifier.
  next = next.next;

  if (optional('<', next)) {
    Token endGroup = next.endGroup;
    if (endGroup != null) {
      next = next.next;
      // identifier `<` `void` `>` is handled by ComplexTypeInfo.
      if (isValidTypeReference(next) && !identical('void', next.stringValue)) {
        next = next.next;
        if (next == endGroup) {
          // We've seen identifier `<` identifier `>`
          next = next.next;
          if (!isGeneralizedFunctionType(next)) {
            if (required || looksLikeName(next)) {
              // identifier `<` identifier `>` identifier
              return simpleTypeWith1Argument;
            } else {
              // identifier `<` identifier `>` non-identifier
              return noType;
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
    return required ? simpleType : noType;
  }

  if (optional('.', next)) {
    next = next.next;
    if (isValidTypeReference(next)) {
      next = next.next;
      // We've seen identifier `.` identifier
      if (!optional('<', next) && !isGeneralizedFunctionType(next)) {
        if (required || looksLikeName(next)) {
          // identifier `.` identifier identifier
          return prefixedType;
        } else {
          // identifier `.` identifier non-identifier
          return noType;
        }
      }
      // identifier `.` identifier
      return new ComplexTypeInfo(token).computePrefixedType(required);
    }
    // identifier `.` non-identifier
    return required
        ? new ComplexTypeInfo(token).computePrefixedType(required)
        : noType;
  }

  if (isGeneralizedFunctionType(next)) {
    // `Function`
    return new ComplexTypeInfo(token).computeIdentifierGFT(required);
  }

  if (required || looksLikeName(next)) {
    // identifier identifier
    return simpleType;
  }
  return noType;
}
