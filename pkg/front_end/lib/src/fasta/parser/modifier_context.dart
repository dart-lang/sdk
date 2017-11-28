// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../scanner/token.dart' show SyntheticStringToken, Token, TokenType;
import '../messages.dart' as fasta;
import 'formal_parameter_kind.dart' show FormalParameterKind;
import 'forwarding_listener.dart' show ForwardingListener;
import 'member_kind.dart' show MemberKind;
import 'parser.dart' show Parser;
import 'type_continuation.dart' show TypeContinuation;
import 'util.dart' show optional;

bool isModifier(Token token) {
  if (!token.isModifier) {
    return false;
  }
  if (token.type.isBuiltIn) {
    // A built-in identifier can only be a modifier as long as it is
    // followed by another modifier or an identifier. Otherwise, it is the
    // identifier.
    //
    // For example, `external` is a modifier in this declaration:
    //   external Foo foo();
    // but is the identifier in this declaration
    //   external() => true;
    if (!token.next.type.isKeyword && !token.next.isIdentifier) {
      return false;
    }
  }
  return true;
}

class ModifierContext {
  final Parser parser;
  MemberKind memberKind;
  final FormalParameterKind parameterKind;
  final bool isVarAllowed;
  TypeContinuation typeContinuation;
  int modifierCount = 0;

  ModifierContext(this.parser, this.memberKind, this.parameterKind,
      this.isVarAllowed, this.typeContinuation);

  bool get isCovariantFinalAllowed =>
      memberKind != MemberKind.StaticField &&
      memberKind != MemberKind.NonStaticField;

  Token parseOpt(Token token) {
    if (optional('external', token.next)) {
      token = parseExternalOpt(token);
    }

    if (optional('static', token.next)) {
      token = parseStaticOpt(token);
    } else if (optional('covariant', token.next)) {
      token = parseCovariantOpt(token);
      if (optional('final', token.next)) {
        if (isCovariantFinalAllowed) {
          token = parseFinal(token);
        }
      } else if (optional('var', token.next)) {
        token = parseVar(token);
      }
      return token;
    }

    if (optional('final', token.next)) {
      token = parseFinal(token);
    } else if (optional('var', token.next)) {
      token = parseVar(token);
    } else if (optional('const', token.next)) {
      token = parseConst(token);
    }
    return token;
  }

  Token parseConst(Token token) {
    Token next = token.next;
    assert(optional('const', next));
    if (!isVarAllowed) {
      parser.reportRecoverableErrorWithToken(
          next, fasta.templateExtraneousModifier);
      // TODO(danrubel): investigate why token must be included (fall through)
      // so that tests will pass. I think that it should not be included
      // because the 'const' is invalid in this situation.
      //
      // return token.next;
    }
    typeContinuation ??= TypeContinuation.Optional;
    modifierCount++;
    return parser.parseModifier(token.next);
  }

  Token parseCovariantOpt(Token token) {
    Token next = token.next;
    assert(optional('covariant', next));
    // A built-in identifier can only be a modifier as long as it is
    // followed by another modifier or an identifier.
    // Otherwise, it is the identifier.
    if (!next.next.isKeywordOrIdentifier) {
      return token;
    }
    switch (memberKind) {
      case MemberKind.StaticField:
      case MemberKind.StaticMethod:
      case MemberKind.TopLevelField:
      case MemberKind.TopLevelMethod:
        parser.reportRecoverableErrorWithToken(
            next, fasta.templateExtraneousModifier);
        return next;

      default:
        modifierCount++;
        return parser.parseModifier(token.next);
    }
  }

  Token parseExternalOpt(Token token) {
    Token next = token.next;
    assert(optional('external', next));
    // A built-in identifier can only be a modifier as long as it is
    // followed by another modifier or an identifier.
    // Otherwise, it is the identifier.
    if (!next.next.isKeywordOrIdentifier) {
      return token;
    }
    switch (memberKind) {
      case MemberKind.Factory:
      case MemberKind.NonStaticMethod:
      case MemberKind.StaticMethod:
      case MemberKind.TopLevelMethod:
        modifierCount++;
        return parser.parseModifier(token.next);

      case MemberKind.StaticField:
      case MemberKind.NonStaticField:
        parser.reportRecoverableError(next, fasta.messageExternalField);
        return next;

      default:
        parser.reportRecoverableErrorWithToken(
            next, fasta.templateExtraneousModifier);
        return next;
    }
  }

  Token parseFinal(Token token) {
    Token next = token.next;
    if (!isVarAllowed && parameterKind == null) {
      parser.reportRecoverableErrorWithToken(
          next, fasta.templateExtraneousModifier);
      return next;
    }
    typeContinuation ??= TypeContinuation.Optional;
    modifierCount++;
    return parser.parseModifier(token.next);
  }

  Token parseStaticOpt(Token token) {
    Token next = token.next;
    assert(optional('static', next));
    // A built-in identifier can only be a modifier as long as it is
    // followed by another modifier or an identifier.
    // Otherwise, it is the identifier.
    if (!next.next.isKeywordOrIdentifier) {
      return token;
    }
    if (parameterKind != null) {
      parser.reportRecoverableErrorWithToken(
          next, fasta.templateExtraneousModifier);
      return next;
    }
    switch (memberKind) {
      case MemberKind.NonStaticMethod:
        memberKind = MemberKind.StaticMethod;
        modifierCount++;
        return parser.parseModifier(next);
      case MemberKind.NonStaticField:
        memberKind = MemberKind.StaticField;
        modifierCount++;
        return parser.parseModifier(next);
      default:
        parser.reportRecoverableErrorWithToken(
            next, fasta.templateExtraneousModifier);
        return next;
    }
  }

  Token parseVar(Token token) {
    if (!isVarAllowed && parameterKind == null) {
      Token next = token.next;
      parser.reportRecoverableErrorWithToken(
          next, fasta.templateExtraneousModifier);
      return next;
    }
    switch (typeContinuation ?? TypeContinuation.Required) {
      case TypeContinuation.NormalFormalParameter:
        typeContinuation = TypeContinuation.NormalFormalParameterAfterVar;
        break;

      case TypeContinuation.OptionalPositionalFormalParameter:
        typeContinuation =
            TypeContinuation.OptionalPositionalFormalParameterAfterVar;
        break;

      case TypeContinuation.NamedFormalParameter:
        typeContinuation = TypeContinuation.NamedFormalParameterAfterVar;
        break;

      default:
        typeContinuation = TypeContinuation.OptionalAfterVar;
        break;
    }
    modifierCount++;
    return parser.parseModifier(token.next);
  }
}

class ModifierRecoveryContext extends ModifierContext {
  Token constToken;
  Token covariantToken;
  Token externalToken;
  Token finalToken;
  Token staticToken;
  Token varToken;

  ModifierRecoveryContext(
      Parser parser,
      MemberKind memberKind,
      FormalParameterKind parameterKind,
      bool isVarAllowed,
      TypeContinuation typeContinuation)
      : super(
            parser, memberKind, parameterKind, isVarAllowed, typeContinuation);

  @override
  Token parseOpt(Token token) {
    // Reparse to determine which modifiers have already been parsed
    // but intercept the events so they are not sent to the primary listener.
    final primaryListener = parser.listener;
    parser.listener = new ForwardingListener();
    token = super.parseOpt(token);
    parser.listener = primaryListener;

    // Process invalid and out-of-order modifiers
    while (isModifier(token.next)) {
      final value = token.next.stringValue;
      if (identical('abstract', value)) {
        token = parseAbstract(token);
      } else if (identical('const', value)) {
        token = parseConst(token);
      } else if (identical('covariant', value)) {
        token = parseCovariantOpt(token);
      } else if (identical('external', value)) {
        token = parseExternalOpt(token);
      } else if (identical('final', value)) {
        token = parseFinal(token);
      } else if (identical('static', value)) {
        token = parseStaticOpt(token);
      } else if (identical('var', value)) {
        token = parseVar(token);
      } else {
        token = parseExtraneousModifier(token);
      }
    }

    return token;
  }

  Token parseAbstract(Token token) {
    assert(optional('abstract', token.next));
    if (memberKind == MemberKind.NonStaticField ||
        memberKind == MemberKind.NonStaticMethod ||
        memberKind == MemberKind.StaticField ||
        memberKind == MemberKind.StaticMethod) {
      parser.reportRecoverableError(
          token.next, fasta.messageAbstractClassMember);
      return token.next;
    }
    return parseExtraneousModifier(token);
  }

  @override
  Token parseConst(Token token) {
    Token next = token.next;
    if (constToken != null) {
      parser.reportRecoverableErrorWithToken(
          next, fasta.templateDuplicatedModifier);
      return next;
    }
    constToken = next;
    if (covariantToken != null) {
      parser.reportRecoverableError(constToken, fasta.messageConstAndCovariant);
      return constToken;
    }
    if (finalToken != null) {
      parser.reportRecoverableError(constToken, fasta.messageConstAndFinal);
      return constToken;
    }
    if (varToken != null) {
      parser.reportRecoverableError(constToken, fasta.messageConstAndVar);
      return constToken;
    }
    return super.parseConst(token);
  }

  @override
  Token parseCovariantOpt(Token token) {
    Token next = token.next;
    if (covariantToken != null) {
      parser.reportRecoverableErrorWithToken(
          next, fasta.templateDuplicatedModifier);
      return next;
    }
    covariantToken = next;
    if (constToken != null) {
      parser.reportRecoverableError(
          covariantToken, fasta.messageConstAndCovariant);
      return covariantToken;
    }
    if (staticToken != null) {
      parser.reportRecoverableError(
          covariantToken, fasta.messageCovariantAndStatic);
      return covariantToken;
    }
    if (varToken != null) {
      parser.reportRecoverableError(
          covariantToken, fasta.messageCovariantAfterVar);
      // fall through to parse modifier
    } else if (finalToken != null) {
      if (!isCovariantFinalAllowed) {
        parser.reportRecoverableError(
            covariantToken, fasta.messageFinalAndCovariant);
        return covariantToken;
      }
      parser.reportRecoverableError(
          covariantToken, fasta.messageCovariantAfterFinal);
      // fall through to parse modifier
    }
    return super.parseCovariantOpt(token);
  }

  @override
  Token parseExternalOpt(Token token) {
    Token next = token.next;
    if (externalToken != null) {
      parser.reportRecoverableErrorWithToken(
          next, fasta.templateDuplicatedModifier);
      return next;
    }
    externalToken = token.next;
    return super.parseExternalOpt(token);
  }

  @override
  Token parseFinal(Token token) {
    Token next = token.next;
    if (finalToken != null) {
      parser.reportRecoverableErrorWithToken(
          next, fasta.templateDuplicatedModifier);
      return next;
    }
    finalToken = next;
    if (constToken != null) {
      parser.reportRecoverableError(finalToken, fasta.messageConstAndFinal);
      return finalToken;
    }
    if (covariantToken != null && !isCovariantFinalAllowed) {
      parser.reportRecoverableError(finalToken, fasta.messageFinalAndCovariant);
      return finalToken;
    }
    if (varToken != null) {
      parser.reportRecoverableError(finalToken, fasta.messageFinalAndVar);
      return finalToken;
    }
    return super.parseFinal(token);
  }

  Token parseExtraneousModifier(Token token) {
    Token next = token.next;
    parser.reportRecoverableErrorWithToken(
        next, fasta.templateExtraneousModifier);
    return next;
  }

  @override
  Token parseStaticOpt(Token token) {
    Token next = token.next;
    if (staticToken != null) {
      parser.reportRecoverableErrorWithToken(
          next, fasta.templateDuplicatedModifier);
      return next;
    }
    staticToken = next;
    if (covariantToken != null) {
      parser.reportRecoverableError(
          staticToken, fasta.messageCovariantAndStatic);
      return staticToken;
    }
    if (constToken != null) {
      parser.reportRecoverableError(staticToken, fasta.messageStaticAfterConst);
      // fall through to parse modifier
    } else if (finalToken != null) {
      parser.reportRecoverableError(staticToken, fasta.messageStaticAfterFinal);
      // fall through to parse modifier
    } else if (varToken != null) {
      parser.reportRecoverableError(staticToken, fasta.messageStaticAfterVar);
      // fall through to parse modifier
    }
    return super.parseStaticOpt(token);
  }

  @override
  Token parseVar(Token token) {
    Token next = token.next;
    if (varToken != null) {
      parser.reportRecoverableErrorWithToken(
          next, fasta.templateDuplicatedModifier);
      return next;
    }
    varToken = next;
    if (constToken != null) {
      parser.reportRecoverableError(varToken, fasta.messageConstAndVar);
      return varToken;
    }
    if (finalToken != null) {
      parser.reportRecoverableError(varToken, fasta.messageFinalAndVar);
      return varToken;
    }
    return super.parseVar(token);
  }
}

class ClassMethodModifierContext {
  final Parser parser;
  Token getOrSet;

  int modifierCount;
  Token constToken;
  Token covariantToken;
  Token externalToken;
  Token staticToken;

  /// If recovery finds an invalid class member declaration
  /// (e.g. an enum declared inside a class),
  /// then this is set to the last token in the invalid declaration.
  Token endInvalidMemberToken;

  ClassMethodModifierContext(this.parser);

  Token parseRecovery(Token token, Token externalToken, Token staticToken,
      Token getOrSet, Token afterModifiers) {
    modifierCount = 0;
    this.getOrSet = getOrSet;
    if (externalToken != null) {
      this.externalToken = externalToken;
      ++modifierCount;
    }
    if (staticToken != null) {
      this.staticToken = staticToken;
      ++modifierCount;
    }
    while (token != afterModifiers) {
      String value = token.stringValue;
      if (identical(value, 'abstract')) {
        token = parseAbstractRecovery(token);
      } else if (identical(value, 'class')) {
        token = parseClassRecovery(token);
      } else if (identical(value, 'const')) {
        parseConstRecovery(token);
        token = token.next;
      } else if (identical(value, 'covariant')) {
        parseCovariantRecovery(token);
        token = token.next;
      } else if (identical(value, 'enum')) {
        token = parseEnumRecovery(token);
      } else if (identical(value, 'external')) {
        parseExternalRecovery(token);
        token = token.next;
      } else if (identical(value, 'static')) {
        parseStaticRecovery(token);
        token = token.next;
      } else if (identical(value, 'typedef')) {
        parser.reportRecoverableError(token, fasta.messageTypedefInClass);
        token = token.next;
      } else if (identical(value, 'var')) {
        parseVarRecovery(token);
        token = token.next;
      } else if (token.isModifier) {
        parser.reportRecoverableErrorWithToken(
            token, fasta.templateExtraneousModifier);
        token = token.next;
      } else {
        parser.reportRecoverableErrorWithToken(
            token, fasta.templateUnexpectedToken);
        // We found something that doesn't look like a modifier,
        // so skip the rest of the tokens.
        token = afterModifiers.next;
        break;
      }
      if (endInvalidMemberToken != null) {
        return afterModifiers;
      }
    }
    return token;
  }

  Token parseAbstractRecovery(Token token) {
    assert(optional('abstract', token));
    if (optional('class', token.next)) {
      return parseClassRecovery(token.next);
    }
    parser.reportRecoverableError(token, fasta.messageAbstractClassMember);
    return token.next;
  }

  Token parseClassRecovery(Token token) {
    assert(optional('class', token));
    token = token.next;
    parser.reportRecoverableError(token, fasta.messageClassInClass);
    // If the declaration appears to be a valid class declaration
    // then skip the entire declaration so that we only generate the one
    // error (above) rather than a plethora of unhelpful errors.
    if (token.isIdentifier) {
      endInvalidMemberToken = token;
      // skip class name
      token = token.next;
      // TODO(danrubel): consider parsing (skipping) the class header
      // with a recovery listener so that no events are generated
      if (optional('{', token) && token.endGroup != null) {
        // skip class body
        endInvalidMemberToken = token.endGroup;
        token = endInvalidMemberToken.next;
      }
    }
    return token;
  }

  void parseConstRecovery(Token token) {
    assert(optional('const', token));
    if (constToken != null) {
      parser.reportRecoverableErrorWithToken(
          token, fasta.templateDuplicatedModifier);
    } else if (getOrSet != null) {
      parser.reportRecoverableErrorWithToken(
          token, fasta.templateExtraneousModifier);
    } else {
      constToken = token;
      parser.parseModifier(token);
      ++modifierCount;
    }
  }

  void parseCovariantRecovery(Token token) {
    assert(optional('covariant', token));
    if (covariantToken != null) {
      parser.reportRecoverableErrorWithToken(
          token, fasta.templateDuplicatedModifier);
    } else if (getOrSet == null || optional('get', getOrSet)) {
      parser.reportRecoverableError(token, fasta.messageCovariantMember);
    } else if (staticToken != null) {
      parser.reportRecoverableError(token, fasta.messageCovariantAndStatic);
    } else {
      covariantToken = token;
      parser.parseModifier(token);
      ++modifierCount;
    }
  }

  Token parseEnumRecovery(Token token) {
    assert(optional('enum', token));
    parser.reportRecoverableError(token, fasta.messageEnumInClass);
    token = token.next;
    // If the declaration appears to be a valid enum declaration
    // then skip the entire declaration so that we only generate the one
    // error (above) rather than a plethora of unhelpful errors.
    if (token.isIdentifier) {
      endInvalidMemberToken = token;
      // skip enum name
      token = token.next;
      if (optional('{', token) && token.endGroup != null) {
        // TODO(danrubel): Consider replacing this `skip enum` functionality
        // with something that can parse and resolve the declaration
        // even though it is in a class context
        endInvalidMemberToken = token.endGroup;
        token = token.next;
      }
    }
    return token;
  }

  void parseExternalRecovery(Token token) {
    assert(optional('external', token));
    if (externalToken != null) {
      parser.reportRecoverableErrorWithToken(
          token, fasta.templateDuplicatedModifier);
    } else {
      if (staticToken != null) {
        parser.reportRecoverableError(token, fasta.messageExternalAfterStatic);
        // Fall through to record token.
      } else if (constToken != null) {
        parser.reportRecoverableError(token, fasta.messageExternalAfterConst);
        // Fall through to record token.
      }
      externalToken = token;
      parser.parseModifier(token);
      ++modifierCount;
    }
  }

  void parseStaticRecovery(Token token) {
    assert(optional('static', token));
    if (staticToken != null) {
      parser.reportRecoverableErrorWithToken(
          token, fasta.templateDuplicatedModifier);
    } else if (covariantToken != null) {
      parser.reportRecoverableError(token, fasta.messageCovariantAndStatic);
    } else {
      if (constToken != null) {
        parser.reportRecoverableError(token, fasta.messageStaticAfterConst);
        // Fall through to record token.
      }
      staticToken = token;
      parser.parseModifier(token);
      ++modifierCount;
    }
  }

  void parseVarRecovery(Token token) {
    if (token.next.isIdentifier && optional('(', token.next.next)) {
      parser.reportRecoverableError(token, fasta.messageVarReturnType);
    } else {
      parser.reportRecoverableErrorWithToken(
          token, fasta.templateExtraneousModifier);
    }
  }
}

class FactoryModifierContext {
  final Parser parser;
  int modifierCount;
  Token constToken;
  Token externalToken;
  Token factoryKeyword;

  FactoryModifierContext(
      this.parser, this.modifierCount, this.externalToken, this.constToken);

  Token parseRecovery(Token token) {
    Token next = token.next;
    while (true) {
      final value = next.stringValue;
      if (identical('const', value)) {
        parseConst(next);
      } else if (identical('external', value)) {
        parseExternal(next);
      } else if (identical('factory', value)) {
        parseFactory(next);
      } else if (isModifier(next)) {
        parser.reportRecoverableErrorWithToken(
            next, fasta.templateExtraneousModifier);
      } else {
        break;
      }
      token = next;
      next = token.next;
    }
    while (isModifier(next)) {
      final value = next.stringValue;
      if (identical('const', value)) {
        parseConst(next);
      } else {
        parser.reportRecoverableErrorWithToken(
            next, fasta.templateExtraneousModifier);
      }
      token = next;
      next = token.next;
    }
    return token;
  }

  void parseConst(Token token) {
    assert(optional('const', token));
    if (constToken == null) {
      if (factoryKeyword != null) {
        parser.reportRecoverableError(token, fasta.messageConstAfterFactory);
      }
      constToken = token;
      parser.parseModifier(token);
      ++modifierCount;
    } else {
      parser.reportRecoverableErrorWithToken(
          token, fasta.templateDuplicatedModifier);
    }
  }

  void parseExternal(Token token) {
    assert(optional('external', token));
    if (externalToken == null) {
      if (constToken != null) {
        parser.reportRecoverableError(token, fasta.messageExternalAfterConst);
      } else if (factoryKeyword != null) {
        parser.reportRecoverableError(token, fasta.messageExternalAfterFactory);
      }
      externalToken = token;
      parser.parseModifier(token);
      ++modifierCount;
    } else {
      parser.reportRecoverableErrorWithToken(
          token, fasta.templateDuplicatedModifier);
    }
  }

  void parseFactory(Token token) {
    assert(optional('factory', token));
    if (factoryKeyword == null) {
      factoryKeyword = token;
    } else {
      parser.reportRecoverableErrorWithToken(
          token, fasta.templateDuplicatedModifier);
    }
  }
}

class TopLevelMethodModifierContext {
  final Parser parser;
  Token name;
  Token externalToken;

  /// If recovery finds the beginning of a new declaration,
  /// then this is set to the last token in the prior declaration.
  Token endInvalidTopLevelDeclarationToken;

  TopLevelMethodModifierContext(this.parser, this.name);

  /// Parse modifiers from the token following [token] up to but not including
  /// [afterModifiers]. If a new declaration start is found in the sequence of
  /// tokens, then set [endInvalidTopLevelDeclarationToken] to be the last token
  /// in the current declaration and return the token immediately preceding the
  /// new declaration.
  Token parseRecovery(Token token, Token afterModifiers) {
    assert(token != afterModifiers && token.next != afterModifiers);

    while (token.next != afterModifiers) {
      token = token.next;
      if (optional('external', token)) {
        if (externalToken == null) {
          externalToken = token;
        } else {
          parser.reportRecoverableErrorWithToken(
              token, fasta.templateDuplicatedModifier);
        }
      } else if (optional('operator', token)) {
        parser.reportRecoverableError(token, fasta.messageTopLevelOperator);
        // If the next token is a top level keyword, then
        // Indicate to the caller that the next token should be
        // parsed as a new top level declaration.
        Token next = token.next;
        if (next.isTopLevelKeyword) {
          endInvalidTopLevelDeclarationToken = token;
          return token;
        }
        if (next.isOperator) {
          // If the operator is not one of the modifiers, then skip it,
          // and insert a synthetic modifier
          // to be interpreted as the top level function's identifier.
          if (identical(next, afterModifiers)) {
            name = parser.rewriter.insertToken(
                new SyntheticStringToken(
                    TokenType.IDENTIFIER,
                    '#synthetic_function_${next.charOffset}',
                    token.charOffset,
                    0),
                next.next);
            return name;
          }
          // If the next token is an operator, then skip it
          // because the error message above says it all.
          token = token.next;
        }
      } else if (optional('factory', token)) {
        parser.reportRecoverableError(
            token, fasta.messageFactoryTopLevelDeclaration);
        // Indicate to the caller that the next token should be
        // parsed as a new top level declaration.
        endInvalidTopLevelDeclarationToken = token;
        return token;
      } else {
        // TODO(danrubel): report more specific analyzer error codes
        parser.reportRecoverableErrorWithToken(
            token, fasta.templateExtraneousModifier);
      }
    }
    return token;
  }
}
