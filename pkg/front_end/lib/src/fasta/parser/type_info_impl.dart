// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.parser.type_info_impl;

import '../../scanner/token.dart'
    show BeginToken, SyntheticToken, Token, TokenType;

import '../fasta_codes.dart' as fasta;

import '../scanner/token_constants.dart' show IDENTIFIER_TOKEN;

import '../util/link.dart' show Link;

import 'identifier_context.dart' show IdentifierContext;

import 'member_kind.dart' show MemberKind;

import 'listener.dart' show Listener;

import 'parser.dart' show Parser;

import 'type_info.dart';

import 'util.dart' show isOneOf, optional, skipMetadata;

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
    token = simpleTypeArgument1.parseArguments(token, parser);
    listener.handleType(start, token.next);
    return token;
  }

  @override
  Token skipType(Token token) {
    token = token.next.next;
    assert(optional('<', token));
    assert(token.endGroup != null || optional('>>', token.next.next));
    return token.endGroup ?? token.next;
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
    token.kind == IDENTIFIER_TOKEN ||
    optional('this', token) ||
    (token.isIdentifier &&
        // Although `typedef` is a legal identifier,
        // type `typedef` identifier is not legal and in this situation
        // `typedef` is probably a separate declaration.
        (!optional('typedef', token) || !token.next.isIdentifier));

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

  /// Type arguments were seen during analysis.
  final TypeParamOrArgInfo typeArguments;

  /// The last token in the type reference.
  Token end;

  /// The tokens before the start of type variables of function types seen
  /// during analysis. Notice that the tokens in this list might precede
  /// either `'<'` or `'('` as not all function types have type parameters.
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

    for (Link<Token> t = typeVariableStarters; t.isNotEmpty; t = t.tail) {
      parser.parseTypeVariablesOpt(t.head);
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

/// See [noTypeParamOrArg].
class NoTypeParamOrArg implements TypeParamOrArgInfo {
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

class SimpleTypeArgument1 implements TypeParamOrArgInfo {
  const SimpleTypeArgument1();

  @override
  Token parseArguments(Token token, Parser parser) {
    BeginToken start = token = token.next;
    assert(optional('<', token));
    Listener listener = parser.listener;
    listener.beginTypeArguments(token);
    token = simpleType.parseType(token, parser);
    token = processEndGroup(token, start, parser);
    parser.listener.endTypeArguments(1, start, token);
    return token;
  }

  @override
  Token parseVariables(Token token, Parser parser) {
    BeginToken start = token = token.next;
    assert(optional('<', token));
    Listener listener = parser.listener;
    listener.beginTypeVariables(token);
    token = token.next;
    listener.beginTypeVariable(token);
    listener.beginMetadataStar(token);
    listener.endMetadataStar(0);
    listener.handleIdentifier(token, IdentifierContext.typeVariableDeclaration);
    listener.handleNoType(token);
    token = processEndGroup(token, start, parser);
    listener.endTypeVariable(token, null);
    listener.endTypeVariables(1, start, token);
    return token;
  }

  @override
  Token skip(Token token) {
    token = token.next;
    assert(token.endGroup != null ||
        (optional('>', token.next.next) || optional('>>', token.next.next)));
    return token.endGroup ??
        (optional('>>', token.next.next) ? token.next : token.next.next);
  }
}

class ComplexTypeParamOrArgInfo implements TypeParamOrArgInfo {
  /// The first token in the type var.
  final BeginToken start;

  /// The last token in the group (typically `>`).
  /// If a `>>` has not yet been split, then this field will be
  /// `>>` for the outer group and the token before `>>` for the inner group.
  Token end;

  /// A collection of `<` without closing `>` in the reverse order from which
  /// they were encountered in the token stream.
  Link<Token> unbalancedLt = const Link<Token>();

  ComplexTypeParamOrArgInfo(Token token)
      : assert(optional('<', token.next)),
        start = token.next;

  /// Parse the tokens and return the receiver or [noTypeParamOrArg] if there
  /// are no type parameters or arguments. This does not modify the token
  /// stream.
  ///
  /// If this group is enclosed and the outer group ends with `>>`, then
  /// [endGroup] is set to either `>>` if the token has not been split
  /// or the first `>` if the `>>` token has been split.
  TypeParamOrArgInfo compute(Token endGroup) {
    Token innerEndGroup;
    if (start.endGroup != null && optional('>>', start.endGroup)) {
      innerEndGroup = start.endGroup;
    }

    Token token;
    Token next = start;
    do {
      TypeInfo typeInfo = computeType(next, true, innerEndGroup);
      if (typeInfo == noType) {
        while (typeInfo == noType && optional('@', next.next)) {
          next = skipMetadata(next);
          typeInfo = computeType(next, true, innerEndGroup);
        }
        if (typeInfo == noType && !optional(',', next.next)) {
          token = next;
          next = token.next;
          break;
        }
        assert(typeInfo != noType || optional(',', next.next));
        // Fall through to process type (if any) and consume `,`
      }
      token = typeInfo.skipType(next);
      next = token.next;
      if (optional('extends', next) || optional('super', next)) {
        token = computeType(next, true, innerEndGroup).skipType(next);
        next = token.next;
      }
    } while (optional(',', next));

    if (next == start.endGroup) {
      end = next;
    } else if (next == endGroup) {
      assert(start.endGroup == null);
      assert(optional('>', endGroup) || optional('>>', endGroup));
      // If `>>`, then the end or last consumed token is the token before `>>`.
      end = optional('>>', next) ? token : next;
    } else {
      return noTypeParamOrArg;
    }
    return this;
  }

  /// Parse the tokens and return the receiver or [noTypeParamOrArg] if there
  /// are no type parameters or arguments. This does not modify the token
  /// stream.
  ///
  /// This is called when parsing type parameters in a top level
  /// or class member declaration. It assumes that a leading `<` cannot be part
  /// of an expression, and thus tries to more aggressively recover.
  ///
  TypeParamOrArgInfo computeBalancedButInvalid() {
    assert(start.endGroup != null);
    Token next = start.endGroup.next;
    if (next.isIdentifier || optional('(', next)) {
      end = start.endGroup;
      return this;
    } else {
      return noTypeParamOrArg;
    }
  }

  /// Parse the tokens and return the receiver or [noTypeParamOrArg] if there
  /// are no type parameters or arguments. This does not modify the token
  /// stream.
  ///
  /// This is called when parsing type parameters in a top level
  /// or class member declaration. It assumes that a leading `<` cannot be part
  /// of an expression, and thus tries to more aggressively recover
  /// given an unmatched '<'.
  ///
  TypeParamOrArgInfo computeUnbalanced() {
    assert(start.endGroup == null);
    unbalancedLt = unbalancedLt.prepend(start);
    Token token = start;
    Token next = token.next;
    while (!next.isEof) {
      if (optional('Function', next)) {
        next = next.next;
        if (optional('<', next)) {
          next = skipTypeVariables(next);
          if (next == null) {
            break;
          }
          next = next.next;
        }
        if (optional('(', next)) {
          next = next.endGroup;
        } else {
          break;
        }
      } else if (optional('<', next)) {
        Token endGroup = skipTypeVariables(next);
        if (endGroup != null) {
          next = endGroup;
        } else {
          unbalancedLt = unbalancedLt.prepend(next);
        }
      } else if (!isValidTypeReference(next) &&
          !isOneOf(next, const ['.', ',', 'extends', 'super'])) {
        break;
      }
      token = next;
      next = token.next;
    }

    end = token;
    return this;
  }

  @override
  Token parseArguments(Token token, Parser parser) {
    Token begin = balanceLt(token, parser);
    Token next = begin;
    Token innerEndGroup = processBeginGroup(begin, parser);
    parser.listener.beginTypeArguments(begin);
    int count = 0;
    while (true) {
      TypeInfo typeInfo = computeType(next, true, innerEndGroup);
      if (typeInfo == noType) {
        // Recovery
        while (typeInfo == noType && optional('@', next.next)) {
          parser.reportRecoverableErrorWithToken(
              next.next, fasta.templateUnexpectedToken);
          next = skipMetadata(next);
          typeInfo = computeType(next, true, innerEndGroup);
        }
        // Fall through to process type (if any) and consume `,`
      }
      token = typeInfo.ensureTypeOrVoid(next, parser);
      next = token.next;
      ++count;
      if (!optional(',', next)) {
        if (IDENTIFIER_TOKEN != next.kind) {
          break;
        }

        // Recovery: missing comma
        parser.reportRecoverableError(
            next, fasta.templateExpectedButGot.withArguments(','));
        next = parser.rewriter
            .insertTokenAfter(
                token, new SyntheticToken(TokenType.COMMA, next.charOffset))
            .next;
      }
    }
    end = processEndGroup(token, begin, parser);
    parser.listener.endTypeArguments(count, begin, end);
    return end;
  }

  @override
  Token parseVariables(Token token, Parser parser) {
    Token begin = balanceLt(token, parser);
    Token next = begin;
    Token innerEndGroup = processBeginGroup(begin, parser);
    parser.listener.beginTypeVariables(begin);
    int count = 0;
    while (true) {
      parser.listener.beginTypeVariable(next.next);
      token = parser.parseMetadataStar(next);
      token = parser.ensureIdentifier(
          token, IdentifierContext.typeVariableDeclaration);
      Token extendsOrSuper = null;
      next = token.next;
      if (optional('extends', next) || optional('super', next)) {
        extendsOrSuper = next;
        token = computeType(next, true, innerEndGroup)
            .ensureTypeOrVoid(next, parser);
        next = token.next;
      } else {
        parser.listener.handleNoType(token);
      }
      parser.listener.endTypeVariable(next, extendsOrSuper);
      ++count;
      if (!optional(',', next)) {
        if (IDENTIFIER_TOKEN != next.kind) {
          break;
        }

        // Recovery: missing comma
        parser.reportRecoverableError(
            next, fasta.templateExpectedButGot.withArguments(','));
        next = parser.rewriter
            .insertTokenAfter(
                token, new SyntheticToken(TokenType.COMMA, next.charOffset))
            .next;
      }
    }
    end = processEndGroup(token, begin, parser);
    parser.listener.endTypeVariables(count, begin, end);
    return end;
  }

  @override
  Token skip(Token token) => end;

  /// For every unbalanced `<` append a synthetic `>`. Return the first `<`
  Token balanceLt(Token token, Parser parser) {
    assert(identical(start, token.next));
    if (unbalancedLt.isEmpty) {
      return start;
    }
    Token begin = parser.rewriter.balanceLt(token, end, unbalancedLt);
    assert(begin.endGroup != null);
    if (begin.endGroup.isSynthetic) {
      parser.reportRecoverableError(
          begin.endGroup.next, fasta.templateExpectedButGot.withArguments('>'));
    }
    return begin;
  }
}

Token processBeginGroup(BeginToken start, Parser parser) {
  Token innerEndGroup;
  if (start.endGroup != null && optional('>>', start.endGroup)) {
    innerEndGroup = parser.rewriter.splitGtGt(start);
  }
  return innerEndGroup;
}

Token processEndGroup(Token token, BeginToken start, Parser parser) {
  Token next = token.next;
  if (next == start.endGroup) {
    return next;
  } else if (optional('>', next)) {
    // When `>>` is split, the inner group's endGroup updated here.
    assert(start.endGroup == null);
    start.endGroup = next;
    return next;
  } else if (optional('>>', next)) {
    // In this case, the last consumed token is the token before `>>`.
    return token;
  } else {
    // Recovery
    parser.reportRecoverableErrorWithToken(next, fasta.templateUnexpectedToken);
    if (start.endGroup != null) {
      return start.endGroup;
    }
    while (true) {
      if (optional('>', next)) {
        start.endGroup = next;
        return next;
      }
      if (optional('>>', next)) {
        // In this case, the last consumed token is the token before `>>`.
        return token;
      }
      if (next.isEof) {
        // Sanity check.
        return next;
      }
      token = next;
      next = token.next;
    }
  }
}
