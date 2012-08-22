// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class DartBackend extends Backend {
  final List<CompilerTask> tasks;

  Map<Element, TreeElements> get resolvedElements =>
      compiler.enqueuer.resolution.resolvedElements;

  DartBackend(Compiler compiler, [bool validateUnparse = false])
      : tasks = <CompilerTask>[],
      super(compiler);

  void enqueueHelpers(Enqueuer world) { }
  void codegen(WorkItem work) { }
  void processNativeClasses(Enqueuer world,
                            Collection<LibraryElement> libraries) { }

  void assembleProgram() {
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
    Map<ClassElement, Set<Element>> classMembers =
        new Map<ClassElement, Set<Element>>();

    // Build all top level elements to emit and necessary class members.
    var newTypedefElementCallback, newClassElementCallback;

    processElement(element, treeElements) {
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
      addTopLevel(classElement, emptyTreeElements);
      classMembers.putIfAbsent(classElement, () => new Set());
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
        classMembers[enclosingClass].add(element);
        processElement(element, treeElements);
      } else {
        if (!element.isTopLevel()) {
          compiler.cancel(reason: 'Cannot process $element', element: element);
        }
        addTopLevel(element, treeElements);
      }
    });

    // Create all necessary placeholders.
    PlaceholderCollector collector = new PlaceholderCollector(compiler);
    makePlaceholders(element) {
      TreeElements treeElements = resolvedElements[element];
      if (treeElements === null) treeElements = emptyTreeElements;
      collector.collect(element, treeElements);
      if (element is ClassElement) {
        classMembers[element].forEach(makePlaceholders);
      }
    }
    topLevelElements.forEach(makePlaceholders);

    // Create renames.
    Map<Node, String> renames = new Map<Node, String>();
    Map<LibraryElement, String> imports = new Map<LibraryElement, String>();
    renamePlaceholders(compiler, collector, renames, imports);

    // Sort elements.
    final sortedTopLevels = sortElements(topLevelElements);
    final sortedClassMembers = new Map<ClassElement, List<Element>>();
    classMembers.forEach((classElement, members) {
      sortedClassMembers[classElement] = sortElements(members);
    });

    final unparser = new Unparser.withRenamer((Node node) => renames[node]);
    compiler.assembledCode = emitCode(
        compiler, unparser, imports, sortedTopLevels, sortedClassMembers);
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
      Element rootElement, this.treeElements,
      this.newTypedefElementCallback, this.newClassElementCallback)
      : this.rootElement = (rootElement is VariableElement)
          ? (rootElement as VariableElement).variables : rootElement;

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

compareBy(f) => (x, y) => f(x).compareTo(f(y));

List sorted(Iterable l, comparison) {
  final result = new List.from(l);
  result.sort(comparison);
  return result;
}

List<Element> sortElements(Collection<Element> elements) {
  compareElements(e0, e1) {
    int result = compareBy((e) => e.getLibrary().uri.toString())(e0, e1);
    if (result != 0) return result;
    return compareBy((e) => e.position().charOffset)(e0, e1);
  }

  return sorted(elements, compareElements);
}
