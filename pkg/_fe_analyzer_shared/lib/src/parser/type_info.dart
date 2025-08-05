// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library _fe_analyzer_shared.parser.type_info;

import '../scanner/token.dart'
    show Keyword, Token, TokenIsAExtension, TokenType, TokenTypeIsAExtension;

import '../scanner/token_constants.dart' show IDENTIFIER_TOKEN, KEYWORD_TOKEN;

import 'identifier_context.dart';

import 'parser_impl.dart' show Parser;

import 'type_info_impl.dart';

import 'util.dart' show isAnyOf;

/// [TypeInfo] provides information collected by [computeType]
/// about a particular type reference.
abstract class TypeInfo {
  /// Return type info representing the receiver without the trailing `?`
  /// or the receiver if the receiver does not represent a nullable type.
  TypeInfo get asNonNullable;

  /// Return `true` if the tokens comprising the type represented by the
  /// receiver could be interpreted as a valid standalone expression.
  /// For example, `A` or `A.b` could be interpreted as type references
  /// or expressions, while `A<T>` only looks like a type reference.
  bool get couldBeExpression;

  /// Return true if the receiver has a trailing `?`.
  bool get isNullable;

  /// Returns true if the type represents a function type, i.e. something like
  /// void Function foo(int x);
  bool get isFunctionType;

  /// Returns true if the type has type arguments.
  bool get hasTypeArguments;

  bool get recovered => false;

  /// Call this function when the token after [token] must be a type (not void).
  /// This function will call the appropriate event methods on the [Parser]'s
  /// listener to handle the type, inserting a synthetic type reference if
  /// necessary. This may modify the token stream when parsing `>>` or `>>>`
  /// or `>>>=` in valid code or during recovery.
  Token ensureTypeNotVoid(Token token, Parser parser);

  /// Call this function when the token after [token] must be a type or void.
  /// This function will call the appropriate event methods on the [Parser]'s
  /// listener to handle the type, inserting a synthetic type reference if
  /// necessary. This may modify the token stream when parsing `>>` or `>>>`
  /// or `>>>=` in valid code or during recovery.
  Token ensureTypeOrVoid(Token token, Parser parser);

  /// Call this function to parse an optional type (not void) after [token].
  /// This function will call the appropriate event methods on the [Parser]'s
  /// listener to handle the type. This may modify the token stream
  /// when parsing `>>` or `>>>` or `>>>=`  in valid code or during recovery.
  Token parseTypeNotVoid(Token token, Parser parser);

  /// Call this function to parse an optional type or void after [token].
  /// This function will call the appropriate event methods on the [Parser]'s
  /// listener to handle the type. This may modify the token stream
  /// when parsing `>>` or `>>>` or `>>>=` in valid code or during recovery.
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
  const TypeParamOrArgInfo();

  /// Return `true` if the receiver represents a single type argument
  bool get isSimpleTypeArgument => false;

  /// Return the number of type arguments
  int get typeArgumentCount;

  bool get recovered => false;

  /// Return the simple type associated with this simple type argument
  /// or throw an exception if this is not a simple type argument.
  TypeInfo get typeInfo {
    throw "Internal error: $runtimeType is not a SimpleTypeArgument.";
  }

  /// Call this function to parse optional type arguments after [token].
  /// This function will call the appropriate event methods on the [Parser]'s
  /// listener to handle the arguments. This may modify the token stream
  /// when parsing `>>` or `>>>` or `>>>=` in valid code or during recovery.
  Token parseArguments(Token token, Parser parser);

  /// Call this function to parse optional type parameters
  /// (also known as type variables) after [token].
  /// This function will call the appropriate event methods on the [Parser]'s
  /// listener to handle the parameters. This may modify the token stream
  /// when parsing `>>` or `>>>` or `>>>=` in valid code or during recovery.
  Token parseVariables(Token token, Parser parser);

  /// Call this function with the [token] before the type var to obtain
  /// the last token in the type var. If there is no type var, then this method
  /// will return [token]. This does not modify the token stream.
  Token skip(Token token);
}

/// [NoType] is a specialized [TypeInfo] returned by [computeType] when
/// there is no type information in the source.
const TypeInfo noType = const NoType();

/// [NoTypeParamOrArg] is a specialized [TypeParamOrArgInfo] returned by
/// [computeTypeParamOrArg] when no type parameters or arguments are found.
const TypeParamOrArgInfo noTypeParamOrArg = const NoTypeParamOrArg();

/// [VoidType] is a specialized [TypeInfo] returned by [computeType] when
/// `void` appears in the source.
const TypeInfo voidType = const VoidType();

bool isGeneralizedFunctionType(Token token) {
  return token.isA(Keyword.FUNCTION) &&
      (token.next!.isA(TokenType.LT) || token.next!.isA(TokenType.OPEN_PAREN));
}

bool isPossibleRecordType(Token token) {
  return token.isA(TokenType.OPEN_PAREN) &&
      token.endGroup != null &&
      !token.endGroup!.isSynthetic;
}

bool isValidNonRecordTypeReference(Token token) {
  TokenType type = token.type;
  int kind = type.kind;
  if (IDENTIFIER_TOKEN == kind) return true;
  if (KEYWORD_TOKEN == kind) {
    return type.isPseudo ||
        (type.isBuiltIn && token.next!.isA(TokenType.PERIOD)) ||
        type.isA(Keyword.DYNAMIC) ||
        type.isA(Keyword.FUNCTION) ||
        type.isA(Keyword.VOID);
  }
  return false;
}

/// Called by the parser to obtain information about a possible type reference
/// that follows [token]. This does not modify the token stream.
///
/// If [inDeclaration] is `true`, then this will more aggressively recover
/// given unbalanced `<` `>` and invalid parameters or arguments.
TypeInfo computeType(
  final Token token,
  bool required, [
  bool inDeclaration = false,
  bool acceptKeywordForSimpleType = false,
]) {
  Token next = token.next!;
  if (!isValidNonRecordTypeReference(next) && !isPossibleRecordType(next)) {
    // As next is not a valid type reference, this is all recovery.
    if (next.type.isBuiltIn) {
      TypeParamOrArgInfo typeParamOrArg = computeTypeParamOrArg(
        next,
        inDeclaration,
      );
      if (typeParamOrArg != noTypeParamOrArg) {
        // Recovery: built-in `<` ... `>`
        if (required || looksLikeName(typeParamOrArg.skip(next).next!)) {
          return new ComplexTypeInfo(
            token,
            typeParamOrArg,
          ).computeBuiltinOrVarAsType(required)..recovered = true;
        }
      } else if (required || isGeneralizedFunctionType(next.next!)) {
        String? value = next.stringValue;
        if ((!identical('get', value) &&
            !identical('set', value) &&
            !identical('factory', value) &&
            !identical('operator', value) &&
            !(identical('typedef', value) && next.next!.isIdentifier))) {
          return new ComplexTypeInfo(
            token,
            typeParamOrArg,
          ).computeBuiltinOrVarAsType(required)..recovered = true;
        }
      }
    } else if (required) {
      // Recovery
      if (next.isA(TokenType.PERIOD)) {
        // Looks like prefixed type missing the prefix
        TypeInfo result = new ComplexTypeInfo(
          token,
          computeTypeParamOrArg(next, inDeclaration),
        ).computePrefixedType(required);
        if (result is ComplexTypeInfo) result.recovered = true;
        return result;
      } else if (next.isA(Keyword.VAR) &&
          isAnyOf(next.next!, const [
            TokenType.LT,
            TokenType.COMMA,
            TokenType.GT,
          ])) {
        return new ComplexTypeInfo(
          token,
          computeTypeParamOrArg(next, inDeclaration),
        ).computeBuiltinOrVarAsType(required)..recovered = true;
      }
    }
    return noType;
  }

  if (next.isA(Keyword.VOID)) {
    next = next.next!;
    if (isGeneralizedFunctionType(next)) {
      // `void` `Function` ...
      return new ComplexTypeInfo(
        token,
        noTypeParamOrArg,
      ).computeVoidGFT(required);
    }
    // `void`
    return voidType;
  }

  if (isGeneralizedFunctionType(next)) {
    // `Function` ...
    return new ComplexTypeInfo(
      token,
      noTypeParamOrArg,
    ).computeNoTypeGFT(token, required);
  }

  if (isPossibleRecordType(next)) {
    // ([...])
    Token after = next.endGroup!.next!;
    if (isGeneralizedFunctionType(after)) {
      // ([...]) `Function`
      return new ComplexTypeInfo(
        token,
        noTypeParamOrArg,
      ).computeRecordTypeGFT(required);
    }
    if (after.isA(TokenType.QUESTION) &&
        isGeneralizedFunctionType(after.next!)) {
      // ([...]) `?` `Function`
      return new ComplexTypeInfo(
        token,
        noTypeParamOrArg,
      ).computeRecordTypeQuestionGFT(required);
    }
    return new ComplexTypeInfo(
      token,
      noTypeParamOrArg,
    ).computeRecordType(required);
  }

  // We've seen an identifier.

  TypeParamOrArgInfo typeParamOrArg = computeTypeParamOrArg(
    next,
    inDeclaration,
  );
  if (typeParamOrArg != noTypeParamOrArg) {
    if (typeParamOrArg.isSimpleTypeArgument) {
      // We've seen identifier `<` identifier `>`
      next = typeParamOrArg.skip(next).next!;
      if (next.isA(TokenType.QUESTION)) {
        next = next.next!;
        if (!isGeneralizedFunctionType(next)) {
          if ((required || looksLikeName(next)) &&
              typeParamOrArg == simpleTypeArgument1) {
            // identifier `<` identifier `>` `?` identifier
            return simpleNullableTypeWith1Argument;
          }
          // identifier `<` identifier `>` `?` non-identifier
          return noType;
        }
      } else if (!isGeneralizedFunctionType(next)) {
        if (required || looksLikeName(next)) {
          // identifier `<` identifier `>` identifier
          return typeParamOrArg.typeInfo;
        }
        // identifier `<` identifier `>` non-identifier
        return noType;
      }
    }
    // TODO(danrubel): Consider adding a const for
    // identifier `<` identifier `,` identifier `>`
    // if that proves to be a common case.

    // identifier `<` ... `>`
    return new ComplexTypeInfo(
      token,
      typeParamOrArg,
    ).computeSimpleWithTypeArguments(required);
  }

  assert(typeParamOrArg == noTypeParamOrArg);
  next = next.next!;

  if (next.isA(TokenType.PERIOD)) {
    next = next.next!;
    if (isValidNonRecordTypeReference(next)) {
      // We've seen identifier `.` identifier
      typeParamOrArg = computeTypeParamOrArg(next, inDeclaration);
      next = next.next!;
      if (typeParamOrArg == noTypeParamOrArg) {
        if (next.isA(TokenType.QUESTION)) {
          next = next.next!;
          if (!isGeneralizedFunctionType(next)) {
            if (required || looksLikeName(next)) {
              // identifier `.` identifier `?` identifier
              // TODO(danrubel): consider adding PrefixedNullableType
              // Fall through to build complex type
            } else {
              // identifier `.` identifier `?` non-identifier
              return noType;
            }
          }
        } else {
          if (!isGeneralizedFunctionType(next)) {
            if (required || looksLikeName(next)) {
              // identifier `.` identifier identifier
              return prefixedType;
            } else {
              // identifier `.` identifier non-identifier
              return noType;
            }
          }
        }
      }
      // identifier `.` identifier
      return new ComplexTypeInfo(
        token,
        typeParamOrArg,
      ).computePrefixedType(required);
    }
    // identifier `.` non-identifier
    if (required) {
      typeParamOrArg = computeTypeParamOrArg(token.next!.next!, inDeclaration);
      return new ComplexTypeInfo(
        token,
        typeParamOrArg,
      ).computePrefixedType(required);
    }
    return noType;
  }

  assert(typeParamOrArg == noTypeParamOrArg);
  if (isGeneralizedFunctionType(next)) {
    // identifier `Function`
    return new ComplexTypeInfo(
      token,
      noTypeParamOrArg,
    ).computeIdentifierGFT(required);
  }

  if (next.isA(TokenType.QUESTION)) {
    next = next.next!;
    if (isGeneralizedFunctionType(next)) {
      // identifier `?` Function `(`
      return new ComplexTypeInfo(
        token,
        noTypeParamOrArg,
      ).computeIdentifierQuestionGFT(required);
    } else if (required || looksLikeName(next)) {
      // identifier `?`
      return simpleNullableType;
    }
  } else if (required ||
      looksLikeName(next) ||
      (acceptKeywordForSimpleType &&
          next.isKeywordOrIdentifier &&
          isOkNextValueInFormalParameter(next.next!))) {
    // identifier identifier
    return simpleType;
  }
  return noType;
}

/// Computes the [TypeInfo] for a variable pattern.
///
/// This is similar to [computeType], but has special logic to account for an
/// ambiguity that arises in patterns due to the fact that `as` can either be
/// an identifier or the operator in a castPattern.
TypeInfo computeVariablePatternType(Token token, [bool required = false]) {
  TypeInfo typeInfo = computeType(token, required);
  Token afterType = typeInfo.skipType(token);
  if (!identical(afterType, token)) {
    Token next = afterType.next!;
    if (next.isIdentifier) {
      if (next.isA(Keyword.AS) || next.isA(Keyword.WHEN)) {
        // We've seen `TYPE as` or `TYPE when`.  `as` is a built-in identifier
        // and `when` is a pseudo-keyword, so this *could* be a variable
        // pattern.  Or it could be that TYPE should have been parsed as a
        // pattern.  We've decided to resolve the ambiguity by assuming that
        // TYPE was the pattern, and interpret the `when` or `as` as introducing
        // a guard or a cast pattern, respectively (see discussion at
        // https://github.com/dart-lang/sdk/issues/52199).
        return noType;
      }
    }
  }
  return typeInfo;
}

/// Called by the parser to obtain information about a possible group of type
/// parameters or type arguments that follow [token].
/// This does not modify the token stream.
///
/// If [inDeclaration] is `true`, then this will more aggressively recover
/// given unbalanced `<` `>` and invalid parameters or arguments.
@pragma("vm:prefer-inline")
TypeParamOrArgInfo computeTypeParamOrArg(
  Token token, [
  bool inDeclaration = false,
  bool allowsVariance = false,
]) {
  Token beginGroup = token.next!;
  if (!beginGroup.isA(TokenType.LT)) {
    return noTypeParamOrArg;
  }
  return _computeTypeParamOrArgImpl(
    token,
    beginGroup,
    inDeclaration,
    allowsVariance,
  );
}

TypeParamOrArgInfo _computeTypeParamOrArgImpl(
  Token token,
  Token beginGroup,
  bool inDeclaration,
  bool allowsVariance,
) {
  // identifier `<` `void` `>` and `<` `dynamic` `>`
  // are handled by ComplexTypeInfo.
  Token next = beginGroup.next!;
  if ((next.kind == IDENTIFIER_TOKEN || next.type.isPseudo)) {
    if (next.next!.isA(TokenType.GT)) {
      return simpleTypeArgument1;
    } else if (next.next!.isA(TokenType.GT_GT)) {
      return simpleTypeArgument1GtGt;
    } else if (next.next!.isA(TokenType.GT_EQ)) {
      return simpleTypeArgument1GtEq;
    }
  } else if (next.isA(TokenType.OPEN_PAREN)) {
    bool recordType = false;
    if (isPossibleRecordType(next)) {
      TypeInfo type = computeType(beginGroup, /* required = */ false);
      if (type is ComplexTypeInfo &&
          (type.isRecordType || type.gftReturnTypeHasRecordType) &&
          !type.recovered) {
        // Looks like a record type.
        recordType = true;
      }
    }
    if (!recordType) {
      return noTypeParamOrArg;
    }
  }

  // TODO(danrubel): Consider adding additional const for common situations.
  return new ComplexTypeParamOrArgInfo(
    token,
    inDeclaration,
    allowsVariance,
  ).compute();
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
  return _mayFollowTypeArgs(typeArg.skip(token).next!.typeIndex) &&
          !typeArg.recovered
      ? typeArg
      : noTypeParamOrArg;
}

/// The set of identifiers that are illegal to use as the name of a variable in
/// a variable pattern, or as the name of an identifier in an identifier
/// pattern.
const Set<String> illegalPatternIdentifiers = {'when', 'as'};

/// Indicates whether the given [tokenTypeIndex] is allowed to follow a list of
/// type arguments used as a selector after an expression.
///
/// Get the index from a token via `Token.typeIndex`.
///
/// This is used for disambiguating constructs like `f(a<b,c>(d))` and
/// `f(a<b,c>-d)`.  In the case of `f(a<b,c>(d))`, `true` will be returned,
/// indicating that the `<` and `>` should be interpreted as delimiting type
/// arguments (so one argument is being passed to `f` -- a call to the generic
/// function `a`).  In the case of `f(a<b,c>-d)`, `false` will be returned,
/// indicating that the `<` and `>` should be interpreted as operators (so two
/// arguments are being passed to `f`: `a < b` and `c > -d`).
///
// DartDocTest(() {
//   for (int i = 0; i < 256; i++) {
//     if (_mayFollowTypeArgs(i) !=
//         _mayFollowTypeArgs_helper_for_testing(i)) {
//       return false;
//     }
//   }
//   return true;
// }(), true);
@pragma("vm:prefer-inline")
bool _mayFollowTypeArgs(int tokenTypeIndex) {
  // Table has size 256 to avoid bounds checks as this is called with
  // `Token.typeIndex` which is know to be in [0-255].
  const List<bool> table = [
    // format hack.
    true, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false,
    false, false, true, false, false, false, false, false,
    true, true, false, false, true, true, true, false,
    true, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false,
    false, false, false, false, true, false, false, false,
    true, false, false, false, false, false, false, false,
    false, true, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false,
    // format hack.
  ];

  return table[tokenTypeIndex];
}

// ignore: unused_element
bool _mayFollowTypeArgs_helper_for_testing(int tokenTypeIndex) {
  return tokenTypeIndex == TokenType.OPEN_PAREN.index ||
      tokenTypeIndex == TokenType.PERIOD.index ||
      tokenTypeIndex == TokenType.EQ_EQ.index ||
      tokenTypeIndex == TokenType.BANG_EQ.index ||
      tokenTypeIndex == TokenType.CLOSE_PAREN.index ||
      tokenTypeIndex == TokenType.CLOSE_SQUARE_BRACKET.index ||
      tokenTypeIndex == TokenType.CLOSE_CURLY_BRACKET.index ||
      tokenTypeIndex == TokenType.SEMICOLON.index ||
      tokenTypeIndex == TokenType.COLON.index ||
      tokenTypeIndex == TokenType.COMMA.index ||
      tokenTypeIndex == TokenType.EOF.index;
}
