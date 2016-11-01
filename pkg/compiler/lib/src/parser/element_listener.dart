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
import '../tokens/keyword.dart' show Keyword;
import '../tokens/precedence_constants.dart' as Precedence show BAD_INPUT_INFO;
import '../tokens/token.dart'
    show BeginGroupToken, ErrorToken, KeywordToken, Token;
import '../tokens/token_constants.dart' as Tokens show EOF_TOKEN;
import '../tree/tree.dart';
import '../util/util.dart' show Link, LinkBuilder;
import 'listener.dart' show closeBraceFor, Listener, ParserError, VERBOSE;
import 'partial_elements.dart'
    show
        PartialClassElement,
        PartialElement,
        PartialFieldList,
        PartialFunctionElement,
        PartialMetadataAnnotation,
        PartialTypedefElement;

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

  void endLibraryName(Token libraryKeyword, Token semicolon) {
    Expression name = popNode();
    addLibraryTag(new LibraryName(
        libraryKeyword, name, popMetadata(compilationUnitElement)));
  }

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

  void endDottedName(int count, Token token) {
    NodeList identifiers = makeNodeList(count, null, null, '.');
    pushNode(new DottedName(token, identifiers));
  }

  void endConditionalUris(int count) {
    if (count == 0) {
      pushNode(null);
    } else {
      pushNode(makeNodeList(count, null, null, " "));
    }
  }

  void endConditionalUri(Token ifToken, Token equalSign) {
    StringNode uri = popNode();
    LiteralString conditionValue = (equalSign != null) ? popNode() : null;
    DottedName identifier = popNode();
    pushNode(new ConditionalUri(ifToken, identifier, conditionValue, uri));
  }

  void endEnum(Token enumKeyword, Token endBrace, int count) {
    NodeList names = makeNodeList(count, enumKeyword.next.next, endBrace, ",");
    Identifier name = popNode();

    int id = idGenerator.getNextFreeId();
    Element enclosing = compilationUnitElement;
    pushElement(new EnumClassElementX(
        name.source, enclosing, id, new Enum(enumKeyword, name, names)));
    rejectBuiltInIdentifier(name);
  }

  void endExport(Token exportKeyword, Token semicolon) {
    NodeList combinators = popNode();
    NodeList conditionalUris = popNode();
    StringNode uri = popNode();
    addLibraryTag(new Export(exportKeyword, uri, conditionalUris, combinators,
        popMetadata(compilationUnitElement)));
  }

  void endCombinators(int count) {
    if (0 == count) {
      pushNode(null);
    } else {
      pushNode(makeNodeList(count, null, null, " "));
    }
  }

  void endHide(Token hideKeyword) => pushCombinator(hideKeyword);

  void endShow(Token showKeyword) => pushCombinator(showKeyword);

  void pushCombinator(Token keywordToken) {
    NodeList identifiers = popNode();
    pushNode(new Combinator(identifiers, keywordToken));
  }

  void endIdentifierList(int count) {
    pushNode(makeNodeList(count, null, null, ","));
  }

  void endTypeList(int count) {
    pushNode(makeNodeList(count, null, null, ","));
  }

  void endPart(Token partKeyword, Token semicolon) {
    StringNode uri = popLiteralString();
    addLibraryTag(
        new Part(partKeyword, uri, popMetadata(compilationUnitElement)));
  }

  void endPartOf(Token partKeyword, Token semicolon) {
    Expression name = popNode();
    addPartOfTag(
        new PartOf(partKeyword, name, popMetadata(compilationUnitElement)));
  }

  void addPartOfTag(PartOf tag) {
    compilationUnitElement.setPartOf(tag, reporter);
  }

  void endMetadata(Token beginToken, Token periodBeforeName, Token endToken) {
    if (periodBeforeName != null) {
      popNode(); // Discard name.
    }
    popNode(); // Discard node (Send or Identifier).
    pushMetadata(new PartialMetadataAnnotation(beginToken, endToken));
  }

  void endTopLevelDeclaration(Token token) {
    if (!metadata.isEmpty) {
      MetadataAnnotationX first = metadata.first;
      recoverableError(first.beginToken, 'Metadata not supported here.');
      metadata.clear();
    }
  }

  void endClassDeclaration(int interfacesCount, Token beginToken,
      Token extendsKeyword, Token implementsKeyword, Token endToken) {
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

  void endFunctionTypeAlias(Token typedefKeyword, Token endToken) {
    popNode(); // TODO(karlklose): do not throw away typeVariables.
    Identifier name = popNode();
    popNode(); // returnType
    pushElement(new PartialTypedefElement(
        name.source, compilationUnitElement, typedefKeyword, endToken));
    rejectBuiltInIdentifier(name);
  }

  void endNamedMixinApplication(
      Token classKeyword, Token implementsKeyword, Token endToken) {
    NodeList interfaces = (implementsKeyword != null) ? popNode() : null;
    MixinApplication mixinApplication = popNode();
    Modifiers modifiers = popNode();
    NodeList typeParameters = popNode();
    Identifier name = popNode();
    NamedMixinApplication namedMixinApplication = new NamedMixinApplication(
        name,
        typeParameters,
        modifiers,
        mixinApplication,
        interfaces,
        classKeyword,
        endToken);

    int id = idGenerator.getNextFreeId();
    Element enclosing = compilationUnitElement;
    pushElement(new NamedMixinApplicationElementX(
        name.source, enclosing, id, namedMixinApplication));
    rejectBuiltInIdentifier(name);
  }

  void endMixinApplication() {
    NodeList mixins = popNode();
    TypeAnnotation superclass = popNode();
    pushNode(new MixinApplication(superclass, mixins));
  }

  void handleVoidKeyword(Token token) {
    pushNode(new TypeAnnotation(new Identifier(token), null));
  }

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

  void handleIdentifier(Token token) {
    pushNode(new Identifier(token));
  }

  void handleQualified(Token period) {
    Identifier last = popNode();
    Expression first = popNode();
    pushNode(new Send(first, last));
  }

  void handleNoType(Token token) {
    pushNode(null);
  }

  void endTypeVariable(Token token, Token extendsOrSuper) {
    TypeAnnotation bound = popNode();
    Identifier name = popNode();
    pushNode(new TypeVariable(name, extendsOrSuper, bound));
    rejectBuiltInIdentifier(name);
  }

  void endTypeVariables(int count, Token beginToken, Token endToken) {
    pushNode(makeNodeList(count, beginToken, endToken, ','));
  }

  void handleNoTypeVariables(Token token) {
    pushNode(null);
  }

  void endTypeArguments(int count, Token beginToken, Token endToken) {
    pushNode(makeNodeList(count, beginToken, endToken, ','));
  }

  void handleNoTypeArguments(Token token) {
    pushNode(null);
  }

  void endType(Token beginToken, Token endToken) {
    NodeList typeArguments = popNode();
    Expression typeName = popNode();
    pushNode(new TypeAnnotation(typeName, typeArguments));
  }

  void handleParenthesizedExpression(BeginGroupToken token) {
    Expression expression = popNode();
    pushNode(new ParenthesizedExpression(expression, token));
  }

  void handleModifier(Token token) {
    pushNode(new Identifier(token));
  }

  void handleModifiers(int count) {
    if (count == 0) {
      pushNode(Modifiers.EMPTY);
    } else {
      NodeList modifierNodes = makeNodeList(count, null, null, ' ');
      pushNode(new Modifiers(modifierNodes));
    }
  }

  Token expected(String string, Token token) {
    if (token is ErrorToken) {
      reportErrorToken(token);
    } else if (identical(';', string)) {
      // When a semicolon is missing, it often leads to an error on the
      // following line. So we try to find the token preceding the semicolon
      // and report that something is missing *after* it.
      Token preceding = findPrecedingToken(token);
      if (preceding == token) {
        reportError(
            token, MessageKind.MISSING_TOKEN_BEFORE_THIS, {'token': string});
      } else {
        reportError(
            preceding, MessageKind.MISSING_TOKEN_AFTER_THIS, {'token': string});
      }
      return token;
    } else {
      reportFatalError(
          token,
          MessageTemplate.TEMPLATES[MessageKind.MISSING_TOKEN_BEFORE_THIS]
              .message({'token': string}, true).toString());
    }
    return skipToEof(token);
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

  Token expectedIdentifier(Token token) {
    if (token is KeywordToken) {
      reportError(token, MessageKind.EXPECTED_IDENTIFIER_NOT_RESERVED_WORD,
          {'keyword': token.value});
    } else if (token is ErrorToken) {
      reportErrorToken(token);
      return synthesizeIdentifier(token);
    } else {
      reportFatalError(token, "Expected identifier, but got '${token.value}'.");
    }
    return token;
  }

  Token expectedType(Token token) {
    pushNode(null);
    if (token is ErrorToken) {
      reportErrorToken(token);
      return synthesizeIdentifier(token);
    } else {
      reportFatalError(token, "Expected a type, but got '${token.value}'.");
      return skipToEof(token);
    }
  }

  Token expectedExpression(Token token) {
    if (token is ErrorToken) {
      reportErrorToken(token);
      pushNode(new ErrorExpression(token));
      return token.next;
    } else {
      reportFatalError(
          token, "Expected an expression, but got '${token.value}'.");
      pushNode(null);
      return skipToEof(token);
    }
  }

  Token unexpected(Token token) {
    if (token is ErrorToken) {
      reportErrorToken(token);
    } else {
      String message = "Unexpected token '${token.value}'.";
      if (token.info == Precedence.BAD_INPUT_INFO) {
        message = token.value;
      }
      reportFatalError(token, message);
    }
    return skipToEof(token);
  }

  Token expectedBlockToSkip(Token token) {
    if (identical(token.stringValue, 'native')) {
      return native.handleNativeBlockToSkip(this, token);
    } else {
      return unexpected(token);
    }
  }

  Token expectedFunctionBody(Token token) {
    if (token is ErrorToken) {
      reportErrorToken(token);
    } else {
      String printString = token.value;
      reportFatalError(
          token, "Expected a function body, but got '$printString'.");
    }
    return skipToEof(token);
  }

  Token expectedClassBody(Token token) {
    if (token is ErrorToken) {
      reportErrorToken(token);
    } else {
      reportFatalError(
          token, "Expected a class body, but got '${token.value}'.");
    }
    return skipToEof(token);
  }

  Token expectedClassBodyToSkip(Token token) {
    return unexpected(token);
  }

  Token expectedDeclaration(Token token) {
    if (token is ErrorToken) {
      reportErrorToken(token);
    } else {
      reportFatalError(
          token, "Expected a declaration, but got '${token.value}'.");
    }
    return skipToEof(token);
  }

  Token unmatched(Token token) {
    if (token is ErrorToken) {
      reportErrorToken(token);
    } else {
      String begin = token.value;
      String end = closeBraceFor(begin);
      reportError(
          token, MessageKind.UNMATCHED_TOKEN, {'begin': begin, 'end': end});
    }
    Token next = token.next;
    while (next is ErrorToken) {
      next = next.next;
    }
    return next;
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

  void beginLiteralString(Token token) {
    String source = token.value;
    StringQuoting quoting = StringValidator.quotingFromString(source);
    pushQuoting(quoting);
    // Just wrap the token for now. At the end of the interpolation,
    // when we know how many there are, go back and validate the tokens.
    pushNode(new LiteralString(token, null));
  }

  void handleStringPart(Token token) {
    // Just push an unvalidated token now, and replace it when we know the
    // end of the interpolation.
    pushNode(new LiteralString(token, null));
  }

  void endLiteralString(int count) {
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

  void beginMember(Token token) {
    memberErrors = memberErrors.prepend(false);
  }

  void beginTopLevelMember(Token token) {
    beginMember(token);
  }

  void endMember() {
    memberErrors = memberErrors.tail;
  }

  /// Don't call this method. Should only be used as a last resort when there
  /// is no feasible way to recover from a parser error.
  void reportFatalError(Spannable spannable, String message) {
    reportError(spannable, MessageKind.GENERIC, {'text': message});
    // Some parse errors are infeasible to recover from, so we throw an error.
    throw new ParserError(message);
  }

  @override
  void reportErrorHelper(Spannable spannable, MessageKind errorCode,
      [Map arguments = const {}]) {
    if (currentMemberHasParseError) return; // Error already reported.
    if (suppressParseErrors) return;
    if (!memberErrors.isEmpty) {
      memberErrors = memberErrors.tail.prepend(true);
    }
    reporter.reportErrorMessage(spannable, errorCode, arguments);
  }
}
