// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class ScannerTask extends CompilerTask {
  ScannerTask(Compiler compiler) : super(compiler);
  String get name => 'Scanner';

  void scanLibrary(LibraryElement library) {
    var compilationUnit = library.entryCompilationUnit;
    compiler.log("scanning library ${compilationUnit.script.name}");
    scan(compilationUnit);
    processScriptTags(library);
  }

  void scan(CompilationUnitElement compilationUnit) {
    measure(() {
      scanElements(compilationUnit);
    });
  }

  void processScriptTags(LibraryElement library) {
    int tagState = TagState.NO_TAG_SEEN;

    /**
     * If [value] is less than [tagState] complain and return
     * [tagState]. Otherwise return the new value for [tagState]
     * (transition function for state machine).
     */
    int checkTag(int value, ScriptTag tag) {
      if (tagState > value) {
        compiler.reportError(tag, 'out of order');
        return tagState;
      }
      return TagState.NEXT[value];
    }

    LinkBuilder<ScriptTag> imports = new LinkBuilder<ScriptTag>();
    Uri base = library.entryCompilationUnit.script.uri;
    for (ScriptTag tag in library.tags.reverse()) {
      StringNode argument = tag.argument;
      // TODO(lrn): Support interpolations here. We need access to the
      // special constants that can be inserted into script tag strings.
      Uri resolved = base.resolve(argument.dartString.slowToString());
      if (tag.isImport()) {
        tagState = checkTag(TagState.IMPORT, tag);
        // It is not safe to import other libraries at this point as
        // another library could then observe the current library
        // before it fully declares all the members that are sourced
        // in.
        imports.addLast(tag);
      } else if (tag.isLibrary()) {
        tagState = checkTag(TagState.LIBRARY, tag);
        if (library.libraryTag !== null) {
          compiler.cancel("duplicated library declaration", node: tag);
        } else {
          library.libraryTag = tag;
        }
      } else if (tag.isSource()) {
        tagState = checkTag(TagState.SOURCE, tag);
        importSourceFromTag(tag, resolved, library);
      } else {
        compiler.cancel("illegal script tag: ${tag.tag}", node: tag);
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

    for (ScriptTag tag in imports.toLink()) {
      importLibraryFromTag(tag, library.entryCompilationUnit);
    }
  }

  /**
   * Handle a source tag in the scope of [library]. The [path] given is used as
   * is, any resolution should be done beforehand.
   */
  void importSourceFromTag(ScriptTag tag, Uri path, LibraryElement library) {
    Script sourceScript = compiler.readScript(path, tag);
    CompilationUnitElement unit =
        new CompilationUnitElement(sourceScript, library);
    compiler.withCurrentElement(unit, () => compiler.scanner.scan(unit));
  }

  /**
   * Handle an import script tag by importing the referenced library into the
   * current library.
   * Returns the resolved library [Uri].
   */
  Uri importLibraryFromTag(ScriptTag tag,
                           CompilationUnitElement compilationUnit) {
    Uri base = compilationUnit.script.uri;
    StringNode argument = tag.argument;
    Uri resolved = base.resolve(argument.dartString.slowToString());
    LibraryElement importedLibrary = loadLibrary(resolved, argument, resolved);
    importLibrary(compilationUnit.getLibrary(),
                  importedLibrary,
                  tag,
                  compilationUnit);
    return resolved;
  }

  void scanElements(CompilationUnitElement compilationUnit) {
    Script script = compilationUnit.script;
    Token tokens;
    try {
      tokens = new StringScanner(script.text).tokenize();
    } catch (MalformedInputException ex) {
      Token token;
      var message;
      if (ex.position is num) {
        // TODO(ahe): Always use tokens in MalformedInputException.
        token = new Token(EOF_INFO, ex.position);
      } else {
        token = ex.position;
      }
      compiler.cancel(ex.message, token: token);
    }
    compiler.dietParser.dietParse(compilationUnit, tokens);
  }

  LibraryElement loadLibrary(Uri uri, Node node, Uri canonicalUri) {
    bool newLibrary = false;
    LibraryElement library =
      compiler.libraries.putIfAbsent(uri.toString(), () {
          newLibrary = true;
          Script script = compiler.readScript(uri, node);
          LibraryElement element = new LibraryElement(script, canonicalUri);
          native.maybeEnableNative(compiler, element, uri);
          return element;
        });
    if (newLibrary) {
      compiler.withCurrentElement(library, () {
        scanLibrary(library);
        compiler.onLibraryLoaded(library, uri);
      });
    }
    return library;
  }

  void importLibrary(LibraryElement library, LibraryElement imported,
                     ScriptTag tag, [CompilationUnitElement compilationUnit]) {
    if (!imported.hasLibraryName()) {
      compiler.withCurrentElement(library, () {
        compiler.reportError(tag === null ? null : tag.argument,
                             'no #library tag found in ${imported.uri}');
      });
    }
    if (tag !== null && tag.prefix !== null) {
      SourceString prefix =
          new SourceString(tag.prefix.dartString.slowToString());
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
          library.addToScope(element, compiler);
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
