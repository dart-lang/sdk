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
#import('util/util.dart');

class PatchParserTask extends leg.CompilerTask {
  PatchParserTask(leg.Compiler compiler): super(compiler);
  final String name = "Patching Parser";

  /**
   * Scans a library patch file, applies the method patches and
   * injections to the library, and returns a list of class
   * patches.
   */
  void patchLibrary(Uri patchUri, LibraryElement library) {
    leg.Script script = compiler.readScript(patchUri, null);
    CompilationUnitElement compilationUnit =
        new CompilationUnitElement(script, library);
    library.addCompilationUnit(compilationUnit);
    LinkBuilder<tree.ScriptTag> imports = new LinkBuilder<tree.ScriptTag>();
    compiler.withCurrentElement(compilationUnit, () {
      // This patches the elements of the patch library into [library].
      // Injected elements are added directly under the compilation unit.
      // Patch elements are stored on the patched functions or classes.
      scanLibraryElements(compilationUnit, imports);
    });
    // After scanning declarations, we handle the import tags in the patch.
    // TODO(lrn): These imports end up in the original library and are in
    // scope for the original methods too. This should be fixed.
    for (tree.ScriptTag tag in imports.toLink()) {
      compiler.scanner.importLibraryFromTag(tag, compilationUnit);
    }
  }

  void scanLibraryElements(
        CompilationUnitElement compilationUnit,
        LinkBuilder<tree.ScriptTag> imports) {
    measure(() {
      // TODO(lrn): Possibly recursively handle #source directives in patch.
      leg.Script script = compilationUnit.script;
      Token tokens = new StringScanner(script.text).tokenize();
      Function idGenerator = compiler.getNextFreeClassId;
      PatchListener patchListener =
          new PatchElementListener(compiler,
                                   compilationUnit,
                                   idGenerator,
                                   imports);
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
abstract class PatchListener extends Listener {
  void beginPatch(Token patch);
  void endPatch(Token patch);
}

/**
 * Partial parser that extends the top-level and class grammars to allow the
 * word "patch" in front of some declarations.
 */
class PatchParser extends PartialParser {
  PatchParser(PatchListener listener) : super(listener);

  PatchListener get patchListener => listener;

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
  final LinkBuilder<tree.ScriptTag> imports;
  bool isMemberPatch = false;
  bool isClassPatch = false;

  PatchElementListener(leg.DiagnosticListener listener,
                       CompilationUnitElement patchElement,
                       int idGenerator(),
                       this.imports)
    : super(listener, patchElement, idGenerator);

  MetadataAnnotation popMetadata() {
    // TODO(ahe): Remove this method.
    popNode(); // Discard null.
    return new PatchMetadataAnnotation();
  }

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

  /**
    * Allow script tags (import only, the parser rejects the rest for now) in
    * patch files. The import tags will be added to the library.
    */
  bool allowScriptTags() => true;

  void addScriptTag(tree.ScriptTag tag) {
    super.addScriptTag(tag);
    imports.addLast(tag);
  }

  void pushElement(Element element) {
    if (isMemberPatch || (isClassPatch && element is ClassElement)) {
      // Apply patch.
      element.addMetadata(popMetadata());
      LibraryElement library = compilationUnitElement.getLibrary();
      Element existing = library.localLookup(element.name);
      if (isMemberPatch) {
        if (element is! FunctionElement) {
          listener.internalErrorOnElement(element,
                                          "Member patch is not a function.");
        }
        if (existing.kind === ElementKind.ABSTRACT_FIELD) {
          if (!element.isAccessor()) {
            listener.internalErrorOnElement(
                element, "Patching non-accessor with accessor");
          }
          AbstractFieldElement field = existing;
          if (element.isGetter()) {
            existing = field.getter;
          } else {
            existing = field.setter;
          }
        }
        if (existing is! FunctionElement) {
          listener.internalErrorOnElement(element,
                                          "No corresponding method for patch.");
        }
        FunctionElement function = existing;
        if (function.isPatched) {
          listener.internalErrorOnElement(
              element, "Patching the same function more than once.");
        }
        function.patch = element;
      } else {
        if (existing is! ClassElement) {
          listener.internalErrorOnElement(
              element, "Patching a non-class with a class patch.");
        }
        ClassElement classElement = existing;
        if (classElement.isPatched) {
          listener.internalErrorOnElement(
              element, "Patching the same class more than once.");
        }
        classElement.patch = element;
      }
      return;
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

  MetadataAnnotation popMetadata() {
    // TODO(ahe): Remove this method.
    popNode(); // Discard null.
    return new PatchMetadataAnnotation();
  }

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
      element.addMetadata(popMetadata());
    }
    super.addMember(element);
  }
}

// TODO(ahe): Get rid of this class.
class PatchMetadataAnnotation extends MetadataAnnotation {
  final leg.Constant value = null;

  PatchMetadataAnnotation() : super(STATE_DONE);
}
