// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class ScannerTask extends CompilerTask {
  ScannerTask(Compiler compiler) : super(compiler);
  String get name => 'Scanner';

  final Map<String, LibraryElement> libraryNames =
      new Map<String, LibraryElement>();

  void scanLibrary(LibraryElement library) {
    var compilationUnit = library.entryCompilationUnit;
    compiler.log("scanning library ${compilationUnit.script.name}");
    scan(compilationUnit);
    processLibraryTags(library);
  }

  void scan(CompilationUnitElement compilationUnit) {
    measure(() {
      scanElements(compilationUnit);
    });
  }

  void processLibraryTags(LibraryElement library) {
    int tagState = TagState.NO_TAG_SEEN;

    /**
     * If [value] is less than [tagState] complain and return
     * [tagState]. Otherwise return the new value for [tagState]
     * (transition function for state machine).
     */
    int checkTag(int value, LibraryTag tag) {
      if (tagState > value) {
        compiler.reportError(tag, 'out of order');
        return tagState;
      }
      return TagState.NEXT[value];
    }

    LinkBuilder<Import> imports = new LinkBuilder<Import>();
    Uri base = library.entryCompilationUnit.script.uri;
    for (LibraryTag tag in library.tags.reverse()) {
      if (tag.isImport) {
        tagState = checkTag(TagState.IMPORT, tag);
        if (tag.combinators != null) {
          compiler.unimplemented('combinators', node: tag.combinators);
        }
        // It is not safe to import other libraries at this point as
        // another library could then observe the current library
        // before it fully declares all the members that are sourced
        // in.
        imports.addLast(tag);
      } else if (tag.isLibraryName) {
        tagState = checkTag(TagState.LIBRARY, tag);
        if (library.libraryTag !== null) {
          compiler.cancel("duplicated library declaration", node: tag);
        } else {
          library.libraryTag = tag;
        }
        checkDuplicatedLibraryName(library);
      } else if (tag.isPart) {
        StringNode uri = tag.uri;
        Uri resolved = base.resolve(uri.dartString.slowToString());
        tagState = checkTag(TagState.SOURCE, tag);
        loadPart(tag, resolved, library);
      } else {
        compiler.internalError("Unhandled library tag.", node: tag);
      }
    }

    // Apply patch, if any.
    if (library.uri.scheme == 'dart') {
      compiler.patchDartLibrary(library, library.uri.path);
    }

    // Now that we have processed all the source tags, it is safe to
    // start loading other libraries.

    if (library.uri.scheme != 'dart' || library.uri.path != 'core') {
      compiler.importCoreLibrary(library);
    }

    for (Import tag in imports.toLink()) {
      importLibraryFromTag(tag, library.entryCompilationUnit);
    }
  }

  void checkDuplicatedLibraryName(LibraryElement library) {
    LibraryTag tag = library.libraryTag;
    if (tag != null) {
      String name = library.getLibraryOrScriptName();
      LibraryElement existing =
          libraryNames.putIfAbsent(name, () => library);
      if (existing !== library) {
        Uri uri = library.entryCompilationUnit.script.uri;
        compiler.reportMessage(
            compiler.spanFromNode(tag.name, uri),
            MessageKind.DUPLICATED_LIBRARY_NAME.error([name]),
            api_s.Diagnostic.WARNING);
        Uri existingUri = existing.entryCompilationUnit.script.uri;
        compiler.reportMessage(
            compiler.spanFromNode(existing.libraryTag.name, existingUri),
            MessageKind.DUPLICATED_LIBRARY_NAME.error([name]),
            api_s.Diagnostic.WARNING);
      }
    }
  }

  /**
   * Handle a part tag in the scope of [library]. The [path] given is used as
   * is, any resolution should be done beforehand.
   */
  void loadPart(Part part, Uri path, LibraryElement library) {
    Script sourceScript = compiler.readScript(path, part.uri);
    CompilationUnitElement unit =
        new CompilationUnitElement(sourceScript, library);
    compiler.withCurrentElement(unit, () => compiler.scanner.scan(unit));
  }

  /**
   * Handle an import script tag by importing the referenced library into the
   * current library.
   * Returns the resolved library [Uri].
   */
  Uri importLibraryFromTag(Import tag,
                           CompilationUnitElement compilationUnit) {
    Uri base = compilationUnit.script.uri;
    Uri resolved = base.resolve(tag.uri.dartString.slowToString());
    LibraryElement importedLibrary = loadLibrary(resolved, tag.uri, resolved);
    importLibrary(compilationUnit.getLibrary(),
                  importedLibrary,
                  tag,
                  compilationUnit);
    return resolved;
  }

  void scanElements(CompilationUnitElement compilationUnit) {
    Script script = compilationUnit.script;
    Token tokens = new StringScanner(script.text).tokenize();
    compiler.dietParser.dietParse(compilationUnit, tokens);
  }

  LibraryElement loadLibrary(Uri uri, Node node, Uri canonicalUri) {
    bool newLibrary = false;
    LibraryElement createLibrary() {
      newLibrary = true;
      Script script = compiler.readScript(uri, node);
      LibraryElement element = new LibraryElement(script, canonicalUri);
      native.maybeEnableNative(compiler, element, uri);
      return element;
    }
    LibraryElement library;
    if (canonicalUri === null) {
      library = createLibrary();
    } else {
      library = compiler.libraries.putIfAbsent(canonicalUri.toString(),
                                               createLibrary);
    }
    if (newLibrary) {
      compiler.withCurrentElement(library, () {
        scanLibrary(library);
        compiler.onLibraryLoaded(library, uri);
      });
    }
    return library;
  }

  void importLibrary(LibraryElement library, LibraryElement imported,
                     Import tag, [CompilationUnitElement compilationUnit]) {
    if (!imported.hasLibraryName()) {
      compiler.withCurrentElement(library, () {
        compiler.reportError(tag === null ? null : tag.uri,
                             'no #library tag found in ${imported.uri}');
      });
    }
    if (tag !== null && tag.prefix !== null) {
      SourceString prefix = tag.prefix.source;
      Element e = library.find(prefix);
      if (e === null) {
        if (compilationUnit === null) {
          compilationUnit = library.entryCompilationUnit;
        }
        e = new PrefixElement(prefix, compilationUnit, tag.getBeginToken());
        library.addToScope(e, compiler);
      }
      if (e.kind !== ElementKind.PREFIX) {
        compiler.withCurrentElement(e, () {
          compiler.reportWarning(new Identifier(e.position()),
                                 'duplicated definition');
        });
        compiler.reportError(tag.prefix, 'duplicate defintion');
      }
      PrefixElement prefixElement = e;
      imported.forEachExport((Element element) {
        Element existing =
            prefixElement.imported.putIfAbsent(element.name, () => element);
        if (existing !== element) {
          compiler.withCurrentElement(existing, () {
            compiler.reportWarning(new Identifier(existing.position()),
                                   'duplicated import');
          });
          compiler.withCurrentElement(element, () {
            compiler.reportError(new Identifier(element.position()),
                                 'duplicated import');
          });
        }
      });
    } else {
      imported.forEachExport((Element element) {
        compiler.withCurrentElement(element, () {
          library.addImport(element, compiler);
        });
      });
    }
  }
}

class DietParserTask extends CompilerTask {
  DietParserTask(Compiler compiler) : super(compiler);
  final String name = 'Diet Parser';

  dietParse(CompilationUnitElement compilationUnit, Token tokens) {
    measure(() {
      Function idGenerator = compiler.getNextFreeClassId;
      ElementListener listener =
          new ElementListener(compiler, compilationUnit, idGenerator);
      PartialParser parser = new PartialParser(listener);
      parser.parseUnit(tokens);
    });
  }
}

/**
 * The fields of this class models a state machine for checking script
 * tags come in the correct order.
 */
class TagState {
  static const int NO_TAG_SEEN = 0;
  static const int LIBRARY = 1;
  static const int IMPORT = 2;
  static const int SOURCE = 3;
  static const int RESOURCE = 4;

  /** Next state. */
  static const List<int> NEXT =
      const <int>[NO_TAG_SEEN,
                  IMPORT, // Only one library tag is allowed.
                  IMPORT,
                  SOURCE,
                  RESOURCE];
}
