// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("patchparser");
#import("dart:uri");

#import("tree/tree.dart", prefix: "tree");
#import("leg.dart", prefix: 'leg');  // CompilerTask, Compiler.
#import("apiimpl.dart");
#import("scanner/scannerlib.dart");  // Scanner, Parsers, Listeners
#import("elements/elements.dart");
#import('native_handler.dart', prefix: 'native');


class PatchParserTask extends leg.CompilerTask {
  PatchParserTask(leg.Compiler compiler): super(compiler);
  final String name = "Patching Parser";

  LibraryElement loadPatchLibrary(Uri uri) {
    bool newLibrary = false;
    LibraryElement library =
      compiler.libraries.putIfAbsent(uri.toString(), () {
          newLibrary = true;
          leg.Script script = compiler.readScript(uri, null);
          LibraryElement element =
              new LibraryElement(script);
          native.maybeEnableNative(compiler, element, uri);
          return element;
        });
    if (newLibrary) {
      compiler.withCurrentElement(library, () {
        scanLibraryElements(library);
        compiler.onLibraryLoaded(library, uri);
      });
    }
    return library;
  }

  void scanLibraryElements(LibraryElement library) {
    measure(() {
      // TODO(lrn): Possibly recursively handle #source directives in patch.
      leg.Script script = library.entryCompilationUnit.script;
      Token tokens = new StringScanner(script.text).tokenize();
      Function idGenerator = compiler.getNextFreeClassId;
      PatchListener patchListener =
          new PatchElementListener(compiler,
                                   library.entryCompilationUnit,
                                   idGenerator);
      new PatchParser(patchListener).parseUnit(tokens);
    });
  }

  tree.ClassNode parsePatchClassNode(PartialClassElement element) {
    // Parse [PartialClassElement] using a "patch"-aware parser instead
    // of calling its [parseNode] method.
    if (element.cachedNode != null) return element.cachedNode;
    PatchMemberListener listener =
        new PatchMemberListener(compiler, element);
    Parser parser = new PatchClassElementParser(listener);
    Token token = parser.parseTopLevelDeclaration(element.beginToken);
    assert(token === element.endToken.next);
    element.cachedNode = listener.popNode();
    assert(listener.nodes.isEmpty());
    return element.cachedNode;
  }
}

/**
 * Extension of the [Listener] interface to handle the extra "patch" pseudo-
 * keyword in patch files.
 * Patch files shouldn't have a type named "patch".
 */
interface PatchListener extends Listener {
  void beginPatch(Token patch);
  void endPatch(Token patch);
}

/**
 * Partial parser that extends the top-level and class grammars to allow the
 * word "patch" in front of some declarations.
 */
class PatchParser extends PartialParser {
  PatchParser(PatchListener listener) : super(listener);

  PatchListener get patchListener() => listener;

  bool isPatch(Token token) {
    return token.stringValue === null &&
           token.slowToString() == "patch";
  }

  /**
   * Parse top-level declarations, and allow "patch" in front of functions
   * and classes.
   */
  Token parseTopLevelDeclaration(Token token) {
    if (!isPatch(token)) {
      return super.parseTopLevelDeclaration(token);
    }
    Token patch = token;
    token = token.next;
    String value = token.stringValue;
    if (value === 'interface'
        || value === 'typedef'
        || value === '#'
        || value === 'abstract') {
      // At the top level, you can only patch functions and classes.
      // Patch classes and functions can't be marked abstract.
      return listener.unexpected(patch);
    }
    patchListener.beginPatch(patch);
    token = super.parseTopLevelDeclaration(token);
    patchListener.endPatch(patch);
    return token;
  }

  /**
   * Parse a class member.
   * If the member starts with "patch", it's a member override.
   * Only methods can be overridden, including constructors, getters and
   * setters, but not fields. If "patch" occurs in front of a field, the error
   * is caught elsewhere.
   */
  Token parseMember(Token token) {
    if (!isPatch(token)) {
      return super.parseMember(token);
    }
    Token patch = token;
    patchListener.beginPatch(patch);
    token = super.parseMember(token.next);
    patchListener.endPatch(patch);
    return token;
  }
}


/**
 * Partial parser for patch files that also handles the members of class
 * declarations.
 */
class PatchClassElementParser extends PatchParser {
  PatchClassElementParser(PatchListener listener) : super(listener);

  Token parseClassBody(Token token) => fullParseClassBody(token);
}


/**
 * Extension of [ElementListener] for parsing patch files.
 */
class PatchElementListener extends ElementListener implements PatchListener {
  bool isMemberPatch = false;
  bool isClassPatch = false;
  PatchElementListener(leg.DiagnosticListener listener,
                       CompilationUnitElement patchElement,
                       int idGenerator())
    : super(listener, patchElement, idGenerator);

  void beginPatch(Token token) {
    if (token.next.stringValue === "class") {
      isClassPatch = true;
    } else {
      isMemberPatch = true;
    }
    handleIdentifier(token);
  }

  void endPatch(Token token) {
    if (token.next.stringValue === "class") {
      isClassPatch = false;
    } else {
      isMemberPatch = false;
    }
  }

  void pushElement(Element element) {
    if (isMemberPatch || (isClassPatch && element is ClassElement)) {
      element.addMetadata(popNode());
    }
    super.pushElement(element);
  }
}


/**
 * Extension of [MemberListener] for parsing patch class bodies.
 */
class PatchMemberListener extends MemberListener implements PatchListener {
  bool isMemberPatch = false;
  bool isClassPatch = false;
  PatchMemberListener(leg.DiagnosticListener listener,
                      Element enclosingElement)
    : super(listener, enclosingElement);

  void beginPatch(Token token) {
    if (token.next.stringValue === "class") {
      isClassPatch = true;
    } else {
      isMemberPatch = true;
    }
    handleIdentifier(token);
  }

  void endPatch(Token token) {
    if (token.next.stringValue === "class") {
      isClassPatch = false;
    } else {
      isMemberPatch = false;
    }
  }

  void addMember(Element element) {
    if (isMemberPatch || (isClassPatch && element is ClassElement)) {
      element.addMetadata(popNode());
    }
    super.addMember(element);
  }
}
