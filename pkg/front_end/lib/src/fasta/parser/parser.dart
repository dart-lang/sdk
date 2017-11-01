// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.parser.parser;

import '../fasta_codes.dart' show Message, Template;

import '../fasta_codes.dart' as fasta;

import '../scanner.dart' show ErrorToken, Token;

import '../scanner/recover.dart' show closeBraceFor, skipToEof;

import '../../scanner/token.dart'
    show
        ASSIGNMENT_PRECEDENCE,
        BeginToken,
        CASCADE_PRECEDENCE,
        EQUALITY_PRECEDENCE,
        Keyword,
        POSTFIX_PRECEDENCE,
        RELATIONAL_PRECEDENCE,
        SyntheticBeginToken,
        SyntheticKeywordToken,
        SyntheticStringToken,
        SyntheticToken,
        TokenType;

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

import 'assert.dart' show Assert;

import 'async_modifier.dart' show AsyncModifier;

import 'directive_context.dart';

import 'formal_parameter_kind.dart'
    show
        FormalParameterKind,
        isMandatoryFormalParameterKind,
        isOptionalPositionalFormalParameterKind;

import 'identifier_context.dart' show IdentifierContext;

import 'listener.dart' show Listener;

import 'member_kind.dart' show MemberKind;

import 'modifier_context.dart'
    show
        ClassMethodModifierContext,
        FactoryModifierContext,
        ModifierContext,
        ModifierRecoveryContext,
        TopLevelMethodModifierContext,
        isModifier;

import 'recovery_listeners.dart'
    show ClassHeaderRecoveryListener, ImportRecoveryListener;

import 'token_stream_rewriter.dart' show TokenStreamRewriter;

import 'type_continuation.dart'
    show TypeContinuation, typeContiunationFromFormalParameterKind;

import 'util.dart' show closeBraceTokenFor, optional;

/// An event generating parser of Dart programs. This parser expects all tokens
/// in a linked list (aka a token stream).
///
/// The class [Scanner] is used to generate a token stream. See the file
/// [scanner.dart](../scanner.dart).
///
/// Subclasses of the class [Listener] are used to listen to events.
///
/// Most methods of this class belong in one of four major categories: parse
/// methods, peek methods, ensure methods, and skip methods.
///
/// Parse methods all have the prefix `parse`, generate events
/// (by calling methods on [listener]), and return the next token to parse.
/// Some exceptions to this last point are methods such as [parseFunctionBody]
/// and [parseClassBody] which return the last token parsed
/// rather than the next token to be parsed.
/// Parse methods are generally named `parseGrammarProductionSuffix`.
/// The suffix can be one of `opt`, or `star`.
/// `opt` means zero or one matches, `star` means zero or more matches.
/// For example, [parseMetadataStar] corresponds to this grammar snippet:
/// `metadata*`, and [parseArgumentsOpt] corresponds to: `arguments?`.
///
/// Peek methods all have the prefix `peek`, do not generate events
/// (except for errors) and may return null.
///
/// Ensure methods all have the prefix `ensure` and may generate events.
/// They return the current token, or insert and return a synthetic token
/// if the current token does not match. For example,
/// [ensureSemicolon] returns the current token if the current token is a
/// semicolon, otherwise inserts a synthetic semicolon in the token stream
/// before the current token and then returns that new synthetic token.
///
/// Skip methods are like parse methods, but all have the prefix `skip`
/// and skip over some parts of the file being parsed.
/// Typically, skip methods generate an event for the structure being skipped,
/// but not for its substructures.
///
/// ## Current Token
///
/// The current token is always to be found in a formal parameter named
/// `token`. This parameter should be the first as this increases the chance
/// that a compiler will place it in a register.
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
/// parser. One should favor the methods [optional] and [expect] to recognize
/// keywords or identifiers. In some cases, it's possible to compare a token's
/// `stringValue` using [identical], but normally [optional] will suffice.
///
/// Historically, we over-used identical, and when identical is used on objects
/// other than strings, it can often be replaced by `==`.
///
/// ## Flexibility, Extensibility, and Specification
///
/// The parser is designed to be flexible and extensible. Its methods are
/// designed to be overridden in subclasses, so it can be extended to handle
/// unspecified language extension or experiments while everything in this file
/// attempts to follow the specification (unless when it interferes with error
/// recovery).
///
/// We achieve flexibility, extensible, and specification compliance by
/// following a few rules-of-thumb:
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
/// #### Legacy Implementation of `native` Keyword
///
/// TODO(ahe,danrubel): Remove this section.
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
/// listener with the code [fasta.messageExpectedFunctionBody]. The listener can
/// then look at the error code and the token and use the methods in
/// [native_support.dart](native_support.dart) to parse the native syntax.
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
/// ### Legacy Error Recovery
///
/// What's described below will be phased out in preference of the parser
/// reporting and recovering from syntax errors. The motivation for this is
/// that we have multiple listeners that use the parser, and this will ensure
/// consistency.
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
  Listener listener;

  Uri get uri => listener.uri;

  bool mayParseFunctionExpressions = true;

  /// Represents parser state: what asynchronous syntax is allowed in the
  /// function being currently parsed. In rare situations, this can be set by
  /// external clients, for example, to parse an expression outside a function.
  AsyncModifier asyncState = AsyncModifier.Sync;

  /// A rewriter for inserting synthetic tokens.
  /// Access using [rewriter] for lazy initialization.
  TokenStreamRewriter cachedRewriter;

  TokenStreamRewriter get rewriter {
    cachedRewriter ??= new TokenStreamRewriter();
    return cachedRewriter;
  }

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

  /// ```
  /// libraryDefinition:
  ///   scriptTag?
  ///   libraryName?
  ///   importOrExport*
  ///   partDirective*
  ///   topLevelDefinition*
  /// ;
  ///
  /// partDeclaration:
  ///   partHeader topLevelDefinition*
  /// ;
  /// ```
  Token parseUnit(Token token) {
    listener.beginCompilationUnit(token);
    int count = 0;
    DirectiveContext directiveState = new DirectiveContext();
    while (!token.isEof) {
      Token start = token;
      token = parseTopLevelDeclarationImpl(
          syntheticPreviousToken(token), directiveState);
      listener.endTopLevelDeclaration(token);
      count++;
      if (start == token) {
        // If progress has not been made reaching the end of the token stream,
        // then report an error and skip the current token.
        reportRecoverableErrorWithToken(
            token, fasta.templateExpectedDeclaration);
        listener.handleInvalidTopLevelDeclaration(token);
        token = token.next;
        listener.endTopLevelDeclaration(token);
        count++;
      }
    }
    listener.endCompilationUnit(count, token);
    // Clear fields that could lead to memory leak.
    cachedRewriter = null;
    return token;
  }

  Token parseTopLevelDeclaration(Token token) {
    token = parseTopLevelDeclarationImpl(syntheticPreviousToken(token), null);
    listener.endTopLevelDeclaration(token);
    return token;
  }

  /// ```
  /// topLevelDefinition:
  ///   classDefinition |
  ///   enumType |
  ///   typeAlias |
  ///   'external'? functionSignature ';' |
  ///   'external'? getterSignature ';' |
  ///   'external''? setterSignature ';' |
  ///   functionSignature functionBody |
  ///   returnType? 'get' identifier functionBody |
  ///   returnType? 'set' identifier formalParameterList functionBody |
  ///   ('final' | 'const') type? staticFinalDeclarationList ';' |
  ///   variableDeclaration ';'
  /// ;
  /// ```
  Token parseTopLevelDeclarationImpl(
      Token token, DirectiveContext directiveState) {
    // TODO(brianwilkerson) Return the last consumed token.
    if (identical(token.next.type, TokenType.SCRIPT_TAG)) {
      directiveState?.checkScriptTag(this, token.next);
      return parseScript(token).next;
    }
    token = parseMetadataStar(token.next);
    if (token.isTopLevelKeyword) {
      return parseTopLevelKeywordDeclaration(null, token, directiveState);
    }
    Token start = token;
    // Skip modifiers to find a top level keyword or identifier
    while (token.isModifier) {
      token = token.next;
    }
    if (token.isTopLevelKeyword) {
      Token abstractToken;
      Token modifier = start;
      while (modifier != token) {
        if (optional('abstract', modifier) &&
            optional('class', token) &&
            abstractToken == null) {
          abstractToken = modifier;
        } else {
          // Recovery
          reportTopLevelModifierError(modifier, token);
        }
        modifier = modifier.next;
      }
      return parseTopLevelKeywordDeclaration(
          abstractToken, token, directiveState);
    } else if (token.isIdentifier || token.keyword != null) {
      // TODO(danrubel): improve parseTopLevelMember
      // so that we don't parse modifiers twice.
      directiveState?.checkDeclaration();
      return parseTopLevelMember(start);
    } else if (start != token) {
      directiveState?.checkDeclaration();
      // Handle the edge case where a modifier is being used as an identifier
      return parseTopLevelMember(start);
    }
    // Ignore any preceding modifiers and just report the unexpected token
    reportRecoverableErrorWithToken(token, fasta.templateExpectedDeclaration);
    listener.handleInvalidTopLevelDeclaration(token);
    return token.next;
  }

  // Report an error for the given modifier preceding a top level keyword
  // such as `import` or `class`.
  void reportTopLevelModifierError(Token modifier, Token afterModifiers) {
    if (optional('const', modifier) && optional('class', afterModifiers)) {
      reportRecoverableError(modifier, fasta.messageConstClass);
    } else if (optional('external', modifier)) {
      if (optional('class', afterModifiers)) {
        reportRecoverableError(modifier, fasta.messageExternalClass);
      } else if (optional('enum', afterModifiers)) {
        reportRecoverableError(modifier, fasta.messageExternalEnum);
      } else if (optional('typedef', afterModifiers)) {
        reportRecoverableError(modifier, fasta.messageExternalTypedef);
      } else {
        reportRecoverableErrorWithToken(
            modifier, fasta.templateExtraneousModifier);
      }
    } else {
      reportRecoverableErrorWithToken(
          modifier, fasta.templateExtraneousModifier);
    }
  }

  /// Parse any top-level declaration that begins with a keyword.
  Token parseTopLevelKeywordDeclaration(
      Token abstractToken, Token token, DirectiveContext directiveState) {
    // TODO(brianwilkerson) Accept the last consumed token.
    // TODO(brianwilkerson) Return the last consumed token.
    assert(token.isTopLevelKeyword);
    final String value = token.stringValue;
    if (identical(value, 'class')) {
      directiveState?.checkDeclaration();
      return parseClassOrNamedMixinApplication(abstractToken, token).next;
    } else if (identical(value, 'enum')) {
      directiveState?.checkDeclaration();
      return parseEnum(token).next;
    } else if (identical(value, 'typedef')) {
      Token next = token.next;
      if (next.isIdentifier || optional("void", next)) {
        directiveState?.checkDeclaration();
        return parseTypedef(token).next;
      } else {
        directiveState?.checkDeclaration();
        return parseTopLevelMember(token);
      }
    } else {
      // The remaining top level keywords are built-in keywords
      // and can be used as an identifier in a top level declaration
      // such as "abstract<T>() => 0;".
      String nextValue = token.next.stringValue;
      if (identical(nextValue, '(') || identical(nextValue, '<')) {
        directiveState?.checkDeclaration();
        return parseTopLevelMember(token);
      } else if (identical(value, 'library')) {
        directiveState?.checkLibrary(this, token);
        return parseLibraryName(token).next;
      } else if (identical(value, 'import')) {
        directiveState?.checkImport(this, token);
        return parseImport(token).next;
      } else if (identical(value, 'export')) {
        directiveState?.checkExport(this, token);
        return parseExport(token).next;
      } else if (identical(value, 'part')) {
        return parsePartOrPartOf(token, directiveState).next;
      }
    }

    throw "Internal error: Unhandled top level keyword '$value'.";
  }

  /// ```
  /// libraryDirective:
  ///   'library' qualified ';'
  /// ;
  /// ```
  Token parseLibraryName(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    assert(optional('library', token));
    Token libraryKeyword = token;
    listener.beginLibraryName(libraryKeyword);
    token = parseQualified(token.next, IdentifierContext.libraryName,
            IdentifierContext.libraryNameContinuation)
        .next;
    token = ensureSemicolon(token);
    listener.endLibraryName(libraryKeyword, token);
    return token;
  }

  /// ```
  /// importPrefix:
  ///   'deferred'? 'as' identifier
  /// ;
  /// ```
  Token parseImportPrefixOpt(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    // TODO(brianwilkerson) Return the last consumed token.
    if (optional('deferred', token) && optional('as', token.next)) {
      Token deferredToken = token;
      Token asKeyword = token.next;
      token = ensureIdentifier(
              asKeyword.next, IdentifierContext.importPrefixDeclaration)
          .next;
      listener.handleImportPrefix(deferredToken, asKeyword);
    } else if (optional('as', token)) {
      Token asKeyword = token;
      token = ensureIdentifier(
              token.next, IdentifierContext.importPrefixDeclaration)
          .next;
      listener.handleImportPrefix(null, asKeyword);
    } else {
      listener.handleImportPrefix(null, null);
    }
    return token;
  }

  /// ```
  /// importDirective:
  ///   'import' uri ('if' '(' test ')' uri)* importPrefix? combinator* ';'
  /// ;
  /// ```
  Token parseImport(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    assert(optional('import', token));
    Token importKeyword = token;
    listener.beginImport(importKeyword);
    token = parseLiteralStringOrRecoverExpression(token.next);
    Token afterUri = token;
    token = parseConditionalUris(token);
    token = parseImportPrefixOpt(token);
    token = parseCombinators(token);
    if (optional(';', token)) {
      listener.endImport(importKeyword, token);
      return token;
    } else {
      // Recovery
      listener.endImport(importKeyword, null);
      return parseImportRecovery(afterUri, token);
    }
  }

  /// Recover given out-of-order clauses in an import directive where [token] is
  /// the import keyword and [recoveryStart] is the token on which main parsing
  /// stopped.
  Token parseImportRecovery(Token token, Token recoveryStart) {
    // TODO(brianwilkerson) Accept the last consumed token.
    final primaryListener = listener;
    final recoveryListener = new ImportRecoveryListener(primaryListener);

    // Reparse to determine which clauses have already been parsed
    // but intercept the events so they are not sent to the primary listener
    listener = recoveryListener;
    token = parseConditionalUris(token);
    token = parseImportPrefixOpt(token);
    token = parseCombinators(token);

    Token firstDeferredKeyword = recoveryListener.deferredKeyword;
    bool hasPrefix = recoveryListener.asKeyword != null;
    bool hasCombinator = recoveryListener.hasCombinator;

    // Update the recovery listener to forward subsequent events
    // to the primary listener
    recoveryListener.listener = primaryListener;

    // Parse additional out-of-order clauses.
    Token semicolon;
    do {
      Token start = token;

      // Check for extraneous token in the middle of an import statement.
      token = skipUnexpectedTokenOpt(
          token, const <String>['if', 'deferred', 'as', 'hide', 'show', ';']);

      // During recovery, clauses are parsed in the same order
      // and generate the same events as in the parseImport method above.
      recoveryListener.clear();
      token = parseConditionalUris(token);
      if (recoveryListener.ifKeyword != null) {
        if (firstDeferredKeyword != null) {
          // TODO(danrubel): report error indicating conditional should
          // be moved before deferred keyword
        } else if (hasPrefix) {
          // TODO(danrubel): report error indicating conditional should
          // be moved before prefix clause
        } else if (hasCombinator) {
          // TODO(danrubel): report error indicating conditional should
          // be moved before combinators
        }
      }

      if (optional('deferred', token) && !optional('as', token.next)) {
        listener.handleImportPrefix(token, null);
        token = token.next;
      } else {
        token = parseImportPrefixOpt(token);
      }
      if (recoveryListener.deferredKeyword != null) {
        if (firstDeferredKeyword != null) {
          reportRecoverableError(
              recoveryListener.deferredKeyword, fasta.messageDuplicateDeferred);
        } else {
          if (hasPrefix) {
            reportRecoverableError(recoveryListener.deferredKeyword,
                fasta.messageDeferredAfterPrefix);
          }
          firstDeferredKeyword = recoveryListener.deferredKeyword;
        }
      }
      if (recoveryListener.asKeyword != null) {
        if (hasPrefix) {
          reportRecoverableError(
              recoveryListener.asKeyword, fasta.messageDuplicatePrefix);
        } else {
          if (hasCombinator) {
            reportRecoverableError(
                recoveryListener.asKeyword, fasta.messagePrefixAfterCombinator);
          }
          hasPrefix = true;
        }
      }

      token = parseCombinators(token);
      hasCombinator = hasCombinator || recoveryListener.hasCombinator;

      if (optional(';', token)) {
        semicolon = token;
      } else if (identical(start, token)) {
        // If no forward progress was made, insert ';' so that we exit loop.
        semicolon = ensureSemicolon(token);
      }
      listener.handleRecoverImport(semicolon);
    } while (semicolon == null);

    if (firstDeferredKeyword != null && !hasPrefix) {
      reportRecoverableError(
          firstDeferredKeyword, fasta.messageMissingPrefixInDeferredImport);
    }

    return semicolon;
  }

  /// ```
  /// conditionalUris:
  ///   conditionalUri*
  /// ;
  /// ```
  Token parseConditionalUris(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    // TODO(brianwilkerson) Return the last consumed token.
    // TODO(brianwilkerson): Rename to `parseConditionalUrisStar`?
    listener.beginConditionalUris(token);
    int count = 0;
    while (optional('if', token)) {
      count++;
      token = parseConditionalUri(token);
    }
    listener.endConditionalUris(count);
    return token;
  }

  /// ```
  /// conditionalUri:
  ///   'if' '(' dottedName ('==' literalString)? ')' uri
  /// ;
  /// ```
  Token parseConditionalUri(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    // TODO(brianwilkerson) Return the last consumed token.
    listener.beginConditionalUri(token);
    Token ifKeyword = token;
    token = expect('if', token);
    Token leftParen = token;
    token = expect('(', token);
    token = parseDottedName(token).next;
    Token equalitySign;
    if (optional('==', token)) {
      equalitySign = token;
      token = parseLiteralStringOrRecoverExpression(token.next);
    }
    token = expect(')', token);
    token = parseLiteralStringOrRecoverExpression(token);
    listener.endConditionalUri(ifKeyword, leftParen, equalitySign);
    return token;
  }

  /// ```
  /// dottedName:
  ///   identifier ('.' identifier)*
  /// ;
  /// ```
  Token parseDottedName(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    token = ensureIdentifier(token, IdentifierContext.dottedName);
    Token firstIdentifier = token;
    listener.beginDottedName(firstIdentifier);
    int count = 1;
    while (optional('.', token.next)) {
      token = ensureIdentifier(
          token.next.next, IdentifierContext.dottedNameContinuation);
      count++;
    }
    listener.endDottedName(count, firstIdentifier);
    return token;
  }

  /// ```
  /// exportDirective:
  ///   'export' uri conditional-uris* combinator* ';'
  /// ;
  /// ```
  Token parseExport(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    assert(optional('export', token));
    Token exportKeyword = token;
    listener.beginExport(exportKeyword);
    token = ensureParseLiteralString(token.next).next;
    token = parseConditionalUris(token);
    token = parseCombinators(token);
    token = ensureSemicolon(token);
    listener.endExport(exportKeyword, token);
    return token;
  }

  /// ```
  /// combinators:
  ///   (hideCombinator | showCombinator)*
  /// ;
  /// ```
  Token parseCombinators(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    // TODO(brianwilkerson) Return the last consumed token.
    // TODO(brianwilkerson): Rename to `parseCombinatorsStar`?
    listener.beginCombinators(token);
    int count = 0;
    while (true) {
      String value = token.stringValue;
      if (identical('hide', value)) {
        token = parseHide(token).next;
      } else if (identical('show', value)) {
        token = parseShow(token).next;
      } else {
        listener.endCombinators(count);
        break;
      }
      count++;
    }
    return token;
  }

  /// ```
  /// hideCombinator:
  ///   'hide' identifierList
  /// ;
  /// ```
  Token parseHide(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    assert(optional('hide', token));
    Token hideKeyword = token;
    listener.beginHide(hideKeyword);
    token = parseIdentifierList(token.next);
    listener.endHide(hideKeyword);
    return token;
  }

  /// ```
  /// showCombinator:
  ///   'show' identifierList
  /// ;
  /// ```
  Token parseShow(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    assert(optional('show', token));
    Token showKeyword = token;
    listener.beginShow(showKeyword);
    token = parseIdentifierList(token.next);
    listener.endShow(showKeyword);
    return token;
  }

  /// ```
  /// identifierList:
  ///   identifier (',' identifier)*
  /// ;
  /// ```
  Token parseIdentifierList(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    token = ensureIdentifier(token, IdentifierContext.combinator);
    listener.beginIdentifierList(token);
    int count = 1;
    while (optional(',', token.next)) {
      token = ensureIdentifier(token.next.next, IdentifierContext.combinator);
      count++;
    }
    listener.endIdentifierList(count);
    return token;
  }

  /// ```
  /// typeList:
  ///   type (',' type)*
  /// ;
  /// ```
  Token parseTypeList(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    // TODO(brianwilkerson) Return the last consumed token.
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

  Token parsePartOrPartOf(Token token, DirectiveContext directiveState) {
    // TODO(brianwilkerson) Accept the last consumed token.
    assert(optional('part', token));
    if (optional('of', token.next)) {
      directiveState?.checkPartOf(this, token);
      return parsePartOf(token);
    } else {
      directiveState?.checkPart(this, token);
      return parsePart(token);
    }
  }

  /// ```
  /// partDirective:
  ///   'part' uri ';'
  /// ;
  /// ```
  Token parsePart(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    assert(optional('part', token));
    Token partKeyword = token;
    listener.beginPart(token);
    token = parseLiteralStringOrRecoverExpression(token.next);
    token = ensureSemicolon(token);
    listener.endPart(partKeyword, token);
    return token;
  }

  /// ```
  /// partOfDirective:
  ///   'part' 'of' (qualified | uri) ';'
  /// ;
  /// ```
  Token parsePartOf(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    assert(optional('part', token));
    assert(optional('of', token.next));
    listener.beginPartOf(token);
    Token partKeyword = token;
    Token ofKeyword = token.next;
    token = ofKeyword.next;
    bool hasName = token.isIdentifier;
    if (hasName) {
      token = parseQualified(token, IdentifierContext.partName,
              IdentifierContext.partNameContinuation)
          .next;
    } else {
      token = parseLiteralStringOrRecoverExpression(token);
    }
    token = ensureSemicolon(token);
    listener.endPartOf(partKeyword, ofKeyword, token, hasName);
    return token;
  }

  /// ```
  /// metadata:
  ///   annotation*
  /// ;
  /// ```
  Token parseMetadataStar(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    // TODO(brianwilkerson) Return the last consumed token.
    token = listener.injectGenericCommentTypeAssign(token);
    // TODO(brianwilkerson): Remove the `token` because we cannot make any
    // guarantee about which token it will be.
    listener.beginMetadataStar(token);
    int count = 0;
    while (optional('@', token)) {
      token = parseMetadata(token);
      count++;
    }
    listener.endMetadataStar(count);
    return token;
  }

  /// ```
  /// annotation:
  ///   '@' qualified ('.' identifier)? arguments?
  /// ;
  /// ```
  Token parseMetadata(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    // TODO(brianwilkerson) Return the last consumed token.
    assert(optional('@', token));
    listener.beginMetadata(token);
    Token atToken = token;
    token = ensureIdentifier(token.next, IdentifierContext.metadataReference);
    token = parseQualifiedRestOpt(token, IdentifierContext.metadataContinuation)
        .next;
    if (optional("<", token)) {
      reportRecoverableError(token, fasta.messageMetadataTypeArguments);
    }
    token = parseTypeArgumentsOpt(token);
    Token period = null;
    if (optional('.', token)) {
      period = token;
      token = ensureIdentifier(token.next,
              IdentifierContext.metadataContinuationAfterTypeArguments)
          .next;
    }
    token = parseArgumentsOpt(token);
    listener.endMetadata(atToken, period, token);
    return token;
  }

  /// ```
  /// scriptTag:
  ///   '#!' (˜NEWLINE)* NEWLINE
  /// ;
  /// ```
  Token parseScript(Token token) {
    token = token.next;
    assert(identical(token.type, TokenType.SCRIPT_TAG));
    listener.handleScript(token);
    return token;
  }

  /// ```
  /// typeAlias:
  ///   metadata 'typedef' typeAliasBody
  /// ;
  ///
  /// typeAliasBody:
  ///   functionTypeAlias
  /// ;
  ///
  /// functionTypeAlias:
  ///   functionPrefix typeParameters? formalParameterList ‘;’
  /// ;
  ///
  /// functionPrefix:
  ///   returnType? identifier
  /// ;
  /// ```
  Token parseTypedef(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    assert(optional('typedef', token));
    Token typedefKeyword = token;
    listener.beginFunctionTypeAlias(token);
    Token equals;
    Token afterType = parseType(token.next, TypeContinuation.Typedef);
    if (afterType == null) {
      token = ensureIdentifier(token.next, IdentifierContext.typedefDeclaration)
          .next;
      token = parseTypeVariablesOpt(token);
      equals = token;
      token = expect('=', token);
      token = parseType(token);
    } else {
      token = ensureIdentifier(afterType, IdentifierContext.typedefDeclaration)
          .next;
      token = parseTypeVariablesOpt(token);
      token =
          parseFormalParametersRequiredOpt(token, MemberKind.FunctionTypeAlias)
              .next;
    }
    token = ensureSemicolon(token);
    listener.endFunctionTypeAlias(typedefKeyword, equals, token);
    return token;
  }

  /// Parse a mixin application starting from `with`. Assumes that the first
  /// type has already been parsed.
  Token parseMixinApplicationRest(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    // TODO(brianwilkerson) Return the last consumed token.
    listener.beginMixinApplication(token);
    Token withKeyword = token;
    token = expect('with', token);
    token = parseTypeList(token);
    listener.endMixinApplication(withKeyword);
    return token;
  }

  Token parseFormalParametersOpt(Token token, MemberKind kind) {
    // TODO(brianwilkerson) Accept the last consumed token.
    // TODO(brianwilkerson) Return the last consumed token.
    if (optional('(', token)) {
      return parseFormalParameters(token, kind).next;
    } else {
      listener.handleNoFormalParameters(token, kind);
      return token;
    }
  }

  Token skipFormalParameters(Token token, MemberKind kind) {
    // TODO(brianwilkerson) Accept the last consumed token.
    // TODO(ahe): Shouldn't this be `beginFormalParameters`?
    assert(optional('(', token));
    listener.beginOptionalFormalParameters(token);
    Token closeBrace = closeBraceTokenFor(token);
    listener.endFormalParameters(0, token, closeBrace, kind);
    return closeBrace;
  }

  /// Parses the formal parameter list of a function.
  ///
  /// If `kind == MemberKind.GeneralizedFunctionType`, then names may be
  /// omitted (except for named arguments). Otherwise, types may be omitted.
  Token parseFormalParametersRequiredOpt(Token token, MemberKind kind) {
    // TODO(brianwilkerson) Accept the last consumed token.
    if (!optional('(', token)) {
      reportRecoverableError(token, missingParameterMessage(kind));
      Token replacement = link(
          new SyntheticBeginToken(TokenType.OPEN_PAREN, token.charOffset),
          new SyntheticToken(TokenType.CLOSE_PAREN, token.charOffset));
      token = rewriter.insertToken(replacement, token);
    }
    return parseFormalParameters(token, kind);
  }

  /// Parses the formal parameter list of a function given that the left
  /// parenthesis is known to exist.
  ///
  /// If `kind == MemberKind.GeneralizedFunctionType`, then names may be
  /// omitted (except for named arguments). Otherwise, types may be omitted.
  Token parseFormalParameters(Token token, MemberKind kind) {
    // TODO(brianwilkerson) Accept the last consumed token.
    assert(optional('(', token));
    Token begin = token;
    listener.beginFormalParameters(begin, kind);
    int parameterCount = 0;
    do {
      token = token.next;
      if (optional(')', token)) {
        break;
      }
      ++parameterCount;
      String value = token.stringValue;
      if (identical(value, '[')) {
        token = parseOptionalFormalParameters(token, false, kind).next;
        break;
      } else if (identical(value, '{')) {
        token = parseOptionalFormalParameters(token, true, kind).next;
        break;
      } else if (identical(value, '[]')) {
        --parameterCount;
        reportRecoverableError(token, fasta.messageEmptyOptionalParameterList);
        token = token.next;
        break;
      }
      token = parseFormalParameter(token, FormalParameterKind.mandatory, kind);
    } while (optional(',', token));
    listener.endFormalParameters(parameterCount, begin, token, kind);
    expect(')', token);
    return token;
  }

  /// Return the message that should be produced when the formal parameters are
  /// missing.
  Message missingParameterMessage(MemberKind kind) {
    if (kind == MemberKind.FunctionTypeAlias) {
      return fasta.messageMissingTypedefParameters;
    } else if (kind == MemberKind.NonStaticMethod ||
        kind == MemberKind.StaticMethod ||
        kind == MemberKind.TopLevelMethod) {
      return fasta.messageMissingMethodParameters;
    }
    return fasta.messageMissingFunctionParameters;
  }

  /// ```
  /// normalFormalParameter:
  ///   functionFormalParameter |
  ///   fieldFormalParameter |
  ///   simpleFormalParameter
  /// ;
  ///
  /// functionFormalParameter:
  ///   metadata 'covariant'? returnType? identifier formalParameterList
  /// ;
  ///
  /// simpleFormalParameter:
  ///   metadata 'covariant'? finalConstVarOrType? identifier |
  /// ;
  ///
  /// fieldFormalParameter:
  ///   metadata finalConstVarOrType? 'this' '.' identifier formalParameterList?
  /// ;
  /// ```
  Token parseFormalParameter(
      Token token, FormalParameterKind parameterKind, MemberKind memberKind) {
    // TODO(brianwilkerson) Accept the last consumed token.
    // TODO(brianwilkerson) Return the last consumed token.
    token = parseMetadataStar(token);
    listener.beginFormalParameter(token, memberKind);
    token = parseModifiers(token, memberKind, parameterKind: parameterKind);
    return token;
  }

  /// ```
  /// defaultFormalParameter:
  ///   normalFormalParameter ('=' expression)?
  /// ;
  ///
  /// defaultNamedParameter:
  ///   normalFormalParameter ('=' expression)? |
  ///   normalFormalParameter (':' expression)?
  /// ;
  /// ```
  Token parseOptionalFormalParameters(
      Token token, bool isNamed, MemberKind kind) {
    // TODO(brianwilkerson) Accept the last consumed token.
    assert(isNamed ? optional('{', token) : optional('[', token));
    Token begin = token;
    listener.beginOptionalFormalParameters(begin);
    int parameterCount = 0;
    do {
      token = token.next;
      if (isNamed && optional('}', token)) {
        break;
      } else if (!isNamed && optional(']', token)) {
        break;
      }
      var type = isNamed
          ? FormalParameterKind.optionalNamed
          : FormalParameterKind.optionalPositional;
      token = parseFormalParameter(token, type, kind);
      ++parameterCount;
    } while (optional(',', token));
    if (parameterCount == 0) {
      reportRecoverableError(
          token,
          isNamed
              ? fasta.messageEmptyNamedParameterList
              : fasta.messageEmptyOptionalParameterList);
    }
    listener.endOptionalFormalParameters(parameterCount, begin, token);
    if (isNamed) {
      expect('}', token);
    } else {
      expect(']', token);
    }
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

  /// Returns `true` if [token] matches '<' type (',' type)* '>' '(', and
  /// otherwise returns `false`. The final '(' is not part of the grammar
  /// construct `typeArguments`, but it is required here such that type
  /// arguments in generic method invocations can be recognized, and as few as
  /// possible other constructs will pass (e.g., 'a < C, D > 3').
  bool isValidMethodTypeArguments(Token token) {
    Token Function(Token token) tryParseType;

    /// Returns token after match if [token] matches '<' type (',' type)* '>'
    /// '(', and otherwise returns null. Does not produce listener events. With
    /// respect to the final '(', please see the description of
    /// [isValidMethodTypeArguments].
    Token tryParseMethodTypeArguments(Token token) {
      if (!identical(token.kind, LT_TOKEN)) return null;
      Token endToken = closeBraceTokenFor(token);
      if (endToken == null ||
          !identical(endToken.next.kind, OPEN_PAREN_TOKEN)) {
        return null;
      }
      token = tryParseType(token.next);
      while (token != null && identical(token.kind, COMMA_TOKEN)) {
        token = tryParseType(token.next);
      }
      if (token == null || !identical(token.kind, GT_TOKEN)) return null;
      return token.next;
    }

    /// Returns token after match if [token] matches identifier ('.'
    /// identifier)?, and otherwise returns null. Does not produce listener
    /// events.
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
    /// '>' may be the first character in a '>>' token, in which case a
    /// synthetic '>' token is created and returned, representing the second
    /// '>' in the '>>' token.
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

    /// Returns token after match if [token] matches typeName typeArguments?,
    /// and otherwise returns null. Does not produce listener events.
    tryParseType = (Token token) {
      token = tryParseQualified(token);
      if (token == null) return null;
      Token tokenAfterQualified = token;
      token = tryParseNestedTypeArguments(token);
      return token == null ? tokenAfterQualified : token;
    };

    return tryParseMethodTypeArguments(token) != null;
  }

  /// ```
  /// qualified:
  ///   identifier qualifiedRest*
  /// ;
  /// ```
  Token parseQualified(Token token, IdentifierContext context,
      IdentifierContext continuationContext) {
    // TODO(brianwilkerson) Accept the last consumed token.
    token = ensureIdentifier(token, context);
    while (optional('.', token.next)) {
      token = parseQualifiedRest(token, continuationContext);
    }
    return token;
  }

  /// ```
  /// qualifiedRestOpt:
  ///   qualifiedRest?
  /// ;
  /// ```
  Token parseQualifiedRestOpt(
      Token token, IdentifierContext continuationContext) {
    if (optional('.', token.next)) {
      return parseQualifiedRest(token, continuationContext);
    } else {
      return token;
    }
  }

  /// ```
  /// qualifiedRest:
  ///   '.' identifier
  /// ;
  /// ```
  Token parseQualifiedRest(Token token, IdentifierContext context) {
    token = token.next;
    assert(optional('.', token));
    Token period = token;
    token = ensureIdentifier(token.next, context);
    listener.handleQualified(period);
    return token;
  }

  Token skipBlock(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    if (!optional('{', token)) {
      return reportUnrecoverableError(token, fasta.messageExpectedBlockToSkip)
          .next;
    }
    Token closeBrace = closeBraceTokenFor(token);
    if (closeBrace == null ||
        !identical(closeBrace.kind, $CLOSE_CURLY_BRACKET)) {
      return reportUnmatchedToken(token).next;
    }
    return closeBrace;
  }

  /// ```
  /// enumType:
  ///   metadata 'enum' id '{' id [',' id]* [','] '}'
  /// ;
  /// ```
  Token parseEnum(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    assert(optional('enum', token));
    listener.beginEnum(token);
    Token enumKeyword = token;
    token =
        ensureIdentifier(token.next, IdentifierContext.enumDeclaration).next;
    Token leftBrace = token;
    token = expect('{', token);
    int count = 0;
    if (!optional('}', token)) {
      Token before = token;
      token = parseMetadataStar(token);
      if (!identical(token, before)) {
        reportRecoverableError(before, fasta.messageAnnotationOnEnumConstant);
      }
      token =
          ensureIdentifier(token, IdentifierContext.enumValueDeclaration).next;
      count++;
      while (optional(',', token)) {
        token = token.next;
        if (optional('}', token)) break;
        Token before = token;
        token = parseMetadataStar(token);
        if (!identical(token, before)) {
          reportRecoverableError(before, fasta.messageAnnotationOnEnumConstant);
        }
        token = ensureIdentifier(token, IdentifierContext.enumValueDeclaration)
            .next;
        count++;
      }
    } else {
      reportRecoverableError(token, fasta.messageEnumDeclarationEmpty);
    }
    expect('}', token);
    listener.endEnum(enumKeyword, leftBrace, count);
    return token;
  }

  Token parseClassOrNamedMixinApplication(Token abstractToken, Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    listener.beginClassOrNamedMixinApplication(token);
    Token begin = abstractToken ?? token;
    if (abstractToken != null) {
      token = parseModifier(abstractToken).next;
      listener.handleModifiers(1);
    } else {
      listener.handleModifiers(0);
    }
    Token classKeyword = token;
    token = expect("class", token);
    Token name =
        ensureIdentifier(token, IdentifierContext.classOrNamedMixinDeclaration);
    token = parseTypeVariablesOpt(name.next);
    if (optional('=', token)) {
      listener.beginNamedMixinApplication(begin, name);
      return parseNamedMixinApplication(token, begin, classKeyword);
    } else {
      listener.beginClassDeclaration(begin, name);
      return parseClass(token, begin, classKeyword);
    }
  }

  Token parseNamedMixinApplication(
      Token token, Token begin, Token classKeyword) {
    // TODO(brianwilkerson) Accept the last consumed token.
    assert(optional('=', token));
    Token equals = token;
    token = parseType(token.next);
    token = parseMixinApplicationRest(token);
    Token implementsKeyword = null;
    if (optional('implements', token)) {
      implementsKeyword = token;
      token = parseTypeList(token.next);
    }
    token = ensureSemicolon(token);
    listener.endNamedMixinApplication(
        begin, classKeyword, equals, implementsKeyword, token);
    return token;
  }

  /// Parse the portion of a class declaration (not a mixin application) that
  /// follows the end of the type parameters.
  ///
  /// ```
  /// classDefinition:
  ///   metadata abstract? 'class' identifier typeParameters?
  ///       (superclass mixins?)? interfaces?
  ///       '{' (metadata classMemberDefinition)* '}' |
  ///   metadata abstract? 'class' mixinApplicationClass
  /// ;
  /// ```
  Token parseClass(Token token, Token begin, Token classKeyword) {
    // TODO(brianwilkerson) Accept the last consumed token.
    Token start = token;
    token = parseClassHeader(token, begin, classKeyword);
    if (!optional('{', token)) {
      // Recovery
      token = parseClassHeaderRecovery(start, begin, classKeyword);
    }
    token = parseClassBody(token, start);
    listener.endClassDeclaration(begin, token);
    return token;
  }

  Token parseClassHeader(Token token, Token begin, Token classKeyword) {
    // TODO(brianwilkerson) Accept the last consumed token.
    // TODO(brianwilkerson) Return the last consumed token.
    // TODO(brianwilkerson): Rename to `parseClassHeaderOpt`?
    token = parseClassExtendsOpt(token);
    token = parseClassImplementsOpt(token);
    Token nativeToken;
    if (optional('native', token)) {
      nativeToken = token;
      token = parseNativeClause(nativeToken).next;
    }
    listener.handleClassHeader(begin, classKeyword, nativeToken);
    return token;
  }

  /// Recover given out-of-order clauses in a class header.
  Token parseClassHeaderRecovery(Token token, Token begin, Token classKeyword) {
    // TODO(brianwilkerson) Accept the last consumed token.
    // TODO(brianwilkerson) Return the last consumed token.
    final primaryListener = listener;
    final recoveryListener = new ClassHeaderRecoveryListener(primaryListener);

    // Reparse to determine which clauses have already been parsed
    // but intercept the events so they are not sent to the primary listener.
    listener = recoveryListener;
    token = parseClassHeader(token, begin, classKeyword);
    bool hasExtends = recoveryListener.extendsKeyword != null;
    bool hasImplements = recoveryListener.implementsKeyword != null;
    Token withKeyword = recoveryListener.withKeyword;

    // Update the recovery listener to forward subsequent events
    // to the primary listener.
    recoveryListener.listener = primaryListener;

    // Parse additional out-of-order clauses
    Token start;
    do {
      start = token;

      // Check for extraneous token in the middle of a class header.
      token = skipUnexpectedTokenOpt(
          token, const <String>['extends', 'with', 'implements', '{']);

      // During recovery, clauses are parsed in the same order
      // and generate the same events as in the parseClassHeader method above.
      recoveryListener.clear();
      if (optional('with', token)) {
        // If there is a `with` clause without a preceding `extends` clause
        // then insert a synthetic `extends` clause and parse both clauses.
        Token extendsKeyword =
            new SyntheticKeywordToken(Keyword.EXTENDS, token.offset);
        Token superclassToken = new SyntheticStringToken(
            TokenType.IDENTIFIER, 'Object', token.offset);
        rewriter.insertToken(extendsKeyword, token);
        rewriter.insertToken(superclassToken, token);
        token = parseType(superclassToken);
        token = parseMixinApplicationRest(token);
        listener.handleClassExtends(extendsKeyword);
      } else {
        token = parseClassExtendsOpt(token);

        if (recoveryListener.extendsKeyword != null) {
          if (hasExtends) {
            reportRecoverableError(
                recoveryListener.extendsKeyword, fasta.messageMultipleExtends);
          } else {
            if (withKeyword != null) {
              reportRecoverableError(recoveryListener.extendsKeyword,
                  fasta.messageWithBeforeExtends);
            } else if (hasImplements) {
              reportRecoverableError(recoveryListener.extendsKeyword,
                  fasta.messageImplementsBeforeExtends);
            }
            hasExtends = true;
          }
        }
      }

      if (recoveryListener.withKeyword != null) {
        if (withKeyword != null) {
          reportRecoverableError(
              recoveryListener.withKeyword, fasta.messageMultipleWith);
        } else {
          if (hasImplements) {
            reportRecoverableError(recoveryListener.withKeyword,
                fasta.messageImplementsBeforeWith);
          }
          withKeyword = recoveryListener.withKeyword;
        }
      }

      token = parseClassImplementsOpt(token);

      if (recoveryListener.implementsKeyword != null) {
        if (hasImplements) {
          reportRecoverableError(recoveryListener.implementsKeyword,
              fasta.messageMultipleImplements);
        } else {
          hasImplements = true;
        }
      }

      listener.handleRecoverClassHeader();

      // Exit if a class body is detected, or if no progress has been made
    } while (!optional('{', token) && start != token);

    if (withKeyword != null && !hasExtends) {
      reportRecoverableError(withKeyword, fasta.messageWithWithoutExtends);
    }

    listener = primaryListener;
    return token;
  }

  Token parseClassExtendsOpt(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    // TODO(brianwilkerson) Return the last consumed token.
    if (optional('extends', token)) {
      Token extendsKeyword = token;
      token = parseType(token.next);
      if (optional('with', token)) {
        token = parseMixinApplicationRest(token);
      }
      listener.handleClassExtends(extendsKeyword);
    } else {
      listener.handleNoType(token);
      listener.handleClassExtends(null);
    }
    return token;
  }

  /// ```
  /// implementsClause:
  ///   'implements' typeName (',' typeName)*
  /// ;
  /// ```
  Token parseClassImplementsOpt(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    // TODO(brianwilkerson) Return the last consumed token.
    Token implementsKeyword;
    int interfacesCount = 0;
    if (optional('implements', token)) {
      implementsKeyword = token;
      do {
        token = parseType(token.next);
        ++interfacesCount;
      } while (optional(',', token));
    }
    listener.handleClassImplements(implementsKeyword, interfacesCount);
    return token;
  }

  Token parseStringPart(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    if (token.kind != STRING_TOKEN) {
      token =
          reportUnrecoverableErrorWithToken(token, fasta.templateExpectedString)
              .next;
    }
    listener.handleStringPart(token);
    return token;
  }

  /// Insert a synthetic identifier before the given [token] and create an error
  /// message based on the given [context]. Return the synthetic identifier that
  /// was inserted.
  Token insertSyntheticIdentifier(Token token, IdentifierContext context) {
    Message message = context.recoveryTemplate.withArguments(token);
    Token identifier =
        new SyntheticStringToken(TokenType.IDENTIFIER, '', token.charOffset, 0);
    return rewriteAndRecover(token, message, identifier);
  }

  /// Parse a simple identifier at the given [token], and return the identifier
  /// that was parsed.
  ///
  /// If the token is not an identifier, or is not appropriate for use as an
  /// identifier in the given [context], create a synthetic identifier, report
  /// an error, and return the synthetic identifier.
  Token ensureIdentifier(Token token, IdentifierContext context) {
    if (!token.isIdentifier) {
      if (optional("void", token)) {
        reportRecoverableError(token, fasta.messageInvalidVoid);
      } else if (token is ErrorToken) {
        // TODO(brianwilkerson): This preserves the current semantics, but the
        // listener should not be recovering from this case, so this needs to be
        // reworked to recover in this method (probably inside the outermost
        // if statement).
        token =
            reportUnrecoverableErrorWithToken(token, context.recoveryTemplate)
                .next;
      } else if (isIdentifierForRecovery(token, context)) {
        reportRecoverableErrorWithToken(token, context.recoveryTemplate);
      } else if (isPostIdentifierForRecovery(token, context) ||
          isStartOfNextSibling(token, context)) {
        token = insertSyntheticIdentifier(token, context);
      } else {
        reportRecoverableErrorWithToken(token, context.recoveryTemplate);
      }
    } else if (token.type.isBuiltIn && !context.isBuiltInIdentifierAllowed) {
      if (context.inDeclaration) {
        reportRecoverableErrorWithToken(
            token, fasta.templateBuiltInIdentifierInDeclaration);
      } else if (!optional("dynamic", token)) {
        reportRecoverableErrorWithToken(
            token, fasta.templateBuiltInIdentifierAsType);
      }
    } else if (!inPlainSync && token.type.isPseudo) {
      if (optional('await', token)) {
        reportRecoverableError(token, fasta.messageAwaitAsIdentifier);
      } else if (optional('yield', token)) {
        reportRecoverableError(token, fasta.messageYieldAsIdentifier);
      } else if (optional('async', token)) {
        reportRecoverableError(token, fasta.messageAsyncAsIdentifier);
      }
    }
    listener.handleIdentifier(token, context);
    return token;
  }

  /// Return `true` if the given [token] should be treated like an identifier in
  /// the given [context] for the purposes of recovery.
  bool isIdentifierForRecovery(Token token, IdentifierContext context) {
    if (!token.type.isKeyword) {
      return false;
    }
    return isPostIdentifierForRecovery(token.next, context);
  }

  /// Return `true` if the given [token] appears to be a token that would be
  /// expected after an identifier in the given [context].
  bool isPostIdentifierForRecovery(Token token, IdentifierContext context) {
    if (token.isEof) {
      return true;
    }
    List<String> followingValues;
    if (context == IdentifierContext.classOrNamedMixinDeclaration) {
      followingValues = ['<', 'extends', 'with', 'implements', '{'];
    } else if (context == IdentifierContext.fieldDeclaration) {
      followingValues = [';', '=', ','];
    } else if (context == IdentifierContext.enumDeclaration) {
      followingValues = ['{'];
    } else if (context == IdentifierContext.enumValueDeclaration) {
      followingValues = [',', '}'];
    } else if (context == IdentifierContext.expression ||
        context == IdentifierContext.expressionContinuation) {
      if (token.isOperator) {
        return true;
      }
      followingValues = [
        ',',
        '(',
        ')',
        '[',
        ']',
        '}',
        '?',
        ':',
        'as',
        'is',
        ';'
      ];
    } else if (context == IdentifierContext.formalParameterDeclaration) {
      followingValues = [':', '=', ',', '(', ')', '[', ']', '{', '}'];
    } else if (context == IdentifierContext.importPrefixDeclaration) {
      followingValues = [';', 'hide', 'show', 'deferred', 'as'];
    } else if (context == IdentifierContext.labelDeclaration) {
      followingValues = [':'];
    } else if (context == IdentifierContext.libraryName ||
        context == IdentifierContext.libraryNameContinuation) {
      followingValues = ['.', ';'];
    } else if (context == IdentifierContext.literalSymbol ||
        context == IdentifierContext.literalSymbolContinuation) {
      followingValues = ['.', ';'];
    } else if (context == IdentifierContext.localAccessorDeclaration) {
      followingValues = ['(', '{', '=>'];
    } else if (context == IdentifierContext.localFunctionDeclaration ||
        context == IdentifierContext.localFunctionDeclarationContinuation) {
      followingValues = ['.', '(', '{', '=>'];
    } else if (context == IdentifierContext.localVariableDeclaration) {
      followingValues = [';', '=', ','];
    } else if (context == IdentifierContext.methodDeclaration ||
        context == IdentifierContext.methodDeclarationContinuation) {
      followingValues = ['.', '(', '{', '=>'];
    } else if (context == IdentifierContext.topLevelFunctionDeclaration) {
      followingValues = ['(', '{', '=>'];
    } else if (context == IdentifierContext.topLevelVariableDeclaration) {
      followingValues = [';', '=', ','];
    } else if (context == IdentifierContext.typedefDeclaration) {
      followingValues = ['(', '<', ';'];
    } else if (context == IdentifierContext.typeReference ||
        context == IdentifierContext.typeReferenceContinuation) {
      followingValues = ['>', ')', ']', '}', ';'];
    } else if (context == IdentifierContext.typeVariableDeclaration) {
      followingValues = ['<', '>'];
    } else {
      return false;
    }
    for (String tokenValue in followingValues) {
      if (optional(tokenValue, token)) {
        return true;
      }
    }
    return false;
  }

  /// Return `true` if the given [token] appears to be the start of a (virtual)
  /// node that would be a sibling of the current node or one of its parents.
  /// The type of the current node is suggested by the given [context].
  bool isStartOfNextSibling(Token token, IdentifierContext context) {
    if (!token.type.isKeyword) {
      return false;
    }

    List<String> classMemberKeywords() =>
        <String>['const', 'final', 'var', 'void'];
    List<String> statementKeywords() => <String>[
          'const',
          'do',
          'final',
          'if',
          'switch',
          'try',
          'var',
          'void',
          'while'
        ];
    List<String> topLevelKeywords() => <String>[
          'class',
          'const',
          'enum',
          'export',
          'final',
          'import',
          'library',
          'part',
          'typedef',
          'var',
          'void'
        ];

    // TODO(brianwilkerson): At the moment, this test is entirely based on data
    // that can be represented declaratively. If that proves to be sufficient,
    // then this data can be moved into a field in IdentifierContext and we
    // could create a method to test whether a given token matches one of the
    // patterns.
    List<String> initialKeywords;
    if (context == IdentifierContext.classOrNamedMixinDeclaration) {
      initialKeywords = topLevelKeywords();
    } else if (context == IdentifierContext.fieldDeclaration) {
      initialKeywords = classMemberKeywords();
    } else if (context == IdentifierContext.enumDeclaration) {
      initialKeywords = topLevelKeywords();
    } else if (context == IdentifierContext.formalParameterDeclaration) {
      initialKeywords = topLevelKeywords()
        ..addAll(classMemberKeywords())
        ..addAll(statementKeywords())
        ..add('covariant');
    } else if (context == IdentifierContext.importPrefixDeclaration) {
      initialKeywords = topLevelKeywords();
    } else if (context == IdentifierContext.labelDeclaration) {
      initialKeywords = statementKeywords();
    } else if (context == IdentifierContext.localAccessorDeclaration) {
      initialKeywords = statementKeywords();
    } else if (context == IdentifierContext.localFunctionDeclaration) {
      initialKeywords = statementKeywords();
    } else if (context ==
        IdentifierContext.localFunctionDeclarationContinuation) {
      initialKeywords = statementKeywords();
    } else if (context == IdentifierContext.localVariableDeclaration) {
      initialKeywords = statementKeywords();
    } else if (context == IdentifierContext.methodDeclaration) {
      initialKeywords = classMemberKeywords();
    } else if (context == IdentifierContext.methodDeclarationContinuation) {
      initialKeywords = classMemberKeywords();
    } else if (context == IdentifierContext.topLevelFunctionDeclaration) {
      initialKeywords = topLevelKeywords();
    } else if (context == IdentifierContext.topLevelVariableDeclaration) {
      initialKeywords = topLevelKeywords();
    } else if (context == IdentifierContext.typedefDeclaration) {
      initialKeywords = topLevelKeywords();
    } else if (context == IdentifierContext.typeVariableDeclaration) {
      initialKeywords = topLevelKeywords()
        ..addAll(classMemberKeywords())
        ..addAll(statementKeywords());
    } else {
      return false;
    }
    for (String tokenValue in initialKeywords) {
      if (optional(tokenValue, token)) {
        return true;
      }
    }
    return false;
  }

  Token expect(String string, Token token) {
    // TODO(danrubel): update all uses of expect(';'...) to ensureSemicolon
    // then add assert(!identical(';', string));
    if (!identical(string, token.stringValue)) {
      return reportUnrecoverableError(
              token, fasta.templateExpectedButGot.withArguments(string))
          .next;
    }
    return token.next;
  }

  /// ```
  /// typeVariable:
  ///   metadata? identifier (('extends' | 'super') typeName)?
  /// ;
  /// ```
  Token parseTypeVariable(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    // TODO(brianwilkerson) Return the last consumed token.
    listener.beginTypeVariable(token);
    token = parseMetadataStar(token);
    token =
        ensureIdentifier(token, IdentifierContext.typeVariableDeclaration).next;
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

  /// Returns `true` if the stringValue of the [token] is either [value1],
  /// [value2], or [value3].
  bool isOneOf3(Token token, String value1, String value2, String value3) {
    String stringValue = token.stringValue;
    return identical(value1, stringValue) ||
        identical(value2, stringValue) ||
        identical(value3, stringValue);
  }

  /// Returns `true` if the stringValue of the [token] is either [value1],
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

  /// Parse a type, if it is appropriate to do so.
  ///
  /// If this method can parse a type, it will return the next (non-null) token
  /// after the type. Otherwise, it returns null.
  Token parseType(Token token,
      [TypeContinuation continuation = TypeContinuation.Required,
      IdentifierContext continuationContext,
      MemberKind memberKind]) {
    // TODO(brianwilkerson) Accept the last consumed token.
    // TODO(brianwilkerson) Return the last consumed token.
    /// True if we've seen the `var` keyword.
    bool hasVar = false;

    /// Where the type begins.
    Token begin;

    /// Non-null if 'void' is the first token.
    Token voidToken;

    /// True if the tokens at [begin] looks like a type.
    bool looksLikeType = false;

    /// True if a type that could be a return type for a generalized function
    /// type was seen during analysis.
    bool hasReturnType = false;

    /// The identifier context to use for parsing the type.
    IdentifierContext context = IdentifierContext.typeReference;

    /// Non-null if type arguments were seen during analysis.
    Token typeArguments;

    /// The number of function types seen during analysis.
    int functionTypes = 0;

    /// The start of type variables of function types seen during
    /// analysis. Notice that the tokens in this list might be either `'<'` or
    /// `'('` as not all function types have type parameters. Also, it is safe
    /// to assume that [closeBraceTokenFor] will return non-null for all these tokens.
    Link<Token> typeVariableStarters = const Link<Token>();

    {
      // Analyse the next tokens to see if they could be a type.

      if (continuation ==
          TypeContinuation.ExpressionStatementOrConstDeclaration) {
        // This is a special case. The first token is `const` and we need to
        // analyze the tokens following the const keyword.
        assert(optional("const", token));
        begin = token;
        token = token.next;
        token = listener.injectGenericCommentTypeAssign(token);
        assert(begin.next == token);
      } else {
        // Modify [begin] in case generic type are injected from a comment.
        begin = token = listener.injectGenericCommentTypeAssign(token);
      }

      if (optional("void", token)) {
        // `void` is a type.
        looksLikeType = true;
        voidToken = token;
        token = token.next;
      } else if (isValidTypeReference(token) &&
          !isGeneralizedFunctionType(token)) {
        // We're looking at an identifier that could be a type (or `dynamic`).
        looksLikeType = true;
        token = token.next;
        if (optional(".", token) && isValidTypeReference(token.next)) {
          // We're looking at `prefix '.' identifier`.
          context = IdentifierContext.prefixedTypeReference;
          token = token.next.next;
        }
        if (optional("<", token)) {
          Token close = closeBraceTokenFor(token);
          if (close != null &&
              (optional(">", close) || optional(">>", close))) {
            // We found some type arguments.
            typeArguments = token;
            token = close.next;
          }
        }
      }

      // If what we have seen so far looks like a type, that could be a return
      // type for a generalized function type.
      hasReturnType = looksLikeType;

      while (optional("Function", token)) {
        Token typeVariableStart = token.next;
        if (optional("<", token.next)) {
          Token close = closeBraceTokenFor(token.next);
          if (close != null && optional(">", close)) {
            token = close;
          } else {
            break; // Not a function type.
          }
        }
        if (optional("(", token.next)) {
          // This is a function type.
          Token close = closeBraceTokenFor(token.next);
          assert(optional(")", close));
          looksLikeType = true;
          functionTypes++;
          typeVariableStarters =
              typeVariableStarters.prepend(typeVariableStart);
          token = close.next;
        } else {
          break; // Not a function type.
        }
      }
    }

    /// Call this function when it's known that [begin] is a type. This
    /// function will call the appropriate event methods on [listener] to
    /// handle the type.
    Token commitType() {
      int count = 0;
      for (Token typeVariableStart in typeVariableStarters) {
        count++;
        parseTypeVariablesOpt(typeVariableStart);
        listener.beginFunctionType(begin);
      }
      assert(count == functionTypes);

      if (functionTypes > 0 && !hasReturnType) {
        // A function type without return type.
        // Push the non-existing return type first. The loop below will
        // generate the full type.
        listener.handleNoType(begin);
        token = begin;
      } else if (functionTypes > 0 && voidToken != null) {
        listener.handleVoidKeyword(voidToken);
        token = voidToken.next;
      } else {
        token = ensureIdentifier(begin, context);
        token = parseQualifiedRestOpt(
                token, IdentifierContext.typeReferenceContinuation)
            .next;
        assert(typeArguments == null || typeArguments == token);
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

      for (int i = 0; i < functionTypes; i++) {
        assert(optional('Function', token));
        Token functionToken = token;
        token = token.next;
        if (optional("<", token)) {
          // Skip type parameters, they were parsed above.
          token = closeBraceTokenFor(token).next;
        }
        token = parseFormalParametersRequiredOpt(
                token, MemberKind.GeneralizedFunctionType)
            .next;
        listener.endFunctionType(functionToken, token);
      }

      if (hasVar) {
        reportRecoverableError(begin, fasta.messageTypeAfterVar);
      }

      return token;
    }

    /// Returns true if [kind] is '=', ';', or ',', that is, if [kind] could be
    /// the end of a variable declaration.
    bool looksLikeVariableDeclarationEnd(int kind) {
      return EQ_TOKEN == kind || SEMICOLON_TOKEN == kind || COMMA_TOKEN == kind;
    }

    /// Returns true if [token] could be the start of a function body.
    bool looksLikeFunctionBody(Token token) {
      return optional('{', token) ||
          optional('=>', token) ||
          optional('async', token) ||
          optional('sync', token);
    }

    /// Returns true if [token] could be the start of a function declaration
    /// without a return type.
    bool looksLikeFunctionDeclaration(Token token) {
      if (!token.isIdentifier) {
        return false;
      }
      token = token.next;
      if (optional('<', token)) {
        Token closeBrace = closeBraceTokenFor(token);
        if (closeBrace == null) return false;
        token = closeBrace.next;
      }
      if (optional('(', token)) {
        return looksLikeFunctionBody(closeBraceTokenFor(token).next);
      }
      return false;
    }

    FormalParameterKind parameterKind;
    switch (continuation) {
      case TypeContinuation.Required:
        // If the token after the type is not an identifier,
        // the report a missing type
        if (!token.isIdentifier) {
          if (memberKind == MemberKind.TopLevelField ||
              memberKind == MemberKind.NonStaticField ||
              memberKind == MemberKind.StaticField) {
            reportRecoverableError(
                begin, fasta.messageMissingConstFinalVarOrType);
            listener.handleNoType(begin);
            return begin;
          }
        }
        return commitType();

      optional:
      case TypeContinuation.Optional:
        if (looksLikeType) {
          if (functionTypes > 0) {
            return commitType(); // Parse function type.
          }
          if (voidToken != null) {
            listener.handleVoidKeyword(voidToken);
            return voidToken.next;
          }
          if (token.isIdentifier || optional('this', token)) {
            return commitType(); // Parse type.
          }
        }
        listener.handleNoType(begin);
        return begin;

      case TypeContinuation.OptionalAfterVar:
        hasVar = true;
        continue optional;

      case TypeContinuation.Typedef:
        if (optional('=', token)) {
          return null; // This isn't a type, it's a new-style typedef.
        }
        continue optional;

      case TypeContinuation.ExpressionStatementOrDeclaration:
        assert(begin.isIdentifier || identical(begin.stringValue, 'void'));
        if (!inPlainSync && optional("await", begin)) {
          return parseExpressionStatement(begin).next;
        }

        if (looksLikeType && token.isIdentifier) {
          Token afterId = token.next;

          int afterIdKind = afterId.kind;
          if (looksLikeVariableDeclarationEnd(afterIdKind)) {
            // We are looking at `type identifier` followed by
            // `(',' | '=' | ';')`.

            // TODO(ahe): Generate type events and call
            // parseVariablesDeclarationRest instead.
            return parseVariablesDeclaration(begin).next;
          } else if (OPEN_PAREN_TOKEN == afterIdKind) {
            // We are looking at `type identifier '('`.
            if (looksLikeFunctionBody(closeBraceTokenFor(afterId).next)) {
              // We are looking at `type identifier '(' ... ')'` followed
              // `( '{' | '=>' | 'async' | 'sync' )`.

              // Although it looks like there are no type variables here, they
              // may get injected from a comment.
              Token formals = parseTypeVariablesOpt(afterId);

              listener.beginLocalFunctionDeclaration(begin);
              listener.handleModifiers(0);
              if (voidToken != null) {
                listener.handleVoidKeyword(voidToken);
              } else {
                commitType();
              }
              return parseNamedFunctionRest(begin, token, formals, false);
            }
          } else if (identical(afterIdKind, LT_TOKEN)) {
            // We are looking at `type identifier '<'`.
            Token formals = closeBraceTokenFor(afterId)?.next;
            if (formals != null && optional("(", formals)) {
              if (looksLikeFunctionBody(closeBraceTokenFor(formals).next)) {
                // We are looking at "type identifier '<' ... '>' '(' ... ')'"
                // followed by '{', '=>', 'async', or 'sync'.
                parseTypeVariablesOpt(afterId);
                listener.beginLocalFunctionDeclaration(begin);
                listener.handleModifiers(0);
                if (voidToken != null) {
                  listener.handleVoidKeyword(voidToken);
                } else {
                  commitType();
                }
                return parseNamedFunctionRest(begin, token, formals, false);
              }
            }
          }
          // Fall-through to expression statement.
        } else {
          token = begin;
          if (optional(':', token.next)) {
            return parseLabeledStatement(token).next;
          } else if (optional('(', token.next)) {
            if (looksLikeFunctionBody(closeBraceTokenFor(token.next).next)) {
              // We are looking at `identifier '(' ... ')'` followed by `'{'`,
              // `'=>'`, `'async'`, or `'sync'`.

              // Although it looks like there are no type variables here, they
              // may get injected from a comment.
              Token formals = parseTypeVariablesOpt(token.next);

              listener.beginLocalFunctionDeclaration(token);
              listener.handleModifiers(0);
              listener.handleNoType(token);
              return parseNamedFunctionRest(begin, token, formals, false);
            }
          } else if (optional('<', token.next)) {
            Token afterTypeVariables = closeBraceTokenFor(token.next)?.next;
            if (afterTypeVariables != null &&
                optional("(", afterTypeVariables)) {
              if (looksLikeFunctionBody(
                  closeBraceTokenFor(afterTypeVariables).next)) {
                // We are looking at `identifier '<' ... '>' '(' ... ')'`
                // followed by `'{'`, `'=>'`, `'async'`, or `'sync'`.
                parseTypeVariablesOpt(token.next);
                listener.beginLocalFunctionDeclaration(token);
                listener.handleModifiers(0);
                listener.handleNoType(token);
                return parseNamedFunctionRest(
                    begin, token, afterTypeVariables, false);
              }
            }
            // Fall through to expression statement.
          }
        }
        return parseExpressionStatement(begin).next;

      case TypeContinuation.ExpressionStatementOrConstDeclaration:
        Token identifier;
        if (looksLikeType && token.isIdentifier) {
          identifier = token;
        } else if (begin.next.isIdentifier) {
          identifier = begin.next;
        }
        if (identifier != null) {
          if (looksLikeVariableDeclarationEnd(identifier.next.kind)) {
            // We are looking at "const type identifier" followed by '=', ';',
            // or ','.

            // TODO(ahe): Generate type events and call
            // parseVariablesDeclarationRest instead.
            return parseVariablesDeclaration(begin).next;
          }
          // Fall-through to expression statement.
        }

        return parseExpressionStatement(begin).next;

      case TypeContinuation.SendOrFunctionLiteral:
        Token name;
        bool hasReturnType;
        if (looksLikeType && looksLikeFunctionDeclaration(token)) {
          name = token;
          hasReturnType = true;
          // Fall-through to parseNamedFunctionRest below.
        } else if (looksLikeFunctionDeclaration(begin)) {
          name = begin;
          hasReturnType = false;
          // Fall-through to parseNamedFunctionRest below.
        } else {
          return parseSend(begin, continuationContext);
        }

        Token formals = parseTypeVariablesOpt(name.next);
        listener.beginNamedFunctionExpression(begin);
        listener.handleModifiers(0);
        if (hasReturnType) {
          if (voidToken != null) {
            listener.handleVoidKeyword(voidToken);
          } else {
            commitType();
          }
          reportRecoverableError(
              begin, fasta.messageReturnTypeFunctionExpression);
        } else {
          listener.handleNoType(begin);
        }

        return parseNamedFunctionRest(begin, name, formals, true);

      case TypeContinuation.VariablesDeclarationOrExpression:
        if (looksLikeType &&
            token.isIdentifier &&
            isOneOf4(token.next, '=', ';', ',', 'in')) {
          // TODO(ahe): Generate type events and call
          // parseVariablesDeclarationNoSemicolonRest instead.
          return parseVariablesDeclarationNoSemicolon(begin).next;
        }
        return parseExpression(begin);

      case TypeContinuation.NormalFormalParameter:
      case TypeContinuation.NormalFormalParameterAfterVar:
        parameterKind = FormalParameterKind.mandatory;
        hasVar = continuation == TypeContinuation.NormalFormalParameterAfterVar;
        continue handleParameters;

      case TypeContinuation.OptionalPositionalFormalParameter:
      case TypeContinuation.OptionalPositionalFormalParameterAfterVar:
        parameterKind = FormalParameterKind.optionalPositional;
        hasVar = continuation ==
            TypeContinuation.OptionalPositionalFormalParameterAfterVar;
        continue handleParameters;

      case TypeContinuation.NamedFormalParameterAfterVar:
        hasVar = true;
        continue handleParameters;

      handleParameters:
      case TypeContinuation.NamedFormalParameter:
        parameterKind ??= FormalParameterKind.optionalNamed;
        bool inFunctionType = memberKind == MemberKind.GeneralizedFunctionType;
        bool isNamedParameter =
            parameterKind == FormalParameterKind.optionalNamed;

        bool untyped = false;
        if (!looksLikeType || optional("this", begin)) {
          untyped = true;
          token = begin;
        }

        Token thisKeyword;
        Token periodAfterThis;
        Token nameToken = token;
        IdentifierContext nameContext =
            IdentifierContext.formalParameterDeclaration;
        token = token.next;
        if (inFunctionType) {
          if (isNamedParameter || nameToken.isIdentifier) {
            nameContext = IdentifierContext.formalParameterDeclaration;
          } else {
            // No name required in a function type.
            nameContext = null;
            token = nameToken;
          }
        } else if (optional('this', nameToken)) {
          thisKeyword = nameToken;
          if (!optional('.', token)) {
            // Recover from a missing period by inserting one.
            Message message = fasta.templateExpectedButGot.withArguments('.');
            Token newToken =
                new SyntheticToken(TokenType.PERIOD, token.charOffset);
            periodAfterThis = rewriteAndRecover(token, message, newToken);
          } else {
            periodAfterThis = token;
          }
          token = periodAfterThis.next;
          nameContext = IdentifierContext.fieldInitializer;
          if (!token.isIdentifier) {
            // Recover from a missing identifier by inserting one.
            token = insertSyntheticIdentifier(token, nameContext);
          }
          nameToken = token;
          token = token.next;
        } else if (!nameToken.isIdentifier) {
          untyped = true;
          nameToken = begin;
          token = nameToken.next;
        }
        if (isNamedParameter && nameToken.lexeme.startsWith("_")) {
          // TODO(ahe): Move this to after committing the type.
          reportRecoverableError(nameToken, fasta.messagePrivateNamedParameter);
        }

        token = listener.injectGenericCommentTypeList(token);

        Token inlineFunctionTypeStart;
        if (optional("<", token)) {
          Token closer = closeBraceTokenFor(token);
          if (closer != null) {
            if (optional("(", closer.next)) {
              inlineFunctionTypeStart = token;
              token = token.next;
            }
          }
        } else if (optional("(", token)) {
          inlineFunctionTypeStart = token;
          token = closeBraceTokenFor(token).next;
        }

        if (inlineFunctionTypeStart != null) {
          token = parseTypeVariablesOpt(inlineFunctionTypeStart);
          listener.beginFunctionTypedFormalParameter(inlineFunctionTypeStart);
          if (!untyped) {
            if (voidToken != null) {
              listener.handleVoidKeyword(voidToken);
            } else {
              Token saved = token;
              commitType();
              token = saved;
            }
          } else {
            listener.handleNoType(begin);
          }
          token = parseFormalParametersRequiredOpt(
                  token, MemberKind.FunctionTypedParameter)
              .next;
          listener.endFunctionTypedFormalParameter();

          // Generalized function types don't allow inline function types.
          // The following isn't allowed:
          //    int Function(int bar(String x)).
          if (memberKind == MemberKind.GeneralizedFunctionType) {
            reportRecoverableError(inlineFunctionTypeStart,
                fasta.messageInvalidInlineFunctionType);
          }
        } else if (untyped) {
          listener.handleNoType(begin);
        } else {
          Token saved = token;
          commitType();
          token = saved;
        }

        if (nameContext != null) {
          nameToken = ensureIdentifier(nameToken, nameContext);
        } else {
          listener.handleNoName(nameToken);
        }

        String value = token.stringValue;
        if ((identical('=', value)) || (identical(':', value))) {
          Token equal = token;
          token = parseExpression(token.next);
          listener.handleValuedFormalParameter(equal, token);
          if (isMandatoryFormalParameterKind(parameterKind)) {
            reportRecoverableError(
                equal, fasta.messageRequiredParameterWithDefault);
          } else if (isOptionalPositionalFormalParameterKind(parameterKind) &&
              identical(':', value)) {
            reportRecoverableError(
                equal, fasta.messagePositionalParameterWithEquals);
          } else if (inFunctionType ||
              memberKind == MemberKind.FunctionTypeAlias ||
              memberKind == MemberKind.FunctionTypedParameter) {
            reportRecoverableError(
                equal, fasta.messageFunctionTypeDefaultValue);
          }
        } else {
          listener.handleFormalParameterWithoutValue(token);
        }
        listener.endFormalParameter(
            thisKeyword, periodAfterThis, nameToken, parameterKind, memberKind);

        return token;
    }

    throw "Internal error: Unhandled continuation '$continuation'.";
  }

  Token parseTypeArgumentsOpt(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    // TODO(brianwilkerson) Return the last consumed token.
    return parseStuff(
        token,
        (t) => listener.beginTypeArguments(t),
        (t) => parseType(t),
        (c, bt, et) => listener.endTypeArguments(c, bt, et),
        (t) => listener.handleNoTypeArguments(t));
  }

  Token parseTypeVariablesOpt(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    // TODO(brianwilkerson) Return the last consumed token.
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
    // TODO(brianwilkerson) Accept the last consumed token.
    // TODO(brianwilkerson) Return the last consumed token.
    // TODO(brianwilkerson): Rename to `parseStuffOpt`?
    token = listener.injectGenericCommentTypeList(token);
    if (optional('<', token)) {
      Token begin = token;
      beginStuff(begin);
      int count = 0;
      do {
        token = stuffParser(token.next);
        ++count;
      } while (optional(',', token));
      if (identical(token.stringValue, '>>')) {
        Token replacement = new Token(TokenType.GT, token.charOffset)
          ..next = new Token(TokenType.GT, token.charOffset + 1);
        token = rewriter.replaceToken(token, replacement);
      }
      endStuff(count, begin, token);
      return expect('>', token);
    }
    handleNoStuff(token);
    return token;
  }

  Token parseTopLevelMember(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    // TODO(brianwilkerson) Return the last consumed token.
    Token start = token;
    listener.beginTopLevelMember(token);

    Link<Token> identifiers = findMemberName(token);
    if (identifiers.isEmpty) {
      return reportUnrecoverableErrorWithToken(
              start, fasta.templateExpectedDeclaration)
          .next;
    }
    Token afterName = identifiers.head;
    identifiers = identifiers.tail;

    if (identifiers.isEmpty) {
      return reportUnrecoverableErrorWithToken(
              start, fasta.templateExpectedDeclaration)
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
    Token afterModifiers =
        identifiers.isNotEmpty ? identifiers.head.next : start;
    return isField
        ? parseFields(start, identifiers.reverse(), type, name, true).next
        : parseTopLevelMethod(start, afterModifiers, type, getOrSet, name);
  }

  Token parseFields(Token start, Link<Token> modifiers, Token type, Token name,
      bool isTopLevel) {
    // TODO(brianwilkerson) Accept the last consumed token.
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
        isVarAllowed: true);

    if (token != name) {
      reportRecoverableErrorWithToken(token, fasta.templateExtraneousModifier);
      token = name;
    }

    IdentifierContext context = isTopLevel
        ? IdentifierContext.topLevelVariableDeclaration
        : IdentifierContext.fieldDeclaration;
    token = ensureIdentifier(token, context).next;

    int fieldCount = 1;
    token = parseFieldInitializerOpt(token, name, varFinalOrConst, isTopLevel);
    while (optional(',', token)) {
      name = ensureIdentifier(token.next, context);
      token = parseFieldInitializerOpt(
          name.next, name, varFinalOrConst, isTopLevel);
      ++fieldCount;
    }
    token = ensureSemicolon(token);
    if (isTopLevel) {
      listener.endTopLevelFields(fieldCount, start, token);
    } else {
      listener.endFields(fieldCount, start, token);
    }
    return token;
  }

  Token parseTopLevelMethod(Token start, Token afterModifiers, Token type,
      Token getOrSet, Token name) {
    // TODO(brianwilkerson) Accept the last consumed token.
    // TODO(brianwilkerson) Return the last consumed token.
    Token token = start;

    // Parse modifiers
    Token externalToken;
    if (token == afterModifiers) {
      listener.beginTopLevelMethod(start, name);
      listener.handleModifiers(0);
    } else if (optional('external', token) && token.next == afterModifiers) {
      listener.beginTopLevelMethod(start, name);
      externalToken = token;
      parseModifier(externalToken);
      listener.handleModifiers(1);
      token = token.next;
    } else {
      // If there are modifiers other than or in addition to `external`
      // then we need to recover.
      final context = new TopLevelMethodModifierContext(this);
      token = context.parseRecovery(token, afterModifiers);

      // If the modifiers form a partial top level directive or declaration
      // and we have found the start of a new top level declaration
      // then return to parse that new declaration.
      if (context.endInvalidTopLevelDeclarationToken != null) {
        listener.handleInvalidTopLevelDeclaration(
            context.endInvalidTopLevelDeclarationToken);
        return token;
      }

      listener.beginTopLevelMethod(start, name);
      externalToken = context.externalToken;
      if (externalToken == null) {
        listener.handleModifiers(0);
      } else {
        parseModifier(externalToken);
        listener.handleModifiers(1);
      }
      // Fall through to continue parsing the top level method.
    }

    if (type == null) {
      listener.handleNoType(name);
    } else {
      parseType(type, TypeContinuation.Optional);
    }
    name =
        ensureIdentifier(name, IdentifierContext.topLevelFunctionDeclaration);
    token = name.next;

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
      reportRecoverableError(asyncToken, fasta.messageSetterNotSync);
    }
    token = parseFunctionBody(token, false, externalToken != null);
    asyncState = savedAsyncModifier;
    listener.endTopLevelMethod(start, getOrSet, token);
    return token.next;
  }

  void checkFormals(bool isGetter, Token name, Token token) {
    if (optional("(", token)) {
      if (isGetter) {
        reportRecoverableError(token, fasta.messageGetterWithFormals);
      }
    } else if (!isGetter) {
      reportRecoverableErrorWithToken(name, fasta.templateNoFormals);
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
        return identifiers;
      } else if (optional("=", token) ||
          optional(";", token) ||
          optional(",", token)) {
        // A field or abstract getter.
        identifiers = identifiers.prepend(token);
        return identifiers;
      } else if (optional('native', token) &&
          (token.next.kind == STRING_TOKEN || optional(';', token.next))) {
        // Skip.
        token = token.next;
        if (token.kind == STRING_TOKEN) {
          token = token.next;
        }
        continue;
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
              token = token.next;
              Token closeBrace = closeBraceTokenFor(token);
              if (closeBrace == null) {
                token = reportUnmatchedToken(token).next;
              } else {
                token = closeBrace;
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
        } else if (token.type.isBuiltIn) {
          // Handle the edge case where a built-in keyword is being used
          // as the identifier, as in "abstract<T>() => 0;"
          if (optional('<', token.next)) {
            Token identifier = token;
            if (token.next is BeginToken) {
              token = token.next;
              Token closeBrace = closeBraceTokenFor(token);
              if (closeBrace == null) {
                // Handle the edge case where the user is defining the less
                // than operator, as in "bool operator <(other) => false;"
                if (optional('operator', identifier)) {
                  token = identifier;
                } else {
                  token = reportUnmatchedToken(token).next;
                }
              } else {
                token = closeBrace;
              }
            }
          }
        }
        token = token.next;
      }
      while (isGeneralizedFunctionType(token)) {
        token = token.next;
        if (optional('<', token)) {
          if (token is BeginToken) {
            Token closeBrace = closeBraceTokenFor(token);
            if (closeBrace == null) {
              token = reportUnmatchedToken(token).next;
            } else {
              token = closeBrace.next;
            }
          }
        }
        if (!optional('(', token)) {
          if (optional(';', token)) {
            reportRecoverableError(token, fasta.messageExpectedOpenParens);
          }
          token = expect("(", token);
        }
        if (token is BeginToken) {
          Token closeBrace = closeBraceTokenFor(token);
          if (closeBrace == null) {
            token = reportUnmatchedToken(token).next;
          } else {
            token = closeBrace.next;
          }
        }
      }
    }
    return const Link<Token>();
  }

  Token parseFieldInitializerOpt(
      Token token, Token name, Token varFinalOrConst, bool isTopLevel) {
    // TODO(brianwilkerson) Accept the last consumed token.
    // TODO(brianwilkerson) Return the last consumed token.
    if (optional('=', token)) {
      Token assignment = token;
      listener.beginFieldInitializer(token);
      token = parseExpression(token.next);
      listener.endFieldInitializer(assignment, token);
    } else {
      if (varFinalOrConst != null) {
        if (optional("const", varFinalOrConst)) {
          reportRecoverableError(
              name,
              fasta.templateConstFieldWithoutInitializer
                  .withArguments(name.lexeme));
        } else if (isTopLevel && optional("final", varFinalOrConst)) {
          reportRecoverableError(
              name,
              fasta.templateFinalFieldWithoutInitializer
                  .withArguments(name.lexeme));
        }
      }
      listener.handleNoFieldInitializer(token);
    }
    return token;
  }

  Token parseVariableInitializerOpt(Token token) {
    if (optional('=', token.next)) {
      Token assignment = token.next;
      listener.beginVariableInitializer(assignment);
      // TODO(brianwilkerson): Remove the invocation of `previous` after
      // converting `parseExpression` to return the last consumed token.
      token = parseExpression(assignment.next).previous;
      listener.endVariableInitializer(assignment);
    } else {
      listener.handleNoVariableInitializer(token.next);
    }
    return token;
  }

  Token parseInitializersOpt(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    // TODO(brianwilkerson) Return the last consumed token.
    if (optional(':', token)) {
      return parseInitializers(token);
    } else {
      listener.handleNoInitializers();
      return token;
    }
  }

  /// ```
  /// initializers:
  ///   ':' initializerListEntry (',' initializerListEntry)*
  /// ;
  /// ```
  Token parseInitializers(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    // TODO(brianwilkerson) Return the last consumed token.
    assert(optional(':', token));
    Token begin = token;
    listener.beginInitializers(begin);
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

  /// ```
  /// initializerListEntry:
  ///   'super' ('.' identifier)? arguments |
  ///   fieldInitializer |
  ///   assertion
  /// ;
  ///
  /// fieldInitializer:
  ///   ('this' '.')? identifier '=' conditionalExpression cascadeSection*
  /// ;
  /// ```
  Token parseInitializer(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    // TODO(brianwilkerson) Return the last consumed token.
    listener.beginInitializer(token);
    if (optional('assert', token)) {
      token = parseAssert(token, Assert.Initializer);
    } else {
      token = parseExpression(token);
    }
    listener.endInitializer(token);
    return token;
  }

  Token ensureParseLiteralString(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    if (!identical(token.kind, STRING_TOKEN)) {
      Message message = fasta.templateExpectedString.withArguments(token);
      Token newToken =
          new SyntheticStringToken(TokenType.STRING, '""', token.charOffset, 0);
      token = rewriteAndRecover(token, message, newToken);
    }
    return parseLiteralString(token);
  }

  /// If the given [token] is a semi-colon, return it. Otherwise, report an
  /// error, insert a synthetic semi-colon, and return the inserted semi-colon.
  Token ensureSemicolon(Token token) {
    // TODO(danrubel): Once all expect(';'...) call sites have been converted
    // to use this method, remove similar semicolon recovery code
    // from the handleError method in element_listener.dart.
    if (optional(';', token)) return token;
    Message message = fasta.templateExpectedButGot.withArguments(';');
    Token newToken = new SyntheticToken(TokenType.SEMICOLON, token.charOffset);
    return rewriteAndRecover(token, message, newToken);
  }

  Token rewriteAndRecover(Token token, Message message, Token newToken) {
    reportRecoverableError(token, message);
    return rewriter.insertToken(newToken, token);
  }

  /// Report the given token as unexpected and return the next token
  /// if the next token is one of the [expectedNext],
  /// otherwise just return the given token.
  Token skipUnexpectedTokenOpt(Token token, List<String> expectedNext) {
    if (token.keyword == null) {
      final String nextValue = token.next.stringValue;
      for (String expectedValue in expectedNext) {
        if (identical(nextValue, expectedValue)) {
          reportRecoverableErrorWithToken(token, fasta.templateUnexpectedToken);
          return token.next;
        }
      }
    }
    return token;
  }

  Token parseLiteralStringOrRecoverExpression(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    // TODO(brianwilkerson) Return the last consumed token.
    if (identical(token.kind, STRING_TOKEN)) {
      return parseLiteralString(token).next;
    } else if (token is ErrorToken) {
      return reportErrorToken(token, false);
    } else {
      reportRecoverableErrorWithToken(token, fasta.templateExpectedString);
      return parseRecoverExpression(
          token, fasta.templateExpectedString.withArguments(token));
    }
  }

  Token expectSemicolon(Token token) {
    return expect(';', token);
  }

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
    // TODO(brianwilkerson) Accept the last consumed token.
    assert(token.isModifier);
    listener.handleModifier(token);
    return token;
  }

  /// This method is used in most locations where modifiers can occur. However,
  /// it isn't used when parsing a class or when parsing the modifiers of a
  /// member function (non-local), but is used when parsing their formal
  /// parameters.
  ///
  /// When parsing the formal parameters of any function, [parameterKind] is
  /// non-null.
  Token parseModifiers(Token token, MemberKind memberKind,
      {FormalParameterKind parameterKind, bool isVarAllowed: false}) {
    // TODO(brianwilkerson) Accept the last consumed token.
    // TODO(brianwilkerson) Return the last consumed token.
    ModifierContext context = new ModifierContext(
        this,
        memberKind,
        parameterKind,
        isVarAllowed,
        typeContiunationFromFormalParameterKind(parameterKind));

    final firstModifier = token;
    token = context.parseOpt(token);

    // If the next token is a modifier,
    // then it's probably out of order and we need to recover from that.
    if (isModifier(token)) {
      // Recovery
      context = new ModifierRecoveryContext(this, memberKind, parameterKind,
          isVarAllowed, typeContiunationFromFormalParameterKind(parameterKind));
      token = context.parseOpt(firstModifier);
    }
    listener.handleModifiers(context.modifierCount);

    memberKind = context.memberKind;
    context.typeContinuation ??=
        (isVarAllowed || memberKind == MemberKind.GeneralizedFunctionType)
            ? TypeContinuation.Required
            : TypeContinuation.Optional;

    token = parseType(token, context.typeContinuation, null, memberKind);
    return token;
  }

  Token parseNativeClause(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    assert(optional('native', token));
    Token nativeToken = token;
    bool hasName = false;
    if (token.next.kind == STRING_TOKEN) {
      hasName = true;
      token = parseLiteralString(token.next);
    }
    listener.handleNativeClause(nativeToken, hasName);
    reportRecoverableError(
        nativeToken, fasta.messageNativeClauseShouldBeAnnotation);
    return token;
  }

  Token skipClassBody(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    if (!optional('{', token)) {
      return reportUnrecoverableErrorWithToken(
              token, fasta.templateExpectedClassBodyToSkip)
          .next;
    }
    Token closeBrace = closeBraceTokenFor(token);
    if (closeBrace == null ||
        !identical(closeBrace.kind, $CLOSE_CURLY_BRACKET)) {
      return reportUnmatchedToken(token).next;
    }
    return closeBrace;
  }

  /// ```
  /// classBody:
  ///   '{' classMember* '}'
  /// ;
  /// ```
  ///
  /// The [beforeBody] token is required to be a token that appears somewhere
  /// before the [token] in the token stream.
  Token parseClassBody(Token token, Token beforeBody) {
    // TODO(brianwilkerson) Accept the last consumed token.
    Token begin = token;
    listener.beginClassBody(token);
    if (!optional('{', token)) {
      reportRecoverableError(
          token, fasta.templateExpectedClassBody.withArguments(token));
      BeginToken replacement = link(
          new SyntheticBeginToken(TokenType.OPEN_CURLY_BRACKET, token.offset),
          new SyntheticToken(TokenType.CLOSE_CURLY_BRACKET, token.offset));
      rewriter.insertToken(replacement, token);
      token = begin = replacement;
    }
    token = token.next;
    int count = 0;
    while (notEofOrValue('}', token)) {
      token = parseMember(token).next;
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
    while (isModifier(token)) {
      token = token.next;
    }
    return optional('factory', token);
  }

  bool isModifierOrFactory(Token next) =>
      optional('factory', next) || isModifier(next);

  /// ```
  /// classMember:
  ///   fieldDeclaration |
  ///   constructorDeclaration |
  ///   methodDeclaration
  /// ;
  /// ```
  Token parseMember(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    token = parseMetadataStar(token);
    Token start = token;
    listener.beginMember(token);
    // TODO(danrubel): isFactoryDeclaration scans forward over modifiers
    // which findMemberName does as well. See if this can be done once
    // instead of twice.
    if (isFactoryDeclaration(token)) {
      token = parseFactoryMethod(token);
      listener.endMember();
      assert(token.next != null);
      return token;
    }

    Link<Token> identifiers = findMemberName(token);
    if (identifiers.isEmpty) {
      return reportUnrecoverableErrorWithToken(
          start, fasta.templateExpectedDeclaration);
    }
    Token afterName = identifiers.head;
    identifiers = identifiers.tail;

    if (identifiers.isEmpty) {
      return reportUnrecoverableErrorWithToken(
          start, fasta.templateExpectedDeclaration);
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
        token = reportUnexpectedToken(token);
        if (identical(token.next.kind, EOF_TOKEN)) {
          // TODO(ahe): This is a hack, see parseTopLevelMember.
          listener.endFields(1, start, token.next);
          listener.endMember();
          return token;
        }
        token = token.next;
      }
    }

    Token afterModifiers =
        identifiers.isNotEmpty ? identifiers.head.next : start;
    token = isField
        ? parseFields(start, identifiers.reverse(), type, name, false)
        : parseMethod(start, afterModifiers, type, getOrSet, name);
    listener.endMember();
    return token;
  }

  Token parseMethod(Token token, Token afterModifiers, Token type,
      Token getOrSet, Token name) {
    // TODO(brianwilkerson) Accept the last consumed token.
    Token start = token;

    Token externalModifier;
    Token staticModifier;
    if (token != afterModifiers) {
      int modifierCount = 0;
      if (optional('external', token)) {
        externalModifier = token;
        parseModifier(externalModifier);
        ++modifierCount;
        token = token.next;
      }
      if (token != afterModifiers) {
        if (optional('static', token)) {
          staticModifier = token;
          parseModifier(staticModifier);
          ++modifierCount;
          token = token.next;
        }
        if (token != afterModifiers) {
          if (getOrSet == null) {
            if (optional("const", token)) {
              if (token.next == afterModifiers) {
                parseModifier(token);
                ++modifierCount;
                token = token.next;
              }
            }
          } else if (optional('set', getOrSet)) {
            if (staticModifier == null && optional('covariant', token)) {
              if (token.next == afterModifiers) {
                parseModifier(token);
                ++modifierCount;
                token = token.next;
              }
            }
          }
          // If the next token is a modifier,
          // then it's probably out of order and we need to recover from that.
          if (token != afterModifiers) {
            final context = new ClassMethodModifierContext(this);
            token = context.parseRecovery(token, externalModifier,
                staticModifier, getOrSet, afterModifiers);

            // If the modifiers form a partial top level directive
            // or declaration and we have found the start of a new top level
            // declaration then return to parse that new declaration.
            if (context.endInvalidMemberToken != null) {
              listener.handleInvalidMember(context.endInvalidMemberToken);
              return context.endInvalidMemberToken;
            }

            externalModifier = context.externalToken;
            staticModifier = context.staticToken;
            modifierCount = context.modifierCount;
          }
        }
      }
      listener.beginMethod(start, name);
      listener.handleModifiers(modifierCount);
    } else {
      listener.beginMethod(start, name);
      listener.handleModifiers(0);
    }

    if (type == null) {
      listener.handleNoType(name);
    } else {
      parseType(type, TypeContinuation.Optional);
    }
    if (optional('operator', name)) {
      token = parseOperatorName(name);
      if (staticModifier != null) {
        reportRecoverableError(staticModifier, fasta.messageStaticOperator);
      }
    } else {
      token = ensureIdentifier(name, IdentifierContext.methodDeclaration);
    }

    // TODO(brianwilkerson): Can the next statement be moved inside the else above?
    token = parseQualifiedRestOpt(
            token, IdentifierContext.methodDeclarationContinuation)
        .next;
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

    bool allowAbstract = staticModifier == null;
    AsyncModifier savedAsyncModifier = asyncState;
    Token asyncToken = token;
    token = parseAsyncModifier(token);
    if (getOrSet != null && !inPlainSync && optional("set", getOrSet)) {
      reportRecoverableError(asyncToken, fasta.messageSetterNotSync);
    }
    if (externalModifier != null) {
      if (!optional(';', token)) {
        reportRecoverableError(token, fasta.messageExternalMethodWithBody);
      }
      allowAbstract = true;
    }
    if (optional('=', token)) {
      token = parseRedirectingFactoryBody(token);
    } else {
      token = parseFunctionBody(token, false, allowAbstract);
    }
    asyncState = savedAsyncModifier;
    listener.endMethod(getOrSet, start, token);
    return token;
  }

  Token parseFactoryMethod(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    assert(isFactoryDeclaration(token));
    Token start = token;
    Token constToken;
    Token externalToken;
    Token factoryKeyword;

    if (optional('factory', token) && !isModifierOrFactory(token.next)) {
      listener.handleModifiers(0);
      factoryKeyword = token;
      token = token.next;
    } else {
      int modifierCount = 0;
      if (optional('external', token)) {
        externalToken = token;
        parseModifier(token);
        ++modifierCount;
        token = token.next;
      }
      if (optional('const', token)) {
        constToken = token;
        parseModifier(token);
        ++modifierCount;
        token = token.next;
      }
      if (optional('factory', token) && !isModifierOrFactory(token.next)) {
        factoryKeyword = token;
        token = token.next;
      } else {
        // Recovery
        FactoryModifierContext context = new FactoryModifierContext(
            this, modifierCount, externalToken, constToken);
        token = context.parseRecovery(token);
        externalToken = context.externalToken;
        constToken = context.constToken;
        factoryKeyword = context.factoryKeyword;
        modifierCount = context.modifierCount;
      }
      listener.handleModifiers(modifierCount);
    }

    listener.beginFactoryMethod(factoryKeyword);
    token = parseConstructorReference(token);
    token = parseFormalParametersRequiredOpt(token, MemberKind.Factory).next;
    Token asyncToken = token;
    token = parseAsyncModifier(token);
    if (!inPlainSync) {
      reportRecoverableError(asyncToken, fasta.messageFactoryNotSync);
    }
    if (optional('=', token)) {
      // TODO(danrubel): There is a duplicate check at the semantic level
      // that needs to be removed now that the check is performed here.
      if (externalToken != null) {
        // TODO(danrubel): The more correct error message here would be
        // that a redirecting factory cannot be external.
        reportRecoverableError(token, fasta.messageExternalConstructorWithBody);
      }
      token = parseRedirectingFactoryBody(token);
    } else if (externalToken != null) {
      if (!optional(';', token)) {
        // TODO(danrubel): The more correct error message here would be
        // that an external *factory* cannot have a body.
        reportRecoverableError(token, fasta.messageExternalConstructorWithBody);
      }
      token = parseFunctionBody(token, false, true);
    } else {
      if (constToken != null && !optional('native', token)) {
        // TODO(danrubel): report error to fix
        // test_constFactory in parser_fasta_test.dart
        //reportRecoverableError(constToken, fasta.messageConstFactory);
      }
      token = parseFunctionBody(token, false, false);
    }
    listener.endFactoryMethod(start, factoryKeyword, token);
    return token;
  }

  Token parseOperatorName(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    assert(optional('operator', token));
    if (token.next.isUserDefinableOperator) {
      Token operator = token;
      token = token.next;
      listener.handleOperatorName(operator, token);
      return token;
    } else {
      return ensureIdentifier(token, IdentifierContext.operatorName);
    }
  }

  Token parseFunctionExpression(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    // TODO(brianwilkerson) Return the last consumed token.
    Token beginToken = token;
    listener.beginFunctionExpression(token);
    token = parseFormalParametersRequiredOpt(token, MemberKind.Local).next;
    token = parseAsyncOptBody(token, true, false);
    listener.endFunctionExpression(beginToken, token);
    return token;
  }

  /// Parses the rest of a named function declaration starting from its [name]
  /// but then skips any type parameters and continue parsing from [formals]
  /// (the formal parameters).
  ///
  /// If [isFunctionExpression] is true, this method parses the rest of named
  /// function expression which isn't legal syntax in Dart.  Useful for
  /// recovering from Javascript code being pasted into a Dart program, as it
  /// will interpret `function foo() {}` as a named function expression with
  /// return type `function` and name `foo`.
  ///
  /// Precondition: the parser has previously generated these events:
  ///
  /// - Type variables.
  /// - `beginLocalFunctionDeclaration` if [isFunctionExpression] is false,
  ///   otherwise `beginNamedFunctionExpression`.
  /// - Modifiers.
  /// - Return type.
  Token parseNamedFunctionRest(
      Token begin, Token name, Token formals, bool isFunctionExpression) {
    // TODO(brianwilkerson) Accept the last consumed token.
    // TODO(brianwilkerson) Return the last consumed token.
    Token token = name;
    listener.beginFunctionName(token);
    token = ensureIdentifier(token, IdentifierContext.localFunctionDeclaration)
        .next;
    if (isFunctionExpression) {
      reportRecoverableError(name, fasta.messageNamedFunctionExpression);
    }
    listener.endFunctionName(begin, token);
    token = parseFormalParametersOpt(formals, MemberKind.Local);
    token = parseInitializersOpt(token);
    token = parseAsyncOptBody(token, isFunctionExpression, false);
    if (isFunctionExpression) {
      listener.endNamedFunctionExpression(token);
      return token;
    } else {
      listener.endLocalFunctionDeclaration(token);
      return token.next;
    }
  }

  /// Parses a function body optionally preceded by an async modifier (see
  /// [parseAsyncModifier]).  This method is used in both expression context
  /// (when [ofFunctionExpression] is true) and statement context. In statement
  /// context (when [ofFunctionExpression] is false), and if the function body
  /// is on the form `=> expression`, a trailing semicolon is required.
  ///
  /// It's an error if there's no function body unless [allowAbstract] is true.
  Token parseAsyncOptBody(
      Token token, bool ofFunctionExpression, bool allowAbstract) {
    // TODO(brianwilkerson) Accept the last consumed token.
    // TODO(brianwilkerson) Return the last consumed token.
    AsyncModifier savedAsyncModifier = asyncState;
    token = parseAsyncModifier(token);
    token = parseFunctionBody(token, ofFunctionExpression, allowAbstract);
    asyncState = savedAsyncModifier;
    return token;
  }

  Token parseConstructorReference(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    // TODO(brianwilkerson) Return the last consumed token.
    Token start =
        ensureIdentifier(token, IdentifierContext.constructorReference);
    listener.beginConstructorReference(start);
    token = parseQualifiedRestOpt(
            start, IdentifierContext.constructorReferenceContinuation)
        .next;
    token = parseTypeArgumentsOpt(token);
    Token period = null;
    if (optional('.', token)) {
      period = token;
      token = ensureIdentifier(
              token.next,
              IdentifierContext
                  .constructorReferenceContinuationAfterTypeArguments)
          .next;
    } else {
      listener
          .handleNoConstructorReferenceContinuationAfterTypeArguments(token);
    }
    listener.endConstructorReference(start, period, token);
    return token;
  }

  Token parseRedirectingFactoryBody(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    assert(optional('=', token));
    listener.beginRedirectingFactoryBody(token);
    Token equals = token;
    token = parseConstructorReference(token.next);
    token = ensureSemicolon(token);
    listener.endRedirectingFactoryBody(equals, token);
    return token;
  }

  Token skipFunctionBody(Token token, bool isExpression, bool allowAbstract) {
    // TODO(brianwilkerson) Accept the last consumed token.
    // TODO(brianwilkerson) Return the last consumed token.
    assert(!isExpression);
    token = skipAsyncModifier(token);
    if (optional('native', token)) {
      Token nativeToken = token;
      // TODO(danrubel): skip the native clause rather than parsing it
      // or remove this code completely when we remove support
      // for the `native` clause.
      token = parseNativeClause(token).next;
      if (optional(';', token)) {
        listener.handleNativeFunctionBodySkipped(nativeToken, token);
        return token;
      }
      listener.handleNativeFunctionBodyIgnored(nativeToken, token);
      // Fall through to recover and skip function body
    }
    String value = token.stringValue;
    if (identical(value, ';')) {
      if (!allowAbstract) {
        reportRecoverableError(token, fasta.messageExpectedBody);
      }
      listener.handleNoFunctionBody(token);
    } else {
      if (identical(value, '=>')) {
        token = parseExpression(token.next);
        expectSemicolon(token);
        listener.handleFunctionBodySkipped(token, true);
      } else if (identical(value, '=')) {
        reportRecoverableError(token, fasta.messageExpectedBody);
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

  /// Parses a function body.  This method is used in both expression context
  /// (when [ofFunctionExpression] is true) and statement context. In statement
  /// context (when [ofFunctionExpression] is false), and if the function body
  /// is on the form `=> expression`, a trailing semicolon is required.
  ///
  /// It's an error if there's no function body unless [allowAbstract] is true.
  Token parseFunctionBody(
      Token token, bool ofFunctionExpression, bool allowAbstract) {
    // TODO(brianwilkerson) Accept the last consumed token.
    // TODO(brianwilkerson) Return the last consumed token.
    if (optional('native', token)) {
      Token nativeToken = token;
      token = parseNativeClause(nativeToken).next;
      if (optional(';', token)) {
        listener.handleNativeFunctionBody(nativeToken, token);
        return token;
      }
      reportRecoverableError(token, fasta.messageExternalMethodWithBody);
      listener.handleNativeFunctionBodyIgnored(nativeToken, token);
      // Ignore the native keyword and fall through to parse the body
    }
    if (optional(';', token)) {
      if (!allowAbstract) {
        reportRecoverableError(token, fasta.messageExpectedBody);
      }
      listener.handleEmptyFunctionBody(token);
      return token;
    } else if (optional('=>', token)) {
      Token begin = token;
      token = parseExpression(token.next);
      if (!ofFunctionExpression) {
        token = ensureSemicolon(token);
        listener.handleExpressionFunctionBody(begin, token);
      } else {
        listener.handleExpressionFunctionBody(begin, null);
      }
      if (inGenerator) {
        listener.handleInvalidStatement(
            token, fasta.messageGeneratorReturnsValue);
      }
      return token;
    } else if (optional('=', token)) {
      Token begin = token;
      // Recover from a bad factory method.
      reportRecoverableError(token, fasta.messageExpectedBody);
      token = parseExpression(token.next);
      if (!ofFunctionExpression) {
        token = ensureSemicolon(token);
        listener.handleExpressionFunctionBody(begin, token);
      } else {
        listener.handleExpressionFunctionBody(begin, null);
      }
      return token;
    }
    Token begin = token;
    int statementCount = 0;
    if (!optional('{', token)) {
      token = reportUnrecoverableErrorWithToken(
              token, fasta.templateExpectedFunctionBody)
          .next;
      listener.handleInvalidFunctionBody(token);
      return token;
    }

    listener.beginBlockFunctionBody(begin);
    token = token.next;
    while (notEofOrValue('}', token)) {
      Token startToken = token;
      token = parseStatementOpt(token).next;
      if (identical(token, startToken)) {
        // No progress was made, so we report the current token as being invalid
        // and move forward.
        reportRecoverableError(
            token, fasta.templateUnexpectedToken.withArguments(token));
        token = token.next;
      }
      ++statementCount;
    }
    listener.endBlockFunctionBody(statementCount, begin, token);
    expect('}', token);
    return ofFunctionExpression ? token.next : token;
  }

  Token skipAsyncModifier(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    // TODO(brianwilkerson) Return the last consumed token.
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
    // TODO(brianwilkerson) Accept the last consumed token.
    // TODO(brianwilkerson) Return the last consumed token.
    // TODO(brianwilkerson): Rename to `parseAsyncModifierOpt`?
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
        reportRecoverableError(async, fasta.messageInvalidSyncModifier);
      }
    }
    listener.handleAsyncModifier(async, star);
    if (!inPlainSync && optional(';', token)) {
      reportRecoverableError(token, fasta.messageAbstractNotSync);
    }
    return token;
  }

  int statementDepth = 0;
  Token parseStatementOpt(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    // TODO(brianwilkerson): Rename this to `parseStatement`?
    if (statementDepth++ > 500) {
      // This happens for degenerate programs, for example, a lot of nested
      // if-statements. The language test deep_nesting2_negative_test, for
      // example, provokes this.
      return reportUnrecoverableError(token, fasta.messageStackOverflow);
    }
    Token result = parseStatementX(token);
    statementDepth--;
    return result;
  }

  Token parseStatementX(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
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
          reportRecoverableError(token, fasta.messageYieldNotGenerator);
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

  /// ```
  /// yieldStatement:
  ///   'yield' expression? ';'
  /// ;
  /// ```
  Token parseYieldStatement(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    assert(identical('yield', token.stringValue));
    Token begin = token;
    listener.beginYieldStatement(begin);
    token = token.next;
    Token starToken;
    if (optional('*', token)) {
      starToken = token;
      token = token.next;
    }
    token = parseExpression(token);
    token = ensureSemicolon(token);
    listener.endYieldStatement(begin, starToken, token);
    return token;
  }

  /// ```
  /// returnStatement:
  ///   'return' expression? ';'
  /// ;
  /// ```
  Token parseReturnStatement(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    assert(optional('return', token));
    Token begin = token;
    listener.beginReturnStatement(begin);
    assert(optional('return', token));
    token = token.next;
    if (optional(';', token)) {
      listener.endReturnStatement(false, begin, token);
      return token;
    }
    token = parseExpression(token);
    token = ensureSemicolon(token);
    listener.endReturnStatement(true, begin, token);
    if (inGenerator) {
      listener.handleInvalidStatement(
          begin, fasta.messageGeneratorReturnsValue);
    }
    return token;
  }

  Token parseExpressionStatementOrDeclaration(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    // TODO(brianwilkerson): Remove the invocation of `previous` after
    // converting `parseType` to return the last consumed token.
    return parseType(token, TypeContinuation.ExpressionStatementOrDeclaration)
        .previous;
  }

  Token parseExpressionStatementOrConstDeclaration(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    assert(optional('const', token));
    if (token.next.isModifier) {
      return parseVariablesDeclaration(token);
    } else {
      // TODO(brianwilkerson): Remove the invocation of `previous` after
      // converting `parseType` to return the last consumed token.
      return parseType(
              token, TypeContinuation.ExpressionStatementOrConstDeclaration)
          .previous;
    }
  }

  /// ```
  /// label:
  ///   identifier ':'
  /// ;
  /// ```
  Token parseLabel(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    // TODO(brianwilkerson): Enable this assert.
    // `parseType` is allowing `void` to be a label.
//    assert(token.isIdentifier);
    assert(optional(':', token.next));
    token = ensureIdentifier(token, IdentifierContext.labelDeclaration).next;
    expect(':', token);
    listener.handleLabel(token);
    return token;
  }

  /// ```
  /// statement:
  ///   label* nonLabelledStatement
  /// ;
  /// ```
  Token parseLabeledStatement(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    // TODO(brianwilkerson): Enable this assert.
    // `parseType` is allowing `void` to be a label.
//    assert(token.isIdentifier);
    assert(optional(':', token.next));
    int labelCount = 0;
    do {
      token = parseLabel(token).next;
      labelCount++;
    } while (token.isIdentifier && optional(':', token.next));
    listener.beginLabeledStatement(token, labelCount);
    token = parseStatementOpt(token);
    listener.endLabeledStatement(labelCount);
    return token;
  }

  /// ```
  /// expressionStatement:
  ///   expression? ';'
  /// ;
  /// ```
  Token parseExpressionStatement(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    // TODO(brianwilkerson): If the next token is not the start of a valid
    // expression, then this method shouldn't report that we have an expression
    // statement.
    listener.beginExpressionStatement(token);
    token = parseExpression(token);
    token = ensureSemicolon(token);
    listener.endExpressionStatement(token);
    return token;
  }

  Token skipExpression(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    // TODO(brianwilkerson) Return the last consumed token.
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
          token = closeBraceTokenFor(token.next) ?? token;
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
          token = closeBraceTokenFor(token.next) ?? token;
          token = token.next;
          if (identical(token.stringValue, '{')) {
            token = closeBraceTokenFor(token) ?? token;
            token = token.next;
          }
          continue;
        }
      }
      if (!mayParseFunctionExpressions && identical(value, '{')) {
        break;
      }
      if (token is BeginToken) {
        token = closeBraceTokenFor(token) ?? token;
      } else if (token is ErrorToken) {
        reportErrorToken(token, false).next;
      }
      token = token.next;
    }
    return token;
  }

  Token parseRecoverExpression(Token token, Message message) {
    // TODO(brianwilkerson) Accept the last consumed token.
    // TODO(brianwilkerson) Return the last consumed token.
    return parseExpression(token);
  }

  int expressionDepth = 0;
  Token parseExpression(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    // TODO(brianwilkerson) Return the last consumed token.
    if (expressionDepth++ > 500) {
      // This happens in degenerate programs, for example, with a lot of nested
      // list literals. This is provoked by, for example, the language test
      // deep_nesting1_negative_test.
      return reportUnrecoverableError(token, fasta.messageStackOverflow).next;
    }
    Token result = optional('throw', token)
        ? parseThrowExpression(token, true)
        : parsePrecedenceExpression(token, ASSIGNMENT_PRECEDENCE, true);
    expressionDepth--;
    return result;
  }

  Token parseExpressionWithoutCascade(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    // TODO(brianwilkerson) Return the last consumed token.
    return optional('throw', token)
        ? parseThrowExpression(token, false)
        : parsePrecedenceExpression(token, ASSIGNMENT_PRECEDENCE, false);
  }

  Token parseConditionalExpressionRest(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    // TODO(brianwilkerson) Return the last consumed token.
    assert(optional('?', token));
    Token question = token;
    listener.beginConditionalExpression();
    token = parseExpressionWithoutCascade(token.next);
    Token colon = token;
    token = expect(':', token);
    listener.handleConditionalExpressionColon();
    token = parseExpressionWithoutCascade(token);
    listener.endConditionalExpression(question, colon);
    return token;
  }

  Token parsePrecedenceExpression(
      Token token, int precedence, bool allowCascades) {
    // TODO(brianwilkerson) Accept the last consumed token.
    // TODO(brianwilkerson) Return the last consumed token.
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
            listener.endBinaryExpression(operator);
          } else if ((identical(type, TokenType.OPEN_PAREN)) ||
              (identical(type, TokenType.OPEN_SQUARE_BRACKET))) {
            token = parseArgumentOrIndexStar(token);
          } else if ((identical(type, TokenType.PLUS_PLUS)) ||
              (identical(type, TokenType.MINUS_MINUS))) {
            listener.handleUnaryPostfixAssignmentExpression(token);
            token = token.next;
          } else if (identical(type, TokenType.INDEX)) {
            BeginToken replacement = link(
                new BeginToken(TokenType.OPEN_SQUARE_BRACKET, token.charOffset,
                    token.precedingComments),
                new Token(
                    TokenType.CLOSE_SQUARE_BRACKET, token.charOffset + 1));
            token = rewriter.replaceToken(token, replacement);
            token = parseArgumentOrIndexStar(token);
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
          listener.beginBinaryExpression(token);
          // Left associative, so we recurse at the next higher
          // precedence level.
          token =
              parsePrecedenceExpression(token.next, level + 1, allowCascades);
          listener.endBinaryExpression(operator);
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
    // TODO(brianwilkerson) Accept the last consumed token.
    // TODO(brianwilkerson) Return the last consumed token.
    assert(optional('..', token));
    listener.beginCascade(token);
    Token cascadeOperator = token;
    token = token.next;
    if (optional('[', token)) {
      token = parseArgumentOrIndexStar(token);
    } else if (token.isIdentifier) {
      token = parseSend(token, IdentifierContext.expressionContinuation);
      listener.endBinaryExpression(cascadeOperator);
    } else {
      return reportUnexpectedToken(token).next;
    }
    Token mark;
    do {
      mark = token;
      if (optional('.', token)) {
        Token period = token;
        token = parseSend(token.next, IdentifierContext.expressionContinuation);
        listener.endBinaryExpression(period);
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
    // TODO(brianwilkerson) Accept the last consumed token.
    // TODO(brianwilkerson) Return the last consumed token.
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
      reportRecoverableError(token, fasta.messageUnsupportedPrefixPlus);
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
    // TODO(brianwilkerson) Accept the last consumed token.
    // TODO(brianwilkerson) Return the last consumed token.
    Token beginToken = token;
    while (true) {
      if (optional('[', token)) {
        Token openSquareBracket = token;
        bool old = mayParseFunctionExpressions;
        mayParseFunctionExpressions = true;
        token = parseExpression(token.next);
        mayParseFunctionExpressions = old;
        if (!optional(']', token)) {
          Message message = fasta.templateExpectedButGot.withArguments(']');
          Token newToken = new SyntheticToken(
              TokenType.CLOSE_SQUARE_BRACKET, token.charOffset);
          token = rewriteAndRecover(token, message, newToken);
        }
        listener.handleIndexedExpression(openSquareBracket, token);
        token = token.next;
      } else if (optional('(', token)) {
        listener.handleNoTypeArguments(token);
        token = parseArguments(token).next;
        listener.handleSend(beginToken, token);
      } else {
        break;
      }
    }
    return token;
  }

  Token parsePrimary(Token token, IdentifierContext context) {
    // TODO(brianwilkerson) Accept the last consumed token.
    // TODO(brianwilkerson) Return the last consumed token.
    token = listener.injectGenericCommentTypeList(token);
    final kind = token.kind;
    if (kind == IDENTIFIER_TOKEN) {
      return parseSendOrFunctionLiteral(token, context);
    } else if (kind == INT_TOKEN || kind == HEXADECIMAL_TOKEN) {
      return parseLiteralInt(token).next;
    } else if (kind == DOUBLE_TOKEN) {
      return parseLiteralDouble(token).next;
    } else if (kind == STRING_TOKEN) {
      return parseLiteralString(token).next;
    } else if (kind == HASH_TOKEN) {
      return parseLiteralSymbol(token).next;
    } else if (kind == KEYWORD_TOKEN) {
      final String value = token.stringValue;
      if (identical(value, "true") || identical(value, "false")) {
        return parseLiteralBool(token).next;
      } else if (identical(value, "null")) {
        return parseLiteralNull(token).next;
      } else if (identical(value, "this")) {
        return parseThisExpression(token, context).next;
      } else if (identical(value, "super")) {
        return parseSuperExpression(token, context).next;
      } else if (identical(value, "new")) {
        return parseNewExpression(token).next;
      } else if (identical(value, "const")) {
        return parseConstExpression(token);
      } else if (identical(value, "void")) {
        return parseSendOrFunctionLiteral(token, context);
      } else if (!inPlainSync &&
          (identical(value, "yield") || identical(value, "async"))) {
        // Fall through to the recovery code.
      } else if (identical(value, "assert")) {
        return parseAssert(token, Assert.Expression);
      } else if (token.isIdentifier) {
        return parseSendOrFunctionLiteral(token, context);
      } else {
        // Fall through to the recovery code.
      }
    } else if (kind == OPEN_PAREN_TOKEN) {
      return parseParenthesizedExpressionOrFunctionLiteral(token);
    } else if (kind == OPEN_SQUARE_BRACKET_TOKEN || optional('[]', token)) {
      listener.handleNoTypeArguments(token);
      return parseLiteralListSuffix(token, null).next;
    } else if (kind == OPEN_CURLY_BRACKET_TOKEN) {
      listener.handleNoTypeArguments(token);
      return parseLiteralMapSuffix(token, null).next;
    } else if (kind == LT_TOKEN) {
      return parseLiteralListOrMapOrFunction(token, null);
    } else {
      // Fall through to the recovery code.
    }
    //
    // Recovery code.
    //
    if (token is ErrorToken) {
      do {
        // Report the error in the error token, skip the error token, and try
        // again.
        token = reportErrorTokenAndAdvance(token);
      } while (token is ErrorToken);
      return parsePrimary(token, context);
    } else {
      return parseSend(token, context);
    }
  }

  Token parseParenthesizedExpressionOrFunctionLiteral(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    // TODO(brianwilkerson) Return the last consumed token.
    assert(optional('(', token));
    Token nextToken = closeBraceTokenFor(token).next;
    int kind = nextToken.kind;
    if (mayParseFunctionExpressions &&
        (identical(kind, FUNCTION_TOKEN) ||
            identical(kind, OPEN_CURLY_BRACKET_TOKEN) ||
            (identical(kind, KEYWORD_TOKEN) &&
                (optional('async', nextToken) ||
                    optional('sync', nextToken))))) {
      listener.handleNoTypeVariables(token);
      return parseFunctionExpression(token);
    } else {
      bool old = mayParseFunctionExpressions;
      mayParseFunctionExpressions = true;
      token = parseParenthesizedExpression(token).next;
      mayParseFunctionExpressions = old;
      return token;
    }
  }

  Token parseParenthesizedExpression(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    if (!optional('(', token)) {
      // Recover
      reportRecoverableError(
          token, fasta.templateExpectedToken.withArguments('('));
      reportRecoverableError(
          token, fasta.templateExpectedToken.withArguments(')'));
      BeginToken replacement = link(
          new SyntheticBeginToken(TokenType.OPEN_PAREN, token.charOffset),
          new SyntheticToken(TokenType.CLOSE_PAREN, token.charOffset));
      token = rewriter.insertToken(replacement, token);
    }
    BeginToken begin = token;
    token = parseExpression(token.next);
    if (!identical(begin.endGroup, token)) {
      reportUnexpectedToken(token).next;
      token = begin.endGroup;
    }
    listener.handleParenthesizedExpression(begin);
    expect(')', token);
    return token;
  }

  Token parseThisExpression(Token token, IdentifierContext context) {
    // TODO(brianwilkerson) Accept the last consumed token.
    assert(optional('this', token));
    Token thisToken = token;
    listener.handleThisExpression(thisToken, context);
    Token next = token.next;
    if (optional('(', next)) {
      // Constructor forwarding.
      listener.handleNoTypeArguments(next);
      token = parseArguments(next);
      listener.handleSend(thisToken, token.next);
    }
    return token;
  }

  Token parseSuperExpression(Token token, IdentifierContext context) {
    // TODO(brianwilkerson) Accept the last consumed token.
    assert(optional('super', token));
    Token superToken = token;
    listener.handleSuperExpression(superToken, context);
    Token next = token.next;
    if (optional('(', next)) {
      // Super constructor.
      listener.handleNoTypeArguments(next);
      token = parseArguments(next);
      listener.handleSend(superToken, token.next);
    } else if (optional("?.", next)) {
      reportRecoverableError(next, fasta.messageSuperNullAware);
    }
    return token;
  }

  /// This method parses the portion of a list literal starting with the left
  /// square bracket.
  ///
  /// ```
  /// listLiteral:
  ///   'const'? typeArguments? '[' (expressionList ','?)? ']'
  /// ;
  /// ```
  ///
  /// Provide a [constKeyword] if the literal is preceded by 'const', or `null`
  /// if not. This is a suffix parser because it is assumed that type arguments
  /// have been parsed, or `listener.handleNoTypeArguments` has been executed.
  Token parseLiteralListSuffix(Token token, Token constKeyword) {
    // TODO(brianwilkerson) Accept the last consumed token.
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
      expect(']', token);
      return token;
    }
    BeginToken replacement = link(
        new BeginToken(TokenType.OPEN_SQUARE_BRACKET, token.offset),
        new Token(TokenType.CLOSE_SQUARE_BRACKET, token.offset + 1));
    rewriter.replaceToken(token, replacement);
    token = replacement.next;
    listener.handleLiteralList(0, replacement, constKeyword, token);
    return token;
  }

  /// This method parses the portion of a map literal that starts with the left
  /// curly brace.
  ///
  /// ```
  /// mapLiteral:
  ///   'const'? typeArguments? '{' (mapLiteralEntry (',' mapLiteralEntry)* ','?)? '}'
  /// ;
  /// ```
  ///
  /// Provide a [constKeyword] if the literal is preceded by 'const', or `null`
  /// if not. This is a suffix parser because it is assumed that type arguments
  /// have been parsed, or `listener.handleNoTypeArguments` has been executed.
  Token parseLiteralMapSuffix(Token token, Token constKeyword) {
    // TODO(brianwilkerson) Accept the last consumed token.
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
    expect('}', token);
    return token;
  }

  /// formalParameterList functionBody.
  ///
  /// This is a suffix parser because it is assumed that type arguments have
  /// been parsed, or `listener.handleNoTypeArguments(..)` has been executed.
  Token parseLiteralFunctionSuffix(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    // TODO(brianwilkerson) Return the last consumed token.
    assert(optional('(', token));
    Token closeBrace = closeBraceTokenFor(token);
    if (closeBrace != null) {
      Token nextToken = closeBrace.next;
      int kind = nextToken.kind;
      if (identical(kind, FUNCTION_TOKEN) ||
          identical(kind, OPEN_CURLY_BRACKET_TOKEN) ||
          (identical(kind, KEYWORD_TOKEN) &&
              (optional('async', nextToken) || optional('sync', nextToken)))) {
        return parseFunctionExpression(token);
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
    // TODO(brianwilkerson) Accept the last consumed token.
    // TODO(brianwilkerson) Return the last consumed token.
    assert(optional('<', token));
    Token closeBrace = closeBraceTokenFor(token);
    if (constKeyword == null &&
        closeBrace != null &&
        identical(closeBrace.next.kind, OPEN_PAREN_TOKEN)) {
      token = parseTypeVariablesOpt(token);
      return parseLiteralFunctionSuffix(token);
    } else {
      token = parseTypeArgumentsOpt(token);
      if (optional('{', token)) {
        return parseLiteralMapSuffix(token, constKeyword).next;
      } else if ((optional('[', token)) || (optional('[]', token))) {
        return parseLiteralListSuffix(token, constKeyword).next;
      }
      return reportUnexpectedToken(token).next;
    }
  }

  /// ```
  /// mapLiteralEntry:
  ///   expression ':' expression
  /// ;
  /// ```
  Token parseMapLiteralEntry(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    // TODO(brianwilkerson) Return the last consumed token.
    listener.beginLiteralMapEntry(token);
    // Assume the listener rejects non-string keys.
    // TODO(brianwilkerson): Change the assumption above by moving error
    // checking into the parser, making it possible to recover.
    token = parseExpression(token);
    Token colon = token;
    token = expect(':', token);
    token = parseExpression(token);
    listener.endLiteralMapEntry(colon, token);
    return token;
  }

  Token parseSendOrFunctionLiteral(Token token, IdentifierContext context) {
    // TODO(brianwilkerson) Accept the last consumed token.
    // TODO(brianwilkerson) Return the last consumed token.
    if (!mayParseFunctionExpressions) {
      return parseSend(token, context);
    } else {
      return parseType(token, TypeContinuation.SendOrFunctionLiteral, context);
    }
  }

  Token parseRequiredArguments(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    if (optional('(', token)) {
      token = parseArguments(token);
    } else {
      listener.handleNoArguments(token);
      token = reportUnexpectedToken(token);
    }
    return token;
  }

  /// ```
  /// newExpression:
  ///   'new' type ('.' identifier)? arguments
  /// ;
  /// ```
  Token parseNewExpression(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    assert(optional('new', token));
    Token newKeyword = token;
    listener.beginNewExpression(newKeyword);
    token = parseConstructorReference(token.next);
    token = parseRequiredArguments(token);
    listener.endNewExpression(newKeyword);
    return token;
  }

  /// This method parses a list or map literal that is known to start with the
  /// keyword 'const'.
  ///
  /// ```
  /// listLiteral:
  ///   'const'? typeArguments? '[' (expressionList ','?)? ']'
  /// ;
  ///
  /// mapLiteral:
  ///   'const'? typeArguments? '{' (mapLiteralEntry (',' mapLiteralEntry)* ','?)? '}'
  /// ;
  ///
  /// mapLiteralEntry:
  ///   expression ':' expression
  /// ;
  /// ```
  Token parseConstExpression(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    // TODO(brianwilkerson) Return the last consumed token.
    assert(optional('const', token));
    Token constKeyword = token;
    token = listener.injectGenericCommentTypeList(token.next);
    final String value = token.stringValue;
    if ((identical(value, '[')) || (identical(value, '[]'))) {
      listener.beginConstLiteral(token);
      listener.handleNoTypeArguments(token);
      token = parseLiteralListSuffix(token, constKeyword).next;
      listener.endConstLiteral(token);
      return token;
    }
    if (identical(value, '{')) {
      listener.beginConstLiteral(token);
      listener.handleNoTypeArguments(token);
      token = parseLiteralMapSuffix(token, constKeyword).next;
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
    token = parseRequiredArguments(token).next;
    listener.endConstExpression(constKeyword);
    return token;
  }

  /// ```
  /// intLiteral:
  ///   integer
  /// ;
  /// ```
  Token parseLiteralInt(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    assert(identical(token.kind, INT_TOKEN) ||
        identical(token.kind, HEXADECIMAL_TOKEN));
    listener.handleLiteralInt(token);
    return token;
  }

  /// ```
  /// doubleLiteral:
  ///   double
  /// ;
  /// ```
  Token parseLiteralDouble(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    assert(identical(token.kind, DOUBLE_TOKEN));
    listener.handleLiteralDouble(token);
    return token;
  }

  /// ```
  /// stringLiteral:
  ///   (multilineString | singleLineString)+
  /// ;
  /// ```
  Token parseLiteralString(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    assert(identical(token.kind, STRING_TOKEN));
    bool old = mayParseFunctionExpressions;
    mayParseFunctionExpressions = true;
    token = parseSingleLiteralString(token);
    int count = 1;
    while (identical(token.next.kind, STRING_TOKEN)) {
      token = parseSingleLiteralString(token.next);
      count++;
    }
    if (count > 1) {
      listener.handleStringJuxtaposition(count);
    }
    mayParseFunctionExpressions = old;
    return token;
  }

  /// ```
  /// symbolLiteral:
  ///   '#' (operator | (identifier ('.' identifier)*))
  /// ;
  /// ```
  Token parseLiteralSymbol(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    assert(optional('#', token));
    Token hashToken = token;
    listener.beginLiteralSymbol(hashToken);
    token = token.next;
    if (token.isUserDefinableOperator) {
      listener.handleOperator(token);
      listener.endLiteralSymbol(hashToken, 1);
      return token;
    } else if (identical(token.stringValue, 'void')) {
      listener.handleSymbolVoid(token);
      listener.endLiteralSymbol(hashToken, 1);
      return token;
    } else {
      int count = 1;
      token = ensureIdentifier(token, IdentifierContext.literalSymbol);
      while (optional('.', token.next)) {
        count++;
        token = ensureIdentifier(
            token.next.next, IdentifierContext.literalSymbolContinuation);
      }
      listener.endLiteralSymbol(hashToken, count);
      return token;
    }
  }

  Token parseSingleLiteralString(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    assert(identical(token.kind, STRING_TOKEN));
    listener.beginLiteralString(token);
    // Parsing the prefix, for instance 'x of 'x${id}y${id}z'
    int interpolationCount = 0;
    var kind = token.next.kind;
    while (kind != EOF_TOKEN) {
      if (identical(kind, STRING_INTERPOLATION_TOKEN)) {
        // Parsing ${expression}.
        token = parseExpression(token.next.next);
        token = expect('}', token);
      } else if (identical(kind, STRING_INTERPOLATION_IDENTIFIER_TOKEN)) {
        // Parsing $identifier.
        token = parseExpression(token.next.next);
      } else {
        break;
      }
      ++interpolationCount;
      // Parsing the infix/suffix, for instance y and z' of 'x${id}y${id}z'
      token = parseStringPart(token);
      kind = token.next.kind;
    }
    listener.endLiteralString(interpolationCount, token.next);
    return token;
  }

  /// ```
  /// booleanLiteral:
  ///   'true' |
  ///   'false'
  /// ;
  /// ```
  Token parseLiteralBool(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    assert(optional('false', token) || optional('true', token));
    listener.handleLiteralBool(token);
    return token;
  }

  /// ```
  /// nullLiteral:
  ///   'null'
  /// ;
  /// ```
  Token parseLiteralNull(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    assert(optional('null', token));
    listener.handleLiteralNull(token);
    return token;
  }

  Token parseSend(Token token, IdentifierContext context) {
    // TODO(brianwilkerson) Accept the last consumed token.
    // TODO(brianwilkerson) Return the last consumed token.
    Token beginToken = ensureIdentifier(token, context);
    token = listener.injectGenericCommentTypeList(beginToken.next);
    if (isValidMethodTypeArguments(token)) {
      token = parseTypeArgumentsOpt(token);
    } else {
      listener.handleNoTypeArguments(token);
    }
    token = parseArgumentsOpt(token);
    listener.handleSend(beginToken, token);
    return token;
  }

  Token skipArgumentsOpt(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    // TODO(brianwilkerson) Return the last consumed token.
    listener.handleNoArguments(token);
    if (optional('(', token)) {
      return closeBraceTokenFor(token).next;
    } else {
      return token;
    }
  }

  Token parseArgumentsOpt(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    // TODO(brianwilkerson) Return the last consumed token.
    if (!optional('(', token)) {
      listener.handleNoArguments(token);
      return token;
    } else {
      return parseArguments(token).next;
    }
  }

  /// ```
  /// arguments:
  ///   '(' (argumentList ','?)? ')'
  /// ;
  ///
  /// argumentList:
  ///   namedArgument (',' namedArgument)* |
  ///   expressionList (',' namedArgument)*
  /// ;
  ///
  /// namedArgument:
  ///   label expression
  /// ;
  /// ```
  Token parseArguments(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    assert(optional('(', token));
    Token begin = token;
    listener.beginArguments(begin);
    int argumentCount = 0;
    bool hasSeenNamedArgument = false;
    bool old = mayParseFunctionExpressions;
    mayParseFunctionExpressions = true;
    do {
      token = token.next;
      if (optional(')', token)) {
        break;
      }
      Token colon = null;
      if (optional(':', token.next)) {
        token =
            ensureIdentifier(token, IdentifierContext.namedArgumentReference)
                .next;
        colon = token;
        token = token.next;
        hasSeenNamedArgument = true;
      } else if (hasSeenNamedArgument) {
        // Positional argument after named argument.
        reportRecoverableError(
            token, fasta.messagePositionalAfterNamedArgument);
      }
      token = parseExpression(token);
      if (colon != null) listener.handleNamedArgument(colon);
      ++argumentCount;
    } while (optional(',', token));
    mayParseFunctionExpressions = old;
    listener.endArguments(argumentCount, begin, token);
    expect(')', token);
    return token;
  }

  /// ```
  /// typeTest::
  ///   'is' '!'? type
  /// ;
  /// ```
  Token parseIsOperatorRest(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    // TODO(brianwilkerson) Return the last consumed token.
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

  /// ```
  /// typeCast:
  ///   'as' type
  /// ;
  /// ```
  Token parseAsOperatorRest(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    // TODO(brianwilkerson) Return the last consumed token.
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
    // TODO(brianwilkerson) Accept the last consumed token.
    return parseVariablesDeclarationMaybeSemicolon(token, true);
  }

  Token parseVariablesDeclarationRest(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    return parseVariablesDeclarationMaybeSemicolonRest(token, true);
  }

  Token parseVariablesDeclarationNoSemicolon(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    // Only called when parsing a for loop, so this is for parsing locals.
    return parseVariablesDeclarationMaybeSemicolon(token, false);
  }

  Token parseVariablesDeclarationNoSemicolonRest(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    // Only called when parsing a for loop, so this is for parsing locals.
    return parseVariablesDeclarationMaybeSemicolonRest(token, false);
  }

  Token parseVariablesDeclarationMaybeSemicolon(
      Token token, bool endWithSemicolon) {
    // TODO(brianwilkerson) Accept the last consumed token.
    token = parseMetadataStar(token);

    // If the next token has a type substitution comment /*=T*/, then
    // the current 'var' token should be repealed and replaced.
    if (optional('var', token)) {
      token =
          listener.replaceTokenWithGenericCommentTypeAssign(token, token.next);
    }

    token = parseModifiers(token, MemberKind.Local, isVarAllowed: true);
    return parseVariablesDeclarationMaybeSemicolonRest(token, endWithSemicolon);
  }

  Token parseVariablesDeclarationMaybeSemicolonRest(
      Token token, bool endWithSemicolon) {
    // TODO(brianwilkerson) Accept the last consumed token.
    int count = 1;
    listener.beginVariablesDeclaration(token);
    token = parseOptionallyInitializedIdentifier(token);
    while (optional(',', token.next)) {
      token = parseOptionallyInitializedIdentifier(token.next.next);
      ++count;
    }
    if (endWithSemicolon) {
      Token semicolon = ensureSemicolon(token.next);
      listener.endVariablesDeclaration(count, semicolon);
      return semicolon;
    } else {
      listener.endVariablesDeclaration(count, null);
      return token;
    }
  }

  Token parseOptionallyInitializedIdentifier(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    Token nameToken =
        ensureIdentifier(token, IdentifierContext.localVariableDeclaration);
    listener.beginInitializedIdentifier(nameToken);
    token = parseVariableInitializerOpt(nameToken);
    listener.endInitializedIdentifier(nameToken);
    return token;
  }

  /// ```
  /// ifStatement:
  ///   'if' '(' expression ')' statement ('else' statement)?
  /// ;
  /// ```
  Token parseIfStatement(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    assert(optional('if', token));
    Token ifToken = token;
    listener.beginIfStatement(ifToken);
    token = parseParenthesizedExpression(token.next).next;
    listener.beginThenStatement(token);
    token = parseStatementOpt(token);
    listener.endThenStatement(token);
    Token elseToken = null;
    if (optional('else', token.next)) {
      elseToken = token.next;
      listener.beginElseStatement(elseToken);
      token = parseStatementOpt(elseToken.next);
      listener.endElseStatement(elseToken);
    }
    listener.endIfStatement(ifToken, elseToken);
    return token;
  }

  /// ```
  /// forStatement:
  ///   'await'? 'for' '(' forLoopParts ')' statement
  /// ;
  ///
  /// forLoopParts:
  ///   forInitializerStatement expression? ';' expressionList? |
  ///   declaredIdentifier 'in' expression |
  ///   identifier 'in' expression
  /// ;
  /// ```
  Token parseForStatement(Token awaitToken, Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    Token forKeyword = token;
    listener.beginForStatement(forKeyword);
    token = expect('for', token);
    Token leftParenthesis = token;
    token = expect('(', token);
    token = parseVariablesDeclarationOrExpressionOpt(token);
    if (optional('in', token)) {
      if (awaitToken != null && !inAsync) {
        reportRecoverableError(token, fasta.messageAwaitForNotAsync);
      }
      return parseForInRest(awaitToken, forKeyword, leftParenthesis, token);
    } else if (optional(':', token)) {
      reportRecoverableError(token, fasta.messageColonInPlaceOfIn);
      if (awaitToken != null && !inAsync) {
        reportRecoverableError(token, fasta.messageAwaitForNotAsync);
      }
      return parseForInRest(awaitToken, forKeyword, leftParenthesis, token);
    } else {
      if (awaitToken != null) {
        reportRecoverableError(awaitToken, fasta.messageInvalidAwaitFor);
      }
      return parseForRest(forKeyword, leftParenthesis, token);
    }
  }

  /// ```
  /// forInitializerStatement:
  ///   localVariableDeclaration |
  ///   expression? ';'
  /// ;
  /// ```
  Token parseVariablesDeclarationOrExpressionOpt(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    // TODO(brianwilkerson) Return the last consumed token.
    final String value = token.stringValue;
    if (identical(value, ';')) {
      listener.handleNoExpression(token);
      return token;
    } else if (isOneOf4(token, '@', 'var', 'final', 'const')) {
      return parseVariablesDeclarationNoSemicolon(token).next;
    }
    return parseType(token, TypeContinuation.VariablesDeclarationOrExpression);
  }

  /// This method parses the portion of the forLoopParts that starts with the
  /// first semicolon (the one that terminates the forInitializerStatement).
  ///
  /// ```
  /// forLoopParts:
  ///   forInitializerStatement expression? ';' expressionList? |
  ///   declaredIdentifier 'in' expression |
  ///   identifier 'in' expression
  /// ;
  /// ```
  Token parseForRest(Token forToken, Token leftParenthesis, Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    Token leftSeparator = ensureSemicolon(token);
    token = leftSeparator.next;
    if (optional(';', token)) {
      token = parseEmptyStatement(token).next;
    } else {
      token = parseExpressionStatement(token).next;
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
    token = parseStatementOpt(token);
    listener.endForStatementBody(token.next);
    listener.endForStatement(
        forToken, leftParenthesis, leftSeparator, expressionCount, token.next);
    return token;
  }

  /// This method parses the portion of the forLoopParts that starts with the
  /// keyword 'in'. For the sake of recovery, we accept a colon in place of the
  /// keyword.
  ///
  /// ```
  /// forLoopParts:
  ///   forInitializerStatement expression? ';' expressionList? |
  ///   declaredIdentifier 'in' expression |
  ///   identifier 'in' expression
  /// ;
  /// ```
  Token parseForInRest(
      Token awaitToken, Token forKeyword, Token leftParenthesis, Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    assert(optional('in', token) || optional(':', token));
    Token inKeyword = token;
    token = token.next;
    listener.beginForInExpression(token);
    token = parseExpression(token);
    listener.endForInExpression(token);
    token = expect(')', token);
    listener.beginForInBody(token);
    token = parseStatementOpt(token);
    listener.endForInBody(token.next);
    listener.endForIn(
        awaitToken, forKeyword, leftParenthesis, inKeyword, token.next);
    return token;
  }

  /// ```
  /// whileStatement:
  ///   'while' '(' expression ')' statement
  /// ;
  /// ```
  Token parseWhileStatement(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    assert(optional('while', token));
    Token whileToken = token;
    listener.beginWhileStatement(whileToken);
    token = parseParenthesizedExpression(token.next).next;
    listener.beginWhileStatementBody(token);
    token = parseStatementOpt(token);
    listener.endWhileStatementBody(token.next);
    listener.endWhileStatement(whileToken, token.next);
    return token;
  }

  /// ```
  /// doStatement:
  ///   'do' statement 'while' '(' expression ')' ';'
  /// ;
  /// ```
  Token parseDoWhileStatement(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    assert(optional('do', token));
    Token doToken = token;
    listener.beginDoWhileStatement(doToken);
    token = token.next;
    listener.beginDoWhileStatementBody(token);
    token = parseStatementOpt(token).next;
    listener.endDoWhileStatementBody(token);
    Token whileToken = token;
    token = expect('while', token);
    token = parseParenthesizedExpression(token).next;
    token = ensureSemicolon(token);
    listener.endDoWhileStatement(doToken, whileToken, token);
    return token;
  }

  /// ```
  /// block:
  ///   '{' statement* '}'
  /// ;
  /// ```
  Token parseBlock(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    Token begin = token;
    listener.beginBlock(begin);
    int statementCount = 0;
    token = expect('{', token);
    while (notEofOrValue('}', token)) {
      Token startToken = token;
      token = parseStatementOpt(token).next;
      if (identical(token, startToken)) {
        // No progress was made, so we report the current token as being invalid
        // and move forward.
        reportRecoverableError(
            token, fasta.templateUnexpectedToken.withArguments(token));
        token = token.next;
      }
      ++statementCount;
    }
    listener.endBlock(statementCount, begin, token);
    expect('}', token);
    return token;
  }

  /// ```
  /// awaitExpression:
  ///   'await' unaryExpression
  /// ;
  /// ```
  Token parseAwaitExpression(Token token, bool allowCascades) {
    // TODO(brianwilkerson) Accept the last consumed token.
    // TODO(brianwilkerson) Return the last consumed token.
    assert(optional('await', token));
    Token awaitToken = token;
    listener.beginAwaitExpression(awaitToken);
    if (!inAsync) {
      reportRecoverableError(awaitToken, fasta.messageAwaitNotAsync);
    }
    token = parsePrecedenceExpression(
        token.next, POSTFIX_PRECEDENCE, allowCascades);
    listener.endAwaitExpression(awaitToken, token);
    return token;
  }

  /// ```
  /// throwExpression:
  ///   'throw' expression
  /// ;
  ///
  /// throwExpressionWithoutCascade:
  ///   'throw' expressionWithoutCascade
  /// ;
  /// ```
  Token parseThrowExpression(Token token, bool allowCascades) {
    // TODO(brianwilkerson) Accept the last consumed token.
    // TODO(brianwilkerson) Return the last consumed token.
    assert(optional('throw', token));
    Token throwToken = token;
    token = allowCascades
        ? parseExpression(token.next)
        : parseExpressionWithoutCascade(token.next);
    listener.handleThrowExpression(throwToken, token);
    return token;
  }

  /// ```
  /// rethrowStatement:
  ///   'rethrow' ';'
  /// ;
  /// ```
  Token parseRethrowStatement(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    assert(optional('rethrow', token) || optional('throw', token));
    Token throwToken = token;
    listener.beginRethrowStatement(throwToken);
    // TODO(kasperl): Disallow throw here.
    if (optional('throw', throwToken)) {
      token = expect('throw', token);
    } else {
      token = expect('rethrow', token);
    }
    token = ensureSemicolon(token);
    listener.endRethrowStatement(throwToken, token);
    return token;
  }

  /// ```
  /// tryStatement:
  ///   'try' block (onPart+ finallyPart? | finallyPart)
  /// ;
  ///
  /// onPart:
  ///   catchPart block |
  ///   'on' type catchPart? block
  /// ;
  ///
  /// catchPart:
  ///   'catch' '(' identifier (',' identifier)? ')'
  /// ;
  ///
  /// finallyPart:
  ///   'finally' block
  /// ;
  /// ```
  Token parseTryStatement(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    assert(optional('try', token));
    Token tryKeyword = token;
    listener.beginTryStatement(tryKeyword);
    Token lastConsumed = parseBlock(token.next);
    token = lastConsumed.next;
    int catchCount = 0;

    String value = token.stringValue;
    while (identical(value, 'catch') || identical(value, 'on')) {
      listener.beginCatchClause(token);
      Token onKeyword = null;
      if (identical(value, 'on')) {
        // 'on' type catchPart?
        onKeyword = token;
        token = parseType(token.next);
        value = token.stringValue;
      }
      Token catchKeyword = null;
      Token comma = null;
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
          reportRecoverableError(exceptionName, fasta.messageCatchSyntax);
        } else if (optional(")", commaOrCloseParens)) {
          // OK: `catch (identifier)`.
        } else if (!optional(",", commaOrCloseParens)) {
          reportRecoverableError(exceptionName, fasta.messageCatchSyntax);
        } else {
          comma = commaOrCloseParens;
          if (!traceName.isIdentifier) {
            reportRecoverableError(exceptionName, fasta.messageCatchSyntax);
          } else if (!optional(")", closeParens)) {
            reportRecoverableError(exceptionName, fasta.messageCatchSyntax);
          }
        }
        token =
            parseFormalParametersRequiredOpt(token.next, MemberKind.Catch).next;
      }
      listener.endCatchClause(token);
      lastConsumed = parseBlock(token);
      token = lastConsumed.next;
      ++catchCount;
      listener.handleCatchBlock(onKeyword, catchKeyword, comma);
      value = token.stringValue; // while condition
    }

    Token finallyKeyword = null;
    if (optional('finally', token)) {
      finallyKeyword = token;
      lastConsumed = parseBlock(token.next);
      token = lastConsumed.next;
      listener.handleFinallyBlock(finallyKeyword);
    } else {
      if (catchCount == 0) {
        reportRecoverableError(tryKeyword, fasta.messageOnlyTry);
      }
    }
    listener.endTryStatement(catchCount, tryKeyword, finallyKeyword);
    return lastConsumed;
  }

  /// ```
  /// switchStatement:
  ///   'switch' parenthesizedExpression switchBlock
  /// ;
  /// ```
  Token parseSwitchStatement(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    assert(optional('switch', token));
    Token switchKeyword = token;
    listener.beginSwitchStatement(switchKeyword);
    token = parseParenthesizedExpression(token.next).next;
    token = parseSwitchBlock(token);
    listener.endSwitchStatement(switchKeyword, token);
    return token;
  }

  /// ```
  /// switchBlock:
  ///   '{' switchCase* defaultCase? '}'
  /// ;
  /// ```
  Token parseSwitchBlock(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
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
  ///
  /// ```
  /// switchCase:
  ///   label* 'case' expression ‘:’ statements
  /// ;
  ///
  /// defaultCase:
  ///   label* 'default' ‘:’ statements
  /// ;
  /// ```
  Token parseSwitchCase(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    // TODO(brianwilkerson) Return the last consumed token.
    Token begin = token;
    Token defaultKeyword = null;
    Token colonAfterDefault = null;
    int expressionCount = 0;
    int labelCount = 0;
    Token peek = peekPastLabels(token);
    while (true) {
      // Loop until we find something that can't be part of a switch case.
      String value = peek.stringValue;
      if (identical(value, 'default')) {
        while (!identical(token, peek)) {
          token = parseLabel(token).next;
          labelCount++;
        }
        defaultKeyword = token;
        colonAfterDefault = token.next;
        token = expect(':', colonAfterDefault);
        peek = token;
        break;
      } else if (identical(value, 'case')) {
        while (!identical(token, peek)) {
          token = parseLabel(token).next;
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
          reportUnrecoverableError(
              token, fasta.templateExpectedButGot.withArguments("case"));
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
        Token startToken = token;
        token = parseStatementOpt(token).next;
        if (identical(token, startToken)) {
          // No progress was made, so we report the current token as being
          // invalid and move forward.
          reportRecoverableError(
              token, fasta.templateUnexpectedToken.withArguments(token));
          token = token.next;
        }
        ++statementCount;
      }
      peek = peekPastLabels(token);
    }
    listener.endSwitchCase(labelCount, expressionCount, defaultKeyword,
        colonAfterDefault, statementCount, begin, token);
    return token;
  }

  /// ```
  /// breakStatement:
  ///   'break' identifier? ';'
  /// ;
  /// ```
  Token parseBreakStatement(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    assert(optional('break', token));
    Token breakKeyword = token;
    token = token.next;
    bool hasTarget = false;
    if (token.isIdentifier) {
      token = ensureIdentifier(token, IdentifierContext.labelReference).next;
      hasTarget = true;
    }
    token = ensureSemicolon(token);
    listener.handleBreakStatement(hasTarget, breakKeyword, token);
    return token;
  }

  /// ```
  /// assertion:
  ///   'assert' '(' expression (',' expression)? ','? ')'
  /// ;
  /// ```
  Token parseAssert(Token token, Assert kind) {
    // TODO(brianwilkerson) Accept the last consumed token.
    // TODO(brianwilkerson) Return the last consumed token.
    // Also implemented by ClassMemberParser, which uses `skipExpression`, so
    // this can't return the last consumed token until `skipExpression` does.
    assert(optional('assert', token));
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
      if (optional(')', token)) {
        commaToken = null;
      } else {
        token = parseExpression(token);
      }
    }
    if (optional(',', token)) {
      Token firstExtra = token.next;
      if (optional(')', firstExtra)) {
        token = firstExtra;
      } else {
        while (optional(',', token)) {
          token = token.next;
          Token begin = token;
          token = parseExpression(token);
          listener.handleExtraneousExpression(
              begin, fasta.messageAssertExtraneousArgument);
        }
        reportRecoverableError(
            firstExtra, fasta.messageAssertExtraneousArgument);
      }
    }
    token = expect(')', token);
    mayParseFunctionExpressions = old;
    listener.endAssert(assertKeyword, kind, leftParenthesis, commaToken, token);
    if (kind == Assert.Expression) {
      reportRecoverableError(assertKeyword, fasta.messageAssertAsExpression);
    }
    return token;
  }

  /// ```
  /// assertStatement:
  ///   assertion ';'
  /// ;
  /// ```
  Token parseAssertStatement(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    assert(optional('assert', token));
    token = parseAssert(token, Assert.Statement);
    return ensureSemicolon(token);
  }

  /// ```
  /// continueStatement:
  ///   'continue' identifier? ';'
  /// ;
  /// ```
  Token parseContinueStatement(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    assert(optional('continue', token));
    Token continueKeyword = token;
    token = token.next;
    bool hasTarget = false;
    if (token.isIdentifier) {
      token = ensureIdentifier(token, IdentifierContext.labelReference).next;
      hasTarget = true;
    }
    token = ensureSemicolon(token);
    listener.handleContinueStatement(hasTarget, continueKeyword, token);
    return token;
  }

  /// ```
  /// emptyStatement:
  ///   ';'
  /// ;
  /// ```
  Token parseEmptyStatement(Token token) {
    // TODO(brianwilkerson) Accept the last consumed token.
    assert(optional(';', token));
    listener.handleEmptyStatement(token);
    return token;
  }

  /// Don't call this method. Should only be used as a last resort when there
  /// is no feasible way to recover from a parser error.
  Token reportUnrecoverableError(Token token, Message message) {
    Token next;
    if (token is ErrorToken) {
      next = reportErrorToken(token, false);
    } else {
      next = listener.handleUnrecoverableError(token, message);
    }
    return next ?? skipToEof(token);
  }

  void reportRecoverableError(Token token, Message message) {
    if (token is ErrorToken) {
      reportErrorToken(token, true);
    } else {
      listener.handleRecoverableError(message, token, token);
    }
  }

  Token reportUnrecoverableErrorWithToken(
      Token token, Template<_MessageWithArgument<Token>> template) {
    Token next;
    if (token is ErrorToken) {
      next = reportErrorToken(token, false);
    } else {
      next = listener.handleUnrecoverableError(
          token, template.withArguments(token));
    }
    return next ?? skipToEof(token);
  }

  void reportRecoverableErrorWithToken(
      Token token, Template<_MessageWithArgument<Token>> template) {
    if (token is ErrorToken) {
      reportErrorToken(token, true);
    } else {
      listener.handleRecoverableError(
          template.withArguments(token), token, token);
    }
  }

  Token reportErrorToken(ErrorToken token, bool isRecoverable) {
    Message message = token.assertionMessage;
    // TODO(brianwilkerson): Error recovery belongs in the parser, not the
    // listeners. As a result, the following code needs to be re-worked. While
    // listeners still need to handle errors, there should not be a distinction
    // between recoverable and non-recoverable errors.
    if (isRecoverable) {
      listener.handleRecoverableError(message, token, token);
      return null;
    } else {
      Token next = listener.handleUnrecoverableError(token, message);
      return next ?? skipToEof(token);
    }
  }

  /// Report the given error [token] as an unrecoverable error and return the
  /// next token to be processed.
  Token reportErrorTokenAndAdvance(ErrorToken token) {
    Token nextToken = reportErrorToken(token, false);
    if (nextToken == token) {
      return token.next;
    }
    return nextToken;
  }

  Token reportUnmatchedToken(BeginToken token) {
    return reportUnrecoverableError(
        token,
        fasta.templateUnmatchedToken
            .withArguments(closeBraceFor(token.lexeme), token));
  }

  Token reportUnexpectedToken(Token token) {
    return reportUnrecoverableErrorWithToken(
        token, fasta.templateUnexpectedToken);
  }

  /// Create a short token chain from the [beginToken] and [endToken] and return
  /// the [beginToken].
  Token link(BeginToken beginToken, Token endToken) {
    beginToken.next = endToken;
    beginToken.endGroup = endToken;
    return beginToken;
  }

  /// Create and return a token whose next token is the given [token].
  Token syntheticPreviousToken(Token token) {
    Token before = new Token.eof(0);
    before.next = token;
    return before;
  }
}

// TODO(ahe): Remove when analyzer supports generalized function syntax.
typedef _MessageWithArgument<T> = Message Function(T);
