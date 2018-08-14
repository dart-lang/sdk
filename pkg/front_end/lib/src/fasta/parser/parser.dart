// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.parser.parser;

import '../fasta_codes.dart' show Message, Template;

import '../fasta_codes.dart' as fasta;

import '../scanner.dart' show ErrorToken, Token;

import '../../scanner/token.dart'
    show
        ASSIGNMENT_PRECEDENCE,
        BeginToken,
        CASCADE_PRECEDENCE,
        EQUALITY_PRECEDENCE,
        Keyword,
        POSTFIX_PRECEDENCE,
        RELATIONAL_PRECEDENCE,
        SELECTOR_PRECEDENCE,
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
        HASH_TOKEN,
        HEXADECIMAL_TOKEN,
        IDENTIFIER_TOKEN,
        INT_TOKEN,
        KEYWORD_TOKEN,
        LT_TOKEN,
        OPEN_CURLY_BRACKET_TOKEN,
        OPEN_PAREN_TOKEN,
        OPEN_SQUARE_BRACKET_TOKEN,
        SEMICOLON_TOKEN,
        STRING_INTERPOLATION_IDENTIFIER_TOKEN,
        STRING_INTERPOLATION_TOKEN,
        STRING_TOKEN;

import 'assert.dart' show Assert;

import 'async_modifier.dart' show AsyncModifier;

import 'directive_context.dart';

import 'formal_parameter_kind.dart'
    show
        FormalParameterKind,
        isMandatoryFormalParameterKind,
        isOptionalPositionalFormalParameterKind;

import 'forwarding_listener.dart' show ForwardingListener;

import 'identifier_context.dart'
    show IdentifierContext, looksLikeExpressionStart;

import 'listener.dart' show Listener;

import 'loop_state.dart' show LoopState;

import 'member_kind.dart' show MemberKind;

import 'modifier_context.dart' show ModifierRecoveryContext, isModifier;

import 'recovery_listeners.dart'
    show ClassHeaderRecoveryListener, ImportRecoveryListener;

import 'token_stream_rewriter.dart' show TokenStreamRewriter;

import 'type_info.dart'
    show
        TypeInfo,
        TypeParamOrArgInfo,
        computeMethodTypeArguments,
        computeType,
        computeTypeParamOrArg,
        isValidTypeReference,
        noType,
        noTypeParamOrArg;

import 'util.dart'
    show
        findNonZeroLengthToken,
        findPreviousNonZeroLengthToken,
        isLetter,
        isLetterOrDigit,
        isOneOf,
        isWhitespace,
        optional;

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
        // Recovery:
        // If progress has not been made reaching the end of the token stream,
        // then report an error and skip the current token.
        token = token.next;
        listener.beginMetadataStar(token);
        listener.endMetadataStar(0);
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
        final String value = token.next.stringValue;
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
    Token next = token.next;
    if (next.isTopLevelKeyword) {
      return parseTopLevelKeywordDeclaration(token, null, directiveState);
    }
    Token start = token;
    // Skip modifiers to find a top level keyword or identifier
    if (next.isModifier) {
      if (optional('var', next) ||
          ((optional('const', next) || optional('final', next)) &&
              // Ignore `const class` and `final class` so that it is reported
              // below as an invalid modifier on a class.
              !optional('class', next.next))) {
        directiveState?.checkDeclaration();
        return parseTopLevelMemberImpl(token);
      }
      while (token.next.isModifier) {
        token = token.next;
      }
    }
    next = token.next;
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
    } else if (next.isKeywordOrIdentifier) {
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
          new SyntheticStringToken(
              TokenType.IDENTIFIER,
              '#synthetic_function_${next.charOffset}',
              next.next.charOffset,
              0));
      return parseTopLevelMemberImpl(next);
    }
    // Ignore any preceding modifiers and just report the unexpected token
    listener.beginTopLevelMember(next);
    return parseInvalidTopLevelDeclaration(token);
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
      String nextValue = token.next.stringValue;
      directiveState?.checkDeclaration();
      if (identical('(', nextValue) ||
          identical('<', nextValue) ||
          identical('.', nextValue)) {
        return parseTopLevelMemberImpl(previous);
      } else {
        return parseTypedef(previous);
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
    final recoveryListener = new ImportRecoveryListener();

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
    assert(optional('if', token));
    listener.beginConditionalUri(token);
    Token leftParen = token.next;
    if (!optional('(', leftParen)) {
      reportRecoverableError(
          leftParen, fasta.templateExpectedButGot.withArguments('('));
      leftParen = rewriter.insertParens(token, true);
    }
    token = parseDottedName(leftParen);
    Token next = token.next;
    Token equalitySign;
    if (optional('==', next)) {
      equalitySign = next;
      token = ensureLiteralString(next);
      next = token.next;
    }
    if (next != leftParen.endGroup) {
      Token endGroup = leftParen.endGroup;
      if (endGroup.isSynthetic) {
        // The scanner did not place the synthetic ')' correctly, so move it.
        next = rewriter.moveSynthetic(token, endGroup);
      } else {
        reportRecoverableErrorWithToken(next, fasta.templateUnexpectedToken);
        next = endGroup;
      }
    }
    token = next;
    assert(optional(')', token));

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
    token = computeType(token, true).ensureTypeOrVoid(token, this);
    int count = 1;
    while (optional(',', token.next)) {
      token = computeType(token.next, true).ensureTypeOrVoid(token.next, this);
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
    token = computeTypeParamOrArg(token).parseArguments(token, this);
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
  ///   metadata 'typedef' typeAliasBody |
  ///   metadata 'typedef' identifier typeParameters? '=' functionType ';'
  /// ;
  ///
  /// functionType:
  ///   returnType? 'Function' typeParameters? parameterTypeList
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
    TypeInfo typeInfo = computeType(typedefKeyword, false);
    token = typeInfo.skipType(typedefKeyword).next;
    Token equals;
    TypeParamOrArgInfo typeParam = computeTypeParamOrArg(token, true);
    if (typeInfo == noType &&
        (token.kind == IDENTIFIER_TOKEN || token.type.isPseudo) &&
        optional('=', typeParam.skip(token).next)) {
      listener.handleIdentifier(token, IdentifierContext.typedefDeclaration);
      equals = typeParam.parseVariables(token, this).next;
      assert(optional('=', equals));
      token = computeType(equals, true).ensureTypeOrVoid(equals, this);
    } else {
      token = typeInfo.parseType(typedefKeyword, this);
      token = ensureIdentifier(token, IdentifierContext.typedefDeclaration);
      token = typeParam.parseVariables(token, this);
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
    if (!optional('with', withKeyword)) {
      reportRecoverableError(
          withKeyword, fasta.templateExpectedButGot.withArguments('with'));
      withKeyword =
          new SyntheticKeywordToken(Keyword.WITH, withKeyword.charOffset);
      rewriter.insertTokenAfter(token, withKeyword);
      if (!isValidTypeReference(withKeyword.next)) {
        rewriter.insertSyntheticIdentifier(withKeyword);
      }
    }
    listener.beginMixinApplication(withKeyword);
    assert(optional('with', withKeyword));
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
    token = token.next;
    assert(optional('(', token));
    // TODO(ahe): Shouldn't this be `beginFormalParameters`?
    listener.beginOptionalFormalParameters(token);
    Token closeBrace = token.endGroup;
    assert(optional(')', closeBrace));
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
      rewriter.insertParens(token, false);
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
      if (!optional(',', next)) {
        Token next = token.next;
        if (optional(')', next)) {
          token = next;
        } else {
          // Recovery
          if (begin.endGroup.isSynthetic) {
            // Scanner has already reported a missing `)` error,
            // but placed the `)` in the wrong location, so move it.
            token = rewriter.moveSynthetic(token, begin.endGroup);
          } else if (next.kind == IDENTIFIER_TOKEN &&
              next.next.kind == IDENTIFIER_TOKEN) {
            // Looks like a missing comma
            Token comma = new SyntheticToken(TokenType.COMMA, next.charOffset);
            token = rewriter.insertTokenAfter(token, comma).next;
            continue;
          } else {
            token = ensureCloseParen(token, begin);
          }
        }
        break;
      }
      token = next;
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
    Token start = next;

    final bool inFunctionType =
        memberKind == MemberKind.GeneralizedFunctionType;

    Token covariantToken;
    Token varFinalOrConst;
    if (isModifier(next)) {
      if (optional('covariant', next)) {
        if (memberKind != MemberKind.StaticMethod &&
            memberKind != MemberKind.TopLevelMethod) {
          covariantToken = token = next;
          next = token.next;
        }
      }

      if (isModifier(next)) {
        if (!inFunctionType) {
          if (optional('var', next)) {
            varFinalOrConst = token = next;
            next = token.next;
          } else if (optional('final', next)) {
            varFinalOrConst = token = next;
            next = token.next;
          }
        }

        if (isModifier(next)) {
          // Recovery
          ModifierRecoveryContext context = new ModifierRecoveryContext(this);
          token = context.parseFormalParameterModifiers(token, memberKind,
              covariantToken: covariantToken, varFinalOrConst: varFinalOrConst);
          covariantToken = context.covariantToken;
          varFinalOrConst = context.varFinalOrConst;
          context = null;
        }
      }
    }

    listener.beginFormalParameter(
        start, memberKind, covariantToken, varFinalOrConst);

    // Type is required in a generalized function type, but optional otherwise.
    final Token beforeType = token;
    TypeInfo typeInfo = computeType(token, inFunctionType);
    token = typeInfo.skipType(token);
    next = token.next;
    if (typeInfo == noType &&
        (optional('.', next) ||
            (next.isIdentifier && optional('.', next.next)))) {
      // Recovery: Malformed type reference.
      typeInfo = computeType(beforeType, true);
      token = typeInfo.skipType(beforeType);
      next = token.next;
    }

    final bool isNamedParameter =
        parameterKind == FormalParameterKind.optionalNamed;

    Token thisKeyword;
    Token periodAfterThis;
    IdentifierContext nameContext =
        IdentifierContext.formalParameterDeclaration;

    if (!inFunctionType && optional('this', next)) {
      thisKeyword = token = next;
      next = token.next;
      if (!optional('.', next)) {
        // Recover from a missing period by inserting one.
        next = rewriteAndRecover(
                token,
                fasta.templateExpectedButGot.withArguments('.'),
                new SyntheticToken(TokenType.PERIOD, next.charOffset))
            .next;
      }
      periodAfterThis = token = next;
      next = token.next;
      nameContext = IdentifierContext.fieldInitializer;
    }

    if (next.isIdentifier) {
      token = next;
      next = token.next;
    }
    Token beforeInlineFunctionType;
    TypeParamOrArgInfo typeParam = noTypeParamOrArg;
    if (optional("<", next)) {
      typeParam = computeTypeParamOrArg(token);
      if (typeParam != noTypeParamOrArg) {
        Token closer = typeParam.skip(token);
        if (optional("(", closer.next)) {
          if (varFinalOrConst != null) {
            reportRecoverableError(
                varFinalOrConst, fasta.messageFunctionTypedParameterVar);
          }
          beforeInlineFunctionType = token;
          token = closer.next.endGroup;
          next = token.next;
        }
      }
    } else if (optional("(", next)) {
      if (varFinalOrConst != null) {
        reportRecoverableError(
            varFinalOrConst, fasta.messageFunctionTypedParameterVar);
      }
      beforeInlineFunctionType = token;
      token = next.endGroup;
      next = token.next;
    }
    if (typeInfo != noType &&
        varFinalOrConst != null &&
        optional('var', varFinalOrConst)) {
      reportRecoverableError(varFinalOrConst, fasta.messageTypeAfterVar);
    }

    Token endInlineFunctionType;
    if (beforeInlineFunctionType != null) {
      endInlineFunctionType =
          typeParam.parseVariables(beforeInlineFunctionType, this);
      listener.beginFunctionTypedFormalParameter(beforeInlineFunctionType.next);
      token = typeInfo.parseType(beforeType, this);
      endInlineFunctionType = parseFormalParametersRequiredOpt(
          endInlineFunctionType, MemberKind.FunctionTypedParameter);
      listener.endFunctionTypedFormalParameter(beforeInlineFunctionType);

      // Generalized function types don't allow inline function types.
      // The following isn't allowed:
      //    int Function(int bar(String x)).
      if (inFunctionType) {
        reportRecoverableError(beforeInlineFunctionType.next,
            fasta.messageInvalidInlineFunctionType);
      }
    } else if (inFunctionType) {
      token = typeInfo.ensureTypeOrVoid(beforeType, this);
    } else {
      token = typeInfo.parseType(beforeType, this);
    }

    Token nameToken;
    if (periodAfterThis != null) {
      token = periodAfterThis;
    }
    next = token.next;
    if (inFunctionType && !isNamedParameter && !next.isKeywordOrIdentifier) {
      nameToken = token.next;
      listener.handleNoName(nameToken);
    } else {
      nameToken = token = ensureIdentifier(token, nameContext);
      if (isNamedParameter && nameToken.lexeme.startsWith("_")) {
        reportRecoverableError(nameToken, fasta.messagePrivateNamedParameter);
      }
    }
    if (endInlineFunctionType != null) {
      token = endInlineFunctionType;
    }
    next = token.next;

    String value = next.stringValue;
    if ((identical('=', value)) || (identical(':', value))) {
      Token equal = next;
      listener.beginFormalParameterDefaultValueExpression();
      token = parseExpression(equal);
      next = token.next;
      listener.endFormalParameterDefaultValueExpression();
      // TODO(danrubel): Consider removing the last parameter from the
      // handleValuedFormalParameter event... it appears to be unused.
      listener.handleValuedFormalParameter(equal, next);
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
        reportRecoverableError(equal, fasta.messageFunctionTypeDefaultValue);
      }
    } else {
      listener.handleFormalParameterWithoutValue(next);
    }
    listener.endFormalParameter(
        thisKeyword, periodAfterThis, nameToken, parameterKind, memberKind);
    return token;
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
    // The scanner ensures that `{` always has a closing `}`.
    return ensureBlock(token, null).endGroup;
  }

  /// ```
  /// enumType:
  ///   metadata 'enum' id '{' metadata id [',' metadata id]* [','] '}'
  /// ;
  /// ```
  Token parseEnum(Token token) {
    Token enumKeyword = token.next;
    assert(optional('enum', enumKeyword));
    listener.beginEnum(enumKeyword);
    token = ensureIdentifier(enumKeyword, IdentifierContext.enumDeclaration);
    Token leftBrace = token.next;
    int count = 0;
    if (optional('{', leftBrace)) {
      token = leftBrace;
      while (true) {
        Token next = token.next;
        if (optional('}', next)) {
          token = next;
          if (count == 0) {
            reportRecoverableError(token, fasta.messageEnumDeclarationEmpty);
          }
          break;
        }
        token = parseMetadataStar(token);
        token = ensureIdentifier(token, IdentifierContext.enumValueDeclaration);
        next = token.next;
        count++;
        if (optional(',', next)) {
          token = next;
        } else if (optional('}', next)) {
          token = next;
          break;
        } else {
          // Recovery
          Token endGroup = leftBrace.endGroup;
          if (endGroup.isSynthetic) {
            // The scanner did not place the synthetic '}' correctly.
            token = rewriter.moveSynthetic(token, endGroup);
            break;
          } else if (next.isIdentifier) {
            // If the next token is an identifier, assume a missing comma.
            // TODO(danrubel): Consider improved recovery for missing `}`
            // both here and when the scanner inserts a synthetic `}`
            // for situations such as `enum Letter {a, b   Letter e;`.
            reportRecoverableError(
                next, fasta.templateExpectedButGot.withArguments(','));
          } else {
            // Otherwise assume a missing `}` and exit the loop
            reportRecoverableError(
                next, fasta.templateExpectedButGot.withArguments('}'));
            token = leftBrace.endGroup;
            break;
          }
        }
      }
    } else {
      leftBrace = ensureBlock(token, fasta.templateExpectedEnumBody);
      token = leftBrace.endGroup;
    }
    assert(optional('}', token));
    listener.endEnum(enumKeyword, leftBrace, count);
    return token;
  }

  Token parseClassOrNamedMixinApplication(
      Token token, Token beforeAbstractToken) {
    token = token.next;
    listener.beginClassOrNamedMixinApplication(token);
    Token abstractToken = beforeAbstractToken?.next;
    Token begin = abstractToken ?? token;
    Token classKeyword = token;
    assert(optional('class', token));
    Token name =
        ensureIdentifier(token, IdentifierContext.classOrNamedMixinDeclaration);
    token = computeTypeParamOrArg(name, true).parseVariables(name, this);
    if (optional('=', token.next)) {
      listener.beginNamedMixinApplication(begin, abstractToken, name);
      return parseNamedMixinApplication(token, begin, classKeyword);
    } else {
      listener.beginClassDeclaration(begin, abstractToken, name);
      return parseClass(token, begin, classKeyword);
    }
  }

  Token parseNamedMixinApplication(
      Token token, Token begin, Token classKeyword) {
    Token equals = token = token.next;
    assert(optional('=', equals));
    token = computeType(token, true).ensureTypeNotVoid(token, this);
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
    final recoveryListener = new ClassHeaderRecoveryListener();

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
        token = computeType(extendsKeyword, true)
            .ensureTypeNotVoid(extendsKeyword, this);
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
      token = computeType(next, true).ensureTypeNotVoid(next, this);
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
        token =
            computeType(token.next, true).ensureTypeNotVoid(token.next, this);
        ++interfacesCount;
      } while (optional(',', token.next));
    }
    listener.handleClassImplements(implementsKeyword, interfacesCount);
    return token;
  }

  Token parseStringPart(Token token) {
    Token next = token.next;
    if (next.kind != STRING_TOKEN) {
      bool errorReported = false;
      while (next is ErrorToken) {
        errorReported = true;
        reportErrorToken(next);
        token = next;
        next = token.next;
      }
      if (next.kind != STRING_TOKEN) {
        if (!errorReported) {
          reportRecoverableErrorWithToken(next, fasta.templateExpectedString);
        }
        next = rewriter
            .insertTokenAfter(token,
                new SyntheticStringToken(TokenType.STRING, '', next.charOffset))
            .next;
      }
    }
    listener.handleStringPart(next);
    return next;
  }

  /// Insert a synthetic identifier after the given [token] and create an error
  /// message based on the given [context]. Return the synthetic identifier that
  /// was inserted.
  Token insertSyntheticIdentifier(Token token, IdentifierContext context,
      {Message message, Token messageOnToken}) {
    Token next = token.next;
    reportRecoverableError(messageOnToken ?? next,
        message ?? context.recoveryTemplate.withArguments(next));
    return rewriter.insertSyntheticIdentifier(token);
  }

  /// Parse a simple identifier at the given [token], and return the identifier
  /// that was parsed.
  ///
  /// If the token is not an identifier, or is not appropriate for use as an
  /// identifier in the given [context], create a synthetic identifier, report
  /// an error, and return the synthetic identifier.
  Token ensureIdentifier(Token token, IdentifierContext context) {
    assert(context != null);
    Token identifier = token.next;
    if (identifier.kind != IDENTIFIER_TOKEN) {
      identifier = context.ensureIdentifier(token, this);
      assert(identifier != null);
      assert(identifier.isKeywordOrIdentifier);
    }
    listener.handleIdentifier(identifier, context);
    return identifier;
  }

  bool notEofOrValue(String value, Token token) {
    return !identical(token.kind, EOF_TOKEN) &&
        !identical(value, token.stringValue);
  }

  Token parseTypeVariablesOpt(Token token) {
    return computeTypeParamOrArg(token, true).parseVariables(token, this);
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

    if (isModifier(next)) {
      if (optional('external', next)) {
        externalToken = token = next;
        next = token.next;
      }
      if (isModifier(next)) {
        if (optional('final', next)) {
          varFinalOrConst = token = next;
          next = token.next;
        } else if (optional('var', next)) {
          varFinalOrConst = token = next;
          next = token.next;
        } else if (optional('const', next)) {
          varFinalOrConst = token = next;
          next = token.next;
        }
        if (isModifier(next)) {
          // Recovery
          if (varFinalOrConst != null &&
              (optional('final', next) ||
                  optional('var', next) ||
                  optional('const', next))) {
            // If another `var`, `final`, or `const` then fall through
            // to parse that as part of the next top level declaration.
          } else {
            ModifierRecoveryContext context = new ModifierRecoveryContext(this);
            token = context.parseTopLevelModifiers(token,
                externalToken: externalToken, varFinalOrConst: varFinalOrConst);
            next = token.next;

            externalToken = context.externalToken;
            varFinalOrConst = context.varFinalOrConst;
            context = null;
          }
        }
      }
    }

    Token beforeType = token;
    TypeInfo typeInfo = computeType(token, false, true);
    token = typeInfo.skipType(token);
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
          return parseInvalidTopLevelDeclaration(token);
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
      return parseTopLevelMethod(beforeStart, externalToken, beforeType,
          typeInfo, getOrSet, token.next);
    }

    if (getOrSet != null) {
      reportRecoverableErrorWithToken(
          getOrSet, fasta.templateExtraneousModifier);
    }
    return parseFields(beforeStart, externalToken, null, null, varFinalOrConst,
        beforeType, typeInfo, token.next, true);
  }

  Token parseFields(
      Token beforeStart,
      Token externalToken,
      Token staticToken,
      Token covariantToken,
      Token varFinalOrConst,
      Token beforeType,
      TypeInfo typeInfo,
      Token name,
      bool isTopLevel) {
    if (externalToken != null) {
      reportRecoverableError(externalToken, fasta.messageExternalField);
    }
    if (covariantToken != null) {
      if (varFinalOrConst != null && optional('final', varFinalOrConst)) {
        reportRecoverableError(covariantToken, fasta.messageFinalAndCovariant);
        covariantToken = null;
      }
    }
    if (typeInfo == noType) {
      if (varFinalOrConst == null) {
        reportRecoverableError(name, fasta.messageMissingConstFinalVarOrType);
      }
    } else {
      if (varFinalOrConst != null && optional('var', varFinalOrConst)) {
        reportRecoverableError(varFinalOrConst, fasta.messageTypeAfterVar);
      }
    }

    Token token = typeInfo.parseType(beforeType, this);
    assert(token.next == name);

    IdentifierContext context = isTopLevel
        ? IdentifierContext.topLevelVariableDeclaration
        : IdentifierContext.fieldDeclaration;
    name = ensureIdentifier(token, context);

    int fieldCount = 1;
    token = parseFieldInitializerOpt(name, name, varFinalOrConst, isTopLevel);
    while (optional(',', token.next)) {
      name = ensureIdentifier(token.next, context);
      token = parseFieldInitializerOpt(name, name, varFinalOrConst, isTopLevel);
      ++fieldCount;
    }
    token = ensureSemicolon(token);
    if (isTopLevel) {
      listener.endTopLevelFields(staticToken, covariantToken, varFinalOrConst,
          fieldCount, beforeStart.next, token);
    } else {
      listener.endFields(staticToken, covariantToken, varFinalOrConst,
          fieldCount, beforeStart.next, token);
    }
    return token;
  }

  Token parseTopLevelMethod(Token beforeStart, Token externalToken,
      Token beforeType, TypeInfo typeInfo, Token getOrSet, Token name) {
    listener.beginTopLevelMethod(beforeStart, externalToken);

    Token token = typeInfo.parseType(beforeType, this);
    assert(token.next == (getOrSet ?? name));
    name = ensureIdentifier(
        getOrSet ?? token, IdentifierContext.topLevelFunctionDeclaration);

    bool isGetter = false;
    if (getOrSet == null) {
      token = parseMethodTypeVar(name);
    } else {
      isGetter = optional("get", getOrSet);
      token = name;
      listener.handleNoTypeVariables(token.next);
    }
    checkFormals(token, name, isGetter, MemberKind.TopLevelMethod);
    token = parseFormalParametersOpt(token, MemberKind.TopLevelMethod);
    AsyncModifier savedAsyncModifier = asyncState;
    Token asyncToken = token.next;
    token = parseAsyncModifierOpt(token);
    if (getOrSet != null && !inPlainSync && optional("set", getOrSet)) {
      reportRecoverableError(asyncToken, fasta.messageSetterNotSync);
    }
    bool isExternal = externalToken != null;
    if (isExternal && !optional(';', token.next)) {
      reportRecoverableError(
          externalToken, fasta.messageExternalMethodWithBody);
    }
    token = parseFunctionBody(token, false, isExternal);
    asyncState = savedAsyncModifier;
    listener.endTopLevelMethod(beforeStart.next, getOrSet, token);
    return token;
  }

  Token parseMethodTypeVar(Token name) {
    if (!optional('<', name.next)) {
      return noTypeParamOrArg.parseVariables(name, this);
    }
    TypeParamOrArgInfo typeVar = computeTypeParamOrArg(name, true);
    Token token = typeVar.parseVariables(name, this);
    if (optional('=', token.next)) {
      // Recovery
      token = token.next;
      reportRecoverableErrorWithToken(token, fasta.templateUnexpectedToken);
    }
    return token;
  }

  void checkFormals(Token token, Token name, bool isGetter, MemberKind kind) {
    Token next = token.next;
    if (optional("(", next)) {
      if (isGetter) {
        reportRecoverableError(next, fasta.messageGetterWithFormals);
      }
    } else if (!isGetter) {
      if (optional('operator', name)) {
        Token next = name.next;
        if (next.isOperator) {
          name = next;
        } else if (isUnaryMinus(next)) {
          name = next.next;
        }
      }
      // Recovery
      reportRecoverableError(name, missingParameterMessage(kind));
      rewriter.insertParens(token, false);
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
      if (varFinalOrConst != null && !name.isSynthetic) {
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
    Token beforeExpression = token;
    if (optional('assert', next)) {
      token = parseAssert(token, Assert.Initializer);
      listener.endInitializer(token.next);
      return token;
    } else if (optional('super', next)) {
      return parseSuperInitializerExpression(token);
    } else if (optional('this', next)) {
      token = next;
      next = token.next;
      if (optional('.', next)) {
        token = next;
        next = token.next;
        if (next.isIdentifier) {
          token = next;
        } else {
          // Recovery
          token = insertSyntheticIdentifier(
              token, IdentifierContext.fieldInitializer);
        }
        next = token.next;
        if (optional('=', next)) {
          return parseInitializerExpressionRest(beforeExpression);
        }
      }
      if (optional('(', next)) {
        token = parseInitializerExpressionRest(beforeExpression);
        next = token.next;
        if (optional('{', next) || optional('=>', next)) {
          reportRecoverableError(
              next, fasta.messageRedirectingConstructorWithBody);
        }
        return token;
      }
      // Recovery
      if (optional('this', token)) {
        // TODO(danrubel): Consider a better error message indicating that
        // `this.<fieldname>=` is expected.
        reportRecoverableError(
            next, fasta.templateExpectedButGot.withArguments('.'));
        rewriter.insertTokenAfter(
            token, new SyntheticToken(TokenType.PERIOD, next.offset));
        token = rewriter.insertSyntheticIdentifier(token.next);
        next = token.next;
      }
      // Fall through to recovery
    } else if (next.isIdentifier) {
      if (optional('=', next.next)) {
        return parseInitializerExpressionRest(token);
      }
      // Fall through to recovery
    } else {
      // Recovery
      insertSyntheticIdentifier(token, IdentifierContext.fieldInitializer,
          message: fasta.messageExpectedAnInitializer, messageOnToken: token);
      return parseInitializerExpressionRest(beforeExpression);
    }
    // Recovery
    // Insert a sythetic assignment to ensure that the expression is indeed
    // an assignment. Failing to do so causes this test to fail:
    // pkg/front_end/testcases/regress/issue_31192.dart
    // TODO(danrubel): Investigate better recovery.
    token = insertSyntheticIdentifier(
        beforeExpression, IdentifierContext.fieldInitializer,
        message: fasta.messageMissingAssignmentInInitializer);
    rewriter.insertTokenAfter(
        token, new SyntheticToken(TokenType.EQ, token.offset));
    return parseInitializerExpressionRest(beforeExpression);
  }

  /// Parse the `super` initializer:
  /// ```
  ///   'super' ('.' identifier)? arguments ;
  /// ```
  Token parseSuperInitializerExpression(final Token start) {
    Token token = start.next;
    assert(optional('super', token));
    Token next = token.next;
    if (optional('.', next)) {
      token = next;
      next = token.next;
      if (next.kind != IDENTIFIER_TOKEN) {
        next = IdentifierContext.expressionContinuation
            .ensureIdentifier(token, this);
      }
      token = next;
      next = token.next;
    }
    if (!optional('(', next)) {
      reportRecoverableError(
          token, fasta.templateExpectedAfterButGot.withArguments('('));
      rewriter.insertParens(token, false);
    }
    return parseInitializerExpressionRest(start);
  }

  Token parseInitializerExpressionRest(Token token) {
    token = parseExpression(token);
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
        : template.withArguments(next);
    reportRecoverableError(next, message);
    return insertBlock(token);
  }

  Token insertBlock(Token token) {
    Token next = token.next;
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
    if (openParen.endGroup.isSynthetic) {
      // Scanner has already reported a missing `)` error,
      // but placed the `)` in the wrong location, so move it.
      return rewriter.moveSynthetic(token, openParen.endGroup);
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

  /// If the token after [token] is a not literal string,
  /// then insert a synthetic literal string.
  /// Call `parseLiteralString` and return the result.
  Token ensureLiteralString(Token token) {
    Token next = token.next;
    if (!identical(next.kind, STRING_TOKEN)) {
      Message message = fasta.templateExpectedString.withArguments(next);
      Token newToken =
          new SyntheticStringToken(TokenType.STRING, '""', next.charOffset, 0);
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

    // Find a token on the same line as where the ';' should be inserted.
    // Reporting the error on this token makes it easier
    // for users to understand and fix the error.
    reportRecoverableError(findPreviousNonZeroLengthToken(token),
        fasta.templateExpectedAfterButGot.withArguments(';'));

    return rewriter.insertToken(
        token, new SyntheticToken(TokenType.SEMICOLON, next.charOffset));
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
    // The scanner ensures that `{` always has a closing `}`.
    return ensureBlock(token, fasta.templateExpectedClassBody);
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

  bool isUnaryMinus(Token token) =>
      token.kind == IDENTIFIER_TOKEN &&
      token.lexeme == 'unary' &&
      optional('-', token.next);

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
            varFinalOrConst = token = next;
            next = token.next;
          } else if (optional('var', next)) {
            varFinalOrConst = token = next;
            next = token.next;
          } else if (optional('const', next) && covariantToken == null) {
            varFinalOrConst = token = next;
            next = token.next;
          }
          if (isModifier(next)) {
            ModifierRecoveryContext context = new ModifierRecoveryContext(this);
            token = context.parseClassMemberModifiers(token,
                externalToken: externalToken,
                staticToken: staticToken,
                covariantToken: covariantToken,
                varFinalOrConst: varFinalOrConst);
            next = token.next;

            covariantToken = context.covariantToken;
            externalToken = context.externalToken;
            staticToken = context.staticToken;
            varFinalOrConst = context.varFinalOrConst;

            context = null;
          }
        }
      }
    }

    listener.beginMember();

    Token beforeType = token;
    TypeInfo typeInfo = computeType(token, false, true);
    token = typeInfo.skipType(token);
    next = token.next;

    Token getOrSet;
    if (next.type != TokenType.IDENTIFIER) {
      String value = next.stringValue;
      if (identical(value, 'get') || identical(value, 'set')) {
        if (next.next.isIdentifier) {
          getOrSet = token = next;
          next = token.next;
        }
        // Fall through to continue parsing `get` or `set` as an identifier.
      } else if (identical(value, 'factory')) {
        Token next2 = next.next;
        if (next2.isIdentifier || next2.isModifier) {
          token = parseFactoryMethod(token, beforeStart, externalToken,
              staticToken ?? covariantToken, varFinalOrConst);
          listener.endMember();
          return token;
        }
        // Fall through to continue parsing `factory` as an identifier.
      } else if (identical(value, 'operator')) {
        Token next2 = next.next;
        TypeParamOrArgInfo typeParam = computeTypeParamOrArg(next);
        // `operator` can be used as an identifier as in
        // `int operator<T>()` or `int operator = 2`
        if (next2.isUserDefinableOperator && typeParam == noTypeParamOrArg) {
          token = parseMethod(
              beforeStart,
              externalToken,
              staticToken,
              covariantToken,
              varFinalOrConst,
              beforeType,
              typeInfo,
              getOrSet,
              token.next);
          listener.endMember();
          return token;
        } else if (optional('===', next2) ||
            optional('!==', next2) ||
            (next2.isOperator &&
                !optional('=', next2) &&
                !optional('<', next2))) {
          // Recovery: Invalid operator
          return parseInvalidOperatorDeclaration(beforeStart, externalToken,
              staticToken, covariantToken, varFinalOrConst, beforeType);
        } else if (isUnaryMinus(next2)) {
          // Recovery
          token = parseMethod(
              beforeStart,
              externalToken,
              staticToken,
              covariantToken,
              varFinalOrConst,
              beforeType,
              typeInfo,
              getOrSet,
              token.next);
          listener.endMember();
          return token;
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
            typeInfo,
            getOrSet);
      }
    } else if (typeInfo == noType && varFinalOrConst == null) {
      Token next2 = next.next;
      if (next2.isUserDefinableOperator && next2.endGroup == null) {
        String value = next2.next.stringValue;
        if (identical(value, '(') ||
            identical(value, '{') ||
            identical(value, '=>')) {
          // Recovery: Missing `operator` keyword
          return parseInvalidOperatorDeclaration(beforeStart, externalToken,
              staticToken, covariantToken, varFinalOrConst, beforeType);
        }
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
      token = parseMethod(
          beforeStart,
          externalToken,
          staticToken,
          covariantToken,
          varFinalOrConst,
          beforeType,
          typeInfo,
          getOrSet,
          token.next);
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
          typeInfo,
          token.next,
          false);
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
      TypeInfo typeInfo,
      Token getOrSet,
      Token name) {
    bool isOperator = getOrSet == null && optional('operator', name);

    if (staticToken != null) {
      if (isOperator) {
        reportRecoverableError(staticToken, fasta.messageStaticOperator);
        staticToken = null;
      }
    } else if (covariantToken != null) {
      if (getOrSet == null || optional('get', getOrSet)) {
        reportRecoverableError(covariantToken, fasta.messageCovariantMember);
        covariantToken = null;
      }
    }
    if (varFinalOrConst != null) {
      if (optional('const', varFinalOrConst)) {
        if (getOrSet != null) {
          reportRecoverableErrorWithToken(
              varFinalOrConst, fasta.templateExtraneousModifier);
          varFinalOrConst = null;
        }
      } else if (optional('var', varFinalOrConst)) {
        reportRecoverableError(varFinalOrConst, fasta.messageVarReturnType);
        varFinalOrConst = null;
      } else {
        assert(optional('final', varFinalOrConst));
        reportRecoverableErrorWithToken(
            varFinalOrConst, fasta.templateExtraneousModifier);
        varFinalOrConst = null;
      }
    }

    // TODO(danrubel): Consider parsing the name before calling beginMethod
    // rather than passing the name token into beginMethod.
    listener.beginMethod(
        externalToken, staticToken, covariantToken, varFinalOrConst, name);

    Token token = typeInfo.parseType(beforeType, this);
    assert(token.next == (getOrSet ?? name));
    token = getOrSet ?? token;

    if (isOperator) {
      token = parseOperatorName(token);
    } else {
      token = ensureIdentifier(token, IdentifierContext.methodDeclaration);
      token = parseQualifiedRestOpt(
          token, IdentifierContext.methodDeclarationContinuation);
    }

    bool isGetter = false;
    if (getOrSet == null) {
      token = parseMethodTypeVar(token);
    } else {
      isGetter = optional("get", getOrSet);
      listener.handleNoTypeVariables(token.next);
    }

    MemberKind kind = staticToken != null
        ? MemberKind.StaticMethod
        : MemberKind.NonStaticMethod;
    checkFormals(token, name, isGetter, kind);
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
      token = parseFunctionBody(token, false,
          (staticToken == null || externalToken != null) && inPlainSync);
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
      ModifierRecoveryContext context = new ModifierRecoveryContext(this);
      token = context.parseModifiersAfterFactory(token,
          externalToken: externalToken,
          staticOrCovariant: staticOrCovariant,
          varFinalOrConst: varFinalOrConst);

      externalToken = context.externalToken;
      staticOrCovariant = context.staticToken ?? context.covariantToken;
      varFinalOrConst = context.varFinalOrConst;
    }

    if (staticOrCovariant != null) {
      reportRecoverableErrorWithToken(
          staticOrCovariant, fasta.templateExtraneousModifier);
    }
    if (varFinalOrConst != null && !optional('const', varFinalOrConst)) {
      reportRecoverableErrorWithToken(
          varFinalOrConst, fasta.templateExtraneousModifier);
      varFinalOrConst = null;
    }

    listener.beginFactoryMethod(beforeStart, externalToken, varFinalOrConst);
    token = ensureIdentifier(token, IdentifierContext.methodDeclaration);
    token = parseQualifiedRestOpt(
        token, IdentifierContext.methodDeclarationContinuation);
    token = parseMethodTypeVar(token);
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
        if (optional('const', varFinalOrConst)) {
          reportRecoverableError(varFinalOrConst, fasta.messageConstFactory);
        }
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
      if (computeTypeParamOrArg(token) != noTypeParamOrArg) {
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
    } else if (isUnaryMinus(next)) {
      // Recovery
      reportRecoverableErrorWithToken(next, fasta.templateUnexpectedToken);
      next = next.next;
      listener.handleOperatorName(token, next);
      return next;
    } else {
      // Recovery
      // Scanner reports an error for `===` and `!==`.
      if (next.type != TokenType.EQ_EQ_EQ &&
          next.type != TokenType.BANG_EQ_EQ) {
        // The user has specified an invalid operator name.
        // Report the error, accept the invalid operator name, and move on.
        reportRecoverableErrorWithToken(next, fasta.templateInvalidOperator);
      }
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

  Token parseFunctionLiteral(
      Token start,
      Token beforeName,
      Token name,
      TypeInfo typeInfo,
      TypeParamOrArgInfo typeParam,
      IdentifierContext context) {
    Token formals = typeParam.parseVariables(name, this);
    listener.beginNamedFunctionExpression(start.next);
    typeInfo.parseType(start, this);
    return parseNamedFunctionRest(beforeName, start.next, formals, true);
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
    token = parseFormalParametersRequiredOpt(formals, MemberKind.Local);
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

  Token parseConstructorReference(Token token, [TypeParamOrArgInfo typeArg]) {
    Token start =
        ensureIdentifier(token, IdentifierContext.constructorReference);
    listener.beginConstructorReference(start);
    token = parseQualifiedRestOpt(
        start, IdentifierContext.constructorReferenceContinuation);
    typeArg ??= computeTypeParamOrArg(token);
    token = typeArg.parseArguments(token, this);
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
      // If `return` used instead of `=>`, then report an error and continue
      if (optional('return', next)) {
        reportRecoverableError(next, fasta.messageExpectedBody);
        next = rewriter
            .insertTokenAfter(next,
                new SyntheticToken(TokenType.FUNCTION, next.next.charOffset))
            .next;
        return parseExpressionFunctionBody(next, ofFunctionExpression);
      }
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
    assert(optional('}', token));
    listener.endBlockFunctionBody(statementCount, begin, token);
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
      return recoverFromStackOverflow(token);
    }
    Token result = parseStatementX(token);
    statementDepth--;
    return result;
  }

  Token parseStatementX(Token token) {
    if (identical(token.next.kind, IDENTIFIER_TOKEN)) {
      if (optional(':', token.next.next)) {
        return parseLabeledStatement(token);
      }
      return parseExpressionStatementOrDeclarationAfterModifiers(token, token);
    }
    final value = token.next.stringValue;
    if (identical(value, '{')) {
      return parseBlock(token);
    } else if (identical(value, 'return')) {
      return parseReturnStatement(token);
    } else if (identical(value, 'var') || identical(value, 'final')) {
      Token varOrFinal = token.next;
      if (isModifier(varOrFinal.next)) {
        return parseExpressionStatementOrDeclaration(token);
      } else {
        return parseExpressionStatementOrDeclarationAfterModifiers(
            varOrFinal, token, varOrFinal);
      }
    } else if (identical(value, 'if')) {
      return parseIfStatement(token);
    } else if (identical(value, 'await') && optional('for', token.next.next)) {
      return parseForStatement(token.next, token.next);
    } else if (identical(value, 'for')) {
      return parseForStatement(token, null);
    } else if (identical(value, 'rethrow')) {
      return parseRethrowStatement(token);
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
    } else if (!inPlainSync && identical(value, 'await')) {
      return parseExpressionStatement(token);
    } else if (identical(value, 'set') && token.next.next.isIdentifier) {
      // Recovery: invalid use of `set`
      reportRecoverableErrorWithToken(
          token.next, fasta.templateUnexpectedToken);
      return parseStatementX(token.next);
    } else if (token.next.isIdentifier) {
      if (optional(':', token.next.next)) {
        return parseLabeledStatement(token);
      }
      return parseExpressionStatementOrDeclaration(token);
    } else {
      return parseExpressionStatementOrDeclaration(token);
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

  /// ```
  /// label:
  ///   identifier ':'
  /// ;
  /// ```
  Token parseLabel(Token token) {
    assert(token.next.isIdentifier);
    token = ensureIdentifier(token, IdentifierContext.labelDeclaration).next;
    assert(optional(':', token));
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
    assert(next.isIdentifier);
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

  int expressionDepth = 0;
  Token parseExpression(Token token) {
    if (expressionDepth++ > 500) {
      // This happens in degenerate programs, for example, with a lot of nested
      // list literals. This is provoked by, for example, the language test
      // deep_nesting1_negative_test.
      Token next = token.next;
      reportRecoverableError(next, fasta.messageStackOverflow);

      // Recovery
      Token endGroup = next.endGroup;
      if (endGroup != null) {
        while (!next.isEof && !identical(next, endGroup)) {
          token = next;
          next = token.next;
        }
      } else {
        while (!isOneOf(next, const [')', ']', '}', ';'])) {
          token = next;
          next = token.next;
        }
      }
      if (!token.isEof) {
        token = rewriter.insertSyntheticIdentifier(token);
        listener.handleIdentifier(token, IdentifierContext.expression);
      }
    } else {
      token = optional('throw', token.next)
          ? parseThrowExpression(token, true)
          : parsePrecedenceExpression(token, ASSIGNMENT_PRECEDENCE, true);
    }
    expressionDepth--;
    return token;
  }

  Token parseExpressionWithoutCascade(Token token) {
    return optional('throw', token.next)
        ? parseThrowExpression(token, false)
        : parsePrecedenceExpression(token, ASSIGNMENT_PRECEDENCE, false);
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
    assert(precedence <= SELECTOR_PRECEDENCE);
    token = parseUnaryExpression(token, allowCascades);
    Token next = token.next;
    TokenType type = next.type;
    int tokenLevel = type.precedence;
    Token typeArguments;
    TypeParamOrArgInfo typeArg = computeMethodTypeArguments(token);
    if (typeArg != noTypeParamOrArg) {
      // For example a(b)<T>(c), where token is before '<'.
      typeArguments = next;
      token = typeArg.parseArguments(token, this);
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
          Token next = token.next;
          token = optional('throw', next.next)
              ? parseThrowExpression(next, false)
              : parsePrecedenceExpression(next, level, allowCascades);
          listener.handleAssignmentExpression(operator);
        } else if (identical(tokenLevel, POSTFIX_PRECEDENCE)) {
          if ((identical(type, TokenType.PLUS_PLUS)) ||
              (identical(type, TokenType.MINUS_MINUS))) {
            listener.handleUnaryPostfixAssignmentExpression(token.next);
            token = next;
          }
        } else if (identical(tokenLevel, SELECTOR_PRECEDENCE)) {
          if (identical(type, TokenType.PERIOD) ||
              identical(type, TokenType.QUESTION_PERIOD)) {
            // Left associative, so we recurse at the next higher precedence
            // level. However, SELECTOR_PRECEDENCE is the highest level, so we
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
          } else if (identical(type, TokenType.INDEX)) {
            BeginToken replacement = link(
                new BeginToken(TokenType.OPEN_SQUARE_BRACKET, next.charOffset,
                    next.precedingComments),
                new Token(TokenType.CLOSE_SQUARE_BRACKET, next.charOffset + 1));
            rewriter.replaceTokenFollowing(token, replacement);
            replacement.endToken = replacement.next;
            token = parseArgumentOrIndexStar(token, null);
          } else {
            // Recovery
            reportRecoverableErrorWithToken(
                token.next, fasta.templateUnexpectedToken);
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
      if (optional('.', next) || optional('?.', next)) {
        Token period = next;
        token = parseSend(next, IdentifierContext.expressionContinuation);
        next = token.next;
        listener.endBinaryExpression(period);
      }
      Token typeArguments;
      TypeParamOrArgInfo typeArg = computeMethodTypeArguments(token);
      if (typeArg != noTypeParamOrArg) {
        // For example a(b)..<T>(c), where token is '<'.
        typeArguments = next;
        token = typeArg.parseArguments(token, this);
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
    } else if (token.next.isIdentifier) {
      Token identifier = token.next;
      if (optional(".", identifier.next)) {
        identifier = identifier.next.next;
      }
      if (identifier.isIdentifier) {
        // Looking at `identifier ('.' identifier)?`.
        if (optional("<", identifier.next)) {
          TypeParamOrArgInfo typeArg = computeTypeParamOrArg(identifier);
          if (typeArg != noTypeParamOrArg) {
            Token endTypeArguments = typeArg.skip(identifier);
            if (optional(".", endTypeArguments.next)) {
              return parseImplicitCreationExpression(token, typeArg);
            }
          }
        }
      }
    }
    return parsePrimary(token, IdentifierContext.expression);
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
          listener.handleNoTypeArguments(next);
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
      } else if (identical(value, "return")) {
        // Recovery
        token = token.next;
        reportRecoverableErrorWithToken(token, fasta.templateUnexpectedToken);
        return parsePrimary(token, context);
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
        reportErrorToken(token);
        token = token.next;
      } while (token is ErrorToken);
      return parsePrimary(previous, context);
    } else {
      return parseSend(token, context);
    }
  }

  Token parseParenthesizedExpressionOrFunctionLiteral(Token token) {
    Token next = token.next;
    assert(optional('(', next));
    Token nextToken = next.endGroup.next;
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

  Token parseParenthesizedCondition(Token token) {
    if (!optional('(', token.next)) {
      // Recover
      Token next = token.next;
      reportRecoverableError(
          next, fasta.templateExpectedToken.withArguments('('));
      rewriter.insertParens(token, false);
    }
    Token begin = token.next;
    token = parseExpressionInParenthesis(token);
    listener.handleParenthesizedCondition(begin);
    return token;
  }

  Token parseParenthesizedExpression(Token token) {
    Token begin = token.next;
    token = parseExpressionInParenthesis(token);
    listener.handleParenthesizedExpression(begin);
    return token;
  }

  Token parseExpressionInParenthesis(Token token) {
    token = token.next;
    assert(optional('(', token));
    BeginToken begin = token;
    token = parseExpression(token);
    token = ensureCloseParen(token, begin);
    assert(optional(')', token));
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
    if (optional('[]', token)) {
      token = rewriteSquareBrackets(beforeToken).next;
      listener.handleLiteralList(0, token, constKeyword, token.next);
      return token.next;
    }
    bool old = mayParseFunctionExpressions;
    mayParseFunctionExpressions = true;
    while (true) {
      Token next = token.next;
      if (optional(']', next)) {
        token = next;
        break;
      }
      token = parseExpression(token);
      next = token.next;
      ++count;
      if (!optional(',', next)) {
        if (optional(']', next)) {
          token = next;
          break;
        }

        // Recovery
        if (!looksLikeExpressionStart(next)) {
          if (beginToken.endGroup.isSynthetic) {
            // The scanner has already reported an error,
            // but inserted `]` in the wrong place.
            token = rewriter.moveSynthetic(token, beginToken.endGroup);
          } else {
            // Report an error and jump to the end of the list.
            reportRecoverableError(
                next, fasta.templateExpectedButGot.withArguments(']'));
            token = beginToken.endGroup;
          }
          break;
        }
        // This looks like the start of an expression.
        // Report an error, insert the comma, and continue parsing.
        next = rewriteAndRecover(
                token,
                fasta.templateExpectedButGot.withArguments(','),
                new SyntheticToken(TokenType.COMMA, next.offset))
            .next;
      }
      token = next;
    }
    mayParseFunctionExpressions = old;
    listener.handleLiteralList(count, beginToken, constKeyword, token);
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
        if (looksLikeExpressionStart(next)) {
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
    assert(optional('(', token.next));
    // Scanner ensures `(` has matching `)`.
    Token next = token.next.endGroup.next;
    int kind = next.kind;
    if (!identical(kind, FUNCTION_TOKEN) &&
        !identical(kind, OPEN_CURLY_BRACKET_TOKEN) &&
        (!identical(kind, KEYWORD_TOKEN) ||
            !optional('async', next) && !optional('sync', next))) {
      reportRecoverableErrorWithToken(next, fasta.templateUnexpectedToken);
    }
    return parseFunctionExpression(token);
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
  Token parseLiteralListOrMapOrFunction(final Token start, Token constKeyword) {
    assert(optional('<', start.next));
    TypeParamOrArgInfo typeParamOrArg = computeTypeParamOrArg(start, true);
    Token token = typeParamOrArg.skip(start);
    Token next = token.next;
    if (optional('(', next)) {
      if (constKeyword != null) {
        reportRecoverableErrorWithToken(
            constKeyword, fasta.templateUnexpectedToken);
      }
      token = typeParamOrArg.parseVariables(start, this);
      return parseLiteralFunctionSuffix(token);
    }
    token = typeParamOrArg.parseArguments(start, this);
    if (optional('{', next)) {
      return parseLiteralMapSuffix(token, constKeyword);
    }
    if (!optional('[', next) && !optional('[]', next)) {
      // TODO(danrubel): Improve this error message.
      reportRecoverableError(
          next, fasta.templateExpectedButGot.withArguments('['));
      rewriter.insertTokenAfter(
          token, new SyntheticToken(TokenType.INDEX, next.charOffset));
    }
    return parseLiteralListSuffix(token, constKeyword);
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
    }
    TypeInfo typeInfo = computeType(token, false);
    Token beforeName = typeInfo.skipType(token);
    Token name = beforeName.next;
    if (name.isIdentifier) {
      TypeParamOrArgInfo typeParam = computeTypeParamOrArg(name);
      Token next = name;
      if (typeParam != noTypeParamOrArg) {
        next = typeParam.skip(next);
      }
      next = next.next;
      if (optional('(', next)) {
        if (looksLikeFunctionBody(next.endGroup.next)) {
          return parseFunctionLiteral(
              token, beforeName, name, typeInfo, typeParam, context);
        }
      }
    }
    return parseSend(token, context);
  }

  Token parseRequiredArguments(Token token) {
    Token next = token.next;
    if (!optional('(', next)) {
      reportRecoverableError(
          token, fasta.templateExpectedButGot.withArguments('('));
      rewriter.insertParens(token, false);
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

  Token parseImplicitCreationExpression(
      Token token, TypeParamOrArgInfo typeArg) {
    Token begin = token;
    listener.beginImplicitCreationExpression(token);
    token = parseConstructorReference(token, typeArg);
    token = parseRequiredArguments(token);
    listener.endImplicitCreationExpression(begin);
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
    TypeParamOrArgInfo typeArg = computeMethodTypeArguments(token);
    if (typeArg != noTypeParamOrArg) {
      token = typeArg.parseArguments(token, this);
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
      return next.endGroup;
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
        if (looksLikeExpressionStart(next)) {
          // If this looks like the start of an expression,
          // then report an error, insert the comma, and continue parsing.
          next = rewriteAndRecover(
                  token,
                  fasta.templateExpectedButGot.withArguments(','),
                  new SyntheticToken(TokenType.COMMA, next.offset))
              .next;
        } else {
          token = ensureCloseParen(token, begin);
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
    token = computeType(token, true).ensureTypeNotVoid(token, this);
    listener.handleIsOperator(operator, not);
    return skipChainedAsIsOperators(token);
  }

  /// ```
  /// typeCast:
  ///   'as' type
  /// ;
  /// ```
  Token parseAsOperatorRest(Token token) {
    Token operator = token = token.next;
    assert(optional('as', operator));
    token = computeType(token, true).ensureTypeNotVoid(token, this);
    listener.handleAsOperator(operator);
    return skipChainedAsIsOperators(token);
  }

  Token skipChainedAsIsOperators(Token token) {
    while (true) {
      Token next = token.next;
      String value = next.stringValue;
      if (!identical(value, 'is') && !identical(value, 'as')) {
        return token;
      }
      // The is- and as-operators cannot be chained.
      // TODO(danrubel): Consider a better error message.
      reportRecoverableErrorWithToken(next, fasta.templateUnexpectedToken);
      if (optional('!', next.next)) {
        next = next.next;
      }
      token = computeType(next, true).skipType(next);
      next = token.next;
      value = next.stringValue;
    }
  }

  /// Returns true if [token] could be the start of a function declaration
  /// without a return type.
  bool looksLikeLocalFunction(Token token) {
    if (token.isIdentifier) {
      if (optional('<', token.next)) {
        TypeParamOrArgInfo typeParam = computeTypeParamOrArg(token);
        if (typeParam == noTypeParamOrArg) {
          return false;
        }
        token = typeParam.skip(token);
      }
      token = token.next;
      if (optional('(', token)) {
        token = token.endGroup.next;
        return optional('{', token) ||
            optional('=>', token) ||
            optional('async', token) ||
            optional('sync', token);
      } else if (optional('=>', token)) {
        // Recovery: Looks like a local function that is missing parenthesis.
        return true;
      }
    }
    return false;
  }

  /// Returns true if [token] could be the start of a function body.
  bool looksLikeFunctionBody(Token token) {
    return optional('{', token) ||
        optional('=>', token) ||
        optional('async', token) ||
        optional('sync', token);
  }

  Token parseExpressionStatementOrConstDeclaration(final Token start) {
    Token constToken = start.next;
    assert(optional('const', constToken));
    if (!isModifier(constToken.next)) {
      TypeInfo typeInfo = computeType(constToken, false);
      if (typeInfo == noType) {
        Token next = constToken.next;
        if (!next.isIdentifier) {
          return parseExpressionStatement(start);
        }
        next = next.next;
        if (!(optional('=', next) ||
            // Recovery
            next.isKeywordOrIdentifier ||
            optional(';', next) ||
            optional(',', next) ||
            optional('{', next))) {
          return parseExpressionStatement(start);
        }
      }
      return parseExpressionStatementOrDeclarationAfterModifiers(
          constToken, start, constToken, typeInfo);
    }
    return parseExpressionStatementOrDeclaration(start);
  }

  /// This method has two modes based upon [onlyParseVariableDeclarationStart].
  ///
  /// If [onlyParseVariableDeclarationStart] is `false` (the default) then this
  /// method will parse a local variable declaration, a local function,
  /// or an expression statement, and then return the last consumed token.
  ///
  /// If [onlyParseVariableDeclarationStart] is `true` then this method
  /// will only parse the metadata, modifiers, and type of a local variable
  /// declaration if it exists. It is the responsibility of the caller to
  /// call [parseVariablesDeclarationRest] to finish parsing the local variable
  /// declaration. If a local variable declaration is not found then this
  /// method will return [start].
  Token parseExpressionStatementOrDeclaration(final Token start,
      [bool onlyParseVariableDeclarationStart = false]) {
    Token token = start;
    Token next = token.next;
    if (optional('@', next)) {
      token = parseMetadataStar(token);
      next = token.next;
    }

    Token varFinalOrConst;
    if (isModifier(next)) {
      if (optional('var', next)) {
        varFinalOrConst = token = token.next;
        next = token.next;
      } else if (optional('final', next) || optional('const', next)) {
        varFinalOrConst = token = token.next;
        next = token.next;
      }

      if (isModifier(next)) {
        // Recovery
        ModifierRecoveryContext modifierContext =
            new ModifierRecoveryContext(this);
        token = modifierContext.parseVariableDeclarationModifiers(token,
            varFinalOrConst: varFinalOrConst);
        next = token.next;

        varFinalOrConst = modifierContext.varFinalOrConst;
        modifierContext = null;
      }
    }

    return parseExpressionStatementOrDeclarationAfterModifiers(
        token, start, varFinalOrConst, null, onlyParseVariableDeclarationStart);
  }

  /// See [parseExpressionStatementOrDeclaration]
  Token parseExpressionStatementOrDeclarationAfterModifiers(
      final Token beforeType, final Token start,
      [Token varFinalOrConst = null,
      TypeInfo typeInfo,
      bool onlyParseVariableDeclarationStart = false]) {
    typeInfo ??= computeType(beforeType, false);
    Token token = typeInfo.skipType(beforeType);
    Token next = token.next;

    if (!onlyParseVariableDeclarationStart) {
      if (looksLikeLocalFunction(next)) {
        // Parse a local function declaration.
        if (varFinalOrConst != null) {
          reportRecoverableErrorWithToken(
              varFinalOrConst, fasta.templateExtraneousModifier);
        }
        if (!optional('@', start.next)) {
          listener.beginMetadataStar(start.next);
          listener.endMetadataStar(0);
        }
        Token beforeFormals =
            computeTypeParamOrArg(next).parseVariables(next, this);
        listener.beginLocalFunctionDeclaration(start.next);
        token = typeInfo.parseType(beforeType, this);
        next = token.next;
        return parseNamedFunctionRest(token, start.next, beforeFormals, false);
      }
    }

    if (token == start) {
      // If no annotation, modifier, or type, and this is not a local function
      // then this must be an expression statement.
      if (onlyParseVariableDeclarationStart) {
        return start;
      } else {
        return parseExpressionStatement(start);
      }
    }
    if (next.type.isBuiltIn &&
        beforeType == start &&
        typeInfo.couldBeExpression) {
      // Detect expressions such as identifier `as` identifier
      // and treat those as expressions.
      if (optional('as', next) || optional('is', next)) {
        int kind = next.next.kind;
        if (EQ_TOKEN != kind &&
            SEMICOLON_TOKEN != kind &&
            COMMA_TOKEN != kind) {
          if (onlyParseVariableDeclarationStart) {
            if (!optional('in', next.next)) {
              return start;
            }
          } else {
            return parseExpressionStatement(start);
          }
        }
      }
    }

    if (next.isIdentifier) {
      // Only report these errors if there is an identifier. If there is not an
      // identifier, then allow ensureIdentifier to report an error
      // and don't report errors here.
      if (varFinalOrConst == null) {
        if (typeInfo == noType) {
          reportRecoverableError(next, fasta.messageMissingConstFinalVarOrType);
        }
      } else if (optional('var', varFinalOrConst)) {
        if (typeInfo != noType) {
          reportRecoverableError(varFinalOrConst, fasta.messageTypeAfterVar);
        }
      }
    }

    if (!optional('@', start.next)) {
      listener.beginMetadataStar(start.next);
      listener.endMetadataStar(0);
    }
    token = typeInfo.parseType(beforeType, this);
    next = token.next;
    listener.beginVariablesDeclaration(next, varFinalOrConst);
    if (!onlyParseVariableDeclarationStart) {
      token = parseVariablesDeclarationRest(token, true);
    }
    return token;
  }

  Token parseVariablesDeclarationRest(Token token, bool endWithSemicolon) {
    int count = 1;
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
    token = parseParenthesizedCondition(ifToken);
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
  ///
  /// forInitializerStatement:
  ///   localVariableDeclaration |
  ///   expression? ';'
  /// ;
  /// ```
  Token parseForStatement(Token token, Token awaitToken) {
    Token forKeyword = token = token.next;
    assert(awaitToken == null || optional('await', awaitToken));
    assert(optional('for', token));
    listener.beginForStatement(forKeyword);

    Token leftParenthesis = forKeyword.next;
    if (!optional('(', leftParenthesis)) {
      // Recovery
      reportRecoverableError(
          leftParenthesis, fasta.templateExpectedButGot.withArguments('('));
      int offset = leftParenthesis.offset;

      BeginToken openParen =
          token.setNext(new SyntheticBeginToken(TokenType.OPEN_PAREN, offset));

      Token loopPart;
      if (awaitToken != null) {
        loopPart = openParen.setNext(
            new SyntheticStringToken(TokenType.IDENTIFIER, '', offset));
        loopPart =
            loopPart.setNext(new SyntheticKeywordToken(Keyword.IN, offset));
        loopPart = loopPart.setNext(
            new SyntheticStringToken(TokenType.IDENTIFIER, '', offset));
      } else {
        loopPart =
            openParen.setNext(new SyntheticToken(TokenType.SEMICOLON, offset));
        loopPart =
            loopPart.setNext(new SyntheticToken(TokenType.SEMICOLON, offset));
      }

      Token closeParen =
          loopPart.setNext(new SyntheticToken(TokenType.CLOSE_PAREN, offset));
      openParen.endGroup = closeParen;
      Token identifier = closeParen
          .setNext(new SyntheticStringToken(TokenType.IDENTIFIER, '', offset));
      Token semicolon =
          identifier.setNext(new SyntheticToken(TokenType.SEMICOLON, offset));
      semicolon.setNext(leftParenthesis);

      leftParenthesis = openParen;
    }
    token = leftParenthesis;

    // Pass `true` so that the [parseExpressionStatementOrDeclaration] only
    // parses the metadata, modifiers, and type of a local variable
    // declaration if it exists. This enables capturing [beforeIdentifier]
    // for later error reporting.
    token = parseExpressionStatementOrDeclaration(token, true);
    Token beforeIdentifier = token;

    // Parse the remainder of the local variable declaration
    // or an expression if no local variable declaration was found.
    if (token != leftParenthesis) {
      token = parseVariablesDeclarationRest(token, false);
    } else if (optional(';', token.next)) {
      listener.handleNoExpression(token.next);
    } else {
      token = parseExpression(token);
    }

    Token next = token.next;
    if (!optional('in', next)) {
      if (optional(':', next)) {
        // Recovery
        reportRecoverableError(next, fasta.messageColonInPlaceOfIn);
        // Fall through to process `for ( ... in ... )`
      } else if (awaitToken == null || optional(';', next)) {
        // Process `for ( ... ; ... ; ... )`
        if (awaitToken != null) {
          reportRecoverableError(awaitToken, fasta.messageInvalidAwaitFor);
        }
        return parseForRest(token, forKeyword, leftParenthesis);
      } else {
        // Recovery
        reportRecoverableError(
            next, fasta.templateExpectedButGot.withArguments('in'));
        next = token.setNext(
            new SyntheticKeywordToken(Keyword.IN, next.offset)..setNext(next));
      }
    }

    // Process `for ( ... in ... )`
    Token identifier = beforeIdentifier.next;
    if (!identifier.isIdentifier) {
      reportRecoverableErrorWithToken(
          identifier, fasta.templateExpectedIdentifier);
    } else if (identifier != token) {
      if (optional('=', identifier.next)) {
        reportRecoverableError(
            identifier.next, fasta.messageInitializedVariableInForEach);
      } else {
        reportRecoverableErrorWithToken(
            identifier.next, fasta.templateUnexpectedToken);
      }
    } else if (awaitToken != null && !inAsync) {
      reportRecoverableError(next, fasta.messageAwaitForNotAsync);
    }
    return parseForInRest(token, awaitToken, forKeyword, leftParenthesis);
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
  Token parseForRest(Token token, Token forToken, Token leftParenthesis) {
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
    if (token != leftParenthesis.endGroup) {
      reportRecoverableErrorWithToken(token, fasta.templateUnexpectedToken);
      token = leftParenthesis.endGroup;
    }
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
      Token token, Token awaitToken, Token forKeyword, Token leftParenthesis) {
    Token inKeyword = token.next;
    assert(optional('in', inKeyword) || optional(':', inKeyword));
    listener.beginForInExpression(inKeyword.next);
    token = parseExpression(inKeyword);
    token = ensureCloseParen(token, leftParenthesis);
    listener.endForInExpression(token);
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
    token = parseParenthesizedCondition(whileToken);
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
    token = parseStatement(doToken);
    loopState = savedLoopState;
    listener.endDoWhileStatementBody(token);
    Token whileToken = token.next;
    if (!optional('while', whileToken)) {
      reportRecoverableError(
          whileToken, fasta.templateExpectedButGot.withArguments('while'));
      whileToken = rewriter
          .insertTokenAfter(token,
              new SyntheticKeywordToken(Keyword.WHILE, whileToken.charOffset))
          .next;
    }
    token = parseParenthesizedCondition(whileToken);
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
    Token startToken = token.next;
    while (notEofOrValue('}', startToken)) {
      token = parseStatement(token);
      if (identical(token.next, startToken)) {
        // No progress was made, so we report the current token as being invalid
        // and move forward.
        token = token.next;
        reportRecoverableError(
            token, fasta.templateUnexpectedToken.withArguments(token));
      }
      ++statementCount;
      startToken = token.next;
    }
    token = token.next;
    assert(optional('}', token));
    listener.endBlock(statementCount, begin, token);
    return token;
  }

  Token parseInvalidBlock(Token token) {
    Token begin = token.next;
    assert(optional('{', begin));
    // Parse and report the invalid block, but suppress errors
    // because an error has already been reported by the caller.
    Listener originalListener = listener;
    listener = new ForwardingListener(listener)..forwardErrors = false;
    token = parseBlock(token);
    listener = originalListener;
    listener.handleInvalidTopLevelBlock(begin);
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
    if (optional(';', throwToken.next)) {
      // TODO(danrubel): Find a better way to intercept the parseExpression
      // recovery to generate this error message rather than explicitly
      // checking the next token as we are doing here.
      reportRecoverableError(
          throwToken.next, fasta.messageMissingExpressionInThrow);
      rewriter.insertTokenAfter(
          throwToken,
          new SyntheticStringToken(
              TokenType.STRING, '""', throwToken.next.charOffset, 0));
    }
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
    assert(optional('rethrow', throwToken));
    listener.beginRethrowStatement(throwToken);
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
        lastConsumed = computeType(token, true).ensureTypeNotVoid(token, this);
        token = lastConsumed.next;
        value = token.stringValue;
      }
      Token catchKeyword = null;
      Token comma = null;
      if (identical(value, 'catch')) {
        catchKeyword = token;

        Token openParens = catchKeyword.next;
        if (!optional("(", openParens)) {
          reportRecoverableError(openParens, fasta.messageCatchSyntax);
          openParens = rewriter.insertParens(catchKeyword, true);
        }

        Token exceptionName = openParens.next;
        if (exceptionName.kind != IDENTIFIER_TOKEN) {
          exceptionName = IdentifierContext.catchParameter
              .ensureIdentifier(openParens, this);
        }

        if (optional(")", exceptionName.next)) {
          // OK: `catch (identifier)`.
        } else {
          comma = exceptionName.next;
          if (!optional(",", comma)) {
            // Recovery
            if (!exceptionName.isSynthetic) {
              reportRecoverableError(comma, fasta.messageCatchSyntax);
            }

            // TODO(danrubel): Consider inserting `on` clause if
            // exceptionName is preceded by type and followed by a comma.
            // Then this
            //   } catch (E e, t) {
            // will recover to
            //   } on E catch (e, t) {
            // with a detailed explaination for the user in the error
            // indicating what they should do to fix the code.

            // TODO(danrubel): Consider inserting synthetic identifier if
            // exceptionName is a non-synthetic identifier followed by `.`.
            // Then this
            //   } catch (
            //   e.f();
            // will recover to
            //   } catch (_s_) {}
            //   e.f();
            // rather than
            //   } catch (e) {}
            //   _s_.f();

            if (openParens.endGroup.isSynthetic) {
              // The scanner did not place the synthetic ')' correctly.
              rewriter.moveSynthetic(exceptionName, openParens.endGroup);
              comma = null;
            } else {
              comma = rewriter.insertToken(exceptionName,
                  new SyntheticToken(TokenType.COMMA, comma.charOffset));
            }
          }
          if (comma != null) {
            Token traceName = comma.next;
            if (traceName.kind != IDENTIFIER_TOKEN) {
              traceName = IdentifierContext.catchParameter
                  .ensureIdentifier(comma, this);
            }
            if (!optional(")", traceName.next)) {
              // Recovery
              if (!traceName.isSynthetic) {
                reportRecoverableError(exceptionName, fasta.messageCatchSyntax);
              }
              if (openParens.endGroup.isSynthetic) {
                // The scanner did not place the synthetic ')' correctly.
                rewriter.moveSynthetic(traceName, openParens.endGroup);
              }
            }
          }
        }
        lastConsumed = parseFormalParameters(catchKeyword, MemberKind.Catch);
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
    token = parseParenthesizedCondition(switchKeyword);
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
    token = token.next;
    assert(optional('assert', token));
    listener.beginAssert(token, kind);
    Token assertKeyword = token;
    Token leftParenthesis = token.next;
    if (!optional('(', leftParenthesis)) {
      // Recovery
      reportRecoverableError(
          leftParenthesis, fasta.templateExpectedButGot.withArguments('('));
      leftParenthesis = rewriter.insertParens(token, true);
    }
    token = leftParenthesis;
    Token commaToken = null;
    bool old = mayParseFunctionExpressions;
    mayParseFunctionExpressions = true;

    token = parseExpression(token);
    if (optional(',', token.next)) {
      token = token.next;
      if (!optional(')', token.next)) {
        commaToken = token;
        token = parseExpression(token);
        if (optional(',', token.next)) {
          // Trailing comma is ignored.
          token = token.next;
        }
      }
    }

    Token endGroup = leftParenthesis.endGroup;
    if (token.next == endGroup) {
      token = endGroup;
    } else {
      // Recovery
      if (endGroup.isSynthetic) {
        // The scanner did not place the synthetic ')' correctly, so move it.
        token = rewriter.moveSynthetic(token, endGroup);
      } else {
        reportRecoverableErrorWithToken(
            token.next, fasta.templateUnexpectedToken);
        token = endGroup;
      }
    }

    assert(optional(')', token));
    mayParseFunctionExpressions = old;
    if (kind == Assert.Expression) {
      reportRecoverableError(assertKeyword, fasta.messageAssertAsExpression);
    } else if (kind == Assert.Statement) {
      ensureSemicolon(token);
    }
    listener.endAssert(
        assertKeyword, kind, leftParenthesis, commaToken, token.next);
    return token;
  }

  /// ```
  /// assertStatement:
  ///   assertion ';'
  /// ;
  /// ```
  Token parseAssertStatement(Token token) {
    assert(optional('assert', token.next));
    // parseAssert ensures that there is a trailing semicolon.
    return parseAssert(token, Assert.Statement).next;
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

  /// Recover from finding an operator declaration missing the `operator`
  /// keyword. The metadata for the member, if any, has already been parsed
  /// (and events have already been generated).
  Token parseInvalidOperatorDeclaration(
      Token beforeStart,
      Token externalToken,
      Token staticToken,
      Token covariantToken,
      Token varFinalOrConst,
      Token beforeType) {
    TypeInfo typeInfo = computeType(beforeType, true, true);

    Token beforeName = typeInfo.skipType(beforeType);
    Token next = beforeName.next;

    if (optional('operator', next)) {
      next = next.next;
    } else {
      reportRecoverableError(next, fasta.messageMissingOperatorKeyword);
      rewriter.insertTokenAfter(
          beforeName, new SyntheticToken(Keyword.OPERATOR, next.offset));
    }

    assert((next.isOperator && next.endGroup == null) ||
        optional('===', next) ||
        optional('!==', next));

    Token token = parseMethod(
        beforeStart,
        externalToken,
        staticToken,
        covariantToken,
        varFinalOrConst,
        beforeType,
        typeInfo,
        null,
        beforeName.next);
    listener.endMember();
    return token;
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
      TypeInfo typeInfo,
      Token getOrSet) {
    Token next = token.next;
    String value = next.stringValue;

    if (identical(value, 'class')) {
      return reportAndSkipClassInClass(next);
    } else if (identical(value, 'enum')) {
      return reportAndSkipEnumInClass(next);
    } else if (identical(value, 'typedef')) {
      return reportAndSkipTypedefInClass(next);
    } else if (next.isOperator && next.endGroup == null) {
      return parseInvalidOperatorDeclaration(beforeStart, externalToken,
          staticToken, covariantToken, varFinalOrConst, beforeType);
    }

    if (getOrSet != null ||
        identical(value, '(') ||
        identical(value, '=>') ||
        identical(value, '{')) {
      token = parseMethod(
          beforeStart,
          externalToken,
          staticToken,
          covariantToken,
          varFinalOrConst,
          beforeType,
          typeInfo,
          getOrSet,
          token.next);
    } else if (token == beforeStart) {
      // TODO(danrubel): Provide a more specific error message for extra ';'.
      reportRecoverableErrorWithToken(next, fasta.templateExpectedClassMember);
      listener.handleInvalidMember(next);
      if (!identical(value, '}')) {
        // Ensure we make progress.
        token = next;
      }
    } else {
      token = parseFields(
          beforeStart,
          externalToken,
          staticToken,
          covariantToken,
          varFinalOrConst,
          beforeType,
          typeInfo,
          token.next,
          false);
    }

    listener.endMember();
    return token;
  }

  /// Report that the nesting depth of the code being parsed is too large for
  /// the parser to safely handle. Return the next `}` or EOF.
  Token recoverFromStackOverflow(Token token) {
    Token next = token.next;
    reportRecoverableError(next, fasta.messageStackOverflow);

    next = new SyntheticToken(TokenType.SEMICOLON, token.offset);
    rewriter.insertTokenAfter(token, next);
    listener.handleEmptyStatement(next);

    while (notEofOrValue('}', next)) {
      token = next;
      next = token.next;
    }
    return token;
  }

  void reportRecoverableError(Token token, Message message) {
    if (token is ErrorToken) {
      reportErrorToken(token);
    } else {
      // Find a non-synthetic token on which to report the error.
      token = findNonZeroLengthToken(token);
      listener.handleRecoverableError(message, token, token);
    }
  }

  void reportRecoverableErrorWithToken(
      Token token, Template<_MessageWithArgument<Token>> template) {
    if (token is ErrorToken) {
      reportErrorToken(token);
    } else {
      // Find a non-synthetic token on which to report the error.
      token = findNonZeroLengthToken(token);
      listener.handleRecoverableError(
          template.withArguments(token), token, token);
    }
  }

  void reportErrorToken(ErrorToken token) {
    listener.handleRecoverableError(token.assertionMessage, token, token);
  }

  Token parseInvalidTopLevelDeclaration(Token token) {
    Token next = token.next;
    reportRecoverableErrorWithToken(
        next,
        optional(';', next)
            ? fasta.templateUnexpectedToken
            : fasta.templateExpectedDeclaration);
    if (optional('{', next)) {
      next = parseInvalidBlock(token);
    }
    listener.handleInvalidTopLevelDeclaration(next);
    return next;
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
    beginToken.setNext(endToken);
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

  /// Return the first dartdoc comment token preceding the given token
  /// or `null` if no dartdoc token is found.
  Token findDartDoc(Token token) {
    Token comments = token.precedingComments;
    Token dartdoc = null;
    bool isMultiline = false;
    while (comments != null) {
      String lexeme = comments.lexeme;
      if (lexeme.startsWith('///')) {
        if (!isMultiline) {
          dartdoc = comments;
          isMultiline = true;
        }
      } else if (lexeme.startsWith('/**')) {
        dartdoc = comments;
        isMultiline = false;
      }
      comments = comments.next;
    }
    return dartdoc;
  }

  /// Parse the comment references in a sequence of comment tokens
  /// where [dartdoc] (not null) is the first token in the sequence.
  /// Return the number of comment references parsed.
  int parseCommentReferences(Token dartdoc) {
    return dartdoc.lexeme.startsWith('///')
        ? parseReferencesInSingleLineComments(dartdoc)
        : parseReferencesInMultiLineComment(dartdoc);
  }

  /// Parse the comment references in a multi-line comment token.
  /// Return the number of comment references parsed.
  int parseReferencesInMultiLineComment(Token multiLineDoc) {
    String comment = multiLineDoc.lexeme;
    assert(comment.startsWith('/**'));
    int count = 0;
    int length = comment.length;
    int start = 3;
    bool inCodeBlock = false;
    int codeBlock = comment.indexOf('```', 3);
    if (codeBlock == -1) {
      codeBlock = length;
    }
    while (start < length) {
      if (isWhitespace(comment.codeUnitAt(start))) {
        ++start;
        continue;
      }
      int end = comment.indexOf('\n', start);
      if (end == -1) {
        end = length;
      }
      if (codeBlock < end) {
        inCodeBlock = !inCodeBlock;
        codeBlock = comment.indexOf('```', end);
        if (codeBlock == -1) {
          codeBlock = length;
        }
      }
      if (!inCodeBlock && !comment.startsWith('*     ', start)) {
        count += parseCommentReferencesInText(multiLineDoc, start, end);
      }
      start = end + 1;
    }
    return count;
  }

  /// Parse the comment references in a sequence of single line comment tokens
  /// where [token] is the first comment token in the sequence.
  /// Return the number of comment references parsed.
  int parseReferencesInSingleLineComments(Token token) {
    int count = 0;
    bool inCodeBlock = false;
    while (token != null && !token.isEof) {
      String comment = token.lexeme;
      if (comment.startsWith('///')) {
        if (comment.indexOf('```', 3) != -1) {
          inCodeBlock = !inCodeBlock;
        }
        if (!inCodeBlock && !comment.startsWith('///    ')) {
          count += parseCommentReferencesInText(token, 3, comment.length);
        }
      }
      token = token.next;
    }
    return count;
  }

  /// Parse the comment references in the text between [start] inclusive
  /// and [end] exclusive. Return a count indicating how many were parsed.
  int parseCommentReferencesInText(Token commentToken, int start, int end) {
    String comment = commentToken.lexeme;
    int count = 0;
    int index = start;
    while (index < end) {
      int ch = comment.codeUnitAt(index);
      if (ch == 0x5B /* `[` */) {
        ++index;
        if (index < end && comment.codeUnitAt(index) == 0x3A /* `:` */) {
          // Skip old-style code block.
          index = comment.indexOf(':]', index + 1) + 1;
          if (index == 0 || index > end) {
            break;
          }
        } else {
          int referenceStart = index;
          index = comment.indexOf(']', index);
          if (index == -1 || index >= end) {
            // Recovery: terminating ']' is not typed yet.
            index = findReferenceEnd(comment, referenceStart, end);
          }
          if (ch != 0x27 /* `'` */ && ch != 0x22 /* `"` */) {
            if (isLinkText(comment, index)) {
              // TODO(brianwilkerson) Handle the case where there's a library
              // URI in the link text.
            } else {
              listener.handleCommentReferenceText(
                  comment.substring(referenceStart, index),
                  commentToken.charOffset + referenceStart);
              ++count;
            }
          }
        }
      } else if (ch == 0x60 /* '`' */) {
        // Skip inline code block if there is both starting '`' and ending '`'
        int endCodeBlock = comment.indexOf('`', index + 1);
        if (endCodeBlock != -1 && endCodeBlock < end) {
          index = endCodeBlock;
        }
      }
      ++index;
    }
    return count;
  }

  /// Given a comment reference without a closing `]`,
  /// search for a possible place where `]` should be.
  int findReferenceEnd(String comment, int index, int end) {
    // Find the end of the identifier if there is one
    if (index >= end || !isLetter(comment.codeUnitAt(index))) {
      return index;
    }
    while (index < end && isLetterOrDigit(comment.codeUnitAt(index))) {
      ++index;
    }

    // Check for a trailing `.`
    if (index >= end || comment.codeUnitAt(index) != 0x2E /* `.` */) {
      return index;
    }
    ++index;

    // Find end of the identifier after the `.`
    if (index >= end || !isLetter(comment.codeUnitAt(index))) {
      return index;
    }
    ++index;
    while (index < end && isLetterOrDigit(comment.codeUnitAt(index))) {
      ++index;
    }
    return index;
  }

  /// Parse the tokens in a single comment reference and generate either a
  /// `handleCommentReference` or `handleNoCommentReference` event.
  /// Return `true` if a comment reference was successfully parsed.
  bool parseOneCommentReference(Token token, int referenceOffset) {
    Token begin = token;
    Token newKeyword = null;
    if (optional('new', token)) {
      newKeyword = token;
      token = token.next;
    }
    Token prefix, period;
    if (token.isIdentifier && optional('.', token.next)) {
      prefix = token;
      period = token.next;
      token = period.next;
    }
    if (token.isEof) {
      // Recovery: Insert a synthetic identifier for code completion
      token = rewriter.insertSyntheticIdentifier(
          period ?? newKeyword ?? syntheticPreviousToken(token));
      if (begin == token.next) {
        begin = token;
      }
    }
    Token operatorKeyword = null;
    if (optional('operator', token)) {
      operatorKeyword = token;
      token = token.next;
    }
    if (token.isUserDefinableOperator) {
      if (token.next.isEof) {
        parseOneCommentReferenceRest(
            begin, referenceOffset, newKeyword, prefix, period, token);
        return true;
      }
    } else {
      token = operatorKeyword ?? token;
      if (token.next.isEof) {
        if (token.isIdentifier) {
          parseOneCommentReferenceRest(
              begin, referenceOffset, newKeyword, prefix, period, token);
          return true;
        }
        Keyword keyword = token.keyword;
        if (newKeyword == null &&
            prefix == null &&
            (keyword == Keyword.THIS ||
                keyword == Keyword.NULL ||
                keyword == Keyword.TRUE ||
                keyword == Keyword.FALSE)) {
          // TODO(brianwilkerson) If we want to support this we will need to
          // extend the definition of CommentReference to take an expression
          // rather than an identifier. For now we just ignore it to reduce the
          // number of errors produced, but that's probably not a valid long
          // term approach.
        }
      }
    }
    listener.handleNoCommentReference();
    return false;
  }

  void parseOneCommentReferenceRest(
      Token begin,
      int referenceOffset,
      Token newKeyword,
      Token prefix,
      Token period,
      Token identifierOrOperator) {
    // Adjust the token offsets to match the enclosing comment token.
    Token token = begin;
    do {
      token.offset += referenceOffset;
      token = token.next;
    } while (!token.isEof);

    listener.handleCommentReference(
        newKeyword, prefix, period, identifierOrOperator);
  }

  /// Given that we have just found bracketed text within the given [comment],
  /// look to see whether that text is (a) followed by a parenthesized link
  /// address, (b) followed by a colon, or (c) followed by optional whitespace
  /// and another square bracket. The [rightIndex] is the index of the right
  /// bracket. Return `true` if the bracketed text is followed by a link
  /// address.
  ///
  /// This method uses the syntax described by the
  /// <a href="http://daringfireball.net/projects/markdown/syntax">markdown</a>
  /// project.
  bool isLinkText(String comment, int rightIndex) {
    int length = comment.length;
    int index = rightIndex + 1;
    if (index >= length) {
      return false;
    }
    int ch = comment.codeUnitAt(index);
    if (ch == 0x28 || ch == 0x3A) {
      return true;
    }
    while (isWhitespace(ch)) {
      index = index + 1;
      if (index >= length) {
        return false;
      }
      ch = comment.codeUnitAt(index);
    }
    return ch == 0x5B;
  }
}

// TODO(ahe): Remove when analyzer supports generalized function syntax.
typedef _MessageWithArgument<T> = Message Function(T);
