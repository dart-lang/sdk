// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.parser.parser;

import '../fasta_codes.dart'
    show
        FastaCode,
        FastaMessage,
        codeAbstractNotSync,
        codeAsciiControlCharacter,
        codeAssertAsExpression,
        codeAssertExtraneousArgument,
        codeAsyncAsIdentifier,
        codeAwaitAsIdentifier,
        codeAwaitForNotAsync,
        codeAwaitNotAsync,
        codeBuiltInIdentifierAsType,
        codeBuiltInIdentifierInDeclaration,
        codeCatchSyntax,
        codeConstFieldWithoutInitializer,
        codeEmptyNamedParameterList,
        codeEmptyOptionalParameterList,
        codeEncoding,
        codeExpectedBlockToSkip,
        codeExpectedBody,
        codeExpectedButGot,
        codeExpectedClassBody,
        codeExpectedClassBodyToSkip,
        codeExpectedDeclaration,
        codeExpectedExpression,
        codeExpectedFunctionBody,
        codeExpectedIdentifier,
        codeExpectedOpenParens,
        codeExpectedString,
        codeExtraneousModifier,
        codeFactoryNotSync,
        codeFinalFieldWithoutInitializer,
        codeFunctionTypeDefaultValue,
        codeGeneratorReturnsValue,
        codeGetterWithFormals,
        codeInvalidAwaitFor,
        codeInvalidInlineFunctionType,
        codeInvalidSyncModifier,
        codeInvalidVoid,
        codeMetadataTypeArguments,
        codeNoFormals,
        codeNonAsciiIdentifier,
        codeNonAsciiWhitespace,
        codeOnlyTry,
        codePositionalParameterWithEquals,
        codePrivateNamedParameter,
        codeRequiredParameterWithDefault,
        codeSetterNotSync,
        codeStackOverflow,
        codeSuperNullAware,
        codeTypeAfterVar,
        codeTypeRequired,
        codeUnexpectedToken,
        codeUnmatchedToken,
        codeUnspecified,
        codeUnsupportedPrefixPlus,
        codeUnterminatedString,
        codeYieldAsIdentifier,
        codeYieldNotGenerator;

import '../scanner.dart' show ErrorToken, Token;

import '../scanner/recover.dart' show closeBraceFor, skipToEof;

import '../../scanner/token.dart'
    show
        ASSIGNMENT_PRECEDENCE,
        BeginToken,
        CASCADE_PRECEDENCE,
        EQUALITY_PRECEDENCE,
        POSTFIX_PRECEDENCE,
        RELATIONAL_PRECEDENCE,
        TokenType;

import '../scanner/token.dart' show isUserDefinableOperator;

import '../scanner/token_constants.dart'
    show
        COMMA_TOKEN,
        DOUBLE_TOKEN,
        EOF_TOKEN,
        EQ_TOKEN,
        FUNCTION_TOKEN,
        GT_TOKEN,
        GT_GT_TOKEN,
        HASH_TOKEN,
        HEXADECIMAL_TOKEN,
        IDENTIFIER_TOKEN,
        INT_TOKEN,
        KEYWORD_TOKEN,
        LT_TOKEN,
        OPEN_CURLY_BRACKET_TOKEN,
        OPEN_PAREN_TOKEN,
        OPEN_SQUARE_BRACKET_TOKEN,
        PERIOD_TOKEN,
        SEMICOLON_TOKEN,
        STRING_INTERPOLATION_IDENTIFIER_TOKEN,
        STRING_INTERPOLATION_TOKEN,
        STRING_TOKEN;

import '../scanner/characters.dart' show $CLOSE_CURLY_BRACKET;

import '../util/link.dart' show Link;

import 'async_modifier.dart' show AsyncModifier;

import 'listener.dart' show Listener;

import 'identifier_context.dart' show IdentifierContext;

/// Returns true if [token] is the symbol or keyword [value].
bool optional(String value, Token token) {
  return identical(value, token.stringValue);
}

class FormalParameterType {
  final String type;
  const FormalParameterType(this.type);
  bool get isRequired => this == REQUIRED;
  bool get isPositional => this == POSITIONAL;
  bool get isNamed => this == NAMED;
  static final REQUIRED = const FormalParameterType('required');
  static final POSITIONAL = const FormalParameterType('positional');
  static final NAMED = const FormalParameterType('named');
}

enum MemberKind {
  /// A catch block, not a real member.
  Catch,

  /// A factory
  Factory,

  /// Old-style typedef.
  FunctionTypeAlias,

  /// Old-style function-typed parameter, not a real member.
  FunctionTypedParameter,

  /// A generalized function type, not a real member.
  GeneralizedFunctionType,

  /// A local function.
  Local,

  /// A non-static method in a class (including constructors).
  NonStaticMethod,

  /// A static method in a class.
  StaticMethod,

  /// A top-level method.
  TopLevelMethod,

  /// An instance field in a class.
  NonStaticField,

  /// A static field in a class.
  StaticField,

  /// A top-level field.
  TopLevelField,
}

/// Syntactic forms of `assert`.
///
/// An assertion can legally occur as a statement. However, assertions are also
/// experimentally allowed in initializers. For improved error recovery, we
/// also attempt to parse asserts as expressions.
enum Assert {
  Expression,
  Initializer,
  Statement,
}

/// An event generating parser of Dart programs. This parser expects all tokens
/// in a linked list (aka a token stream).
///
/// The class [Scanner] is used to generate a token stream. See the file
/// [scanner.dart](../scanner.dart).
///
/// Subclasses of the class [Listener] are used to listen to events.
///
/// Most methods of this class belong in one of three major categories: parse
/// methods, peek methods, and skip methods. Parse methods all have the prefix
/// `parse`, peek methods all have the prefix `peek`, and skip methods all have
/// the prefix `skip`.
///
/// Parse methods generate events (by calling methods on [listener]) and return
/// the next token to parse. Peek methods do not generate events (except for
/// errors) and may return null. Skip methods are like parse methods, but skip
/// over some parts of the file being parsed.
///
/// Parse methods are generally named `parseGrammarProductionSuffix`. The
/// suffix can be one of `opt`, or `star`. `opt` means zero or one matches,
/// `star` means zero or more matches. For example, [parseMetadataStar]
/// corresponds to this grammar snippet: `metadata*`, and [parseTypeOpt]
/// corresponds to: `type?`.
///
/// ## Implementation Notes
///
/// The parser assumes that keywords, built-in identifiers, and other special
/// words (pseudo-keywords) are all canonicalized. To extend the parser to
/// recognize a new identifier, one should modify
/// [keyword.dart](../scanner/keyword.dart) and ensure the identifier is added
/// to the keyword table.
///
/// As a consequence of this, one should not use `==` to compare strings in the
/// parser. One should favor the methods [optional] and [expected] to recognize
/// keywords or identifiers. In some cases, it's possible to compare a token's
/// `stringValue` using [identical], but normally [optional] will suffice.
///
/// Historically, we over-used identical, and when identical is used on other
/// objects than strings, it can often be replaced by `==`.
///
/// ## Flexibility, Extensibility, and Specification
///
/// The parser is designed to be flexible and extensible. Its methods are
/// designed to be overridden in subclasses, so it can be extended to handle
/// unspecified language extension or experiments while everything in this file
/// attempts to follow the specification (unless when it interferes with error
/// recovery).
///
/// We achieve flexibily, extensible, and specification compliance by following
/// a few rules-of-thumb:
///
/// 1. All methods in the parser should be public.
///
/// 2. The methods follow the specified grammar, and do not implement custom
/// extensions, for example, `native`.
///
/// 3. The parser doesn't rewrite the token stream (when dealing with `>>`).
///
/// ### Implementing Extensions
///
/// For various reasons, some Dart language implementations have used
/// custom/unspecified extensions to the Dart grammar. Examples of this
/// includes diet parsing, patch files, `native` keyword, and generic
/// comments. This class isn't supposed to implement any of these
/// features. Instead it provides hooks for those extensions to be implemented
/// in subclasses or listeners. Let's examine how diet parsing and `native`
/// keyword is currently supported by Fasta.
///
/// #### Implementation of `native` Keyword
///
/// Both dart2js and the Dart VM have used the `native` keyword to mark methods
/// that couldn't be implemented in the Dart language and needed to be
/// implemented in JavaScript or C++, respectively. An example of the syntax
/// extension used by the Dart VM is:
///
///     nativeFunction() native "NativeFunction";
///
/// When attempting to parse this function, the parser eventually calls
/// [parseFunctionBody]. This method will report an unrecoverable error to the
/// listener with the code [codeExpectedFunctionBody]. The listener can then
/// look at the error code and the token and use the methods in
/// [dart_vm_native.dart](dart_vm_native.dart) to parse the native syntax.
///
/// #### Implementation of Diet Parsing
///
/// We call it _diet_ _parsing_ when the parser skips parts of a file. Both
/// dart2js and the Dart VM have been relying on this from early on as it allows
/// them to more quickly compile small programs that use small parts of big
/// libraries. It's also become an integrated part of how Fasta builds up
/// outlines before starting to parse method bodies.
///
/// When looking through this parser, you'll find a number of unused methods
/// starting with `skip`. These methods are only used by subclasses, such as
/// [ClassMemberParser](class_member_parser.dart) and
/// [TopLevelParser](top_level_parser.dart). These methods violate the
/// principle above about following the specified grammar, and originally lived
/// in subclasses. However, we realized that these methods were so widely used
/// and hard to maintain in subclasses, that it made sense to move them here.
///
/// ### Specification and Error Recovery
///
/// To improve error recovery, the parser will inform the listener of
/// recoverable errors and continue to parse.  An example of a recoverable
/// error is:
///
///     Error: Asynchronous for-loop can only be used in 'async' or 'async*'...
///     main() { await for (var x in []) {} }
///              ^^^^^
///
/// For unrecoverable errors, the parser will ask the listener for help to
/// recover from the error. We haven't made much progress on these kinds of
/// errors, so in most cases, the parser aborts by skipping to the end of file.
///
/// Historically, this parser has been rather lax in what it allows, and
/// deferred the enforcement of some syntactical rules to subsequent phases. It
/// doesn't matter how we got there, only that we've identified that it's
/// easier if the parser reports as many errors it can, but informs the
/// listener if the error is recoverable or not.
///
/// Currently, the parser is particularly lax when it comes to the order of
/// modifiers such as `abstract`, `final`, `static`, etc. Historically, dart2js
/// would handle such errors in later phases. We hope that these cases will go
/// away as Fasta matures.
class Parser {
  final Listener listener;

  Uri get uri => listener.uri;

  bool mayParseFunctionExpressions = true;

  /// Represents parser state: what asynchronous syntax is allowed in the
  /// function being currently parsed. In rare situations, this can be set by
  /// external clients, for example, to parse an expression outside a function.
  AsyncModifier asyncState = AsyncModifier.Sync;

  Parser(this.listener);

  bool get inGenerator {
    return asyncState == AsyncModifier.AsyncStar ||
        asyncState == AsyncModifier.SyncStar;
  }

  bool get inAsync {
    return asyncState == AsyncModifier.Async ||
        asyncState == AsyncModifier.AsyncStar;
  }

  bool get inPlainSync => asyncState == AsyncModifier.Sync;

  Token parseUnit(Token token) {
    listener.beginCompilationUnit(token);
    int count = 0;
    while (!identical(token.kind, EOF_TOKEN)) {
      token = parseTopLevelDeclaration(token);
      count++;
    }
    listener.endCompilationUnit(count, token);
    return token;
  }

  Token parseTopLevelDeclaration(Token token) {
    token = _parseTopLevelDeclaration(token);
    listener.endTopLevelDeclaration(token);
    return token;
  }

  Token _parseTopLevelDeclaration(Token token) {
    if (identical(token.type, TokenType.SCRIPT_TAG)) {
      return parseScript(token);
    }
    token = parseMetadataStar(token);
    final String value = token.stringValue;
    if ((identical(value, 'abstract') && optional('class', token.next)) ||
        identical(value, 'class')) {
      return parseClassOrNamedMixinApplication(token);
    } else if (identical(value, 'enum')) {
      return parseEnum(token);
    } else if (identical(value, 'typedef') &&
        (token.next.isIdentifier || optional("void", token.next))) {
      return parseTypedef(token);
    } else if (identical(value, 'library')) {
      return parseLibraryName(token);
    } else if (identical(value, 'import')) {
      return parseImport(token);
    } else if (identical(value, 'export')) {
      return parseExport(token);
    } else if (identical(value, 'part')) {
      return parsePartOrPartOf(token);
    } else {
      return parseTopLevelMember(token);
    }
  }

  /// library qualified ';'
  Token parseLibraryName(Token token) {
    Token libraryKeyword = token;
    listener.beginLibraryName(libraryKeyword);
    assert(optional('library', token));
    token = parseQualified(token.next, IdentifierContext.libraryName,
        IdentifierContext.libraryNameContinuation);
    Token semicolon = token;
    token = expect(';', token);
    listener.endLibraryName(libraryKeyword, semicolon);
    return token;
  }

  /// import uri (if (test) uri)* (as identifier)? combinator* ';'
  Token parseImport(Token token) {
    Token importKeyword = token;
    listener.beginImport(importKeyword);
    assert(optional('import', token));
    token = parseLiteralStringOrRecoverExpression(token.next);
    token = parseConditionalUris(token);
    Token deferredKeyword;
    if (optional('deferred', token)) {
      deferredKeyword = token;
      token = token.next;
    }
    Token asKeyword;
    if (optional('as', token)) {
      asKeyword = token;
      token = parseIdentifier(
          token.next, IdentifierContext.importPrefixDeclaration);
    }
    token = parseCombinators(token);
    Token semicolon = token;
    token = expect(';', token);
    listener.endImport(importKeyword, deferredKeyword, asKeyword, semicolon);
    return token;
  }

  /// if (test) uri
  Token parseConditionalUris(Token token) {
    listener.beginConditionalUris(token);
    int count = 0;
    while (optional('if', token)) {
      count++;
      token = parseConditionalUri(token);
    }
    listener.endConditionalUris(count);
    return token;
  }

  Token parseConditionalUri(Token token) {
    listener.beginConditionalUri(token);
    Token ifKeyword = token;
    token = expect('if', token);
    token = expect('(', token);
    token = parseDottedName(token);
    Token equalitySign;
    if (optional('==', token)) {
      equalitySign = token;
      token = parseLiteralStringOrRecoverExpression(token.next);
    }
    token = expect(')', token);
    token = parseLiteralStringOrRecoverExpression(token);
    listener.endConditionalUri(ifKeyword, equalitySign);
    return token;
  }

  Token parseDottedName(Token token) {
    listener.beginDottedName(token);
    Token firstIdentifier = token;
    token = parseIdentifier(token, IdentifierContext.dottedName);
    int count = 1;
    while (optional('.', token)) {
      token =
          parseIdentifier(token.next, IdentifierContext.dottedNameContinuation);
      count++;
    }
    listener.endDottedName(count, firstIdentifier);
    return token;
  }

  /// export uri conditional-uris* combinator* ';'
  Token parseExport(Token token) {
    Token exportKeyword = token;
    listener.beginExport(exportKeyword);
    assert(optional('export', token));
    token = parseLiteralStringOrRecoverExpression(token.next);
    token = parseConditionalUris(token);
    token = parseCombinators(token);
    Token semicolon = token;
    token = expect(';', token);
    listener.endExport(exportKeyword, semicolon);
    return token;
  }

  Token parseCombinators(Token token) {
    listener.beginCombinators(token);
    int count = 0;
    while (true) {
      String value = token.stringValue;
      if (identical('hide', value)) {
        token = parseHide(token);
      } else if (identical('show', value)) {
        token = parseShow(token);
      } else {
        listener.endCombinators(count);
        break;
      }
      count++;
    }
    return token;
  }

  /// hide identifierList
  Token parseHide(Token token) {
    Token hideKeyword = token;
    listener.beginHide(hideKeyword);
    assert(optional('hide', token));
    token = parseIdentifierList(token.next);
    listener.endHide(hideKeyword);
    return token;
  }

  /// show identifierList
  Token parseShow(Token token) {
    Token showKeyword = token;
    listener.beginShow(showKeyword);
    assert(optional('show', token));
    token = parseIdentifierList(token.next);
    listener.endShow(showKeyword);
    return token;
  }

  /// identifier (, identifier)*
  Token parseIdentifierList(Token token) {
    listener.beginIdentifierList(token);
    token = parseIdentifier(token, IdentifierContext.combinator);
    int count = 1;
    while (optional(',', token)) {
      token = parseIdentifier(token.next, IdentifierContext.combinator);
      count++;
    }
    listener.endIdentifierList(count);
    return token;
  }

  /// type (, type)*
  Token parseTypeList(Token token) {
    listener.beginTypeList(token);
    token = parseType(token);
    int count = 1;
    while (optional(',', token)) {
      token = parseType(token.next);
      count++;
    }
    listener.endTypeList(count);
    return token;
  }

  Token parsePartOrPartOf(Token token) {
    assert(optional('part', token));
    if (optional('of', token.next)) {
      return parsePartOf(token);
    } else {
      return parsePart(token);
    }
  }

  Token parsePart(Token token) {
    Token partKeyword = token;
    listener.beginPart(token);
    assert(optional('part', token));
    token = parseLiteralStringOrRecoverExpression(token.next);
    Token semicolon = token;
    token = expect(';', token);
    listener.endPart(partKeyword, semicolon);
    return token;
  }

  Token parsePartOf(Token token) {
    listener.beginPartOf(token);
    assert(optional('part', token));
    assert(optional('of', token.next));
    Token partKeyword = token;
    token = token.next.next;
    bool hasName = token.isIdentifier;
    if (hasName) {
      token = parseQualified(token, IdentifierContext.partName,
          IdentifierContext.partNameContinuation);
    } else {
      token = parseLiteralStringOrRecoverExpression(token);
    }
    Token semicolon = token;
    token = expect(';', token);
    listener.endPartOf(partKeyword, semicolon, hasName);
    return token;
  }

  Token parseMetadataStar(Token token, {bool forParameter: false}) {
    token = listener.injectGenericCommentTypeAssign(token);
    listener.beginMetadataStar(token);
    int count = 0;
    while (optional('@', token)) {
      token = parseMetadata(token);
      count++;
    }
    listener.endMetadataStar(count, forParameter);
    return token;
  }

  /// Parse `'@' qualified (‘.’ identifier)? (arguments)?`
  Token parseMetadata(Token token) {
    listener.beginMetadata(token);
    Token atToken = token;
    assert(optional('@', token));
    token = parseIdentifier(token.next, IdentifierContext.metadataReference);
    token =
        parseQualifiedRestOpt(token, IdentifierContext.metadataContinuation);
    if (optional("<", token)) {
      reportRecoverableErrorCode(token, codeMetadataTypeArguments);
    }
    token = parseTypeArgumentsOpt(token);
    Token period = null;
    if (optional('.', token)) {
      period = token;
      token = parseIdentifier(
          token.next, IdentifierContext.metadataContinuationAfterTypeArguments);
    }
    token = parseArgumentsOpt(token);
    listener.endMetadata(atToken, period, token);
    return token;
  }

  Token parseScript(Token token) {
    listener.handleScript(token);
    return token.next;
  }

  Token parseTypedef(Token token) {
    Token typedefKeyword = token;
    listener.beginFunctionTypeAlias(token);
    Token equals;
    if (optional('=', peekAfterNominalType(token.next))) {
      token = parseIdentifier(token.next, IdentifierContext.typedefDeclaration);
      token = parseTypeVariablesOpt(token);
      equals = token;
      token = expect('=', token);
      token = parseType(token);
    } else {
      token = parseReturnTypeOpt(token.next);
      token = parseIdentifier(token, IdentifierContext.typedefDeclaration);
      token = parseTypeVariablesOpt(token);
      token = parseFormalParameters(token, MemberKind.FunctionTypeAlias);
    }
    listener.endFunctionTypeAlias(typedefKeyword, equals, token);
    return expect(';', token);
  }

  Token parseMixinApplication(Token token) {
    listener.beginMixinApplication(token);
    token = parseType(token);
    Token withKeyword = token;
    token = expect('with', token);
    token = parseTypeList(token);
    listener.endMixinApplication(withKeyword);
    return token;
  }

  Token parseReturnTypeOpt(Token token) {
    if (identical(token.stringValue, 'void')) {
      if (isGeneralizedFunctionType(token.next)) {
        return parseType(token);
      } else {
        listener.handleVoidKeyword(token);
        return token.next;
      }
    } else {
      return parseTypeOpt(token);
    }
  }

  Token parseFormalParametersOpt(Token token, MemberKind kind) {
    if (optional('(', token)) {
      return parseFormalParameters(token, kind);
    } else {
      listener.handleNoFormalParameters(token, kind);
      return token;
    }
  }

  Token skipFormalParameters(Token token, MemberKind kind) {
    // TODO(ahe): Shouldn't this be `beginFormalParameters`?
    listener.beginOptionalFormalParameters(token);
    if (!optional('(', token)) {
      if (optional(';', token)) {
        reportRecoverableErrorCode(token, codeExpectedOpenParens);
        return token;
      }
      return reportUnrecoverableErrorCodeWithString(
              token, codeExpectedButGot, "(")
          .next;
    }
    BeginToken beginGroupToken = token;
    Token endToken = beginGroupToken.endGroup;
    listener.endFormalParameters(0, token, endToken, kind);
    return endToken.next;
  }

  /// Parses the formal parameter list of a function.
  ///
  /// If `kind == MemberKind.GeneralizedFunctionType`, then names may be
  /// omitted (except for named arguments). Otherwise, types may be omitted.
  Token parseFormalParameters(Token token, MemberKind kind) {
    Token begin = token;
    listener.beginFormalParameters(begin, kind);
    expect('(', token);
    int parameterCount = 0;
    do {
      token = token.next;
      if (optional(')', token)) {
        break;
      }
      ++parameterCount;
      String value = token.stringValue;
      if (identical(value, '[')) {
        token = parseOptionalFormalParameters(token, false, kind);
        break;
      } else if (identical(value, '{')) {
        token = parseOptionalFormalParameters(token, true, kind);
        break;
      } else if (identical(value, '[]')) {
        --parameterCount;
        reportRecoverableErrorCode(token, codeEmptyOptionalParameterList);
        token = token.next;
        break;
      }
      token = parseFormalParameter(token, FormalParameterType.REQUIRED, kind);
    } while (optional(',', token));
    listener.endFormalParameters(parameterCount, begin, token, kind);
    return expect(')', token);
  }

  Token parseFormalParameter(
      Token token, FormalParameterType parameterKind, MemberKind memberKind) {
    token = parseMetadataStar(token, forParameter: true);
    listener.beginFormalParameter(token, memberKind);

    bool inFunctionType = memberKind == MemberKind.GeneralizedFunctionType;
    token = parseModifiers(token, memberKind, parameterKind: parameterKind);
    bool isNamedParameter = parameterKind == FormalParameterType.NAMED;

    Token thisKeyword = null;
    Token nameToken;
    if (inFunctionType) {
      if (isNamedParameter || token.isIdentifier) {
        nameToken = token;
        token = parseIdentifier(
            token, IdentifierContext.formalParameterDeclaration);
      } else {
        listener.handleNoName(token);
      }
    } else {
      if (optional('this', token)) {
        thisKeyword = token;
        token = expect('.', token.next);
        nameToken = token;
        token = parseIdentifier(token, IdentifierContext.fieldInitializer);
      } else {
        nameToken = token;
        token = parseIdentifier(
            token, IdentifierContext.formalParameterDeclaration);
      }
    }
    if (isNamedParameter && nameToken.lexeme.startsWith("_")) {
      reportRecoverableErrorCode(nameToken, codePrivateNamedParameter);
    }

    token = listener.injectGenericCommentTypeList(token);
    if (optional('(', token)) {
      Token inlineFunctionTypeStart = token;
      listener.beginFunctionTypedFormalParameter(token);
      listener.handleNoTypeVariables(token);
      token = parseFormalParameters(token, MemberKind.FunctionTypedParameter);
      listener.endFunctionTypedFormalParameter(thisKeyword, parameterKind);
      // Generalized function types don't allow inline function types.
      // The following isn't allowed:
      //    int Function(int bar(String x)).
      if (memberKind == MemberKind.GeneralizedFunctionType) {
        reportRecoverableErrorCode(
            inlineFunctionTypeStart, codeInvalidInlineFunctionType);
      }
    } else if (optional('<', token)) {
      Token inlineFunctionTypeStart = token;
      listener.beginFunctionTypedFormalParameter(token);
      token = parseTypeVariablesOpt(token);
      token = parseFormalParameters(token, MemberKind.FunctionTypedParameter);
      listener.endFunctionTypedFormalParameter(thisKeyword, parameterKind);
      // Generalized function types don't allow inline function types.
      // The following isn't allowed:
      //    int Function(int bar(String x)).
      if (memberKind == MemberKind.GeneralizedFunctionType) {
        reportRecoverableErrorCode(
            inlineFunctionTypeStart, codeInvalidInlineFunctionType);
      }
    }
    String value = token.stringValue;
    if ((identical('=', value)) || (identical(':', value))) {
      Token equal = token;
      token = parseExpression(token.next);
      listener.handleValuedFormalParameter(equal, token);
      if (parameterKind.isRequired) {
        reportRecoverableErrorCode(equal, codeRequiredParameterWithDefault);
      } else if (parameterKind.isPositional && identical(':', value)) {
        reportRecoverableErrorCode(equal, codePositionalParameterWithEquals);
      } else if (inFunctionType ||
          memberKind == MemberKind.FunctionTypeAlias ||
          memberKind == MemberKind.FunctionTypedParameter) {
        reportRecoverableErrorCode(equal.next, codeFunctionTypeDefaultValue);
      }
    } else {
      listener.handleFormalParameterWithoutValue(token);
    }
    listener.endFormalParameter(
        thisKeyword, nameToken, parameterKind, memberKind);
    return token;
  }

  Token parseOptionalFormalParameters(
      Token token, bool isNamed, MemberKind kind) {
    Token begin = token;
    listener.beginOptionalFormalParameters(begin);
    assert((isNamed && optional('{', token)) || optional('[', token));
    int parameterCount = 0;
    do {
      token = token.next;
      if (isNamed && optional('}', token)) {
        break;
      } else if (!isNamed && optional(']', token)) {
        break;
      }
      var type =
          isNamed ? FormalParameterType.NAMED : FormalParameterType.POSITIONAL;
      token = parseFormalParameter(token, type, kind);
      ++parameterCount;
    } while (optional(',', token));
    if (parameterCount == 0) {
      reportRecoverableErrorCode(
          token,
          isNamed
              ? codeEmptyNamedParameterList
              : codeEmptyOptionalParameterList);
    }
    listener.endOptionalFormalParameters(parameterCount, begin, token);
    if (isNamed) {
      return expect('}', token);
    } else {
      return expect(']', token);
    }
  }

  Token parseTypeOpt(Token token) {
    if (isGeneralizedFunctionType(token)) {
      // Function type without return type.
      return parseType(token);
    }
    token = listener.injectGenericCommentTypeAssign(token);
    Token peek = peekAfterIfType(token);
    if (peek != null && (peek.isIdentifier || optional('this', peek))) {
      return parseType(token);
    }
    listener.handleNoType(token);
    return token;
  }

  bool isValidTypeReference(Token token) {
    int kind = token.kind;
    if (IDENTIFIER_TOKEN == kind) return true;
    if (KEYWORD_TOKEN == kind) {
      String value = token.type.lexeme;
      return token.type.isPseudo ||
          (identical(value, 'dynamic')) ||
          (identical(value, 'void'));
    }
    return false;
  }

  /// Returns true if [token] matches '<' type (',' type)* '>' '(', and
  /// otherwise returns false. The final '(' is not part of the grammar
  /// construct `typeArguments`, but it is required here such that type
  /// arguments in generic method invocations can be recognized, and as few as
  /// possible other constructs will pass (e.g., 'a < C, D > 3').
  bool isValidMethodTypeArguments(Token token) {
    return tryParseMethodTypeArguments(token) != null;
  }

  /// Returns token after match if [token] matches '<' type (',' type)* '>' '(',
  /// and otherwise returns null. Does not produce listener events. With respect
  /// to the final '(', please see the description of
  /// [isValidMethodTypeArguments].
  Token tryParseMethodTypeArguments(Token token) {
    if (!identical(token.kind, LT_TOKEN)) return null;
    BeginToken beginToken = token;
    Token endToken = beginToken.endGroup;
    if (endToken == null || !identical(endToken.next.kind, OPEN_PAREN_TOKEN)) {
      return null;
    }
    token = tryParseType(token.next);
    while (token != null && identical(token.kind, COMMA_TOKEN)) {
      token = tryParseType(token.next);
    }
    if (token == null || !identical(token.kind, GT_TOKEN)) return null;
    return token.next;
  }

  /// Returns token after match if [token] matches typeName typeArguments?, and
  /// otherwise returns null. Does not produce listener events.
  Token tryParseType(Token token) {
    token = tryParseQualified(token);
    if (token == null) return null;
    Token tokenAfterQualified = token;
    token = tryParseNestedTypeArguments(token);
    return token == null ? tokenAfterQualified : token;
  }

  /// Returns token after match if [token] matches identifier ('.' identifier)?,
  /// and otherwise returns null. Does not produce listener events.
  Token tryParseQualified(Token token) {
    if (!isValidTypeReference(token)) return null;
    token = token.next;
    if (!identical(token.kind, PERIOD_TOKEN)) return token;
    token = token.next;
    if (!identical(token.kind, IDENTIFIER_TOKEN)) return null;
    return token.next;
  }

  /// Returns token after match if [token] matches '<' type (',' type)* '>',
  /// and otherwise returns null. Does not produce listener events. The final
  /// '>' may be the first character in a '>>' token, in which case a synthetic
  /// '>' token is created and returned, representing the second '>' in the
  /// '>>' token.
  Token tryParseNestedTypeArguments(Token token) {
    if (!identical(token.kind, LT_TOKEN)) return null;
    // If the initial '<' matches the first '>' in a '>>' token, we will have
    // `token.endGroup == null`, so we cannot rely on `token.endGroup == null`
    // to imply that the match must fail. Hence no `token.endGroup == null`
    // test here.
    token = tryParseType(token.next);
    while (token != null && identical(token.kind, COMMA_TOKEN)) {
      token = tryParseType(token.next);
    }
    if (token == null) return null;
    if (identical(token.kind, GT_TOKEN)) return token.next;
    if (!identical(token.kind, GT_GT_TOKEN)) return null;
    // [token] is '>>' of which the final '>' that we are parsing is the first
    // character. In order to keep the parsing process on track we must return
    // a synthetic '>' corresponding to the second character of that '>>'.
    Token syntheticToken = new Token(TokenType.GT, token.charOffset + 1);
    syntheticToken.next = token.next;
    return syntheticToken;
  }

  Token parseQualified(Token token, IdentifierContext context,
      IdentifierContext continuationContext) {
    token = parseIdentifier(token, context);
    while (optional('.', token)) {
      token = parseQualifiedRest(token, continuationContext);
    }
    return token;
  }

  Token parseQualifiedRestOpt(
      Token token, IdentifierContext continuationContext) {
    if (optional('.', token)) {
      return parseQualifiedRest(token, continuationContext);
    } else {
      return token;
    }
  }

  Token parseQualifiedRest(Token token, IdentifierContext context) {
    assert(optional('.', token));
    Token period = token;
    token = parseIdentifier(token.next, context);
    listener.handleQualified(period);
    return token;
  }

  Token skipBlock(Token token) {
    if (!optional('{', token)) {
      return reportUnrecoverableErrorCode(token, codeExpectedBlockToSkip).next;
    }
    BeginToken beginGroupToken = token;
    Token endGroup = beginGroupToken.endGroup;
    if (endGroup == null || !identical(endGroup.kind, $CLOSE_CURLY_BRACKET)) {
      return reportUnmatchedToken(beginGroupToken).next;
    }
    return beginGroupToken.endGroup;
  }

  Token parseEnum(Token token) {
    listener.beginEnum(token);
    Token enumKeyword = token;
    token = parseIdentifier(token.next, IdentifierContext.enumDeclaration);
    token = expect('{', token);
    int count = 0;
    if (!optional('}', token)) {
      token = parseIdentifier(token, IdentifierContext.enumValueDeclaration);
      count++;
      while (optional(',', token)) {
        token = token.next;
        if (optional('}', token)) break;
        token = parseIdentifier(token, IdentifierContext.enumValueDeclaration);
        count++;
      }
    }
    Token endBrace = token;
    token = expect('}', token);
    listener.endEnum(enumKeyword, endBrace, count);
    return token;
  }

  Token parseClassOrNamedMixinApplication(Token token) {
    Token begin = token;
    Token abstractKeyword;
    Token classKeyword = token;
    if (optional('abstract', token)) {
      abstractKeyword = token;
      token = token.next;
      classKeyword = token;
    }
    assert(optional('class', classKeyword));
    int modifierCount = 0;
    if (abstractKeyword != null) {
      parseModifier(abstractKeyword);
      modifierCount++;
    }
    listener.handleModifiers(modifierCount);
    bool isMixinApplication = optional('=', peekAfterNominalType(token));
    Token name = token.next;

    if (isMixinApplication) {
      token = parseIdentifier(name, IdentifierContext.namedMixinDeclaration);
      listener.beginNamedMixinApplication(begin, name);
    } else {
      token = parseIdentifier(name, IdentifierContext.classDeclaration);
      listener.beginClassDeclaration(begin, name);
    }

    token = parseTypeVariablesOpt(token);

    if (optional('=', token)) {
      Token equals = token;
      token = token.next;
      return parseNamedMixinApplication(
          token, begin, classKeyword, name, equals);
    } else {
      return parseClass(token, begin, classKeyword, name);
    }
  }

  Token parseNamedMixinApplication(
      Token token, Token begin, Token classKeyword, Token name, Token equals) {
    token = parseMixinApplication(token);
    Token implementsKeyword = null;
    if (optional('implements', token)) {
      implementsKeyword = token;
      token = parseTypeList(token.next);
    }
    listener.endNamedMixinApplication(
        begin, classKeyword, equals, implementsKeyword, token);
    return expect(';', token);
  }

  Token parseClass(Token token, Token begin, Token classKeyword, Token name) {
    Token extendsKeyword;
    if (optional('extends', token)) {
      extendsKeyword = token;
      if (optional('with', peekAfterNominalType(token.next))) {
        token = parseMixinApplication(token.next);
      } else {
        token = parseType(token.next);
      }
    } else {
      extendsKeyword = null;
      listener.handleNoType(token);
    }
    Token implementsKeyword;
    int interfacesCount = 0;
    if (optional('implements', token)) {
      implementsKeyword = token;
      do {
        token = parseType(token.next);
        ++interfacesCount;
      } while (optional(',', token));
    }
    token = parseClassBody(token);
    listener.endClassDeclaration(interfacesCount, begin, classKeyword,
        extendsKeyword, implementsKeyword, token);
    return token.next;
  }

  Token parseStringPart(Token token) {
    if (token.kind != STRING_TOKEN) {
      token =
          reportUnrecoverableErrorCodeWithToken(token, codeExpectedString).next;
    }
    listener.handleStringPart(token);
    return token.next;
  }

  Token parseIdentifier(Token token, IdentifierContext context) {
    if (!token.isIdentifier) {
      if (optional("void", token)) {
        reportRecoverableErrorCode(token, codeInvalidVoid);
      } else {
        token =
            reportUnrecoverableErrorCodeWithToken(token, codeExpectedIdentifier)
                .next;
      }
    } else if (token.type.isBuiltIn && !context.isBuiltInIdentifierAllowed) {
      if (context.inDeclaration) {
        reportRecoverableErrorCodeWithToken(
            token, codeBuiltInIdentifierInDeclaration);
      } else if (!optional("dynamic", token)) {
        reportRecoverableErrorCodeWithToken(token, codeBuiltInIdentifierAsType);
      }
    } else if (!inPlainSync && token.type.isPseudo) {
      if (optional('await', token)) {
        reportRecoverableErrorCode(token, codeAwaitAsIdentifier);
      } else if (optional('yield', token)) {
        reportRecoverableErrorCode(token, codeYieldAsIdentifier);
      } else if (optional('async', token)) {
        reportRecoverableErrorCode(token, codeAsyncAsIdentifier);
      }
    }
    listener.handleIdentifier(token, context);
    return token.next;
  }

  Token expect(String string, Token token) {
    if (!identical(string, token.stringValue)) {
      return reportUnrecoverableErrorCodeWithString(
              token, codeExpectedButGot, string)
          .next;
    }
    return token.next;
  }

  Token parseTypeVariable(Token token) {
    listener.beginTypeVariable(token);
    token = parseMetadataStar(token);
    token = parseIdentifier(token, IdentifierContext.typeVariableDeclaration);
    Token extendsOrSuper = null;
    if (optional('extends', token) || optional('super', token)) {
      extendsOrSuper = token;
      token = parseType(token.next);
    } else {
      listener.handleNoType(token);
    }
    listener.endTypeVariable(token, extendsOrSuper);
    return token;
  }

  /// Returns true if the stringValue of the [token] is either [value1],
  /// [value2], or [value3].
  bool isOneOf3(Token token, String value1, String value2, String value3) {
    String stringValue = token.stringValue;
    return identical(value1, stringValue) ||
        identical(value2, stringValue) ||
        identical(value3, stringValue);
  }

  /// Returns true if the stringValue of the [token] is either [value1],
  /// [value2], [value3], or [value4].
  bool isOneOf4(
      Token token, String value1, String value2, String value3, String value4) {
    String stringValue = token.stringValue;
    return identical(value1, stringValue) ||
        identical(value2, stringValue) ||
        identical(value3, stringValue) ||
        identical(value4, stringValue);
  }

  bool notEofOrValue(String value, Token token) {
    return !identical(token.kind, EOF_TOKEN) &&
        !identical(value, token.stringValue);
  }

  bool isGeneralizedFunctionType(Token token) {
    return optional('Function', token) &&
        (optional('<', token.next) || optional('(', token.next));
  }

  Token parseType(Token token) {
    Token begin = token;
    if (isGeneralizedFunctionType(token)) {
      // A function type without return type.
      // Push the non-existing return type first. The loop below will
      // generate the full type.
      listener.handleNoType(token);
    } else if (optional("void", token) &&
        isGeneralizedFunctionType(token.next)) {
      listener.handleVoidKeyword(token);
      token = token.next;
    } else {
      IdentifierContext context = IdentifierContext.typeReference;
      if (token.isIdentifier && optional(".", token.next)) {
        context = IdentifierContext.prefixedTypeReference;
      }
      token = parseIdentifier(token, context);
      token = parseQualifiedRestOpt(
          token, IdentifierContext.typeReferenceContinuation);
      token = parseTypeArgumentsOpt(token);
      listener.handleType(begin, token);
    }

    {
      Token newBegin =
          listener.replaceTokenWithGenericCommentTypeAssign(begin, token);
      if (!identical(newBegin, begin)) {
        listener.discardTypeReplacedWithCommentTypeAssign();
        return parseType(newBegin);
      }
    }

    // While we see a `Function(` treat the pushed type as return type.
    // For example: `int Function() Function(int) Function(String x)`.
    while (isGeneralizedFunctionType(token)) {
      token = parseFunctionType(token);
    }
    return token;
  }

  /// Parses a generalized function type.
  ///
  /// The return type must already be pushed.
  Token parseFunctionType(Token token) {
    assert(optional('Function', token));
    Token functionToken = token;
    token = token.next;
    token = parseTypeVariablesOpt(token);
    token = parseFormalParameters(token, MemberKind.GeneralizedFunctionType);
    listener.handleFunctionType(functionToken, token);
    return token;
  }

  Token parseTypeArgumentsOpt(Token token) {
    return parseStuff(
        token,
        (t) => listener.beginTypeArguments(t),
        (t) => parseType(t),
        (c, bt, et) => listener.endTypeArguments(c, bt, et),
        (t) => listener.handleNoTypeArguments(t));
  }

  Token parseTypeVariablesOpt(Token token) {
    return parseStuff(
        token,
        (t) => listener.beginTypeVariables(t),
        (t) => parseTypeVariable(t),
        (c, bt, et) => listener.endTypeVariables(c, bt, et),
        (t) => listener.handleNoTypeVariables(t));
  }

  /// TODO(ahe): Clean this up.
  Token parseStuff(Token token, Function beginStuff, Function stuffParser,
      Function endStuff, Function handleNoStuff) {
    token = listener.injectGenericCommentTypeList(token);
    if (optional('<', token)) {
      Token begin = token;
      beginStuff(begin);
      int count = 0;
      do {
        token = stuffParser(token.next);
        ++count;
      } while (optional(',', token));
      Token next = token.next;
      if (identical(token.stringValue, '>>')) {
        token = new Token(TokenType.GT, token.charOffset);
        token.next = new Token(TokenType.GT, token.charOffset + 1);
        token.next.next = next;
      }
      endStuff(count, begin, token);
      return expect('>', token);
    }
    handleNoStuff(token);
    return token;
  }

  Token parseTopLevelMember(Token token) {
    Token start = token;
    listener.beginTopLevelMember(token);

    Link<Token> identifiers = findMemberName(token);
    if (identifiers.isEmpty) {
      return reportUnrecoverableErrorCodeWithToken(
              start, codeExpectedDeclaration)
          .next;
    }
    Token afterName = identifiers.head;
    identifiers = identifiers.tail;

    if (identifiers.isEmpty) {
      return reportUnrecoverableErrorCodeWithToken(
              start, codeExpectedDeclaration)
          .next;
    }
    Token name = identifiers.head;
    identifiers = identifiers.tail;
    Token getOrSet;
    if (!identifiers.isEmpty) {
      String value = identifiers.head.stringValue;
      if ((identical(value, 'get')) || (identical(value, 'set'))) {
        getOrSet = identifiers.head;
        identifiers = identifiers.tail;
      }
    }
    Token type;
    if (!identifiers.isEmpty) {
      if (isValidTypeReference(identifiers.head)) {
        type = identifiers.head;
        identifiers = identifiers.tail;
      }
    }

    token = afterName;
    bool isField;
    while (true) {
      // Loop to allow the listener to rewrite the token stream for
      // error handling.
      final String value = token.stringValue;
      if ((identical(value, '(')) ||
          (identical(value, '{')) ||
          (identical(value, '=>'))) {
        isField = false;
        break;
      } else if ((identical(value, '=')) || (identical(value, ','))) {
        isField = true;
        break;
      } else if (identical(value, ';')) {
        if (getOrSet != null) {
          // If we found a "get" keyword, this must be an abstract
          // getter.
          isField = (!identical(getOrSet.stringValue, 'get'));
          // TODO(ahe): This feels like a hack.
        } else {
          isField = true;
        }
        break;
      } else {
        token = reportUnexpectedToken(token).next;
        if (identical(token.kind, EOF_TOKEN)) return token;
      }
    }
    var modifiers = identifiers.reverse();
    return isField
        ? parseFields(start, modifiers, type, getOrSet, name, true)
        : parseTopLevelMethod(start, modifiers, type, getOrSet, name);
  }

  Token parseFields(Token start, Link<Token> modifiers, Token type,
      Token getOrSet, Token name, bool isTopLevel) {
    Token varFinalOrConst = null;
    for (Token modifier in modifiers) {
      if (optional("var", modifier) ||
          optional("final", modifier) ||
          optional("const", modifier)) {
        varFinalOrConst = modifier;
        break;
      }
    }
    Token token = parseModifiers(start,
        isTopLevel ? MemberKind.TopLevelField : MemberKind.NonStaticField,
        isVariable: true);

    if (token != name) {
      reportRecoverableErrorCodeWithToken(token, codeExtraneousModifier);
      token = name;
    }

    IdentifierContext context = isTopLevel
        ? IdentifierContext.topLevelVariableDeclaration
        : IdentifierContext.fieldDeclaration;
    token = parseIdentifier(token, context);

    int fieldCount = 1;
    token = parseFieldInitializerOpt(token, name, varFinalOrConst, isTopLevel);
    while (optional(',', token)) {
      name = token.next;
      token = parseIdentifier(token.next, context);
      token =
          parseFieldInitializerOpt(token, name, varFinalOrConst, isTopLevel);
      ++fieldCount;
    }
    Token semicolon = token;
    token = expectSemicolon(token);
    if (isTopLevel) {
      listener.endTopLevelFields(fieldCount, start, semicolon);
    } else {
      listener.endFields(fieldCount, start, semicolon);
    }
    return token;
  }

  Token parseTopLevelMethod(Token start, Link<Token> modifiers, Token type,
      Token getOrSet, Token name) {
    listener.beginTopLevelMethod(start, name);
    Token externalModifier;
    // TODO(johnniwinther): Move error reporting to resolution to give more
    // specific error messages.
    for (Token modifier in modifiers) {
      if (externalModifier == null && optional('external', modifier)) {
        externalModifier = modifier;
      } else {
        reportRecoverableErrorCodeWithToken(modifier, codeExtraneousModifier);
      }
    }
    if (externalModifier != null) {
      parseModifier(externalModifier);
      listener.handleModifiers(1);
    } else {
      listener.handleModifiers(0);
    }

    if (type == null) {
      listener.handleNoType(name);
    } else {
      parseReturnTypeOpt(type);
    }
    Token token =
        parseIdentifier(name, IdentifierContext.topLevelFunctionDeclaration);

    bool isGetter = false;
    if (getOrSet == null) {
      token = parseTypeVariablesOpt(token);
    } else {
      isGetter = optional("get", getOrSet);
      listener.handleNoTypeVariables(token);
    }
    checkFormals(isGetter, name, token);
    token = parseFormalParametersOpt(token, MemberKind.TopLevelMethod);
    AsyncModifier savedAsyncModifier = asyncState;
    Token asyncToken = token;
    token = parseAsyncModifier(token);
    if (getOrSet != null && !inPlainSync && optional("set", getOrSet)) {
      reportRecoverableErrorCode(asyncToken, codeSetterNotSync);
    }
    token = parseFunctionBody(token, false, externalModifier != null);
    asyncState = savedAsyncModifier;
    Token endToken = token;
    token = token.next;
    listener.endTopLevelMethod(start, getOrSet, endToken);
    return token;
  }

  void checkFormals(bool isGetter, Token name, Token token) {
    if (optional("(", token)) {
      if (isGetter) {
        reportRecoverableErrorCode(token, codeGetterWithFormals);
      }
    } else if (!isGetter) {
      reportRecoverableErrorCodeWithToken(name, codeNoFormals);
    }
  }

  /// Looks ahead to find the name of a member. Returns a link of the modifiers,
  /// set/get, (operator) name, and either the start of the method body or the
  /// end of the declaration.
  ///
  /// Examples:
  ///
  ///     int get foo;
  /// results in
  ///     [';', 'foo', 'get', 'int']
  ///
  ///
  ///     static const List<int> foo = null;
  /// results in
  ///     ['=', 'foo', 'List', 'const', 'static']
  ///
  ///
  ///     get foo async* { return null }
  /// results in
  ///     ['{', 'foo', 'get']
  ///
  ///
  ///     operator *(arg) => null;
  /// results in
  ///     ['(', '*', 'operator']
  ///
  Link<Token> findMemberName(Token token) {
    // TODO(ahe): This method is rather broken for examples like this:
    //
    //     get<T>(){}
    //
    // In addition, the loop below will include things that can't be
    // identifiers. This may be desirable (for error recovery), or
    // not. Regardless, this method probably needs an overhaul.
    Link<Token> identifiers = const Link<Token>();

    // `true` if 'get' has been seen.
    bool isGetter = false;
    // `true` if an identifier has been seen after 'get'.
    bool hasName = false;

    while (token.kind != EOF_TOKEN) {
      if (optional('get', token)) {
        isGetter = true;
      } else if (hasName &&
          (optional("sync", token) || optional("async", token))) {
        // Skip.
        token = token.next;
        if (optional("*", token)) {
          // Skip.
          token = token.next;
        }
        continue;
      } else if (optional("(", token) ||
          optional("{", token) ||
          optional("=>", token)) {
        // A method.
        identifiers = identifiers.prepend(token);
        return listener.handleMemberName(identifiers);
      } else if (optional("=", token) ||
          optional(";", token) ||
          optional(",", token)) {
        // A field or abstract getter.
        identifiers = identifiers.prepend(token);
        return listener.handleMemberName(identifiers);
      } else if (isGetter) {
        hasName = true;
      }
      token = listener.injectGenericCommentTypeAssign(token);
      identifiers = identifiers.prepend(token);

      if (!isGeneralizedFunctionType(token)) {
        // Read a potential return type.
        if (isValidTypeReference(token)) {
          Token type = token;
          // type ...
          if (optional('.', token.next)) {
            // type '.' ...
            if (token.next.next.isIdentifier) {
              // type '.' identifier
              token = token.next.next;
            }
          }
          if (optional('<', token.next)) {
            if (token.next is BeginToken) {
              BeginToken beginGroup = token.next;
              if (beginGroup.endGroup == null) {
                token = reportUnmatchedToken(beginGroup).next;
              } else {
                token = beginGroup.endGroup;
              }
            }
          }
          // If the next token after a type has a type substitution comment
          // /*=T*/, then the previous type tokens and the reference to them
          // from the link should be replaced.
          {
            Token newType = listener.replaceTokenWithGenericCommentTypeAssign(
                type, token.next);
            if (!identical(newType, type)) {
              identifiers = identifiers.tail;
              token = newType;
              continue;
            }
          }
        }
        token = token.next;
      }
      while (isGeneralizedFunctionType(token)) {
        token = token.next;
        if (optional('<', token)) {
          if (token is BeginToken) {
            BeginToken beginGroup = token;
            if (beginGroup.endGroup == null) {
              token = reportUnmatchedToken(beginGroup).next;
            } else {
              token = beginGroup.endGroup.next;
            }
          }
        }
        if (!optional('(', token)) {
          if (optional(';', token)) {
            reportRecoverableErrorCode(token, codeExpectedOpenParens);
          }
          token = expect("(", token);
        }
        if (token is BeginToken) {
          BeginToken beginGroup = token;
          if (beginGroup.endGroup == null) {
            token = reportUnmatchedToken(beginGroup).next;
          } else {
            token = beginGroup.endGroup.next;
          }
        }
      }
    }
    return listener.handleMemberName(const Link<Token>());
  }

  Token parseFieldInitializerOpt(
      Token token, Token name, Token varFinalOrConst, bool isTopLevel) {
    if (optional('=', token)) {
      Token assignment = token;
      listener.beginFieldInitializer(token);
      token = parseExpression(token.next);
      listener.endFieldInitializer(assignment, token);
    } else {
      if (varFinalOrConst != null) {
        if (optional("const", varFinalOrConst)) {
          reportRecoverableErrorCode(name, codeConstFieldWithoutInitializer);
        } else if (isTopLevel && optional("final", varFinalOrConst)) {
          reportRecoverableErrorCode(name, codeFinalFieldWithoutInitializer);
        }
      }
      listener.handleNoFieldInitializer(token);
    }
    return token;
  }

  Token parseVariableInitializerOpt(Token token) {
    if (optional('=', token)) {
      Token assignment = token;
      listener.beginVariableInitializer(token);
      token = parseExpression(token.next);
      listener.endVariableInitializer(assignment);
    } else {
      listener.handleNoVariableInitializer(token);
    }
    return token;
  }

  Token parseInitializersOpt(Token token) {
    if (optional(':', token)) {
      return parseInitializers(token);
    } else {
      listener.handleNoInitializers();
      return token;
    }
  }

  Token parseInitializers(Token token) {
    Token begin = token;
    listener.beginInitializers(begin);
    expect(':', token);
    int count = 0;
    bool old = mayParseFunctionExpressions;
    mayParseFunctionExpressions = false;
    do {
      token = parseInitializer(token.next);
      ++count;
    } while (optional(',', token));
    mayParseFunctionExpressions = old;
    listener.endInitializers(count, begin, token);
    return token;
  }

  Token parseInitializer(Token token) {
    listener.beginInitializer(token);
    if (optional('assert', token)) {
      token = parseAssert(token, Assert.Initializer);
    } else {
      token = parseExpression(token);
    }
    listener.endInitializer(token);
    return token;
  }

  Token parseLiteralStringOrRecoverExpression(Token token) {
    if (identical(token.kind, STRING_TOKEN)) {
      return parseLiteralString(token);
    } else {
      reportRecoverableErrorCodeWithToken(token, codeExpectedString);
      return parseRecoverExpression(
          token, codeExpectedString.format(uri, token.charOffset, token));
    }
  }

  Token expectSemicolon(Token token) {
    return expect(';', token);
  }

  bool isModifier(Token token) => modifierOrder(token) < 127;

  /// Provides a partial order on modifiers.
  ///
  /// The order is based on the order modifiers must appear in according to the
  /// grammar. For example, `external` must come before `static`.
  ///
  /// In addition, if two modifiers have the same order, they can't both be
  /// used together, for example, `final` and `var` can't be used together.
  ///
  /// If [token] isn't a modifier, 127 is returned.
  int modifierOrder(Token token) {
    final String value = token.stringValue;
    if (identical('external', value)) return 0;
    if (identical('static', value) || identical('covariant', value)) {
      return 1;
    }
    if (identical('final', value) ||
        identical('var', value) ||
        identical('const', value)) {
      return 2;
    }
    if (identical('abstract', value)) return 3;
    return 127;
  }

  Token parseModifier(Token token) {
    assert(isModifier(token));
    listener.handleModifier(token);
    return token.next;
  }

  /// This method is used in most locations where modifiers can occur. However,
  /// it isn't used when parsing a class or when parsing the modifiers of a
  /// member function (non-local), but is used when parsing their formal
  /// parameters.
  ///
  /// When parsing the formal parameters of any function, [parameterKind] is
  /// non-null.
  Token parseModifiers(Token token, MemberKind memberKind,
      {FormalParameterType parameterKind, bool isVariable: false}) {
    bool returnTypeAllowed =
        !isVariable && memberKind != MemberKind.GeneralizedFunctionType;
    bool typeRequired =
        isVariable || memberKind == MemberKind.GeneralizedFunctionType;
    int count = 0;

    int currentOrder = -1;
    bool hasVar = false;
    while (token.kind == KEYWORD_TOKEN) {
      if (token.type.isPseudo) {
        // A pseudo keyword is never a modifier.
        break;
      }
      if (token.type.isBuiltIn) {
        // A built-in identifier can only be a modifier as long as it is
        // followed by another modifier or an identifier. Otherwise, it is the
        // identifier.
        if (token.next.kind != KEYWORD_TOKEN && !token.next.isIdentifier) {
          break;
        }
      }
      int order = modifierOrder(token);
      if (order < 3) {
        // `abstract` isn't parsed with this method.
        if (order > currentOrder) {
          currentOrder = order;
          if (optional("var", token)) {
            if (!isVariable && parameterKind == null) {
              reportRecoverableErrorCodeWithToken(
                  token, codeExtraneousModifier);
            }
            hasVar = true;
            typeRequired = false;
          } else if (optional("final", token)) {
            if (!isVariable && parameterKind == null) {
              reportRecoverableErrorCodeWithToken(
                  token, codeExtraneousModifier);
            }
            typeRequired = false;
          } else if (optional("const", token)) {
            if (!isVariable) {
              reportRecoverableErrorCodeWithToken(
                  token, codeExtraneousModifier);
            }
            typeRequired = false;
          } else if (optional("static", token)) {
            if (parameterKind != null) {
              reportRecoverableErrorCodeWithToken(
                  token, codeExtraneousModifier);
            } else if (memberKind == MemberKind.NonStaticMethod) {
              memberKind = MemberKind.StaticMethod;
            } else if (memberKind == MemberKind.NonStaticField) {
              memberKind = MemberKind.StaticField;
            } else {
              reportRecoverableErrorCodeWithToken(
                  token, codeExtraneousModifier);
              token = token.next;
              continue;
            }
          } else if (optional("covariant", token)) {
            switch (memberKind) {
              case MemberKind.StaticField:
              case MemberKind.StaticMethod:
              case MemberKind.TopLevelField:
              case MemberKind.TopLevelMethod:
                reportRecoverableErrorCodeWithToken(
                    token, codeExtraneousModifier);
                token = token.next;
                continue;

              default:
                break;
            }
          } else if (optional("external", token)) {
            switch (memberKind) {
              case MemberKind.Factory:
              case MemberKind.NonStaticMethod:
              case MemberKind.StaticMethod:
              case MemberKind.TopLevelMethod:
                break;

              default:
                reportRecoverableErrorCodeWithToken(
                    token, codeExtraneousModifier);
                token = token.next;
                continue;
            }
          }
          token = parseModifier(token);
          count++;
        } else {
          reportRecoverableErrorCodeWithToken(token, codeExtraneousModifier);
          token = token.next;
        }
      } else {
        break;
      }
    }
    listener.handleModifiers(count);

    Token beforeType = token;
    if (returnTypeAllowed) {
      token = parseReturnTypeOpt(token);
    } else {
      token = typeRequired ? parseType(token) : parseTypeOpt(token);
    }
    if (typeRequired && beforeType == token) {
      reportRecoverableErrorCode(token, codeTypeRequired);
    }
    if (hasVar && beforeType != token) {
      reportRecoverableErrorCode(beforeType, codeTypeAfterVar);
    }
    return token;
  }

  /// Returns the first token after the type starting at [token].
  ///
  /// This method assumes that [token] is an identifier (or void).  Use
  /// [peekAfterIfType] if [token] isn't known to be an identifier.
  Token peekAfterType(Token token) {
    // We are looking at "identifier ...".
    Token peek = token;
    if (!isGeneralizedFunctionType(token)) {
      peek = peekAfterNominalType(token);
    }

    // We might have just skipped over the return value of the function type.
    // Check again, if we are now at a function type position.
    while (isGeneralizedFunctionType(peek)) {
      peek = peekAfterFunctionType(peek.next);
    }
    return peek;
  }

  /// Returns the first token after the nominal type starting at [token].
  ///
  /// This method assumes that [token] is an identifier (or void).
  Token peekAfterNominalType(Token token) {
    Token peek = token.next;
    if (identical(peek.kind, PERIOD_TOKEN)) {
      if (peek.next.isIdentifier) {
        // Look past a library prefix.
        peek = peek.next.next;
      }
    }
    // We are looking at "qualified ...".
    if (identical(peek.kind, LT_TOKEN)) {
      // Possibly generic type.
      // We are looking at "qualified '<'".
      BeginToken beginGroupToken = peek;
      Token gtToken = beginGroupToken.endGroup;
      if (gtToken != null) {
        // We are looking at "qualified '<' ... '>' ...".
        peek = gtToken.next;
      }
    }
    return peek;
  }

  /// Returns the first token after the function type starting at [token].
  ///
  /// The token must be at the token *after* the `Function` token
  /// position. That is, the return type and the `Function` token must have
  /// already been skipped.
  ///
  /// This function only skips over one function type syntax.  If necessary,
  /// this function must be called multiple times.
  ///
  /// Example:
  ///
  ///     int Function() Function<T>(int)
  ///                 ^          ^
  ///
  /// A call to this function must be either at `(` or at `<`.  If `token`
  /// pointed to the first `(`, then the returned token points to the second
  /// `Function` token.
  Token peekAfterFunctionType(Token token) {
    // Possible inputs are:
    //    ( ... )
    //    < ... >( ... )

    Token peek = token;
    // If there is a generic argument to the function, skip over that one first.
    if (identical(peek.kind, LT_TOKEN)) {
      BeginToken beginGroupToken = peek;
      Token closeToken = beginGroupToken.endGroup;
      if (closeToken != null) {
        peek = closeToken.next;
      }
    }

    // Now we just need to skip over the formals.
    expect('(', peek);

    BeginToken beginGroupToken = peek;
    Token closeToken = beginGroupToken.endGroup;
    if (closeToken != null) {
      peek = closeToken.next;
    }

    return peek;
  }

  /// If [token] is the start of a type, returns the token after that type.
  /// If [token] is not the start of a type, null is returned.
  Token peekAfterIfType(Token token) {
    if (!optional('void', token) && !token.isIdentifier) {
      return null;
    }
    return peekAfterType(token);
  }

  Token skipClassBody(Token token) {
    if (!optional('{', token)) {
      return reportUnrecoverableErrorCodeWithToken(
              token, codeExpectedClassBodyToSkip)
          .next;
    }
    BeginToken beginGroupToken = token;
    Token endGroup = beginGroupToken.endGroup;
    if (endGroup == null || !identical(endGroup.kind, $CLOSE_CURLY_BRACKET)) {
      return reportUnmatchedToken(beginGroupToken).next;
    }
    return endGroup;
  }

  Token parseClassBody(Token token) {
    Token begin = token;
    listener.beginClassBody(token);
    if (!optional('{', token)) {
      token =
          reportUnrecoverableErrorCodeWithToken(token, codeExpectedClassBody)
              .next;
    }
    token = token.next;
    int count = 0;
    while (notEofOrValue('}', token)) {
      token = parseMember(token);
      ++count;
    }
    expect('}', token);
    listener.endClassBody(count, begin, token);
    return token;
  }

  bool isGetOrSet(Token token) {
    final String value = token.stringValue;
    return (identical(value, 'get')) || (identical(value, 'set'));
  }

  bool isFactoryDeclaration(Token token) {
    if (optional('external', token)) token = token.next;
    if (optional('const', token)) token = token.next;
    return optional('factory', token);
  }

  Token parseMember(Token token) {
    token = parseMetadataStar(token);
    Token start = token;
    listener.beginMember(token);
    if (isFactoryDeclaration(token)) {
      token = parseFactoryMethod(token);
      listener.endMember();
      assert(token != null);
      return token;
    }

    Link<Token> identifiers = findMemberName(token);
    if (identifiers.isEmpty) {
      return reportUnrecoverableErrorCodeWithToken(
              start, codeExpectedDeclaration)
          .next;
    }
    Token afterName = identifiers.head;
    identifiers = identifiers.tail;

    if (identifiers.isEmpty) {
      return reportUnrecoverableErrorCodeWithToken(
              start, codeExpectedDeclaration)
          .next;
    }
    Token name = identifiers.head;
    identifiers = identifiers.tail;
    if (!identifiers.isEmpty) {
      if (optional('operator', identifiers.head)) {
        name = identifiers.head;
        identifiers = identifiers.tail;
      }
    }
    Token getOrSet;
    if (!identifiers.isEmpty) {
      if (isGetOrSet(identifiers.head)) {
        getOrSet = identifiers.head;
        identifiers = identifiers.tail;
      }
    }
    Token type;
    if (!identifiers.isEmpty) {
      if (isValidTypeReference(identifiers.head)) {
        type = identifiers.head;
        identifiers = identifiers.tail;
      }
    }

    token = afterName;
    bool isField;
    while (true) {
      // Loop to allow the listener to rewrite the token stream for
      // error handling.
      final String value = token.stringValue;
      if ((identical(value, '(')) ||
          (identical(value, '.')) ||
          (identical(value, '{')) ||
          (identical(value, '=>')) ||
          (identical(value, '<'))) {
        isField = false;
        break;
      } else if (identical(value, ';')) {
        if (getOrSet != null) {
          // If we found a "get" keyword, this must be an abstract
          // getter.
          isField = !optional("get", getOrSet);
          // TODO(ahe): This feels like a hack.
        } else {
          isField = true;
        }
        break;
      } else if ((identical(value, '=')) || (identical(value, ','))) {
        isField = true;
        break;
      } else {
        token = reportUnexpectedToken(token).next;
        if (identical(token.kind, EOF_TOKEN)) {
          // TODO(ahe): This is a hack, see parseTopLevelMember.
          listener.endFields(1, start, token);
          listener.endMember();
          return token;
        }
      }
    }

    var modifiers = identifiers.reverse();
    token = isField
        ? parseFields(start, modifiers, type, getOrSet, name, false)
        : parseMethod(start, modifiers, type, getOrSet, name);
    listener.endMember();
    return token;
  }

  Token parseMethod(Token start, Link<Token> modifiers, Token type,
      Token getOrSet, Token name) {
    listener.beginMethod(start, name);

    Token externalModifier;
    Token staticModifier;
    // TODO(ahe): Consider using [parseModifiers] instead.
    void parseModifierList(Link<Token> tokens) {
      int count = 0;
      int currentOrder = -1;
      for (; !tokens.isEmpty; tokens = tokens.tail) {
        Token token = tokens.head;
        if (optional("abstract", token)) {
          reportRecoverableErrorCodeWithToken(token, codeExtraneousModifier);
          continue;
        }
        int order = modifierOrder(token);
        if (order < 127) {
          if (order > currentOrder) {
            currentOrder = order;
            if (optional("var", token)) {
              reportRecoverableErrorCodeWithToken(
                  token, codeExtraneousModifier);
            } else if (optional("const", token)) {
              if (getOrSet != null) {
                reportRecoverableErrorCodeWithToken(
                    token, codeExtraneousModifier);
                continue;
              }
            } else if (optional("external", token)) {
              externalModifier = token;
            } else if (optional("static", token)) {
              staticModifier = token;
            } else if (optional("covariant", token)) {
              if (staticModifier != null ||
                  getOrSet == null ||
                  optional("get", getOrSet)) {
                reportRecoverableErrorCodeWithToken(
                    token, codeExtraneousModifier);
                continue;
              }
            }
          } else {
            reportRecoverableErrorCodeWithToken(token, codeExtraneousModifier);
            continue;
          }
        } else {
          reportUnexpectedToken(token);
          break; // Skip the remaining modifiers.
        }
        parseModifier(token);
        count++;
      }
      listener.handleModifiers(count);
    }

    parseModifierList(modifiers);

    if (type == null) {
      listener.handleNoType(name);
    } else {
      parseReturnTypeOpt(type);
    }
    Token token;
    if (optional('operator', name)) {
      token = parseOperatorName(name);
      if (staticModifier != null) {
        reportRecoverableErrorCodeWithToken(
            staticModifier, codeExtraneousModifier);
      }
    } else {
      token = parseIdentifier(name, IdentifierContext.methodDeclaration);
    }

    token = parseQualifiedRestOpt(
        token, IdentifierContext.methodDeclarationContinuation);
    bool isGetter = false;
    if (getOrSet == null) {
      token = parseTypeVariablesOpt(token);
    } else {
      isGetter = optional("get", getOrSet);
      listener.handleNoTypeVariables(token);
    }
    checkFormals(isGetter, name, token);
    token = parseFormalParametersOpt(
        token,
        staticModifier != null
            ? MemberKind.StaticMethod
            : MemberKind.NonStaticMethod);
    token = parseInitializersOpt(token);
    AsyncModifier savedAsyncModifier = asyncState;
    Token asyncToken = token;
    token = parseAsyncModifier(token);
    if (getOrSet != null && !inPlainSync && optional("set", getOrSet)) {
      reportRecoverableErrorCode(asyncToken, codeSetterNotSync);
    }
    if (optional('=', token)) {
      token = parseRedirectingFactoryBody(token);
    } else {
      token = parseFunctionBody(
          token, false, staticModifier == null || externalModifier != null);
    }
    asyncState = savedAsyncModifier;
    listener.endMethod(getOrSet, start, token);
    return token.next;
  }

  Token parseFactoryMethod(Token token) {
    assert(isFactoryDeclaration(token));
    Token start = token;
    bool isExternal = false;
    int modifierCount = 0;
    while (isModifier(token)) {
      if (optional('external', token)) {
        isExternal = true;
      }
      token = parseModifier(token);
      modifierCount++;
    }
    listener.handleModifiers(modifierCount);
    Token factoryKeyword = token;
    listener.beginFactoryMethod(factoryKeyword);
    token = expect('factory', token);
    token = parseConstructorReference(token);
    token = parseFormalParameters(token, MemberKind.Factory);
    Token asyncToken = token;
    token = parseAsyncModifier(token);
    if (!inPlainSync) {
      reportRecoverableErrorCode(asyncToken, codeFactoryNotSync);
    }
    if (optional('=', token)) {
      token = parseRedirectingFactoryBody(token);
    } else {
      token = parseFunctionBody(token, false, isExternal);
    }
    listener.endFactoryMethod(start, factoryKeyword, token);
    return token.next;
  }

  Token parseOperatorName(Token token) {
    assert(optional('operator', token));
    if (isUserDefinableOperator(token.next.stringValue)) {
      Token operator = token;
      token = token.next;
      listener.handleOperatorName(operator, token);
      return token.next;
    } else {
      return parseIdentifier(token, IdentifierContext.operatorName);
    }
  }

  Token parseFunction(Token token) {
    Token beginToken = token;
    listener.beginFunction(token);
    token = parseModifiers(token, MemberKind.Local);
    listener.beginFunctionName(token);
    token = parseIdentifier(token, IdentifierContext.localFunctionDeclaration);
    token = parseQualifiedRestOpt(
        token, IdentifierContext.localFunctionDeclarationContinuation);
    listener.endFunctionName(beginToken, token);
    token = parseTypeVariablesOpt(token);
    token = parseFormalParametersOpt(token, MemberKind.Local);
    token = parseInitializersOpt(token);
    AsyncModifier savedAsyncModifier = asyncState;
    token = parseAsyncModifier(token);
    token = parseFunctionBody(token, false, true);
    asyncState = savedAsyncModifier;
    listener.endFunction(null, token);
    return token.next;
  }

  Token parseUnnamedFunction(Token token) {
    Token beginToken = token;
    listener.beginUnnamedFunction(token);
    token = parseFormalParameters(token, MemberKind.Local);
    AsyncModifier savedAsyncModifier = asyncState;
    token = parseAsyncModifier(token);
    bool isBlock = optional('{', token);
    token = parseFunctionBody(token, true, false);
    asyncState = savedAsyncModifier;
    listener.endUnnamedFunction(beginToken, token);
    return isBlock ? token.next : token;
  }

  Token parseFunctionDeclaration(Token token) {
    listener.beginFunctionDeclaration(token);
    token = parseFunction(token);
    listener.endFunctionDeclaration(token);
    return token;
  }

  Token parseFunctionExpression(Token token) {
    Token beginToken = token;
    listener.beginFunction(token);
    listener.handleModifiers(0);
    token = parseReturnTypeOpt(token);
    listener.beginFunctionName(token);
    token = parseIdentifier(token, IdentifierContext.functionExpressionName);
    listener.endFunctionName(beginToken, token);
    token = parseTypeVariablesOpt(token);
    token = parseFormalParameters(token, MemberKind.Local);
    listener.handleNoInitializers();
    AsyncModifier savedAsyncModifier = asyncState;
    token = parseAsyncModifier(token);
    bool isBlock = optional('{', token);
    token = parseFunctionBody(token, true, false);
    asyncState = savedAsyncModifier;
    listener.endFunction(null, token);
    return isBlock ? token.next : token;
  }

  Token parseConstructorReference(Token token) {
    Token start = token;
    listener.beginConstructorReference(start);
    token = parseIdentifier(token, IdentifierContext.constructorReference);
    token = parseQualifiedRestOpt(
        token, IdentifierContext.constructorReferenceContinuation);
    token = parseTypeArgumentsOpt(token);
    Token period = null;
    if (optional('.', token)) {
      period = token;
      token = parseIdentifier(token.next,
          IdentifierContext.constructorReferenceContinuationAfterTypeArguments);
    } else {
      listener
          .handleNoConstructorReferenceContinuationAfterTypeArguments(token);
    }
    listener.endConstructorReference(start, period, token);
    return token;
  }

  Token parseRedirectingFactoryBody(Token token) {
    listener.beginRedirectingFactoryBody(token);
    assert(optional('=', token));
    Token equals = token;
    token = parseConstructorReference(token.next);
    Token semicolon = token;
    expectSemicolon(token);
    listener.endRedirectingFactoryBody(equals, semicolon);
    return token;
  }

  Token skipFunctionBody(Token token, bool isExpression, bool allowAbstract) {
    assert(!isExpression);
    token = skipAsyncModifier(token);
    String value = token.stringValue;
    if (identical(value, ';')) {
      if (!allowAbstract) {
        reportRecoverableErrorCode(token, codeExpectedBody);
      }
      listener.handleNoFunctionBody(token);
    } else {
      if (identical(value, '=>')) {
        token = parseExpression(token.next);
        expectSemicolon(token);
        listener.handleFunctionBodySkipped(token, true);
      } else if (identical(value, '=')) {
        reportRecoverableErrorCode(token, codeExpectedBody);
        token = parseExpression(token.next);
        expectSemicolon(token);
        listener.handleFunctionBodySkipped(token, true);
      } else {
        token = skipBlock(token);
        listener.handleFunctionBodySkipped(token, false);
      }
    }
    return token;
  }

  Token parseFunctionBody(Token token, bool isExpression, bool allowAbstract) {
    if (optional(';', token)) {
      if (!allowAbstract) {
        reportRecoverableErrorCode(token, codeExpectedBody);
      }
      listener.handleEmptyFunctionBody(token);
      return token;
    } else if (optional('=>', token)) {
      Token begin = token;
      token = parseExpression(token.next);
      if (!isExpression) {
        expectSemicolon(token);
        listener.handleExpressionFunctionBody(begin, token);
      } else {
        listener.handleExpressionFunctionBody(begin, null);
      }
      return token;
    } else if (optional('=', token)) {
      Token begin = token;
      // Recover from a bad factory method.
      reportRecoverableErrorCode(token, codeExpectedBody);
      token = parseExpression(token.next);
      if (!isExpression) {
        expectSemicolon(token);
        listener.handleExpressionFunctionBody(begin, token);
      } else {
        listener.handleExpressionFunctionBody(begin, null);
      }
      return token;
    }
    Token begin = token;
    int statementCount = 0;
    if (!optional('{', token)) {
      token =
          reportUnrecoverableErrorCodeWithToken(token, codeExpectedFunctionBody)
              .next;
      listener.handleInvalidFunctionBody(token);
      return token;
    }

    listener.beginBlockFunctionBody(begin);
    token = token.next;
    while (notEofOrValue('}', token)) {
      token = parseStatement(token);
      ++statementCount;
    }
    listener.endBlockFunctionBody(statementCount, begin, token);
    expect('}', token);
    return token;
  }

  Token skipAsyncModifier(Token token) {
    String value = token.stringValue;
    if (identical(value, 'async')) {
      token = token.next;
      value = token.stringValue;

      if (identical(value, '*')) {
        token = token.next;
      }
    } else if (identical(value, 'sync')) {
      token = token.next;
      value = token.stringValue;

      if (identical(value, '*')) {
        token = token.next;
      }
    }
    return token;
  }

  Token parseAsyncModifier(Token token) {
    Token async;
    Token star;
    asyncState = AsyncModifier.Sync;
    if (optional('async', token)) {
      async = token;
      token = token.next;
      if (optional('*', token)) {
        asyncState = AsyncModifier.AsyncStar;
        star = token;
        token = token.next;
      } else {
        asyncState = AsyncModifier.Async;
      }
    } else if (optional('sync', token)) {
      async = token;
      token = token.next;
      if (optional('*', token)) {
        asyncState = AsyncModifier.SyncStar;
        star = token;
        token = token.next;
      } else {
        reportRecoverableErrorCode(async, codeInvalidSyncModifier);
      }
    }
    listener.handleAsyncModifier(async, star);
    if (inGenerator && optional('=>', token)) {
      reportRecoverableErrorCode(token, codeGeneratorReturnsValue);
    } else if (!inPlainSync && optional(';', token)) {
      reportRecoverableErrorCode(token, codeAbstractNotSync);
    }
    return token;
  }

  int statementDepth = 0;
  Token parseStatement(Token token) {
    if (statementDepth++ > 500) {
      // This happens for degenerate programs, for example, a lot of nested
      // if-statements. The language test deep_nesting2_negative_test, for
      // example, provokes this.
      return reportUnrecoverableErrorCode(token, codeStackOverflow).next;
    }
    Token result = parseStatementX(token);
    statementDepth--;
    return result;
  }

  Token parseStatementX(Token token) {
    final value = token.stringValue;
    if (identical(token.kind, IDENTIFIER_TOKEN)) {
      return parseExpressionStatementOrDeclaration(token);
    } else if (identical(value, '{')) {
      return parseBlock(token);
    } else if (identical(value, 'return')) {
      return parseReturnStatement(token);
    } else if (identical(value, 'var') || identical(value, 'final')) {
      return parseVariablesDeclaration(token);
    } else if (identical(value, 'if')) {
      return parseIfStatement(token);
    } else if (identical(value, 'await') && optional('for', token.next)) {
      if (!inAsync) {
        reportRecoverableErrorCode(token, codeAwaitForNotAsync);
      }
      return parseForStatement(token, token.next);
    } else if (identical(value, 'for')) {
      return parseForStatement(null, token);
    } else if (identical(value, 'rethrow')) {
      return parseRethrowStatement(token);
    } else if (identical(value, 'throw') && optional(';', token.next)) {
      // TODO(kasperl): Stop dealing with throw here.
      return parseRethrowStatement(token);
    } else if (identical(value, 'void')) {
      return parseExpressionStatementOrDeclaration(token);
    } else if (identical(value, 'while')) {
      return parseWhileStatement(token);
    } else if (identical(value, 'do')) {
      return parseDoWhileStatement(token);
    } else if (identical(value, 'try')) {
      return parseTryStatement(token);
    } else if (identical(value, 'switch')) {
      return parseSwitchStatement(token);
    } else if (identical(value, 'break')) {
      return parseBreakStatement(token);
    } else if (identical(value, 'continue')) {
      return parseContinueStatement(token);
    } else if (identical(value, 'assert')) {
      return parseAssertStatement(token);
    } else if (identical(value, ';')) {
      return parseEmptyStatement(token);
    } else if (identical(value, 'yield')) {
      switch (asyncState) {
        case AsyncModifier.Sync:
          return parseExpressionStatementOrDeclaration(token);

        case AsyncModifier.SyncStar:
        case AsyncModifier.AsyncStar:
          return parseYieldStatement(token);

        case AsyncModifier.Async:
          reportRecoverableErrorCode(token, codeYieldNotGenerator);
          return parseYieldStatement(token);
      }
      throw "Internal error: Unknown asyncState: '$asyncState'.";
    } else if (identical(value, 'const')) {
      return parseExpressionStatementOrConstDeclaration(token);
    } else if (token.isIdentifier) {
      return parseExpressionStatementOrDeclaration(token);
    } else if (identical(value, '@')) {
      return parseVariablesDeclaration(token);
    } else {
      return parseExpressionStatement(token);
    }
  }

  Token parseYieldStatement(Token token) {
    Token begin = token;
    listener.beginYieldStatement(begin);
    assert(identical('yield', token.stringValue));
    token = token.next;
    Token starToken;
    if (optional('*', token)) {
      starToken = token;
      token = token.next;
    }
    token = parseExpression(token);
    listener.endYieldStatement(begin, starToken, token);
    return expectSemicolon(token);
  }

  Token parseReturnStatement(Token token) {
    Token begin = token;
    listener.beginReturnStatement(begin);
    assert(identical('return', token.stringValue));
    token = token.next;
    if (optional(';', token)) {
      listener.endReturnStatement(false, begin, token);
    } else {
      token = parseExpression(token);
      if (inGenerator) {
        reportRecoverableErrorCode(begin.next, codeGeneratorReturnsValue);
      }
      listener.endReturnStatement(true, begin, token);
    }
    return expectSemicolon(token);
  }

  Token peekIdentifierAfterType(Token token) {
    Token peek = peekAfterType(token);
    if (peek != null && peek.isIdentifier) {
      // We are looking at "type identifier".
      return peek;
    } else {
      return null;
    }
  }

  Token peekIdentifierAfterOptionalType(Token token) {
    Token peek = peekAfterIfType(token);
    if (peek != null && peek.isIdentifier) {
      // We are looking at "type identifier".
      return peek;
    } else if (token.isIdentifier) {
      // We are looking at "identifier".
      return token;
    } else {
      return null;
    }
  }

  Token parseExpressionStatementOrDeclaration(Token token) {
    if (!inPlainSync && optional("await", token)) {
      return parseExpressionStatement(token);
    }
    assert(token.isIdentifier || identical(token.stringValue, 'void'));
    Token identifier = peekIdentifierAfterType(token);
    if (identifier != null) {
      assert(identifier.isIdentifier);

      // If the identifier token has a type substitution comment /*=T*/,
      // then the set of tokens type tokens should be replaced with the
      // tokens parsed from the comment.
      token =
          listener.replaceTokenWithGenericCommentTypeAssign(token, identifier);

      Token afterId = identifier.next;
      int afterIdKind = afterId.kind;
      if (identical(afterIdKind, EQ_TOKEN) ||
          identical(afterIdKind, SEMICOLON_TOKEN) ||
          identical(afterIdKind, COMMA_TOKEN)) {
        // We are looking at "type identifier" followed by '=', ';', ','.
        return parseVariablesDeclaration(token);
      } else if (identical(afterIdKind, OPEN_PAREN_TOKEN)) {
        // We are looking at "type identifier '('".
        BeginToken beginParen = afterId;
        Token endParen = beginParen.endGroup;
        // TODO(eernst): Check for NPE as described in issue 26252.
        Token afterParens = endParen.next;
        if (optional('{', afterParens) ||
            optional('=>', afterParens) ||
            optional('async', afterParens) ||
            optional('sync', afterParens)) {
          // We are looking at "type identifier '(' ... ')'" followed
          // by '{', '=>', 'async', or 'sync'.
          return parseFunctionDeclaration(token);
        }
      } else if (identical(afterIdKind, LT_TOKEN)) {
        // We are looking at "type identifier '<'".
        BeginToken beginAngle = afterId;
        Token endAngle = beginAngle.endGroup;
        if (endAngle != null &&
            identical(endAngle.next.kind, OPEN_PAREN_TOKEN)) {
          BeginToken beginParen = endAngle.next;
          Token endParen = beginParen.endGroup;
          if (endParen != null) {
            Token afterParens = endParen.next;
            if (optional('{', afterParens) ||
                optional('=>', afterParens) ||
                optional('async', afterParens) ||
                optional('sync', afterParens)) {
              // We are looking at "type identifier '<' ... '>' '(' ... ')'"
              // followed by '{', '=>', 'async', or 'sync'.
              return parseFunctionDeclaration(token);
            }
          }
        }
      }
      // Fall-through to expression statement.
    } else {
      if (optional(':', token.next)) {
        return parseLabeledStatement(token);
      } else if (optional('(', token.next)) {
        BeginToken begin = token.next;
        // TODO(eernst): Check for NPE as described in issue 26252.
        String afterParens = begin.endGroup.next.stringValue;
        if (identical(afterParens, '{') ||
            identical(afterParens, '=>') ||
            identical(afterParens, 'async') ||
            identical(afterParens, 'sync')) {
          return parseFunctionDeclaration(token);
        }
      } else if (optional('<', token.next)) {
        BeginToken beginAngle = token.next;
        Token endAngle = beginAngle.endGroup;
        if (endAngle != null &&
            identical(endAngle.next.kind, OPEN_PAREN_TOKEN)) {
          BeginToken beginParen = endAngle.next;
          Token endParen = beginParen.endGroup;
          if (endParen != null) {
            String afterParens = endParen.next.stringValue;
            if (identical(afterParens, '{') ||
                identical(afterParens, '=>') ||
                identical(afterParens, 'async') ||
                identical(afterParens, 'sync')) {
              return parseFunctionDeclaration(token);
            }
          }
        }
        // Fall through to expression statement.
      }
    }
    return parseExpressionStatement(token);
  }

  Token parseExpressionStatementOrConstDeclaration(Token token) {
    assert(identical(token.stringValue, 'const'));
    if (isModifier(token.next)) {
      return parseVariablesDeclaration(token);
    }
    listener.injectGenericCommentTypeAssign(token.next);
    Token identifier = peekIdentifierAfterOptionalType(token.next);
    if (identifier != null) {
      assert(identifier.isIdentifier);
      Token afterId = identifier.next;
      int afterIdKind = afterId.kind;
      if (identical(afterIdKind, EQ_TOKEN) ||
          identical(afterIdKind, SEMICOLON_TOKEN) ||
          identical(afterIdKind, COMMA_TOKEN)) {
        // We are looking at "const type identifier" followed by '=', ';', or
        // ','.
        return parseVariablesDeclaration(token);
      }
      // Fall-through to expression statement.
    }

    return parseExpressionStatement(token);
  }

  Token parseLabel(Token token) {
    token = parseIdentifier(token, IdentifierContext.labelDeclaration);
    Token colon = token;
    token = expect(':', token);
    listener.handleLabel(colon);
    return token;
  }

  Token parseLabeledStatement(Token token) {
    int labelCount = 0;
    do {
      token = parseLabel(token);
      labelCount++;
    } while (token.isIdentifier && optional(':', token.next));
    listener.beginLabeledStatement(token, labelCount);
    token = parseStatement(token);
    listener.endLabeledStatement(labelCount);
    return token;
  }

  Token parseExpressionStatement(Token token) {
    listener.beginExpressionStatement(token);
    token = parseExpression(token);
    listener.endExpressionStatement(token);
    return expectSemicolon(token);
  }

  Token skipExpression(Token token) {
    while (true) {
      final kind = token.kind;
      final value = token.stringValue;
      if ((identical(kind, EOF_TOKEN)) ||
          (identical(value, ';')) ||
          (identical(value, ',')) ||
          (identical(value, '}')) ||
          (identical(value, ')')) ||
          (identical(value, ']'))) {
        break;
      }
      if (identical(value, '=') ||
          identical(value, '?') ||
          identical(value, ':') ||
          identical(value, '??')) {
        var nextValue = token.next.stringValue;
        if (identical(nextValue, 'const')) {
          token = token.next;
          nextValue = token.next.stringValue;
        }
        if (identical(nextValue, '{')) {
          // Handle cases like this:
          // class Foo {
          //   var map;
          //   Foo() : map = {};
          //   Foo.x() : map = true ? {} : {};
          // }
          BeginToken begin = token.next;
          token = (begin.endGroup != null) ? begin.endGroup : token;
          token = token.next;
          continue;
        }
        if (identical(nextValue, '<')) {
          // Handle cases like this:
          // class Foo {
          //   var map;
          //   Foo() : map = <String, Foo>{};
          //   Foo.x() : map = true ? <String, Foo>{} : <String, Foo>{};
          // }
          BeginToken begin = token.next;
          token = (begin.endGroup != null) ? begin.endGroup : token;
          token = token.next;
          if (identical(token.stringValue, '{')) {
            begin = token;
            token = (begin.endGroup != null) ? begin.endGroup : token;
            token = token.next;
          }
          continue;
        }
      }
      if (!mayParseFunctionExpressions && identical(value, '{')) {
        break;
      }
      if (token is BeginToken) {
        BeginToken begin = token;
        token = (begin.endGroup != null) ? begin.endGroup : token;
      } else if (token is ErrorToken) {
        reportErrorToken(token, false).next;
      }
      token = token.next;
    }
    return token;
  }

  Token parseRecoverExpression(Token token, FastaMessage message) =>
      parseExpression(token);

  int expressionDepth = 0;
  Token parseExpression(Token token) {
    if (expressionDepth++ > 500) {
      // This happens in degenerate programs, for example, with a lot of nested
      // list literals. This is provoked by, for examaple, the language test
      // deep_nesting1_negative_test.
      return reportUnrecoverableErrorCode(token, codeStackOverflow).next;
    }
    listener.beginExpression(token);
    Token result = optional('throw', token)
        ? parseThrowExpression(token, true)
        : parsePrecedenceExpression(token, ASSIGNMENT_PRECEDENCE, true);
    expressionDepth--;
    return result;
  }

  Token parseExpressionWithoutCascade(Token token) {
    listener.beginExpression(token);
    return optional('throw', token)
        ? parseThrowExpression(token, false)
        : parsePrecedenceExpression(token, ASSIGNMENT_PRECEDENCE, false);
  }

  Token parseConditionalExpressionRest(Token token) {
    assert(optional('?', token));
    Token question = token;
    token = parseExpressionWithoutCascade(token.next);
    Token colon = token;
    token = expect(':', token);
    token = parseExpressionWithoutCascade(token);
    listener.handleConditionalExpression(question, colon);
    return token;
  }

  Token parsePrecedenceExpression(
      Token token, int precedence, bool allowCascades) {
    assert(precedence >= 1);
    assert(precedence <= POSTFIX_PRECEDENCE);
    token = parseUnaryExpression(token, allowCascades);
    TokenType type = token.type;
    int tokenLevel = type.precedence;
    for (int level = tokenLevel; level >= precedence; --level) {
      while (identical(tokenLevel, level)) {
        Token operator = token;
        if (identical(tokenLevel, CASCADE_PRECEDENCE)) {
          if (!allowCascades) {
            return token;
          }
          token = parseCascadeExpression(token);
        } else if (identical(tokenLevel, ASSIGNMENT_PRECEDENCE)) {
          // Right associative, so we recurse at the same precedence
          // level.
          listener.beginExpression(token.next);
          token = parsePrecedenceExpression(token.next, level, allowCascades);
          listener.handleAssignmentExpression(operator);
        } else if (identical(tokenLevel, POSTFIX_PRECEDENCE)) {
          if (identical(type, TokenType.PERIOD) ||
              identical(type, TokenType.QUESTION_PERIOD)) {
            // Left associative, so we recurse at the next higher precedence
            // level. However, POSTFIX_PRECEDENCE is the highest level, so we
            // should just call [parseUnaryExpression] directly. However, a
            // unary expression isn't legal after a period, so we call
            // [parsePrimary] instead.
            token = parsePrimary(
                token.next, IdentifierContext.expressionContinuation);
            listener.handleBinaryExpression(operator);
          } else if ((identical(type, TokenType.OPEN_PAREN)) ||
              (identical(type, TokenType.OPEN_SQUARE_BRACKET))) {
            token = parseArgumentOrIndexStar(token);
          } else if ((identical(type, TokenType.PLUS_PLUS)) ||
              (identical(type, TokenType.MINUS_MINUS))) {
            listener.handleUnaryPostfixAssignmentExpression(token);
            token = token.next;
          } else {
            token = reportUnexpectedToken(token).next;
          }
        } else if (identical(type, TokenType.IS)) {
          token = parseIsOperatorRest(token);
        } else if (identical(type, TokenType.AS)) {
          token = parseAsOperatorRest(token);
        } else if (identical(type, TokenType.QUESTION)) {
          token = parseConditionalExpressionRest(token);
        } else {
          // Left associative, so we recurse at the next higher
          // precedence level.
          listener.beginExpression(token.next);
          token =
              parsePrecedenceExpression(token.next, level + 1, allowCascades);
          listener.handleBinaryExpression(operator);
        }
        type = token.type;
        tokenLevel = type.precedence;
        if (level == EQUALITY_PRECEDENCE || level == RELATIONAL_PRECEDENCE) {
          // We don't allow (a == b == c) or (a < b < c).
          // Continue the outer loop if we have matched one equality or
          // relational operator.
          break;
        }
      }
    }
    return token;
  }

  Token parseCascadeExpression(Token token) {
    listener.beginCascade(token);
    assert(optional('..', token));
    Token cascadeOperator = token;
    token = token.next;
    if (optional('[', token)) {
      token = parseArgumentOrIndexStar(token);
    } else if (token.isIdentifier) {
      token = parseSend(token, IdentifierContext.expressionContinuation);
      listener.handleBinaryExpression(cascadeOperator);
    } else {
      return reportUnexpectedToken(token).next;
    }
    Token mark;
    do {
      mark = token;
      if (optional('.', token)) {
        Token period = token;
        token = parseSend(token.next, IdentifierContext.expressionContinuation);
        listener.handleBinaryExpression(period);
      }
      token = parseArgumentOrIndexStar(token);
    } while (!identical(mark, token));

    if (identical(token.type.precedence, ASSIGNMENT_PRECEDENCE)) {
      Token assignment = token;
      token = parseExpressionWithoutCascade(token.next);
      listener.handleAssignmentExpression(assignment);
    }
    listener.endCascade();
    return token;
  }

  Token parseUnaryExpression(Token token, bool allowCascades) {
    String value = token.stringValue;
    // Prefix:
    if (optional('await', token)) {
      if (inPlainSync) {
        return parsePrimary(token, IdentifierContext.expression);
      } else {
        return parseAwaitExpression(token, allowCascades);
      }
    } else if (identical(value, '+')) {
      // Dart no longer allows prefix-plus.
      reportRecoverableErrorCode(token, codeUnsupportedPrefixPlus);
      return parseUnaryExpression(token.next, allowCascades);
    } else if ((identical(value, '!')) ||
        (identical(value, '-')) ||
        (identical(value, '~'))) {
      Token operator = token;
      // Right associative, so we recurse at the same precedence
      // level.
      token = parsePrecedenceExpression(
          token.next, POSTFIX_PRECEDENCE, allowCascades);
      listener.handleUnaryPrefixExpression(operator);
      return token;
    } else if ((identical(value, '++')) || identical(value, '--')) {
      // TODO(ahe): Validate this is used correctly.
      Token operator = token;
      // Right associative, so we recurse at the same precedence
      // level.
      token = parsePrecedenceExpression(
          token.next, POSTFIX_PRECEDENCE, allowCascades);
      listener.handleUnaryPrefixAssignmentExpression(operator);
      return token;
    } else {
      return parsePrimary(token, IdentifierContext.expression);
    }
  }

  Token parseArgumentOrIndexStar(Token token) {
    Token beginToken = token;
    while (true) {
      if (optional('[', token)) {
        Token openSquareBracket = token;
        bool old = mayParseFunctionExpressions;
        mayParseFunctionExpressions = true;
        token = parseExpression(token.next);
        mayParseFunctionExpressions = old;
        listener.handleIndexedExpression(openSquareBracket, token);
        token = expect(']', token);
      } else if (optional('(', token)) {
        listener.handleNoTypeArguments(token);
        token = parseArguments(token);
        listener.endSend(beginToken, token);
      } else {
        break;
      }
    }
    return token;
  }

  Token parsePrimary(Token token, IdentifierContext context) {
    token = listener.injectGenericCommentTypeList(token);
    final kind = token.kind;
    if (kind == IDENTIFIER_TOKEN) {
      return parseSendOrFunctionLiteral(token, context);
    } else if (kind == INT_TOKEN || kind == HEXADECIMAL_TOKEN) {
      return parseLiteralInt(token);
    } else if (kind == DOUBLE_TOKEN) {
      return parseLiteralDouble(token);
    } else if (kind == STRING_TOKEN) {
      return parseLiteralString(token);
    } else if (kind == HASH_TOKEN) {
      return parseLiteralSymbol(token);
    } else if (kind == KEYWORD_TOKEN) {
      final String value = token.stringValue;
      if (identical(value, "true") || identical(value, "false")) {
        return parseLiteralBool(token);
      } else if (identical(value, "null")) {
        return parseLiteralNull(token);
      } else if (identical(value, "this")) {
        return parseThisExpression(token, context);
      } else if (identical(value, "super")) {
        return parseSuperExpression(token, context);
      } else if (identical(value, "new")) {
        return parseNewExpression(token);
      } else if (identical(value, "const")) {
        return parseConstExpression(token);
      } else if (identical(value, "void")) {
        return parseFunctionExpression(token);
      } else if (!inPlainSync &&
          (identical(value, "yield") || identical(value, "async"))) {
        return expressionExpected(token);
      } else if (identical(value, "assert")) {
        return parseAssert(token, Assert.Expression);
      } else if (token.isIdentifier) {
        return parseSendOrFunctionLiteral(token, context);
      } else {
        return expressionExpected(token);
      }
    } else if (kind == OPEN_PAREN_TOKEN) {
      return parseParenthesizedExpressionOrFunctionLiteral(token);
    } else if (kind == OPEN_SQUARE_BRACKET_TOKEN || optional('[]', token)) {
      listener.handleNoTypeArguments(token);
      return parseLiteralListSuffix(token, null);
    } else if (kind == OPEN_CURLY_BRACKET_TOKEN) {
      listener.handleNoTypeArguments(token);
      return parseLiteralMapSuffix(token, null);
    } else if (kind == LT_TOKEN) {
      return parseLiteralListOrMapOrFunction(token, null);
    } else {
      return expressionExpected(token);
    }
  }

  Token expressionExpected(Token token) {
    token = reportUnrecoverableErrorCodeWithToken(token, codeExpectedExpression)
        .next;
    listener.handleInvalidExpression(token);
    return token;
  }

  Token parseParenthesizedExpressionOrFunctionLiteral(Token token) {
    BeginToken beginGroup = token;
    // TODO(eernst): Check for NPE as described in issue 26252.
    Token nextToken = beginGroup.endGroup.next;
    int kind = nextToken.kind;
    if (mayParseFunctionExpressions &&
        (identical(kind, FUNCTION_TOKEN) ||
            identical(kind, OPEN_CURLY_BRACKET_TOKEN) ||
            (identical(kind, KEYWORD_TOKEN) &&
                (optional('async', nextToken) ||
                    optional('sync', nextToken))))) {
      listener.handleNoTypeVariables(token);
      return parseUnnamedFunction(token);
    } else {
      bool old = mayParseFunctionExpressions;
      mayParseFunctionExpressions = true;
      token = parseParenthesizedExpression(token);
      mayParseFunctionExpressions = old;
      return token;
    }
  }

  Token parseParenthesizedExpression(Token token) {
    // We expect [begin] to be of type [BeginToken], but we don't know for
    // sure until after calling expect.
    dynamic begin = token;
    token = expect('(', token);
    // [begin] is now known to have type [BeginToken].
    token = parseExpression(token);
    if (!identical(begin.endGroup, token)) {
      reportUnexpectedToken(token).next;
      token = begin.endGroup;
    }
    listener.handleParenthesizedExpression(begin);
    return expect(')', token);
  }

  Token parseThisExpression(Token token, IdentifierContext context) {
    Token beginToken = token;
    listener.handleThisExpression(token, context);
    token = token.next;
    if (optional('(', token)) {
      // Constructor forwarding.
      listener.handleNoTypeArguments(token);
      token = parseArguments(token);
      listener.endSend(beginToken, token);
    }
    return token;
  }

  Token parseSuperExpression(Token token, IdentifierContext context) {
    Token beginToken = token;
    listener.handleSuperExpression(token, context);
    token = token.next;
    if (optional('(', token)) {
      // Super constructor.
      listener.handleNoTypeArguments(token);
      token = parseArguments(token);
      listener.endSend(beginToken, token);
    } else if (optional("?.", token)) {
      reportRecoverableErrorCode(token, codeSuperNullAware);
    }
    return token;
  }

  /// '[' (expressionList ','?)? ']'.
  ///
  /// Provide [constKeyword] if preceded by 'const', null if not.
  /// This is a suffix parser because it is assumed that type arguments have
  /// been parsed, or `listener.handleNoTypeArguments(..)` has been executed.
  Token parseLiteralListSuffix(Token token, Token constKeyword) {
    assert(optional('[', token) || optional('[]', token));
    Token beginToken = token;
    int count = 0;
    if (optional('[', token)) {
      bool old = mayParseFunctionExpressions;
      mayParseFunctionExpressions = true;
      do {
        if (optional(']', token.next)) {
          token = token.next;
          break;
        }
        token = parseExpression(token.next);
        ++count;
      } while (optional(',', token));
      mayParseFunctionExpressions = old;
      listener.handleLiteralList(count, beginToken, constKeyword, token);
      return expect(']', token);
    }
    // Looking at '[]'.
    listener.handleLiteralList(0, token, constKeyword, token);
    return token.next;
  }

  /// '{' (mapLiteralEntry (',' mapLiteralEntry)* ','?)? '}'.
  ///
  /// Provide token for [constKeyword] if preceded by 'const', null if not.
  /// This is a suffix parser because it is assumed that type arguments have
  /// been parsed, or `listener.handleNoTypeArguments(..)` has been executed.
  Token parseLiteralMapSuffix(Token token, Token constKeyword) {
    assert(optional('{', token));
    Token beginToken = token;
    int count = 0;
    bool old = mayParseFunctionExpressions;
    mayParseFunctionExpressions = true;
    do {
      if (optional('}', token.next)) {
        token = token.next;
        break;
      }
      token = parseMapLiteralEntry(token.next);
      ++count;
    } while (optional(',', token));
    mayParseFunctionExpressions = old;
    listener.handleLiteralMap(count, beginToken, constKeyword, token);
    return expect('}', token);
  }

  /// formalParameterList functionBody.
  ///
  /// This is a suffix parser because it is assumed that type arguments have
  /// been parsed, or `listener.handleNoTypeArguments(..)` has been executed.
  Token parseLiteralFunctionSuffix(Token token) {
    assert(optional('(', token));
    BeginToken beginGroup = token;
    if (beginGroup.endGroup != null) {
      Token nextToken = beginGroup.endGroup.next;
      int kind = nextToken.kind;
      if (identical(kind, FUNCTION_TOKEN) ||
          identical(kind, OPEN_CURLY_BRACKET_TOKEN) ||
          (identical(kind, KEYWORD_TOKEN) &&
              (optional('async', nextToken) || optional('sync', nextToken)))) {
        return parseUnnamedFunction(token);
      }
      // Fall through.
    }
    return reportUnexpectedToken(token).next;
  }

  /// genericListLiteral | genericMapLiteral | genericFunctionLiteral.
  ///
  /// Where
  ///   genericListLiteral ::= typeArguments '[' (expressionList ','?)? ']'
  ///   genericMapLiteral ::=
  ///       typeArguments '{' (mapLiteralEntry (',' mapLiteralEntry)* ','?)? '}'
  ///   genericFunctionLiteral ::=
  ///       typeParameters formalParameterList functionBody
  /// Provide token for [constKeyword] if preceded by 'const', null if not.
  Token parseLiteralListOrMapOrFunction(Token token, Token constKeyword) {
    assert(optional('<', token));
    BeginToken begin = token;
    if (constKeyword == null &&
        begin.endGroup != null &&
        identical(begin.endGroup.next.kind, OPEN_PAREN_TOKEN)) {
      token = parseTypeVariablesOpt(token);
      return parseLiteralFunctionSuffix(token);
    } else {
      token = parseTypeArgumentsOpt(token);
      if (optional('{', token)) {
        return parseLiteralMapSuffix(token, constKeyword);
      } else if ((optional('[', token)) || (optional('[]', token))) {
        return parseLiteralListSuffix(token, constKeyword);
      }
      return reportUnexpectedToken(token).next;
    }
  }

  Token parseMapLiteralEntry(Token token) {
    listener.beginLiteralMapEntry(token);
    // Assume the listener rejects non-string keys.
    token = parseExpression(token);
    Token colon = token;
    token = expect(':', token);
    token = parseExpression(token);
    listener.endLiteralMapEntry(colon, token);
    return token;
  }

  Token parseSendOrFunctionLiteral(Token token, IdentifierContext context) {
    if (!mayParseFunctionExpressions) {
      return parseSend(token, context);
    }
    Token peek = peekAfterIfType(token);
    if (peek != null &&
        identical(peek.kind, IDENTIFIER_TOKEN) &&
        isFunctionDeclaration(peek.next)) {
      return parseFunctionExpression(token);
    } else if (isFunctionDeclaration(token.next)) {
      return parseFunctionExpression(token);
    } else {
      return parseSend(token, context);
    }
  }

  bool isFunctionDeclaration(Token token) {
    if (optional('<', token)) {
      BeginToken begin = token;
      if (begin.endGroup == null) return false;
      token = begin.endGroup.next;
    }
    if (optional('(', token)) {
      BeginToken begin = token;
      // TODO(eernst): Check for NPE as described in issue 26252.
      String afterParens = begin.endGroup.next.stringValue;
      if (identical(afterParens, '{') ||
          identical(afterParens, '=>') ||
          identical(afterParens, 'async') ||
          identical(afterParens, 'sync')) {
        return true;
      }
    }
    return false;
  }

  Token parseRequiredArguments(Token token) {
    if (optional('(', token)) {
      token = parseArguments(token);
    } else {
      listener.handleNoArguments(token);
      token = reportUnexpectedToken(token).next;
    }
    return token;
  }

  Token parseNewExpression(Token token) {
    Token newKeyword = token;
    token = expect('new', token);
    listener.beginNewExpression(newKeyword);
    token = parseConstructorReference(token);
    token = parseRequiredArguments(token);
    listener.endNewExpression(newKeyword);
    return token;
  }

  Token parseConstExpression(Token token) {
    Token constKeyword = token;
    token = expect('const', token);
    token = listener.injectGenericCommentTypeList(token);
    final String value = token.stringValue;
    if ((identical(value, '[')) || (identical(value, '[]'))) {
      listener.beginConstLiteral(token);
      listener.handleNoTypeArguments(token);
      token = parseLiteralListSuffix(token, constKeyword);
      listener.endConstLiteral(token);
      return token;
    }
    if (identical(value, '{')) {
      listener.beginConstLiteral(token);
      listener.handleNoTypeArguments(token);
      token = parseLiteralMapSuffix(token, constKeyword);
      listener.endConstLiteral(token);
      return token;
    }
    if (identical(value, '<')) {
      listener.beginConstLiteral(token);
      token = parseLiteralListOrMapOrFunction(token, constKeyword);
      listener.endConstLiteral(token);
      return token;
    }
    listener.beginConstExpression(constKeyword);
    token = parseConstructorReference(token);
    token = parseRequiredArguments(token);
    listener.endConstExpression(constKeyword);
    return token;
  }

  Token parseLiteralInt(Token token) {
    listener.handleLiteralInt(token);
    return token.next;
  }

  Token parseLiteralDouble(Token token) {
    listener.handleLiteralDouble(token);
    return token.next;
  }

  Token parseLiteralString(Token token) {
    bool old = mayParseFunctionExpressions;
    mayParseFunctionExpressions = true;
    token = parseSingleLiteralString(token);
    int count = 1;
    while (identical(token.kind, STRING_TOKEN)) {
      token = parseSingleLiteralString(token);
      count++;
    }
    if (count > 1) {
      listener.handleStringJuxtaposition(count);
    }
    mayParseFunctionExpressions = old;
    return token;
  }

  Token parseLiteralSymbol(Token token) {
    Token hashToken = token;
    listener.beginLiteralSymbol(hashToken);
    token = token.next;
    if (isUserDefinableOperator(token.stringValue)) {
      listener.handleOperator(token);
      listener.endLiteralSymbol(hashToken, 1);
      return token.next;
    } else if (identical(token.stringValue, 'void')) {
      listener.handleSymbolVoid(token);
      listener.endLiteralSymbol(hashToken, 1);
      return token.next;
    } else {
      int count = 1;
      token = parseIdentifier(token, IdentifierContext.literalSymbol);
      while (identical(token.stringValue, '.')) {
        count++;
        token = parseIdentifier(
            token.next, IdentifierContext.literalSymbolContinuation);
      }
      listener.endLiteralSymbol(hashToken, count);
      return token;
    }
  }

  /// Only called when `identical(token.kind, STRING_TOKEN)`.
  Token parseSingleLiteralString(Token token) {
    listener.beginLiteralString(token);
    // Parsing the prefix, for instance 'x of 'x${id}y${id}z'
    token = token.next;
    int interpolationCount = 0;
    var kind = token.kind;
    while (kind != EOF_TOKEN) {
      if (identical(kind, STRING_INTERPOLATION_TOKEN)) {
        // Parsing ${expression}.
        token = token.next;
        token = parseExpression(token);
        token = expect('}', token);
      } else if (identical(kind, STRING_INTERPOLATION_IDENTIFIER_TOKEN)) {
        // Parsing $identifier.
        token = token.next;
        token = parseExpression(token);
      } else {
        break;
      }
      ++interpolationCount;
      // Parsing the infix/suffix, for instance y and z' of 'x${id}y${id}z'
      token = parseStringPart(token);
      kind = token.kind;
    }
    listener.endLiteralString(interpolationCount, token);
    return token;
  }

  Token parseLiteralBool(Token token) {
    listener.handleLiteralBool(token);
    return token.next;
  }

  Token parseLiteralNull(Token token) {
    listener.handleLiteralNull(token);
    return token.next;
  }

  Token parseSend(Token token, IdentifierContext context) {
    Token beginToken = token;
    listener.beginSend(token);
    token = parseIdentifier(token, context);
    token = listener.injectGenericCommentTypeList(token);
    if (isValidMethodTypeArguments(token)) {
      token = parseTypeArgumentsOpt(token);
    } else {
      listener.handleNoTypeArguments(token);
    }
    token = parseArgumentsOpt(token);
    listener.endSend(beginToken, token);
    return token;
  }

  Token skipArgumentsOpt(Token token) {
    listener.handleNoArguments(token);
    if (optional('(', token)) {
      BeginToken begin = token;
      return begin.endGroup.next;
    } else {
      return token;
    }
  }

  Token parseArgumentsOpt(Token token) {
    if (!optional('(', token)) {
      listener.handleNoArguments(token);
      return token;
    } else {
      return parseArguments(token);
    }
  }

  Token parseArguments(Token token) {
    Token begin = token;
    listener.beginArguments(begin);
    assert(identical('(', token.stringValue));
    int argumentCount = 0;
    if (optional(')', token.next)) {
      listener.endArguments(argumentCount, begin, token.next);
      return token.next.next;
    }
    bool old = mayParseFunctionExpressions;
    mayParseFunctionExpressions = true;
    do {
      if (optional(')', token.next)) {
        token = token.next;
        break;
      }
      Token colon = null;
      if (optional(':', token.next.next)) {
        token = parseIdentifier(
            token.next, IdentifierContext.namedArgumentReference);
        colon = token;
      }
      token = parseExpression(token.next);
      if (colon != null) listener.handleNamedArgument(colon);
      ++argumentCount;
    } while (optional(',', token));
    mayParseFunctionExpressions = old;
    listener.endArguments(argumentCount, begin, token);
    return expect(')', token);
  }

  Token parseIsOperatorRest(Token token) {
    assert(optional('is', token));
    Token operator = token;
    Token not = null;
    if (optional('!', token.next)) {
      token = token.next;
      not = token;
    }
    token = parseType(token.next);
    listener.handleIsOperator(operator, not, token);
    String value = token.stringValue;
    if (identical(value, 'is') || identical(value, 'as')) {
      // The is- and as-operators cannot be chained, but they can take part of
      // expressions like: foo is Foo || foo is Bar.
      reportUnexpectedToken(token);
    }
    return token;
  }

  Token parseAsOperatorRest(Token token) {
    assert(optional('as', token));
    Token operator = token;
    token = parseType(token.next);
    listener.handleAsOperator(operator, token);
    String value = token.stringValue;
    if (identical(value, 'is') || identical(value, 'as')) {
      // The is- and as-operators cannot be chained.
      reportUnexpectedToken(token);
    }
    return token;
  }

  Token parseVariablesDeclaration(Token token) {
    return parseVariablesDeclarationMaybeSemicolon(token, true);
  }

  Token parseVariablesDeclarationNoSemicolon(Token token) {
    // Only called when parsing a for loop, so this is for parsing locals.
    return parseVariablesDeclarationMaybeSemicolon(token, false);
  }

  Token parseVariablesDeclarationMaybeSemicolon(
      Token token, bool endWithSemicolon) {
    int count = 1;
    token = parseMetadataStar(token);

    // If the next token has a type substitution comment /*=T*/, then
    // the current 'var' token should be repealed and replaced.
    if (optional('var', token)) {
      token =
          listener.replaceTokenWithGenericCommentTypeAssign(token, token.next);
    }

    token = parseModifiers(token, MemberKind.Local, isVariable: true);
    listener.beginVariablesDeclaration(token);
    token = parseOptionallyInitializedIdentifier(token);
    while (optional(',', token)) {
      token = parseOptionallyInitializedIdentifier(token.next);
      ++count;
    }
    if (endWithSemicolon) {
      Token semicolon = token;
      token = expectSemicolon(semicolon);
      listener.endVariablesDeclaration(count, semicolon);
      return token;
    } else {
      listener.endVariablesDeclaration(count, null);
      return token;
    }
  }

  Token parseOptionallyInitializedIdentifier(Token token) {
    Token nameToken = token;
    listener.beginInitializedIdentifier(token);
    token = parseIdentifier(token, IdentifierContext.localVariableDeclaration);
    token = parseVariableInitializerOpt(token);
    listener.endInitializedIdentifier(nameToken);
    return token;
  }

  Token parseIfStatement(Token token) {
    Token ifToken = token;
    listener.beginIfStatement(ifToken);
    token = expect('if', token);
    token = parseParenthesizedExpression(token);
    listener.beginThenStatement(token);
    token = parseStatement(token);
    listener.endThenStatement(token);
    Token elseToken = null;
    if (optional('else', token)) {
      elseToken = token;
      listener.beginElseStatement(token);
      token = parseStatement(token.next);
      listener.endElseStatement(token);
    }
    listener.endIfStatement(ifToken, elseToken);
    return token;
  }

  Token parseForStatement(Token awaitToken, Token token) {
    Token forKeyword = token;
    listener.beginForStatement(forKeyword);
    token = expect('for', token);
    Token leftParenthesis = token;
    token = expect('(', token);
    token = parseVariablesDeclarationOrExpressionOpt(token);
    if (optional('in', token)) {
      return parseForInRest(awaitToken, forKeyword, leftParenthesis, token);
    } else {
      if (awaitToken != null) {
        reportRecoverableErrorCode(awaitToken, codeInvalidAwaitFor);
      }
      return parseForRest(forKeyword, leftParenthesis, token);
    }
  }

  Token parseVariablesDeclarationOrExpressionOpt(Token token) {
    final String value = token.stringValue;
    if (identical(value, ';')) {
      listener.handleNoExpression(token);
      return token;
    } else if (isOneOf4(token, '@', 'var', 'final', 'const')) {
      return parseVariablesDeclarationNoSemicolon(token);
    }
    Token identifier = peekIdentifierAfterType(token);
    if (identifier != null) {
      assert(identifier.isIdentifier);
      if (isOneOf4(identifier.next, '=', ';', ',', 'in')) {
        return parseVariablesDeclarationNoSemicolon(token);
      }
    }
    return parseExpression(token);
  }

  Token parseForRest(Token forToken, Token leftParenthesis, Token token) {
    Token leftSeparator = token;
    token = expectSemicolon(token);
    if (optional(';', token)) {
      token = parseEmptyStatement(token);
    } else {
      token = parseExpressionStatement(token);
    }
    int expressionCount = 0;
    while (true) {
      if (optional(')', token)) break;
      token = parseExpression(token);
      ++expressionCount;
      if (optional(',', token)) {
        token = token.next;
      } else {
        break;
      }
    }
    token = expect(')', token);
    listener.beginForStatementBody(token);
    token = parseStatement(token);
    listener.endForStatementBody(token);
    listener.endForStatement(forToken, leftSeparator, expressionCount, token);
    return token;
  }

  Token parseForInRest(
      Token awaitToken, Token forKeyword, Token leftParenthesis, Token token) {
    assert(optional('in', token));
    Token inKeyword = token;
    token = token.next;
    listener.beginForInExpression(token);
    token = parseExpression(token);
    listener.endForInExpression(token);
    Token rightParenthesis = token;
    token = expect(')', token);
    listener.beginForInBody(token);
    token = parseStatement(token);
    listener.endForInBody(token);
    listener.endForIn(awaitToken, forKeyword, leftParenthesis, inKeyword,
        rightParenthesis, token);
    return token;
  }

  Token parseWhileStatement(Token token) {
    Token whileToken = token;
    listener.beginWhileStatement(whileToken);
    token = expect('while', token);
    token = parseParenthesizedExpression(token);
    listener.beginWhileStatementBody(token);
    token = parseStatement(token);
    listener.endWhileStatementBody(token);
    listener.endWhileStatement(whileToken, token);
    return token;
  }

  Token parseDoWhileStatement(Token token) {
    Token doToken = token;
    listener.beginDoWhileStatement(doToken);
    token = expect('do', token);
    listener.beginDoWhileStatementBody(token);
    token = parseStatement(token);
    listener.endDoWhileStatementBody(token);
    Token whileToken = token;
    token = expect('while', token);
    token = parseParenthesizedExpression(token);
    listener.endDoWhileStatement(doToken, whileToken, token);
    return expectSemicolon(token);
  }

  Token parseBlock(Token token) {
    Token begin = token;
    listener.beginBlock(begin);
    int statementCount = 0;
    token = expect('{', token);
    while (notEofOrValue('}', token)) {
      token = parseStatement(token);
      ++statementCount;
    }
    listener.endBlock(statementCount, begin, token);
    return expect('}', token);
  }

  Token parseAwaitExpression(Token token, bool allowCascades) {
    Token awaitToken = token;
    listener.beginAwaitExpression(awaitToken);
    token = expect('await', token);
    if (!inAsync) {
      reportRecoverableErrorCode(awaitToken, codeAwaitNotAsync);
    }
    token = parsePrecedenceExpression(token, POSTFIX_PRECEDENCE, allowCascades);
    listener.endAwaitExpression(awaitToken, token);
    return token;
  }

  Token parseThrowExpression(Token token, bool allowCascades) {
    Token throwToken = token;
    listener.beginThrowExpression(throwToken);
    token = expect('throw', token);
    token = allowCascades
        ? parseExpression(token)
        : parseExpressionWithoutCascade(token);
    listener.endThrowExpression(throwToken, token);
    return token;
  }

  Token parseRethrowStatement(Token token) {
    Token throwToken = token;
    listener.beginRethrowStatement(throwToken);
    // TODO(kasperl): Disallow throw here.
    if (identical(throwToken.stringValue, 'throw')) {
      token = expect('throw', token);
    } else {
      token = expect('rethrow', token);
    }
    listener.endRethrowStatement(throwToken, token);
    return expectSemicolon(token);
  }

  Token parseTryStatement(Token token) {
    assert(optional('try', token));
    Token tryKeyword = token;
    listener.beginTryStatement(tryKeyword);
    token = parseBlock(token.next);
    int catchCount = 0;

    String value = token.stringValue;
    while (identical(value, 'catch') || identical(value, 'on')) {
      listener.beginCatchClause(token);
      var onKeyword = null;
      if (identical(value, 'on')) {
        // on qualified catchPart?
        onKeyword = token;
        token = parseType(token.next);
        value = token.stringValue;
      }
      Token catchKeyword = null;
      if (identical(value, 'catch')) {
        catchKeyword = token;
        Token openParens = catchKeyword.next;
        Token exceptionName = openParens.next;
        Token commaOrCloseParens = exceptionName.next;
        Token traceName = commaOrCloseParens.next;
        Token closeParens = traceName.next;
        if (!optional("(", openParens)) {
          // Handled below by parseFormalParameters.
        } else if (!exceptionName.isIdentifier) {
          reportRecoverableErrorCode(exceptionName, codeCatchSyntax);
        } else if (optional(")", commaOrCloseParens)) {
          // OK: `catch (identifier)`.
        } else if (!optional(",", commaOrCloseParens)) {
          reportRecoverableErrorCode(exceptionName, codeCatchSyntax);
        } else if (!traceName.isIdentifier) {
          reportRecoverableErrorCode(exceptionName, codeCatchSyntax);
        } else if (!optional(")", closeParens)) {
          reportRecoverableErrorCode(exceptionName, codeCatchSyntax);
        }
        token = parseFormalParameters(token.next, MemberKind.Catch);
      }
      listener.endCatchClause(token);
      token = parseBlock(token);
      ++catchCount;
      listener.handleCatchBlock(onKeyword, catchKeyword);
      value = token.stringValue; // while condition
    }

    Token finallyKeyword = null;
    if (optional('finally', token)) {
      finallyKeyword = token;
      token = parseBlock(token.next);
      listener.handleFinallyBlock(finallyKeyword);
    } else {
      if (catchCount == 0) {
        reportRecoverableErrorCode(tryKeyword, codeOnlyTry);
      }
    }
    listener.endTryStatement(catchCount, tryKeyword, finallyKeyword);
    return token;
  }

  Token parseSwitchStatement(Token token) {
    assert(optional('switch', token));
    Token switchKeyword = token;
    listener.beginSwitchStatement(switchKeyword);
    token = parseParenthesizedExpression(token.next);
    token = parseSwitchBlock(token);
    listener.endSwitchStatement(switchKeyword, token);
    return token.next;
  }

  Token parseSwitchBlock(Token token) {
    Token begin = token;
    listener.beginSwitchBlock(begin);
    token = expect('{', token);
    int caseCount = 0;
    while (!identical(token.kind, EOF_TOKEN)) {
      if (optional('}', token)) {
        break;
      }
      token = parseSwitchCase(token);
      ++caseCount;
    }
    listener.endSwitchBlock(caseCount, begin, token);
    expect('}', token);
    return token;
  }

  /// Peek after the following labels (if any). The following token
  /// is used to determine if the labels belong to a statement or a
  /// switch case.
  Token peekPastLabels(Token token) {
    while (token.isIdentifier && optional(':', token.next)) {
      token = token.next.next;
    }
    return token;
  }

  /// Parse a group of labels, cases and possibly a default keyword and the
  /// statements that they select.
  Token parseSwitchCase(Token token) {
    Token begin = token;
    Token defaultKeyword = null;
    int expressionCount = 0;
    int labelCount = 0;
    Token peek = peekPastLabels(token);
    while (true) {
      // Loop until we find something that can't be part of a switch case.
      String value = peek.stringValue;
      if (identical(value, 'default')) {
        while (!identical(token, peek)) {
          token = parseLabel(token);
          labelCount++;
        }
        defaultKeyword = token;
        token = expect(':', token.next);
        peek = token;
        break;
      } else if (identical(value, 'case')) {
        while (!identical(token, peek)) {
          token = parseLabel(token);
          labelCount++;
        }
        Token caseKeyword = token;
        listener.beginCaseExpression(token);
        token = parseExpression(token.next);
        listener.endCaseExpression(token);
        Token colonToken = token;
        token = expect(':', token);
        listener.handleCaseMatch(caseKeyword, colonToken);
        expressionCount++;
        peek = peekPastLabels(token);
      } else {
        if (expressionCount == 0) {
          // TODO(ahe): This is probably easy to recover from.
          reportUnrecoverableErrorCodeWithString(
              token, codeExpectedButGot, "case");
        }
        break;
      }
    }
    listener.beginSwitchCase(labelCount, expressionCount, begin);
    // Finally zero or more statements.
    int statementCount = 0;
    while (!identical(token.kind, EOF_TOKEN)) {
      String value = peek.stringValue;
      if ((identical(value, 'case')) ||
          (identical(value, 'default')) ||
          ((identical(value, '}')) && (identical(token, peek)))) {
        // A label just before "}" will be handled as a statement error.
        break;
      } else {
        token = parseStatement(token);
      }
      statementCount++;
      peek = peekPastLabels(token);
    }
    listener.handleSwitchCase(labelCount, expressionCount, defaultKeyword,
        statementCount, begin, token);
    return token;
  }

  Token parseBreakStatement(Token token) {
    assert(optional('break', token));
    Token breakKeyword = token;
    token = token.next;
    bool hasTarget = false;
    if (token.isIdentifier) {
      token = parseIdentifier(token, IdentifierContext.labelReference);
      hasTarget = true;
    }
    listener.handleBreakStatement(hasTarget, breakKeyword, token);
    return expectSemicolon(token);
  }

  Token parseAssert(Token token, Assert kind) {
    listener.beginAssert(token, kind);
    Token assertKeyword = token;
    Token commaToken = null;
    token = expect('assert', token);
    Token leftParenthesis = token;
    token = expect('(', token);
    bool old = mayParseFunctionExpressions;
    mayParseFunctionExpressions = true;
    token = parseExpression(token);
    if (optional(',', token)) {
      commaToken = token;
      token = token.next;
      token = parseExpression(token);
    }
    if (optional(',', token)) {
      Token firstExtra = token.next;
      while (optional(',', token)) {
        token = token.next;
        Token begin = token;
        token = parseExpression(token);
        listener.handleExtraneousExpression(
            begin, codeAssertExtraneousArgument.format(uri, token.charOffset));
      }
      reportRecoverableErrorCode(firstExtra, codeAssertExtraneousArgument);
    }
    Token rightParenthesis = token;
    token = expect(')', token);
    mayParseFunctionExpressions = old;
    listener.endAssert(assertKeyword, kind, leftParenthesis, commaToken,
        rightParenthesis, token);
    if (kind == Assert.Expression) {
      reportRecoverableErrorCode(assertKeyword, codeAssertAsExpression);
    }
    return token;
  }

  Token parseAssertStatement(Token token) {
    token = parseAssert(token, Assert.Statement);
    return expectSemicolon(token);
  }

  Token parseContinueStatement(Token token) {
    assert(optional('continue', token));
    Token continueKeyword = token;
    token = token.next;
    bool hasTarget = false;
    if (token.isIdentifier) {
      token = parseIdentifier(token, IdentifierContext.labelReference);
      hasTarget = true;
    }
    listener.handleContinueStatement(hasTarget, continueKeyword, token);
    return expectSemicolon(token);
  }

  Token parseEmptyStatement(Token token) {
    listener.handleEmptyStatement(token);
    return expectSemicolon(token);
  }

  /// Don't call this method. Should only be used as a last resort when there
  /// is no feasible way to recover from a parser error.
  Token reportUnrecoverableError(Token token, FastaMessage format()) {
    Token next;
    if (token is ErrorToken) {
      next = reportErrorToken(token, false);
    } else {
      next = listener.handleUnrecoverableError(token, format());
    }
    return next ?? skipToEof(token);
  }

  void reportRecoverableError(Token token, FastaMessage format()) {
    if (token is ErrorToken) {
      reportErrorToken(token, true);
    } else {
      listener.handleRecoverableError(token, format());
    }
  }

  Token reportErrorToken(ErrorToken token, bool isRecoverable) {
    FastaCode code = token.errorCode;
    FastaMessage message;
    if (code == codeAsciiControlCharacter) {
      message = codeAsciiControlCharacter.format(
          uri, token.charOffset, token.character);
    } else if (code == codeNonAsciiWhitespace) {
      message =
          codeNonAsciiWhitespace.format(uri, token.charOffset, token.character);
    } else if (code == codeEncoding) {
      message = codeEncoding.format(uri, token.charOffset);
    } else if (code == codeNonAsciiIdentifier) {
      message = codeNonAsciiIdentifier.format(uri, token.charOffset,
          new String.fromCharCodes([token.character]), token.character);
    } else if (code == codeUnterminatedString) {
      message =
          codeUnterminatedString.format(uri, token.charOffset, token.start);
    } else if (code == codeUnmatchedToken) {
      Token begin = token.begin;
      message = codeUnmatchedToken.format(
          uri, token.charOffset, closeBraceFor(begin.lexeme), begin);
    } else if (code == codeUnspecified) {
      message =
          codeUnspecified.format(uri, token.charOffset, token.assertionMessage);
    } else {
      message = code.format(uri, token.charOffset);
    }
    if (isRecoverable) {
      listener.handleRecoverableError(token, message);
      return null;
    } else {
      Token next = listener.handleUnrecoverableError(token, message);
      return next ?? skipToEof(token);
    }
  }

  Token reportUnmatchedToken(BeginToken token) {
    return reportUnrecoverableError(
        token,
        () => codeUnmatchedToken.format(
            uri, token.charOffset, closeBraceFor(token.lexeme), token));
  }

  Token reportUnexpectedToken(Token token) {
    return reportUnrecoverableError(
        token, () => codeUnexpectedToken.format(uri, token.charOffset, token));
  }

  void reportRecoverableErrorCode(Token token, FastaCode<NoArgument> code) {
    reportRecoverableError(token, () => code.format(uri, token.charOffset));
  }

  Token reportUnrecoverableErrorCode(Token token, FastaCode<NoArgument> code) {
    return reportUnrecoverableError(
        token, () => code.format(uri, token.charOffset));
  }

  void reportRecoverableErrorCodeWithToken(
      Token token, FastaCode<TokenArgument> code) {
    reportRecoverableError(
        token, () => code.format(uri, token.charOffset, token));
  }

  Token reportUnrecoverableErrorCodeWithToken(
      Token token, FastaCode<TokenArgument> code) {
    return reportUnrecoverableError(
        token, () => code.format(uri, token.charOffset, token));
  }

  Token reportUnrecoverableErrorCodeWithString(
      Token token, FastaCode<StringArgument> code, String string) {
    return reportUnrecoverableError(
        token, () => code.format(uri, token.charOffset, string));
  }
}

typedef FastaMessage NoArgument(Uri uri, int charOffset);

typedef FastaMessage TokenArgument(Uri uri, int charOffset, Token token);

typedef FastaMessage StringArgument(Uri uri, int charOffset, String string);
