// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.parser.type_info;

import '../../scanner/token.dart' show Token, TokenType;

import '../scanner/token_constants.dart' show IDENTIFIER_TOKEN, KEYWORD_TOKEN;

import 'parser.dart' show Parser;

import 'type_info_impl.dart';

import 'util.dart' show optional;

/// [TypeInfo] provides information collected by [computeType]
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

/// [TypeParamOrArgInfo] provides information collected by
/// [computeTypeParamOrArg] about a particular group of type arguments
/// or type parameters.
abstract class TypeParamOrArgInfo {
  /// Call this function to parse optional type arguments after [token].
  /// This function will call the appropriate event methods on the [Parser]'s
  /// listener to handle the arguments. This may modify the token stream
  /// when parsing `>>` in valid code or during recovery.
  Token parseArguments(Token token, Parser parser);

  /// Call this function to parse optional type parameters
  /// (also known as type variables) after [token].
  /// This function will call the appropriate event methods on the [Parser]'s
  /// listener to handle the parameters. This may modify the token stream
  /// when parsing `>>` in valid code or during recovery.
  Token parseVariables(Token token, Parser parser);

  /// Call this function with the [token] before the type var to obtain
  /// the last token in the type var. If there is no type var, then this method
  /// will return [token]. This does not modify the token stream.
  Token skip(Token token);
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

/// [NoTypeParamOrArg] is a specialized [TypeParamOrArgInfo] returned by
/// [computeTypeParamOrArg] when no type parameters or arguments are found.
const TypeParamOrArgInfo noTypeParamOrArg = const NoTypeParamOrArg();

/// [SimpleTypeArgument1] is a specialized [TypeParamOrArgInfo] returned by
/// [computeTypeParamOrArg] when the type reference is of the form:
/// `<` identifier `>`.
const TypeParamOrArgInfo simpleTypeArgument1 = const SimpleTypeArgument1();

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
///
/// If this method is called by [computeTypeParamOrArg] and the outer group ends
/// with `>>`, then then [innerEndGroup] is set to either `>>` if the token
/// has not been split or the first `>` if the `>>` token has been split.
TypeInfo computeType(final Token token, bool required, [Token innerEndGroup]) {
  Token next = token.next;
  if (!isValidTypeReference(next)) {
    if (next.type.isBuiltIn) {
      TypeParamOrArgInfo typeParamOrArg =
          computeTypeParamOrArg(next, innerEndGroup);
      if (typeParamOrArg != noTypeParamOrArg) {
        // Recovery: built-in `<` ... `>`
        if (required || looksLikeName(typeParamOrArg.skip(next).next)) {
          return new ComplexTypeInfo(token, typeParamOrArg)
              .computeBuiltinAsType(required);
        }
      } else if (required || isGeneralizedFunctionType(next.next)) {
        String value = next.stringValue;
        if ((!identical('get', value) &&
            !identical('set', value) &&
            !identical('factory', value) &&
            !identical('operator', value) &&
            !(identical('typedef', value) && next.next.isIdentifier))) {
          return new ComplexTypeInfo(token, typeParamOrArg)
              .computeBuiltinAsType(required);
        }
      }
    } else if (required && optional('.', next)) {
      // Recovery: looks like prefixed type missing the prefix
      return new ComplexTypeInfo(
              token, computeTypeParamOrArg(next, innerEndGroup))
          .computePrefixedType(required);
    }
    return noType;
  }

  if (optional('void', next)) {
    next = next.next;
    if (isGeneralizedFunctionType(next)) {
      // `void` `Function` ...
      return new ComplexTypeInfo(token, noTypeParamOrArg)
          .computeVoidGFT(required);
    }
    // `void`
    return voidType;
  }

  if (isGeneralizedFunctionType(next)) {
    // `Function` ...
    return new ComplexTypeInfo(token, noTypeParamOrArg)
        .computeNoTypeGFT(required);
  }

  // We've seen an identifier.

  TypeParamOrArgInfo typeParamOrArg =
      computeTypeParamOrArg(next, innerEndGroup);
  if (typeParamOrArg != noTypeParamOrArg) {
    if (typeParamOrArg == simpleTypeArgument1) {
      // We've seen identifier `<` identifier `>`
      next = typeParamOrArg.skip(next).next;
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

    // identifier `<` ... `>`
    return new ComplexTypeInfo(token, typeParamOrArg)
        .computeSimpleWithTypeArguments(required);
  }

  assert(typeParamOrArg == noTypeParamOrArg);
  next = next.next;
  if (optional('.', next)) {
    next = next.next;
    if (isValidTypeReference(next)) {
      // We've seen identifier `.` identifier
      typeParamOrArg = computeTypeParamOrArg(next, innerEndGroup);
      next = next.next;
      if (typeParamOrArg == noTypeParamOrArg &&
          !isGeneralizedFunctionType(next)) {
        if (required || looksLikeName(next)) {
          // identifier `.` identifier identifier
          return prefixedType;
        } else {
          // identifier `.` identifier non-identifier
          return noType;
        }
      }
      // identifier `.` identifier
      return new ComplexTypeInfo(token, typeParamOrArg)
          .computePrefixedType(required);
    }
    // identifier `.` non-identifier
    if (required) {
      typeParamOrArg = computeTypeParamOrArg(token.next.next, innerEndGroup);
      return new ComplexTypeInfo(token, typeParamOrArg)
          .computePrefixedType(required);
    }
    return noType;
  }

  assert(typeParamOrArg == noTypeParamOrArg);
  if (isGeneralizedFunctionType(next)) {
    // identifier `Function`
    return new ComplexTypeInfo(token, noTypeParamOrArg)
        .computeIdentifierGFT(required);
  }

  if (required || looksLikeName(next)) {
    // identifier identifier
    return simpleType;
  }
  return noType;
}

/// Called by the parser to obtain information about a possible group of type
/// parameters that follow [token] in a top level or class member declaration.
/// It assumes that a leading `<` cannot be part of an expression, and thus
/// tries to more aggressively recover given an unmatched '<'
TypeParamOrArgInfo computeTypeParam(Token token) {
  if (!optional('<', token.next)) {
    return noTypeParamOrArg;
  }
  TypeParamOrArgInfo typeParam = computeTypeParamOrArgImpl(token);
  if (typeParam != noTypeParamOrArg) {
    return typeParam;
  }

  // Recovery
  if (token.next.endGroup == null) {
    // Attempt to find where the missing `>` should be inserted.
    return new ComplexTypeParamOrArgInfo(token).computeRecovery();
  } else {
    // The `<` `>` are balanced but there's still a problem.
    return noTypeParamOrArg;
  }
}

/// Called by the parser to obtain information about a possible group of type
/// parameters or type arguments that follow [token].
/// This does not modify the token stream.
///
/// If this method is called by [computeType] and the outer group ends
/// with `>>`, then then [innerEndGroup] is set to either `>>` if the token
/// has not been split or the first `>` if the `>>` token has been split.
TypeParamOrArgInfo computeTypeParamOrArg(Token token, [Token innerEndGroup]) {
  return optional('<', token.next)
      ? computeTypeParamOrArgImpl(token, innerEndGroup)
      : noTypeParamOrArg;
}

TypeParamOrArgInfo computeTypeParamOrArgImpl(Token token,
    [Token innerEndGroup]) {
  Token next = token.next;
  assert(optional('<', next));
  Token endGroup = next.endGroup ?? innerEndGroup;
  if (endGroup == null) {
    return noTypeParamOrArg;
  }
  Token identifier = next.next;
  // identifier `<` `void` `>` and `<` `dynamic` `>`
  // are handled by ComplexTypeInfo.
  if ((identifier.kind == IDENTIFIER_TOKEN || identifier.type.isPseudo) &&
      identifier.next == endGroup) {
    return simpleTypeArgument1;
  }
  // TODO(danrubel): Consider adding additional const for common situations.
  return new ComplexTypeParamOrArgInfo(token).compute(innerEndGroup);
}

/// Called by the parser to obtain information about a possible group of type
/// type arguments that follow [token] and that are followed by '('.
/// Returns the type arguments if [token] matches '<' type (',' type)* '>' '(',
/// and otherwise returns [noTypeParamOrArg]. The final '(' is not part of the
/// grammar construct `typeArguments`, but it is required here such that type
/// arguments in generic method invocations can be recognized, and as few as
/// possible other constructs will pass (e.g., 'a < C, D > 3').
TypeParamOrArgInfo computeMethodTypeArguments(Token token) {
  TypeParamOrArgInfo typeArg = computeTypeParamOrArg(token);
  return optional('(', typeArg.skip(token).next) ? typeArg : noTypeParamOrArg;
}
