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

/// This class parses modifiers in recovery situations,
/// but does not call handleModifier or handleModifiers.
class ModifierRecoveryContext2 {
  final Parser parser;
  TypeContinuation typeContinuation;
  Token abstractToken;
  Token constToken;
  Token covariantToken;
  Token externalToken;
  Token finalToken;
  Token staticToken;
  Token varFinalOrConst;
  Token varToken;

  // Set `true` when parsing modifiers after the `factory` token.
  bool afterFactory = false;

  // TODO(danrubel): Replace [ModifierRecoveryContext] and [ModifierContext]
  // with this class.

  ModifierRecoveryContext2(this.parser);

  /// Parse modifiers for class methods and fields.
  Token parseClassMemberModifiers(
      Token token, TypeContinuation typeContinuation,
      {Token externalToken,
      Token staticToken,
      Token covariantToken,
      Token varFinalOrConst}) {
    token = parseModifiers(token, typeContinuation,
        externalToken: externalToken,
        staticToken: staticToken,
        covariantToken: covariantToken,
        varFinalOrConst: varFinalOrConst);

    if (abstractToken != null) {
      parser.reportRecoverableError(
          abstractToken, fasta.messageAbstractClassMember);
    }
    return token;
  }

  /// Parse modifiers after the `factory` token.
  Token parseModifiersAfterFactory(Token token,
      {Token externalToken, Token staticOrCovariant, Token varFinalOrConst}) {
    afterFactory = true;
    token = parseModifiers(token, null,
        externalToken: externalToken,
        staticOrCovariant: staticOrCovariant,
        varFinalOrConst: varFinalOrConst);

    if (abstractToken != null) {
      parser.reportRecoverableError(
          abstractToken, fasta.messageAbstractClassMember);
    }
    return token;
  }

  /// Parse modifiers for top level functions and fields.
  Token parseTopLevelModifiers(Token token, TypeContinuation typeContinuation,
      {Token externalToken, Token varFinalOrConst}) {
    token = parseModifiers(token, typeContinuation,
        externalToken: externalToken, varFinalOrConst: varFinalOrConst);

    reportExtraneousModifier(abstractToken);
    reportExtraneousModifier(covariantToken);
    reportExtraneousModifier(staticToken);
    return token;
  }

  /// Parse modifiers for variable declarations.
  Token parseVariableDeclarationModifiers(Token token,
      {Token varFinalOrConst}) {
    token = parseModifiers(token, null, varFinalOrConst: varFinalOrConst);

    reportExtraneousModifier(abstractToken);
    reportExtraneousModifier(covariantToken);
    reportExtraneousModifier(externalToken);
    reportExtraneousModifier(staticToken);
    return token;
  }

  /// Parse modifiers during recovery when modifiers are out of order
  /// or invalid. Typically clients call methods like
  /// [parseClassMemberModifiers] which in turn calls this method,
  /// rather than calling this method directly.
  ///
  /// The various modifier token parameters represent tokens of modifiers
  /// that have already been parsed prior to recovery. The [staticOrCovariant]
  /// parameter is for convenience if caller has a token that may be either
  /// `static` or `covariant`. The first non-null parameter of
  /// [staticOrCovariant], [staticToken], or [covariantToken] will be used,
  /// in that order, and the others ignored.
  Token parseModifiers(Token token, TypeContinuation typeContinuation,
      {Token externalToken,
      Token staticToken,
      Token staticOrCovariant,
      Token covariantToken,
      Token varFinalOrConst}) {
    this.typeContinuation = typeContinuation;
    if (externalToken != null) {
      this.externalToken = externalToken;
    }
    if (staticOrCovariant != null) {
      if (optional('static', staticOrCovariant)) {
        this.staticToken = staticOrCovariant;
      } else if (optional('covariant', staticOrCovariant)) {
        this.covariantToken = staticOrCovariant;
      } else {
        throw "Internal error: "
            "Unexpected staticOrCovariant '$staticOrCovariant'.";
      }
    } else if (staticToken != null) {
      this.staticToken = staticToken;
    } else if (covariantToken != null) {
      this.covariantToken = covariantToken;
    }
    if (varFinalOrConst != null) {
      this.varFinalOrConst = varFinalOrConst;
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
    while (true) {
      final value = next.stringValue;
      if (isModifier(next)) {
        if (identical('abstract', value)) {
          token = parseAbstract(token);
        } else if (identical('const', value)) {
          token = parseConst(token);
        } else if (identical('covariant', value)) {
          token = parseCovariant(token);
        } else if (identical('external', value)) {
          token = parseExternal(token);
        } else if (identical('final', value)) {
          token = parseFinal(token);
        } else if (identical('static', value)) {
          token = parseStatic(token);
        } else if (identical('var', value)) {
          token = parseVar(token);
        } else {
          throw 'Internal Error: Unhandled modifier: $value';
        }
      } else if (afterFactory && identical('factory', value)) {
        parser.reportRecoverableErrorWithToken(
            next, fasta.templateDuplicatedModifier);
        token = next;
      } else {
        break;
      }
      next = token.next;
    }

    return token;
  }

  Token parseAbstract(Token token) {
    Token next = token.next;
    assert(optional('abstract', next));
    if (abstractToken == null) {
      abstractToken = next;
      return next;
    }

    // Recovery
    parser.reportRecoverableErrorWithToken(
        next, fasta.templateDuplicatedModifier);
    return next;
  }

  Token parseConst(Token token) {
    Token next = token.next;
    assert(optional('const', next));
    if (varFinalOrConst == null && covariantToken == null) {
      typeContinuation ??= TypeContinuation.Optional;
      varFinalOrConst = constToken = next;

      if (afterFactory) {
        parser.reportRecoverableError(next, fasta.messageConstAfterFactory);
      }
      return next;
    }

    // Recovery
    if (constToken != null) {
      parser.reportRecoverableErrorWithToken(
          next, fasta.templateDuplicatedModifier);
    } else if (covariantToken != null) {
      parser.reportRecoverableError(next, fasta.messageConstAndCovariant);
    } else if (finalToken != null) {
      parser.reportRecoverableError(next, fasta.messageConstAndFinal);
    } else if (varToken != null) {
      parser.reportRecoverableError(next, fasta.messageConstAndVar);
    } else {
      throw 'Internal Error: Unexpected varFinalOrConst: $varFinalOrConst';
    }
    return next;
  }

  Token parseCovariant(Token token) {
    Token next = token.next;
    assert(optional('covariant', next));
    if (constToken == null &&
        covariantToken == null &&
        staticToken == null &&
        !afterFactory) {
      covariantToken = next;

      if (varToken != null) {
        parser.reportRecoverableError(next, fasta.messageCovariantAfterVar);
      } else if (finalToken != null) {
        parser.reportRecoverableError(next, fasta.messageCovariantAfterFinal);
      }
      return next;
    }

    // Recovery
    if (covariantToken != null) {
      parser.reportRecoverableErrorWithToken(
          next, fasta.templateDuplicatedModifier);
    } else if (afterFactory) {
      reportExtraneousModifier(next);
    } else if (constToken != null) {
      parser.reportRecoverableError(next, fasta.messageConstAndCovariant);
    } else if (staticToken != null) {
      parser.reportRecoverableError(next, fasta.messageCovariantAndStatic);
    } else {
      throw 'Internal Error: Unhandled recovery: $next';
    }
    return next;
  }

  Token parseExternal(Token token) {
    Token next = token.next;
    assert(optional('external', next));
    if (externalToken == null) {
      externalToken = next;

      if (afterFactory) {
        parser.reportRecoverableError(next, fasta.messageExternalAfterFactory);
      } else if (constToken != null) {
        parser.reportRecoverableError(next, fasta.messageExternalAfterConst);
      } else if (staticToken != null) {
        parser.reportRecoverableError(next, fasta.messageExternalAfterStatic);
      }
      return next;
    }

    // Recovery
    parser.reportRecoverableErrorWithToken(
        next, fasta.templateDuplicatedModifier);
    return next;
  }

  Token parseFinal(Token token) {
    Token next = token.next;
    assert(optional('final', next));
    if (varFinalOrConst == null && !afterFactory) {
      typeContinuation ??= TypeContinuation.Optional;
      varFinalOrConst = finalToken = next;
      return next;
    }

    // Recovery
    if (finalToken != null) {
      parser.reportRecoverableErrorWithToken(
          next, fasta.templateDuplicatedModifier);
    } else if (afterFactory) {
      reportExtraneousModifier(next);
    } else if (constToken != null) {
      parser.reportRecoverableError(next, fasta.messageConstAndFinal);
    } else if (varToken != null) {
      parser.reportRecoverableError(next, fasta.messageFinalAndVar);
    } else {
      throw 'Internal Error: Unexpected varFinalOrConst: $varFinalOrConst';
    }
    return next;
  }

  Token parseStatic(Token token) {
    Token next = token.next;
    assert(optional('static', next));
    if (covariantToken == null && staticToken == null && !afterFactory) {
      staticToken = next;

      if (constToken != null) {
        parser.reportRecoverableError(next, fasta.messageStaticAfterConst);
      } else if (finalToken != null) {
        parser.reportRecoverableError(next, fasta.messageStaticAfterFinal);
      } else if (varToken != null) {
        parser.reportRecoverableError(next, fasta.messageStaticAfterVar);
      }
      return next;
    }

    // Recovery
    if (covariantToken != null) {
      parser.reportRecoverableError(next, fasta.messageCovariantAndStatic);
    } else if (staticToken != null) {
      parser.reportRecoverableErrorWithToken(
          next, fasta.templateDuplicatedModifier);
    } else if (afterFactory) {
      reportExtraneousModifier(next);
    } else {
      throw 'Internal Error: Unhandled recovery: $next';
    }
    return next;
  }

  Token parseVar(Token token) {
    Token next = token.next;
    assert(optional('var', next));
    if (varFinalOrConst == null && !afterFactory) {
      typeContinuation = typeContinuationAfterVar(typeContinuation);
      varFinalOrConst = varToken = next;
      return next;
    }

    // Recovery
    if (varToken != null) {
      parser.reportRecoverableErrorWithToken(
          next, fasta.templateDuplicatedModifier);
    } else if (afterFactory) {
      reportExtraneousModifier(next);
    } else if (constToken != null) {
      parser.reportRecoverableError(next, fasta.messageConstAndVar);
    } else if (finalToken != null) {
      parser.reportRecoverableError(next, fasta.messageFinalAndVar);
    } else {
      throw 'Internal Error: Unexpected varFinalOrConst: $varFinalOrConst';
    }
    return next;
  }

  void reportExtraneousModifier(Token token) {
    if (token != null) {
      parser.reportRecoverableErrorWithToken(
          token, fasta.templateExtraneousModifier);
    }
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
