// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class DartBackend extends Backend {
  final List<CompilerTask> tasks;
  final bool cutDeclarationTypes;
  // TODO(antonm): make available from command-line options.
  final bool outputAst = false;

  Map<Element, TreeElements> get resolvedElements =>
      compiler.enqueuer.resolution.resolvedElements;

  DartBackend(Compiler compiler, this.cutDeclarationTypes)
      : tasks = <CompilerTask>[],
        super(compiler);

  void enqueueHelpers(Enqueuer world) {
    // Right now resolver doesn't always resolve interfaces needed
    // for literals, so force them. TODO(antonm): fix in the resolver.
    final LITERAL_TYPE_NAMES = const [
      'Map', 'List', 'num', 'int', 'double', 'bool'
    ];
    final coreLibrary = compiler.coreLibrary;
    for (final name in LITERAL_TYPE_NAMES) {
      ClassElement classElement = coreLibrary.findLocal(new SourceString(name));
      classElement.ensureResolved(compiler);
    }
  }
  void codegen(WorkItem work) { }
  void processNativeClasses(Enqueuer world,
                            Collection<LibraryElement> libraries) { }

  void assembleProgram() {
    // Conservatively traverse all platform libraries and collect member names.
    // TODO(antonm): ideally we should only collect names of used members,
    // however as of today there are problems with names of some core library
    // interfaces, most probably for interfaces of literals.
    final fixedMemberNames = new Set<String>();
    for (final library in compiler.libraries.getValues()) {
      if (!library.isPlatformLibrary) continue;
      for (final element in library.localMembers) {
        if (element is ClassElement) {
          ClassElement classElement = element;
          for (final member in classElement.localMembers) {
            final name = member.name.slowToString();
            // Skip operator names.
            if (name.startsWith(@'operator$')) continue;
            // Fetch name of named constructors and factories if any,
            // otherwise store regular name.
            // TODO(antonm): better way to analyze the name.
            fixedMemberNames.add(name.split(@'$').last());
          }
        } else {
          fixedMemberNames.add(element.name.slowToString());
        }
      }
    }
    // TODO(antonm): TypeError.srcType and TypeError.dstType are defined in
    // runtime/lib/error.dart. Overall, all DartVM specific libs should be
    // accounted for.
    fixedMemberNames.add('srcType');
    fixedMemberNames.add('dstType');

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
      !element.getLibrary().isPlatformLibrary &&
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
    PlaceholderCollector collector =
        new PlaceholderCollector(compiler, fixedMemberNames);
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
    renamePlaceholders(
        compiler, collector, renames, imports,
        fixedMemberNames, cutDeclarationTypes);

    // Sort elements.
    final sortedTopLevels = sortElements(topLevelElements);
    final sortedClassMembers = new Map<ClassElement, List<Element>>();
    classMembers.forEach((classElement, members) {
      sortedClassMembers[classElement] = sortElements(members);
    });

    if (outputAst) {
      // TODO(antonm): Ideally XML should be a separate backend.
      // TODO(antonm): obey renames and minification, at least as an option.
      StringBuffer sb = new StringBuffer();
      sb.add('<Program>\n');
      outputElement(element) {
        sb.add(element.parseNode(compiler).toDebugString());
      }

      // Emit XML for AST instead of the program.
      for (final topLevel in sortedTopLevels) {
        if (topLevel is ClassElement) {
          // TODO(antonm): add some class info.
          sortedClassMembers[topLevel].forEach(outputElement);
        } else {
          outputElement(topLevel);
        }
      }
      sb.add('</Program>\n');
      compiler.assembledCode = sb.toString();
      return;
    }

    final unparser = new Unparser.withRenamer((Node node) => renames[node]);
    emitCode(compiler, unparser, imports, sortedTopLevels, sortedClassMembers);
    compiler.assembledCode = unparser.result;
  }

  log(String message) => compiler.log('[DartBackend] $message');
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

compareElements(e0, e1) {
  int result = compareBy((e) => e.getLibrary().uri.toString())(e0, e1);
  if (result != 0) return result;
  return compareBy((e) => e.position().charOffset)(e0, e1);
}

List<Element> sortElements(Collection<Element> elements) =>
    sorted(elements, compareElements);
