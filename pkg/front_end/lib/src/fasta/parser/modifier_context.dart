// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../scanner/token.dart' show Token;
import '../messages.dart' as fasta;
import 'formal_parameter_kind.dart' show FormalParameterKind;
import 'forwarding_listener.dart' show ForwardingListener;
import 'member_kind.dart' show MemberKind;
import 'parser.dart' show Parser;
import 'type_continuation.dart' show TypeContinuation;
import 'util.dart' show optional;

class ModifierContext {
  final Parser parser;
  MemberKind memberKind;
  final FormalParameterKind parameterKind;
  final bool isVarAllowed;
  TypeContinuation typeContinuation;
  int modifierCount = 0;

  ModifierContext(this.parser, this.memberKind, this.parameterKind,
      this.isVarAllowed, this.typeContinuation);

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

  Token parseOpt(Token token) {
    if (optional('external', token)) {
      token = parseExternalOpt(token);
    }

    if (optional('static', token)) {
      token = parseStaticOpt(token);
    } else if (optional('covariant', token)) {
      token = parseCovariantOpt(token);
      if (optional('final', token)) {
        token = parseFinal(token);
      } else if (optional('var', token)) {
        token = parseVar(token);
      }
      return token;
    }

    if (optional('final', token)) {
      token = parseFinal(token);
    } else if (optional('var', token)) {
      token = parseVar(token);
    } else if (optional('const', token)) {
      token = parseConst(token);
    }
    return token;
  }

  Token parseConst(Token token) {
    assert(optional('const', token));
    if (!isVarAllowed) {
      parser.reportRecoverableErrorWithToken(
          token, fasta.templateExtraneousModifier);
      // TODO(danrubel): investigate why token must be included (fall through)
      // so that tests will pass. I think that it should not be included
      // because the 'const' is invalid in this situation.
      //
      // return token.next;
    }
    typeContinuation ??= TypeContinuation.Optional;
    modifierCount++;
    return parser.parseModifier(token);
  }

  Token parseCovariantOpt(Token token) {
    assert(optional('covariant', token));
    // A built-in identifier can only be a modifier as long as it is
    // followed by another modifier or an identifier.
    // Otherwise, it is the identifier.
    if (!token.next.isKeywordOrIdentifier) {
      return token;
    }
    switch (memberKind) {
      case MemberKind.StaticField:
      case MemberKind.StaticMethod:
      case MemberKind.TopLevelField:
      case MemberKind.TopLevelMethod:
        parser.reportRecoverableErrorWithToken(
            token, fasta.templateExtraneousModifier);
        return token.next;

      default:
        modifierCount++;
        return parser.parseModifier(token);
    }
  }

  Token parseExternalOpt(Token token) {
    assert(optional('external', token));
    // A built-in identifier can only be a modifier as long as it is
    // followed by another modifier or an identifier.
    // Otherwise, it is the identifier.
    if (!token.next.isKeywordOrIdentifier) {
      return token;
    }
    switch (memberKind) {
      case MemberKind.Factory:
      case MemberKind.NonStaticMethod:
      case MemberKind.StaticMethod:
      case MemberKind.TopLevelMethod:
        modifierCount++;
        return parser.parseModifier(token);

      default:
        parser.reportRecoverableErrorWithToken(
            token, fasta.templateExtraneousModifier);
        return token.next;
    }
  }

  Token parseFinal(Token token) {
    if (!isVarAllowed && parameterKind == null) {
      parser.reportRecoverableErrorWithToken(
          token, fasta.templateExtraneousModifier);
      return token.next;
    }
    typeContinuation ??= TypeContinuation.Optional;
    modifierCount++;
    return parser.parseModifier(token);
  }

  Token parseStaticOpt(Token token) {
    assert(optional('static', token));
    // A built-in identifier can only be a modifier as long as it is
    // followed by another modifier or an identifier.
    // Otherwise, it is the identifier.
    if (!token.next.isKeywordOrIdentifier) {
      return token;
    }
    if (parameterKind != null) {
      parser.reportRecoverableErrorWithToken(
          token, fasta.templateExtraneousModifier);
      return token.next;
    } else if (memberKind == MemberKind.NonStaticMethod) {
      memberKind = MemberKind.StaticMethod;
      modifierCount++;
      return parser.parseModifier(token);
    } else if (memberKind == MemberKind.NonStaticField) {
      memberKind = MemberKind.StaticField;
      modifierCount++;
      return parser.parseModifier(token);
    } else {
      parser.reportRecoverableErrorWithToken(
          token, fasta.templateExtraneousModifier);
      return token.next;
    }
  }

  Token parseVar(Token token) {
    if (!isVarAllowed && parameterKind == null) {
      parser.reportRecoverableErrorWithToken(
          token, fasta.templateExtraneousModifier);
      return token.next;
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

  @override
  Token parseOpt(Token token) {
    // Reparse to determine which modifiers have already been parsed
    // but intercept the events so they are not sent to the primary listener.
    final primaryListener = parser.listener;
    parser.listener = new ForwardingListener();
    token = super.parseOpt(token);
    parser.listener = primaryListener;

    // Process invalid and out-of-order modifiers
    while (isModifier(token)) {
      final value = token.stringValue;
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
    assert(optional('abstract', token));
    if (memberKind == MemberKind.NonStaticField ||
        memberKind == MemberKind.NonStaticMethod ||
        memberKind == MemberKind.StaticField ||
        memberKind == MemberKind.StaticMethod) {
      parser.reportRecoverableError(token, fasta.messageAbstractClassMember);
      return token.next;
    }
    return parseExtraneousModifier(token);
  }

  @override
  Token parseConst(Token token) {
    if (constToken != null) {
      parser.reportRecoverableErrorWithToken(
          token, fasta.templateDuplicatedModifier);
      return token.next;
    }
    constToken = token;
    if (covariantToken != null) {
      parser.reportRecoverableError(token, fasta.messageConstAndCovariant);
      return token.next;
    }
    if (finalToken != null) {
      parser.reportRecoverableError(token, fasta.messageConstAndFinal);
      return token.next;
    }
    if (varToken != null) {
      parser.reportRecoverableError(token, fasta.messageConstAndVar);
      return token.next;
    }
    return super.parseConst(token);
  }

  @override
  Token parseCovariantOpt(Token token) {
    if (covariantToken != null) {
      parser.reportRecoverableErrorWithToken(
          token, fasta.templateDuplicatedModifier);
      return token.next;
    }
    covariantToken = token;
    if (constToken != null) {
      parser.reportRecoverableError(token, fasta.messageConstAndCovariant);
      return token.next;
    }
    if (staticToken != null) {
      parser.reportRecoverableError(token, fasta.messageCovariantAndStatic);
      return token.next;
    }
    if (varToken != null) {
      parser.reportRecoverableError(token, fasta.messageCovariantAfterVar);
      // fall through to parse modifier
    } else if (finalToken != null) {
      parser.reportRecoverableError(token, fasta.messageCovariantAfterFinal);
      // fall through to parse modifier
    }
    return super.parseCovariantOpt(token);
  }

  @override
  Token parseExternalOpt(Token token) {
    if (externalToken != null) {
      parser.reportRecoverableErrorWithToken(
          token, fasta.templateDuplicatedModifier);
      return token.next;
    }
    externalToken = token;
    return super.parseExternalOpt(token);
  }

  @override
  Token parseFinal(Token token) {
    if (finalToken != null) {
      parser.reportRecoverableErrorWithToken(
          token, fasta.templateDuplicatedModifier);
      return token.next;
    }
    finalToken = token;
    if (constToken != null) {
      parser.reportRecoverableError(token, fasta.messageConstAndFinal);
      return token.next;
    }
    if (covariantToken != null) {
      parser.reportRecoverableError(token, fasta.messageFinalAndCovariant);
      return token.next;
    }
    if (varToken != null) {
      parser.reportRecoverableError(token, fasta.messageFinalAndVar);
      return token.next;
    }
    return super.parseFinal(token);
  }

  Token parseExtraneousModifier(Token token) {
    parser.reportRecoverableErrorWithToken(
        token, fasta.templateExtraneousModifier);
    return token.next;
  }

  @override
  Token parseStaticOpt(Token token) {
    if (staticToken != null) {
      parser.reportRecoverableErrorWithToken(
          token, fasta.templateDuplicatedModifier);
      return token.next;
    }
    staticToken = token;
    if (covariantToken != null) {
      parser.reportRecoverableError(token, fasta.messageCovariantAndStatic);
      return token.next;
    }
    if (finalToken != null) {
      parser.reportRecoverableError(token, fasta.messageStaticAfterFinal);
      // fall through to parse modifier
    }
    return super.parseStaticOpt(token);
  }

  @override
  Token parseVar(Token token) {
    if (varToken != null) {
      parser.reportRecoverableErrorWithToken(
          token, fasta.templateDuplicatedModifier);
      return token.next;
    }
    varToken = token;
    if (constToken != null) {
      parser.reportRecoverableError(token, fasta.messageConstAndVar);
      return token.next;
    }
    if (finalToken != null) {
      parser.reportRecoverableError(token, fasta.messageFinalAndVar);
      return token.next;
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
        parser.reportRecoverableError(token, fasta.messageAbstractClassMember);
      } else if (identical(value, 'class')) {
        parser.reportRecoverableError(token, fasta.messageClassInClass);
      } else if (identical(value, 'enum')) {
        parser.reportRecoverableError(token, fasta.messageEnumInClass);
      } else if (identical(value, 'const')) {
        parseConstRecovery(token);
      } else if (identical(value, 'covariant')) {
        parseCovariantRecovery(token);
      } else if (identical(value, 'external')) {
        parseExternalRecovery(token);
      } else if (identical(value, 'static')) {
        parseStaticRecovery(token);
      } else if (identical(value, 'typedef')) {
        parser.reportRecoverableError(token, fasta.messageTypedefInClass);
      } else if (identical(value, 'var')) {
        parseVarRecovery(token);
      } else if (token.isModifier) {
        parser.reportRecoverableErrorWithToken(
            token, fasta.templateExtraneousModifier);
      } else {
        parser.reportRecoverableErrorWithToken(
            token, fasta.templateUnexpectedToken);
        // We found something that doesn't look like a modifier,
        // so skip the rest of the tokens.
        token = afterModifiers;
        break;
      }
      token = token.next;
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

class TopLevelMethodModifierContext {
  final Parser parser;
  Token externalToken;

  /// If recovery finds the beginning of a new declaration,
  /// then this is set to the last token in the prior declaration.
  Token endInvalidTopLevelDeclarationToken;

  TopLevelMethodModifierContext(this.parser);

  /// Parse modifiers from [token] up to but not including [afterModifiers].
  /// If a new declaration start is found in the sequence of tokens,
  /// then set [endInvalidTopLevelDeclarationToken] to be the last token
  /// in the current declaration
  /// and return the first token in the new declaration.
  Token parseRecovery(Token token, Token afterModifiers) {
    while (token != afterModifiers) {
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
        if (token.next.isTopLevelKeyword) {
          endInvalidTopLevelDeclarationToken = token;
          return token.next;
        }
      } else if (optional('factory', token)) {
        parser.reportRecoverableError(
            token, fasta.messageFactoryTopLevelDeclaration);
        // Indicate to the caller that the next token should be
        // parsed as a new top level declaration.
        endInvalidTopLevelDeclarationToken = token;
        return token.next;
      } else {
        // TODO(danrubel): report more specific analyzer error codes
        parser.reportRecoverableErrorWithToken(
            token, fasta.templateExtraneousModifier);
      }
      token = token.next;
    }
    return token;
  }
}
