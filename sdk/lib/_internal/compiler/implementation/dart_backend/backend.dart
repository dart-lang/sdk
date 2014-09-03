// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart_backend;

// TODO(ahe): This class is simply wrong.  This backend should use
// elements when it can, not AST nodes.  Perhaps a [Map<Element,
// TreeElements>] is what is needed.
class ElementAst {
  final Node ast;
  final TreeElements treeElements;

  ElementAst(AstElement element)
      : this.internal(element.resolvedAst.node, element.resolvedAst.elements);

  ElementAst.internal(this.ast, this.treeElements);
}

class DartBackend extends Backend {
  final List<CompilerTask> tasks;
  final bool forceStripTypes;
  final bool stripAsserts;
  // TODO(antonm): make available from command-line options.
  final bool outputAst = false;
  final Map<ClassNode, List<Node>> memberNodes;

  /// If `true`, libraries are generated into separate files.
  final bool multiFile;

  PlaceholderRenamer placeholderRenamer;

  // TODO(zarah) Maybe change this to a command-line option.
  // Right now, it is set by the tests.
  bool useMirrorHelperLibrary = false;

  /// Initialized if the useMirrorHelperLibrary field is set.
  MirrorRenamer mirrorRenamer;

  /// Initialized when dart:mirrors is loaded if the useMirrorHelperLibrary
  /// field is set.
  LibraryElement mirrorHelperLibrary;
  /// Initialized when dart:mirrors is loaded if the useMirrorHelperLibrary
  /// field is set.
  FunctionElement mirrorHelperGetNameFunction;
  /// Initialized when dart:mirrors is loaded if the useMirrorHelperLibrary
  /// field is set.
  Element mirrorHelperSymbolsMap;

  Iterable<Element> get resolvedElements =>
      compiler.enqueuer.resolution.resolvedElements;

  ConstantSystem get constantSystem {
    return constantCompilerTask.constantCompiler.constantSystem;
  }

  BackendConstantEnvironment get constants => constantCompilerTask;

  DartConstantTask constantCompilerTask;

  DartResolutionCallbacks resolutionCallbacks;

  final Set<ClassElement> usedTypeLiterals = new Set<ClassElement>();

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
    ClassElement typeErrorElement = compiler.coreLibrary.find('TypeError');
    if (classMembers.containsKey(typeErrorElement) ||
        compiler.resolverWorld.isChecks.any(
            (DartType type) => type.element == typeErrorElement)) {
      return false;
    }
    Set<DartType> processedTypes = new Set<DartType>();
    List<DartType> workQueue = new List<DartType>();
    workQueue.addAll(
        classMembers.keys.map((classElement) => classElement.thisType));
    workQueue.addAll(compiler.resolverWorld.isChecks);

    while (!workQueue.isEmpty) {
      DartType type = workQueue.removeLast();
      if (processedTypes.contains(type)) continue;
      processedTypes.add(type);
      if (type is FunctionType) return false;
      if (type is TypedefType) return false;
      if (type is InterfaceType) {
        InterfaceType interfaceType = type;
        // Check all type arguments.
        interfaceType.typeArguments.forEach(workQueue.add);
        ClassElement element = type.element;
        // Check all supertypes.
        if (element.allSupertypes != null) {
          element.allSupertypes.forEach(workQueue.add);
        }
      }
    }
    return true;
  }

  DartBackend(Compiler compiler, List<String> strips, {this.multiFile})
      : tasks = <CompilerTask>[],
        memberNodes = new Map<ClassNode, List<Node>>(),
        forceStripTypes = strips.indexOf('types') != -1,
        stripAsserts = strips.indexOf('asserts') != -1,
        constantCompilerTask  = new DartConstantTask(compiler),
        super(compiler) {
    resolutionCallbacks = new DartResolutionCallbacks(this);
  }

  bool classNeedsRti(ClassElement cls) => false;
  bool methodNeedsRti(FunctionElement function) => false;

  void enqueueHelpers(ResolutionEnqueuer world, Registry registry) {
    // Right now resolver doesn't always resolve interfaces needed
    // for literals, so force them. TODO(antonm): fix in the resolver.
    final LITERAL_TYPE_NAMES = const [
      'Map', 'List', 'num', 'int', 'double', 'bool'
    ];
    final coreLibrary = compiler.coreLibrary;
    for (final name in LITERAL_TYPE_NAMES) {
      ClassElement classElement = coreLibrary.findLocal(name);
      classElement.ensureResolved(compiler);
    }
    // Enqueue the methods that the VM might invoke on user objects because
    // we don't trust the resolution to always get these included.
    world.registerInvocation(new Selector.call("toString", null, 0));
    world.registerInvokedGetter(new Selector.getter("hashCode", null));
    world.registerInvocation(new Selector.binaryOperator("=="));
    world.registerInvocation(new Selector.call("compareTo", null, 1));
  }

  void codegen(CodegenWorkItem work) { }

  bool isUserLibrary(LibraryElement lib) => !lib.isPlatformLibrary;

  /**
   * Tells whether we should output given element. Corelib classes like
   * Object should not be in the resulting code.
   */
  bool shouldOutput(Element element) {
    return (isUserLibrary(element.library) &&
            !element.isSynthesized &&
            element is !AbstractFieldElement)
        || element.library == mirrorHelperLibrary;
  }

  /// Create an [ElementAst] from the CPS IR.
  static ElementAst createElementAst(Compiler compiler,
                                     Tracer tracer,
                                     ConstantSystem constantSystem,
                                     Element element,
                                     cps_ir.FunctionDefinition function) {
    // Transformations on the CPS IR.
    if (tracer != null) {
      tracer.traceCompilation(element.name, null);
    }

    void traceGraph(String title, var irObject) {
      if (tracer != null) {
        tracer.traceGraph(title, irObject);
      }
    }

    new ConstantPropagator(compiler, constantSystem).rewrite(function);
    traceGraph("Sparse constant propagation", function);
    new RedundantPhiEliminator().rewrite(function);
    traceGraph("Redundant phi elimination", function);
    new ShrinkingReducer().rewrite(function);
    traceGraph("Shrinking reductions", function);

    // Do not rewrite the IR after variable allocation.  Allocation
    // makes decisions based on an approximation of IR variable live
    // ranges that can be invalidated by transforming the IR.
    new cps_ir.RegisterAllocator().visit(function);

    tree_builder.Builder builder = new tree_builder.Builder(compiler);
    tree_ir.FunctionDefinition definition = builder.build(function);
    assert(definition != null);
    traceGraph('Tree builder', definition);

    // Transformations on the Tree IR.
    new StatementRewriter().rewrite(definition);
    traceGraph('Statement rewriter', definition);
    new CopyPropagator().rewrite(definition);
    traceGraph('Copy propagation', definition);
    new LoopRewriter().rewrite(definition);
    traceGraph('Loop rewriter', definition);
    new LogicalRewriter().rewrite(definition);
    traceGraph('Logical rewriter', definition);
    new backend_ast_emitter.UnshadowParameters().unshadow(definition);
    traceGraph('Unshadow parameters', definition);

    TreeElementMapping treeElements = new TreeElementMapping(element);
    backend_ast.Node backendAst =
        backend_ast_emitter.emit(definition);
    Node frontend_ast = backend2frontend.emit(treeElements, backendAst);
    return new ElementAst.internal(frontend_ast, treeElements);

  }

  void assembleProgram() {
    // Conservatively traverse all platform libraries and collect member names.
    // TODO(antonm): ideally we should only collect names of used members,
    // however as of today there are problems with names of some core library
    // interfaces, most probably for interfaces of literals.
    final fixedMemberNames = new Set<String>();

    Map<Element, LibraryElement> reexportingLibraries =
        <Element, LibraryElement>{};

    for (final library in compiler.libraryLoader.libraries) {
      if (!library.isPlatformLibrary) continue;
      library.forEachLocalMember((Element element) {
        if (element.isClass) {
          ClassElement classElement = element;
          assert(invariant(classElement, classElement.isResolved,
              message: "Unresolved platform class."));
          classElement.forEachLocalMember((member) {
            final name = member.name;
            // Skip operator names.
            if (!name.startsWith(r'operator$')) {
              // Fetch name of named constructors and factories if any,
              // otherwise store regular name.
              // TODO(antonm): better way to analyze the name.
              fixedMemberNames.add(name.split(r'$').last);
            }
          });
        }
        // Even class names are added due to a delicate problem we have:
        // if one imports dart:core with a prefix, we cannot tell prefix.name
        // from dynamic invocation (alas!).  So we'd better err on preserving
        // those names.
        fixedMemberNames.add(element.name);
      });

      for (Element export in library.exports) {
        if (!library.isInternalLibrary &&
            export.library.isInternalLibrary) {
          // If an element of an internal library is reexported by a platform
          // library, we have to import the reexporting library instead of the
          // internal library, because the internal library is an
          // implementation detail of dart2js.
          reexportingLibraries[export] = library;
        }
      }
    }
    // As of now names of named optionals are not renamed. Therefore add all
    // field names used as named optionals into [fixedMemberNames].
    for (final element in resolvedElements) {
      if (!element.isConstructor) continue;
      Link<Element> optionalParameters =
          element.functionSignature.optionalParameters;
      for (final optional in optionalParameters) {
        if (!optional.isInitializingFormal) continue;
        fixedMemberNames.add(optional.name);
      }
    }
    // The VM will automatically invoke the call method of objects
    // that are invoked as functions. Make sure to not rename that.
    fixedMemberNames.add('call');
    // TODO(antonm): TypeError.srcType and TypeError.dstType are defined in
    // runtime/lib/error.dart. Overall, all DartVM specific libs should be
    // accounted for.
    fixedMemberNames.add('srcType');
    fixedMemberNames.add('dstType');

    if (useMirrorHelperLibrary && compiler.mirrorsLibrary != null) {
        mirrorRenamer = new MirrorRenamer(compiler, this);
    } else {
      useMirrorHelperLibrary = false;
    }

    final elementAsts = new Map<Element, ElementAst>();

    ElementAst parse(AstElement element) {
      if (!compiler.irBuilder.hasIr(element)) {
        return new ElementAst(element);
      } else {
        cps_ir.FunctionDefinition function = compiler.irBuilder.getIr(element);
        return createElementAst(compiler,
            compiler.tracer, constantSystem, element, function);
      }
    }

    List<LibraryElement> userLibraries =
        compiler.libraryLoader.libraries.where(isUserLibrary).toList();

    Set<Element> topLevelElements = new Set<Element>();
    Map<ClassElement, Set<Element>> classMembers =
        new Map<ClassElement, Set<Element>>();

    // Build all top level elements to emit and necessary class members.
    var newTypedefElementCallback, newClassElementCallback;

    void processElement(Element element, ElementAst elementAst) {
      ReferencedElementCollector collector =
          new ReferencedElementCollector(compiler,
                                         element,
                                         elementAst,
                                         newTypedefElementCallback,
                                         newClassElementCallback);
      collector.collect();
      elementAsts[element] = elementAst;
    }

    addTopLevel(AstElement element, ElementAst elementAst) {
      if (topLevelElements.contains(element)) return;
      topLevelElements.add(element);
      processElement(element, elementAst);
    }

    addClass(ClassElement classElement) {
      addTopLevel(classElement, new ElementAst(classElement));
      classMembers.putIfAbsent(classElement, () => new Set());
    }

    newTypedefElementCallback = (TypedefElement element) {
      if (!shouldOutput(element)) return;
      addTopLevel(element, new ElementAst(element));
    };
    newClassElementCallback = (ClassElement classElement) {
      if (!shouldOutput(classElement)) return;
      addClass(classElement);
    };

    compiler.resolverWorld.instantiatedClasses.forEach(
        (ClassElement classElement) {
      if (shouldOutput(classElement)) addClass(classElement);
    });
    resolvedElements.forEach((element) {
      if (!shouldOutput(element) ||
          !compiler.enqueuer.resolution.hasBeenResolved(element)) {
        return;
      }
      ElementAst elementAst = parse(element);

      if (element.isClassMember) {
        ClassElement enclosingClass = element.enclosingClass;
        assert(enclosingClass.isClass);
        assert(enclosingClass.isTopLevel);
        assert(shouldOutput(enclosingClass));
        addClass(enclosingClass);
        classMembers[enclosingClass].add(element);
        processElement(element, elementAst);
      } else {
        if (element.isTopLevel) {
          addTopLevel(element, elementAst);
        }
      }
    });
    Set<ClassElement> emitNoMembersFor = new Set<ClassElement>();
    usedTypeLiterals.forEach((ClassElement element) {
      if (shouldOutput(element)) {
        if (!topLevelElements.contains(element)) {
          // The class is only referenced by type literals.
          emitNoMembersFor.add(element);
        }
        addClass(element);
      }
    });

    // Create all necessary placeholders.
    PlaceholderCollector collector =
        new PlaceholderCollector(compiler, fixedMemberNames, elementAsts);
    makePlaceholders(element) {
      bool oldUseHelper = useMirrorHelperLibrary;
      useMirrorHelperLibrary = (useMirrorHelperLibrary
                               && element.library != mirrorHelperLibrary);
      collector.collect(element);
      useMirrorHelperLibrary = oldUseHelper;

      if (element.isClass) {
        classMembers[element].forEach(makePlaceholders);
      }
    }
    topLevelElements.forEach(makePlaceholders);
    // Create renames.
    bool shouldCutDeclarationTypes = forceStripTypes
        || (compiler.enableMinification
            && isSafeToRemoveTypeDeclarations(classMembers));

    placeholderRenamer =
        new PlaceholderRenamer(compiler, fixedMemberNames, reexportingLibraries,
            cutDeclarationTypes: shouldCutDeclarationTypes);

    placeholderRenamer.computeRenames(collector);

    // Sort elements.
    final List<Element> sortedTopLevels = sortElements(topLevelElements);
    final Map<ClassElement, List<Element>> sortedClassMembers =
        new Map<ClassElement, List<Element>>();
    classMembers.forEach((classElement, members) {
      sortedClassMembers[classElement] = sortElements(members);
    });

    if (outputAst) {
      // TODO(antonm): Ideally XML should be a separate backend.
      // TODO(antonm): obey renames and minification, at least as an option.
      StringBuffer sb = new StringBuffer();
      outputElement(element) {
        sb.write(element.parseNode(compiler).toDebugString());
      }

      // Emit XML for AST instead of the program.
      for (final topLevel in sortedTopLevels) {
        if (topLevel.isClass && !emitNoMembersFor.contains(topLevel)) {
          // TODO(antonm): add some class info.
          sortedClassMembers[topLevel].forEach(outputElement);
        } else {
          outputElement(topLevel);
        }
      }
      compiler.assembledCode = '<Program>\n$sb</Program>\n';
      return;
    }

    final List<Node> topLevelNodes = <Node>[];
    for (final element in sortedTopLevels) {
      topLevelNodes.add(elementAsts[element].ast);
      if (element.isClass && !element.isMixinApplication) {
        final members = <Node>[];
        for (final member in sortedClassMembers[element]) {
          members.add(elementAsts[member].ast);
        }
        memberNodes[elementAsts[element].ast] = members;
      }
    }

    if (useMirrorHelperLibrary) {
      mirrorRenamer.addRenames(placeholderRenamer.renames,
                               topLevelNodes, collector);
    }

    Map<LibraryElement, String> outputPaths = new Map<LibraryElement, String>();
    Map<LibraryElement, EmitterUnparser> unparsers =
        new Map<LibraryElement, EmitterUnparser>();

    // The single unparser used if we collect all the output in one file.
    EmitterUnparser mainUnparser = multiFile
        ? null
        : new EmitterUnparser(placeholderRenamer.renames,
            stripTypes: forceStripTypes,
            minify: compiler.enableMinification);

    if (multiFile) {
      // TODO(sigurdm): Factor handling of library-paths out from emitting.
      String mainName = compiler.outputUri.pathSegments.last;
      String mainBaseName = mainName.endsWith(".dart")
          ? mainName.substring(0, mainName.length - 5)
          : mainName;
      // Map each library to a path based on the uri of the original
      // library and [compiler.outputUri].
      Set<String> usedLibraryPaths = new Set<String>();
      for (LibraryElement library in userLibraries) {
        if (library == compiler.mainApp) {
          outputPaths[library] = mainBaseName;
        } else {
          List<String> names =
              library.canonicalUri.pathSegments.last.split(".");
          if (names.last == "dart") {
            names = names.sublist(0, names.length - 1);
          }
          outputPaths[library] =
              "$mainBaseName.${makeUnique(names.join("."), usedLibraryPaths)}";
        }
      }

      /// Rewrites imports/exports to refer to the paths given in [outputPaths].
      for(LibraryElement outputLibrary in userLibraries) {
        EmitterUnparser unparser = new EmitterUnparser(
            placeholderRenamer.renames,
            stripTypes: forceStripTypes,
            minify: compiler.enableMinification);
        unparsers[outputLibrary] = unparser;
        LibraryName libraryName = outputLibrary.libraryTag;
        if (libraryName != null) {
          unparser.visitLibraryName(libraryName);
        }
        for (LibraryTag tag in outputLibrary.tags) {
          if (tag is! LibraryDependency) continue;
          LibraryDependency dependency = tag;
          LibraryElement libraryElement =
              outputLibrary.getLibraryFromTag(dependency);
          String uri = outputPaths.containsKey(libraryElement)
              ? "${outputPaths[libraryElement]}.dart"
              : libraryElement.canonicalUri.toString();
          if (dependency is Import) {
            unparser.unparseImportTag(uri);
          } else {
            unparser.unparseExportTag(uri);
          }
        }
      }
    } else {
      for(LibraryElement library in placeholderRenamer.platformImports) {
        if (library.isPlatformLibrary && !library.isInternalLibrary) {
          mainUnparser.unparseImportTag(library.canonicalUri.toString());
        }
      }
    }

    for (int i = 0; i < sortedTopLevels.length; i++) {
      Element element = sortedTopLevels[i];
      Node node = topLevelNodes[i];
      Unparser unparser = multiFile ? unparsers[element.library] : mainUnparser;
      if (node is ClassNode) {
        // TODO(smok): Filter out default constructors here.
        unparser.unparseClassWithBody(node, memberNodes[node]);
      } else {
        unparser.unparse(node);
      }
      unparser.newline();
    }

    int totalSize = 0;
    if (multiFile) {
      for(LibraryElement outputLibrary in userLibraries) {
        // TODO(sigurdm): Make the unparser output directly into the buffer instead
        // of caching in `.result`.
        String code = unparsers[outputLibrary].result;
        totalSize += code.length;
        compiler.outputProvider(outputPaths[outputLibrary], "dart")
             ..add(code)
             ..close();
      }
      // TODO(sigurdm): We should get rid of compiler.assembledCode.
      compiler.assembledCode = unparsers[compiler.mainApp].result;
    } else {
      compiler.assembledCode = mainUnparser.result;
      compiler.outputProvider("", "dart")
           ..add(compiler.assembledCode)
           ..close();

      totalSize = compiler.assembledCode.length;
    }

    // Output verbose info about size ratio of resulting bundle to all
    // referenced non-platform sources.
    logResultBundleSizeInfo(topLevelElements, totalSize);
  }

  void logResultBundleSizeInfo(Set<Element> topLevelElements,
                               int totalOutputSize) {
    Iterable<LibraryElement> referencedLibraries =
        compiler.libraryLoader.libraries.where(isUserLibrary);
    // Sum total size of scripts in each referenced library.
    int nonPlatformSize = 0;
    for (LibraryElement lib in referencedLibraries) {
      for (CompilationUnitElement compilationUnit in lib.compilationUnits) {
        nonPlatformSize += compilationUnit.script.file.length;
      }
    }
    int percentage = totalOutputSize * 100 ~/ nonPlatformSize;
    log('Total used non-platform files size: ${nonPlatformSize} bytes, '
        'Output total size: $totalOutputSize bytes (${percentage}%)');
  }

  log(String message) => compiler.log('[DartBackend] $message');

  Future onLibrariesLoaded(Map<Uri, LibraryElement> loadedLibraries) {
    // All platform classes must be resolved to ensure that their member names
    // are preserved.
    loadedLibraries.values.forEach((LibraryElement library) {
      if (library.isPlatformLibrary) {
        library.forEachLocalMember((Element element) {
          if (element.isClass) {
            ClassElement classElement = element;
            classElement.ensureResolved(compiler);
          }
        });
      }
    });
    if (useMirrorHelperLibrary &&
        loadedLibraries.containsKey(Compiler.DART_MIRRORS)) {
      return compiler.libraryLoader.loadLibrary(
          compiler.translateResolvedUri(
              loadedLibraries[Compiler.DART_MIRRORS],
              MirrorRenamer.DART_MIRROR_HELPER, null)).
          then((LibraryElement element) {
        mirrorHelperLibrary = element;
        mirrorHelperGetNameFunction = mirrorHelperLibrary.find(
            MirrorRenamer.MIRROR_HELPER_GET_NAME_FUNCTION);
        mirrorHelperSymbolsMap = mirrorHelperLibrary.find(
            MirrorRenamer.MIRROR_HELPER_SYMBOLS_MAP_NAME);
      });
    }
    return new Future.value();
  }

  void registerStaticSend(Element element, Node node) {
    if (useMirrorHelperLibrary) {
      mirrorRenamer.registerStaticSend(element, node);
    }
  }

  void registerMirrorHelperElement(Element element, Node node) {
    if (mirrorHelperLibrary != null
        && element.library == mirrorHelperLibrary) {
      mirrorRenamer.registerHelperElement(element, node);
    }
  }

  void registerStaticUse(Element element, Enqueuer enqueuer) {
    if (useMirrorHelperLibrary &&
        element == compiler.mirrorSystemGetNameFunction) {
      enqueuer.addToWorkList(mirrorHelperGetNameFunction);
    }
  }
}

class DartResolutionCallbacks extends ResolutionCallbacks {
  final DartBackend backend;

  DartResolutionCallbacks(this.backend);

  void onTypeLiteral(DartType type, Registry registry) {
    if (type.isInterfaceType) {
      backend.usedTypeLiterals.add(type.element);
    }
  }
}

class EmitterUnparser extends Unparser {
  final Map<Node, String> renames;

  EmitterUnparser(this.renames, {bool minify, bool stripTypes})
      : super(minify: minify, stripTypes: stripTypes);

  visit(Node node) {
    if (node != null && renames.containsKey(node)) {
      write(renames[node]);
    } else {
      super.visit(node);
    }
  }

  unparseSendReceiver(Send node, {bool spacesNeeded: false}) {
    // TODO(smok): Remove ugly hack for library prefices.
    if (node.receiver != null && renames[node.receiver] == '') return;
    super.unparseSendReceiver(node, spacesNeeded: spacesNeeded);
  }

  unparseFunctionName(Node name) {
    if (name != null && renames.containsKey(name)) {
      write(renames[name]);
    } else {
      super.unparseFunctionName(name);
    }
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
  final Element element;
  final ElementAst elementAst;
  final newTypedefElementCallback;
  final newClassElementCallback;

  ReferencedElementCollector(this.compiler,
                             this.element,
                             this.elementAst,
                             this.newTypedefElementCallback,
                             this.newClassElementCallback);

  visitNode(Node node) {
    node.visitChildren(this);
  }

  visitTypeAnnotation(TypeAnnotation typeAnnotation) {
    TreeElements treeElements = elementAst.treeElements;
    final DartType type = treeElements.getType(typeAnnotation);
    assert(invariant(typeAnnotation, type != null,
        message: "Missing type for type annotation: $treeElements."));
    if (type.isTypedef) newTypedefElementCallback(type.element);
    if (type.isInterfaceType) newClassElementCallback(type.element);
    typeAnnotation.visitChildren(this);
  }

  void collect() {
    compiler.withCurrentElement(element, () {
      elementAst.ast.accept(this);
    });
  }
}

Comparator compareBy(f) => (x, y) => f(x).compareTo(f(y));

List sorted(Iterable l, comparison) {
  final result = new List.from(l);
  result.sort(comparison);
  return result;
}

compareElements(e0, e1) {
  int result = compareBy((e) => e.library.canonicalUri.toString())(e0, e1);
  if (result != 0) return result;
  return compareBy((e) => e.position.charOffset)(e0, e1);
}

List<Element> sortElements(Iterable<Element> elements) =>
    sorted(elements, compareElements);

/// [ConstantCompilerTask] for compilation of constants for the Dart backend.
///
/// Since this task needs no distinction between frontend and backend constants
/// it also serves as the [BackendConstantEnvironment].
class DartConstantTask extends ConstantCompilerTask
    implements BackendConstantEnvironment {
  final DartConstantCompiler constantCompiler;

  DartConstantTask(Compiler compiler)
    : this.constantCompiler = new DartConstantCompiler(compiler),
      super(compiler);

  String get name => 'ConstantHandler';

  Constant getConstantForVariable(VariableElement element) {
    return constantCompiler.getConstantForVariable(element);
  }

  Constant getConstantForNode(Node node, TreeElements elements) {
    return constantCompiler.getConstantForNode(node, elements);
  }

  Constant getConstantForMetadata(MetadataAnnotation metadata) {
    return metadata.value;
  }

  Constant compileConstant(VariableElement element) {
    return measure(() {
      return constantCompiler.compileConstant(element);
    });
  }

  void compileVariable(VariableElement element) {
    measure(() {
      constantCompiler.compileVariable(element);
    });
  }

  Constant compileNode(Node node, TreeElements elements) {
    return measure(() {
      return constantCompiler.compileNodeWithDefinitions(node, elements);
    });
  }

  Constant compileMetadata(MetadataAnnotation metadata,
                           Node node,
                           TreeElements elements) {
    return measure(() {
      return constantCompiler.compileMetadata(metadata, node, elements);
    });
  }
}
