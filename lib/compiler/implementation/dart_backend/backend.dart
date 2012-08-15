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

  void codegen(WorkItem work) { }

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
    Set<ClassElement> classes = new Set<ClassElement>();
    PlaceholderCollector collector = new PlaceholderCollector(compiler);
    resolvedElements.forEach((element, treeElements) {
      if (!shouldOutput(element)) return;
      if (element is AbstractFieldElement) return;
      collector.collect(element, treeElements);
      new ReferencedElementCollector(
          compiler, element, treeElements, typedefs, classes)
      .collect();
    });
    final emptyTreeElements = new TreeElementMapping();
    collectElement(element) { collector.collect(element, emptyTreeElements); }
    typedefs.forEach(collectElement);
    classes.forEach(collectElement);

    ConflictingRenamer renamer =
        new ConflictingRenamer(compiler, collector);
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
    final emptySet = new Set<Element>();
    classes.forEach((classElement) {
      if (!shouldOutput(classElement)) return;
      if (resolvedClassMembers.containsKey(classElement)) return;
      emitter.outputClass(classElement, emptySet);
    });

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
  final Element rootElement;
  final TreeElements treeElements;
  final Set<TypedefElement> typedefs;
  final Set<ClassElement> classes;

  ReferencedElementCollector(
      this.compiler,
      this.rootElement, this.treeElements,
      this.typedefs, this.classes);

  void collectElement(Element element) {
    new ReferencedElementCollector(
        compiler, element, new TreeElementMapping(), typedefs, classes)
    .collect();
  }

  visitClassNode(ClassNode node) {
    super.visitClassNode(node);
    // Temporary hack which should go away once interfaces
    // and default clauses are out.
    if (node.defaultClause !== null) {
      // Resolver cannot resolve parameterized default clauses.
      TypeAnnotation evilCousine = new TypeAnnotation(
          node.defaultClause.typeName, null);
      evilCousine.accept(this);
    }
  }

  visitNode(Node node) { node.visitChildren(this); }

  visitTypeAnnotation(TypeAnnotation typeAnnotation) {
    final type = compiler.resolveTypeAnnotation(rootElement, typeAnnotation);
    Element typeElement = type.element;
    if (typeElement.isTypedef() && !typedefs.contains(typeElement)) {
      typedefs.add(typeElement);
      collectElement(typeElement);
    }
    if (typeElement.isClass() && !classes.contains(typeElement)) {
      classes.add(typeElement);
      collectElement(typeElement);
    }
    typeAnnotation.visitChildren(this);
  }

  void collect() {
    compiler.withCurrentElement(rootElement, () {
      rootElement.parseNode(compiler).accept(this);
    });
  }
}
