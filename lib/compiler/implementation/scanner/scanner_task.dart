// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class ScannerTask extends CompilerTask {
  ScannerTask(Compiler compiler) : super(compiler);
  String get name() => 'Scanner';

  void scan(CompilationUnitElement compilationUnit) {
    measure(() {
      if (compilationUnit.kind === ElementKind.LIBRARY) {
        compiler.log("scanning library ${compilationUnit.script.name}");
      }
      scanElements(compilationUnit);
      if (compilationUnit.kind === ElementKind.LIBRARY) {
        processScriptTags(compilationUnit);
      }
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
    Uri base = library.script.uri;
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
        Script script = compiler.readScript(resolved, tag);
        CompilationUnitElement unit =
          new CompilationUnitElement(script, library);
        compiler.withCurrentElement(unit, () => scan(unit));
      } else if (tag.isResource()) {
        tagState = checkTag(TagState.RESOURCE, tag);
        compiler.reportWarning(tag, 'ignoring resource tag');
      } else {
        compiler.cancel("illegal script tag: ${tag.tag}", node: tag);
      }
    }
    // TODO(ahe): During Compiler.scanBuiltinLibraries,
    // compiler.coreLibrary is null. Clean this up when there is a
    // better way to access "dart:core".
    bool implicitlyImportCoreLibrary = compiler.coreLibrary !== null;
    for (ScriptTag tag in imports.toLink()) {
      // Now that we have processed all the source tags, it is safe to
      // start loading other libraries.
      StringNode argument = tag.argument;
      Uri resolved = base.resolve(argument.dartString.slowToString());
      if (resolved.toString() == "dart:core") {
        implicitlyImportCoreLibrary = false;
      }
      importLibrary(library, loadLibrary(resolved, tag), tag);
    }
    if (implicitlyImportCoreLibrary) {
      importLibrary(library, compiler.coreLibrary, null);
    }
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

  LibraryElement loadLibrary(Uri uri, ScriptTag node) {
    bool newLibrary = false;
    LibraryElement library =
      compiler.universe.libraries.putIfAbsent(uri.toString(), () {
          newLibrary = true;
          Script script = compiler.readScript(uri, node);
          LibraryElement element = new LibraryElement(script);
          native.maybeEnableNative(compiler, element, uri);
          return element;
        });
    if (newLibrary) {
      compiler.withCurrentElement(library, () => scan(library));
      compiler.onLibraryLoaded(library, uri);
    }
    return library;
  }

  void importLibrary(LibraryElement library, LibraryElement imported,
                     ScriptTag tag) {
    if (!imported.hasLibraryName()) {
      compiler.withCurrentElement(library, () {
        compiler.reportError(tag,
                             'no #library tag found in ${imported.script.uri}');
      });
    }
    if (tag !== null && tag.prefix !== null) {
      SourceString prefix =
          new SourceString(tag.prefix.dartString.slowToString());
      Element e = library.find(prefix);
      if (e === null) {
        e = new PrefixElement(prefix, library, tag.getBeginToken());
        library.define(e, compiler);
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
          library.define(element, compiler);
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
      ElementListener listener = new ElementListener(compiler, compilationUnit);
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
  static final int NO_TAG_SEEN = 0;
  static final int LIBRARY = 1;
  static final int IMPORT = 2;
  static final int SOURCE = 3;
  static final int RESOURCE = 4;

  /** Next state. */
  static final List<int> NEXT =
      const <int>[NO_TAG_SEEN,
                  IMPORT, // Only one library tag is allowed.
                  IMPORT,
                  SOURCE,
                  RESOURCE];
}
