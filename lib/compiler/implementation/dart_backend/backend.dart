// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class DartBackend extends Backend {
  final List<CompilerTask> tasks;
  final UnparseValidator unparseValidator;

  Map<Element, TreeElements> get resolvedElements() =>
      compiler.enqueuer.resolution.resolvedElements;
  Map<ClassElement, Set<Element>> resolvedClassMembers;

  DartBackend(Compiler compiler, [bool validateUnparse = false])
      : tasks = <CompilerTask>[],
      unparseValidator = new UnparseValidator(compiler, validateUnparse),
      resolvedClassMembers = new Map<ClassElement, Set<Element>>(),
      super(compiler) {
    tasks.add(unparseValidator);
  }

  void enqueueHelpers(Enqueuer world) {
    // TODO(antonm): Implement this method, if needed.
  }

  CodeBuffer codegen(WorkItem work) { return new CodeBuffer(); }

  void processNativeClasses(Enqueuer world,
                            Collection<LibraryElement> libraries) {
  }

  /**
   * Adds given class element with its member element to resolved classes
   * collections.
   */
  void addMemberToClass(Element element, ClassElement classElement) {
    // ${element} should have ${classElement} as enclosing.
    assert(element.isMember());
    Set<Element> resolvedElementsInClass = resolvedClassMembers.putIfAbsent(
        classElement, () => new Set<Element>());
    resolvedElementsInClass.add(element);
  }

  void assembleProgram() {
    resolvedElements.forEach((element, treeElements) {
      unparseValidator.check(element);
    });

    /**
     * Tells whether we should output given element. Corelib classes like
     * Object should not be in the resulting code.
     */
    final LIBS_TO_IGNORE = [
      compiler.jsHelperLibrary,
      compiler.interceptorsLibrary,
    ];
    bool shouldOutput(Element element) =>
      element.kind !== ElementKind.VOID &&
      LIBS_TO_IGNORE.indexOf(element.getLibrary()) == -1 &&
      !isDartCoreLib(compiler, element.getLibrary());

    Set<TypedefElement> typedefs = new Set<TypedefElement>();
    PlaceholderCollector collector = new PlaceholderCollector(compiler);
    resolvedElements.forEach((element, treeElements) {
      if (!shouldOutput(element)) return;
      if (element is AbstractFieldElement) return;
      collector.collect(element, treeElements);
      new ReferencedElementCollector(
          compiler, element, treeElements, typedefs)
      .collect();
    });

    ConflictingRenamer renamer =
        new ConflictingRenamer(compiler, collector.placeholders);
    Emitter emitter = new Emitter(compiler, renamer);
    resolvedElements.forEach((element, treeElements) {
      if (!shouldOutput(element)) return;
      if (element.isMember()) {
        ClassElement enclosingClass = element.getEnclosingClass();
        assert(enclosingClass.isClass());
        assert(enclosingClass.isTopLevel());
        addMemberToClass(element, enclosingClass);
        return;
      }
      if (!element.isTopLevel()) {
        compiler.cancel(reason: 'Cannot process $element', element: element);
      }

      emitter.outputElement(element);
    });

    typedefs.forEach(emitter.outputElement);

    // Now output resolved classes with inner elements we met before.
    resolvedClassMembers.forEach(emitter.outputClass);
    compiler.assembledCode = emitter.toString();
  }

  log(String message) => compiler.log('[DartBackend] $message');
}

/**
 * Checks if [:libraryElement:] is a core lib, that is a library
 * provided by the implementation like dart:core, dart:coreimpl, etc.
 */
bool isDartCoreLib(Compiler compiler, LibraryElement libraryElement) {
  final libraries = compiler.libraries;
  for (final uri in libraries.getKeys()) {
    if (libraryElement === libraries[uri]) {
      if (uri.startsWith('dart:')) return true;
    }
  }
  return false;
}

/**
 * Some elements are not recorded by resolver now,
 * for example, typedefs or classes which are only
 * used in signatures, as/is operators or in super clauses
 * (just to name a few).  Retraverse AST to pick those up.
 */
class ReferencedElementCollector extends AbstractVisitor {
  final Compiler compiler;
  final Element element;
  final TreeElements treeElements;
  final Set<TypedefElement> typedefs;

  ReferencedElementCollector(
      this.compiler,
      this.element, this.treeElements,
      this.typedefs);

  visitNode(Node node) { node.visitChildren(this); }

  visitTypeAnnotation(TypeAnnotation typeAnnotation) {
    Element element = treeElements[typeAnnotation];
    if (element !== null) {
      if (element.isTypedef()) typedefs.add(element);
    }
    typeAnnotation.visitChildren(this);
  }

  void collect() {
    element.parseNode(compiler).accept(this);
  }
}
