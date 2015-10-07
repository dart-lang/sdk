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
  final DiagnosticReporter reporter;
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
  DartOutputter(this.reporter, this.outputProvider,
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
  ///
  /// Returns the total size of the generated code.
  int assembleProgram({
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

    libraryInfo = LibraryInfo.processLibraries(
        reporter, libraries, resolvedElements);

    elementInfo = ElementInfoProcessor.createElementInfo(
        instantiatedClasses,
        resolvedElements,
        usedTypeLiterals,
        postProcessElementAst: postProcessElementAst,
        parseElementAst: computeElementAst,
        shouldOutput: shouldOutput,
        sortElements: sortElements);

    PlaceholderCollector collector = collectPlaceholders(
        reporter,
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

    if (outputAst) {
      String code = astOutput(reporter, elementInfo);
      outputProvider("", "dart")
                 ..add(code)
                 ..close();
      return code.length;
    } else {
      output = new MainOutputGenerator();
      return output.generateCode(
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
  }

  static PlaceholderCollector collectPlaceholders(
      DiagnosticReporter reporter,
      MirrorRenamer mirrorRenamer,
      FunctionElement mainFunction,
      LibraryInfo libraryInfo,
      ElementInfo elementInfo) {
    // Create all necessary placeholders.
    PlaceholderCollector collector = new PlaceholderCollector(
        reporter,
        mirrorRenamer,
        libraryInfo.fixedDynamicNames,
        elementInfo.elementAsts,
        mainFunction);

    makePlaceholders(element) {
      collector.collect(element);

      if (element.isClass && !element.isEnumClass) {
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
        libraryInfo.fixedDynamicNames,
        libraryInfo.fixedStaticNames,
        libraryInfo.reexportingLibraries,
        cutDeclarationTypes: shouldCutDeclarationTypes,
        enableMinification: enableMinification);

    placeholderRenamer.computeRenames(collector);
    return placeholderRenamer;
  }

  static String astOutput(DiagnosticReporter reporter,
                          ElementInfo elementInfo) {
    // TODO(antonm): Ideally XML should be a separate backend.
    // TODO(antonm): obey renames and minification, at least as an option.
    StringBuffer sb = new StringBuffer();
    outputElement(element) {
      sb.write(element.parseNode(reporter).toDebugString());
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
  final Set<String> fixedStaticNames;
  final Set<String> fixedDynamicNames;
  final Map<Element, LibraryElement> reexportingLibraries;
  final List<LibraryElement> userLibraries;

  LibraryInfo(this.fixedStaticNames,
              this.fixedDynamicNames,
              this.reexportingLibraries,
              this.userLibraries);

  static LibraryInfo processLibraries(
      DiagnosticReporter reporter,
      Iterable<LibraryElement> libraries,
      Iterable<AstElement> resolvedElements) {
    Set<String> fixedStaticNames = new Set<String>();
    Set<String> fixedDynamicNames = new Set<String>();
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
            if (member.isInstanceMember) {
              fixedDynamicNames.add(member.name);
            } else {
              fixedStaticNames.add(member.name);
            }
          });
        }
        // Even class names are added due to a delicate problem we have:
        // if one imports dart:core with a prefix, we cannot tell prefix.name
        // from dynamic invocation (alas!).  So we'd better err on preserving
        // those names.
        fixedStaticNames.add(element.name);
      });

      library.forEachExport((Element export) {
        if (!library.isInternalLibrary &&
            export.library.isInternalLibrary) {
          // If an element of an internal library is reexported by a platform
          // library, we have to import the reexporting library instead of the
          // internal library, because the internal library is an
          // implementation detail of dart2js.
          reexportingLibraries[export] = library;
        }
      });
    }

    // Map to keep track of names of enum classes. Since these cannot be renamed
    // we ensure that they are unique.
    Map<String, ClassElement> enumClassMap = <String, ClassElement>{};

    // As of now names of named optionals are not renamed. Therefore add all
    // field names used as named optionals into [fixedMemberNames].
    for (final element in resolvedElements) {
      if (!element.isConstructor) continue;
      for (ParameterElement parameter in element.parameters) {
        if (parameter.isInitializingFormal && parameter.isNamed) {
          fixedDynamicNames.add(parameter.name);
        }
      }
      ClassElement cls = element.enclosingClass;
      if (cls != null && cls.isEnumClass) {
        fixedDynamicNames.add('index');

        ClassElement existingEnumClass =
            enumClassMap.putIfAbsent(cls.name, () => cls);
        if (existingEnumClass != cls) {
          reporter.reportError(
              reporter.createMessage(
                  cls,
                  MessageKind.GENERIC,
                  {'text': "Duplicate enum names are not supported "
                           "in dart2dart."}),
          <DiagnosticMessage>[
              reporter.createMessage(
                  existingEnumClass,
                  MessageKind.GENERIC,
                  {'text': "This is the other declaration of '${cls.name}'."}),
          ]);
        }
      }
    }

    fixedStaticNames.addAll(enumClassMap.keys);

    // The VM will automatically invoke the call method of objects
    // that are invoked as functions. Make sure to not rename that.
    fixedDynamicNames.add('call');

    return new LibraryInfo(
        fixedStaticNames, fixedDynamicNames,
        reexportingLibraries, userLibraries);
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
    addTopLevel(classElement, new ElementAst(node, treeElements));
    classMembers.putIfAbsent(classElement, () => new Set());
  }

  void newTypedefElementCallback(TypedefElement element) {
    if (!shouldOutput(element)) return;
    TreeElements treeElements = new TreeElementMapping(element);
    backend2frontend.TreePrinter treePrinter =
        new backend2frontend.TreePrinter(treeElements);
    Node node = treePrinter.makeTypedef(element);
    addTopLevel(element, new ElementAst(node, treeElements));
  }

  void newClassElementCallback(ClassElement classElement) {
    if (!shouldOutput(classElement)) return;
    addClass(classElement);
  }

  void addMember(element) {
    if (element.isClassMember) {
      ClassElement enclosingClass = element.enclosingClass;
      assert(enclosingClass.isClass);
      assert(shouldOutput(enclosingClass));
      addClass(enclosingClass);
      classMembers[enclosingClass].add(element);
      if (enclosingClass.isEnumClass) return;
      processElement(element, parseElementAst(element));
    } else {
      if (element.isTopLevel) {
        addTopLevel(element, parseElementAst(element));
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

  /// Generates the code and returns the total size.
  int generateCode(
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
      if (element.isClass) {
        ClassElement cls = element;
        if (cls.isMixinApplication || cls.isEnumClass) {
          continue;
        }
        final members = <Node>[];
        for (Element member in elementInfo.classMembers[cls]) {
          members.add(elementInfo.elementAsts[member].ast);
        }
        memberNodes[elementInfo.elementAsts[cls].ast] = members;
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
        if (outputLibrary.hasLibraryName) {
          unparser.unparseLibraryName(outputLibrary.libraryName);
        }
        for (ImportElement import in outputLibrary.imports) {
          LibraryElement libraryElement = import.importedLibrary;
          String uri = outputPaths.containsKey(libraryElement)
              ? "${outputPaths[libraryElement]}.dart"
              : libraryElement.canonicalUri.toString();
          unparser.unparseImportTag(uri);
        }
        for (ExportElement export in outputLibrary.exports) {
          LibraryElement libraryElement = export.exportedLibrary;
          String uri = outputPaths.containsKey(libraryElement)
              ? "${outputPaths[libraryElement]}.dart"
              : libraryElement.canonicalUri.toString();
          unparser.unparseExportTag(uri);
        }
      }
    } else {
      placeholderRenamer.platformImports.forEach(
          (LibraryElement library, String prefix) {
        assert(library.isPlatformLibrary && !library.isInternalLibrary);
        mainUnparser.unparseImportTag(library.canonicalUri.toString());
        if (prefix != null) {
          // Adding a prefixed import because (some) top-level access need
          // it to avoid shadowing.
          // TODO(johnniwinther): Avoid prefix-less import if not needed.
          mainUnparser.unparseImportTag(library.canonicalUri.toString(),
                                        prefix: prefix);
        }
      });
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
    } else {
      String code = mainUnparser.result;
      outputProvider("", "dart")
           ..add(code)
           ..close();

      totalSize = code.length;
    }

    return totalSize;
  }
}