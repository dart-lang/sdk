// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../scanner/token.dart' show Token;
import '../messages.dart'
    show
        messageAbstractClassMember,
        messageConstAndCovariant,
        messageConstAndFinal,
        messageConstAndVar,
        messageCovariantAfterFinal,
        messageCovariantAfterVar,
        messageCovariantAndStatic,
        messageFinalAndCovariant,
        messageFinalAndVar,
        messageStaticAfterFinal,
        templateDuplicatedModifier,
        templateExtraneousModifier;
import 'formal_parameter_kind.dart' show FormalParameterKind;
import 'member_kind.dart' show MemberKind;
import 'parser.dart' show Parser;
import 'type_continuation.dart' show TypeContinuation;
import 'util.dart' show optional;

class ModifierContext {
  final Parser parser;
  MemberKind memberKind;
  FormalParameterKind parameterKind;
  bool isVarAllowed;
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
      parser.reportRecoverableErrorWithToken(token, templateExtraneousModifier);
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
            token, templateExtraneousModifier);
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
            token, templateExtraneousModifier);
        return token.next;
    }
  }

  Token parseFinal(Token token) {
    if (!isVarAllowed && parameterKind == null) {
      parser.reportRecoverableErrorWithToken(token, templateExtraneousModifier);
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
      parser.reportRecoverableErrorWithToken(token, templateExtraneousModifier);
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
      parser.reportRecoverableErrorWithToken(token, templateExtraneousModifier);
      return token.next;
    }
  }

  Token parseVar(Token token) {
    if (!isVarAllowed && parameterKind == null) {
      parser.reportRecoverableErrorWithToken(token, templateExtraneousModifier);
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
  final Token recoveryStart;
  Token constToken;
  Token covariantToken;
  Token externalToken;
  Token finalToken;
  Token staticToken;
  Token varToken;

  ModifierRecoveryContext(ModifierContext context, this.recoveryStart)
      : super(
          context.parser,
          context.memberKind,
          context.parameterKind,
          context.isVarAllowed,
          context.typeContinuation,
        ) {
    this.modifierCount = context.modifierCount;
  }

  @override
  Token parseOpt(Token token) {
    // Determine which modifiers have already been parsed
    while (token != recoveryStart) {
      final value = token.stringValue;
      if (identical('const', value)) {
        constToken = token;
      } else if (identical('covariant', value)) {
        covariantToken = token;
      } else if (identical('external', value)) {
        externalToken = token;
      } else if (identical('final', value)) {
        finalToken = token;
      } else if (identical('static', value)) {
        staticToken = token;
      } else if (identical('var', value)) {
        varToken = token;
      }
      token = token.next;
    }

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
      parser.reportRecoverableError(token, messageAbstractClassMember);
      return token.next;
    }
    return parseExtraneousModifier(token);
  }

  @override
  Token parseConst(Token token) {
    if (constToken != null) {
      parser.reportRecoverableErrorWithToken(token, templateDuplicatedModifier);
      return token.next;
    }
    constToken = token;
    if (covariantToken != null) {
      parser.reportRecoverableError(token, messageConstAndCovariant);
      return token.next;
    }
    if (finalToken != null) {
      parser.reportRecoverableError(token, messageConstAndFinal);
      return token.next;
    }
    if (varToken != null) {
      parser.reportRecoverableError(token, messageConstAndVar);
      return token.next;
    }
    return super.parseConst(token);
  }

  @override
  Token parseCovariantOpt(Token token) {
    if (covariantToken != null) {
      parser.reportRecoverableErrorWithToken(token, templateDuplicatedModifier);
      return token.next;
    }
    covariantToken = token;
    if (constToken != null) {
      parser.reportRecoverableError(token, messageConstAndCovariant);
      return token.next;
    }
    if (staticToken != null) {
      parser.reportRecoverableError(token, messageCovariantAndStatic);
      return token.next;
    }
    if (varToken != null) {
      parser.reportRecoverableError(token, messageCovariantAfterVar);
      // fall through to parse modifier
    } else if (finalToken != null) {
      parser.reportRecoverableError(token, messageCovariantAfterFinal);
      // fall through to parse modifier
    }
    return super.parseCovariantOpt(token);
  }

  @override
  Token parseExternalOpt(Token token) {
    if (externalToken != null) {
      parser.reportRecoverableErrorWithToken(token, templateDuplicatedModifier);
      return token.next;
    }
    externalToken = token;
    return super.parseExternalOpt(token);
  }

  @override
  Token parseFinal(Token token) {
    if (finalToken != null) {
      parser.reportRecoverableErrorWithToken(token, templateDuplicatedModifier);
      return token.next;
    }
    finalToken = token;
    if (constToken != null) {
      parser.reportRecoverableError(token, messageConstAndFinal);
      return token.next;
    }
    if (covariantToken != null) {
      parser.reportRecoverableError(token, messageFinalAndCovariant);
      return token.next;
    }
    if (varToken != null) {
      parser.reportRecoverableError(token, messageFinalAndVar);
      return token.next;
    }
    return super.parseFinal(token);
  }

  Token parseExtraneousModifier(Token token) {
    parser.reportRecoverableErrorWithToken(token, templateExtraneousModifier);
    return token.next;
  }

  @override
  Token parseStaticOpt(Token token) {
    if (staticToken != null) {
      parser.reportRecoverableErrorWithToken(token, templateDuplicatedModifier);
      return token.next;
    }
    staticToken = token;
    if (covariantToken != null) {
      parser.reportRecoverableError(token, messageCovariantAndStatic);
      return token.next;
    }
    if (finalToken != null) {
      parser.reportRecoverableError(token, messageStaticAfterFinal);
      // fall through to parse modifier
    }
    return super.parseStaticOpt(token);
  }

  @override
  Token parseVar(Token token) {
    if (varToken != null) {
      parser.reportRecoverableErrorWithToken(token, templateDuplicatedModifier);
      return token.next;
    }
    varToken = token;
    if (constToken != null) {
      parser.reportRecoverableError(token, messageConstAndVar);
      return token.next;
    }
    if (finalToken != null) {
      parser.reportRecoverableError(token, messageFinalAndVar);
      return token.next;
    }
    return super.parseVar(token);
  }
}
