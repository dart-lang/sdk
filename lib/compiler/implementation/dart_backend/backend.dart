// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class ElementAst {
  final Node ast;
  final TreeElements treeElements;

  ElementAst(this.ast, this.treeElements);

  factory ElementAst.rewrite(compiler, ast, treeElements, stripAsserts) {
    final rewriter =
        new FunctionBodyRewriter(compiler, treeElements, stripAsserts);
    return new ElementAst(rewriter.visit(ast), rewriter.cloneTreeElements);
  }

  ElementAst.forClassLike(this.ast)
      : this.treeElements = new TreeElementMapping();
}

class AggregatedTreeElements extends TreeElementMapping {
  final List<TreeElements> treeElements;

  AggregatedTreeElements() : treeElements = <TreeElements>[];

  Element operator[](Node node) {
    final result = super[node];
    return result !== null ? result : getFirstNotNullResult((e) => e[node]);
  }

  Selector getSelector(Send send) {
    final result = super.getSelector(send);
    return result !== null ?
        result : getFirstNotNullResult((e) => e.getSelector(send));
  }

  DartType getType(TypeAnnotation annotation) {
    final result = super.getType(annotation);
    return result !== null ?
        result : getFirstNotNullResult((e) => e.getType(annotation));
  }

  getFirstNotNullResult(f(TreeElements element)) {
    for (final element in treeElements) {
      final result = f(element);
      if (result !== null) return result;
    }

    return null;
  }
}

class VariableListAst extends ElementAst {
  VariableListAst(ast) : super(ast, new AggregatedTreeElements());

  add(VariableElement element, TreeElements treeElements) {
    AggregatedTreeElements e = this.treeElements;
    e[element.cachedNode] = element;
    e.treeElements.add(treeElements);
  }
}

class FunctionBodyRewriter extends CloningVisitor {
  final Compiler compiler;
  final bool stripAsserts;

  FunctionBodyRewriter(this.compiler, originalTreeElements, this.stripAsserts)
      : super(originalTreeElements);

  visitBlock(Block block) {
    shouldOmit(Statement statement) {
      if (statement is EmptyStatement) return true;
      if (statement is ExpressionStatement) {
        Send send = statement.expression.asSend();
        if (send !== null) {
          Element element = originalTreeElements[send];
          if (stripAsserts && element === compiler.assertMethod) {
            return true;
          }
        }
      }
      return false;
    }

    rewiteStatement(Statement statement) {
      if (statement is Block) {
        Link statements = statement.statements.nodes;
        if (!statements.isEmpty() && statements.tail.isEmpty()) {
          Statement single = statements.head;
          bool isDeclaration =
              single is VariableDefinitions || single is FunctionDeclaration;
          if (!isDeclaration) return single;
        }
      }
      return statement;
    }

    NodeList statements = block.statements;
    LinkBuilder<Statement> builder = new LinkBuilder<Statement>();
    for (Statement statement in statements.nodes) {
      if (!shouldOmit(statement)) {
        builder.addLast(visit(rewiteStatement(statement)));
      }
    }
    return new Block(rewriteNodeList(statements, builder.toLink()));
  }
}

class DartBackend extends Backend {
  final List<CompilerTask> tasks;
  final bool forceStripTypes;
  final bool stripAsserts;
  // TODO(antonm): make available from command-line options.
  final bool outputAst = false;

  Map<Element, TreeElements> get resolvedElements =>
      compiler.enqueuer.resolution.resolvedElements;

  /**
   * Tells whether it is safe to remove type declarations from variables,
   * functions parameters. It becomes not safe if:
   * 1) TypeError is used somewhere in the code,
   * 2) The code has typedefs in right hand side of IS checks,
   * 3) The code has classes which extend typedefs, have type arguments typedefs
   *    or type variable bounds typedefs.
   * These restrictions can be less strict.
   */
  bool isSafeToRemoveTypeDeclarations(
      Map<ClassElement, Set<Element>> classMembers) {
    Set<DartType> processedTypes = new Set<DartType>();
    List<DartType> workQueue = new List<DartType>();
    workQueue.addAll(
        classMembers.getKeys().map((classElement) => classElement.type));
    workQueue.addAll(compiler.resolverWorld.isChecks);
    Element typeErrorElement =
        compiler.coreLibrary.find(new SourceString('TypeError'));
    DartType typeErrorType = typeErrorElement.computeType(compiler);
    if (workQueue.indexOf(typeErrorType) != -1) {
      return false;
    }

    void processTypeArguments(Element classElement, NodeList typeArguments) {
      if (typeArguments == null) return;
      for (Node typeArgument in typeArguments.nodes) {
        if (typeArgument is TypeVariable) {
          typeArgument = typeArgument.bound;
        }
        if (typeArgument == null) continue;
        assert(typeArgument is TypeAnnotation);
        DartType argumentType =
            compiler.resolveTypeAnnotation(classElement, typeArgument);
        assert(argumentType !== null);
        workQueue.add(argumentType);
      }
    }

    while (!workQueue.isEmpty()) {
      DartType type = workQueue.removeLast();
      if (processedTypes.contains(type)) continue;
      processedTypes.add(type);
      if (type is TypedefType) return false;
      if (type is InterfaceType) {
        ClassElement element = type.element;
        ClassNode node = element.parseNode(compiler);
        // Check class type args.
        processTypeArguments(element, node.typeParameters);
        // Check superclass type args.
        if (node.superclass !== null) {
          NodeList typeArguments = node.superclass.typeArguments;
          processTypeArguments(element, node.superclass.typeArguments);
        }
        // Check interfaces type args.
        for (Node interfaceNode in node.interfaces) {
          processTypeArguments(
              element, (interfaceNode as TypeAnnotation).typeArguments);
        }
        // Check all supertypes.
        if (element.allSupertypes !== null) {
          workQueue.addAll(element.allSupertypes.toList());
        }
      }
    }
    return true;
  }

  DartBackend(Compiler compiler, List<String> strips)
      : tasks = <CompilerTask>[],
        forceStripTypes = strips.indexOf('types') != -1,
        stripAsserts = strips.indexOf('asserts') != -1,
        super(compiler);

  Element getInterceptor(Selector selector) => null;

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

  bool isUserLibrary(LibraryElement lib) {
    final INTERNAL_HELPERS = [
      compiler.jsHelperLibrary,
      compiler.interceptorsLibrary,
    ];
    return INTERNAL_HELPERS.indexOf(lib) == -1 && !lib.isPlatformLibrary;
  }

  void assembleProgram() {
    // Conservatively traverse all platform libraries and collect member names.
    // TODO(antonm): ideally we should only collect names of used members,
    // however as of today there are problems with names of some core library
    // interfaces, most probably for interfaces of literals.
    final fixedMemberNames = new Set<String>();
    for (final library in compiler.libraries.getValues()) {
      if (!library.isPlatformLibrary) continue;
      library.implementation.forEachLocalMember((Element element) {
        if (element is ClassElement) {
          ClassElement classElement = element;
          // Make sure we parsed the class to initialize its local members.
          // TODO(smok): Figure out if there is a better way to fill local
          // members.
          element.parseNode(compiler);
          for (final member in classElement.localMembers) {
            final name = member.name.slowToString();
            // Skip operator names.
            if (name.startsWith(r'operator$')) continue;
            // Fetch name of named constructors and factories if any,
            // otherwise store regular name.
            // TODO(antonm): better way to analyze the name.
            fixedMemberNames.add(name.split(r'$').last());
          }
        }
        // Even class names are added due to a delicate problem we have:
        // if one imports dart:core with a prefix, we cannot tell prefix.name
        // from dynamic invocation (alas!).  So we'd better err on preserving
        // those names.
        fixedMemberNames.add(element.name.slowToString());
      });
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
    bool shouldOutput(Element element) =>
      element.kind !== ElementKind.VOID &&
      isUserLibrary(element.getLibrary()) &&
      element is !SynthesizedConstructorElement &&
      element is !AbstractFieldElement;

    final elementAsts = new Map<Element, ElementAst>();

    parse(element) => element.parseNode(compiler);

    Set<Element> topLevelElements = new Set<Element>();
    Map<ClassElement, Set<Element>> classMembers =
        new Map<ClassElement, Set<Element>>();

    // Build all top level elements to emit and necessary class members.
    var newTypedefElementCallback, newClassElementCallback;

    processElement(element, elementAst) {
      new ReferencedElementCollector(
          compiler,
          element, elementAst.treeElements,
          newTypedefElementCallback, newClassElementCallback).collect();
      elementAsts[element] = elementAst;
    }

    addTopLevel(element, elementAst) {
      if (topLevelElements.contains(element)) return;
      topLevelElements.add(element);
      processElement(element, elementAst);
    }
    addClass(classElement) {
      addTopLevel(classElement,
                  new ElementAst.forClassLike(parse(classElement)));
      classMembers.putIfAbsent(classElement, () => new Set());
    }

    newTypedefElementCallback = (TypedefElement element) {
      if (!shouldOutput(element)) return;
      addTopLevel(element,
                  new ElementAst.forClassLike(parse(element)));
    };
    newClassElementCallback = (ClassElement classElement) {
      if (!shouldOutput(classElement)) return;
      addClass(classElement);
    };

    resolvedElements.forEach((element, treeElements) {
      if (!shouldOutput(element)) return;

      var elementAst = new ElementAst.rewrite(
          compiler, parse(element), treeElements, stripAsserts);
      if (element.isField()) {
        final list = (element as VariableElement).variables;
        elementAst = elementAsts.putIfAbsent(
            list, () => new VariableListAst(parse(list)));
        (elementAst as VariableListAst).add(element, treeElements);
        element = list;
      }

      if (element.isMember()) {
        ClassElement enclosingClass = element.getEnclosingClass();
        assert(enclosingClass.isClass());
        assert(enclosingClass.isTopLevel());
        assert(shouldOutput(enclosingClass));
        addClass(enclosingClass);
        classMembers[enclosingClass].add(element);
        processElement(element, elementAst);
      } else {
        if (!element.isTopLevel()) {
          compiler.cancel(reason: 'Cannot process $element', element: element);
        }
        addTopLevel(element, elementAst);
      }
    });

    // Add synthesized constructors to classes with no resolved constructors,
    // but which originally had any constructor.  That should prevent
    // those classes from being instantiable with default constructor.
    Identifier synthesizedIdentifier =
        new Identifier(new StringToken(IDENTIFIER_INFO, '', -1));

    NextClassElement:
    for (ClassElement classElement in classMembers.getKeys()) {
      for (Element member in classMembers[classElement]) {
        if (member.isConstructor()) continue NextClassElement;
      }
      if (classElement.constructors.isEmpty()) continue NextClassElement;

      // TODO(antonm): check with AAR team if there is better approach.
      // As an idea: provide template as a Dart code---class C { C.name(); }---
      // and then overwrite necessary parts.
      SynthesizedConstructorElement constructor =
          new SynthesizedConstructorElement(classElement);
      constructor.type = new FunctionType(
          compiler.types.voidType, const EmptyLink<DartType>(),
          constructor);
      constructor.cachedNode = new FunctionExpression(
          new Send(receiver: classElement.parseNode(compiler).name,
                   selector: synthesizedIdentifier),
          new NodeList(beginToken: new StringToken(OPEN_PAREN_INFO, '(', -1),
                       endToken: new StringToken(CLOSE_PAREN_INFO, ')', -1),
                       nodes: const EmptyLink<Node>()),
          new EmptyStatement(new StringToken(SEMICOLON_INFO, ';', -1)),
          null, Modifiers.EMPTY, null, null);

      classMembers[classElement].add(constructor);
      elementAsts[constructor] =
          new ElementAst(constructor.cachedNode, new TreeElementMapping());
    }

    // Create all necessary placeholders.
    PlaceholderCollector collector =
        new PlaceholderCollector(compiler, fixedMemberNames, elementAsts);
    // Add synthesizedIdentifier to set of unresolved names to rename it to
    // some unused identifier.
    collector.unresolvedNodes.add(synthesizedIdentifier);
    makePlaceholders(element) {
      collector.collect(element);
      if (element is ClassElement) {
        classMembers[element].forEach(makePlaceholders);
      }
    }
    topLevelElements.forEach(makePlaceholders);
    // Create renames.
    Map<Node, String> renames = new Map<Node, String>();
    Map<LibraryElement, String> imports = new Map<LibraryElement, String>();
    bool shouldCutDeclarationTypes = forceStripTypes
        || (compiler.enableMinification
            && isSafeToRemoveTypeDeclarations(classMembers));
    renamePlaceholders(
        compiler, collector, renames, imports,
        fixedMemberNames, shouldCutDeclarationTypes);

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
      outputElement(element) { sb.add(parse(element).toDebugString()); }

      // Emit XML for AST instead of the program.
      for (final topLevel in sortedTopLevels) {
        if (topLevel is ClassElement) {
          // TODO(antonm): add some class info.
          sortedClassMembers[topLevel].forEach(outputElement);
        } else {
          outputElement(topLevel);
        }
      }
      compiler.assembledCode = '<Program>\n$sb</Program>\n';
      return;
    }

    final topLevelNodes = <Node>[];
    final memberNodes = new Map<ClassNode, List<Node>>();
    for (final element in sortedTopLevels) {
      topLevelNodes.add(elementAsts[element].ast);
      if (element is ClassElement) {
        final members = <Node>[];
        for (final member in sortedClassMembers[element]) {
          members.add(elementAsts[member].ast);
        }
        memberNodes[elementAsts[element].ast] = members;
      }
    }

    final unparser = new EmitterUnparser(renames);
    emitCode(unparser, imports, topLevelNodes, memberNodes);
    compiler.assembledCode = unparser.result;

    // Output verbose info about size ratio of resulting bundle to all
    // referenced non-platform sources.
    logResultBundleSizeInfo(topLevelElements);
  }

  void logResultBundleSizeInfo(Set<Element> topLevelElements) {
    Collection<LibraryElement> referencedLibraries =
        compiler.libraries.getValues().filter(isUserLibrary);
    // Sum total size of scripts in each referenced library.
    int nonPlatformSize = 0;
    for (LibraryElement lib in referencedLibraries) {
      for (CompilationUnitElement compilationUnit in lib.compilationUnits) {
        nonPlatformSize += compilationUnit.script.text.length;
      }
    }
    int percentage = compiler.assembledCode.length * 100 ~/ nonPlatformSize;
    log('Total used non-platform files size: ${nonPlatformSize} bytes, '
        'bundle size: ${compiler.assembledCode.length} bytes (${percentage}%)');
  }

  log(String message) => compiler.log('[DartBackend] $message');
}

class EmitterUnparser extends Unparser {
  final Map<Node, String> renames;

  EmitterUnparser(this.renames);

  visit(Node node) {
    if (node !== null && renames.containsKey(node)) {
      sb.add(renames[node]);
    } else {
      super.visit(node);
    }
  }

  unparseSendReceiver(Send node, [bool spacesNeeded=false]) {
    // TODO(smok): Remove ugly hack for library prefices.
    if (node.receiver !== null && renames[node.receiver] == '') return;
    super.unparseSendReceiver(node, spacesNeeded);
  }
}


/**
 * Some elements are not recorded by resolver now,
 * for example, typedefs or classes which are only
 * used in signatures, as/is operators or in super clauses
 * (just to name a few).  Retraverse AST to pick those up.
 */
class ReferencedElementCollector extends Visitor {
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
    // We call [resolveReturnType] to allow having 'void'.
    final type = compiler.resolveReturnType(rootElement, typeAnnotation);
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
