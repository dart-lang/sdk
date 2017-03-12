// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.parser.element_listener;

import '../common.dart';
import '../diagnostics/messages.dart' show MessageTemplate;
import '../elements/elements.dart'
    show Element, LibraryElement, MetadataAnnotation;
import '../elements/modelx.dart'
    show
        CompilationUnitElementX,
        DeclarationSite,
        ElementX,
        EnumClassElementX,
        FieldElementX,
        LibraryElementX,
        MetadataAnnotationX,
        NamedMixinApplicationElementX,
        VariableList;
import '../id_generator.dart';
import '../native/native.dart' as native;
import '../string_validator.dart' show StringValidator;
import 'package:front_end/src/fasta/scanner.dart'
    show Keyword, BeginGroupToken, ErrorToken, KeywordToken, StringToken, Token;
import 'package:front_end/src/fasta/scanner.dart' as Tokens show EOF_TOKEN;
import 'package:front_end/src/fasta/scanner/precedence.dart' as Precedence
    show BAD_INPUT_INFO, IDENTIFIER_INFO;
import '../tree/tree.dart';
import '../util/util.dart' show Link, LinkBuilder;
import 'package:front_end/src/fasta/parser.dart'
    show ErrorKind, Listener, ParserError, optional;
import 'package:front_end/src/fasta/parser/identifier_context.dart'
    show IdentifierContext;
import 'partial_elements.dart'
    show
        PartialClassElement,
        PartialElement,
        PartialFieldList,
        PartialFunctionElement,
        PartialMetadataAnnotation,
        PartialTypedefElement;

const bool VERBOSE = false;

/// Options used for scanning.
///
/// Use this to conditionally support special tokens.
///
/// TODO(johnniwinther): This class should be renamed, it is not about options
/// in the same sense as `CompilerOptions` or `DiagnosticOptions`.
class ScannerOptions {
  /// If `true` the pseudo keyword `native` is supported.
  final bool canUseNative;

  const ScannerOptions({this.canUseNative: false});
}

/**
 * A parser event listener designed to work with [PartialParser]. It
 * builds elements representing the top-level declarations found in
 * the parsed compilation unit and records them in
 * [compilationUnitElement].
 */
class ElementListener extends Listener {
  final IdGenerator idGenerator;
  final DiagnosticReporter reporter;
  final ScannerOptions scannerOptions;
  final CompilationUnitElementX compilationUnitElement;
  final StringValidator stringValidator;
  Link<StringQuoting> interpolationScope;

  Link<Node> nodes = const Link<Node>();

  LinkBuilder<MetadataAnnotation> metadata =
      new LinkBuilder<MetadataAnnotation>();

  /// Records a stack of booleans for each member parsed (a stack is used to
  /// support nested members which isn't currently possible, but it also serves
  /// as a simple way to tell we're currently parsing a member). In this case,
  /// member refers to members of a library or a class (but currently, classes
  /// themselves are not considered members).  If the top of the stack
  /// (memberErrors.head) is true, the current member has already reported at
  /// least one parse error.
  Link<bool> memberErrors = const Link<bool>();

  bool suppressParseErrors = false;

  /// Set to true each time we parse a native function body. It is reset in
  /// [handleInvalidFunctionBody] which is called immediately after.
  bool lastErrorWasNativeFunctionBody = false;

  ElementListener(this.scannerOptions, DiagnosticReporter reporter,
      this.compilationUnitElement, this.idGenerator)
      : this.reporter = reporter,
        stringValidator = new StringValidator(reporter),
        interpolationScope = const Link<StringQuoting>();

  bool get currentMemberHasParseError {
    return !memberErrors.isEmpty && memberErrors.head;
  }

  void pushQuoting(StringQuoting quoting) {
    interpolationScope = interpolationScope.prepend(quoting);
  }

  StringQuoting popQuoting() {
    StringQuoting result = interpolationScope.head;
    interpolationScope = interpolationScope.tail;
    return result;
  }

  StringNode popLiteralString() {
    StringNode node = popNode();
    // TODO(lrn): Handle interpolations in script tags.
    if (node.isInterpolation) {
      reporter.internalError(
          node, "String interpolation not supported in library tags.");
      return null;
    }
    return node;
  }

  bool allowLibraryTags() {
    // Library tags are only allowed in the library file itself, not
    // in sourced files.
    LibraryElement library = compilationUnitElement.implementationLibrary;
    return !compilationUnitElement.hasMembers &&
        library.entryCompilationUnit == compilationUnitElement;
  }

  @override
  void endLibraryName(Token libraryKeyword, Token semicolon) {
    Expression name = popNode();
    addLibraryTag(new LibraryName(
        libraryKeyword, name, popMetadata(compilationUnitElement)));
  }

  @override
  void endImport(Token importKeyword, Token deferredKeyword, Token asKeyword,
      Token semicolon) {
    NodeList combinators = popNode();
    bool isDeferred = deferredKeyword != null;
    Identifier prefix;
    if (asKeyword != null) {
      prefix = popNode();
    }
    NodeList conditionalUris = popNode();
    StringNode uri = popLiteralString();
    addLibraryTag(new Import(importKeyword, uri, conditionalUris, prefix,
        combinators, popMetadata(compilationUnitElement),
        isDeferred: isDeferred));
  }

  @override
  void endDottedName(int count, Token token) {
    NodeList identifiers = makeNodeList(count, null, null, '.');
    pushNode(new DottedName(token, identifiers));
  }

  @override
  void endConditionalUris(int count) {
    if (count == 0) {
      pushNode(null);
    } else {
      pushNode(makeNodeList(count, null, null, " "));
    }
  }

  @override
  void endConditionalUri(Token ifToken, Token equalSign) {
    StringNode uri = popNode();
    LiteralString conditionValue = (equalSign != null) ? popNode() : null;
    DottedName identifier = popNode();
    pushNode(new ConditionalUri(ifToken, identifier, conditionValue, uri));
  }

  @override
  void endEnum(Token enumKeyword, Token endBrace, int count) {
    NodeList names = makeNodeList(count, enumKeyword.next.next, endBrace, ",");
    Identifier name = popNode();

    int id = idGenerator.getNextFreeId();
    Element enclosing = compilationUnitElement;
    pushElement(new EnumClassElementX(
        name.source, enclosing, id, new Enum(enumKeyword, name, names)));
    rejectBuiltInIdentifier(name);
  }

  @override
  void endExport(Token exportKeyword, Token semicolon) {
    NodeList combinators = popNode();
    NodeList conditionalUris = popNode();
    StringNode uri = popNode();
    addLibraryTag(new Export(exportKeyword, uri, conditionalUris, combinators,
        popMetadata(compilationUnitElement)));
  }

  @override
  void endCombinators(int count) {
    if (0 == count) {
      pushNode(null);
    } else {
      pushNode(makeNodeList(count, null, null, " "));
    }
  }

  @override
  void endHide(Token hideKeyword) => pushCombinator(hideKeyword);

  @override
  void endShow(Token showKeyword) => pushCombinator(showKeyword);

  void pushCombinator(Token keywordToken) {
    NodeList identifiers = popNode();
    pushNode(new Combinator(identifiers, keywordToken));
  }

  @override
  void endIdentifierList(int count) {
    pushNode(makeNodeList(count, null, null, ","));
  }

  @override
  void endTypeList(int count) {
    pushNode(makeNodeList(count, null, null, ","));
  }

  @override
  void endPart(Token partKeyword, Token semicolon) {
    StringNode uri = popLiteralString();
    addLibraryTag(
        new Part(partKeyword, uri, popMetadata(compilationUnitElement)));
  }

  @override
  void endPartOf(Token partKeyword, Token semicolon) {
    Expression name = popNode();
    addPartOfTag(
        new PartOf(partKeyword, name, popMetadata(compilationUnitElement)));
  }

  void addPartOfTag(PartOf tag) {
    compilationUnitElement.setPartOf(tag, reporter);
  }

  @override
  void endMetadata(Token beginToken, Token periodBeforeName, Token endToken) {
    if (periodBeforeName != null) {
      popNode(); // Discard name.
    }
    popNode(); // Discard node (Send or Identifier).
    pushMetadata(new PartialMetadataAnnotation(beginToken, endToken));
  }

  @override
  void endTopLevelDeclaration(Token token) {
    if (!metadata.isEmpty) {
      MetadataAnnotationX first = metadata.first;
      recoverableError(reporter.spanFromToken(first.beginToken),
          'Metadata not supported here.');
      metadata.clear();
    }
  }

  @override
  void endClassDeclaration(
      int interfacesCount,
      Token beginToken,
      Token classKeyword,
      Token extendsKeyword,
      Token implementsKeyword,
      Token endToken) {
    makeNodeList(interfacesCount, implementsKeyword, null, ","); // interfaces
    popNode(); // superType
    popNode(); // typeParameters
    Identifier name = popNode();
    int id = idGenerator.getNextFreeId();
    PartialClassElement element = new PartialClassElement(
        name.source, beginToken, endToken, compilationUnitElement, id);
    pushElement(element);
    rejectBuiltInIdentifier(name);
  }

  void rejectBuiltInIdentifier(Identifier name) {
    if (name.token is KeywordToken) {
      Keyword keyword = (name.token as KeywordToken).keyword;
      if (!keyword.isPseudo) {
        recoverableError(name, "Illegal name '${keyword.syntax}'.");
      }
    }
  }

  @override
  void endFunctionTypeAlias(
      Token typedefKeyword, Token equals, Token endToken) {
    Identifier name;
    if (equals == null) {
      popNode(); // TODO(karlklose): do not throw away typeVariables.
      name = popNode();
      popNode(); // returnType
    } else {
      popNode();  // Function type.
      popNode();  // TODO(karlklose): do not throw away typeVariables.
      name = popNode();
    }
    pushElement(new PartialTypedefElement(
        name.source, compilationUnitElement, typedefKeyword, endToken));
    rejectBuiltInIdentifier(name);
  }

  @override
  void endNamedMixinApplication(Token beginToken, Token classKeyword,
      Token equals, Token implementsKeyword, Token endToken) {
    NodeList interfaces = (implementsKeyword != null) ? popNode() : null;
    MixinApplication mixinApplication = popNode();
    NodeList typeParameters = popNode();
    Identifier name = popNode();
    Modifiers modifiers = popNode();
    NamedMixinApplication namedMixinApplication = new NamedMixinApplication(
        name,
        typeParameters,
        modifiers,
        mixinApplication,
        interfaces,
        beginToken,
        endToken);

    int id = idGenerator.getNextFreeId();
    Element enclosing = compilationUnitElement;
    pushElement(new NamedMixinApplicationElementX(
        name.source, enclosing, id, namedMixinApplication));
    rejectBuiltInIdentifier(name);
  }

  @override
  void endMixinApplication(Token withKeyword) {
    NodeList mixins = popNode();
    NominalTypeAnnotation superclass = popNode();
    pushNode(new MixinApplication(superclass, mixins));
  }

  @override
  void handleVoidKeyword(Token token) {
    pushNode(new NominalTypeAnnotation(new Identifier(token), null));
  }

  @override
  void endTopLevelMethod(Token beginToken, Token getOrSet, Token endToken) {
    bool hasParseError = currentMemberHasParseError;
    memberErrors = memberErrors.tail;
    popNode(); // typeVariables
    Identifier name = popNode();
    popNode(); // type
    Modifiers modifiers = popNode();
    PartialFunctionElement element = new PartialFunctionElement(name.source,
        beginToken, getOrSet, endToken, modifiers, compilationUnitElement);
    element.hasParseError = hasParseError;
    pushElement(element);
  }

  @override
  void endTopLevelFields(int count, Token beginToken, Token endToken) {
    bool hasParseError = currentMemberHasParseError;
    memberErrors = memberErrors.tail;
    void buildFieldElement(Identifier name, VariableList fields) {
      pushElement(new FieldElementX(name, compilationUnitElement, fields));
    }

    NodeList variables = makeNodeList(count, null, null, ",");
    popNode(); // type
    Modifiers modifiers = popNode();
    buildFieldElements(modifiers, variables, compilationUnitElement,
        buildFieldElement, beginToken, endToken, hasParseError);
  }

  void buildFieldElements(
      Modifiers modifiers,
      NodeList variables,
      Element enclosingElement,
      void buildFieldElement(Identifier name, VariableList fields),
      Token beginToken,
      Token endToken,
      bool hasParseError) {
    VariableList fields =
        new PartialFieldList(beginToken, endToken, modifiers, hasParseError);
    for (Link<Node> variableNodes = variables.nodes;
        !variableNodes.isEmpty;
        variableNodes = variableNodes.tail) {
      Expression initializedIdentifier = variableNodes.head;
      Identifier identifier = initializedIdentifier.asIdentifier();
      if (identifier == null) {
        identifier = initializedIdentifier.asSendSet().selector.asIdentifier();
      }
      buildFieldElement(identifier, fields);
    }
  }

  @override
  void handleIdentifier(Token token, IdentifierContext context) {
    pushNode(new Identifier(token));
  }

  @override
  void handleQualified(Token period) {
    Identifier last = popNode();
    Expression first = popNode();
    pushNode(new Send(first, last));
  }

  @override
  void handleNoConstructorReferenceContinuationAfterTypeArguments(Token token) {
  }

  @override
  void handleNoType(Token token) {
    pushNode(null);
  }

  @override
  void endTypeVariable(Token token, Token extendsOrSuper) {
    NominalTypeAnnotation bound = popNode();
    Identifier name = popNode();
    pushNode(new TypeVariable(name, extendsOrSuper, bound));
    rejectBuiltInIdentifier(name);
  }

  @override
  void endTypeVariables(int count, Token beginToken, Token endToken) {
    pushNode(makeNodeList(count, beginToken, endToken, ','));
  }

  @override
  void handleNoTypeVariables(Token token) {
    pushNode(null);
  }

  @override
  void endTypeArguments(int count, Token beginToken, Token endToken) {
    pushNode(makeNodeList(count, beginToken, endToken, ','));
  }

  @override
  void handleNoTypeArguments(Token token) {
    pushNode(null);
  }

  @override
  void handleType(Token beginToken, Token endToken) {
    NodeList typeArguments = popNode();
    Expression typeName = popNode();
    pushNode(new NominalTypeAnnotation(typeName, typeArguments));
  }

  void handleNoName(Token token) {
    pushNode(null);
  }

  @override
  void handleFunctionType(Token functionToken, Token endToken) {
    popNode();  // Type parameters.
    popNode();  // Return type.
    pushNode(null);
  }

  @override
  void handleParenthesizedExpression(BeginGroupToken token) {
    Expression expression = popNode();
    pushNode(new ParenthesizedExpression(expression, token));
  }

  @override
  void handleModifier(Token token) {
    pushNode(new Identifier(token));
  }

  @override
  void handleModifiers(int count) {
    if (count == 0) {
      pushNode(Modifiers.EMPTY);
    } else {
      NodeList modifierNodes = makeNodeList(count, null, null, ' ');
      pushNode(new Modifiers(modifierNodes));
    }
  }

  @override
  Token handleUnrecoverableError(Token token, ErrorKind kind, Map arguments) {
    Token next = handleError(token, kind, arguments);
    if (next == null &&
        kind != ErrorKind.UnterminatedComment &&
        kind != ErrorKind.UnterminatedString) {
      throw new ParserError.fromTokens(token, token, kind, arguments);
    } else {
      return next;
    }
  }

  @override
  void handleRecoverableError(Token token, ErrorKind kind, Map arguments) {
    handleError(token, kind, arguments);
  }

  @override
  void handleInvalidExpression(Token token) {
    pushNode(new ErrorExpression(token));
  }

  @override
  void handleInvalidFunctionBody(Token token) {
    lastErrorWasNativeFunctionBody = false;
  }

  @override
  void handleInvalidTypeReference(Token token) {
    pushNode(null);
  }

  Token handleError(Token token, ErrorKind kind, Map arguments) {
    MessageKind errorCode;

    switch (kind) {
      case ErrorKind.ExpectedButGot:
        String expected = arguments["expected"];
        if (identical(";", expected)) {
          // When a semicolon is missing, it often leads to an error on the
          // following line. So we try to find the token preceding the semicolon
          // and report that something is missing *after* it.
          Token preceding = findPrecedingToken(token);
          if (preceding == token) {
            reportErrorFromToken(token, MessageKind.MISSING_TOKEN_BEFORE_THIS,
                {'token': expected});
          } else {
            reportErrorFromToken(preceding,
                MessageKind.MISSING_TOKEN_AFTER_THIS, {'token': expected});
          }
          return preceding;
        } else {
          reportFatalError(
              reporter.spanFromToken(token),
              MessageTemplate.TEMPLATES[MessageKind.MISSING_TOKEN_BEFORE_THIS]
                  .message({'token': expected}, true).toString());
          return null;
        }
        break;

      case ErrorKind.ExpectedIdentifier:
        if (token is KeywordToken) {
          reportErrorFromToken(
              token,
              MessageKind.EXPECTED_IDENTIFIER_NOT_RESERVED_WORD,
              {'keyword': token.lexeme});
        } else if (token is ErrorToken) {
          // TODO(ahe): This is dead code.
          return newSyntheticToken(synthesizeIdentifier(token));
        } else {
          reportFatalError(reporter.spanFromToken(token),
              "Expected identifier, but got '${token.lexeme}'.");
        }
        return newSyntheticToken(token);

      case ErrorKind.ExpectedType:
        reportFatalError(reporter.spanFromToken(token),
            "Expected a type, but got '${token.lexeme}'.");
        return null;

      case ErrorKind.ExpectedExpression:
        reportFatalError(reporter.spanFromToken(token),
            "Expected an expression, but got '${token.lexeme}'.");
        return null;

      case ErrorKind.UnexpectedToken:
        String message = "Unexpected token '${token.lexeme}'.";
        if (token.info == Precedence.BAD_INPUT_INFO) {
          message = token.lexeme;
        }
        reportFatalError(reporter.spanFromToken(token), message);
        return null;

      case ErrorKind.ExpectedBlockToSkip:
        if (optional("native", token)) {
          return newSyntheticToken(native.handleNativeBlockToSkip(this, token));
        } else {
          errorCode = MessageKind.BODY_EXPECTED;
        }
        break;

      case ErrorKind.ExpectedFunctionBody:
        if (optional("native", token)) {
          lastErrorWasNativeFunctionBody = true;
          return newSyntheticToken(
              native.handleNativeFunctionBody(this, token));
        } else {
          reportFatalError(reporter.spanFromToken(token),
              "Expected a function body, but got '${token.lexeme}'.");
        }
        return null;

      case ErrorKind.ExpectedClassBodyToSkip:
      case ErrorKind.ExpectedClassBody:
        reportFatalError(reporter.spanFromToken(token),
            "Expected a class body, but got '${token.lexeme}'.");
        return null;

      case ErrorKind.ExpectedDeclaration:
        reportFatalError(reporter.spanFromToken(token),
            "Expected a declaration, but got '${token.lexeme}'.");
        return null;

      case ErrorKind.UnmatchedToken:
        reportErrorFromToken(token, MessageKind.UNMATCHED_TOKEN, arguments);
        Token next = token;
        while (next.next is ErrorToken) {
          next = next.next;
        }
        return next;

      case ErrorKind.EmptyNamedParameterList:
        errorCode = MessageKind.EMPTY_NAMED_PARAMETER_LIST;
        break;

      case ErrorKind.EmptyOptionalParameterList:
        errorCode = MessageKind.EMPTY_OPTIONAL_PARAMETER_LIST;
        break;

      case ErrorKind.ExpectedBody:
        errorCode = MessageKind.BODY_EXPECTED;
        break;

      case ErrorKind.ExpectedHexDigit:
        errorCode = MessageKind.HEX_DIGIT_EXPECTED;
        break;

      case ErrorKind.ExpectedOpenParens:
        errorCode = MessageKind.GENERIC;
        arguments = {"text": "Expected '('."};
        break;

      case ErrorKind.ExpectedString:
        reportFatalError(reporter.spanFromToken(token),
            "Expected a String, but got '${token.lexeme}'.");
        return null;

      case ErrorKind.ExtraneousModifier:
        errorCode = MessageKind.EXTRANEOUS_MODIFIER;
        break;

      case ErrorKind.ExtraneousModifierReplace:
        errorCode = MessageKind.EXTRANEOUS_MODIFIER_REPLACE;
        break;

      case ErrorKind.InvalidAwaitFor:
        errorCode = MessageKind.INVALID_AWAIT_FOR;
        break;

      case ErrorKind.AsciiControlCharacter:
      case ErrorKind.NonAsciiIdentifier:
      case ErrorKind.NonAsciiWhitespace:
      case ErrorKind.Encoding:
        errorCode = MessageKind.BAD_INPUT_CHARACTER;
        break;

      case ErrorKind.InvalidInlineFunctionType:
        errorCode = MessageKind.INVALID_INLINE_FUNCTION_TYPE;
        break;

      case ErrorKind.InvalidSyncModifier:
        errorCode = MessageKind.INVALID_SYNC_MODIFIER;
        break;

      case ErrorKind.InvalidVoid:
        errorCode = MessageKind.VOID_NOT_ALLOWED;
        break;

      case ErrorKind.UnexpectedDollarInString:
        errorCode = MessageKind.MALFORMED_STRING_LITERAL;
        break;

      case ErrorKind.MissingExponent:
        errorCode = MessageKind.EXPONENT_MISSING;
        break;

      case ErrorKind.PositionalParameterWithEquals:
        errorCode = MessageKind.POSITIONAL_PARAMETER_WITH_EQUALS;
        break;

      case ErrorKind.RequiredParameterWithDefault:
        errorCode = MessageKind.REQUIRED_PARAMETER_WITH_DEFAULT;
        break;

      case ErrorKind.UnmatchedToken:
        errorCode = MessageKind.UNMATCHED_TOKEN;
        break;

      case ErrorKind.UnsupportedPrefixPlus:
        errorCode = MessageKind.UNSUPPORTED_PREFIX_PLUS;
        break;

      case ErrorKind.UnterminatedComment:
        errorCode = MessageKind.UNTERMINATED_COMMENT;
        break;

      case ErrorKind.UnterminatedString:
        errorCode = MessageKind.UNTERMINATED_STRING;
        break;

      case ErrorKind.UnterminatedToken:
        errorCode = MessageKind.UNTERMINATED_TOKEN;
        break;

      case ErrorKind.StackOverflow:
        errorCode = MessageKind.GENERIC;
        arguments = {"text": "Stack overflow."};
        break;

      case ErrorKind.Unspecified:
        errorCode = MessageKind.GENERIC;
        break;
    }
    SourceSpan span = reporter.spanFromToken(token);
    reportError(span, errorCode, arguments);
  }

  /// Finds the preceding token via the begin token of the last AST node pushed
  /// on the [nodes] stack.
  Token findPrecedingToken(Token token) {
    Token result;
    Link<Node> nodes = this.nodes;
    while (!nodes.isEmpty) {
      result = findPrecedingTokenFromNode(nodes.head, token);
      if (result != null) {
        return result;
      }
      nodes = nodes.tail;
    }
    if (compilationUnitElement != null) {
      if (compilationUnitElement is CompilationUnitElementX) {
        CompilationUnitElementX unit = compilationUnitElement;
        Link<Element> members = unit.localMembers;
        while (!members.isEmpty) {
          ElementX member = members.head;
          DeclarationSite site = member.declarationSite;
          if (site is PartialElement) {
            result = findPrecedingTokenFromToken(site.endToken, token);
            if (result != null) {
              return result;
            }
          }
          members = members.tail;
        }
        result =
            findPrecedingTokenFromNode(compilationUnitElement.partTag, token);
        if (result != null) {
          return result;
        }
      }
    }
    return token;
  }

  Token findPrecedingTokenFromNode(Node node, Token token) {
    if (node != null) {
      return findPrecedingTokenFromToken(node.getBeginToken(), token);
    }
    return null;
  }

  Token findPrecedingTokenFromToken(Token start, Token token) {
    if (start != null) {
      Token current = start;
      while (current.kind != Tokens.EOF_TOKEN && current.next != token) {
        current = current.next;
      }
      if (current.kind != Tokens.EOF_TOKEN) {
        return current;
      }
    }
    return null;
  }

  /// Finds the preceding token via the begin token of the last AST node pushed
  /// on the [nodes] stack.
  Token synthesizeIdentifier(Token token) {
    Token synthesizedToken = new StringToken.fromString(
        Precedence.IDENTIFIER_INFO, '?', token.charOffset);
    synthesizedToken.next = token.next;
    return synthesizedToken;
  }

  void recoverableError(Spannable node, String message) {
    // TODO(johnniwinther): Make recoverable errors non-fatal.
    reportFatalError(node, message);
  }

  void pushElement(ElementX element) {
    assert(invariant(element, element.declarationSite != null,
        message: 'Missing declaration site for $element.'));
    popMetadata(element);
    compilationUnitElement.addMember(element, reporter);
  }

  List<MetadataAnnotation> popMetadata(ElementX element) {
    List<MetadataAnnotation> result = metadata.toList();
    element.metadata = result;
    metadata.clear();
    return result;
  }

  void pushMetadata(MetadataAnnotation annotation) {
    metadata.addLast(annotation);
  }

  void addLibraryTag(LibraryTag tag) {
    if (!allowLibraryTags()) {
      recoverableError(tag, 'Library tags not allowed here.');
    }
    LibraryElementX implementationLibrary =
        compilationUnitElement.implementationLibrary;
    implementationLibrary.addTag(tag, reporter);
  }

  void pushNode(Node node) {
    nodes = nodes.prepend(node);
    if (VERBOSE) log("push $nodes");
  }

  Node popNode() {
    assert(!nodes.isEmpty);
    Node node = nodes.head;
    nodes = nodes.tail;
    if (VERBOSE) log("pop $nodes");
    return node;
  }

  void log(message) {
    print(message);
  }

  NodeList makeNodeList(
      int count, Token beginToken, Token endToken, String delimiter) {
    Link<Node> poppedNodes = const Link<Node>();
    for (; count > 0; --count) {
      // This effectively reverses the order of nodes so they end up
      // in correct (source) order.
      poppedNodes = poppedNodes.prepend(popNode());
    }
    return new NodeList(beginToken, poppedNodes, endToken, delimiter);
  }

  @override
  void beginLiteralString(Token token) {
    String source = token.lexeme;
    StringQuoting quoting = StringValidator.quotingFromString(source);
    pushQuoting(quoting);
    // Just wrap the token for now. At the end of the interpolation,
    // when we know how many there are, go back and validate the tokens.
    pushNode(new LiteralString(token, null));
  }

  @override
  void handleStringPart(Token token) {
    // Just push an unvalidated token now, and replace it when we know the
    // end of the interpolation.
    pushNode(new LiteralString(token, null));
  }

  @override
  void endLiteralString(int count, Token endToken) {
    StringQuoting quoting = popQuoting();

    Link<StringInterpolationPart> parts = const Link<StringInterpolationPart>();
    // Parts of the string interpolation are popped in reverse order,
    // starting with the last literal string part.
    bool isLast = true;
    for (int i = 0; i < count; i++) {
      LiteralString string = popNode();
      DartString validation = stringValidator.validateInterpolationPart(
          string.token, quoting,
          isFirst: false, isLast: isLast);
      // Replace the unvalidated LiteralString with a new LiteralString
      // object that has the validation result included.
      string = new LiteralString(string.token, validation);
      Expression expression = popNode();
      parts = parts.prepend(new StringInterpolationPart(expression, string));
      isLast = false;
    }

    LiteralString string = popNode();
    DartString validation = stringValidator.validateInterpolationPart(
        string.token, quoting,
        isFirst: true, isLast: isLast);
    string = new LiteralString(string.token, validation);
    if (isLast) {
      pushNode(string);
    } else {
      NodeList partNodes = new NodeList(null, parts, null, "");
      pushNode(new StringInterpolation(string, partNodes));
    }
  }

  @override
  void handleStringJuxtaposition(int stringCount) {
    assert(stringCount != 0);
    Expression accumulator = popNode();
    stringCount--;
    while (stringCount > 0) {
      Expression expression = popNode();
      accumulator = new StringJuxtaposition(expression, accumulator);
      stringCount--;
    }
    pushNode(accumulator);
  }

  @override
  void beginMember(Token token) {
    memberErrors = memberErrors.prepend(false);
  }

  @override
  void beginTopLevelMember(Token token) {
    beginMember(token);
  }

  @override
  void endMember() {
    memberErrors = memberErrors.tail;
  }

  /// Don't call this method. Should only be used as a last resort when there
  /// is no feasible way to recover from a parser error.
  void reportFatalError(Spannable spannable, String message) {
    reportError(spannable, MessageKind.GENERIC, {'text': message});
    // Some parse errors are infeasible to recover from, so we throw an error.
    SourceSpan span = reporter.spanFromSpannable(spannable);
    throw new ParserError(
        span.begin, span.end, ErrorKind.Unspecified, {'text': message});
  }

  void reportError(Spannable spannable, MessageKind errorCode,
      [Map arguments = const {}]) {
    if (currentMemberHasParseError) return; // Error already reported.
    if (suppressParseErrors) return;
    if (!memberErrors.isEmpty) {
      memberErrors = memberErrors.tail.prepend(true);
    }
    reporter.reportErrorMessage(spannable, errorCode, arguments);
  }

  void reportErrorFromToken(Token token, MessageKind errorCode,
      [Map arguments = const {}]) {
    reportError(reporter.spanFromToken(token), errorCode, arguments);
  }
}
