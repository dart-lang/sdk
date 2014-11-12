// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart_backend;

typedef bool IsSafeToRemoveTypeDeclarations(
    Map<ClassElement, Iterable<Element>> classMembers);
typedef void ElementCallback<E>(E element);
typedef void ElementPostProcessFunction(
    AstElement element, ElementAst elementAst,
    ElementCallback<TypedefElement> typedefCallback,
    ElementCallback<ClassElement> classCallback);
typedef ElementAst ComputeElementAstFunction(AstElement element);
typedef bool ElementFilter(Element element);
typedef List<Element> ElementSorter(Iterable<Element> elements);

/// Output engine for dart2dart that is shared between the dart2js and the
/// analyzer implementations of dart2dart.
class DartOutputter {
  final DiagnosticListener listener;
  final CompilerOutputProvider outputProvider;
  final bool forceStripTypes;

  // TODO(antonm): make available from command-line options.
  final bool outputAst = false;
  final bool enableMinification;

  /// If `true`, libraries are generated into separate files.
  final bool multiFile;

  /// Internal structures accessible for tests and logging.
  // TODO(johnniwinther): Clean this up.
  PlaceholderRenamer renamer;
  MainOutputGenerator output;
  LibraryInfo libraryInfo;
  ElementInfo elementInfo;

  // TODO(johnniwinther): Support recompilation.
  DartOutputter(this.listener, this.outputProvider,
                {bool this.forceStripTypes: false,
                 bool this.enableMinification: false,
                 bool this.multiFile: false});

  /// Generate Dart code for the program starting at [mainFunction].
  ///
  /// [libraries] is the set of all libraries (user/package/sdk) that are
  /// referenced in the program.
  ///
  /// [instantiatedClasses] is the set of classes that are potentially
  /// instantiated in the program.
  ///
  /// [resolvedElements] is the set of methods, constructors, and fields that
  /// are potentially accessed/called in the program.
  ///
  /// The [sortElements] function is used to sort [instantiatedClasses] and
  /// [resolvedElements] in the generated output.
  String assembleProgram({
      MirrorRenamer mirrorRenamer: const MirrorRenamer(),
      Iterable<LibraryElement> libraries,
      Iterable<Element> instantiatedClasses,
      Iterable<Element> resolvedElements,
      Iterable<ClassElement> usedTypeLiterals: const <ClassElement>[],
      FunctionElement mainFunction,
      Uri outputUri,
      ElementPostProcessFunction postProcessElementAst,
      ComputeElementAstFunction computeElementAst,
      ElementFilter shouldOutput,
      IsSafeToRemoveTypeDeclarations isSafeToRemoveTypeDeclarations,
      ElementSorter sortElements}) {

    assert(invariant(NO_LOCATION_SPANNABLE, libraries != null,
        message: "'libraries' must be non-null."));
    assert(invariant(NO_LOCATION_SPANNABLE, instantiatedClasses != null,
        message: "'instantiatedClasses' must be non-null."));
    assert(invariant(NO_LOCATION_SPANNABLE, resolvedElements != null,
        message: "'resolvedElements' must be non-null."));
    assert(invariant(NO_LOCATION_SPANNABLE, mainFunction != null,
        message: "'mainFunction' must be non-null."));
    assert(invariant(NO_LOCATION_SPANNABLE, computeElementAst != null,
        message: "'computeElementAst' must be non-null."));
    assert(invariant(NO_LOCATION_SPANNABLE, shouldOutput != null,
        message: "'shouldOutput' must be non-null."));
    assert(invariant(NO_LOCATION_SPANNABLE,
        isSafeToRemoveTypeDeclarations != null,
        message: "'isSafeToRemoveTypeDeclarations' must be non-null."));

    if (sortElements == null) {
      // Ensure deterministic output order.
      sortElements = (Iterable<Element> elements) {
        List<Element> list = elements.toList();
        list.sort((Element a, Element b) => a.name.compareTo(b.name));
        return list;
      };
    }

    libraryInfo = LibraryInfo.processLibraries(libraries, resolvedElements);

    elementInfo = ElementInfoProcessor.createElementInfo(
        instantiatedClasses,
        resolvedElements,
        usedTypeLiterals,
        postProcessElementAst: postProcessElementAst,
        parseElementAst: computeElementAst,
        shouldOutput: shouldOutput,
        sortElements: sortElements);

    PlaceholderCollector collector = collectPlaceholders(
        listener,
        mirrorRenamer,
        mainFunction,
        libraryInfo,
        elementInfo);

    renamer = createRenamer(
        collector,
        libraryInfo,
        elementInfo,
        enableMinification: enableMinification,
        forceStripTypes: forceStripTypes,
        isSafeToRemoveTypeDeclarations: isSafeToRemoveTypeDeclarations);

    String assembledCode;
    if (outputAst) {
      assembledCode = astOutput(listener, elementInfo);
    } else {
      output = new MainOutputGenerator();
      assembledCode = output.generateCode(
          libraryInfo,
          elementInfo,
          collector,
          renamer,
          mainFunction,
          outputUri,
          outputProvider,
          mirrorRenamer,
          multiFile: multiFile,
          forceStripTypes: forceStripTypes,
          enableMinification: enableMinification);
    }
    return assembledCode;
  }

  static PlaceholderCollector collectPlaceholders(
      DiagnosticListener listener,
      MirrorRenamer mirrorRenamer,
      FunctionElement mainFunction,
      LibraryInfo libraryInfo,
      ElementInfo elementInfo) {
    // Create all necessary placeholders.
    PlaceholderCollector collector = new PlaceholderCollector(
        listener,
        mirrorRenamer,
        libraryInfo.fixedMemberNames,
        elementInfo.elementAsts,
        mainFunction);

    makePlaceholders(element) {
      collector.collect(element);

      if (element.isClass) {
        elementInfo.classMembers[element].forEach(makePlaceholders);
      }
    }
    elementInfo.topLevelElements.forEach(makePlaceholders);
    return collector;
  }

  static PlaceholderRenamer createRenamer(
      PlaceholderCollector collector,
      LibraryInfo libraryInfo,
      ElementInfo elementInfo,
      {bool enableMinification: false,
       bool forceStripTypes: false,
       isSafeToRemoveTypeDeclarations}) {
    // Create renames.
    bool shouldCutDeclarationTypes = forceStripTypes
        || (enableMinification
            && isSafeToRemoveTypeDeclarations(elementInfo.classMembers));

    PlaceholderRenamer placeholderRenamer = new PlaceholderRenamer(
        libraryInfo.fixedMemberNames, libraryInfo.reexportingLibraries,
        cutDeclarationTypes: shouldCutDeclarationTypes,
        enableMinification: enableMinification);

    placeholderRenamer.computeRenames(collector);
    return placeholderRenamer;
  }

  static String astOutput(DiagnosticListener listener,
                          ElementInfo elementInfo) {
    // TODO(antonm): Ideally XML should be a separate backend.
    // TODO(antonm): obey renames and minification, at least as an option.
    StringBuffer sb = new StringBuffer();
    outputElement(element) {
      sb.write(element.parseNode(listener).toDebugString());
    }

    // Emit XML for AST instead of the program.
    for (Element topLevel in elementInfo.topLevelElements) {
      if (topLevel.isClass &&
          !elementInfo.emitNoMembersFor.contains(topLevel)) {
        // TODO(antonm): add some class info.
        elementInfo.classMembers[topLevel].forEach(outputElement);
      } else {
        outputElement(topLevel);
      }
    }
    return '<Program>\n$sb</Program>\n';
  }
}

class LibraryInfo {
  final Set<String> fixedMemberNames;
  final Map<Element, LibraryElement> reexportingLibraries;
  final List<LibraryElement> userLibraries;

  LibraryInfo(this.fixedMemberNames,
              this.reexportingLibraries,
              this.userLibraries);

  static LibraryInfo processLibraries(
      Iterable<LibraryElement> libraries,
      Iterable<AstElement> resolvedElements) {
    Set<String> fixedMemberNames = new Set<String>();
    Map<Element, LibraryElement> reexportingLibraries =
          <Element, LibraryElement>{};
    List<LibraryElement> userLibraries = <LibraryElement>[];
    // Conservatively traverse all platform libraries and collect member names.
    // TODO(antonm): ideally we should only collect names of used members,
    // however as of today there are problems with names of some core library
    // interfaces, most probably for interfaces of literals.

    for (LibraryElement library in libraries) {
      if (!library.isPlatformLibrary) {
        userLibraries.add(library);
        continue;
      }
      library.forEachLocalMember((Element element) {
        if (element.isClass) {
          ClassElement classElement = element;
          assert(invariant(classElement, classElement.isResolved,
              message: "Unresolved platform class."));
          classElement.forEachLocalMember((member) {
            String name = member.name;
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

    return new LibraryInfo(
        fixedMemberNames, reexportingLibraries, userLibraries);
  }
}

class ElementInfo {
  final Map<Element, ElementAst> elementAsts;
  final Iterable<Element> topLevelElements;
  final Map<ClassElement, Iterable<Element>> classMembers;
  final Iterable<ClassElement> emitNoMembersFor;

  ElementInfo(this.elementAsts,
              this.topLevelElements,
              this.classMembers,
              this.emitNoMembersFor);
}

class ElementInfoProcessor implements ElementInfo {
  final Map<Element, ElementAst> elementAsts = new Map<Element, ElementAst>();
  final Set<Element> topLevelElements = new Set<Element>();
  final Map<ClassElement, Set<Element>> classMembers =
      new Map<ClassElement, Set<Element>>();
  final Set<ClassElement> emitNoMembersFor = new Set<ClassElement>();
  final ElementPostProcessFunction postProcessElementAst;
  final ComputeElementAstFunction parseElementAst;
  final ElementFilter shouldOutput;

  ElementInfoProcessor(
      {this.postProcessElementAst,
       this.parseElementAst,
       this.shouldOutput});

  static ElementInfo createElementInfo(
      Iterable<ClassElement> instantiatedClasses,
      Iterable<AstElement> resolvedElements,
      Iterable<ClassElement> usedTypeLiterals,
      {ElementPostProcessFunction postProcessElementAst,
       ComputeElementAstFunction parseElementAst,
       ElementFilter shouldOutput,
       ElementSorter sortElements}) {
    ElementInfoProcessor processor = new ElementInfoProcessor(
        postProcessElementAst: postProcessElementAst,
        parseElementAst: parseElementAst,
        shouldOutput: shouldOutput);
    return processor.process(
        instantiatedClasses, resolvedElements, usedTypeLiterals,
        sortElements: sortElements);
  }

  ElementInfo process(Iterable<ClassElement> instantiatedClasses,
                      Iterable<AstElement> resolvedElements,
                      Iterable<ClassElement> usedTypeLiterals,
                      {ElementSorter sortElements}) {
    // Build all top level elements to emit and necessary class members.
    instantiatedClasses.where(shouldOutput).forEach(addClass);
    resolvedElements.where(shouldOutput).forEach(addMember);
    usedTypeLiterals.forEach((ClassElement element) {
      if (shouldOutput(element)) {
        if (!topLevelElements.contains(element)) {
          // The class is only referenced by type literals.
          emitNoMembersFor.add(element);
        }
        addClass(element);
      }
    });

    // Sort elements.
    List<Element> sortedTopLevels = sortElements(topLevelElements);
    Map<ClassElement, List<Element>> sortedClassMembers =
        new Map<ClassElement, List<Element>>();
    classMembers.forEach((classElement, members) {
      sortedClassMembers[classElement] = sortElements(members);
    });

    return new ElementInfo(
        elementAsts, sortedTopLevels, sortedClassMembers, emitNoMembersFor);
  }

  void processElement(Element element, ElementAst elementAst) {
    if (postProcessElementAst != null) {
      postProcessElementAst(element, elementAst,
                            newTypedefElementCallback,
                            newClassElementCallback);
    }
    elementAsts[element] = elementAst;
  }

  void addTopLevel(AstElement element, ElementAst elementAst) {
    if (topLevelElements.contains(element)) return;
    topLevelElements.add(element);
    processElement(element, elementAst);
  }

  void addClass(ClassElement classElement) {
    TreeElements treeElements = new TreeElementMapping(classElement);
    backend2frontend.TreePrinter treePrinter =
        new backend2frontend.TreePrinter(treeElements);
    Node node = treePrinter.makeNodeForClassElement(classElement);
    addTopLevel(classElement, new ElementAst.internal(node, treeElements));
    classMembers.putIfAbsent(classElement, () => new Set());
  }

  void newTypedefElementCallback(TypedefElement element) {
    if (!shouldOutput(element)) return;
    addTopLevel(element, new ElementAst(element));
  }

  void newClassElementCallback(ClassElement classElement) {
    if (!shouldOutput(classElement)) return;
    addClass(classElement);
  }

  void addMember(element) {
    ElementAst elementAst = parseElementAst(element);
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
  }
}

/// Main output generator for [DartOutputter] that emits dart code through a
/// [CompilerOutputProvider].
class MainOutputGenerator {
  final Map<ClassNode, List<Node>> memberNodes =
       new Map<ClassNode, List<Node>>();
  final List<Node> topLevelNodes = <Node>[];

  String generateCode(
      LibraryInfo libraryInfo,
      ElementInfo elementInfo,
      PlaceholderCollector collector,
      PlaceholderRenamer placeholderRenamer,
      FunctionElement mainFunction,
      Uri outputUri,
      CompilerOutputProvider outputProvider,
      MirrorRenamer mirrorRenamer,
      {bool multiFile: false,
       bool forceStripTypes: false,
       bool enableMinification: false}) {
    for (Element element in elementInfo.topLevelElements) {
      topLevelNodes.add(elementInfo.elementAsts[element].ast);
      if (element.isClass && !element.isMixinApplication) {
        final members = <Node>[];
        for (Element member in elementInfo.classMembers[element]) {
          members.add(elementInfo.elementAsts[member].ast);
        }
        memberNodes[elementInfo.elementAsts[element].ast] = members;
      }
    }

    mirrorRenamer.addRenames(placeholderRenamer.renames,
                             topLevelNodes, collector);

    Map<LibraryElement, String> outputPaths = new Map<LibraryElement, String>();
    Map<LibraryElement, EmitterUnparser> unparsers =
        new Map<LibraryElement, EmitterUnparser>();

    // The single unparser used if we collect all the output in one file.
    EmitterUnparser mainUnparser = multiFile
        ? null
        : new EmitterUnparser(placeholderRenamer.renames,
            stripTypes: forceStripTypes,
            minify: enableMinification);

    if (multiFile) {
      // TODO(sigurdm): Factor handling of library-paths out from emitting.
      String mainName = outputUri.pathSegments.last;
      String mainBaseName = mainName.endsWith(".dart")
          ? mainName.substring(0, mainName.length - 5)
          : mainName;
      // Map each library to a path based on the uri of the original
      // library and [compiler.outputUri].
      Set<String> usedLibraryPaths = new Set<String>();
      for (LibraryElement library in libraryInfo.userLibraries) {
        if (library == mainFunction.library) {
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
      for(LibraryElement outputLibrary in libraryInfo.userLibraries) {
        EmitterUnparser unparser = new EmitterUnparser(
            placeholderRenamer.renames,
            stripTypes: forceStripTypes,
            minify: enableMinification);
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

    for (int i = 0; i < elementInfo.topLevelElements.length; i++) {
      Element element = elementInfo.topLevelElements.elementAt(i);
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
    String assembledCode;
    if (multiFile) {
      for(LibraryElement outputLibrary in libraryInfo.userLibraries) {
        // TODO(sigurdm): Make the unparser output directly into the buffer
        // instead of caching in `.result`.
        String code = unparsers[outputLibrary].result;
        totalSize += code.length;
        outputProvider(outputPaths[outputLibrary], "dart")
             ..add(code)
             ..close();
      }
      // TODO(sigurdm): We should get rid of compiler.assembledCode.
      assembledCode = unparsers[mainFunction.library].result;
    } else {
      assembledCode = mainUnparser.result;
      outputProvider("", "dart")
           ..add(assembledCode)
           ..close();

      totalSize = assembledCode.length;
    }

    return assembledCode;
  }
}