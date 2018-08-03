// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../scanner/token.dart' show Token;
import '../messages.dart' as fasta;
import 'member_kind.dart' show MemberKind;
import 'parser.dart' show Parser;
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

/// This class is used to parse modifiers in most locations where modifiers
/// can occur, but does not call handleModifier or handleModifiers.
class ModifierRecoveryContext {
  final Parser parser;
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

  ModifierRecoveryContext(this.parser);

  /// Parse modifiers for class methods and fields.
  Token parseClassMemberModifiers(Token token,
      {Token externalToken,
      Token staticToken,
      Token covariantToken,
      Token varFinalOrConst}) {
    token = parseModifiers(token,
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

  /// Parse modifiers for formal parameters.
  Token parseFormalParameterModifiers(Token token, MemberKind memberKind,
      {Token covariantToken, Token varFinalOrConst}) {
    token = parseModifiers(token,
        covariantToken: covariantToken, varFinalOrConst: varFinalOrConst);

    if (memberKind == MemberKind.StaticMethod ||
        memberKind == MemberKind.TopLevelMethod) {
      reportExtraneousModifier(this.covariantToken);
      this.covariantToken = null;
    }
    if (constToken != null) {
      reportExtraneousModifier(constToken);
      varFinalOrConst = null;
    } else if (memberKind == MemberKind.GeneralizedFunctionType) {
      if (varFinalOrConst != null) {
        parser.reportRecoverableError(
            varFinalOrConst, fasta.messageFunctionTypedParameterVar);
        varFinalOrConst = null;
        finalToken = null;
        varToken = null;
      }
    }
    reportExtraneousModifier(abstractToken);
    reportExtraneousModifier(externalToken);
    reportExtraneousModifier(staticToken);
    return token;
  }

  /// Parse modifiers after the `factory` token.
  Token parseModifiersAfterFactory(Token token,
      {Token externalToken, Token staticOrCovariant, Token varFinalOrConst}) {
    afterFactory = true;
    token = parseModifiers(token,
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
  Token parseTopLevelModifiers(Token token,
      {Token externalToken, Token varFinalOrConst}) {
    token = parseModifiers(token,
        externalToken: externalToken, varFinalOrConst: varFinalOrConst);

    reportExtraneousModifier(abstractToken);
    reportExtraneousModifier(covariantToken);
    reportExtraneousModifier(staticToken);
    return token;
  }

  /// Parse modifiers for variable declarations.
  Token parseVariableDeclarationModifiers(Token token,
      {Token varFinalOrConst}) {
    token = parseModifiers(token, varFinalOrConst: varFinalOrConst);

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
  Token parseModifiers(Token token,
      {Token externalToken,
      Token staticToken,
      Token staticOrCovariant,
      Token covariantToken,
      Token varFinalOrConst}) {
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
