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
        CLOSE_CURLY_BRACKET_TOKEN,
        COMMA_TOKEN,
        DOUBLE_TOKEN,
        EOF_TOKEN,
        EQ_TOKEN,
        FUNCTION_TOKEN,
        GT_GT_TOKEN,
        GT_TOKEN,
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

import 'loop_state.dart' show LoopState;

import 'member_kind.dart' show MemberKind;

import 'modifier_context.dart'
    show
        ModifierRecoveryContext,
        ModifierRecoveryContext2,
        isModifier,
        typeContinuationAfterVar;

import 'recovery_listeners.dart'
    show ClassHeaderRecoveryListener, ImportRecoveryListener;

import 'token_stream_rewriter.dart' show TokenStreamRewriter;

import 'type_continuation.dart'
    show TypeContinuation, typeContinuationFromFormalParameterKind;

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

  // TODO(danrubel): The [loopState] and associated functionality in the
  // [Parser] duplicates work that the resolver needs to do when resolving
  // break/continue targets. Long term, this state and functionality will be
  // removed from the [Parser] class and the resolver will be responsible
  // for generating all break/continue error messages.

  /// Represents parser state: whether parsing outside a loop,
  /// inside a loop, or inside a switch. This is used to determine whether
  /// break and continue statements are allowed.
  LoopState loopState = LoopState.OutsideLoop;

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

  bool get isBreakAllowed => loopState != LoopState.OutsideLoop;

  bool get isContinueAllowed => loopState == LoopState.InsideLoop;

  bool get isContinueWithLabelAllowed => loopState != LoopState.OutsideLoop;

  /// Parse a compilation unit.
  ///
  /// This method is only invoked from outside the parser. As a result, this
  /// method takes the next token to be consumed rather than the last consumed
  /// token and returns the token after the last consumed token rather than the
  /// last consumed token.
  ///
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
    token = syntheticPreviousToken(token);
    while (!token.next.isEof) {
      final Token start = token.next;
      token = parseTopLevelDeclarationImpl(token, directiveState);
      listener.endTopLevelDeclaration(token.next);
      count++;
      if (start == token.next) {
        // If progress has not been made reaching the end of the token stream,
        // then report an error and skip the current token.
        token = token.next;
        reportRecoverableErrorWithToken(
            token, fasta.templateExpectedDeclaration);
        listener.handleInvalidTopLevelDeclaration(token);
        listener.endTopLevelDeclaration(token.next);
        count++;
      }
    }
    token = token.next;
    listener.endCompilationUnit(count, token);
    // Clear fields that could lead to memory leak.
    cachedRewriter = null;
    return token;
  }

  /// This method exists for analyzer compatibility only
  /// and will be removed once analyzer/fasta integration is complete.
  ///
  /// Similar to [parseUnit], this method parses a compilation unit,
  /// but stops when it reaches the first declaration or EOF.
  ///
  /// This method is only invoked from outside the parser. As a result, this
  /// method takes the next token to be consumed rather than the last consumed
  /// token and returns the token after the last consumed token rather than the
  /// last consumed token.
  Token parseDirectives(Token token) {
    listener.beginCompilationUnit(token);
    int count = 0;
    DirectiveContext directiveState = new DirectiveContext();
    token = syntheticPreviousToken(token);
    while (!token.next.isEof) {
      final Token start = token.next;
      final String value = start.stringValue;
      final String nextValue = start.next.stringValue;

      // If a built-in keyword is being used as function name, then stop.
      if (identical(nextValue, '.') ||
          identical(nextValue, '<') ||
          identical(nextValue, '(')) {
        break;
      }

      if (identical(token.next.type, TokenType.SCRIPT_TAG)) {
        directiveState?.checkScriptTag(this, token.next);
        token = parseScript(token);
      } else {
        token = parseMetadataStar(token);
        if (identical(value, 'import')) {
          directiveState?.checkImport(this, token);
          token = parseImport(token);
        } else if (identical(value, 'export')) {
          directiveState?.checkExport(this, token);
          token = parseExport(token);
        } else if (identical(value, 'library')) {
          directiveState?.checkLibrary(this, token);
          token = parseLibraryName(token);
        } else if (identical(value, 'part')) {
          token = parsePartOrPartOf(token, directiveState);
        } else if (identical(value, ';')) {
          token = start;
        } else {
          listener.handleDirectivesOnly();
          break;
        }
      }
      listener.endTopLevelDeclaration(token.next);
    }
    token = token.next;
    listener.endCompilationUnit(count, token);
    // Clear fields that could lead to memory leak.
    cachedRewriter = null;
    return token;
  }

  /// Parse a top-level declaration.
  ///
  /// This method is only invoked from outside the parser. As a result, this
  /// method takes the next token to be consumed rather than the last consumed
  /// token and returns the token after the last consumed token rather than the
  /// last consumed token.
  Token parseTopLevelDeclaration(Token token) {
    token =
        parseTopLevelDeclarationImpl(syntheticPreviousToken(token), null).next;
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
    if (identical(token.next.type, TokenType.SCRIPT_TAG)) {
      directiveState?.checkScriptTag(this, token.next);
      return parseScript(token);
    }
    token = parseMetadataStar(token);
    if (token.next.isTopLevelKeyword) {
      return parseTopLevelKeywordDeclaration(token, null, directiveState);
    }
    Token start = token;
    // Skip modifiers to find a top level keyword or identifier
    while (token.next.isModifier) {
      token = token.next;
    }
    Token next = token.next;
    if (next.isTopLevelKeyword) {
      Token beforeAbstractToken;
      Token beforeModifier = start;
      Token modifier = start.next;
      while (modifier != next) {
        if (optional('abstract', modifier) &&
            optional('class', next) &&
            beforeAbstractToken == null) {
          beforeAbstractToken = beforeModifier;
        } else {
          // Recovery
          reportTopLevelModifierError(modifier, next);
        }
        beforeModifier = modifier;
        modifier = modifier.next;
      }
      return parseTopLevelKeywordDeclaration(
          token, beforeAbstractToken, directiveState);
    } else if (next.isIdentifier || next.keyword != null) {
      // TODO(danrubel): improve parseTopLevelMember
      // so that we don't parse modifiers twice.
      directiveState?.checkDeclaration();
      return parseTopLevelMemberImpl(start);
    } else if (start.next != next) {
      directiveState?.checkDeclaration();
      // Handle the edge case where a modifier is being used as an identifier
      return parseTopLevelMemberImpl(start);
    }
    // Recovery
    if (next.isOperator && optional('(', next.next)) {
      // This appears to be a top level operator declaration, which is invalid.
      reportRecoverableError(next, fasta.messageTopLevelOperator);
      // Insert a synthetic identifier
      // and continue parsing as a top level function.
      rewriter.insertTokenAfter(
          next,
          new SyntheticStringToken(TokenType.IDENTIFIER,
              '#synthetic_function_${next.charOffset}', token.charOffset, 0));
      return parseTopLevelMemberImpl(next);
    }
    // Ignore any preceding modifiers and just report the unexpected token
    listener.beginTopLevelMember(next);
    return reportInvalidTopLevelDeclaration(next);
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
      Token token, Token beforeAbstractToken, DirectiveContext directiveState) {
    Token previous = token;
    token = token.next;
    assert(token.isTopLevelKeyword);
    final String value = token.stringValue;
    if (identical(value, 'class')) {
      directiveState?.checkDeclaration();
      return parseClassOrNamedMixinApplication(previous, beforeAbstractToken);
    } else if (identical(value, 'enum')) {
      directiveState?.checkDeclaration();
      return parseEnum(previous);
    } else if (identical(value, 'typedef')) {
      Token next = token.next;
      directiveState?.checkDeclaration();
      if (next.isIdentifier || optional("void", next)) {
        return parseTypedef(previous);
      } else {
        return parseTopLevelMemberImpl(previous);
      }
    } else {
      // The remaining top level keywords are built-in keywords
      // and can be used in a top level declaration
      // as an identifier such as "abstract<T>() => 0;"
      // or as a prefix such as "abstract.A b() => 0;".
      String nextValue = token.next.stringValue;
      if (identical(nextValue, '(') ||
          identical(nextValue, '<') ||
          identical(nextValue, '.')) {
        directiveState?.checkDeclaration();
        return parseTopLevelMemberImpl(previous);
      } else if (identical(value, 'library')) {
        directiveState?.checkLibrary(this, token);
        return parseLibraryName(previous);
      } else if (identical(value, 'import')) {
        directiveState?.checkImport(this, token);
        return parseImport(previous);
      } else if (identical(value, 'export')) {
        directiveState?.checkExport(this, token);
        return parseExport(previous);
      } else if (identical(value, 'part')) {
        return parsePartOrPartOf(previous, directiveState);
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
    Token libraryKeyword = token.next;
    assert(optional('library', libraryKeyword));
    listener.beginLibraryName(libraryKeyword);
    token = parseQualified(libraryKeyword, IdentifierContext.libraryName,
        IdentifierContext.libraryNameContinuation);
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
    Token next = token.next;
    if (optional('deferred', next) && optional('as', next.next)) {
      Token deferredToken = next;
      Token asKeyword = next.next;
      token = ensureIdentifier(
          asKeyword, IdentifierContext.importPrefixDeclaration);
      listener.handleImportPrefix(deferredToken, asKeyword);
    } else if (optional('as', next)) {
      Token asKeyword = next;
      token = ensureIdentifier(next, IdentifierContext.importPrefixDeclaration);
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
    Token importKeyword = token.next;
    assert(optional('import', importKeyword));
    listener.beginImport(importKeyword);
    token = ensureLiteralString(importKeyword);
    Token uri = token;
    token = parseConditionalUriStar(token);
    token = parseImportPrefixOpt(token);
    token = parseCombinatorStar(token).next;
    if (optional(';', token)) {
      listener.endImport(importKeyword, token);
      return token;
    } else {
      // Recovery
      listener.endImport(importKeyword, null);
      return parseImportRecovery(uri);
    }
  }

  /// Recover given out-of-order clauses in an import directive where [token] is
  /// the import keyword.
  Token parseImportRecovery(Token token) {
    final primaryListener = listener;
    final recoveryListener = new ImportRecoveryListener(primaryListener);

    // Reparse to determine which clauses have already been parsed
    // but intercept the events so they are not sent to the primary listener
    listener = recoveryListener;
    token = parseConditionalUriStar(token);
    token = parseImportPrefixOpt(token);
    token = parseCombinatorStar(token);

    Token firstDeferredKeyword = recoveryListener.deferredKeyword;
    bool hasPrefix = recoveryListener.asKeyword != null;
    bool hasCombinator = recoveryListener.hasCombinator;

    // Update the recovery listener to forward subsequent events
    // to the primary listener
    recoveryListener.listener = primaryListener;

    // Parse additional out-of-order clauses.
    Token semicolon;
    do {
      Token start = token.next;

      // Check for extraneous token in the middle of an import statement.
      token = skipUnexpectedTokenOpt(
          token, const <String>['if', 'deferred', 'as', 'hide', 'show', ';']);

      // During recovery, clauses are parsed in the same order
      // and generate the same events as in the parseImport method above.
      recoveryListener.clear();
      token = parseConditionalUriStar(token);
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

      if (optional('deferred', token.next) &&
          !optional('as', token.next.next)) {
        listener.handleImportPrefix(token.next, null);
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

      token = parseCombinatorStar(token);
      hasCombinator = hasCombinator || recoveryListener.hasCombinator;

      if (optional(';', token.next)) {
        semicolon = token.next;
      } else if (identical(start, token.next)) {
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
  Token parseConditionalUriStar(Token token) {
    listener.beginConditionalUris(token.next);
    int count = 0;
    while (optional('if', token.next)) {
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
    Token ifKeyword = token = token.next;
    listener.beginConditionalUri(ifKeyword);
    token = expect('if', token);
    Token leftParen = token;
    expect('(', token);
    token = parseDottedName(token).next;
    Token equalitySign;
    if (optional('==', token)) {
      equalitySign = token;
      token = ensureLiteralString(token).next;
    }
    expect(')', token);
    token = ensureLiteralString(token);
    listener.endConditionalUri(ifKeyword, leftParen, equalitySign);
    return token;
  }

  /// ```
  /// dottedName:
  ///   identifier ('.' identifier)*
  /// ;
  /// ```
  Token parseDottedName(Token token) {
    token = ensureIdentifier(token, IdentifierContext.dottedName);
    Token firstIdentifier = token;
    int count = 1;
    while (optional('.', token.next)) {
      token = ensureIdentifier(
          token.next, IdentifierContext.dottedNameContinuation);
      count++;
    }
    listener.handleDottedName(count, firstIdentifier);
    return token;
  }

  /// ```
  /// exportDirective:
  ///   'export' uri conditional-uris* combinator* ';'
  /// ;
  /// ```
  Token parseExport(Token token) {
    Token exportKeyword = token.next;
    assert(optional('export', exportKeyword));
    listener.beginExport(exportKeyword);
    token = ensureLiteralString(exportKeyword);
    token = parseConditionalUriStar(token);
    token = parseCombinatorStar(token);
    token = ensureSemicolon(token);
    listener.endExport(exportKeyword, token);
    return token;
  }

  /// ```
  /// combinators:
  ///   (hideCombinator | showCombinator)*
  /// ;
  /// ```
  Token parseCombinatorStar(Token token) {
    Token next = token.next;
    listener.beginCombinators(next);
    int count = 0;
    while (true) {
      String value = next.stringValue;
      if (identical('hide', value)) {
        token = parseHide(token);
      } else if (identical('show', value)) {
        token = parseShow(token);
      } else {
        listener.endCombinators(count);
        break;
      }
      next = token.next;
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
    Token hideKeyword = token.next;
    assert(optional('hide', hideKeyword));
    listener.beginHide(hideKeyword);
    token = parseIdentifierList(hideKeyword);
    listener.endHide(hideKeyword);
    return token;
  }

  /// ```
  /// showCombinator:
  ///   'show' identifierList
  /// ;
  /// ```
  Token parseShow(Token token) {
    Token showKeyword = token.next;
    assert(optional('show', showKeyword));
    listener.beginShow(showKeyword);
    token = parseIdentifierList(showKeyword);
    listener.endShow(showKeyword);
    return token;
  }

  /// ```
  /// identifierList:
  ///   identifier (',' identifier)*
  /// ;
  /// ```
  Token parseIdentifierList(Token token) {
    token = ensureIdentifier(token, IdentifierContext.combinator);
    int count = 1;
    while (optional(',', token.next)) {
      token = ensureIdentifier(token.next, IdentifierContext.combinator);
      count++;
    }
    listener.handleIdentifierList(count);
    return token;
  }

  /// ```
  /// typeList:
  ///   type (',' type)*
  /// ;
  /// ```
  Token parseTypeList(Token token) {
    listener.beginTypeList(token.next);
    token = parseType(token);
    int count = 1;
    while (optional(',', token.next)) {
      token = parseType(token.next);
      count++;
    }
    listener.endTypeList(count);
    return token;
  }

  Token parsePartOrPartOf(Token token, DirectiveContext directiveState) {
    Token next = token.next;
    assert(optional('part', next));
    if (optional('of', next.next)) {
      directiveState?.checkPartOf(this, next);
      return parsePartOf(token);
    } else {
      directiveState?.checkPart(this, next);
      return parsePart(token);
    }
  }

  /// ```
  /// partDirective:
  ///   'part' uri ';'
  /// ;
  /// ```
  Token parsePart(Token token) {
    Token partKeyword = token.next;
    assert(optional('part', partKeyword));
    listener.beginPart(partKeyword);
    token = ensureLiteralString(partKeyword);
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
    Token partKeyword = token.next;
    Token ofKeyword = partKeyword.next;
    assert(optional('part', partKeyword));
    assert(optional('of', ofKeyword));
    listener.beginPartOf(partKeyword);
    bool hasName = ofKeyword.next.isIdentifier;
    if (hasName) {
      token = parseQualified(ofKeyword, IdentifierContext.partName,
          IdentifierContext.partNameContinuation);
    } else {
      token = ensureLiteralString(ofKeyword);
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
    listener.beginMetadataStar(token.next);
    int count = 0;
    while (optional('@', token.next)) {
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
    Token atToken = token.next;
    assert(optional('@', atToken));
    listener.beginMetadata(atToken);
    token = ensureIdentifier(atToken, IdentifierContext.metadataReference);
    token =
        parseQualifiedRestOpt(token, IdentifierContext.metadataContinuation);
    if (optional("<", token.next)) {
      reportRecoverableError(token.next, fasta.messageMetadataTypeArguments);
    }
    token = parseTypeArgumentsOpt(token);
    Token period = null;
    if (optional('.', token.next)) {
      period = token.next;
      token = ensureIdentifier(
          period, IdentifierContext.metadataContinuationAfterTypeArguments);
    }
    token = parseArgumentsOpt(token);
    listener.endMetadata(atToken, period, token.next);
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
    Token typedefKeyword = token.next;
    assert(optional('typedef', typedefKeyword));
    listener.beginFunctionTypeAlias(typedefKeyword);
    Token equals;
    Token afterType = parseType(typedefKeyword, TypeContinuation.Typedef);
    if (afterType == null) {
      token = ensureIdentifier(
          typedefKeyword, IdentifierContext.typedefDeclaration);
      token = parseTypeVariablesOpt(token).next;
      equals = token;
      expect('=', token);
      token = parseType(token);
    } else {
      token = ensureIdentifier(afterType, IdentifierContext.typedefDeclaration);
      token = parseTypeVariablesOpt(token);
      token =
          parseFormalParametersRequiredOpt(token, MemberKind.FunctionTypeAlias);
    }
    token = ensureSemicolon(token);
    listener.endFunctionTypeAlias(typedefKeyword, equals, token);
    return token;
  }

  /// Parse a mixin application starting from `with`. Assumes that the first
  /// type has already been parsed.
  Token parseMixinApplicationRest(Token token) {
    Token withKeyword = token.next;
    listener.beginMixinApplication(withKeyword);
    expect('with', withKeyword);
    token = parseTypeList(withKeyword);
    listener.endMixinApplication(withKeyword);
    return token;
  }

  Token parseFormalParametersOpt(Token token, MemberKind kind) {
    Token next = token.next;
    if (optional('(', next)) {
      return parseFormalParameters(token, kind);
    } else {
      listener.handleNoFormalParameters(next, kind);
      return token;
    }
  }

  Token skipFormalParameters(Token token, MemberKind kind) {
    Token lastConsumed = token;
    token = token.next;
    // TODO(ahe): Shouldn't this be `beginFormalParameters`?
    listener.beginOptionalFormalParameters(token);
    if (!optional('(', token)) {
      if (optional(';', token)) {
        reportRecoverableError(token, fasta.messageExpectedOpenParens);
        listener.endFormalParameters(0, token, token, kind);
        return lastConsumed;
      }
      listener.endFormalParameters(0, token, token, kind);
      return reportUnexpectedToken(token);
    }
    Token closeBrace = closeBraceTokenFor(token);
    listener.endFormalParameters(0, token, closeBrace, kind);
    return closeBrace;
  }

  /// Parses the formal parameter list of a function.
  ///
  /// If `kind == MemberKind.GeneralizedFunctionType`, then names may be
  /// omitted (except for named arguments). Otherwise, types may be omitted.
  Token parseFormalParametersRequiredOpt(Token token, MemberKind kind) {
    Token next = token.next;
    if (!optional('(', next)) {
      reportRecoverableError(next, missingParameterMessage(kind));
      Token replacement = link(
          new SyntheticBeginToken(TokenType.OPEN_PAREN, next.charOffset),
          new SyntheticToken(TokenType.CLOSE_PAREN, next.charOffset));
      rewriter.insertTokenAfter(token, replacement);
    }
    return parseFormalParameters(token, kind);
  }

  /// Parses the formal parameter list of a function given that the left
  /// parenthesis is known to exist.
  ///
  /// If `kind == MemberKind.GeneralizedFunctionType`, then names may be
  /// omitted (except for named arguments). Otherwise, types may be omitted.
  Token parseFormalParameters(Token token, MemberKind kind) {
    Token begin = token = token.next;
    assert(optional('(', token));
    listener.beginFormalParameters(begin, kind);
    int parameterCount = 0;
    while (true) {
      Token next = token.next;
      if (optional(')', next)) {
        token = next;
        break;
      }
      ++parameterCount;
      String value = next.stringValue;
      if (identical(value, '[')) {
        token = parseOptionalPositionalParameters(token, kind);
        token = ensureCloseParen(token, begin);
        break;
      } else if (identical(value, '{')) {
        token = parseOptionalNamedParameters(token, kind);
        token = ensureCloseParen(token, begin);
        break;
      } else if (identical(value, '[]')) {
        // Recovery
        token = rewriteSquareBrackets(token);
        token = parseOptionalPositionalParameters(token, kind);
        token = ensureCloseParen(token, begin);
        break;
      }
      token = parseFormalParameter(token, FormalParameterKind.mandatory, kind);
      next = token.next;
      if (optional(',', next)) {
        token = next;
        continue;
      }
      token = ensureCloseParen(token, begin);
      break;
    }
    assert(optional(')', token));
    listener.endFormalParameters(parameterCount, begin, token, kind);
    return token;
  }

  /// Return the message that should be produced when the formal parameters are
  /// missing.
  Message missingParameterMessage(MemberKind kind) {
    if (kind == MemberKind.FunctionTypeAlias) {
      return fasta.messageMissingTypedefParameters;
    } else if (kind == MemberKind.NonStaticMethod ||
        kind == MemberKind.StaticMethod) {
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
    assert(parameterKind != null);
    token = parseMetadataStar(token);
    Token next = token.next;
    listener.beginFormalParameter(next, memberKind);

    TypeContinuation typeContinuation =
        typeContinuationFromFormalParameterKind(parameterKind);
    Token varFinalOrConst;
    if (isModifier(next)) {
      int modifierCount = 0;
      Token covariantToken;
      if (optional('covariant', next)) {
        if (memberKind != MemberKind.StaticMethod &&
            memberKind != MemberKind.TopLevelMethod) {
          covariantToken = token = parseModifier(token);
          ++modifierCount;
          next = token.next;
        }
      }

      if (isModifier(next)) {
        if (optional('var', next)) {
          typeContinuation = typeContinuationAfterVar(typeContinuation);
          varFinalOrConst = token = parseModifier(token);
          ++modifierCount;
          next = token.next;
        } else if (optional('final', next)) {
          varFinalOrConst = token = parseModifier(token);
          ++modifierCount;
          next = token.next;
        }

        if (isModifier(next)) {
          // Recovery
          ModifierRecoveryContext modifierContext = new ModifierRecoveryContext(
              this, memberKind, parameterKind, false, typeContinuation);
          token = modifierContext.parseRecovery(token,
              covariantToken: covariantToken, varFinalOrConst: varFinalOrConst);

          modifierCount = modifierContext.modifierCount;
          covariantToken = modifierContext.covariantToken;
          varFinalOrConst = modifierContext.varFinalOrConst;

          memberKind = modifierContext.memberKind;
          typeContinuation = modifierContext.typeContinuation;
          varFinalOrConst = modifierContext.varFinalOrConst;
          modifierContext = null;
        }
      }
      listener.handleModifiers(modifierCount);
    } else {
      listener.handleModifiers(0);
    }

    return parseType(
        token, typeContinuation, null, memberKind, varFinalOrConst);
  }

  /// ```
  /// defaultFormalParameter:
  ///   normalFormalParameter ('=' expression)?
  /// ;
  /// ```
  Token parseOptionalPositionalParameters(Token token, MemberKind kind) {
    Token begin = token = token.next;
    assert(optional('[', token));
    listener.beginOptionalFormalParameters(begin);
    int parameterCount = 0;
    while (true) {
      Token next = token.next;
      if (optional(']', next)) {
        break;
      }
      token = parseFormalParameter(
          token, FormalParameterKind.optionalPositional, kind);
      next = token.next;
      ++parameterCount;
      if (!optional(',', next)) {
        if (!optional(']', next)) {
          // Recovery
          reportRecoverableError(
              next, fasta.templateExpectedButGot.withArguments(']'));
          // Scanner guarantees a closing bracket.
          next = begin.endGroup;
          while (token.next != next) {
            token = token.next;
          }
        }
        break;
      }
      token = next;
    }
    if (parameterCount == 0) {
      token = rewriteAndRecover(
          token,
          fasta.messageEmptyOptionalParameterList,
          new SyntheticStringToken(
              TokenType.IDENTIFIER, '', token.next.charOffset, 0));
      token = parseFormalParameter(
          token, FormalParameterKind.optionalPositional, kind);
      ++parameterCount;
    }
    token = token.next;
    assert(optional(']', token));
    listener.endOptionalFormalParameters(parameterCount, begin, token);
    return token;
  }

  /// ```
  /// defaultNamedParameter:
  ///   normalFormalParameter ('=' expression)? |
  ///   normalFormalParameter (':' expression)?
  /// ;
  /// ```
  Token parseOptionalNamedParameters(Token token, MemberKind kind) {
    Token begin = token = token.next;
    assert(optional('{', token));
    listener.beginOptionalFormalParameters(begin);
    int parameterCount = 0;
    while (true) {
      Token next = token.next;
      if (optional('}', next)) {
        break;
      }
      token =
          parseFormalParameter(token, FormalParameterKind.optionalNamed, kind);
      next = token.next;
      ++parameterCount;
      if (!optional(',', next)) {
        if (!optional('}', next)) {
          // Recovery
          reportRecoverableError(
              next, fasta.templateExpectedButGot.withArguments('}'));
          // Scanner guarantees a closing bracket.
          next = begin.endGroup;
          while (token.next != next) {
            token = token.next;
          }
        }
        break;
      }
      token = next;
    }
    if (parameterCount == 0) {
      token = rewriteAndRecover(
          token,
          fasta.messageEmptyNamedParameterList,
          new SyntheticStringToken(
              TokenType.IDENTIFIER, '', token.next.charOffset, 0));
      token =
          parseFormalParameter(token, FormalParameterKind.optionalNamed, kind);
      ++parameterCount;
    }
    token = token.next;
    assert(optional('}', token));
    listener.endOptionalFormalParameters(parameterCount, begin, token);
    return token;
  }

  /// Skip over the `Function` type parameter.
  /// For example, `Function<E>(int foo)` or `Function(foo)` or just `Function`.
  Token skipGenericFunctionType(Token token) {
    Token last = token;
    Token next = token.next;
    while (optional('Function', next)) {
      last = token;
      token = next;
      next = token.next;
      if (optional('<', next)) {
        next = next.endGroup;
        if (next == null) {
          // TODO(danrubel): Consider better recovery
          // because this is probably a type reference.
          return token;
        }
        token = next;
        next = token.next;
      }
      if (optional('(', next)) {
        token = next.endGroup;
        next = token.next;
      }
    }
    if (next.isKeywordOrIdentifier) {
      return token;
    } else {
      return last;
    }
  }

  /// If the token after [token] begins a valid type reference
  /// or looks like a valid type reference, then return the last token
  /// in that type reference, otherwise return [token].
  ///
  /// For example, it is an error when built-in keyword is being used as a type,
  /// as in `abstract<t> foo`. In situations such as this, return the last
  /// token in that type reference and assume the caller will report the error
  /// and recover.
  Token skipTypeReferenceOpt(Token token) {
    final Token beforeStart = token;
    Token next = token.next;

    TokenType type = next.type;
    bool looksLikeTypeRef = false;
    if (type != TokenType.IDENTIFIER) {
      String value = next.stringValue;
      if (identical(value, 'get') || identical(value, 'set')) {
        // No type reference.
        return beforeStart;
      } else if (identical(value, 'factory') || identical(value, 'operator')) {
        Token next2 = next.next;
        if (!optional('<', next2) || next2.endGroup == null) {
          // No type reference.
          return beforeStart;
        }
        // Even though built-ins cannot be used as a type,
        // it looks like its being used as such.
      } else if (identical(value, 'void')) {
        // Found type reference.
        looksLikeTypeRef = true;
      } else if (identical(value, 'Function')) {
        // Found type reference.
        return skipGenericFunctionType(token);
      } else if (identical(value, 'typedef')) {
        // `typedef` can be used as a prefix.
        // For example: `typedef.A x = new typedef.A();`
        if (!optional('.', next.next)) {
          // No type reference.
          return beforeStart;
        }
      } else if (!next.isIdentifier) {
        // No type reference.
        return beforeStart;
      }
    }
    token = next;
    next = token.next;

    if (optional('.', next)) {
      token = next;
      next = token.next;
      if (next.type != TokenType.IDENTIFIER) {
        String value = next.stringValue;
        if (identical(value, 'get') || identical(value, 'set')) {
          // Found a type reference, but missing an identifier after the period.
          rewriteAndRecover(
              token,
              fasta.templateExpectedIdentifier.withArguments(next),
              new SyntheticStringToken(
                  TokenType.IDENTIFIER, '', next.charOffset, 0));
          // Return the newly inserted synthetic token
          // as the end of the type reference.
          return token.next;
        } else if (identical(value, '<')) {
          // Found a type reference, but missing an identifier after the period.
          rewriteAndRecover(
              token,
              fasta.templateExpectedIdentifier.withArguments(next),
              new SyntheticStringToken(
                  TokenType.IDENTIFIER, '', next.charOffset, 0));
          // Fall through to continue processing as a type reference.
          next = token.next;
        } else if (!next.isIdentifier) {
          if (identical(value, 'void')) {
            looksLikeTypeRef = true;
            // Found a type reference, but the period
            // and preceding identifier are both invalid.
            reportRecoverableErrorWithToken(
                token, fasta.templateUnexpectedToken);
            // Fall through to continue processing as a type reference.
          } else {
            // No type reference.
            return beforeStart;
          }
        }
      }
      token = next;
      next = token.next;
    }

    if (optional('<', next)) {
      token = next.endGroup;
      if (token == null) {
        // TODO(danrubel): Consider better recovery
        // because this is probably a type reference.
        return beforeStart;
      }
      next = token.next;
      if (optional('(', next)) {
        // No type reference - e.g. `f<E>()`.
        return beforeStart;
      }
    }

    if (optional('Function', next)) {
      looksLikeTypeRef = true;
      token = skipGenericFunctionType(token);
      next = token.next;
    }

    return next.isIdentifier ||
            (next.isOperator && !optional('=', next)) ||
            looksLikeTypeRef
        ? token
        : beforeStart;
  }

  bool isValidTypeReference(Token token) {
    int kind = token.kind;
    if (IDENTIFIER_TOKEN == kind) return true;
    if (KEYWORD_TOKEN == kind) {
      TokenType type = token.type;
      String value = type.lexeme;
      return type.isPseudo ||
          (type.isBuiltIn && optional('.', token.next)) ||
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
    token = ensureIdentifier(token, context);
    listener.handleQualified(period);
    return token;
  }

  Token skipBlock(Token token) {
    token = ensureBlock(token, null);
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
    Token enumKeyword = token.next;
    assert(optional('enum', enumKeyword));
    listener.beginEnum(enumKeyword);
    token =
        ensureIdentifier(enumKeyword, IdentifierContext.enumDeclaration).next;
    Token leftBrace = token;
    expect('{', token);
    int count = 0;
    do {
      Token next = token.next;
      if (optional('}', next)) {
        token = next;
        if (count == 0) {
          reportRecoverableError(token, fasta.messageEnumDeclarationEmpty);
        }
        break;
      }
      token = parseMetadataStar(token);
      if (!identical(token.next, next)) {
        listener.handleRecoverableError(
            fasta.messageAnnotationOnEnumConstant, next, token);
      }
      token =
          ensureIdentifier(token, IdentifierContext.enumValueDeclaration).next;
      count++;
    } while (optional(',', token));
    expect('}', token);
    listener.endEnum(enumKeyword, leftBrace, count);
    return token;
  }

  Token parseClassOrNamedMixinApplication(
      Token token, Token beforeAbstractToken) {
    token = token.next;
    listener.beginClassOrNamedMixinApplication(token);
    Token begin = beforeAbstractToken?.next ?? token;
    if (beforeAbstractToken != null) {
      token = parseModifier(beforeAbstractToken).next;
      listener.handleModifiers(1);
    } else {
      listener.handleModifiers(0);
    }
    Token classKeyword = token;
    expect("class", token);
    Token name =
        ensureIdentifier(token, IdentifierContext.classOrNamedMixinDeclaration);
    token = parseTypeVariablesOpt(name);
    if (optional('=', token.next)) {
      listener.beginNamedMixinApplication(begin, name);
      return parseNamedMixinApplication(token, begin, classKeyword);
    } else {
      listener.beginClassDeclaration(begin, name);
      return parseClass(token, begin, classKeyword);
    }
  }

  Token parseNamedMixinApplication(
      Token token, Token begin, Token classKeyword) {
    Token equals = token = token.next;
    assert(optional('=', equals));
    token = parseType(token);
    token = parseMixinApplicationRest(token);
    Token implementsKeyword = null;
    if (optional('implements', token.next)) {
      implementsKeyword = token.next;
      token = parseTypeList(implementsKeyword);
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
    Token start = token;
    token = parseClassHeaderOpt(token, begin, classKeyword);
    if (!optional('{', token.next)) {
      // Recovery
      token = parseClassHeaderRecovery(start, begin, classKeyword);
      ensureBlock(token, fasta.templateExpectedClassBody);
    }
    token = parseClassBody(token);
    listener.endClassDeclaration(begin, token);
    return token;
  }

  Token parseClassHeaderOpt(Token token, Token begin, Token classKeyword) {
    token = parseClassExtendsOpt(token);
    token = parseClassImplementsOpt(token);
    Token nativeToken;
    if (optional('native', token.next)) {
      nativeToken = token.next;
      token = parseNativeClause(token);
    }
    listener.handleClassHeader(begin, classKeyword, nativeToken);
    return token;
  }

  /// Recover given out-of-order clauses in a class header.
  Token parseClassHeaderRecovery(Token token, Token begin, Token classKeyword) {
    final primaryListener = listener;
    final recoveryListener = new ClassHeaderRecoveryListener(primaryListener);

    // Reparse to determine which clauses have already been parsed
    // but intercept the events so they are not sent to the primary listener.
    listener = recoveryListener;
    token = parseClassHeaderOpt(token, begin, classKeyword);
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
      Token next = token.next;
      if (optional('with', next)) {
        // If there is a `with` clause without a preceding `extends` clause
        // then insert a synthetic `extends` clause and parse both clauses.
        Token extendsKeyword =
            new SyntheticKeywordToken(Keyword.EXTENDS, next.offset);
        Token superclassToken = new SyntheticStringToken(
            TokenType.IDENTIFIER, 'Object', next.offset, 0);
        rewriter.insertTokenAfter(token, extendsKeyword);
        rewriter.insertTokenAfter(extendsKeyword, superclassToken);
        token = parseType(extendsKeyword);
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
    } while (!optional('{', token.next) && start != token);

    if (withKeyword != null && !hasExtends) {
      reportRecoverableError(withKeyword, fasta.messageWithWithoutExtends);
    }

    listener = primaryListener;
    return token;
  }

  Token parseClassExtendsOpt(Token token) {
    Token next = token.next;
    if (optional('extends', next)) {
      Token extendsKeyword = next;
      token = parseType(next);
      if (optional('with', token.next)) {
        token = parseMixinApplicationRest(token);
      } else {
        token = token;
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
    Token implementsKeyword;
    int interfacesCount = 0;
    if (optional('implements', token.next)) {
      implementsKeyword = token.next;
      do {
        token = parseType(token.next);
        ++interfacesCount;
      } while (optional(',', token.next));
    }
    listener.handleClassImplements(implementsKeyword, interfacesCount);
    return token;
  }

  Token parseStringPart(Token token) {
    token = token.next;
    if (token.kind != STRING_TOKEN) {
      token =
          reportUnrecoverableErrorWithToken(token, fasta.templateExpectedString)
              .next;
    }
    listener.handleStringPart(token);
    return token;
  }

  /// Insert a synthetic identifier after the given [token] and create an error
  /// message based on the given [context]. Return the synthetic identifier that
  /// was inserted.
  Token insertSyntheticIdentifier(Token token, IdentifierContext context,
      {Message message, Token messageOnToken}) {
    Token next = token.next;
    reportRecoverableError(messageOnToken ?? next,
        message ?? context.recoveryTemplate.withArguments(next));
    Token identifier = new SyntheticStringToken(
        TokenType.IDENTIFIER,
        context == IdentifierContext.methodDeclaration ||
                context == IdentifierContext.topLevelVariableDeclaration ||
                context == IdentifierContext.fieldDeclaration
            ? '#synthetic_identifier_${next.offset}'
            : '',
        next.charOffset,
        0);
    rewriter.insertTokenAfter(token, identifier);
    return token.next;
  }

  /// Parse a simple identifier at the given [token], and return the identifier
  /// that was parsed.
  ///
  /// If the token is not an identifier, or is not appropriate for use as an
  /// identifier in the given [context], create a synthetic identifier, report
  /// an error, and return the synthetic identifier.
  Token ensureIdentifier(Token token, IdentifierContext context) {
    Token next = token.next;
    if (!next.isIdentifier) {
      if (optional("void", next)) {
        reportRecoverableError(next, fasta.messageInvalidVoid);
        token = next;
      } else if (next is ErrorToken) {
        // TODO(brianwilkerson): This preserves the current semantics, but the
        // listener should not be recovering from this case, so this needs to be
        // reworked to recover in this method (probably inside the outermost
        // if statement).
        token =
            reportUnrecoverableErrorWithToken(next, context.recoveryTemplate)
                .next;
      } else if (isIdentifierForRecovery(next, context)) {
        reportRecoverableErrorWithToken(next, context.recoveryTemplate);
        token = next;
      } else if (isPostIdentifierForRecovery(next, context) ||
          isStartOfNextSibling(next, context)) {
        token = insertSyntheticIdentifier(token, context);
      } else if (next.isKeywordOrIdentifier) {
        reportRecoverableErrorWithToken(next, context.recoveryTemplate);
        token = next;
      } else if (next.isUserDefinableOperator &&
          context == IdentifierContext.methodDeclaration) {
        // If this is a user definable operator, then assume that the user has
        // forgotten the `operator` keyword.
        token = rewriteAndRecover(token, fasta.messageMissingOperatorKeyword,
            new SyntheticKeywordToken(Keyword.OPERATOR, next.offset));
        return parseOperatorName(token);
      } else {
        reportRecoverableErrorWithToken(next, context.recoveryTemplate);
        if (context == IdentifierContext.methodDeclaration) {
          // Since the token is not a keyword or identifier, consume it to
          // ensure forward progress in parseMethod.
          token = next.next;
          // Supply a non-empty method name so that it does not accidentally
          // match the default constructor.
          token = insertSyntheticIdentifier(next, context);
        } else if (context == IdentifierContext.topLevelVariableDeclaration ||
            context == IdentifierContext.fieldDeclaration) {
          // Since the token is not a keyword or identifier, consume it to
          // ensure forward progress in parseField.
          token = next.next;
          // Supply a non-empty method name so that it does not accidentally
          // match the default constructor.
          token = insertSyntheticIdentifier(next, context);
        } else if (context == IdentifierContext.constructorReference) {
          token = insertSyntheticIdentifier(token, context);
        } else {
          token = next;
        }
      }
    } else if (next.type.isBuiltIn && !context.isBuiltInIdentifierAllowed) {
      if (context.inDeclaration) {
        reportRecoverableErrorWithToken(
            next, fasta.templateBuiltInIdentifierInDeclaration);
      } else if (!optional("dynamic", next)) {
        if (context == IdentifierContext.typeReference &&
            optional('.', next.next)) {
          // Built in identifiers may be used as a prefix
        } else {
          reportRecoverableErrorWithToken(
              next, fasta.templateBuiltInIdentifierAsType);
        }
      }
      token = next;
    } else if (!inPlainSync && next.type.isPseudo) {
      if (optional('await', next)) {
        reportRecoverableError(next, fasta.messageAwaitAsIdentifier);
      } else if (optional('yield', next)) {
        reportRecoverableError(next, fasta.messageYieldAsIdentifier);
      } else if (optional('async', next)) {
        reportRecoverableError(next, fasta.messageAsyncAsIdentifier);
      }
      token = next;
    } else {
      token = next;
    }
    listener.handleIdentifier(token, context);
    return token;
  }

  /// Return `true` if the given [token] should be treated like the start of
  /// an expression for the purposes of recovery.
  bool isExpressionStartForRecovery(Token next) =>
      next.isKeywordOrIdentifier ||
      next.type == TokenType.DOUBLE ||
      next.type == TokenType.HASH ||
      next.type == TokenType.HEXADECIMAL ||
      next.type == TokenType.IDENTIFIER ||
      next.type == TokenType.INT ||
      next.type == TokenType.STRING ||
      optional('{', next) ||
      optional('(', next) ||
      optional('[', next) ||
      optional('[]', next) ||
      optional('<', next) ||
      optional('!', next) ||
      optional('-', next) ||
      optional('~', next) ||
      optional('++', next) ||
      optional('--', next);

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
    } else if (context == IdentifierContext.combinator) {
      followingValues = [';'];
    } else if (context == IdentifierContext.constructorReferenceContinuation) {
      followingValues = ['.', ',', '(', ')', '[', ']', '}', ';'];
    } else if (context == IdentifierContext.fieldDeclaration) {
      followingValues = [';', '=', ',', '}'];
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
        '.',
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
      followingValues = [';', '=', ',', '}'];
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
      followingValues = ['>', ')', ']', '}', ',', ';'];
    } else if (context == IdentifierContext.typeVariableDeclaration) {
      followingValues = ['<', '>', ';', '}'];
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
    listener.beginTypeVariable(token.next);
    token = parseMetadataStar(token);
    token = ensureIdentifier(token, IdentifierContext.typeVariableDeclaration);
    Token extendsOrSuper = null;
    Token next = token.next;
    if (optional('extends', next) || optional('super', next)) {
      extendsOrSuper = next;
      token = parseType(next);
    } else {
      listener.handleNoType(token);
    }
    listener.endTypeVariable(token.next, extendsOrSuper);
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
      MemberKind memberKind,
      Token varFinalOrConst]) {
    /// True if we've seen the `var` keyword.
    bool hasVar = false;

    /// The token before [token].
    Token beforeToken;

    /// The token before the `begin` token.
    Token beforeBegin;

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

    /// The tokens before the start of type variables of function types seen
    /// during analysis. Notice that the tokens in this list might precede
    /// either `'<'` or `'('` as not all function types have type parameters.
    /// Also, it is safe to assume that [closeBraceTokenFor] will return
    /// non-null for all of the tokens following these tokens.
    Link<Token> typeVariableStarters = const Link<Token>();

    {
      // Analyse the next tokens to see if they could be a type.

      if (continuation ==
          TypeContinuation.ExpressionStatementOrConstDeclaration) {
        // This is a special case. The first token is `const` and we need to
        // analyze the tokens following the const keyword.
        assert(optional("const", token.next));
        beforeBegin = token;
        begin = beforeToken = token.next;
        token = beforeToken.next;
      } else {
        beforeToken = beforeBegin = token;
        token = begin = token.next;
      }

      if (optional("void", token)) {
        // `void` is a type.
        looksLikeType = true;
        beforeToken = voidToken = token;
        token = token.next;
      } else if (isValidTypeReference(token) &&
          !isGeneralizedFunctionType(token)) {
        // We're looking at an identifier that could be a type (or `dynamic`).
        looksLikeType = true;
        beforeToken = token;
        token = token.next;
        if (optional(".", token) && isValidTypeReference(token.next)) {
          // We're looking at `prefix '.' identifier`.
          context = IdentifierContext.prefixedTypeReference;
          beforeToken = token.next;
          token = beforeToken.next;
        }
        if (optional("<", token)) {
          Token close = closeBraceTokenFor(token);
          if (close != null &&
              (optional(">", close) || optional(">>", close))) {
            // We found some type arguments.
            typeArguments = token;
            beforeToken = close;
            token = close.next;
          }
        }
      } else if (token.isModifier && isValidTypeReference(token.next)) {
        // Recovery - report error and skip modifier
        reportRecoverableErrorWithToken(token, fasta.templateExpectedType);
        return parseType(token, continuation, continuationContext, memberKind);
      }

      // If what we have seen so far looks like a type, that could be a return
      // type for a generalized function type.
      hasReturnType = looksLikeType;

      while (optional("Function", token)) {
        Token typeVariableStart = token;
        if (optional("<", token.next)) {
          Token close = closeBraceTokenFor(token.next);
          if (close != null && optional(">", close)) {
            beforeToken = previousToken(token, close);
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
          beforeToken = close;
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
        listener.handleNoType(beforeBegin);
        token = beforeBegin;
      } else if (voidToken != null) {
        listener.handleVoidKeyword(voidToken);
        token = voidToken;
      } else {
        token = ensureIdentifier(beforeBegin, context);
        token = parseQualifiedRestOpt(
            token, IdentifierContext.typeReferenceContinuation);
        assert(typeArguments == null || typeArguments == token.next);
        token = parseTypeArgumentsOpt(token);
        listener.handleType(begin, token.next);
      }

      for (int i = 0; i < functionTypes; i++) {
        Token next = token.next;
        assert(optional('Function', next));
        Token functionToken = next;
        if (optional("<", next.next)) {
          // Skip type parameters, they were parsed above.
          next = closeBraceTokenFor(next.next);
        }
        token = parseFormalParametersRequiredOpt(
            next, MemberKind.GeneralizedFunctionType);
        listener.endFunctionType(functionToken, token.next);
      }

      if (hasVar) {
        reportRecoverableError(begin, fasta.messageTypeAfterVar);
      }

      return token;
    }

    /// Returns true if [kind] could be the end of a variable declaration.
    bool looksLikeVariableDeclarationEnd(int kind) {
      return EQ_TOKEN == kind ||
          SEMICOLON_TOKEN == kind ||
          COMMA_TOKEN == kind ||
          // Recovery: Return true for these additional invalid situations
          // in which we assume a missing semicolon.
          OPEN_CURLY_BRACKET_TOKEN == kind ||
          CLOSE_CURLY_BRACKET_TOKEN == kind;
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
            listener.handleNoType(beforeBegin);
            return beforeBegin;
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
            return voidToken;
          }
          if (token.isIdentifier || optional('this', token)) {
            return commitType(); // Parse type.
          }
        }
        listener.handleNoType(beforeBegin);
        return beforeBegin;

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
          return parseExpressionStatement(beforeBegin);
        }

        if (looksLikeType && token.isIdentifier) {
          Token afterId = token.next;

          int afterIdKind = afterId.kind;
          if (looksLikeVariableDeclarationEnd(afterIdKind)) {
            // We are looking at `type identifier` followed by
            // `(',' | '=' | ';')`.

            // TODO(ahe): Generate type events and call
            // parseVariablesDeclarationRest instead.
            return parseVariablesDeclaration(beforeBegin);
          } else if (OPEN_PAREN_TOKEN == afterIdKind) {
            // We are looking at `type identifier '('`.
            if (looksLikeFunctionBody(closeBraceTokenFor(afterId).next)) {
              // We are looking at `type identifier '(' ... ')'` followed
              // `( '{' | '=>' | 'async' | 'sync' )`.

              // Although it looks like there are no type variables here, they
              // may get injected from a comment.
              Token beforeFormals = parseTypeVariablesOpt(token);

              listener.beginLocalFunctionDeclaration(begin);
              listener.handleModifiers(0);
              if (voidToken != null) {
                listener.handleVoidKeyword(voidToken);
              } else {
                commitType();
              }
              return parseNamedFunctionRest(
                  beforeToken, begin, beforeFormals, false);
            }
          } else if (identical(afterIdKind, LT_TOKEN)) {
            // We are looking at `type identifier '<'`.
            Token beforeFormals = closeBraceTokenFor(afterId);
            if (beforeFormals?.next != null &&
                optional("(", beforeFormals.next)) {
              if (looksLikeFunctionBody(
                  closeBraceTokenFor(beforeFormals.next).next)) {
                // We are looking at "type identifier '<' ... '>' '(' ... ')'"
                // followed by '{', '=>', 'async', or 'sync'.
                parseTypeVariablesOpt(token);
                listener.beginLocalFunctionDeclaration(begin);
                listener.handleModifiers(0);
                if (voidToken != null) {
                  listener.handleVoidKeyword(voidToken);
                } else {
                  commitType();
                }
                return parseNamedFunctionRest(
                    beforeToken, begin, beforeFormals, false);
              }
            }
          }
          // Fall-through to expression statement.
        } else {
          beforeToken = beforeBegin;
          token = begin;
          if (optional(':', token.next)) {
            return parseLabeledStatement(beforeToken);
          } else if (optional('(', token.next)) {
            if (looksLikeFunctionBody(closeBraceTokenFor(token.next).next)) {
              // We are looking at `identifier '(' ... ')'` followed by `'{'`,
              // `'=>'`, `'async'`, or `'sync'`.

              // Although it looks like there are no type variables here, they
              // may get injected from a comment.
              Token formals = parseTypeVariablesOpt(token);

              listener.beginLocalFunctionDeclaration(token);
              listener.handleModifiers(0);
              listener.handleNoType(token);
              return parseNamedFunctionRest(beforeToken, begin, formals, false);
            }
          } else if (optional('<', token.next)) {
            Token gt = closeBraceTokenFor(token.next);
            if (gt?.next != null && optional("(", gt.next)) {
              if (looksLikeFunctionBody(closeBraceTokenFor(gt.next).next)) {
                // We are looking at `identifier '<' ... '>' '(' ... ')'`
                // followed by `'{'`, `'=>'`, `'async'`, or `'sync'`.
                parseTypeVariablesOpt(token);
                listener.beginLocalFunctionDeclaration(token);
                listener.handleModifiers(0);
                listener.handleNoType(token);
                return parseNamedFunctionRest(beforeToken, begin, gt, false);
              }
            }
            // Fall through to expression statement.
          }
        }
        return parseExpressionStatement(beforeBegin);

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
            return parseVariablesDeclaration(beforeBegin);
          }
          // Fall-through to expression statement.
        }

        return parseExpressionStatement(beforeBegin);

      case TypeContinuation.SendOrFunctionLiteral:
        Token beforeName;
        Token name;
        bool hasReturnType;
        if (looksLikeType && looksLikeFunctionDeclaration(token)) {
          beforeName = beforeToken;
          name = token;
          hasReturnType = true;
          // Fall-through to parseNamedFunctionRest below.
        } else if (looksLikeFunctionDeclaration(begin)) {
          beforeName = beforeBegin;
          name = begin;
          hasReturnType = false;
          // Fall-through to parseNamedFunctionRest below.
        } else {
          return parseSend(beforeBegin, continuationContext);
        }

        Token formals = parseTypeVariablesOpt(name);
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
          listener.handleNoType(formals);
        }
        if (beforeName.next != name)
          throw new StateError("beforeName.next != name");
        return parseNamedFunctionRest(beforeName, begin, formals, true);

      case TypeContinuation.VariablesDeclarationOrExpression:
        if (looksLikeType && token.isIdentifier) {
          // TODO(ahe): Generate type events and call
          // parseVariablesDeclarationNoSemicolonRest instead.
          return parseVariablesDeclarationNoSemicolon(beforeBegin);
        }
        return parseExpression(beforeBegin);

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
          beforeToken = beforeBegin;
          token = begin;
        }

        Token thisKeyword;
        Token periodAfterThis;
        Token beforeNameToken = beforeToken;
        Token nameToken = token;
        IdentifierContext nameContext =
            IdentifierContext.formalParameterDeclaration;
        beforeToken = token;
        token = token.next;
        if (inFunctionType) {
          if (isNamedParameter) {
            nameContext = IdentifierContext.formalParameterDeclaration;
            if (!nameToken.isKeywordOrIdentifier) {
              beforeToken = beforeNameToken;
              token = nameToken;
            }
          } else if (nameToken.isIdentifier) {
            nameContext = IdentifierContext.formalParameterDeclaration;
          } else {
            // No name required in a function type.
            nameContext = null;
            beforeToken = beforeNameToken;
            token = nameToken;
          }
        } else if (optional('this', nameToken)) {
          thisKeyword = nameToken;
          if (!optional('.', token)) {
            // Recover from a missing period by inserting one.
            Message message = fasta.templateExpectedButGot.withArguments('.');
            Token newToken =
                new SyntheticToken(TokenType.PERIOD, token.charOffset);
            periodAfterThis =
                rewriteAndRecover(thisKeyword, message, newToken).next;
          } else {
            periodAfterThis = token;
          }
          beforeToken = periodAfterThis;
          token = periodAfterThis.next;
          nameContext = IdentifierContext.fieldInitializer;
          if (!token.isIdentifier) {
            // Recover from a missing identifier by inserting one.
            token = insertSyntheticIdentifier(beforeToken, nameContext);
          }
          beforeNameToken = beforeToken;
          beforeToken = nameToken = token;
          token = token.next;
        } else if (!nameToken.isIdentifier) {
          if (optional('.', nameToken)) {
            // Recovery:
            // Looks like a prefixed type, but missing the type and param names.
            // Set the nameToken so that a synthetic identifier is inserted
            // after the `.` token.
            beforeToken = beforeNameToken = nameToken;
            token = nameToken = nameToken.next;
          } else if (context == IdentifierContext.prefixedTypeReference) {
            // Recovery:
            // Looks like a prefixed type, but missing the parameter name.
            beforeToken = nameToken =
                insertSyntheticIdentifier(beforeNameToken, nameContext);
            token = beforeToken.next;
          } else {
            untyped = true;
            beforeNameToken = beforeBegin;
            beforeToken = nameToken = begin;
            token = nameToken.next;
          }
        }
        if (isNamedParameter && nameToken.lexeme.startsWith("_")) {
          // TODO(ahe): Move this to after committing the type.
          reportRecoverableError(nameToken, fasta.messagePrivateNamedParameter);
        }

        Token inlineFunctionTypeStart;
        if (optional("<", token)) {
          Token closer = closeBraceTokenFor(token);
          if (closer != null) {
            if (optional("(", closer.next)) {
              if (varFinalOrConst != null) {
                reportRecoverableError(
                    varFinalOrConst, fasta.messageFunctionTypedParameterVar);
              }
              inlineFunctionTypeStart = beforeToken;
              beforeToken = token;
              token = token.next;
            }
          }
        } else if (optional("(", token)) {
          if (varFinalOrConst != null) {
            reportRecoverableError(
                varFinalOrConst, fasta.messageFunctionTypedParameterVar);
          }
          inlineFunctionTypeStart = beforeToken;
          beforeToken = closeBraceTokenFor(token);
          token = beforeToken.next;
        }

        if (inlineFunctionTypeStart != null) {
          token = parseTypeVariablesOpt(inlineFunctionTypeStart);
          // TODO(brianwilkerson): Figure out how to remove the invocation of
          // `previous`. The method `parseTypeVariablesOpt` returns the last
          // consumed token.
          beforeToken = token.previous;
          listener
              .beginFunctionTypedFormalParameter(inlineFunctionTypeStart.next);
          if (!untyped) {
            if (voidToken != null) {
              listener.handleVoidKeyword(voidToken);
            } else {
              Token saved = token;
              commitType();
              token = saved;
              // We need to recompute the before tokens because [commitType] can
              // cause synthetic tokens to be inserted.
              beforeToken = previousToken(beforeToken, token);
              beforeNameToken = previousToken(beforeNameToken, nameToken);
            }
          } else {
            listener.handleNoType(beforeToken);
          }
          beforeToken = parseFormalParametersRequiredOpt(
              token, MemberKind.FunctionTypedParameter);
          token = beforeToken.next;
          listener.endFunctionTypedFormalParameter();

          // Generalized function types don't allow inline function types.
          // The following isn't allowed:
          //    int Function(int bar(String x)).
          if (memberKind == MemberKind.GeneralizedFunctionType) {
            reportRecoverableError(inlineFunctionTypeStart.next,
                fasta.messageInvalidInlineFunctionType);
          }
        } else if (untyped) {
          listener.handleNoType(token);
        } else {
          Token saved = token;
          commitType();
          token = saved;
          // We need to recompute the before tokens because [commitType] can
          // cause synthetic tokens to be inserted.
          beforeToken = previousToken(beforeToken, token);
          beforeNameToken = previousToken(beforeNameToken, nameToken);
        }

        if (nameContext != null) {
          nameToken = ensureIdentifier(beforeNameToken, nameContext);
          // We need to recompute the before tokens because [ensureIdentifier]
          // can cause synthetic tokens to be inserted.
          beforeToken = previousToken(beforeToken, token);
        } else {
          listener.handleNoName(nameToken);
        }

        String value = token.stringValue;
        if ((identical('=', value)) || (identical(':', value))) {
          Token equal = token;
          beforeToken = parseExpression(token);
          token = beforeToken.next;
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
        return beforeToken;
    }

    throw "Internal error: Unhandled continuation '$continuation'.";
  }

  Token parseTypeArgumentsOpt(Token token) {
    return parseStuffOpt(
        token,
        (t) => listener.beginTypeArguments(t),
        (t) => parseType(t),
        (c, bt, et) => listener.endTypeArguments(c, bt, et),
        (t) => listener.handleNoTypeArguments(t));
  }

  Token parseTypeVariablesOpt(Token token) {
    return parseStuffOpt(
        token,
        (t) => listener.beginTypeVariables(t),
        (t) => parseTypeVariable(t),
        (c, bt, et) => listener.endTypeVariables(c, bt, et),
        (t) => listener.handleNoTypeVariables(t));
  }

  /// TODO(ahe): Clean this up.
  Token parseStuffOpt(Token token, Function beginStuff, Function stuffParser,
      Function endStuff, Function handleNoStuff) {
    Token next = token.next;
    if (optional('<', next)) {
      BeginToken begin = next;
      rewriteLtEndGroupOpt(begin);
      beginStuff(begin);
      int count = 0;
      do {
        token = stuffParser(token.next);
        ++count;
      } while (optional(',', token.next));
      token = begin.endToken = ensureGt(token);
      endStuff(count, begin, token);
      return token;
    }
    handleNoStuff(next);
    return token;
  }

  /// Parse a top level field or function.
  ///
  /// This method is only invoked from outside the parser. As a result, this
  /// method takes the next token to be consumed rather than the last consumed
  /// token and returns the token after the last consumed token rather than the
  /// last consumed token.
  Token parseTopLevelMember(Token token) {
    token = parseMetadataStar(syntheticPreviousToken(token));
    return parseTopLevelMemberImpl(token).next;
  }

  Token parseTopLevelMemberImpl(Token token) {
    Token beforeStart = token;
    Token next = token.next;
    listener.beginTopLevelMember(next);

    Token externalToken;
    Token varFinalOrConst;
    TypeContinuation typeContinuation;

    if (isModifier(next)) {
      if (optional('external', next)) {
        externalToken = token = next;
        next = token.next;
      }
      if (isModifier(next)) {
        if (optional('final', next)) {
          typeContinuation = TypeContinuation.Optional;
          varFinalOrConst = token = next;
          next = token.next;
        } else if (optional('var', next)) {
          typeContinuation = TypeContinuation.OptionalAfterVar;
          varFinalOrConst = token = next;
          next = token.next;
        } else if (optional('const', next)) {
          typeContinuation = TypeContinuation.Optional;
          varFinalOrConst = token = next;
          next = token.next;
        }
        if (isModifier(next)) {
          ModifierRecoveryContext2 context = new ModifierRecoveryContext2(this);
          token = context.parseTopLevelModifiers(token, typeContinuation,
              externalToken: externalToken, varFinalOrConst: varFinalOrConst);
          next = token.next;

          typeContinuation = context.typeContinuation;
          externalToken = context.externalToken;
          varFinalOrConst = context.varFinalOrConst;
          context = null;
        }
      }
    }
    typeContinuation ??= TypeContinuation.Required;

    Token beforeType = token;
    // TODO(danrubel): Consider changing the listener contract
    // so that the type reference can be parsed immediately
    // rather than skipped now and parsed later.
    token = skipTypeReferenceOpt(token);
    if (token == beforeType) {
      // There is no type reference.
      beforeType = null;
    }
    next = token.next;

    Token getOrSet;
    String value = next.stringValue;
    if (identical(value, 'get') || identical(value, 'set')) {
      if (next.next.isIdentifier) {
        getOrSet = token = next;
        next = token.next;
      }
    }

    if (next.type != TokenType.IDENTIFIER) {
      value = next.stringValue;
      if (identical(value, 'factory') || identical(value, 'operator')) {
        // `factory` and `operator` can be used as an identifier.
        value = next.next.stringValue;
        if (getOrSet == null &&
            !identical(value, '(') &&
            !identical(value, '{') &&
            !identical(value, '<') &&
            !identical(value, '=>') &&
            !identical(value, '=') &&
            !identical(value, ';') &&
            !identical(value, ',')) {
          // Recovery
          value = next.stringValue;
          if (identical(value, 'factory')) {
            reportRecoverableError(
                next, fasta.messageFactoryTopLevelDeclaration);
          } else {
            reportRecoverableError(next, fasta.messageTopLevelOperator);
            if (next.next.isOperator) {
              token = next;
              next = token.next;
              if (optional('(', next.next)) {
                rewriter.insertTokenAfter(
                    next,
                    new SyntheticStringToken(
                        TokenType.IDENTIFIER,
                        '#synthetic_identifier_${next.charOffset}',
                        next.charOffset,
                        0));
              }
            }
          }
          listener.handleInvalidTopLevelDeclaration(next);
          return next;
        }
        // Fall through and continue parsing
      } else if (!next.isIdentifier) {
        // Recovery
        if (next.isKeyword) {
          // Fall through to parse the keyword as the identifier.
          // ensureIdentifier will report the error.
        } else if (token == beforeStart) {
          // Ensure we make progress.
          return reportInvalidTopLevelDeclaration(next);
        } else {
          // Looks like a declaration missing an identifier.
          // Insert synthetic identifier and fall through.
          insertSyntheticIdentifier(token, IdentifierContext.methodDeclaration);
          next = token.next;
        }
      }
    }
    // At this point, `token` is beforeName.

    next = next.next;
    value = next.stringValue;
    if (getOrSet != null ||
        identical(value, '(') ||
        identical(value, '{') ||
        identical(value, '<') ||
        identical(value, '.') ||
        identical(value, '=>')) {
      if (varFinalOrConst != null) {
        if (optional('var', varFinalOrConst)) {
          reportRecoverableError(varFinalOrConst, fasta.messageVarReturnType);
        } else {
          reportRecoverableErrorWithToken(
              varFinalOrConst, fasta.templateExtraneousModifier);
        }
      }
      return parseTopLevelMethod(
          beforeStart, externalToken, beforeType, getOrSet, token);
    }

    if (getOrSet != null) {
      reportRecoverableErrorWithToken(
          getOrSet, fasta.templateExtraneousModifier);
    }
    return parseFields(beforeStart, externalToken, null, null, varFinalOrConst,
        beforeType, token, MemberKind.TopLevelField, typeContinuation);
  }

  Token parseFields(
      Token beforeStart,
      Token externalToken,
      Token staticToken,
      Token covariantToken,
      Token varFinalOrConst,
      Token beforeType,
      Token beforeName,
      MemberKind memberKind,
      TypeContinuation typeContinuation) {
    // TODO(danrubel): Consider passing modifiers via endTopLevelField
    // rather than using handleModifier and handleModifiers.
    int modifierCount = 0;
    if (externalToken != null) {
      reportRecoverableError(externalToken, fasta.messageExternalField);
    }
    if (staticToken != null) {
      listener.handleModifier(staticToken);
      ++modifierCount;
    } else if (covariantToken != null) {
      if (varFinalOrConst != null && optional('final', varFinalOrConst)) {
        reportRecoverableError(covariantToken, fasta.messageFinalAndCovariant);
        covariantToken = null;
      } else {
        listener.handleModifier(covariantToken);
        ++modifierCount;
      }
    }
    if (varFinalOrConst != null) {
      listener.handleModifier(varFinalOrConst);
      ++modifierCount;
    }
    listener.handleModifiers(modifierCount);

    bool isTopLevel = memberKind == MemberKind.TopLevelField;

    if (beforeType != null) {
      parseType(beforeType, typeContinuation, null, memberKind);
    } else if (varFinalOrConst != null) {
      listener.handleNoType(beforeName);
    } else {
      // Recovery
      reportRecoverableError(
          beforeName.next, fasta.messageMissingConstFinalVarOrType);
      listener.handleNoType(beforeName);
    }

    IdentifierContext context = isTopLevel
        ? IdentifierContext.topLevelVariableDeclaration
        : IdentifierContext.fieldDeclaration;
    Token name = ensureIdentifier(beforeName, context);

    int fieldCount = 1;
    Token token =
        parseFieldInitializerOpt(name, name, varFinalOrConst, isTopLevel);
    while (optional(',', token.next)) {
      name = ensureIdentifier(token.next, context);
      token = parseFieldInitializerOpt(name, name, varFinalOrConst, isTopLevel);
      ++fieldCount;
    }
    token = ensureSemicolon(token);
    if (isTopLevel) {
      listener.endTopLevelFields(fieldCount, beforeStart.next, token);
    } else {
      listener.endFields(fieldCount, beforeStart.next, token);
    }
    return token;
  }

  Token parseTopLevelMethod(Token beforeStart, Token externalToken,
      Token beforeType, Token getOrSet, Token beforeName) {
    listener.beginTopLevelMethod(beforeStart);

    // TODO(danrubel): Consider passing modifiers via endTopLevelMethod
    // rather than handleModifier and handleModifiers
    if (externalToken != null) {
      listener.handleModifier(externalToken);
      listener.handleModifiers(1);
    } else {
      listener.handleModifiers(0);
    }

    if (beforeType == null) {
      listener.handleNoType(beforeName);
    } else {
      parseType(beforeType, TypeContinuation.Optional);
    }
    Token name = ensureIdentifier(
        beforeName, IdentifierContext.topLevelFunctionDeclaration);

    Token token;
    bool isGetter = false;
    if (getOrSet == null) {
      token = parseTypeVariablesOpt(name);
    } else {
      isGetter = optional("get", getOrSet);
      token = name;
      listener.handleNoTypeVariables(token.next);
    }
    checkFormals(name, isGetter, token.next, MemberKind.TopLevelMethod);
    token = parseFormalParametersOpt(token, MemberKind.TopLevelMethod);
    AsyncModifier savedAsyncModifier = asyncState;
    Token asyncToken = token.next;
    token = parseAsyncModifierOpt(token);
    if (getOrSet != null && !inPlainSync && optional("set", getOrSet)) {
      reportRecoverableError(asyncToken, fasta.messageSetterNotSync);
    }
    token = parseFunctionBody(token, false, externalToken != null);
    asyncState = savedAsyncModifier;
    listener.endTopLevelMethod(beforeStart.next, getOrSet, token);
    return token;
  }

  void checkFormals(Token name, bool isGetter, Token token, MemberKind kind) {
    if (optional("(", token)) {
      if (isGetter) {
        reportRecoverableError(token, fasta.messageGetterWithFormals);
      }
    } else if (!isGetter) {
      reportRecoverableError(name, missingParameterMessage(kind));
    }
  }

  Token parseFieldInitializerOpt(
      Token token, Token name, Token varFinalOrConst, bool isTopLevel) {
    Token next = token.next;
    if (optional('=', next)) {
      Token assignment = next;
      listener.beginFieldInitializer(next);
      token = parseExpression(next);
      listener.endFieldInitializer(assignment, token.next);
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
      listener.handleNoFieldInitializer(token.next);
    }
    return token;
  }

  Token parseVariableInitializerOpt(Token token) {
    if (optional('=', token.next)) {
      Token assignment = token.next;
      listener.beginVariableInitializer(assignment);
      token = parseExpression(assignment);
      listener.endVariableInitializer(assignment);
    } else {
      listener.handleNoVariableInitializer(token.next);
    }
    return token;
  }

  Token parseInitializersOpt(Token token) {
    if (optional(':', token.next)) {
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
    Token begin = token.next;
    assert(optional(':', begin));
    listener.beginInitializers(begin);
    int count = 0;
    bool old = mayParseFunctionExpressions;
    mayParseFunctionExpressions = false;
    do {
      token = parseInitializer(token.next);
      ++count;
    } while (optional(',', token.next));
    mayParseFunctionExpressions = old;
    listener.endInitializers(count, begin, token.next);
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
    Token next = token.next;
    listener.beginInitializer(next);
    if (optional('assert', next)) {
      token = parseAssert(token, Assert.Initializer);
    } else if (optional('super', next)) {
      token = parseExpression(token);
    } else if (optional('this', next)) {
      if (!optional('(', next.next)) {
        if (!optional('.', next.next)) {
          // Recovery
          reportRecoverableError(
              next.next, fasta.templateExpectedButGot.withArguments('.'));
          rewriter.insertTokenAfter(
              next, new SyntheticToken(TokenType.PERIOD, next.next.offset));
        }
        next = next.next;
        if (!next.next.isIdentifier) {
          // Recovery
          insertSyntheticIdentifier(next, IdentifierContext.fieldInitializer);
        }
        next = next.next;
      }
      if (optional('(', next.next)) {
        token = parseExpression(token);
        next = token.next;
        if (optional('{', next) || optional('=>', next)) {
          reportRecoverableError(
              next, fasta.messageRedirectingConstructorWithBody);
        }
      } else {
        if (!optional('=', next.next)) {
          // Recovery
          reportRecoverableError(
              token.next, fasta.messageMissingAssignmentInInitializer);
          next = rewriter
              .insertTokenAfter(
                  next, new SyntheticToken(TokenType.EQ, next.next.offset))
              .next;
          rewriter.insertTokenAfter(next,
              new SyntheticStringToken(TokenType.IDENTIFIER, '', next.offset));
        }
        token = parseExpression(token);
      }
    } else if (next.isIdentifier) {
      if (!optional('=', next.next)) {
        // Recovery
        next = insertSyntheticIdentifier(
            token, IdentifierContext.fieldInitializer,
            message: fasta.messageMissingAssignmentInInitializer,
            messageOnToken: next);
        rewriter.insertTokenAfter(
            next, new SyntheticToken(TokenType.EQ, next.offset));
      }
      token = parseExpression(token);
    } else {
      // Recovery
      insertSyntheticIdentifier(token, IdentifierContext.fieldInitializer,
          message: fasta.messageExpectedAnInitializer, messageOnToken: token);
      token = parseExpression(token);
    }
    listener.endInitializer(token.next);
    return token;
  }

  /// If the next token is an opening curly brace, return it. Otherwise, use the
  /// given [template] to report an error, insert an opening and a closing curly
  /// brace, and return the newly inserted opening curly brace. If the
  /// [template] is `null`, use a default error message instead.
  Token ensureBlock(
      Token token, Template<Message Function(Token token)> template) {
    Token next = token.next;
    if (optional('{', next)) return next;
    Message message = template == null
        ? fasta.templateExpectedButGot.withArguments('{')
        : template.withArguments(token);
    reportRecoverableError(next, message);
    Token replacement = link(
        new SyntheticBeginToken(TokenType.OPEN_CURLY_BRACKET, next.offset),
        new SyntheticToken(TokenType.CLOSE_CURLY_BRACKET, next.offset));
    rewriter.insertTokenAfter(token, replacement);
    return replacement;
  }

  /// If the next token is a closing parenthesis, return it.
  /// Otherwise, report an error and return the closing parenthesis
  /// associated with the specified open parenthesis.
  Token ensureCloseParen(Token token, Token openParen) {
    Token next = token.next;
    if (optional(')', next)) {
      return next;
    }

    // TODO(danrubel): Pass in context for better error message.
    reportRecoverableError(
        next, fasta.templateExpectedButGot.withArguments(')'));

    // Scanner guarantees a closing parenthesis
    // TODO(danrubel): Improve recovery by having callers parse tokens
    // between `token` and `openParen.endGroup`.
    return openParen.endGroup;
  }

  /// If the next token is a colon, return it. Otherwise, report an
  /// error, insert a synthetic colon, and return the inserted colon.
  Token ensureColon(Token token) {
    Token next = token.next;
    if (optional(':', next)) return next;
    Message message = fasta.templateExpectedButGot.withArguments(':');
    Token newToken = new SyntheticToken(TokenType.COLON, next.charOffset);
    return rewriteAndRecover(token, message, newToken).next;
  }

  /// If the token after [token] is a '>', return it.
  /// If the next token is a composite greater-than token such as '>>',
  /// then replace that token with separate tokens, and return the first '>'.
  /// Otherwise, report an error, insert a synthetic '>',
  /// and return that newly inserted synthetic '>'.
  Token ensureGt(Token token) {
    Token next = token.next;
    String value = next.stringValue;
    if (value == '>') {
      return next;
    }
    rewriteGtCompositeOrRecover(token, next, value);
    return token.next;
  }

  /// If the token after [token] is a not literal string,
  /// then insert a synthetic literal string.
  /// Call `parseLiteralString` and return the result.
  Token ensureLiteralString(Token token) {
    Token next = token.next;
    if (!identical(next.kind, STRING_TOKEN)) {
      Message message = fasta.templateExpectedString.withArguments(next);
      Token newToken =
          new SyntheticStringToken(TokenType.STRING, '""', token.charOffset, 0);
      rewriteAndRecover(token, message, newToken);
    }
    return parseLiteralString(token);
  }

  /// If the token after [token] is a semi-colon, return it.
  /// Otherwise, report an error, insert a synthetic semi-colon,
  /// and return the inserted semi-colon.
  Token ensureSemicolon(Token token) {
    // TODO(danrubel): Once all expect(';'...) call sites have been converted
    // to use this method, remove similar semicolon recovery code
    // from the handleError method in element_listener.dart.
    Token next = token.next;
    if (optional(';', next)) return next;
    Message message = fasta.templateExpectedButGot.withArguments(';');
    Token newToken = new SyntheticToken(TokenType.SEMICOLON, next.charOffset);
    return rewriteAndRecover(token, message, newToken).next;
  }

  /// Report an error at the token after [token] that has the given [message].
  /// Insert the [newToken] after [token] and return [token].
  Token rewriteAndRecover(Token token, Message message, Token newToken) {
    reportRecoverableError(token.next, message);
    rewriter.insertTokenAfter(token, newToken);
    return token;
  }

  /// Replace the token after [token] with `[` followed by `]`
  /// and return [token].
  Token rewriteSquareBrackets(Token token) {
    Token next = token.next;
    assert(optional('[]', next));
    Token replacement = link(
        new BeginToken(TokenType.OPEN_SQUARE_BRACKET, next.offset),
        new Token(TokenType.CLOSE_SQUARE_BRACKET, next.offset + 1));
    rewriter.replaceTokenFollowing(token, replacement);
    return token;
  }

  void rewriteGtCompositeOrRecover(Token token, Token next, String value) {
    assert(value != '>');
    Token replacement = new Token(TokenType.GT, next.charOffset);
    if (identical(value, '>>')) {
      replacement.next = new Token(TokenType.GT, next.charOffset + 1);
    } else if (identical(value, '>=')) {
      replacement.next = new Token(TokenType.EQ, next.charOffset + 1);
    } else if (identical(value, '>>=')) {
      replacement.next = new Token(TokenType.GT, next.charOffset + 1);
      replacement.next.next = new Token(TokenType.EQ, next.charOffset + 2);
    } else {
      // Recovery
      rewriteAndRecover(token, fasta.templateExpectedToken.withArguments('>'),
          new SyntheticToken(TokenType.GT, next.offset));
      return;
    }
    rewriter.replaceTokenFollowing(token, replacement);
  }

  void rewriteLtEndGroupOpt(BeginToken beginToken) {
    assert(optional('<', beginToken));
    Token end = beginToken.endGroup;
    String value = end?.stringValue;
    if (value != null && value.length > 1) {
      Token beforeEnd = previousToken(beginToken, end);
      rewriteGtCompositeOrRecover(beforeEnd, end, value);
      beginToken.endGroup = null;
    }
  }

  /// Report the given token as unexpected and return the next token if the next
  /// token is one of the [expectedNext], otherwise just return the given token.
  Token skipUnexpectedTokenOpt(Token token, List<String> expectedNext) {
    Token next = token.next;
    if (next.keyword == null) {
      final String nextValue = next.next.stringValue;
      for (String expectedValue in expectedNext) {
        if (identical(nextValue, expectedValue)) {
          reportRecoverableErrorWithToken(next, fasta.templateUnexpectedToken);
          return next;
        }
      }
    }
    return token;
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
    token = token.next;
    assert(token.isModifier);
    listener.handleModifier(token);
    return token;
  }

  Token parseNativeClause(Token token) {
    Token nativeToken = token = token.next;
    assert(optional('native', nativeToken));
    bool hasName = false;
    if (token.next.kind == STRING_TOKEN) {
      hasName = true;
      token = parseLiteralString(token);
    }
    listener.handleNativeClause(nativeToken, hasName);
    reportRecoverableError(
        nativeToken, fasta.messageNativeClauseShouldBeAnnotation);
    return token;
  }

  Token skipClassBody(Token token) {
    Token previousToken = token;
    token = token.next;
    if (!optional('{', token)) {
      token = ensureBlock(previousToken, fasta.templateExpectedClassBody);
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
  Token parseClassBody(Token token) {
    Token begin = token = token.next;
    assert(optional('{', token));
    listener.beginClassBody(token);
    int count = 0;
    while (notEofOrValue('}', token.next)) {
      token = parseClassMemberImpl(token);
      ++count;
    }
    token = token.next;
    assert(optional('}', token));
    listener.endClassBody(count, begin, token);
    return token;
  }

  bool isGetOrSet(Token token) {
    final String value = token.stringValue;
    return (identical(value, 'get')) || (identical(value, 'set'));
  }

  bool isModifierOrFactory(Token next) =>
      optional('factory', next) || isModifier(next);

  /// Parse a class member.
  ///
  /// This method is only invoked from outside the parser. As a result, this
  /// method takes the next token to be consumed rather than the last consumed
  /// token and returns the token after the last consumed token rather than the
  /// last consumed token.
  Token parseClassMember(Token token) {
    return parseClassMemberImpl(syntheticPreviousToken(token)).next;
  }

  /// ```
  /// classMember:
  ///   fieldDeclaration |
  ///   constructorDeclaration |
  ///   methodDeclaration
  /// ;
  /// ```
  Token parseClassMemberImpl(Token token) {
    Token beforeStart = token = parseMetadataStar(token);

    TypeContinuation typeContinuation;
    Token covariantToken;
    Token externalToken;
    Token staticToken;
    Token varFinalOrConst;

    Token next = token.next;
    if (isModifier(next)) {
      if (optional('external', next)) {
        externalToken = token = next;
        next = token.next;
      }
      if (isModifier(next)) {
        if (optional('static', next)) {
          staticToken = token = next;
          next = token.next;
        } else if (optional('covariant', next)) {
          covariantToken = token = next;
          next = token.next;
        }
        if (isModifier(next)) {
          if (optional('final', next)) {
            typeContinuation = TypeContinuation.Optional;
            varFinalOrConst = token = next;
            next = token.next;
          } else if (optional('var', next)) {
            typeContinuation = TypeContinuation.OptionalAfterVar;
            varFinalOrConst = token = next;
            next = token.next;
          } else if (optional('const', next) && covariantToken == null) {
            typeContinuation = TypeContinuation.Optional;
            varFinalOrConst = token = next;
            next = token.next;
          }
          if (isModifier(next)) {
            ModifierRecoveryContext2 context =
                new ModifierRecoveryContext2(this);
            token = context.parseClassMemberModifiers(token, typeContinuation,
                externalToken: externalToken,
                staticToken: staticToken,
                covariantToken: covariantToken,
                varFinalOrConst: varFinalOrConst);
            next = token.next;

            covariantToken = context.covariantToken;
            externalToken = context.externalToken;
            staticToken = context.staticToken;
            varFinalOrConst = context.varFinalOrConst;

            typeContinuation = context.typeContinuation;
            context = null;
          }
        }
      }
    }
    typeContinuation ??= TypeContinuation.Required;

    listener.beginMember();

    Token beforeType = token;
    // TODO(danrubel): Consider changing the listener contract
    // so that the type reference can be parsed immediately
    // rather than skipped now and parsed later.
    token = skipTypeReferenceOpt(token);
    if (token == beforeType) {
      // There is no type reference.
      beforeType = null;
    }
    next = token.next;

    Token getOrSet;
    if (next.type != TokenType.IDENTIFIER) {
      String value = next.stringValue;
      if (identical(value, 'get') || identical(value, 'set')) {
        if (next.next.isIdentifier) {
          getOrSet = token = next;
          next = token.next;
          if (!next.isIdentifier) {
            // Recovery
            insertSyntheticIdentifier(
                token, IdentifierContext.methodDeclaration);
            next = token.next;
          }
        }
        // Fall through to continue parsing `get` or `set` as an identifier.
      } else if (identical(value, 'factory')) {
        if (next.next.isIdentifier) {
          token = parseFactoryMethod(token, beforeStart, externalToken,
              staticToken ?? covariantToken, varFinalOrConst);
          listener.endMember();
          return token;
        }
        // Fall through to continue parsing `factory` as an identifier.
      } else if (identical(value, 'operator')) {
        Token next2 = next.next;
        // `operator` can be used as an identifier as in
        // `int operator<T>()` or `int operator = 2`
        if (next2.isUserDefinableOperator && next2.endGroup == null) {
          token = parseMethod(beforeStart, externalToken, staticToken,
              covariantToken, varFinalOrConst, beforeType, getOrSet, token);
          listener.endMember();
          return token;
        } else if (optional('===', next2) ||
            (next2.isOperator &&
                !optional('=', next2) &&
                !optional('<', next2))) {
          // Recovery
          token = next2;
          insertSyntheticIdentifier(token, IdentifierContext.methodDeclaration,
              message: fasta.templateInvalidOperator.withArguments(token),
              messageOnToken: token);
          next = token.next;
        }
        // Fall through to continue parsing `operator` as an identifier.
      } else if (!next.isIdentifier ||
          (identical(value, 'typedef') &&
              token == beforeStart &&
              next.next.isIdentifier)) {
        // Recovery
        return recoverFromInvalidClassMember(
            token,
            beforeStart,
            externalToken,
            staticToken,
            covariantToken,
            varFinalOrConst,
            beforeType,
            getOrSet,
            typeContinuation);
      }
    }
    // At this point, token is before the name, and next is the name

    next = next.next;
    String value = next.stringValue;
    if (getOrSet != null ||
        identical(value, '(') ||
        identical(value, '{') ||
        identical(value, '<') ||
        identical(value, '.') ||
        identical(value, '=>')) {
      token = parseMethod(beforeStart, externalToken, staticToken,
          covariantToken, varFinalOrConst, beforeType, getOrSet, token);
    } else {
      if (getOrSet != null) {
        reportRecoverableErrorWithToken(
            getOrSet, fasta.templateExtraneousModifier);
      }
      token = parseFields(
          beforeStart,
          externalToken,
          staticToken,
          covariantToken,
          varFinalOrConst,
          beforeType,
          token,
          staticToken != null
              ? MemberKind.StaticField
              : MemberKind.NonStaticField,
          typeContinuation);
    }
    listener.endMember();
    return token;
  }

  Token parseMethod(
      Token beforeStart,
      Token externalToken,
      Token staticToken,
      Token covariantToken,
      Token varFinalOrConst,
      Token beforeType,
      Token getOrSet,
      Token beforeName) {
    bool isOperator = getOrSet == null && optional('operator', beforeName.next);

    int modifierCount = 0;
    if (externalToken != null) {
      listener.handleModifier(externalToken);
      ++modifierCount;
    }
    if (staticToken != null) {
      if (!isOperator) {
        listener.handleModifier(staticToken);
        ++modifierCount;
      } else {
        reportRecoverableError(staticToken, fasta.messageStaticOperator);
        staticToken = null;
      }
    } else if (covariantToken != null) {
      if (getOrSet != null && !optional('get', getOrSet)) {
        listener.handleModifier(covariantToken);
        ++modifierCount;
      } else {
        reportRecoverableError(covariantToken, fasta.messageCovariantMember);
        covariantToken = null;
      }
    }
    if (varFinalOrConst != null) {
      if (optional('const', varFinalOrConst)) {
        if (getOrSet == null) {
          listener.handleModifier(varFinalOrConst);
          ++modifierCount;
        } else {
          reportRecoverableErrorWithToken(
              varFinalOrConst, fasta.templateExtraneousModifier);
          varFinalOrConst = null;
        }
      } else if (optional('var', varFinalOrConst)) {
        reportRecoverableError(varFinalOrConst, fasta.messageVarReturnType);
      } else {
        assert(optional('final', varFinalOrConst));
        reportRecoverableErrorWithToken(
            varFinalOrConst, fasta.templateExtraneousModifier);
      }
    }
    // TODO(danrubel): Move beginMethod event before handleModifier events
    listener.beginMethod();
    listener.handleModifiers(modifierCount);

    if (beforeType == null) {
      listener.handleNoType(beforeName);
    } else {
      parseType(beforeType, TypeContinuation.Optional);
    }

    Token token;
    if (isOperator) {
      token = parseOperatorName(beforeName);
    } else {
      token = ensureIdentifier(beforeName, IdentifierContext.methodDeclaration);
      token = parseQualifiedRestOpt(
          token, IdentifierContext.methodDeclarationContinuation);
    }

    bool isGetter = false;
    if (getOrSet == null) {
      token = parseTypeVariablesOpt(token);
    } else {
      isGetter = optional("get", getOrSet);
      listener.handleNoTypeVariables(token.next);
    }

    MemberKind kind = staticToken != null
        ? MemberKind.StaticMethod
        : MemberKind.NonStaticMethod;
    checkFormals(beforeName.next, isGetter, token.next, kind);
    Token beforeParam = token;
    token = parseFormalParametersOpt(token, kind);
    token = parseInitializersOpt(token);

    AsyncModifier savedAsyncModifier = asyncState;
    Token asyncToken = token.next;
    token = parseAsyncModifierOpt(token);
    if (getOrSet != null && !inPlainSync && optional("set", getOrSet)) {
      reportRecoverableError(asyncToken, fasta.messageSetterNotSync);
    }
    Token next = token.next;
    if (externalToken != null) {
      if (!optional(';', next)) {
        reportRecoverableError(next, fasta.messageExternalMethodWithBody);
      }
    }
    if (optional('=', next)) {
      reportRecoverableError(next, fasta.messageRedirectionInNonFactory);
      token = parseRedirectingFactoryBody(token);
    } else {
      token = parseFunctionBody(
          token, false, staticToken == null || externalToken != null);
    }
    asyncState = savedAsyncModifier;
    listener.endMethod(getOrSet, beforeStart.next, beforeParam.next, token);
    return token;
  }

  Token parseFactoryMethod(Token token, Token beforeStart, Token externalToken,
      Token staticOrCovariant, Token varFinalOrConst) {
    Token factoryKeyword = token = token.next;
    assert(optional('factory', factoryKeyword));

    if (!isValidTypeReference(token.next)) {
      // Recovery
      ModifierRecoveryContext2 context = new ModifierRecoveryContext2(this);
      token = context.parseModifiersAfterFactory(token,
          externalToken: externalToken,
          staticOrCovariant: staticOrCovariant,
          varFinalOrConst: varFinalOrConst);

      externalToken = context.externalToken;
      staticOrCovariant = context.staticToken ?? context.covariantToken;
      varFinalOrConst = context.varFinalOrConst;
    }

    int modifierCount = 0;
    if (externalToken != null) {
      listener.handleModifier(externalToken);
      ++modifierCount;
    }
    if (staticOrCovariant != null) {
      reportRecoverableErrorWithToken(
          staticOrCovariant, fasta.templateExtraneousModifier);
    }
    if (varFinalOrConst != null) {
      if (optional('const', varFinalOrConst)) {
        listener.handleModifier(varFinalOrConst);
        ++modifierCount;
      } else {
        reportRecoverableErrorWithToken(
            varFinalOrConst, fasta.templateExtraneousModifier);
        varFinalOrConst = null;
      }
    }
    listener.handleModifiers(modifierCount);

    listener.beginFactoryMethod(beforeStart);
    token = parseConstructorReference(token);
    token = parseFormalParametersRequiredOpt(token, MemberKind.Factory);
    Token asyncToken = token.next;
    token = parseAsyncModifierOpt(token);
    Token next = token.next;
    if (!inPlainSync) {
      reportRecoverableError(asyncToken, fasta.messageFactoryNotSync);
    }
    if (optional('=', next)) {
      if (externalToken != null) {
        reportRecoverableError(next, fasta.messageExternalFactoryRedirection);
      }
      token = parseRedirectingFactoryBody(token);
    } else if (externalToken != null) {
      if (!optional(';', next)) {
        reportRecoverableError(next, fasta.messageExternalFactoryWithBody);
      }
      token = parseFunctionBody(token, false, true);
    } else {
      if (varFinalOrConst != null && !optional('native', next)) {
        // TODO(danrubel): report error to fix
        // test_constFactory in parser_fasta_test.dart
        //reportRecoverableError(constToken, fasta.messageConstFactory);
      }
      token = parseFunctionBody(token, false, false);
    }
    listener.endFactoryMethod(beforeStart.next, factoryKeyword, token);
    return token;
  }

  Token parseOperatorName(Token token) {
    Token beforeToken = token;
    token = token.next;
    assert(optional('operator', token));
    Token next = token.next;
    if (next.isUserDefinableOperator) {
      if (next.endGroup != null) {
        // `operator` is being used as an identifier.
        // For example: `int operator<T>(foo) => 0;`
        listener.handleIdentifier(token, IdentifierContext.methodDeclaration);
        return token;
      } else {
        listener.handleOperatorName(token, next);
        return next;
      }
    } else if (optional('(', next)) {
      return ensureIdentifier(beforeToken, IdentifierContext.operatorName);
    } else {
      // Recovery
      // The user has specified an invalid operator name.
      // Report the error, accept the invalid operator name, and move on.
      reportRecoverableErrorWithToken(next, fasta.templateInvalidOperator);
      listener.handleInvalidOperatorName(token, next);
      return next;
    }
  }

  Token parseFunctionExpression(Token token) {
    Token beginToken = token.next;
    listener.beginFunctionExpression(beginToken);
    token = parseFormalParametersRequiredOpt(token, MemberKind.Local);
    token = parseAsyncOptBody(token, true, false);
    listener.endFunctionExpression(beginToken, token.next);
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
      Token beforeName, Token begin, Token formals, bool isFunctionExpression) {
    Token token = beforeName.next;
    listener.beginFunctionName(token);
    token =
        ensureIdentifier(beforeName, IdentifierContext.localFunctionDeclaration)
            .next;
    if (isFunctionExpression) {
      reportRecoverableError(
          beforeName.next, fasta.messageNamedFunctionExpression);
    }
    listener.endFunctionName(begin, token);
    token = parseFormalParametersOpt(formals, MemberKind.Local);
    token = parseInitializersOpt(token);
    token = parseAsyncOptBody(token, isFunctionExpression, false);
    if (isFunctionExpression) {
      listener.endNamedFunctionExpression(token);
    } else {
      listener.endLocalFunctionDeclaration(token);
    }
    return token;
  }

  /// Parses a function body optionally preceded by an async modifier (see
  /// [parseAsyncModifierOpt]).  This method is used in both expression context
  /// (when [ofFunctionExpression] is true) and statement context. In statement
  /// context (when [ofFunctionExpression] is false), and if the function body
  /// is on the form `=> expression`, a trailing semicolon is required.
  ///
  /// It's an error if there's no function body unless [allowAbstract] is true.
  Token parseAsyncOptBody(
      Token token, bool ofFunctionExpression, bool allowAbstract) {
    AsyncModifier savedAsyncModifier = asyncState;
    token = parseAsyncModifierOpt(token);
    token = parseFunctionBody(token, ofFunctionExpression, allowAbstract);
    asyncState = savedAsyncModifier;
    return token;
  }

  Token parseConstructorReference(Token token) {
    Token start =
        ensureIdentifier(token, IdentifierContext.constructorReference);
    listener.beginConstructorReference(start);
    token = parseQualifiedRestOpt(
        start, IdentifierContext.constructorReferenceContinuation);
    token = parseTypeArgumentsOpt(token);
    Token period = null;
    if (optional('.', token.next)) {
      period = token.next;
      token = ensureIdentifier(period,
          IdentifierContext.constructorReferenceContinuationAfterTypeArguments);
    } else {
      listener.handleNoConstructorReferenceContinuationAfterTypeArguments(
          token.next);
    }
    listener.endConstructorReference(start, period, token.next);
    return token;
  }

  Token parseRedirectingFactoryBody(Token token) {
    token = token.next;
    assert(optional('=', token));
    listener.beginRedirectingFactoryBody(token);
    Token equals = token;
    token = parseConstructorReference(token);
    token = ensureSemicolon(token);
    listener.endRedirectingFactoryBody(equals, token);
    return token;
  }

  Token skipFunctionBody(Token token, bool isExpression, bool allowAbstract) {
    assert(!isExpression);
    token = skipAsyncModifier(token);
    Token next = token.next;
    if (optional('native', next)) {
      Token nativeToken = next;
      // TODO(danrubel): skip the native clause rather than parsing it
      // or remove this code completely when we remove support
      // for the `native` clause.
      token = parseNativeClause(token);
      next = token.next;
      if (optional(';', next)) {
        listener.handleNativeFunctionBodySkipped(nativeToken, next);
        return token.next;
      }
      listener.handleNativeFunctionBodyIgnored(nativeToken, next);
      // Fall through to recover and skip function body
    }
    String value = next.stringValue;
    if (identical(value, ';')) {
      token = next;
      if (!allowAbstract) {
        reportRecoverableError(token, fasta.messageExpectedBody);
      }
      listener.handleNoFunctionBody(token);
    } else if (identical(value, '=>')) {
      token = parseExpression(next);
      // There ought to be a semicolon following the expression, but we check
      // before advancing in order to be consistent with the way the method
      // [parseFunctionBody] recovers when the semicolon is missing.
      if (optional(';', token.next)) {
        token = token.next;
      }
      listener.handleFunctionBodySkipped(token, true);
    } else if (identical(value, '=')) {
      token = next;
      reportRecoverableError(token, fasta.messageExpectedBody);
      token = parseExpression(token);
      // There ought to be a semicolon following the expression, but we check
      // before advancing in order to be consistent with the way the method
      // [parseFunctionBody] recovers when the semicolon is missing.
      if (optional(';', token.next)) {
        token = token.next;
      }
      listener.handleFunctionBodySkipped(token, true);
    } else {
      token = skipBlock(token);
      listener.handleFunctionBodySkipped(token, false);
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
    Token next = token.next;
    if (optional('native', next)) {
      Token nativeToken = next;
      token = parseNativeClause(token);
      next = token.next;
      if (optional(';', next)) {
        listener.handleNativeFunctionBody(nativeToken, next);
        return next;
      }
      reportRecoverableError(next, fasta.messageExternalMethodWithBody);
      listener.handleNativeFunctionBodyIgnored(nativeToken, next);
      // Ignore the native keyword and fall through to parse the body
    }
    if (optional(';', next)) {
      if (!allowAbstract) {
        reportRecoverableError(next, fasta.messageExpectedBody);
      }
      listener.handleEmptyFunctionBody(next);
      return next;
    } else if (optional('=>', next)) {
      return parseExpressionFunctionBody(next, ofFunctionExpression);
    } else if (optional('=', next)) {
      Token begin = next;
      // Recover from a bad factory method.
      reportRecoverableError(next, fasta.messageExpectedBody);
      token = parseExpression(next);
      if (!ofFunctionExpression) {
        token = ensureSemicolon(token);
        listener.handleExpressionFunctionBody(begin, token);
      } else {
        listener.handleExpressionFunctionBody(begin, null);
      }
      return token;
    }
    Token begin = next;
    int statementCount = 0;
    if (!optional('{', next)) {
      // Recovery
      // If there is a stray simple identifier in the function expression
      // because the user is typing (e.g. `() asy => null;`)
      // then report an error, skip the token, and continue parsing.
      if (next.isKeywordOrIdentifier && optional('=>', next.next)) {
        reportRecoverableErrorWithToken(next, fasta.templateUnexpectedToken);
        return parseExpressionFunctionBody(next.next, ofFunctionExpression);
      }
      if (next.isKeywordOrIdentifier && optional('{', next.next)) {
        reportRecoverableErrorWithToken(next, fasta.templateUnexpectedToken);
        token = next;
        begin = next = token.next;
        // Fall through to parse the block.
      } else {
        token = ensureBlock(token, fasta.templateExpectedFunctionBody);
        listener.handleInvalidFunctionBody(token);
        return token.endGroup;
      }
    }

    LoopState savedLoopState = loopState;
    loopState = LoopState.OutsideLoop;
    listener.beginBlockFunctionBody(begin);
    token = next;
    while (notEofOrValue('}', token.next)) {
      Token startToken = token.next;
      token = parseStatement(token);
      if (identical(token.next, startToken)) {
        // No progress was made, so we report the current token as being invalid
        // and move forward.
        reportRecoverableError(
            token, fasta.templateUnexpectedToken.withArguments(token));
        token = token.next;
      }
      ++statementCount;
    }
    token = token.next;
    listener.endBlockFunctionBody(statementCount, begin, token);
    expect('}', token);
    loopState = savedLoopState;
    return token;
  }

  Token parseExpressionFunctionBody(Token token, bool ofFunctionExpression) {
    assert(optional('=>', token));
    Token begin = token;
    token = parseExpression(token);
    if (!ofFunctionExpression) {
      token = ensureSemicolon(token);
      listener.handleExpressionFunctionBody(begin, token);
    } else {
      listener.handleExpressionFunctionBody(begin, null);
    }
    if (inGenerator) {
      listener.handleInvalidStatement(
          begin, fasta.messageGeneratorReturnsValue);
    }
    return token;
  }

  Token skipAsyncModifier(Token token) {
    String value = token.next.stringValue;
    if (identical(value, 'async')) {
      token = token.next;
      value = token.next.stringValue;

      if (identical(value, '*')) {
        token = token.next;
      }
    } else if (identical(value, 'sync')) {
      token = token.next;
      value = token.next.stringValue;

      if (identical(value, '*')) {
        token = token.next;
      }
    }
    return token;
  }

  Token parseAsyncModifierOpt(Token token) {
    Token async;
    Token star;
    asyncState = AsyncModifier.Sync;
    Token next = token.next;
    if (optional('async', next)) {
      async = token = next;
      next = token.next;
      if (optional('*', next)) {
        asyncState = AsyncModifier.AsyncStar;
        star = next;
        token = next;
      } else {
        asyncState = AsyncModifier.Async;
      }
    } else if (optional('sync', next)) {
      async = token = next;
      next = token.next;
      if (optional('*', next)) {
        asyncState = AsyncModifier.SyncStar;
        star = next;
        token = next;
      } else {
        reportRecoverableError(async, fasta.messageInvalidSyncModifier);
      }
    }
    listener.handleAsyncModifier(async, star);
    if (!inPlainSync && optional(';', token.next)) {
      reportRecoverableError(token.next, fasta.messageAbstractNotSync);
    }
    return token;
  }

  int statementDepth = 0;
  Token parseStatement(Token token) {
    if (statementDepth++ > 500) {
      // This happens for degenerate programs, for example, a lot of nested
      // if-statements. The language test deep_nesting2_negative_test, for
      // example, provokes this.
      return recoverFromStackOverflow(token.next);
    }
    Token result = parseStatementX(token);
    statementDepth--;
    return result;
  }

  Token parseStatementX(Token token) {
    final value = token.next.stringValue;
    if (identical(token.next.kind, IDENTIFIER_TOKEN)) {
      return parseExpressionStatementOrDeclaration(token);
    } else if (identical(value, '{')) {
      return parseBlock(token);
    } else if (identical(value, 'return')) {
      return parseReturnStatement(token);
    } else if (identical(value, 'var') || identical(value, 'final')) {
      return parseVariablesDeclaration(token);
    } else if (identical(value, 'if')) {
      return parseIfStatement(token);
    } else if (identical(value, 'await') && optional('for', token.next.next)) {
      return parseForStatement(token.next, token.next);
    } else if (identical(value, 'for')) {
      return parseForStatement(null, token);
    } else if (identical(value, 'rethrow')) {
      return parseRethrowStatement(token);
    } else if (identical(value, 'throw') && optional(';', token.next.next)) {
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
          reportRecoverableError(token.next, fasta.messageYieldNotGenerator);
          return parseYieldStatement(token);
      }
      throw "Internal error: Unknown asyncState: '$asyncState'.";
    } else if (identical(value, 'const')) {
      return parseExpressionStatementOrConstDeclaration(token);
    } else if (isModifier(token.next)) {
      return parseVariablesDeclaration(token);
    } else if (token.next.isIdentifier) {
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
    Token begin = token = token.next;
    assert(optional('yield', token));
    listener.beginYieldStatement(begin);
    Token starToken;
    if (optional('*', token.next)) {
      starToken = token = token.next;
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
    Token begin = token = token.next;
    assert(optional('return', token));
    listener.beginReturnStatement(begin);
    Token next = token.next;
    if (optional(';', next)) {
      listener.endReturnStatement(false, begin, next);
      return next;
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
    return parseType(token, TypeContinuation.ExpressionStatementOrDeclaration);
  }

  Token parseExpressionStatementOrConstDeclaration(Token token) {
    Token next = token.next;
    assert(optional('const', next));
    if (next.next.isModifier) {
      return parseVariablesDeclaration(token);
    } else {
      return parseType(
          token, TypeContinuation.ExpressionStatementOrConstDeclaration);
    }
  }

  /// ```
  /// label:
  ///   identifier ':'
  /// ;
  /// ```
  Token parseLabel(Token token) {
    // TODO(brianwilkerson): Enable this assert.
    // `parseType` is allowing `void` to be a label.
//    assert(token.next.isIdentifier);
    assert(optional(':', token.next.next));
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
    Token next = token.next;
    // TODO(brianwilkerson): Enable this assert.
    // `parseType` is allowing `void` to be a label.
//    assert(next.isIdentifier);
    assert(optional(':', next.next));
    int labelCount = 0;
    do {
      token = parseLabel(token);
      next = token.next;
      labelCount++;
    } while (next.isIdentifier && optional(':', next.next));
    listener.beginLabeledStatement(next, labelCount);
    token = parseStatement(token);
    listener.endLabeledStatement(labelCount);
    return token;
  }

  /// ```
  /// expressionStatement:
  ///   expression? ';'
  /// ;
  /// ```
  ///
  /// Note: This method can fail to make progress. If there is neither an
  /// expression nor a semi-colon, then a synthetic identifier and synthetic
  /// semicolon will be inserted before [token] and the semicolon will be
  /// returned.
  Token parseExpressionStatement(Token token) {
    // TODO(brianwilkerson): If the next token is not the start of a valid
    // expression, then this method shouldn't report that we have an expression
    // statement.
    listener.beginExpressionStatement(token.next);
    token = parseExpression(token);
    token = ensureSemicolon(token);
    listener.endExpressionStatement(token);
    return token;
  }

  Token skipExpression(Token token) {
    while (true) {
      Token next = token.next;
      final kind = next.kind;
      final value = next.stringValue;
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
        var nextValue = next.next.stringValue;
        if (identical(nextValue, 'const')) {
          token = next;
          next = token.next;
          nextValue = next.next.stringValue;
        }
        if (identical(nextValue, '{')) {
          // Handle cases like this:
          // class Foo {
          //   var map;
          //   Foo() : map = {};
          //   Foo.x() : map = true ? {} : {};
          // }
          token = closeBraceTokenFor(next.next) ?? next;
          next = token.next;
          continue;
        }
        if (identical(nextValue, '<')) {
          // Handle cases like this:
          // class Foo {
          //   var map;
          //   Foo() : map = <String, Foo>{};
          //   Foo.x() : map = true ? <String, Foo>{} : <String, Foo>{};
          // }
          token = closeBraceTokenFor(next.next) ?? next;
          next = token.next;
          if (identical(next.stringValue, '{')) {
            token = closeBraceTokenFor(next) ?? next;
            next = token.next;
          }
          continue;
        }
      }
      if (!mayParseFunctionExpressions && identical(value, '{')) {
        break;
      }
      if (next is BeginToken) {
        token = closeBraceTokenFor(next) ?? next;
      } else {
        if (next is ErrorToken) {
          reportErrorToken(next, false);
        }
        token = next;
      }
    }
    return token;
  }

  int expressionDepth = 0;
  Token parseExpression(Token token) {
    if (expressionDepth++ > 500) {
      // This happens in degenerate programs, for example, with a lot of nested
      // list literals. This is provoked by, for example, the language test
      // deep_nesting1_negative_test.
      return reportUnmatchedToken(token.next);
    }
    Token result = optional('throw', token.next)
        ? parseThrowExpression(token, true)
        : parsePrecedenceExpression(token, ASSIGNMENT_PRECEDENCE, true);
    expressionDepth--;
    return result;
  }

  Token parseExpressionWithoutCascade(Token token) {
    Token result = optional('throw', token.next)
        ? parseThrowExpression(token, false)
        : parsePrecedenceExpression(token, ASSIGNMENT_PRECEDENCE, false);
    return result;
  }

  Token parseConditionalExpressionRest(Token token) {
    Token question = token = token.next;
    assert(optional('?', question));
    listener.beginConditionalExpression(token);
    token = parseExpressionWithoutCascade(token);
    Token colon = ensureColon(token);
    listener.handleConditionalExpressionColon();
    token = parseExpressionWithoutCascade(colon);
    listener.endConditionalExpression(question, colon);
    return token;
  }

  Token parsePrecedenceExpression(
      Token token, int precedence, bool allowCascades) {
    assert(precedence >= 1);
    assert(precedence <= POSTFIX_PRECEDENCE);
    token = parseUnaryExpression(token, allowCascades);
    Token next = token.next;
    TokenType type = next.type;
    int tokenLevel = type.precedence;
    Token typeArguments;
    if (isValidMethodTypeArguments(next)) {
      // For example a(b)<T>(c), where token is '<'.
      typeArguments = next;
      token = parseTypeArgumentsOpt(token);
      next = token.next;
      assert(optional('(', next));
      type = next.type;
      tokenLevel = type.precedence;
    }
    for (int level = tokenLevel; level >= precedence; --level) {
      int lastBinaryExpressionLevel = -1;
      while (identical(tokenLevel, level)) {
        Token operator = next;
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
            token = parseArgumentOrIndexStar(token, typeArguments);
            next = token.next;
          } else if ((identical(type, TokenType.PLUS_PLUS)) ||
              (identical(type, TokenType.MINUS_MINUS))) {
            listener.handleUnaryPostfixAssignmentExpression(token.next);
            token = next;
          } else if (identical(type, TokenType.INDEX)) {
            BeginToken replacement = link(
                new BeginToken(TokenType.OPEN_SQUARE_BRACKET, next.charOffset,
                    next.precedingComments),
                new Token(TokenType.CLOSE_SQUARE_BRACKET, next.charOffset + 1));
            rewriter.replaceTokenFollowing(token, replacement);
            replacement.endToken = replacement.next;
            token = parseArgumentOrIndexStar(token, null);
          } else {
            token = reportUnexpectedToken(token.next);
          }
        } else if (identical(type, TokenType.IS)) {
          token = parseIsOperatorRest(token);
        } else if (identical(type, TokenType.AS)) {
          token = parseAsOperatorRest(token);
        } else if (identical(type, TokenType.QUESTION)) {
          token = parseConditionalExpressionRest(token);
        } else {
          if (level == EQUALITY_PRECEDENCE || level == RELATIONAL_PRECEDENCE) {
            // We don't allow (a == b == c) or (a < b < c).
            if (lastBinaryExpressionLevel == level) {
              // Report an error, then continue parsing as if it is legal.
              reportRecoverableError(
                  next, fasta.messageEqualityCannotBeEqualityOperand);
            } else {
              // Set a flag to catch subsequent binary expressions of this type.
              lastBinaryExpressionLevel = level;
            }
          }
          listener.beginBinaryExpression(next);
          // Left associative, so we recurse at the next higher
          // precedence level.
          token =
              parsePrecedenceExpression(token.next, level + 1, allowCascades);
          listener.endBinaryExpression(operator);
        }
        next = token.next;
        type = next.type;
        tokenLevel = type.precedence;
      }
    }
    return token;
  }

  Token parseCascadeExpression(Token token) {
    Token cascadeOperator = token = token.next;
    assert(optional('..', cascadeOperator));
    listener.beginCascade(cascadeOperator);
    if (optional('[', token.next)) {
      token = parseArgumentOrIndexStar(token, null);
    } else {
      token = parseSend(token, IdentifierContext.expressionContinuation);
      listener.endBinaryExpression(cascadeOperator);
    }
    Token next = token.next;
    Token mark;
    do {
      mark = token;
      if (optional('.', next)) {
        Token period = next;
        token = parseSend(next, IdentifierContext.expressionContinuation);
        next = token.next;
        listener.endBinaryExpression(period);
      }
      Token typeArguments;
      if (isValidMethodTypeArguments(next)) {
        // For example a(b)..<T>(c), where token is '<'.
        typeArguments = next;
        token = parseTypeArgumentsOpt(token);
        next = token.next;
        assert(optional('(', next));
      }
      token = parseArgumentOrIndexStar(token, typeArguments);
      next = token.next;
    } while (!identical(mark, token));

    if (identical(next.type.precedence, ASSIGNMENT_PRECEDENCE)) {
      Token assignment = next;
      token = parseExpressionWithoutCascade(next);
      listener.handleAssignmentExpression(assignment);
    }
    listener.endCascade();
    return token;
  }

  Token parseUnaryExpression(Token token, bool allowCascades) {
    String value = token.next.stringValue;
    // Prefix:
    if (identical(value, 'await')) {
      if (inPlainSync) {
        return parsePrimary(token, IdentifierContext.expression);
      } else {
        return parseAwaitExpression(token, allowCascades);
      }
    } else if (identical(value, '+')) {
      // Dart no longer allows prefix-plus.
      rewriteAndRecover(
          token,
          // TODO(danrubel): Consider reporting "missing identifier" instead.
          fasta.messageUnsupportedPrefixPlus,
          new SyntheticStringToken(
              TokenType.IDENTIFIER, '', token.next.offset));
      return parsePrimary(token, IdentifierContext.expression);
    } else if ((identical(value, '!')) ||
        (identical(value, '-')) ||
        (identical(value, '~'))) {
      Token operator = token.next;
      // Right associative, so we recurse at the same precedence
      // level.
      token = parsePrecedenceExpression(
          token.next, POSTFIX_PRECEDENCE, allowCascades);
      listener.handleUnaryPrefixExpression(operator);
      return token;
    } else if ((identical(value, '++')) || identical(value, '--')) {
      // TODO(ahe): Validate this is used correctly.
      Token operator = token.next;
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

  Token parseArgumentOrIndexStar(Token token, Token typeArguments) {
    // TODO(danrubel): Accept the token before typeArguments
    // TODO(brianwilkerson): Consider replacing `typeArguments` with a boolean
    // flag, given that the only thing it's used for is to compare it with null.
    Token next = token.next;
    Token beginToken = next;
    while (true) {
      if (optional('[', next)) {
        assert(typeArguments == null);
        Token openSquareBracket = next;
        bool old = mayParseFunctionExpressions;
        mayParseFunctionExpressions = true;
        token = parseExpression(next);
        next = token.next;
        mayParseFunctionExpressions = old;
        if (!optional(']', next)) {
          Message message = fasta.templateExpectedButGot.withArguments(']');
          Token newToken = new SyntheticToken(
              TokenType.CLOSE_SQUARE_BRACKET, next.charOffset);
          next = rewriteAndRecover(token, message, newToken).next;
        }
        listener.handleIndexedExpression(openSquareBracket, next);
        token = next;
        next = token.next;
      } else if (optional('(', next)) {
        if (typeArguments == null) {
          if (isValidMethodTypeArguments(next)) {
            token = parseTypeArgumentsOpt(token);
            next = token.next;
          } else {
            listener.handleNoTypeArguments(next);
          }
        }
        token = parseArguments(token);
        next = token.next;
        listener.handleSend(beginToken, next);
        typeArguments = null;
      } else {
        break;
      }
    }
    return token;
  }

  Token parsePrimary(Token token, IdentifierContext context) {
    final kind = token.next.kind;
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
      final String value = token.next.stringValue;
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
        return parseSendOrFunctionLiteral(token, context);
      } else if (!inPlainSync &&
          (identical(value, "yield") || identical(value, "async"))) {
        // Fall through to the recovery code.
      } else if (identical(value, "assert")) {
        return parseAssert(token, Assert.Expression);
      } else if (token.next.isIdentifier) {
        return parseSendOrFunctionLiteral(token, context);
      } else {
        // Fall through to the recovery code.
      }
    } else if (kind == OPEN_PAREN_TOKEN) {
      return parseParenthesizedExpressionOrFunctionLiteral(token);
    } else if (kind == OPEN_SQUARE_BRACKET_TOKEN ||
        optional('[]', token.next)) {
      listener.handleNoTypeArguments(token.next);
      return parseLiteralListSuffix(token, null);
    } else if (kind == OPEN_CURLY_BRACKET_TOKEN) {
      listener.handleNoTypeArguments(token.next);
      return parseLiteralMapSuffix(token, null);
    } else if (kind == LT_TOKEN) {
      return parseLiteralListOrMapOrFunction(token, null);
    } else {
      // Fall through to the recovery code.
    }
    //
    // Recovery code.
    //
    if (token.next is ErrorToken) {
      token = token.next;
      Token previous;
      do {
        // Report the error in the error token, skip the error token, and try
        // again.
        previous = token;
        token = reportErrorTokenAndAdvance(token);
      } while (token is ErrorToken);
      return parsePrimary(previous, context);
    } else {
      return parseSend(token, context);
    }
  }

  Token parseParenthesizedExpressionOrFunctionLiteral(Token token) {
    Token next = token.next;
    assert(optional('(', next));
    Token nextToken = closeBraceTokenFor(next).next;
    int kind = nextToken.kind;
    if (mayParseFunctionExpressions) {
      if ((identical(kind, FUNCTION_TOKEN) ||
          identical(kind, OPEN_CURLY_BRACKET_TOKEN))) {
        listener.handleNoTypeVariables(next);
        return parseFunctionExpression(token);
      } else if (identical(kind, KEYWORD_TOKEN) ||
          identical(kind, IDENTIFIER_TOKEN)) {
        if (optional('async', nextToken) || optional('sync', nextToken)) {
          listener.handleNoTypeVariables(next);
          return parseFunctionExpression(token);
        }
        // Recovery
        // If there is a stray simple identifier in the function expression
        // because the user is typing (e.g. `() asy {}`) then continue parsing
        // and allow parseFunctionExpression to report an unexpected token.
        kind = nextToken.next.kind;
        if ((identical(kind, FUNCTION_TOKEN) ||
            identical(kind, OPEN_CURLY_BRACKET_TOKEN))) {
          listener.handleNoTypeVariables(next);
          return parseFunctionExpression(token);
        }
      }
    }
    bool old = mayParseFunctionExpressions;
    mayParseFunctionExpressions = true;
    token = parseParenthesizedExpression(token);
    mayParseFunctionExpressions = old;
    return token;
  }

  Token parseParenthesizedExpression(Token token) {
    Token previousToken = token;
    token = token.next;
    if (!optional('(', token)) {
      // Recover
      reportRecoverableError(
          token, fasta.templateExpectedToken.withArguments('('));
      reportRecoverableError(
          token, fasta.templateExpectedToken.withArguments(')'));
      BeginToken replacement = link(
          new SyntheticBeginToken(TokenType.OPEN_PAREN, token.charOffset),
          new SyntheticToken(TokenType.CLOSE_PAREN, token.charOffset));
      token = rewriter.insertTokenAfter(previousToken, replacement).next;
    }
    BeginToken begin = token;
    token = parseExpression(token).next;
    if (!identical(begin.endGroup, token)) {
      reportRecoverableError(
          token, fasta.templateExpectedButGot.withArguments(')'));
      token = begin.endGroup;
    }
    listener.handleParenthesizedExpression(begin);
    expect(')', token);
    return token;
  }

  Token parseThisExpression(Token token, IdentifierContext context) {
    Token thisToken = token = token.next;
    assert(optional('this', thisToken));
    listener.handleThisExpression(thisToken, context);
    Token next = token.next;
    if (optional('(', next)) {
      // Constructor forwarding.
      listener.handleNoTypeArguments(next);
      token = parseArguments(token);
      listener.handleSend(thisToken, token.next);
    }
    return token;
  }

  Token parseSuperExpression(Token token, IdentifierContext context) {
    Token superToken = token = token.next;
    assert(optional('super', token));
    listener.handleSuperExpression(superToken, context);
    Token next = token.next;
    if (optional('(', next)) {
      // Super constructor.
      listener.handleNoTypeArguments(next);
      token = parseArguments(token);
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
    Token beforeToken = token;
    Token beginToken = token = token.next;
    assert(optional('[', token) || optional('[]', token));
    int count = 0;
    if (optional('[', token)) {
      bool old = mayParseFunctionExpressions;
      mayParseFunctionExpressions = true;
      do {
        if (optional(']', token.next)) {
          token = token.next;
          break;
        }
        token = parseExpression(token).next;
        ++count;
      } while (optional(',', token));
      mayParseFunctionExpressions = old;
      listener.handleLiteralList(count, beginToken, constKeyword, token);
      expect(']', token);
      return token;
    }
    token = rewriteSquareBrackets(beforeToken).next;
    listener.handleLiteralList(0, token, constKeyword, token.next);
    return token.next;
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
    Token beginToken = token = token.next;
    assert(optional('{', beginToken));
    int count = 0;
    bool old = mayParseFunctionExpressions;
    mayParseFunctionExpressions = true;
    while (true) {
      if (optional('}', token.next)) {
        token = token.next;
        break;
      }
      token = parseMapLiteralEntry(token);
      Token next = token.next;
      ++count;
      if (!optional(',', next)) {
        if (optional('}', next)) {
          token = next;
          break;
        }
        // Recovery
        if (isExpressionStartForRecovery(next)) {
          // If this looks like the start of an expression,
          // then report an error, insert the comma, and continue parsing.
          next = rewriteAndRecover(
                  token,
                  fasta.templateExpectedButGot.withArguments(','),
                  new SyntheticToken(TokenType.COMMA, next.offset))
              .next;
        } else {
          reportRecoverableError(
              next, fasta.templateExpectedButGot.withArguments('}'));
          // Scanner guarantees a closing curly bracket
          token = beginToken.endGroup;
          break;
        }
      }
      token = next;
    }
    assert(optional('}', token));
    mayParseFunctionExpressions = old;
    listener.handleLiteralMap(count, beginToken, constKeyword, token);
    return token;
  }

  /// formalParameterList functionBody.
  ///
  /// This is a suffix parser because it is assumed that type arguments have
  /// been parsed, or `listener.handleNoTypeArguments(..)` has been executed.
  Token parseLiteralFunctionSuffix(Token token) {
    Token next = token.next;
    assert(optional('(', next));
    Token closeBrace = closeBraceTokenFor(next);
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
    return reportUnexpectedToken(next);
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
    Token next = token.next;
    assert(optional('<', next));
    Token closeBrace = closeBraceTokenFor(next);
    if (constKeyword == null &&
        closeBrace != null &&
        identical(closeBrace.next.kind, OPEN_PAREN_TOKEN)) {
      token = parseTypeVariablesOpt(token);
      return parseLiteralFunctionSuffix(token);
    } else {
      token = parseTypeArgumentsOpt(token);
      Token next = token.next;
      if (optional('{', next)) {
        return parseLiteralMapSuffix(token, constKeyword);
      } else if ((optional('[', next)) || (optional('[]', next))) {
        return parseLiteralListSuffix(token, constKeyword);
      }
      return reportUnexpectedToken(token.next);
    }
  }

  /// ```
  /// mapLiteralEntry:
  ///   expression ':' expression
  /// ;
  /// ```
  Token parseMapLiteralEntry(Token token) {
    listener.beginLiteralMapEntry(token.next);
    // Assume the listener rejects non-string keys.
    // TODO(brianwilkerson): Change the assumption above by moving error
    // checking into the parser, making it possible to recover.
    token = parseExpression(token);
    Token colon = ensureColon(token);
    token = parseExpression(colon);
    listener.endLiteralMapEntry(colon, token.next);
    return token;
  }

  Token parseSendOrFunctionLiteral(Token token, IdentifierContext context) {
    if (!mayParseFunctionExpressions) {
      return parseSend(token, context);
    } else {
      return parseType(token, TypeContinuation.SendOrFunctionLiteral, context);
    }
  }

  Token parseRequiredArguments(Token token) {
    Token next = token.next;
    if (!optional('(', next)) {
      reportRecoverableError(
          token, fasta.templateExpectedButGot.withArguments('('));
      BeginToken replacement = link(
          new SyntheticBeginToken(TokenType.OPEN_PAREN, next.offset),
          new SyntheticToken(TokenType.CLOSE_PAREN, next.offset));
      rewriter.insertTokenAfter(token, replacement);
    }
    token = parseArguments(token);
    return token;
  }

  /// ```
  /// newExpression:
  ///   'new' type ('.' identifier)? arguments
  /// ;
  /// ```
  Token parseNewExpression(Token token) {
    Token newKeyword = token.next;
    assert(optional('new', newKeyword));
    listener.beginNewExpression(newKeyword);
    token = parseConstructorReference(newKeyword);
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
    Token constKeyword = token = token.next;
    assert(optional('const', constKeyword));
    Token next = token.next;
    final String value = next.stringValue;
    if ((identical(value, '[')) || (identical(value, '[]'))) {
      listener.beginConstLiteral(next);
      listener.handleNoTypeArguments(next);
      token = parseLiteralListSuffix(token, constKeyword);
      listener.endConstLiteral(token.next);
      return token;
    }
    if (identical(value, '{')) {
      listener.beginConstLiteral(next);
      listener.handleNoTypeArguments(next);
      token = parseLiteralMapSuffix(token, constKeyword);
      listener.endConstLiteral(token.next);
      return token;
    }
    if (identical(value, '<')) {
      listener.beginConstLiteral(next);
      token = parseLiteralListOrMapOrFunction(token, constKeyword);
      listener.endConstLiteral(token.next);
      return token;
    }
    listener.beginConstExpression(constKeyword);
    token = parseConstructorReference(token);
    token = parseRequiredArguments(token);
    listener.endConstExpression(constKeyword);
    return token;
  }

  /// ```
  /// intLiteral:
  ///   integer
  /// ;
  /// ```
  Token parseLiteralInt(Token token) {
    token = token.next;
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
    token = token.next;
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
    assert(identical(token.next.kind, STRING_TOKEN));
    bool old = mayParseFunctionExpressions;
    mayParseFunctionExpressions = true;
    token = parseSingleLiteralString(token);
    int count = 1;
    while (identical(token.next.kind, STRING_TOKEN)) {
      token = parseSingleLiteralString(token);
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
    Token hashToken = token = token.next;
    assert(optional('#', hashToken));
    listener.beginLiteralSymbol(hashToken);
    Token next = token.next;
    if (next.isUserDefinableOperator) {
      listener.handleOperator(next);
      listener.endLiteralSymbol(hashToken, 1);
      return next;
    } else if (optional('void', next)) {
      listener.handleSymbolVoid(next);
      listener.endLiteralSymbol(hashToken, 1);
      return next;
    } else {
      int count = 1;
      token = ensureIdentifier(token, IdentifierContext.literalSymbol);
      while (optional('.', token.next)) {
        count++;
        token = ensureIdentifier(
            token.next, IdentifierContext.literalSymbolContinuation);
      }
      listener.endLiteralSymbol(hashToken, count);
      return token;
    }
  }

  Token parseSingleLiteralString(Token token) {
    token = token.next;
    assert(identical(token.kind, STRING_TOKEN));
    listener.beginLiteralString(token);
    // Parsing the prefix, for instance 'x of 'x${id}y${id}z'
    int interpolationCount = 0;
    Token next = token.next;
    var kind = next.kind;
    while (kind != EOF_TOKEN) {
      if (identical(kind, STRING_INTERPOLATION_TOKEN)) {
        // Parsing ${expression}.
        token = parseExpression(next).next;
        if (!optional('}', token)) {
          reportRecoverableError(
              token, fasta.templateExpectedButGot.withArguments('}'));
          token = next.endGroup;
        }
        listener.handleInterpolationExpression(next, token);
      } else if (identical(kind, STRING_INTERPOLATION_IDENTIFIER_TOKEN)) {
        // Parsing $identifier.
        token = parseIdentifierExpression(next);
        listener.handleInterpolationExpression(next, null);
      } else {
        break;
      }
      ++interpolationCount;
      // Parsing the infix/suffix, for instance y and z' of 'x${id}y${id}z'
      token = parseStringPart(token);
      next = token.next;
      kind = next.kind;
    }
    listener.endLiteralString(interpolationCount, next);
    return token;
  }

  Token parseIdentifierExpression(Token token) {
    Token next = token.next;
    if (next.kind == KEYWORD_TOKEN && identical(next.stringValue, "this")) {
      listener.handleThisExpression(next, IdentifierContext.expression);
      return next;
    } else {
      return parseSend(token, IdentifierContext.expression);
    }
  }

  /// ```
  /// booleanLiteral:
  ///   'true' |
  ///   'false'
  /// ;
  /// ```
  Token parseLiteralBool(Token token) {
    token = token.next;
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
    token = token.next;
    assert(optional('null', token));
    listener.handleLiteralNull(token);
    return token;
  }

  Token parseSend(Token token, IdentifierContext context) {
    Token beginToken = token = ensureIdentifier(token, context);
    if (isValidMethodTypeArguments(token.next)) {
      token = parseTypeArgumentsOpt(token);
    } else {
      listener.handleNoTypeArguments(token.next);
    }
    token = parseArgumentsOpt(token);
    listener.handleSend(beginToken, token.next);
    return token;
  }

  Token skipArgumentsOpt(Token token) {
    Token next = token.next;
    listener.handleNoArguments(next);
    if (optional('(', next)) {
      return closeBraceTokenFor(next);
    } else {
      return token;
    }
  }

  Token parseArgumentsOpt(Token token) {
    Token next = token.next;
    if (!optional('(', next)) {
      listener.handleNoArguments(next);
      return token;
    } else {
      return parseArguments(token);
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
    Token begin = token = token.next;
    assert(optional('(', begin));
    listener.beginArguments(begin);
    int argumentCount = 0;
    bool hasSeenNamedArgument = false;
    bool old = mayParseFunctionExpressions;
    mayParseFunctionExpressions = true;
    while (true) {
      Token next = token.next;
      if (optional(')', next)) {
        token = next;
        break;
      }
      Token colon = null;
      if (optional(':', next.next)) {
        token =
            ensureIdentifier(token, IdentifierContext.namedArgumentReference)
                .next;
        colon = token;
        hasSeenNamedArgument = true;
      } else if (hasSeenNamedArgument) {
        // Positional argument after named argument.
        reportRecoverableError(next, fasta.messagePositionalAfterNamedArgument);
      }
      token = parseExpression(token);
      next = token.next;
      if (colon != null) listener.handleNamedArgument(colon);
      ++argumentCount;
      if (!optional(',', next)) {
        if (optional(')', next)) {
          token = next;
          break;
        }
        // Recovery
        if (isExpressionStartForRecovery(next)) {
          // If this looks like the start of an expression,
          // then report an error, insert the comma, and continue parsing.
          next = rewriteAndRecover(
                  token,
                  fasta.templateExpectedButGot.withArguments(','),
                  new SyntheticToken(TokenType.COMMA, next.offset))
              .next;
        } else {
          reportRecoverableError(
              next, fasta.templateExpectedButGot.withArguments(')'));
          // Scanner guarantees a closing parenthesis
          token = begin.endGroup;
          break;
        }
      }
      token = next;
    }
    assert(optional(')', token));
    mayParseFunctionExpressions = old;
    listener.endArguments(argumentCount, begin, token);
    return token;
  }

  /// ```
  /// typeTest::
  ///   'is' '!'? type
  /// ;
  /// ```
  Token parseIsOperatorRest(Token token) {
    Token operator = token = token.next;
    assert(optional('is', operator));
    Token not = null;
    if (optional('!', token.next)) {
      not = token = token.next;
    }
    token = parseType(token);
    Token next = token.next;
    listener.handleIsOperator(operator, not, next);
    String value = next.stringValue;
    if (identical(value, 'is') || identical(value, 'as')) {
      // The is- and as-operators cannot be chained, but they can take part of
      // expressions like: foo is Foo || foo is Bar.
      reportUnexpectedToken(next);
    }
    return token;
  }

  /// ```
  /// typeCast:
  ///   'as' type
  /// ;
  /// ```
  Token parseAsOperatorRest(Token token) {
    Token operator = token = token.next;
    assert(optional('as', operator));
    token = parseType(token);
    Token next = token.next;
    listener.handleAsOperator(operator, next);
    String value = next.stringValue;
    if (identical(value, 'is') || identical(value, 'as')) {
      // The is- and as-operators cannot be chained.
      reportUnexpectedToken(next);
    }
    return token;
  }

  Token parseVariablesDeclaration(Token token) {
    return parseVariablesDeclarationMaybeSemicolon(token, true);
  }

  Token parseVariablesDeclarationRest(Token token) {
    return parseVariablesDeclarationMaybeSemicolonRest(token, true);
  }

  Token parseVariablesDeclarationNoSemicolon(Token token) {
    // Only called when parsing a for loop, so this is for parsing locals.
    return parseVariablesDeclarationMaybeSemicolon(token, false);
  }

  Token parseVariablesDeclarationNoSemicolonRest(Token token) {
    // Only called when parsing a for loop, so this is for parsing locals.
    return parseVariablesDeclarationMaybeSemicolonRest(token, false);
  }

  Token parseVariablesDeclarationMaybeSemicolon(
      Token token, bool endWithSemicolon) {
    token = parseMetadataStar(token);
    Token next = token.next;

    MemberKind memberKind = MemberKind.Local;
    TypeContinuation typeContinuation;
    Token varFinalOrConst;
    if (isModifier(next)) {
      if (optional('var', next)) {
        typeContinuation = TypeContinuation.OptionalAfterVar;
        varFinalOrConst = token = parseModifier(token);
        next = token.next;
      } else if (optional('final', next) || optional('const', next)) {
        typeContinuation = TypeContinuation.Optional;
        varFinalOrConst = token = parseModifier(token);
        next = token.next;
      }

      if (isModifier(next)) {
        // Recovery
        ModifierRecoveryContext modifierContext = new ModifierRecoveryContext(
            this, memberKind, null, true, typeContinuation);
        token = modifierContext.parseRecovery(token,
            varFinalOrConst: varFinalOrConst);

        varFinalOrConst = modifierContext.varFinalOrConst;
        listener.handleModifiers(modifierContext.modifierCount);

        memberKind = modifierContext.memberKind;
        typeContinuation = modifierContext.typeContinuation;
        modifierContext = null;
      } else {
        listener.handleModifiers(1);
      }
    } else {
      listener.handleModifiers(0);
    }

    token = parseType(
        token, typeContinuation ?? TypeContinuation.Required, null, memberKind);
    return parseVariablesDeclarationMaybeSemicolonRest(token, endWithSemicolon);
  }

  Token parseVariablesDeclarationMaybeSemicolonRest(
      Token token, bool endWithSemicolon) {
    int count = 1;
    listener.beginVariablesDeclaration(token.next);
    token = parseOptionallyInitializedIdentifier(token);
    while (optional(',', token.next)) {
      token = parseOptionallyInitializedIdentifier(token.next);
      ++count;
    }
    if (endWithSemicolon) {
      Token semicolon = ensureSemicolon(token);
      listener.endVariablesDeclaration(count, semicolon);
      return semicolon;
    } else {
      listener.endVariablesDeclaration(count, null);
      return token;
    }
  }

  Token parseOptionallyInitializedIdentifier(Token token) {
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
    Token ifToken = token.next;
    assert(optional('if', ifToken));
    listener.beginIfStatement(ifToken);
    token = parseParenthesizedExpression(ifToken);
    listener.beginThenStatement(token.next);
    token = parseStatement(token);
    listener.endThenStatement(token);
    Token elseToken = null;
    if (optional('else', token.next)) {
      elseToken = token.next;
      listener.beginElseStatement(elseToken);
      token = parseStatement(elseToken);
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
    // TODO(brianwilkerson): Consider moving `token` to be the first parameter.
    Token forKeyword = token.next;
    assert(awaitToken == null || optional('await', awaitToken));
    listener.beginForStatement(forKeyword);
    token = expect('for', forKeyword);
    Token leftParenthesis = token;
    expect('(', token);
    token = parseVariablesDeclarationOrExpressionOpt(token);
    Token next = token.next;
    if (optional('in', next)) {
      if (awaitToken != null && !inAsync) {
        reportRecoverableError(next, fasta.messageAwaitForNotAsync);
      }
      return parseForInRest(awaitToken, forKeyword, leftParenthesis, token);
    } else if (optional(':', next)) {
      reportRecoverableError(next, fasta.messageColonInPlaceOfIn);
      if (awaitToken != null && !inAsync) {
        reportRecoverableError(next, fasta.messageAwaitForNotAsync);
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
    Token next = token.next;
    final String value = next.stringValue;
    if (identical(value, ';')) {
      listener.handleNoExpression(next);
      return token;
    } else if (isOneOf4(next, '@', 'var', 'final', 'const')) {
      return parseVariablesDeclarationNoSemicolon(token);
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
    // TODO(brianwilkerson): Consider moving `token` to be the first parameter.
    Token leftSeparator = ensureSemicolon(token);
    if (optional(';', leftSeparator.next)) {
      token = parseEmptyStatement(leftSeparator);
    } else {
      token = parseExpressionStatement(leftSeparator);
    }
    int expressionCount = 0;
    while (true) {
      Token next = token.next;
      if (optional(')', next)) {
        token = next;
        break;
      }
      token = parseExpression(token).next;
      ++expressionCount;
      if (!optional(',', token)) {
        break;
      }
    }
    expect(')', token);
    listener.beginForStatementBody(token.next);
    LoopState savedLoopState = loopState;
    loopState = LoopState.InsideLoop;
    token = parseStatement(token);
    loopState = savedLoopState;
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
    // TODO(brianwilkerson): Consider moving `token` to be the first parameter.
    Token inKeyword = token.next;
    assert(optional('in', inKeyword) || optional(':', inKeyword));
    listener.beginForInExpression(inKeyword.next);
    token = parseExpression(inKeyword).next;
    listener.endForInExpression(token);
    expect(')', token);
    listener.beginForInBody(token.next);
    LoopState savedLoopState = loopState;
    loopState = LoopState.InsideLoop;
    token = parseStatement(token);
    loopState = savedLoopState;
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
    Token whileToken = token.next;
    assert(optional('while', whileToken));
    listener.beginWhileStatement(whileToken);
    token = parseParenthesizedExpression(whileToken);
    listener.beginWhileStatementBody(token.next);
    LoopState savedLoopState = loopState;
    loopState = LoopState.InsideLoop;
    token = parseStatement(token);
    loopState = savedLoopState;
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
    Token doToken = token.next;
    assert(optional('do', doToken));
    listener.beginDoWhileStatement(doToken);
    listener.beginDoWhileStatementBody(doToken.next);
    LoopState savedLoopState = loopState;
    loopState = LoopState.InsideLoop;
    token = parseStatement(doToken).next;
    loopState = savedLoopState;
    listener.endDoWhileStatementBody(token);
    Token whileToken = token;
    expect('while', token);
    token = parseParenthesizedExpression(token);
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
    Token begin = token = ensureBlock(token, null);
    listener.beginBlock(begin);
    int statementCount = 0;
    while (notEofOrValue('}', token.next)) {
      Token startToken = token.next;
      token = parseStatement(token);
      if (identical(token.next, startToken)) {
        // No progress was made, so we report the current token as being invalid
        // and move forward.
        token = token.next;
        reportRecoverableError(
            token, fasta.templateUnexpectedToken.withArguments(token));
      }
      ++statementCount;
    }
    token = token.next;
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
    Token awaitToken = token.next;
    assert(optional('await', awaitToken));
    listener.beginAwaitExpression(awaitToken);
    if (!inAsync) {
      reportRecoverableError(awaitToken, fasta.messageAwaitNotAsync);
    }
    token = parsePrecedenceExpression(
        awaitToken, POSTFIX_PRECEDENCE, allowCascades);
    listener.endAwaitExpression(awaitToken, token.next);
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
    Token throwToken = token.next;
    assert(optional('throw', throwToken));
    token = allowCascades
        ? parseExpression(throwToken)
        : parseExpressionWithoutCascade(throwToken);
    listener.handleThrowExpression(throwToken, token.next);
    return token;
  }

  /// ```
  /// rethrowStatement:
  ///   'rethrow' ';'
  /// ;
  /// ```
  Token parseRethrowStatement(Token token) {
    Token throwToken = token.next;
    assert(optional('rethrow', throwToken) || optional('throw', throwToken));
    listener.beginRethrowStatement(throwToken);
    // TODO(kasperl): Disallow throw here.
    if (optional('throw', throwToken)) {
      expect('throw', throwToken);
    } else {
      expect('rethrow', throwToken);
    }
    token = ensureSemicolon(throwToken);
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
    Token tryKeyword = token.next;
    assert(optional('try', tryKeyword));
    listener.beginTryStatement(tryKeyword);
    Token lastConsumed = parseBlock(tryKeyword);
    token = lastConsumed.next;
    int catchCount = 0;

    String value = token.stringValue;
    while (identical(value, 'catch') || identical(value, 'on')) {
      listener.beginCatchClause(token);
      Token onKeyword = null;
      if (identical(value, 'on')) {
        // 'on' type catchPart?
        onKeyword = token;
        lastConsumed = parseType(token);
        token = lastConsumed.next;
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
        lastConsumed =
            parseFormalParametersRequiredOpt(token, MemberKind.Catch);
        token = lastConsumed.next;
      }
      listener.endCatchClause(token);
      lastConsumed = parseBlock(lastConsumed);
      token = lastConsumed.next;
      ++catchCount;
      listener.handleCatchBlock(onKeyword, catchKeyword, comma);
      value = token.stringValue; // while condition
    }

    Token finallyKeyword = null;
    if (optional('finally', token)) {
      finallyKeyword = token;
      lastConsumed = parseBlock(token);
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
    Token switchKeyword = token.next;
    assert(optional('switch', switchKeyword));
    listener.beginSwitchStatement(switchKeyword);
    token = parseParenthesizedExpression(switchKeyword);
    LoopState savedLoopState = loopState;
    if (loopState == LoopState.OutsideLoop) {
      loopState = LoopState.InsideSwitch;
    }
    token = parseSwitchBlock(token);
    loopState = savedLoopState;
    listener.endSwitchStatement(switchKeyword, token);
    return token;
  }

  /// ```
  /// switchBlock:
  ///   '{' switchCase* defaultCase? '}'
  /// ;
  /// ```
  Token parseSwitchBlock(Token token) {
    Token beginSwitch = token = ensureBlock(token, null);
    listener.beginSwitchBlock(beginSwitch);
    int caseCount = 0;
    Token defaultKeyword = null;
    Token colonAfterDefault = null;
    while (notEofOrValue('}', token.next)) {
      Token beginCase = token.next;
      int expressionCount = 0;
      int labelCount = 0;
      Token peek = peekPastLabels(beginCase);
      while (true) {
        // Loop until we find something that can't be part of a switch case.
        String value = peek.stringValue;
        if (identical(value, 'default')) {
          while (!identical(token.next, peek)) {
            token = parseLabel(token);
            labelCount++;
          }
          if (defaultKeyword != null) {
            reportRecoverableError(
                token.next, fasta.messageSwitchHasMultipleDefaults);
          }
          defaultKeyword = token.next;
          colonAfterDefault = token = ensureColon(defaultKeyword);
          peek = token.next;
          break;
        } else if (identical(value, 'case')) {
          while (!identical(token.next, peek)) {
            token = parseLabel(token);
            labelCount++;
          }
          Token caseKeyword = token.next;
          if (defaultKeyword != null) {
            reportRecoverableError(
                caseKeyword, fasta.messageSwitchHasCaseAfterDefault);
          }
          listener.beginCaseExpression(caseKeyword);
          token = parseExpression(caseKeyword);
          token = ensureColon(token);
          listener.endCaseExpression(token);
          listener.handleCaseMatch(caseKeyword, token);
          expressionCount++;
          peek = peekPastLabels(token.next);
        } else if (expressionCount > 0) {
          break;
        } else {
          // Recovery
          reportRecoverableError(
              peek, fasta.templateExpectedToken.withArguments("case"));
          Token endGroup = beginSwitch.endGroup;
          while (token.next != endGroup) {
            token = token.next;
          }
          peek = peekPastLabels(token.next);
          break;
        }
      }
      token = parseStatementsInSwitchCase(token, peek, beginCase, labelCount,
          expressionCount, defaultKeyword, colonAfterDefault);
      ++caseCount;
    }
    token = token.next;
    listener.endSwitchBlock(caseCount, beginSwitch, token);
    assert(optional('}', token));
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

  /// Parse statements after a switch `case:` or `default:`.
  Token parseStatementsInSwitchCase(
      Token token,
      Token peek,
      Token begin,
      int labelCount,
      int expressionCount,
      Token defaultKeyword,
      Token colonAfterDefault) {
    listener.beginSwitchCase(labelCount, expressionCount, begin);
    // Finally zero or more statements.
    int statementCount = 0;
    while (!identical(token.next.kind, EOF_TOKEN)) {
      String value = peek.stringValue;
      if ((identical(value, 'case')) ||
          (identical(value, 'default')) ||
          ((identical(value, '}')) && (identical(token.next, peek)))) {
        // A label just before "}" will be handled as a statement error.
        break;
      } else {
        Token startToken = token.next;
        token = parseStatement(token);
        Token next = token.next;
        if (identical(next, startToken)) {
          // No progress was made, so we report the current token as being
          // invalid and move forward.
          reportRecoverableError(
              next, fasta.templateUnexpectedToken.withArguments(next));
          token = next;
        }
        ++statementCount;
      }
      peek = peekPastLabels(token.next);
    }
    listener.endSwitchCase(labelCount, expressionCount, defaultKeyword,
        colonAfterDefault, statementCount, begin, token.next);
    return token;
  }

  /// ```
  /// breakStatement:
  ///   'break' identifier? ';'
  /// ;
  /// ```
  Token parseBreakStatement(Token token) {
    Token breakKeyword = token = token.next;
    assert(optional('break', breakKeyword));
    bool hasTarget = false;
    if (token.next.isIdentifier) {
      token = ensureIdentifier(token, IdentifierContext.labelReference);
      hasTarget = true;
    } else if (!isBreakAllowed) {
      reportRecoverableError(breakKeyword, fasta.messageBreakOutsideOfLoop);
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
    Token assertKeyword = token.next;
    assert(optional('assert', assertKeyword));
    listener.beginAssert(assertKeyword, kind);
    Token commaToken = null;
    token = assertKeyword.next;
    Token leftParenthesis = token;
    expect('(', token);
    bool old = mayParseFunctionExpressions;
    mayParseFunctionExpressions = true;
    token = parseExpression(token).next;
    if (optional(',', token)) {
      if (optional(')', token.next)) {
        token = token.next;
      } else {
        commaToken = token;
        token = parseExpression(token).next;
      }
    }
    if (optional(',', token)) {
      Token firstExtra = token.next;
      if (optional(')', firstExtra)) {
        token = firstExtra;
      } else {
        while (optional(',', token)) {
          Token begin = token.next;
          token = parseExpression(token).next;
          listener.handleExtraneousExpression(
              begin, fasta.messageAssertExtraneousArgument);
        }
        reportRecoverableError(
            firstExtra, fasta.messageAssertExtraneousArgument);
      }
    }
    expect(')', token);
    mayParseFunctionExpressions = old;
    listener.endAssert(
        assertKeyword, kind, leftParenthesis, commaToken, token.next);
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
    assert(optional('assert', token.next));
    token = parseAssert(token, Assert.Statement);
    return ensureSemicolon(token);
  }

  /// ```
  /// continueStatement:
  ///   'continue' identifier? ';'
  /// ;
  /// ```
  Token parseContinueStatement(Token token) {
    Token continueKeyword = token = token.next;
    assert(optional('continue', continueKeyword));
    bool hasTarget = false;
    if (token.next.isIdentifier) {
      token = ensureIdentifier(token, IdentifierContext.labelReference);
      hasTarget = true;
      if (!isContinueWithLabelAllowed) {
        reportRecoverableError(
            continueKeyword, fasta.messageContinueOutsideOfLoop);
      }
    } else if (!isContinueAllowed) {
      reportRecoverableError(
          continueKeyword,
          loopState == LoopState.InsideSwitch
              ? fasta.messageContinueWithoutLabelInCase
              : fasta.messageContinueOutsideOfLoop);
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
    token = token.next;
    assert(optional(';', token));
    listener.handleEmptyStatement(token);
    return token;
  }

  /// Given a token ([beforeToken]) that is known to be before another [token],
  /// return the token that is immediately before the [token].
  Token previousToken(Token beforeToken, Token token) {
    Token next = beforeToken.next;
    while (next != token && next != beforeToken) {
      beforeToken = next;
      next = beforeToken.next;
    }
    return beforeToken;
  }

  /// Recover from finding an invalid class member. The metadata for the member,
  /// if any, has already been parsed (and events have already been generated).
  /// The member was expected to start with the token after [token].
  Token recoverFromInvalidClassMember(
      Token token,
      Token beforeStart,
      Token externalToken,
      Token staticToken,
      Token covariantToken,
      Token varFinalOrConst,
      Token beforeType,
      Token getOrSet,
      TypeContinuation typeContinuation) {
    Token next = token.next;
    String value = next.stringValue;

    if (identical(value, 'class')) {
      return reportAndSkipClassInClass(next);
    } else if (identical(value, 'enum')) {
      return reportAndSkipEnumInClass(next);
    } else if (identical(value, 'typedef')) {
      return reportAndSkipTypedefInClass(next);
    }

    bool looksLikeMethod = getOrSet != null ||
        identical(value, '(') ||
        identical(value, '=>') ||
        identical(value, '{') ||
        next.isOperator;
    if (token == beforeStart && !looksLikeMethod) {
      // Ensure we make progress.
      // TODO(danrubel): Provide a more specific error message for extra ';'.
      reportRecoverableErrorWithToken(next, fasta.templateExpectedClassMember);
      listener.handleInvalidMember(next);
      token = next;
    } else {
      // Looks like a partial declaration.
      if (next.isUserDefinableOperator) {
        reportRecoverableError(next, fasta.messageMissingOperatorKeyword);
        // Insert a synthetic 'operator'.
        rewriter.insertTokenAfter(
            token, new SyntheticToken(Keyword.OPERATOR, next.offset));
      } else {
        if (next.isOperator) {
          reportRecoverableErrorWithToken(next, fasta.templateInvalidOperator);
          token = next;
          next = token.next;
        } else {
          reportRecoverableError(
              next, fasta.templateExpectedIdentifier.withArguments(next));
        }
        // Insert a synthetic identifier and continue parsing.
        if (!next.isIdentifier) {
          rewriter.insertTokenAfter(
              token,
              new SyntheticStringToken(
                  TokenType.IDENTIFIER,
                  '#synthetic_identifier_${next.charOffset}',
                  next.charOffset,
                  0));
        }
      }

      if (looksLikeMethod) {
        token = parseMethod(beforeStart, externalToken, staticToken,
            covariantToken, varFinalOrConst, beforeType, getOrSet, token);
      } else {
        token = parseFields(
            beforeStart,
            externalToken,
            staticToken,
            covariantToken,
            varFinalOrConst,
            beforeType,
            token,
            MemberKind.NonStaticField,
            typeContinuation);
      }
    }

    listener.endMember();
    return token;
  }

  /// Report that the nesting depth of the code being parsed is too large for
  /// the parser to safely handle. Return the EOF token in order to cause the
  /// parser to unwind and exit.
  Token recoverFromStackOverflow(Token token) {
    listener.handleRecoverableError(fasta.messageStackOverflow, token, token);
    Token semicolon = new SyntheticToken(TokenType.SEMICOLON, token.offset);
    listener.handleEmptyStatement(semicolon);
    return skipToEof(token);
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

  Token reportInvalidTopLevelDeclaration(Token token) {
    reportRecoverableErrorWithToken(token, fasta.templateExpectedDeclaration);
    listener.handleInvalidTopLevelDeclaration(token);
    return token;
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

  Token reportAndSkipClassInClass(Token token) {
    assert(optional('class', token));
    reportRecoverableError(token, fasta.messageClassInClass);
    listener.handleInvalidMember(token);
    Token next = token.next;
    // If the declaration appears to be a valid class declaration
    // then skip the entire declaration so that we only generate the one
    // error (above) rather than a plethora of unhelpful errors.
    if (next.isIdentifier) {
      // skip class name
      token = next;
      next = token.next;
      // TODO(danrubel): consider parsing (skipping) the class header
      // with a recovery listener so that no events are generated
      if (optional('{', next) && next.endGroup != null) {
        // skip class body
        token = next.endGroup;
      }
    }
    return token;
  }

  Token reportAndSkipEnumInClass(Token token) {
    assert(optional('enum', token));
    reportRecoverableError(token, fasta.messageEnumInClass);
    listener.handleInvalidMember(token);
    Token next = token.next;
    // If the declaration appears to be a valid enum declaration
    // then skip the entire declaration so that we only generate the one
    // error (above) rather than a plethora of unhelpful errors.
    if (next.isIdentifier) {
      // skip enum name
      token = next;
      next = token.next;
      if (optional('{', next) && next.endGroup != null) {
        // TODO(danrubel): Consider replacing this `skip enum` functionality
        // with something that can parse and resolve the declaration
        // even though it is in a class context
        token = next.endGroup;
      }
    }
    return token;
  }

  Token reportAndSkipTypedefInClass(Token token) {
    assert(optional('typedef', token));
    reportRecoverableError(token, fasta.messageTypedefInClass);
    listener.handleInvalidMember(token);
    // TODO(brianwilkerson): If the declaration appears to be a valid typedef
    // then skip the entire declaration so that we generate a single error
    // (above) rather than many unhelpful errors.
    return token;
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
    // Return the previous token if there is one so that any token inserted
    // before `token` will be properly inserted into the token stream.
    // TODO(danrubel): remove this once all methods have been converted to
    // use and return the last token consumed and the `previous` field
    // has been removed.
    if (token.previous != null) {
      return token.previous;
    }
    Token before = new Token.eof(-1);
    before.next = token;
    return before;
  }
}

// TODO(ahe): Remove when analyzer supports generalized function syntax.
typedef _MessageWithArgument<T> = Message Function(T);
