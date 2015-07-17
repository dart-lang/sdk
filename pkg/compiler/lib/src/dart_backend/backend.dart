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

  ElementAst(this.ast, this.treeElements);
}

class DartBackend extends Backend {
  final List<CompilerTask> tasks;
  final bool stripAsserts;

  bool get supportsReflection => true;

  // TODO(zarah) Maybe change this to a command-line option.
  // Right now, it is set by the tests.
  bool useMirrorHelperLibrary = false;

  /// Updated to a [MirrorRenamerImpl] instance if the [useMirrorHelperLibrary]
  /// field is set and mirror are needed.
  MirrorRenamer mirrorRenamer = const MirrorRenamer();

  final DartOutputter outputter;

  // Used in test.
  PlaceholderRenamer get placeholderRenamer => outputter.renamer;
  Map<ClassNode, List<Node>> get memberNodes => outputter.output.memberNodes;

  ConstantSystem get constantSystem {
    return constantCompilerTask.constantCompiler.constantSystem;
  }

  BackendConstantEnvironment get constants => constantCompilerTask;

  DartConstantTask constantCompilerTask;

  DartResolutionCallbacks resolutionCallbacks;

  final Set<ClassElement> usedTypeLiterals = new Set<ClassElement>();

  /// The set of visible platform classes that are implemented by instantiated
  /// user classes.
  final Set<ClassElement> _userImplementedPlatformClasses =
      new Set<ClassElement>();

  bool enableCodegenWithErrorsIfSupported(Spannable node) {
    compiler.reportHint(node,
        MessageKind.GENERIC,
        {'text': "Generation of code with compile time errors is not "
                 "supported for dart2dart."});
    return false;
  }

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
      Map<ClassElement, Iterable<Element>> classMembers) {
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

  DartBackend(Compiler compiler, List<String> strips, {bool multiFile})
      : tasks = <CompilerTask>[],
        stripAsserts = strips.indexOf('asserts') != -1,
        constantCompilerTask = new DartConstantTask(compiler),
        outputter = new DartOutputter(
            compiler, compiler.outputProvider,
            forceStripTypes: strips.indexOf('types') != -1,
            multiFile: multiFile,
            enableMinification: compiler.enableMinification),
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
    world.registerInvocation(
        new UniverseSelector(new Selector.call("toString", null, 0), null));
    world.registerInvokedGetter(
        new UniverseSelector(new Selector.getter("hashCode", null), null));
    world.registerInvocation(
        new UniverseSelector(new Selector.binaryOperator("=="), null));
    world.registerInvocation(
        new UniverseSelector(new Selector.call("compareTo", null, 1), null));
  }

  WorldImpact codegen(CodegenWorkItem work) => const WorldImpact();

  /**
   * Tells whether we should output given element. Corelib classes like
   * Object should not be in the resulting code.
   */
  @override
  bool shouldOutput(Element element) {
    return (!element.library.isPlatformLibrary &&
            !element.isSynthesized &&
            element is! AbstractFieldElement)
        || mirrorRenamer.isMirrorHelperLibrary(element.library);
  }

  int assembleProgram() {
    ElementAst computeElementAst(AstElement element) {
      return new ElementAst(element.resolvedAst.node,
                            element.resolvedAst.elements);
    }

    // TODO(johnniwinther): Remove the need for this method.
    void postProcessElementAst(
        AstElement element, ElementAst elementAst,
        newTypedefElementCallback,
        newClassElementCallback) {
      ReferencedElementCollector collector =
          new ReferencedElementCollector(compiler,
                                         element,
                                         elementAst,
                                         newTypedefElementCallback,
                                         newClassElementCallback);
      collector.collect();
    }

    int totalSize = outputter.assembleProgram(
        libraries: compiler.libraryLoader.libraries,
        instantiatedClasses: compiler.resolverWorld.directlyInstantiatedClasses,
        resolvedElements: compiler.enqueuer.resolution.resolvedElements,
        usedTypeLiterals: usedTypeLiterals,
        postProcessElementAst: postProcessElementAst,
        computeElementAst: computeElementAst,
        shouldOutput: shouldOutput,
        isSafeToRemoveTypeDeclarations: isSafeToRemoveTypeDeclarations,
        sortElements: Elements.sortedByPosition,
        mirrorRenamer: mirrorRenamer,
        mainFunction: compiler.mainFunction,
        outputUri: compiler.outputUri);

    // Output verbose info about size ratio of resulting bundle to all
    // referenced non-platform sources.
    logResultBundleSizeInfo(
        outputter.libraryInfo.userLibraries,
        outputter.elementInfo.topLevelElements,
        totalSize);

    return totalSize;
  }

  void logResultBundleSizeInfo(Iterable<LibraryElement> userLibraries,
                               Iterable<Element> topLevelElements,
                               int totalOutputSize) {
    // Sum total size of scripts in each referenced library.
    int nonPlatformSize = 0;
    for (LibraryElement lib in userLibraries) {
      for (CompilationUnitElement compilationUnit in lib.compilationUnits) {
        nonPlatformSize += compilationUnit.script.file.length;
      }
    }
    int percentage = totalOutputSize * 100 ~/ nonPlatformSize;
    log('Total used non-platform files size: ${nonPlatformSize} bytes, '
        'Output total size: $totalOutputSize bytes (${percentage}%)');
  }

  log(String message) => compiler.log('[DartBackend] $message');

  @override
  Future onLibrariesLoaded(LoadedLibraries loadedLibraries) {
    // All platform classes must be resolved to ensure that their member names
    // are preserved.
    loadedLibraries.forEachLibrary((LibraryElement library) {
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
        loadedLibraries.containsLibrary(Compiler.DART_MIRRORS)) {
      return compiler.libraryLoader.loadLibrary(
          compiler.translateResolvedUri(
              loadedLibraries.getLibrary(Compiler.DART_MIRRORS),
              MirrorRenamerImpl.DART_MIRROR_HELPER, null)).
          then((LibraryElement library) {
        mirrorRenamer = new MirrorRenamerImpl(compiler, this, library);
      });
    }
    return new Future.value();
  }

  @override
  void registerStaticUse(Element element, Enqueuer enqueuer) {
    if (element == compiler.mirrorSystemGetNameFunction) {
      FunctionElement getNameFunction = mirrorRenamer.getNameFunction;
      if (getNameFunction != null) {
        enqueuer.addToWorkList(getNameFunction);
      }
    }
  }

  @override
  void registerInstantiatedType(InterfaceType type, Registry registry) {
    // Without patching, dart2dart has no way of performing sound tree-shaking
    // in face external functions. Therefore we employ another scheme:
    //
    // Based on the assumption that the platform code only relies on the
    // interfaces of it's own classes, we can approximate the semantics of
    // external functions by eagerly registering dynamic invocation of instance
    // members defined the platform interfaces.
    //
    // Since we only need to generate code for non-platform classes we can
    // restrict this registration to platform interfaces implemented by
    // instantiated non-platform classes.
    //
    // Consider for instance this program:
    //
    //     import 'dart:math' show Random;
    //
    //     class MyRandom implements Random {
    //       int nextInt() => 0;
    //     }
    //
    //     main() {
    //       print([0, 1, 2].shuffle(new MyRandom()));
    //     }
    //
    // Here `MyRandom` is a subtype if `Random` defined in 'dart:math'. By the
    // assumption, all methods defined `Random` are potentially called, and
    // therefore, though there are no visible call sites from the user node,
    // dynamic invocation of for instance `nextInt` should be registered. In
    // this case, `nextInt` is actually called by the standard implementation of
    // `shuffle`.

    ClassElement cls = type.element;
    if (!cls.library.isPlatformLibrary) {
      for (Link<DartType> link = cls.allSupertypes;
           !link.isEmpty;
           link = link.tail) {
        InterfaceType supertype = link.head;
        ClassElement superclass = supertype.element;
        LibraryElement library = superclass.library;
        if (library.isPlatformLibrary) {
          if (_userImplementedPlatformClasses.add(superclass)) {
            // Register selectors for all instance methods since these might
            // be called on user classes from within the platform
            // implementation.
            superclass.forEachLocalMember((MemberElement element) {
              if (element.isConstructor || element.isStatic) return;

              FunctionElement function = element.asFunctionElement();
              element.computeType(compiler);
              Selector selector = new Selector.fromElement(element);
              if (selector.isGetter) {
                registry.registerDynamicGetter(
                    new UniverseSelector(selector, null));
              } else if (selector.isSetter) {
                registry.registerDynamicSetter(
                    new UniverseSelector(selector, null));
              } else {
                registry.registerDynamicInvocation(
                    new UniverseSelector(selector, null));
              }
            });
          }
        }
      }
    }

  }

  @override
  bool enableDeferredLoadingIfSupported(Spannable node, Registry registry) {
    // TODO(sigurdm): Implement deferred loading for dart2dart.
    compiler.reportWarning(node, MessageKind.DEFERRED_LIBRARY_DART_2_DART);
    return false;
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

  @override
  ConstantSystem get constantSystem => constantCompiler.constantSystem;

  @override
  ConstantValue getConstantValue(ConstantExpression expression) {
    return constantCompiler.getConstantValue(expression);
  }

  @override
  ConstantValue getConstantValueForVariable(VariableElement element) {
    return constantCompiler.getConstantValueForVariable(element);
  }

  @override
  ConstantExpression getConstantForVariable(VariableElement element) {
    return constantCompiler.getConstantForVariable(element);
  }

  @override
  ConstantExpression getConstantForNode(Node node, TreeElements elements) {
    return constantCompiler.getConstantForNode(node, elements);
  }

  @override
  ConstantValue getConstantValueForNode(Node node, TreeElements elements) {
    return getConstantValue(
        constantCompiler.getConstantForNode(node, elements));
  }

  @override
  ConstantValue getConstantValueForMetadata(MetadataAnnotation metadata) {
    return getConstantValue(metadata.constant);
  }

  @override
  ConstantExpression compileConstant(VariableElement element) {
    return measure(() {
      return constantCompiler.compileConstant(element);
    });
  }

  void compileVariable(VariableElement element) {
    measure(() {
      constantCompiler.compileVariable(element);
    });
  }

  @override
  ConstantExpression compileNode(
      Node node,
      TreeElements elements,
      {bool enforceConst: true}) {
    return measure(() {
      return constantCompiler.compileNodeWithDefinitions(node, elements,
          isConst: enforceConst);
    });
  }

  @override
  ConstantExpression compileMetadata(
      MetadataAnnotation metadata,
      Node node,
      TreeElements elements) {
    return measure(() {
      return constantCompiler.compileMetadata(metadata, node, elements);
    });
  }

  // TODO(johnniwinther): Remove this when values are computed from the
  // expressions.
  @override
  void copyConstantValues(DartConstantTask task) {
    constantCompiler.constantValueMap.addAll(
        task.constantCompiler.constantValueMap);
  }
}
