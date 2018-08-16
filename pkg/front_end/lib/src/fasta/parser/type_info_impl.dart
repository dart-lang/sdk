// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.parser.type_info_impl;

import '../../scanner/token.dart' show SyntheticToken, Token, TokenType;

import '../fasta_codes.dart' as fasta;

import '../scanner/token_constants.dart' show IDENTIFIER_TOKEN;

import '../util/link.dart' show Link;

import 'identifier_context.dart' show IdentifierContext;

import 'member_kind.dart' show MemberKind;

import 'listener.dart' show Listener;

import 'parser.dart' show Parser;

import 'type_info.dart';

import 'util.dart'
    show
        optional,
        skipMetadata,
        splitGtEq,
        splitGtFromGtGtEq,
        splitGtGt,
        syntheticGt;

/// [SimpleType] is a specialized [TypeInfo] returned by [computeType]
/// when there is a single identifier as the type reference.
const TypeInfo simpleType = const SimpleType();

/// [PrefixedType] is a specialized [TypeInfo] returned by [computeType]
/// when the type reference is of the form: identifier `.` identifier.
const TypeInfo prefixedType = const PrefixedType();

/// [SimpleTypeWith1Argument] is a specialized [TypeInfo] returned by
/// [computeType] when the type reference is of the form:
/// identifier `<` identifier `>`.
const TypeInfo simpleTypeWith1Argument =
    const SimpleTypeWith1Argument(simpleTypeArgument1);

/// [SimpleTypeWith1Argument] is a specialized [TypeInfo] returned by
/// [computeType] when the type reference is of the form:
/// identifier `<` identifier `>=`.
const TypeInfo simpleTypeWith1ArgumentGtEq =
    const SimpleTypeWith1Argument(simpleTypeArgument1GtEq);

/// [SimpleTypeWith1Argument] is a specialized [TypeInfo] returned by
/// [computeType] when the type reference is of the form:
/// identifier `<` identifier `>>`.
const TypeInfo simpleTypeWith1ArgumentGtGt =
    const SimpleTypeWith1Argument(simpleTypeArgument1GtGt);

/// [SimpleTypeArgument1] is a specialized [TypeParamOrArgInfo] returned by
/// [computeTypeParamOrArg] when the type reference is of the form:
/// `<` identifier `>`.
const TypeParamOrArgInfo simpleTypeArgument1 = const SimpleTypeArgument1();

/// [SimpleTypeArgument1] is a specialized [TypeParamOrArgInfo] returned by
/// [computeTypeParamOrArg] when the type reference is of the form:
/// `<` identifier `>=`.
const TypeParamOrArgInfo simpleTypeArgument1GtEq =
    const SimpleTypeArgument1GtEq();

/// [SimpleTypeArgument1] is a specialized [TypeParamOrArgInfo] returned by
/// [computeTypeParamOrArg] when the type reference is of the form:
/// `<` identifier `>>`.
const TypeParamOrArgInfo simpleTypeArgument1GtGt =
    const SimpleTypeArgument1GtGt();

/// See documentation on the [noType] const.
class NoType implements TypeInfo {
  const NoType();

  @override
  bool get couldBeExpression => false;

  @override
  Token ensureTypeNotVoid(Token token, Parser parser) {
    parser.reportRecoverableErrorWithToken(
        token.next, fasta.templateExpectedType);
    parser.rewriter.insertSyntheticIdentifier(token);
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
    listener.handleType(start);
    return token;
  }

  @override
  Token skipType(Token token) {
    return token.next.next.next;
  }
}

/// See documentation on the [simpleTypeWith1Argument] const.
class SimpleTypeWith1Argument implements TypeInfo {
  final TypeParamOrArgInfo typeArg;

  const SimpleTypeWith1Argument(this.typeArg);

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
    token = typeArg.parseArguments(token, parser);
    listener.handleType(start);
    return token;
  }

  @override
  Token skipType(Token token) {
    token = token.next;
    assert(token.isKeywordOrIdentifier);
    return typeArg.skip(token);
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
    assert(isValidTypeReference(token));
    Listener listener = parser.listener;
    listener.handleIdentifier(token, IdentifierContext.typeReference);
    token = noTypeParamOrArg.parseArguments(token, parser);
    listener.handleType(token);
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
    token.kind == IDENTIFIER_TOKEN ||
    optional('this', token) ||
    (token.isIdentifier &&
        // Although `typedef` is a legal identifier,
        // type `typedef` identifier is not legal and in this situation
        // `typedef` is probably a separate declaration.
        (!optional('typedef', token) || !token.next.isIdentifier));

/// When missing a comma, determine if the given token looks like it should
/// be part of a collection of type parameters or arguments.
bool looksLikeTypeParamOrArg(bool inDeclaration, Token token) {
  if (inDeclaration && token.kind == IDENTIFIER_TOKEN) {
    Token next = token.next;
    if (next.kind == IDENTIFIER_TOKEN ||
        optional(',', next) ||
        isCloser(next)) {
      return true;
    }
  }
  return false;
}

/// Instances of [ComplexTypeInfo] are returned by [computeType] to represent
/// type references that cannot be represented by the constants above.
class ComplexTypeInfo implements TypeInfo {
  /// The first token in the type reference.
  Token start;

  /// Type arguments were seen during analysis.
  final TypeParamOrArgInfo typeArguments;

  /// The last token in the type reference.
  Token end;

  /// The `Function` tokens before the start of type variables of function types
  /// as seen during analysis.
  Link<Token> typeVariableStarters = const Link<Token>();

  /// If the receiver represents a generalized function type then this indicates
  /// whether it has a return type, otherwise this is `null`.
  bool gftHasReturnType;

  ComplexTypeInfo(Token beforeStart, this.typeArguments)
      : this.start = beforeStart.next;

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

    final typeVariableEndGroups = <Token>[];
    for (Link<Token> t = typeVariableStarters; t.isNotEmpty; t = t.tail) {
      typeVariableEndGroups.add(
          computeTypeParamOrArg(t.head, true).parseVariables(t.head, parser));
      parser.listener.beginFunctionType(start);
    }

    if (gftHasReturnType == false) {
      // A function type without return type.
      // Push the non-existing return type first. The loop below will
      // generate the full type.
      noType.parseType(token, parser);
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
            // Recovery: Update `end` if a synthetic identifier was inserted.
            end = token;
          }
        }
        token = typeArguments.parseArguments(token, parser);
        parser.listener.handleType(typeRefOrPrefix);
      }
    }

    int endGroupIndex = typeVariableEndGroups.length - 1;
    for (Link<Token> t = typeVariableStarters; t.isNotEmpty; t = t.tail) {
      token = token.next;
      assert(optional('Function', token));
      Token functionToken = token;
      if (optional("<", token.next)) {
        // Skip type parameters, they were parsed above.
        token = typeVariableEndGroups[endGroupIndex];
        assert(optional('>', token));
      }
      --endGroupIndex;
      token = parser.parseFormalParametersRequiredOpt(
          token, MemberKind.GeneralizedFunctionType);
      parser.listener.endFunctionType(functionToken);
    }

    // There are two situations in which the [token] != [end]:
    // Valid code:    identifier `<` identifier `<` identifier `>>`
    //    where `>>` is replaced by two tokens.
    // Invalid code:  identifier `<` identifier identifier `>`
    //    where a synthetic `>` is inserted between the identifiers.
    assert(identical(token, end) || optional('>', token));

    // During recovery, [token] may be a synthetic that was inserted in the
    // middle of the type reference.
    end = token;
    return token;
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

  /// Given a builtin, return the receiver so that parseType will report
  /// an error for the builtin used as a type.
  TypeInfo computeBuiltinAsType(bool required) {
    assert(start.type.isBuiltIn);

    end = typeArguments.skip(start);
    computeRest(end.next, required);
    assert(end != null);
    return this;
  }

  /// Given identifier `<` ... `>`, compute the type
  /// and return the receiver or one of the [TypeInfo] constants.
  TypeInfo computeSimpleWithTypeArguments(bool required) {
    assert(isValidTypeReference(start));
    assert(optional('<', start.next));
    assert(typeArguments != noTypeParamOrArg);

    end = typeArguments.skip(start);
    computeRest(end.next, required);

    if (!required && !looksLikeName(end.next) && gftHasReturnType == null) {
      return noType;
    }
    assert(end != null);
    return this;
  }

  /// Given identifier `.` identifier (or `.` identifier or identifier `.`
  /// for recovery), compute the type and return the receiver or one of the
  /// [TypeInfo] constants.
  TypeInfo computePrefixedType(bool required) {
    Token token = start;
    if (!optional('.', token)) {
      assert(token.isKeywordOrIdentifier);
      token = token.next;
    }
    assert(optional('.', token));
    if (token.next.isKeywordOrIdentifier) {
      token = token.next;
    }

    end = typeArguments.skip(token);
    computeRest(end.next, required);
    if (!required && !looksLikeName(end.next) && gftHasReturnType == null) {
      return noType;
    }
    assert(end != null);
    return this;
  }

  void computeRest(Token token, bool required) {
    while (optional('Function', token)) {
      Token typeVariableStart = token;
      // TODO(danrubel): Consider caching TypeParamOrArgInfo
      token = computeTypeParamOrArg(token, true).skip(token);
      token = token.next;
      if (!optional('(', token)) {
        break; // Not a function type.
      }
      token = token.endGroup;
      if (token == null) {
        break; // Not a function type.
      }
      if (!required) {
        if (!(token.next.isIdentifier || optional('this', token.next))) {
          break; // `Function` used as the name in a function declaration.
        }
      }
      assert(optional(')', token));
      gftHasReturnType ??= typeVariableStart != start;
      typeVariableStarters = typeVariableStarters.prepend(typeVariableStart);
      end = token;
      token = token.next;
    }
  }
}

/// See [noTypeParamOrArg].
class NoTypeParamOrArg extends TypeParamOrArgInfo {
  const NoTypeParamOrArg();

  @override
  Token parseArguments(Token token, Parser parser) {
    parser.listener.handleNoTypeArguments(token.next);
    return token;
  }

  @override
  Token parseVariables(Token token, Parser parser) {
    parser.listener.handleNoTypeVariables(token.next);
    return token;
  }

  @override
  Token skip(Token token) => token;
}

class SimpleTypeArgument1 extends TypeParamOrArgInfo {
  const SimpleTypeArgument1();

  @override
  bool get isSimpleTypeArgument => true;

  @override
  TypeInfo get typeInfo => simpleTypeWith1Argument;

  @override
  Token parseArguments(Token token, Parser parser) {
    Token beginGroup = token.next;
    assert(optional('<', beginGroup));
    Token endGroup = parseEndGroup(beginGroup, beginGroup.next);
    Listener listener = parser.listener;
    listener.beginTypeArguments(beginGroup);
    simpleType.parseType(beginGroup, parser);
    parser.listener.endTypeArguments(1, beginGroup, endGroup);
    return endGroup;
  }

  @override
  Token parseVariables(Token token, Parser parser) {
    Token beginGroup = token.next;
    assert(optional('<', beginGroup));
    token = beginGroup.next;
    Token endGroup = parseEndGroup(beginGroup, token);
    Listener listener = parser.listener;
    listener.beginTypeVariables(beginGroup);
    listener.beginMetadataStar(token);
    listener.endMetadataStar(0);
    listener.handleIdentifier(token, IdentifierContext.typeVariableDeclaration);
    listener.beginTypeVariable(token);
    listener.handleTypeVariablesDefined(token, 1);
    listener.handleNoType(token);
    listener.endTypeVariable(endGroup, 0, null);
    listener.endTypeVariables(beginGroup, endGroup);
    return endGroup;
  }

  @override
  Token skip(Token token) {
    token = token.next;
    assert(optional('<', token));
    token = token.next;
    assert(token.isKeywordOrIdentifier);
    return skipEndGroup(token);
  }

  Token skipEndGroup(Token token) {
    token = token.next;
    assert(optional('>', token));
    return token;
  }

  Token parseEndGroup(Token beginGroup, Token token) {
    token = token.next;
    assert(optional('>', token));
    return token;
  }
}

class SimpleTypeArgument1GtEq extends SimpleTypeArgument1 {
  const SimpleTypeArgument1GtEq();

  @override
  TypeInfo get typeInfo => simpleTypeWith1ArgumentGtEq;

  Token skipEndGroup(Token token) {
    token = token.next;
    assert(optional('>=', token));
    return splitGtEq(token);
  }

  Token parseEndGroup(Token beginGroup, Token beforeEndGroup) {
    Token endGroup = beforeEndGroup.next;
    if (!optional('>', endGroup)) {
      endGroup = splitGtEq(endGroup);
      endGroup.next.setNext(endGroup.next.next);
    }
    beforeEndGroup.setNext(endGroup);
    return endGroup;
  }
}

class SimpleTypeArgument1GtGt extends SimpleTypeArgument1 {
  const SimpleTypeArgument1GtGt();

  @override
  TypeInfo get typeInfo => simpleTypeWith1ArgumentGtGt;

  Token skipEndGroup(Token token) {
    token = token.next;
    assert(optional('>>', token));
    return splitGtGt(token);
  }

  Token parseEndGroup(Token beginGroup, Token beforeEndGroup) {
    Token endGroup = beforeEndGroup.next;
    if (!optional('>', endGroup)) {
      endGroup = splitGtGt(endGroup);
      endGroup.next.setNext(endGroup.next.next);
    }
    beforeEndGroup.setNext(endGroup);
    return endGroup;
  }
}

class ComplexTypeParamOrArgInfo extends TypeParamOrArgInfo {
  /// The first token in the type var.
  final Token start;

  /// If [inDeclaration] is `true`, then this will more aggressively recover
  /// given unbalanced `<` `>` and invalid parameters or arguments.
  final bool inDeclaration;

  /// The token before the end group token (e.g. `>`, `>>`, `>=`, or `>>=`)
  /// or after which a synthetic end group token should be inserted.
  Token beforeEnd;

  ComplexTypeParamOrArgInfo(Token token, this.inDeclaration)
      : assert(optional('<', token.next)),
        assert(inDeclaration != null),
        start = token.next;

  /// Parse the tokens and return the receiver or [noTypeParamOrArg] if there
  /// are no type parameters or arguments. This does not modify the token
  /// stream.
  TypeParamOrArgInfo compute() {
    Token token;
    Token next = start;
    while (true) {
      TypeInfo typeInfo = computeType(next, true, inDeclaration);
      if (typeInfo == noType) {
        while (typeInfo == noType && optional('@', next.next)) {
          next = skipMetadata(next);
          typeInfo = computeType(next, true, inDeclaration);
        }
        if (typeInfo == noType) {
          if (next == start && !inDeclaration && !isCloser(next.next)) {
            return noTypeParamOrArg;
          }
          if (!optional(',', next.next)) {
            token = next;
            next = token.next;
            break;
          }
        }
        assert(typeInfo != noType || optional(',', next.next));
        // Fall through to process type (if any) and consume `,`
      }
      token = typeInfo.skipType(next);
      next = token.next;
      if (optional('extends', next) || optional('super', next)) {
        token = computeType(next, true, inDeclaration).skipType(next);
        next = token.next;
      }
      if (!optional(',', next)) {
        if (isCloser(next)) {
          beforeEnd = token;
          return this;
        }
        if (!inDeclaration) {
          return noTypeParamOrArg;
        }

        // Recovery
        if (!looksLikeTypeParamOrArg(inDeclaration, next)) {
          break;
        }
        // Looks like missing comma. Continue looping.
        next = token;
      }
    }

    // Recovery
    beforeEnd = token;
    if (!isCloser(next)) {
      if (optional('(', next)) {
        token = next.endGroup;
        next = token.next;
      }
      if (!isCloser(next)) {
        token = next;
        next = token.next;
      }
      if (isCloser(next)) {
        beforeEnd = token;
      }
    }
    return this;
  }

  @override
  Token parseArguments(Token token, Parser parser) {
    assert(identical(token.next, start));
    Token next = start;
    parser.listener.beginTypeArguments(start);
    int count = 0;
    while (true) {
      TypeInfo typeInfo = computeType(next, true, inDeclaration);
      if (typeInfo == noType) {
        // Recovery
        while (typeInfo == noType && optional('@', next.next)) {
          parser.reportRecoverableErrorWithToken(
              next.next, fasta.templateUnexpectedToken);
          next = skipMetadata(next);
          typeInfo = computeType(next, true, inDeclaration);
        }
        // Fall through to process type (if any) and consume `,`
      }
      token = typeInfo.ensureTypeOrVoid(next, parser);
      next = token.next;
      ++count;
      if (!optional(',', next)) {
        if (parseCloser(token)) {
          beforeEnd = token;
          break;
        }

        // Recovery
        if (!looksLikeTypeParamOrArg(inDeclaration, next)) {
          parseUnexpectedEnd(token, parser);
          break;
        }
        // Missing comma. Report error, insert comma, and continue looping.
        next = parseMissingComma(token, parser);
      }
    }
    Token endGroup = beforeEnd.next;
    parser.listener.endTypeArguments(count, start, endGroup);
    return endGroup;
  }

  @override
  Token parseVariables(Token token, Parser parser) {
    assert(identical(token.next, start));
    Token next = start;
    Listener listener = parser.listener;
    listener.beginTypeVariables(start);
    int count = 0;

    Link<Token> typeStarts = const Link<Token>();
    Link<TypeInfo> superTypeInfos = const Link<TypeInfo>();

    while (true) {
      token = parser.parseMetadataStar(next);
      next = parser.ensureIdentifier(
          token, IdentifierContext.typeVariableDeclaration);
      if (beforeEnd == token) {
        beforeEnd = next;
      }
      token = next;
      listener.beginTypeVariable(token);
      typeStarts = typeStarts.prepend(token);

      next = token.next;
      if (optional('extends', next) || optional('super', next)) {
        TypeInfo typeInfo = computeType(next, true, inDeclaration);
        token = typeInfo.skipType(next);
        next = token.next;
        superTypeInfos = superTypeInfos.prepend(typeInfo);
      } else {
        superTypeInfos = superTypeInfos.prepend(null);
      }

      ++count;
      if (!optional(',', next)) {
        if (isCloser(token)) {
          break;
        }

        // Recovery
        if (!looksLikeTypeParamOrArg(inDeclaration, next)) {
          break;
        }
        // Missing comma. Report error, insert comma, and continue looping.
        next = parseMissingComma(token, parser);
      }
    }

    assert(count > 0);
    assert(typeStarts.slowLength() == count);
    assert(superTypeInfos.slowLength() == count);
    listener.handleTypeVariablesDefined(token, count);

    token = null;
    while (typeStarts.isNotEmpty) {
      Token token2 = typeStarts.head;
      TypeInfo typeInfo = superTypeInfos.head;

      Token extendsOrSuper = null;
      Token next2 = token2.next;
      if (typeInfo != null) {
        assert(optional('extends', next2) || optional('super', next2));
        extendsOrSuper = next2;
        token2 = typeInfo.ensureTypeOrVoid(next2, parser);
        next2 = token2.next;
      } else {
        assert(!optional('extends', next2) && !optional('super', next2));
        listener.handleNoType(token2);
      }
      // Type variables are "completed" in reverse order, so capture the last
      // consumed token from the first "completed" type variable.
      token ??= token2;
      listener.endTypeVariable(next2, --count, extendsOrSuper);

      typeStarts = typeStarts.tail;
      superTypeInfos = superTypeInfos.tail;
    }

    if (parseCloser(token)) {
      beforeEnd = token;
    } else {
      parseUnexpectedEnd(token, parser);
    }
    Token endGroup = beforeEnd.next;
    listener.endTypeVariables(start, endGroup);
    return endGroup;
  }

  Token parseMissingComma(Token token, Parser parser) {
    Token next = token.next;
    parser.reportRecoverableError(
        next, fasta.templateExpectedButGot.withArguments(','));
    return parser.rewriter.insertToken(
        token, new SyntheticToken(TokenType.COMMA, next.charOffset));
  }

  void parseUnexpectedEnd(Token token, Parser parser) {
    if (beforeEnd.isSynthetic && beforeEnd.charOffset == token.charOffset) {
      // Ensure that beforeEnd is in the token stream
      // as a nested type argument or parameter may have inserted
      // a synthetic closer.
      beforeEnd = token;
    }
    if (parseCloser(beforeEnd)) {
      parser.reportRecoverableErrorWithToken(
          token.next, fasta.templateUnexpectedToken);
    } else {
      // If token is synthetic, then an error has already been reported.
      if (!token.isSynthetic) {
        parser.reportRecoverableError(
            token, fasta.templateExpectedAfterButGot.withArguments('>'));
      }
      Token next = beforeEnd.next;
      Token endGroup = syntheticGt(next);
      endGroup.setNext(next);
      beforeEnd.setNext(endGroup);
    }
  }

  @override
  Token skip(Token token) {
    final next = beforeEnd.next;
    final value = next.stringValue;
    if (identical(value, '>')) {
      return next;
    } else if (identical(value, '>>')) {
      return splitGtGt(next);
    } else if (identical(value, '>=')) {
      return splitGtEq(next);
    } else if (identical(value, '>>=')) {
      return splitGtFromGtGtEq(next);
    }
    return syntheticGt(next);
  }
}

/// Return `true` if [token] is one of `>`, `>>`, `>=', or `>>=`.
bool isCloser(Token token) {
  final value = token.stringValue;
  return identical(value, '>') ||
      identical(value, '>>') ||
      identical(value, '>=') ||
      identical(value, '>>=');
}

/// If [token] is one of `>`, `>>`, `>=', or `>>=`,
/// then update the token stream and return `true`.
bool parseCloser(Token beforeCloser) {
  Token closer = beforeCloser.next;
  String value = closer.stringValue;
  if (identical(value, '>')) {
    return true;
  }
  Token split;
  if (identical(value, '>>')) {
    split = splitGtGt(closer);
  } else if (identical(value, '>=')) {
    split = splitGtEq(closer);
  } else if (identical(value, '>>=')) {
    split = splitGtFromGtGtEq(closer);
  } else {
    return false;
  }
  split.next.setNext(closer.next);
  beforeCloser.setNext(split);
  return true;
}
