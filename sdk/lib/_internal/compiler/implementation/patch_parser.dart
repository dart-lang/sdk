// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This library contains the infrastructure to parse and integrate patch files.
 *
 * Three types of elements can be patched: [LibraryElement], [ClassElement],
 * [FunctionElement]. Patches are introduced in patch libraries which are loaded
 * together with the corresponding origin library. Which libraries that are
 * patched is determined by the dart2jsPatchPath field of LibraryInfo found
 * in [:lib/_internal/libraries.dart:].
 *
 * Patch libraries are parsed like regular library and thus provided with their
 * own elements. These elements which are distinct from the elements from the
 * patched library and the relation between patched and patch elements is
 * established through the [:patch:] and [:origin:] fields found on
 * [LibraryElement], [ClassElement] and [FunctionElement]. The [:patch:] fields
 * are set on the patched elements to point to their corresponding patch
 * element, and the [:origin:] elements are set on the patch elements to point
 * their corresponding patched elements.
 *
 * The fields [Element.isPatched] and [Element.isPatch] can be used to determine
 * whether the [:patch:] or [:origin:] field, respectively, has been set on an
 * element, regardless of whether the element is one of the three patchable
 * element types or not.
 *
 * ## Variants of classes and functions ##
 *
 * With patches there are four variants of classes and function:
 *
 * Regular: A class or function which is not declared in a patch library and
 *   which has no corresponding patch.
 * Origin: A class or function which is not declared in a patch library and
 *   which has a corresponding patch. Origin functions must use the [:external:]
 *   modifier and can have no body. Origin classes and functions are also
 *   called 'patched'.
 * Patch: A class or function which is declared in a patch library and which
 *   has a corresponding origin. Both patch classes and patch functions must use
 *   the [:patch:] modifier.
 * Injected: A class or function (or even field) which is declared in a
 *   patch library and which has no corresponding origin. An injected element
 *   cannot use the [:patch:] modifier. Injected elements are never visible from
 *   outside the patch library in which they have been declared. For this
 *   reason, injected elements are often declared private and therefore called
 *   also called 'patch private'.
 *
 * Examples of the variants is shown in the code below:
 *
 *     // In the origin library:
 *     class RegularClass { // A regular class.
 *       void regularMethod() {} // A regular method.
 *     }
 *     class PatchedClass { // An origin class.
 *       int regularField; // A regular field.
 *       void regularMethod() {} // A regular method.
 *       external void patchedMethod(); // An origin method.
 *     }
 *
 *     // In the patch library:
 *     class _InjectedClass { // An injected class.
 *       void _injectedMethod() {} // An injected method.
 *     }
 *     patch class PatchedClass { // A patch class.
 *       int _injectedField; { // An injected field.
 *       patch void patchedMethod() {} // A patch method.
 *     }
 *
 *
 * ## Declaration and implementation ##
 *
 * With patches we have two views on elements: as the 'declaration' which
 * introduces the entity and defines its interface, and as the 'implementation'
 * which defines the actual implementation of the entity.
 *
 * Every element has a 'declaration' and an 'implementation' element. For
 * regular and injected elements these are the same. For origin elements the
 * declaration is the element itself and the implementation is the patch element
 * found through its [:patch:] field. For patch elements the implementation is
 * the element itself and the declaration is the origin element found through
 * its [:origin:] field. The declaration and implementation of any element is
 * conveniently available through the [Element.declaration] and
 * [Element.implementation] getters.
 *
 * Most patch-related invariants enforced through-out the compiler are defined
 * in terms of 'declaration' and 'implementation', and tested through the
 * predicate getters [Element.isDeclaration] and [Element.isImplementation].
 * Patch invariants are stated both in comments and as assertions.
 *
 *
 * ## General invariant guidelines ##
 *
 * For [LibraryElement] we always use declarations. This means the
 * [Element.getLibrary] method will only return library declarations. Patch
 * library implementations are only accessed through calls to
 * [Element.getImplementationLibrary] which is used to setup the correct
 * [Element.enclosingElement] relation between patch/injected elements and the
 * patch library.
 *
 * For [ClassElement] and [FunctionElement] we use declarations for determining
 * identity and implementations for work based on the AST nodes, such as
 * resolution, type-checking, type inference, building SSA graphs, etc.
 * - Worklist only contain declaration elements.
 * - Most maps and sets use declarations exclusively, and their individual
 *   invariants are stated in the field comments.
 * - [tree.TreeElements] only map to patch elements from inside a patch library.
 *   TODO(johnniwinther): Simplify this invariant to use only declarations in
 *   [tree.TreeElements].
 * - Builders shift between declaration and implementation depending on usages.
 * - Compile-time constants use constructor implementation exclusively.
 * - Work on function parameters is performed on the declaration of the function
 *   element.
 */

library patchparser;

import 'dart:async';

import "tree/tree.dart" as tree;
import "dart2jslib.dart" as leg;  // CompilerTask, Compiler.
import "scanner/scannerlib.dart";  // Scanner, Parsers, Listeners
import "elements/elements.dart";
import "elements/modelx.dart"
    show LibraryElementX,
         MetadataAnnotationX,
         ClassElementX,
         FunctionElementX;
import 'util/util.dart';

class PatchParserTask extends leg.CompilerTask {
  PatchParserTask(leg.Compiler compiler): super(compiler);
  final String name = "Patching Parser";

  /**
   * Scans a library patch file, applies the method patches and
   * injections to the library, and returns a list of class
   * patches.
   */
  Future patchLibrary(leg.LibraryDependencyHandler handler,
                      Uri patchUri, LibraryElement originLibrary) {
    return compiler.readScript(originLibrary, patchUri)
        .then((leg.Script script) {
      var patchLibrary = new LibraryElementX(script, null, originLibrary);
      return compiler.withCurrentElement(patchLibrary, () {
        handler.registerNewLibrary(patchLibrary);
        var imports = new LinkBuilder<tree.LibraryTag>();
        compiler.withCurrentElement(patchLibrary.entryCompilationUnit, () {
          // This patches the elements of the patch library into [library].
          // Injected elements are added directly under the compilation unit.
          // Patch elements are stored on the patched functions or classes.
          scanLibraryElements(patchLibrary.entryCompilationUnit, imports);
        });
        // TODO(rnystrom): Remove .toList() here if #11523 is fixed.
        return Future.forEach(imports.toLink().toList(), (tag) {
          return compiler.withCurrentElement(patchLibrary, () {
            return compiler.libraryLoader.registerLibraryFromTag(
                handler, patchLibrary, tag);
          });
        });
      });
    });
  }

  void scanLibraryElements(
        CompilationUnitElement compilationUnit,
        LinkBuilder<tree.LibraryTag> imports) {
    measure(() {
      // TODO(lrn): Possibly recursively handle 'part' directives in patch.
      leg.Script script = compilationUnit.script;
      Token tokens = new Scanner(script.file).tokenize();
      Function idGenerator = compiler.getNextFreeClassId;
      PatchListener patchListener =
          new PatchElementListener(compiler,
                                   compilationUnit,
                                   idGenerator,
                                   imports);
      new PatchParser(patchListener).parseUnit(tokens);
    });
  }

  void parsePatchClassNode(PartialClassElement element) {
    // Parse [PartialClassElement] using a "patch"-aware parser instead
    // of calling its [parseNode] method.
    if (element.cachedNode != null) return;

    measure(() => compiler.withCurrentElement(element, () {
      PatchMemberListener listener = new PatchMemberListener(compiler, element);
      Parser parser = new PatchClassElementParser(listener);
      Token token = parser.parseTopLevelDeclaration(element.beginToken);
      assert(identical(token, element.endToken.next));
      element.cachedNode = listener.popNode();
      assert(listener.nodes.isEmpty);

      Link<Element> patches = element.localMembers;
      applyContainerPatch(element.origin, patches);
    }));
  }

  void applyContainerPatch(ClassElement originClass,
                           Link<Element> patches) {
    for (Element patch in patches) {
      if (!isPatchElement(patch)) continue;

      Element origin = originClass.localLookup(patch.name);
      patchElement(compiler, origin, patch);
    }
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

  bool isPatch(Token token) => token.value == 'patch';

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
    if (identical(value, 'interface')
        || identical(value, 'typedef')
        || identical(value, '#')
        || identical(value, 'abstract')) {
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
  final LinkBuilder<tree.LibraryTag> imports;
  bool isMemberPatch = false;
  bool isClassPatch = false;

  PatchElementListener(leg.DiagnosticListener listener,
                       CompilationUnitElement patchElement,
                       int idGenerator(),
                       this.imports)
    : super(listener, patchElement, idGenerator);

  MetadataAnnotation popMetadataHack() {
    // TODO(ahe): Remove this method.
    popNode(); // Discard null.
    return new PatchMetadataAnnotation();
  }

  void beginPatch(Token token) {
    if (identical(token.next.stringValue, "class")) {
      isClassPatch = true;
    } else {
      isMemberPatch = true;
    }
    handleIdentifier(token);
  }

  void endPatch(Token token) {
    if (identical(token.next.stringValue, "class")) {
      isClassPatch = false;
    } else {
      isMemberPatch = false;
    }
  }

  /**
    * Allow script tags (import only, the parser rejects the rest for now) in
    * patch files. The import tags will be added to the library.
    */
  bool allowLibraryTags() => true;

  void addLibraryTag(tree.LibraryTag tag) {
    super.addLibraryTag(tag);
    imports.addLast(tag);
  }

  void pushElement(Element patch) {
    if (isMemberPatch || (isClassPatch && patch is ClassElement)) {
      // Apply patch.
      patch.addMetadata(popMetadataHack());
      LibraryElement originLibrary = compilationUnitElement.getLibrary();
      assert(originLibrary.isPatched);
      Element origin = originLibrary.localLookup(patch.name);
      patchElement(listener, origin, patch);
    }
    super.pushElement(patch);
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

  MetadataAnnotation popMetadataHack() {
    // TODO(ahe): Remove this method.
    popNode(); // Discard null.
    return new PatchMetadataAnnotation();
  }

  void beginPatch(Token token) {
    if (identical(token.next.stringValue, "class")) {
      isClassPatch = true;
    } else {
      isMemberPatch = true;
    }
    handleIdentifier(token);
  }

  void endPatch(Token token) {
    if (identical(token.next.stringValue, "class")) {
      isClassPatch = false;
    } else {
      isMemberPatch = false;
    }
  }

  void addMember(Element element) {
    if (isMemberPatch || (isClassPatch && element is ClassElement)) {
      element.addMetadata(popMetadataHack());
    }
    super.addMember(element);
  }
}

// TODO(ahe): Get rid of this class.
class PatchMetadataAnnotation extends MetadataAnnotationX {
  final leg.Constant value = null;

  PatchMetadataAnnotation() : super(STATE_DONE);

  tree.Node parseNode(leg.DiagnosticListener listener) => null;

  Token get beginToken => null;
  Token get endToken => null;
}

void patchElement(leg.DiagnosticListener listener,
                   Element origin,
                   Element patch) {
  if (origin == null) {
    listener.reportError(
        patch, leg.MessageKind.PATCH_NON_EXISTING, {'name': patch.name});
    return;
  }
  if (!(origin.isClass() ||
        origin.isConstructor() ||
        origin.isFunction() ||
        origin.isAbstractField())) {
    // TODO(ahe): Remove this error when the parser rejects all bad modifiers.
    listener.reportError(origin, leg.MessageKind.PATCH_NONPATCHABLE);
    return;
  }
  if (patch.isClass()) {
    tryPatchClass(listener, origin, patch);
  } else if (patch.isGetter()) {
    tryPatchGetter(listener, origin, patch);
  } else if (patch.isSetter()) {
    tryPatchSetter(listener, origin, patch);
  } else if (patch.isConstructor()) {
    tryPatchConstructor(listener, origin, patch);
  } else if(patch.isFunction()) {
    tryPatchFunction(listener, origin, patch);
  } else {
    // TODO(ahe): Remove this error when the parser rejects all bad modifiers.
    listener.reportError(patch, leg.MessageKind.PATCH_NONPATCHABLE);
  }
}

void tryPatchClass(leg.DiagnosticListener listener,
                    Element origin,
                    ClassElement patch) {
  if (!origin.isClass()) {
    listener.reportError(
        origin, leg.MessageKind.PATCH_NON_CLASS, {'className': patch.name});
    listener.reportInfo(
        patch, leg.MessageKind.PATCH_POINT_TO_CLASS, {'className': patch.name});
    return;
  }
  patchClass(listener, origin, patch);
}

void patchClass(leg.DiagnosticListener listener,
                ClassElementX origin,
                ClassElementX patch) {
  if (origin.isPatched) {
    listener.internalError(origin,
        "Patching the same class more than once.");
  }
  origin.applyPatch(patch);
}

void tryPatchGetter(leg.DiagnosticListener listener,
                    Element origin,
                    FunctionElement patch) {
  if (!origin.isAbstractField()) {
    listener.reportError(
        origin, leg.MessageKind.PATCH_NON_GETTER, {'name': origin.name});
    listener.reportInfo(
        patch,
        leg.MessageKind.PATCH_POINT_TO_GETTER, {'getterName': patch.name});
    return;
  }
  AbstractFieldElement originField = origin;
  if (originField.getter == null) {
    listener.reportError(
        origin, leg.MessageKind.PATCH_NO_GETTER, {'getterName': patch.name});
    listener.reportInfo(
        patch,
        leg.MessageKind.PATCH_POINT_TO_GETTER, {'getterName': patch.name});
    return;
  }
  patchFunction(listener, originField.getter, patch);
}

void tryPatchSetter(leg.DiagnosticListener listener,
                     Element origin,
                     FunctionElement patch) {
  if (!origin.isAbstractField()) {
    listener.reportError(
        origin, leg.MessageKind.PATCH_NON_SETTER, {'name': origin.name});
    listener.reportInfo(
        patch,
        leg.MessageKind.PATCH_POINT_TO_SETTER, {'setterName': patch.name});
    return;
  }
  AbstractFieldElement originField = origin;
  if (originField.setter == null) {
    listener.reportError(
        origin, leg.MessageKind.PATCH_NO_SETTER, {'setterName': patch.name});
    listener.reportInfo(
        patch,
        leg.MessageKind.PATCH_POINT_TO_SETTER, {'setterName': patch.name});
    return;
  }
  patchFunction(listener, originField.setter, patch);
}

void tryPatchConstructor(leg.DiagnosticListener listener,
                          Element origin,
                          FunctionElement patch) {
  if (!origin.isConstructor()) {
    listener.reportError(
        origin,
        leg.MessageKind.PATCH_NON_CONSTRUCTOR, {'constructorName': patch.name});
    listener.reportInfo(
        patch,
        leg.MessageKind.PATCH_POINT_TO_CONSTRUCTOR,
        {'constructorName': patch.name});
    return;
  }
  patchFunction(listener, origin, patch);
}

void tryPatchFunction(leg.DiagnosticListener listener,
                      Element origin,
                      FunctionElement patch) {
  if (!origin.isFunction()) {
    listener.reportError(
        origin,
        leg.MessageKind.PATCH_NON_FUNCTION, {'functionName': patch.name});
    listener.reportInfo(
        patch,
        leg.MessageKind.PATCH_POINT_TO_FUNCTION, {'functionName': patch.name});
    return;
  }
  patchFunction(listener, origin, patch);
}

void patchFunction(leg.DiagnosticListener listener,
                   FunctionElementX origin,
                   FunctionElementX patch) {
  if (!origin.modifiers.isExternal()) {
    listener.reportError(origin, leg.MessageKind.PATCH_NON_EXTERNAL);
    listener.reportInfo(
        patch,
        leg.MessageKind.PATCH_POINT_TO_FUNCTION, {'functionName': patch.name});
    return;
  }
  if (origin.isPatched) {
    listener.internalError(origin,
        "Trying to patch a function more than once.");
  }
  if (origin.cachedNode != null) {
    listener.internalError(origin,
        "Trying to patch an already compiled function.");
  }
  origin.applyPatch(patch);
}

// TODO(johnniwinther): Add unittest when patch is (real) metadata.
bool isPatchElement(Element element) {
  // TODO(lrn): More checks needed if we introduce metadata for real.
  // In that case, it must have the identifier "native" as metadata.
  for (Link link = element.metadata; !link.isEmpty; link = link.tail) {
    if (link.head is PatchMetadataAnnotation) return true;
  }
  return false;
}
