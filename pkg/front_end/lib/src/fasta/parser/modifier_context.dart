// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../scanner/token.dart' show Keyword, Token;
import '../messages.dart' as fasta;
import 'formal_parameter_kind.dart';
import 'member_kind.dart' show MemberKind;
import 'parser.dart' show Parser;
import 'util.dart' show optional;

bool isModifier(Token token) {
  if (!token.isModifier) {
    return false;
  } else if (token.type.isBuiltIn) {
    // A built-in keyword can only be a modifier as long as it is
    // followed by another keyword or an identifier. Otherwise, it is the
    // identifier.
    //
    // For example, `external` is a modifier in this declaration:
    //   external Foo foo();
    // but is the identifier in this declaration
    //   external() => true;
    // and in
    //   for (final external in list) { }
    Token next = token.next;
    Keyword keyword = next.keyword;
    if (keyword == null && !next.isIdentifier || keyword == Keyword.IN) {
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
  Token lateToken;
  Token requiredToken;
  Token staticToken;
  Token varToken;

  // Set `true` when parsing modifiers after the `factory` token.
  bool afterFactory = false;

  // TODO(danrubel): Replace [ModifierRecoveryContext] and [ModifierContext]
  // with this class.

  ModifierRecoveryContext(this.parser);

  set staticOrCovariant(Token staticOrCovariant) {
    if (staticOrCovariant == null) {
      covariantToken = null;
      staticToken = null;
    } else if (optional('covariant', staticOrCovariant)) {
      covariantToken = staticOrCovariant;
      staticToken = null;
    } else if (optional('static', staticOrCovariant)) {
      covariantToken = null;
      staticToken = staticOrCovariant;
    } else {
      throw "Internal error: "
          "Unexpected staticOrCovariant '$staticOrCovariant'.";
    }
  }

  Token get varFinalOrConst => varToken ?? finalToken ?? constToken;

  set varFinalOrConst(Token varFinalOrConst) {
    if (varFinalOrConst == null) {
      varToken = null;
      finalToken = null;
      constToken = null;
    } else if (optional('var', varFinalOrConst)) {
      varToken = varFinalOrConst;
      finalToken = null;
      constToken = null;
    } else if (optional('final', varFinalOrConst)) {
      varToken = null;
      finalToken = varFinalOrConst;
      constToken = null;
    } else if (optional('const', varFinalOrConst)) {
      varToken = null;
      finalToken = null;
      constToken = varFinalOrConst;
    } else {
      throw "Internal error: Unexpected varFinalOrConst '$varFinalOrConst'.";
    }
  }

  /// Parse modifiers for class methods and fields.
  Token parseClassMemberModifiers(Token token) {
    token = parseModifiers(token);
    if (abstractToken != null) {
      parser.reportRecoverableError(
          abstractToken, fasta.messageAbstractClassMember);
    }
    reportExtraneousModifier(requiredToken);
    return token;
  }

  /// Parse modifiers for formal parameters.
  Token parseFormalParameterModifiers(
      Token token, FormalParameterKind parameterKind, MemberKind memberKind) {
    token = parseModifiers(token);

    if (parameterKind != FormalParameterKind.optionalNamed) {
      reportExtraneousModifier(requiredToken);
    }
    if (memberKind == MemberKind.StaticMethod ||
        memberKind == MemberKind.TopLevelMethod) {
      reportExtraneousModifier(this.covariantToken);
      this.covariantToken = null;
    }
    if (constToken != null) {
      reportExtraneousModifier(constToken);
    } else if (memberKind == MemberKind.GeneralizedFunctionType) {
      if (varFinalOrConst != null) {
        parser.reportRecoverableError(
            varFinalOrConst, fasta.messageFunctionTypedParameterVar);
      }
    }
    reportExtraneousModifier(abstractToken);
    reportExtraneousModifier(externalToken);
    reportExtraneousModifier(lateToken);
    reportExtraneousModifier(staticToken);
    return token;
  }

  /// Parse modifiers after the `factory` token.
  Token parseModifiersAfterFactory(Token token) {
    afterFactory = true;
    token = parseModifiers(token);
    if (abstractToken != null) {
      parser.reportRecoverableError(
          abstractToken, fasta.messageAbstractClassMember);
    }
    reportExtraneousModifier(lateToken);
    reportExtraneousModifier(requiredToken);
    return token;
  }

  /// Parse modifiers for top level functions and fields.
  Token parseTopLevelModifiers(Token token) {
    token = parseModifiers(token);
    reportExtraneousModifier(abstractToken);
    reportExtraneousModifier(covariantToken);
    reportExtraneousModifier(requiredToken);
    reportExtraneousModifier(staticToken);
    return token;
  }

  /// Parse modifiers for variable declarations.
  Token parseVariableDeclarationModifiers(Token token) {
    token = parseModifiers(token);
    reportExtraneousModifier(abstractToken);
    reportExtraneousModifier(covariantToken);
    reportExtraneousModifier(externalToken);
    reportExtraneousModifier(requiredToken);
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
  Token parseModifiers(Token token) {
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
        } else if (identical('late', value)) {
          token = parseLate(token);
        } else if (identical('required', value)) {
          token = parseRequired(token);
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
      constToken = next;

      if (afterFactory) {
        reportModifierOutOfOrder(next, 'factory');
      } else if (lateToken != null) {
        reportConflictingModifiers(next, lateToken);
      }
      return next;
    }

    // Recovery
    if (constToken != null) {
      parser.reportRecoverableErrorWithToken(
          next, fasta.templateDuplicatedModifier);
    } else if (covariantToken != null) {
      reportConflictingModifiers(next, covariantToken);
    } else if (finalToken != null) {
      parser.reportRecoverableError(next, fasta.messageConstAndFinal);
    } else if (varToken != null) {
      reportConflictingModifiers(next, varToken);
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
        reportModifierOutOfOrder(next, finalToken.lexeme);
      } else if (lateToken != null) {
        reportModifierOutOfOrder(next, lateToken.lexeme);
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
      reportConflictingModifiers(next, constToken);
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
      } else if (lateToken != null) {
        reportModifierOutOfOrder(next, lateToken.lexeme);
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
      finalToken = next;
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
    } else if (lateToken != null) {
      reportModifierOutOfOrder(next, lateToken.lexeme);
    } else {
      throw 'Internal Error: Unexpected varFinalOrConst: $varFinalOrConst';
    }
    return next;
  }

  Token parseLate(Token token) {
    Token next = token.next;
    assert(optional('late', next));
    if (lateToken == null) {
      lateToken = next;

      if (constToken != null) {
        reportConflictingModifiers(next, constToken);
      } else if (varToken != null) {
        reportConflictingModifiers(next, varToken);
      } else if (finalToken != null) {
        reportModifierOutOfOrder(next, finalToken.lexeme);
      }
      return next;
    }

    // Recovery
    parser.reportRecoverableErrorWithToken(
        next, fasta.templateDuplicatedModifier);
    return next;
  }

  Token parseRequired(Token token) {
    Token next = token.next;
    assert(optional('required', next));
    if (requiredToken == null) {
      requiredToken = next;

      if (constToken != null) {
        reportModifierOutOfOrder(requiredToken, constToken.lexeme);
      } else if (covariantToken != null) {
        reportModifierOutOfOrder(requiredToken, covariantToken.lexeme);
      } else if (finalToken != null) {
        reportModifierOutOfOrder(requiredToken, finalToken.lexeme);
      } else if (varToken != null) {
        reportModifierOutOfOrder(requiredToken, varToken.lexeme);
      }
      return next;
    }

    // Recovery
    parser.reportRecoverableErrorWithToken(
        next, fasta.templateDuplicatedModifier);
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
      } else if (lateToken != null) {
        reportModifierOutOfOrder(next, lateToken.lexeme);
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
      varToken = next;

      if (lateToken != null) {
        reportConflictingModifiers(next, lateToken);
      }
      return next;
    }

    // Recovery
    if (varToken != null) {
      parser.reportRecoverableErrorWithToken(
          next, fasta.templateDuplicatedModifier);
    } else if (afterFactory) {
      reportExtraneousModifier(next);
    } else if (constToken != null) {
      reportConflictingModifiers(next, constToken);
    } else if (finalToken != null) {
      parser.reportRecoverableError(next, fasta.messageFinalAndVar);
    } else {
      throw 'Internal Error: Unexpected varFinalOrConst: $varFinalOrConst';
    }
    return next;
  }

  void reportConflictingModifiers(Token modifier, Token earlierModifier) {
    parser.reportRecoverableError(
        modifier,
        fasta.templateConflictingModifiers
            .withArguments(modifier.lexeme, earlierModifier.lexeme));
  }

  void reportExtraneousModifier(Token modifier) {
    if (modifier != null) {
      parser.reportRecoverableErrorWithToken(
          modifier, fasta.templateExtraneousModifier);
    }
  }

  void reportModifierOutOfOrder(Token modifier, String beforeModifier) {
    parser.reportRecoverableError(
        modifier,
        fasta.templateModifierOutOfOrder
            .withArguments(modifier.lexeme, beforeModifier));
  }
}
