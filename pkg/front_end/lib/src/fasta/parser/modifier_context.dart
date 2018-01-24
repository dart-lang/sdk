// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../scanner/token.dart' show Token;
import '../messages.dart' as fasta;
import 'formal_parameter_kind.dart' show FormalParameterKind;
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

/// Skip modifier tokens until the last modifier token is reached
/// and return that token. If [token] is not a modifier, then return [token].
Token skipToLastModifier(Token token) {
  Token next = token.next;
  while (isModifier(next)) {
    token = next;
    next = token.next;
  }
  return token;
}

TypeContinuation typeContinuationAfterVar(TypeContinuation typeContinuation) {
  switch (typeContinuation) {
    case TypeContinuation.NormalFormalParameter:
      return TypeContinuation.NormalFormalParameterAfterVar;

    case TypeContinuation.OptionalPositionalFormalParameter:
      return TypeContinuation.OptionalPositionalFormalParameterAfterVar;

    case TypeContinuation.NamedFormalParameter:
      return TypeContinuation.NamedFormalParameterAfterVar;

    default:
      return TypeContinuation.OptionalAfterVar;
  }
}

TypeContinuation typeContinuationFromMemberKind(
        bool isVarAllowed, MemberKind memberKind) =>
    (isVarAllowed || memberKind == MemberKind.GeneralizedFunctionType)
        ? TypeContinuation.Required
        : TypeContinuation.Optional;

/// This class is used to parse modifiers in most locations where modifiers
/// can occur. However, it isn't used when parsing a class or when parsing
/// the modifiers of a member function (non-local),
/// but is used when parsing their formal parameters.
class ModifierContext {
  final Parser parser;
  MemberKind memberKind;

  /// When parsing the formal parameters of any function,
  /// [parameterKind] is non-null.
  final FormalParameterKind parameterKind;

  final bool isVarAllowed;
  TypeContinuation typeContinuation;
  int modifierCount = 0;
  Token varFinalOrConst;

  ModifierContext(this.parser, this.memberKind, this.parameterKind,
      this.isVarAllowed, this.typeContinuation);

  bool get isCovariantFinalAllowed =>
      memberKind != MemberKind.StaticField &&
      memberKind != MemberKind.NonStaticField;

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
    varFinalOrConst ??= next;
    modifierCount++;
    return parser.parseModifier(token);
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
      case MemberKind.Local:
      case MemberKind.StaticField:
      case MemberKind.StaticMethod:
      case MemberKind.TopLevelField:
      case MemberKind.TopLevelMethod:
        parser.reportRecoverableErrorWithToken(
            next, fasta.templateExtraneousModifier);
        return next;

      default:
        modifierCount++;
        return parser.parseModifier(token);
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
        return parser.parseModifier(token);

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
    assert(optional('final', next));
    if (!isVarAllowed && parameterKind == null) {
      parser.reportRecoverableErrorWithToken(
          next, fasta.templateExtraneousModifier);
      return next;
    }
    typeContinuation ??= TypeContinuation.Optional;
    varFinalOrConst ??= next;
    modifierCount++;
    return parser.parseModifier(token);
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
        return parser.parseModifier(token);
      case MemberKind.NonStaticField:
        memberKind = MemberKind.StaticField;
        modifierCount++;
        return parser.parseModifier(token);
      default:
        parser.reportRecoverableErrorWithToken(
            next, fasta.templateExtraneousModifier);
        return next;
    }
  }

  Token parseVar(Token token) {
    Token next = token.next;
    assert(optional('var', next));
    if (!isVarAllowed && parameterKind == null) {
      parser.reportRecoverableErrorWithToken(
          next, fasta.templateExtraneousModifier);
      return next;
    }
    typeContinuation = typeContinuationAfterVar(typeContinuation);
    varFinalOrConst ??= next;
    modifierCount++;
    return parser.parseModifier(token);
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

  Token parseRecovery(Token token,
      {Token covariantToken, Token staticToken, Token varFinalOrConst}) {
    if (covariantToken != null) {
      this.covariantToken = covariantToken;
      ++modifierCount;
    }
    if (staticToken != null) {
      this.staticToken = staticToken;
      ++modifierCount;
    }
    if (varFinalOrConst != null) {
      this.varFinalOrConst = varFinalOrConst;
      ++modifierCount;
      if (optional('var', varFinalOrConst)) {
        varToken = varFinalOrConst;
      } else if (optional('final', varFinalOrConst)) {
        finalToken = varFinalOrConst;
      } else if (optional('const', varFinalOrConst)) {
        constToken = varFinalOrConst;
      } else {
        throw "Internal error: Unexpected varFinalOrConst '$varFinalOrConst'.";
      }
    }

    // Process invalid and out-of-order modifiers
    Token next = token.next;
    while (isModifier(next)) {
      final value = next.stringValue;
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
      next = token.next;
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
    if (next.isModifier) {
      parser.reportRecoverableErrorWithToken(
          next, fasta.templateExtraneousModifier);
    } else {
      // TODO(danrubel): Provide more specific error messages.
      parser.reportRecoverableErrorWithToken(
          next, fasta.templateUnexpectedToken);
    }
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

  ClassMethodModifierContext(this.parser);

  Token parseRecovery(Token token, Token getOrSet, int modifierCount,
      {Token constToken,
      Token covariantToken,
      Token externalToken,
      Token staticToken}) {
    this.getOrSet = getOrSet;
    this.modifierCount = modifierCount;
    this.constToken = constToken;
    this.covariantToken = covariantToken;
    this.externalToken = externalToken;
    this.staticToken = staticToken;

    while (isModifier(token.next)) {
      String value = token.next.stringValue;
      if (identical(value, 'abstract')) {
        token = parseAbstractRecovery(token);
      } else if (identical(value, 'const')) {
        token = parseConstRecovery(token);
      } else if (identical(value, 'covariant')) {
        token = parseCovariantRecovery(token);
      } else if (identical(value, 'external')) {
        token = parseExternalRecovery(token);
      } else if (identical(value, 'static')) {
        token = parseStaticRecovery(token);
      } else if (identical(value, 'var')) {
        token = parseVarRecovery(token);
      } else {
        parser.reportRecoverableErrorWithToken(
            token.next, fasta.templateExtraneousModifier);
        token = token.next;
      }
    }
    return token.next;
  }

  Token parseAbstractRecovery(Token token) {
    token = token.next;
    assert(optional('abstract', token));
    parser.reportRecoverableError(token, fasta.messageAbstractClassMember);
    return token;
  }

  Token parseConstRecovery(Token token) {
    Token next = token.next;
    assert(optional('const', next));
    if (constToken != null) {
      parser.reportRecoverableErrorWithToken(
          next, fasta.templateDuplicatedModifier);
    } else if (getOrSet != null) {
      parser.reportRecoverableErrorWithToken(
          next, fasta.templateExtraneousModifier);
    } else {
      constToken = next;
      parser.parseModifier(token);
      ++modifierCount;
    }
    return next;
  }

  Token parseCovariantRecovery(Token token) {
    Token next = token.next;
    assert(optional('covariant', next));
    if (covariantToken != null) {
      parser.reportRecoverableErrorWithToken(
          next, fasta.templateDuplicatedModifier);
    } else if (getOrSet == null || optional('get', getOrSet)) {
      parser.reportRecoverableError(next, fasta.messageCovariantMember);
    } else if (staticToken != null) {
      parser.reportRecoverableError(next, fasta.messageCovariantAndStatic);
    } else {
      covariantToken = next;
      parser.parseModifier(token);
      ++modifierCount;
    }
    return next;
  }

  Token parseExternalRecovery(Token token) {
    Token next = token.next;
    assert(optional('external', next));
    if (externalToken != null) {
      parser.reportRecoverableErrorWithToken(
          next, fasta.templateDuplicatedModifier);
    } else {
      if (staticToken != null) {
        parser.reportRecoverableError(next, fasta.messageExternalAfterStatic);
        // Fall through to record token.
      } else if (constToken != null) {
        parser.reportRecoverableError(next, fasta.messageExternalAfterConst);
        // Fall through to record token.
      }
      externalToken = next;
      parser.parseModifier(token);
      ++modifierCount;
    }
    return next;
  }

  Token parseStaticRecovery(Token token) {
    Token next = token.next;
    assert(optional('static', next));
    if (staticToken != null) {
      parser.reportRecoverableErrorWithToken(
          next, fasta.templateDuplicatedModifier);
    } else if (covariantToken != null) {
      parser.reportRecoverableError(next, fasta.messageCovariantAndStatic);
    } else {
      if (constToken != null) {
        parser.reportRecoverableError(next, fasta.messageStaticAfterConst);
        // Fall through to record token.
      }
      staticToken = next;
      parser.parseModifier(token);
      ++modifierCount;
    }
    return next;
  }

  Token parseVarRecovery(Token token) {
    token = token.next;
    if (token.next.isIdentifier && optional('(', token.next.next)) {
      parser.reportRecoverableError(token, fasta.messageVarReturnType);
    } else {
      parser.reportRecoverableErrorWithToken(
          token, fasta.templateExtraneousModifier);
    }
    return token;
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
        parseConst(token);
      } else if (identical('external', value)) {
        parseExternal(token);
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
        parseConst(token);
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
    Token next = token.next;
    assert(optional('const', next));
    if (constToken == null) {
      if (factoryKeyword != null) {
        parser.reportRecoverableError(next, fasta.messageConstAfterFactory);
      }
      constToken = next;
      parser.parseModifier(token);
      ++modifierCount;
    } else {
      parser.reportRecoverableErrorWithToken(
          next, fasta.templateDuplicatedModifier);
    }
  }

  void parseExternal(Token token) {
    Token next = token.next;
    assert(optional('external', next));
    if (externalToken == null) {
      if (constToken != null) {
        parser.reportRecoverableError(next, fasta.messageExternalAfterConst);
      } else if (factoryKeyword != null) {
        parser.reportRecoverableError(next, fasta.messageExternalAfterFactory);
      }
      externalToken = next;
      parser.parseModifier(token);
      ++modifierCount;
    } else {
      parser.reportRecoverableErrorWithToken(
          next, fasta.templateDuplicatedModifier);
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
  Token externalToken;

  TopLevelMethodModifierContext(this.parser);

  /// Parse modifiers from the tokens following [token].
  Token parseRecovery(Token token) {
    Token beforeToken = token;
    while (isModifier(token.next)) {
      beforeToken = token;
      token = token.next;
      if (optional('external', token)) {
        if (externalToken == null) {
          externalToken = token;
        } else {
          parser.reportRecoverableErrorWithToken(
              token, fasta.templateDuplicatedModifier);
        }
      } else {
        // TODO(danrubel): report more specific analyzer error codes
        parser.reportRecoverableErrorWithToken(
            token, fasta.templateExtraneousModifier);
      }
    }
    return beforeToken;
  }
}
