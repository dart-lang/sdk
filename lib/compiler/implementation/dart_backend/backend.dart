// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class DartBackend extends Backend {
  final List<CompilerTask> tasks;
  final UnparseValidator unparseValidator;

  Map<Element, TreeElements> get resolvedElements() =>
      compiler.enqueuer.resolution.resolvedElements;

  DartBackend(Compiler compiler, [bool validateUnparse = false])
      : tasks = <CompilerTask>[],
      unparseValidator = new UnparseValidator(compiler, validateUnparse),
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
      !isDartCoreLib(compiler, element.getLibrary()) &&
      element is !AbstractFieldElement;

    final emptyTreeElements = new TreeElementMapping();

    Set<Element> topLevelElements = new Set<Element>();
    Map<ClassElement, Set<Element>> classes =
        new Map<ClassElement, Set<Element>>();

    PlaceholderCollector collector = new PlaceholderCollector(compiler);
    var newTypedefElementCallback, newClassElementCallback;

    processElement(element, treeElements) {
      collector.collect(element, treeElements);
      new ReferencedElementCollector(
          compiler,
          element, treeElements,
          newTypedefElementCallback, newClassElementCallback).collect();
    }

    addTopLevel(element, treeElements) {
      if (topLevelElements.contains(element)) return;
      topLevelElements.add(element);
      processElement(element, treeElements);
    }
    addClass(classElement) {
      if (classes.containsKey(classElement)) return;
      classes[classElement] = new Set<Element>();
      processElement(classElement, emptyTreeElements);
    }

    newTypedefElementCallback = (TypedefElement element) {
      if (!shouldOutput(element)) return;
      addTopLevel(element, emptyTreeElements);
    };
    newClassElementCallback = (ClassElement classElement) {
      if (!shouldOutput(classElement)) return;
      addClass(classElement);
    };

    resolvedElements.forEach((element, treeElements) {
      if (!shouldOutput(element)) return;

      if (element.isMember()) {
        ClassElement enclosingClass = element.getEnclosingClass();
        assert(enclosingClass.isClass());
        assert(enclosingClass.isTopLevel());
        assert(shouldOutput(enclosingClass));
        addClass(enclosingClass);
        classes[enclosingClass].add(element);
        processElement(element, treeElements);
      } else {
        if (!element.isTopLevel()) {
          compiler.cancel(reason: 'Cannot process $element', element: element);
        }
        addTopLevel(element, treeElements);
      }
    });

    Map<Node, String> renames = new Map<Node, String>();
    Map<LibraryElement, String> imports = new Map<LibraryElement, String>();
    renamePlaceholders(compiler, collector, renames, imports);

    Emitter emitter = new Emitter(compiler, renames);
    emitter.outputImports(imports);
    topLevelElements.forEach(emitter.outputElement);
    classes.forEach(emitter.outputClass);

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
  final newTypedefElementCallback;
  final newClassElementCallback;

  ReferencedElementCollector(
      this.compiler,
      this.rootElement, this.treeElements,
      this.newTypedefElementCallback, this.newClassElementCallback);

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
    if (typeElement.isTypedef()) newTypedefElementCallback(typeElement);
    if (typeElement.isClass()) newClassElementCallback(typeElement);
    typeAnnotation.visitChildren(this);
  }

  void collect() {
    compiler.withCurrentElement(rootElement, () {
      rootElement.parseNode(compiler).accept(this);
    });
  }
}
