// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * To generate docs for a library, run this script with the path to an
 * entrypoint .dart file, like:
 *
 *     $ dart dartdoc.dart foo.dart
 *
 * This will create a "docs" directory with the docs for your libraries. To
 * create these beautiful docs, dartdoc parses your library and every library
 * it imports (recursively). From each library, it parses all classes and
 * members, finds the associated doc comments and builds crosslinked docs from
 * them.
 */
#library('dartdoc');

#import('dart:io');
#import('dart:json');
#import('../../frog/lang.dart');
#import('../../frog/file_system.dart');
#import('../../frog/file_system_vm.dart');
#import('classify.dart');
#import('markdown.dart', prefix: 'md');

#source('comment_map.dart');
#source('utils.dart');

/**
 * Generates completely static HTML containing everything you need to browse
 * the docs. The only client side behavior is trivial stuff like syntax
 * highlighting code.
 */
final MODE_STATIC = 0;

/**
 * Generated docs do not include baked HTML navigation. Instead, a single
 * `nav.json` file is created and the appropriate navigation is generated
 * client-side by parsing that and building HTML.
 *
 * This dramatically reduces the generated size of the HTML since a large
 * fraction of each static page is just redundant navigation links.
 *
 * In this mode, the browser will do a XHR for nav.json which means that to
 * preview docs locally, you will need to enable requesting file:// links in
 * your browser or run a little local server like `python -m SimpleHTTPServer`.
 */
final MODE_LIVE_NAV = 1;

/**
 * Run this from the `lib/dartdoc` directory.
 */
void main() {
  final args = new Options().arguments;

  // Parse the dartdoc options.
  bool includeSource;
  int mode;
  String outputDir;
  bool generateAppCache;

  for (int i = 0; i < args.length - 1; i++) {
    final arg = args[i];

    switch (arg) {
      case '--no-code':
        includeSource = false;
        break;

      case '--mode=static':
        mode = MODE_STATIC;
        break;

      case '--mode=live-nav':
        mode = MODE_LIVE_NAV;
        break;

      case '--generate-app-cache':
      case '--generate-app-cache=true':
        generateAppCache = true;
        break;

      default:
        if (arg.startsWith('--out=')) {
          outputDir = arg.substring('--out='.length);
        } else {
          print('Unknown option: $arg');
          return;
        }
        break;
    }
  }

  // The entrypoint of the library to generate docs for.
  final entrypoint = args[args.length - 1];

  final files = new VMFileSystem();

  // TODO(rnystrom): Note that the following lines get munged by create-sdk to
  // work with the SDK's different file layout. If you change, be sure to test
  // that dartdoc still works when run from the built SDK directory.
  final frogPath = joinPaths(scriptDir, '../../frog/');
  final libDir = joinPaths(frogPath, 'lib');
  final compilerPath = joinPaths(frogPath, 'minfrog');

  parseOptions(frogPath, ['', '', '--libdir=$libDir'], files);
  initializeWorld(files);

  final dartdoc = new Dartdoc();

  if (includeSource != null) dartdoc.includeSource = includeSource;
  if (mode != null) dartdoc.mode = mode;
  if (outputDir != null) dartdoc.outputDir = outputDir;
  if (generateAppCache != null) dartdoc.generateAppCache = generateAppCache;

  cleanOutputDirectory(dartdoc.outputDir);

  // Compile the client-side code to JS.
  final clientScript = (dartdoc.mode == MODE_STATIC) ? 'static' : 'live-nav';
  final Future scriptCompiled = compileScript(compilerPath, libDir,
                '$scriptDir/client-$clientScript.dart',
                '${dartdoc.outputDir}/client-$clientScript.js');

  final Future filesCopied = copyFiles('$scriptDir/static', dartdoc.outputDir);

  Futures.wait([scriptCompiled, filesCopied]).then((_) {
    dartdoc.document(entrypoint);
  });

  print('Documented ${dartdoc._totalLibraries} libraries, ' +
      '${dartdoc._totalTypes} types, and ' +
      '${dartdoc._totalMembers} members.');
}

/**
 * Gets the full path to the directory containing the entrypoint of the current
 * script. In other words, if you invoked dartdoc, directly, it will be the
 * path to the directory containing `dartdoc.dart`. If you're running a script
 * that imports dartdoc, it will be the path to that script.
 */
String get scriptDir() {
  return dirname(new File(new Options().script).fullPathSync());
}

/**
 * Deletes and recreates the output directory at [path] if it exists.
 */
void cleanOutputDirectory(String path) {
  final outputDir = new Directory(path);
  if (outputDir.existsSync()) {
    outputDir.deleteRecursivelySync();
  }

  outputDir.createSync();
}

/**
 * Copies all of the files in the directory [from] to [to]. Does *not*
 * recursively copy subdirectories.
 *
 * Note: runs asynchronously, so you won't see any files copied until after the
 * event loop has had a chance to pump (i.e. after `main()` has returned).
 */
Future copyFiles(String from, String to) {
  final completer = new Completer();
  final fromDir = new Directory(from);
  fromDir.onFile = (path) {
    final name = basename(path);
    // TODO(rnystrom): Hackish. Ignore 'hidden' files like .DS_Store.
    if (name.startsWith('.')) return;

    new File(path).readAsBytes((bytes) {
      final outFile = new File('$to/$name');
      final stream = outFile.openOutputStream(FileMode.WRITE);
      stream.write(bytes, copyBuffer: false);
      stream.close();
    });
  };
  fromDir.onDone = (done) => completer.complete(true);
  fromDir.list(recursive: false);
  return completer.future;
}

/**
 * Compiles the given Dart script to a JavaScript file at [jsPath] using the
 * Dart-to-JS compiler located at [compilerPath].
 */
Future compileScript(String compilerPath, String libDir,
    String dartPath, String jsPath) {
  final completer = new Completer();
  onExit(int exitCode, String stdout, String stderr) {
    if (exitCode != 0) {
      final message = 'Non-zero exit code from $compilerPath';
      print('$message.');
      print(stdout);
      print(stderr);
      throw message;
    }
    completer.complete(true);
  }

  onError(error) {
    final message = 'Error trying to execute $compilerPath. Error: $error';
    print('$message.');
    throw message;
  }

  print('Compiling $dartPath to $jsPath');
  new Process.run(compilerPath, [
    '--libdir=$libDir', '--out=$jsPath',
    '--compile-only', '--enable-type-checks', '--warnings-as-errors',
    dartPath], null, onExit).onError = onError;
  return completer.future;
}

class Dartdoc {

  /** Set to `false` to not include the source code in the generated docs. */
  bool includeSource = true;

  /**
   * Dartdoc can generate docs in a few different ways based on how dynamic you
   * want the client-side behavior to be. The value for this should be one of
   * the `MODE_` constants.
   */
  int mode = MODE_LIVE_NAV;

  /**
   * Generates the App Cache manifest file, enabling offline doc viewing.
   */
  bool generateAppCache = false;

  /** Path to generate HTML files into. */
  String outputDir = 'docs';

  /**
   * The title used for the overall generated output. Set this to change it.
   */
  String mainTitle = 'Dart Documentation';

  /**
   * The URL that the Dart logo links to. Defaults "index.html", the main
   * page for the generated docs, but can be anything.
   */
  String mainUrl = 'index.html';

  /**
   * The Google Custom Search ID that should be used for the search box. If
   * this is `null` then no search box will be shown.
   */
  String searchEngineId = null;

  /* The URL that the embedded search results should be displayed on. */
  String searchResultsUrl = 'results.html';

  /** Set this to add footer text to each generated page. */
  String footerText = '';

  /** Set this to add content before the footer */
  String preFooterText = '';

  /**
   * From exposes the set of libraries in `world.libraries`. That maps library
   * *keys* to [Library] objects. The keys are *not* exactly the same as their
   * names. This means if we order by key, we won't actually have them sorted
   * correctly. This list contains the libraries in correct order by their
   * *name*.
   */
  List<Library> _sortedLibraries;

  CommentMap _comments;

  /** The library that we're currently generating docs for. */
  Library _currentLibrary;

  /** The type that we're currently generating docs for. */
  Type _currentType;

  /** The member that we're currently generating docs for. */
  Member _currentMember;

  /** The path to the file currently being written to, relative to [outdir]. */
  String _filePath;

  /** The file currently being written to. */
  StringBuffer _file;

  int _totalLibraries = 0;
  int _totalTypes = 0;
  int _totalMembers = 0;

  Dartdoc()
    : _comments = new CommentMap() {
    // Patch in support for [:...:]-style code to the markdown parser.
    // TODO(rnystrom): Markdown already has syntax for this. Phase this out?
    md.InlineParser.syntaxes.insertRange(0, 1,
        new md.CodeSyntax(@'\[\:((?:.|\n)*?)\:\]'));

    md.setImplicitLinkResolver((name) => resolveNameReference(name,
            library: _currentLibrary, type: _currentType,
            member: _currentMember));
  }

  void document([String entrypoint]) {
    var oldDietParse = options.dietParse;
    try {
      options.dietParse = true;

      // If we have an entrypoint, process it. Otherwise, just use whatever
      // libraries have been previously loaded by the calling code.
      if (entrypoint != null) {
        world.processDartScript(entrypoint);
      }

      world.resolveAll();

      // Sort the libraries by name (not key).
      _sortedLibraries = world.libraries.getValues();
      _sortedLibraries.sort((a, b) {
        return a.name.toUpperCase().compareTo(b.name.toUpperCase());
      });

      // Generate the docs.
      if (mode == MODE_LIVE_NAV) docNavigationJson();

      docIndex();
      for (final library in _sortedLibraries) {
        docLibrary(library);
      }

      if (generateAppCache) {
        generateAppCacheManifest();
      }
    } finally {
      options.dietParse = oldDietParse;
    }
  }

  void startFile(String path) {
    _filePath = path;
    _file = new StringBuffer();
  }

  void endFile() {
    final outPath = '$outputDir/$_filePath';
    final dir = new Directory(dirname(outPath));
    if (!dir.existsSync()) {
      dir.createSync();
    }

    world.files.writeString(outPath, _file.toString());
    _filePath = null;
    _file = null;
  }

  void write(String s) {
    _file.add(s);
  }

  void writeln(String s) {
    write(s);
    write('\n');
  }

  /**
   * Writes the page header with the given [title] and [breadcrumbs]. The
   * breadcrumbs are an interleaved list of links and titles. If a link is null,
   * then no link will be generated. For example, given:
   *
   *     ['foo', 'foo.html', 'bar', null]
   *
   * It will output:
   *
   *     <a href="foo.html">foo</a> &rsaquo; bar
   */
  void writeHeader(String title, List<String> breadcrumbs) {
    final htmlAttributes = generateAppCache ?
        'manifest="/appcache.manifest"' : '';
    
    write(
        '''
        <!DOCTYPE html>
        <html${htmlAttributes == '' ? '' : ' $htmlAttributes'}>
        <head>
        ''');
    writeHeadContents(title);

    // Add data attributes describing what the page documents.
    var data = '';
    if (_currentLibrary != null) {
      data += ' data-library="${md.escapeHtml(_currentLibrary.name)}"';
    }

    if (_currentType != null) {
      data += ' data-type="${md.escapeHtml(typeName(_currentType))}"';
    }

    write(
        '''
        </head>
        <body$data>
        <div class="page">
        <div class="header">
          ${a(mainUrl, '<div class="logo"></div>')}
          ${a('index.html', mainTitle)}
        ''');

    // Write the breadcrumb trail.
    for (int i = 0; i < breadcrumbs.length; i += 2) {
      if (breadcrumbs[i + 1] == null) {
        write(' &rsaquo; ${breadcrumbs[i]}');
      } else {
        write(' &rsaquo; ${a(breadcrumbs[i + 1], breadcrumbs[i])}');
      }
    }

    if (searchEngineId != null) {
      writeln(
        '''
        <form action="$searchResultsUrl" id="search-box">
          <input type="hidden" name="cx" value="$searchEngineId">
          <input type="hidden" name="ie" value="UTF-8">
          <input type="hidden" name="hl" value="en">
          <input type="search" name="q" id="q" autocomplete="off"
              placeholder="Search">
        </form>
        ''');
    }

    writeln('</div>');

    docNavigation();
    writeln('<div class="content">');
  }

  String get clientScript() {
    switch (mode) {
      case MODE_STATIC:   return 'client-static';
      case MODE_LIVE_NAV: return 'client-live-nav';
      default: throw 'Unknown mode $mode.';
    }
  }

  void writeHeadContents(String title) {
    writeln(
        '''
        <meta charset="utf-8">
        <title>$title / $mainTitle</title>
        <link rel="stylesheet" type="text/css"
            href="${relativePath('styles.css')}">
        <link href="http://fonts.googleapis.com/css?family=Open+Sans:400,600,700,800" rel="stylesheet" type="text/css">
        <link rel="shortcut icon" href="${relativePath('favicon.ico')}">
        ''');
  }

  void writeFooter() {
    writeln(
        '''
        </div>
        <div class="clear"></div>
        </div>
        ${preFooterText}
        <div class="footer">$footerText</div>
        <script async src="${relativePath('$clientScript.js')}"></script>
        </body></html>
        ''');
  }

  void docIndex() {
    startFile('index.html');

    writeHeader(mainTitle, []);

    writeln('<h2>$mainTitle</h2>');
    writeln('<h3>Libraries</h3>');

    for (final library in _sortedLibraries) {
      docIndexLibrary(library);
    }

    writeFooter();
    endFile();
  }

  void docIndexLibrary(Library library) {
    writeln('<h4>${a(libraryUrl(library), library.name)}</h4>');
  }

  /**
   * Walks the libraries and creates a JSON object containing the data needed
   * to generate navigation for them.
   */
  void docNavigationJson() {
    startFile('nav.json');

    final libraries = {};

    for (final library in _sortedLibraries) {
      docLibraryNavigationJson(library, libraries);
    }

    writeln(JSON.stringify(libraries));
    endFile();
  }

  void docLibraryNavigationJson(Library library, Map libraries) {
    final types = [];

    for (final type in orderByName(library.types)) {
      if (type.isTop) continue;
      if (type.name.startsWith('_')) continue;

      final kind = type.isClass ? 'class' : 'interface';
      final url = typeUrl(type);
      types.add({ 'name': typeName(type), 'kind': kind, 'url': url });
    }

    libraries[library.name] = types;
  }

  void docNavigation() {
    writeln(
        '''
        <div class="nav">
        ''');

    if (mode == MODE_STATIC) {
      for (final library in _sortedLibraries) {
        write('<h2><div class="icon-library"></div>');

        if ((_currentLibrary == library) && (_currentType == null)) {
          write('<strong>${library.name}</strong>');
        } else {
          write('${a(libraryUrl(library), library.name)}');
        }
        write('</h2>');

        // Only expand classes in navigation for current library.
        if (_currentLibrary == library) docLibraryNavigation(library);
      }
    }

    writeln('</div>');
  }

  /** Writes the navigation for the types contained by the given library. */
  void docLibraryNavigation(Library library) {
    // Show the exception types separately.
    final types = <Type>[];
    final exceptions = <Type>[];

    for (final type in orderByName(library.types)) {
      if (type.isTop) continue;
      if (type.name.startsWith('_')) continue;

      if (type.name.endsWith('Exception')) {
        exceptions.add(type);
      } else {
        types.add(type);
      }
    }

    if ((types.length == 0) && (exceptions.length == 0)) return;

    writeln('<ul class="icon">');
    types.forEach(docTypeNavigation);
    exceptions.forEach(docTypeNavigation);
    writeln('</ul>');
  }

  /** Writes a linked navigation list item for the given type. */
  void docTypeNavigation(Type type) {
    var icon = 'interface';
    if (type.name.endsWith('Exception')) {
      icon = 'exception';
    } else if (type.isClass) {
      icon = 'class';
    }

    write('<li>');
    if (_currentType == type) {
      write(
          '<div class="icon-$icon"></div><strong>${typeName(type)}</strong>');
    } else {
      write(a(typeUrl(type),
          '<div class="icon-$icon"></div>${typeName(type)}'));
    }
    writeln('</li>');
  }

  void docLibrary(Library library) {
    _totalLibraries++;
    _currentLibrary = library;
    _currentType = null;

    startFile(libraryUrl(library));
    writeHeader('${library.name} Library',
        [library.name, libraryUrl(library)]);
    writeln('<h2><strong>${library.name}</strong> library</h2>');

    // Look for a comment for the entire library.
    final comment = _comments.findLibrary(library.baseSource);
    if (comment != null) {
      final html = md.markdownToHtml(comment);
      writeln('<div class="doc">$html</div>');
    }

    // Document the top-level members.
    docMembers(library.topType);

    // Document the types.
    final classes = <Type>[];
    final interfaces = <Type>[];
    final exceptions = <Type>[];

    for (final type in orderByName(library.types)) {
      if (type.isTop) continue;
      if (type.name.startsWith('_')) continue;

      if (type.name.endsWith('Exception')) {
        exceptions.add(type);
      } else if (type.isClass) {
        classes.add(type);
      } else {
        interfaces.add(type);
      }
    }

    docTypes(classes, 'Classes');
    docTypes(interfaces, 'Interfaces');
    docTypes(exceptions, 'Exceptions');

    writeFooter();
    endFile();

    for (final type in library.types.getValues()) {
      if (type.isTop) continue;
      if (type.name.startsWith('_')) continue;
      docType(type);
    }
  }

  void docTypes(List<Type> types, String header) {
    if (types.length == 0) return;

    writeln('<h3>$header</h3>');

    for (final type in types) {
      writeln(
          '''
          <div class="type">
          <h4>
            ${a(typeUrl(type), "<strong>${typeName(type)}</strong>")}
          </h4>
          </div>
          ''');
    }
  }

  void docType(Type type) {
    _totalTypes++;
    _currentType = type;

    startFile(typeUrl(type));

    final typeTitle =
      '${typeName(type)} ${type.isClass ? "Class" : "Interface"}';
    writeHeader('$typeTitle / ${type.library.name} Library',
        [type.library.name, libraryUrl(type.library),
         typeName(type), typeUrl(type)]);
    writeln(
        '''
        <h2><strong>${typeName(type, showBounds: true)}</strong>
          ${type.isClass ? "Class" : "Interface"}
        </h2>
        ''');

    docCode(type.span, getTypeComment(type));
    docInheritance(type);
    docConstructors(type);
    docMembers(type);

    writeTypeFooter();
    writeFooter();
    endFile();
  }

  /** Override this to write additional content at the end of a type's page. */
  void writeTypeFooter() {
    // Do nothing.
  }

  /**
   * Writes an inline type span for the given type. This is a little box with
   * an icon and the type's name. It's similar to how types appear in the
   * navigation, but is suitable for inline (as opposed to in a `<ul>`) use.
   */
  void typeSpan(Type type) {
    var icon = 'interface';
    if (type.name.endsWith('Exception')) {
      icon = 'exception';
    } else if (type.isClass) {
      icon = 'class';
    }

    write('<span class="type-box"><span class="icon-$icon"></span>');
    if (_currentType == type) {
      write('<strong>${typeName(type)}</strong>');
    } else {
      write(a(typeUrl(type), typeName(type)));
    }
    write('</span>');
  }

  /**
   * Document the other types that touch [Type] in the inheritance hierarchy:
   * subclasses, superclasses, subinterfaces, superinferfaces, and default
   * class.
   */
  void docInheritance(Type type) {
    // Don't show the inheritance details for Object. It doesn't have any base
    // class (obviously) and it has too many subclasses to be useful.
    if (type.isObject) return;

    // Writes an unordered list of references to types with an optional header.
    listTypes(types, header) {
      if (types == null) return;

      // Skip private types.
      final publicTypes = types.filter((type) => !type.name.startsWith('_'));
      if (publicTypes.length == 0) return;

      writeln('<h3>$header</h3>');
      writeln('<p>');
      bool first = true;
      for (final type in publicTypes) {
        if (!first) write(', ');
        typeSpan(type);
        first = false;
      }
      writeln('</p>');
    }

    if (type.isClass) {
      // Show the chain of superclasses.
      if (!type.parent.isObject) {
        final supertypes = [];
        var thisType = type.parent;
        // As a sanity check, only show up to five levels of nesting, otherwise
        // the box starts to get hideous.
        do {
          supertypes.add(thisType);
          thisType = thisType.parent;
        } while (!thisType.isObject);

        writeln('<h3>Extends</h3>');
        writeln('<p>');
        for (var i = supertypes.length - 1; i >= 0; i--) {
          typeSpan(supertypes[i]);
          write('&nbsp;&gt;&nbsp;');
        }

        // Write this class.
        typeSpan(type);
        writeln('</p>');
      }

      // Find the immediate declared subclasses (Type.subtypes includes many
      // transitive subtypes).
      final subtypes = [];
      for (final subtype in type.subtypes) {
        if (subtype.parent == type) subtypes.add(subtype);
      }
      subtypes.sort((a, b) => a.name.compareTo(b.name));

      listTypes(subtypes, 'Subclasses');
      listTypes(type.interfaces, 'Implements');
    } else {
      // Show the default class.
      if (type.genericType.defaultType != null) {
        listTypes([type.genericType.defaultType], 'Default class');
      }

      // List extended interfaces.
      listTypes(type.interfaces, 'Extends');

      // List subinterfaces and implementing classes.
      final subinterfaces = [];
      final implementing = [];

      for (final subtype in type.subtypes) {
        // We only want explicitly declared subinterfaces, so check that this
        // type is a superinterface.
        for (final supertype in subtype.interfaces) {
          if (supertype == type) {
            if (subtype.isClass) {
              implementing.add(subtype);
            } else {
              subinterfaces.add(subtype);
            }
            break;
          }
        }
      }

      listTypes(subinterfaces, 'Subinterfaces');
      listTypes(implementing, 'Implemented by');
    }
  }

  /** Document the constructors for [Type], if any. */
  void docConstructors(Type type) {
    final names = type.constructors.getKeys().filter(
      (name) => !name.startsWith('_'));

    if (names.length > 0) {
      writeln('<h3>Constructors</h3>');
      names.sort((x, y) => x.toUpperCase().compareTo(y.toUpperCase()));

      for (final name in names) {
        docMethod(type, type.constructors[name], constructorName: name);
      }
    }
  }

  void docMembers(Type type) {
    // Collect the different kinds of members.
    final staticMethods = [];
    final staticFields = [];
    final instanceMethods = [];
    final instanceFields = [];

    for (final member in orderByName(type.members)) {
      if (member.name.startsWith('_')) continue;

      final methods = member.isStatic ? staticMethods : instanceMethods;
      final fields = member.isStatic ? staticFields : instanceFields;

      if (member.isProperty) {
        if (member.canGet) methods.add(member.getter);
        if (member.canSet) methods.add(member.setter);
      } else if (member.isMethod) {
        methods.add(member);
      } else if (member.isField) {
        fields.add(member);
      }
    }

    if (staticMethods.length > 0) {
      final title = type.isTop ? 'Functions' : 'Static Methods';
      writeln('<h3>$title</h3>');
      for (final method in staticMethods) docMethod(type, method);
    }

    if (staticFields.length > 0) {
      final title = type.isTop ? 'Variables' : 'Static Fields';
      writeln('<h3>$title</h3>');
      for (final field in staticFields) docField(type, field);
    }

    if (instanceMethods.length > 0) {
      writeln('<h3>Methods</h3>');
      for (final method in instanceMethods) docMethod(type, method);
    }

    if (instanceFields.length > 0) {
      writeln('<h3>Fields</h3>');
      for (final field in instanceFields) docField(type, field);
    }
  }

  /**
   * Documents the [method] in type [type]. Handles all kinds of methods
   * including getters, setters, and constructors.
   */
  void docMethod(Type type, MethodMember method,
      [String constructorName = null]) {
    _totalMembers++;
    _currentMember = method;

    writeln('<div class="method"><h4 id="${memberAnchor(method)}">');

    if (includeSource) {
      writeln('<span class="show-code">Code</span>');
    }

    if (method.isConstructor) {
      write(method.isConst ? 'const ' : 'new ');
    }

    if (constructorName == null) {
      annotateType(type, method.returnType);
    }

    // Translate specially-named methods: getters, setters, operators.
    var name = method.name;
    if (name.startsWith('get:')) {
      // Getter.
      name = 'get ${name.substring(4)}';
    } else if (name.startsWith('set:')) {
      // Setter.
      name = 'set ${name.substring(4)}';
    } else if (name == ':negate') {
      // Dart uses 'negate' for prefix negate operators, not '!'.
      name = 'operator negate';
    } else if (name == ':call') {
      name = 'operator call';
    } else {
      // See if it's an operator.
      name = TokenKind.rawOperatorFromMethod(name);
      if (name == null) {
        name = method.name;
      } else {
        name = 'operator $name';
      }
    }

    write('<strong>$name</strong>');

    // Named constructors.
    if (constructorName != null && constructorName != '') {
      write('.');
      write(constructorName);
    }

    docParamList(type, method);

    write(''' <a class="anchor-link" href="#${memberAnchor(method)}"
              title="Permalink to ${typeName(type)}.$name">#</a>''');
    writeln('</h4>');

    docCode(method.span, getMethodComment(method), showCode: true);

    writeln('</div>');
  }

  /** Documents the field [field] of type [type]. */
  void docField(Type type, FieldMember field) {
    _totalMembers++;
    _currentMember = field;

    writeln('<div class="field"><h4 id="${memberAnchor(field)}">');

    if (includeSource) {
      writeln('<span class="show-code">Code</span>');
    }

    if (field.isFinal) {
      write('final ');
    } else if (field.type.name == 'Dynamic') {
      write('var ');
    }

    annotateType(type, field.type);
    write(
        '''
        <strong>${field.name}</strong> <a class="anchor-link"
            href="#${memberAnchor(field)}"
            title="Permalink to ${typeName(type)}.${field.name}">#</a>
        </h4>
        ''');

    docCode(field.span, getFieldComment(field), showCode: true);
    writeln('</div>');
  }

  void docParamList(Type enclosingType, MethodMember member) {
    write('(');
    bool first = true;
    bool inOptionals = false;
    for (final parameter in member.parameters) {
      if (!first) write(', ');

      if (!inOptionals && parameter.isOptional) {
        write('[');
        inOptionals = true;
      }

      annotateType(enclosingType, parameter.type, parameter.name);

      // Show the default value for named optional parameters.
      if (parameter.isOptional && parameter.hasDefaultValue) {
        write(' = ');
        // TODO(rnystrom): Using the definition text here is a bit cheap.
        // We really should be pretty-printing the AST so that if you have:
        //   foo([arg = 1 + /* comment */ 2])
        // the docs should just show:
        //   foo([arg = 1 + 2])
        // For now, we'll assume you don't do that.
        write(parameter.definition.value.span.text);
      }

      first = false;
    }

    if (inOptionals) write(']');
    write(')');
  }

  /**
   * Documents the code contained within [span] with [comment]. If [showCode]
   * is `true` (and [includeSource] is set), also includes the source code.
   */
  void docCode(SourceSpan span, String comment, [bool showCode = false]) {
    writeln('<div class="doc">');
    if (comment != null) {
      writeln(comment);
    }

    if (includeSource && showCode) {
      writeln('<pre class="source">');
      writeln(md.escapeHtml(unindentCode(span)));
      writeln('</pre>');
    }

    writeln('</div>');
  }

  /** Get the doc comment associated with the given type. */
  String getTypeComment(Type type) {
    String comment = _comments.find(type.span);
    if (comment == null) return null;
    return commentToHtml(comment);
  }

  /** Get the doc comment associated with the given method. */
  String getMethodComment(MethodMember method) {
    String comment = _comments.find(method.span);
    if (comment == null) return null;
    return commentToHtml(comment);
  }

  /** Get the doc comment associated with the given field. */
  String getFieldComment(FieldMember field) {
    String comment = _comments.find(field.span);
    if (comment == null) return null;
    return commentToHtml(comment);
  }

  String commentToHtml(String comment) => md.markdownToHtml(comment);

  /**
   * Converts [fullPath] which is understood to be a full path from the root of
   * the generated docs to one relative to the current file.
   */
  String relativePath(String fullPath) {
    // Don't make it relative if it's an absolute path.
    if (isAbsolute(fullPath)) return fullPath;

    // TODO(rnystrom): Walks all the way up to root each time. Shouldn't do
    // this if the paths overlap.
    return repeat('../', countOccurrences(_filePath, '/')) + fullPath;
  }

  /** Gets whether or not the given URL is absolute or relative. */
  bool isAbsolute(String url) {
    // TODO(rnystrom): Why don't we have a nice type in the platform for this?
    // TODO(rnystrom): This is a bit hackish. We consider any URL that lacks
    // a scheme to be relative.
    return const RegExp(@'^\w+:').hasMatch(url);
  }

  /** Gets the URL to the documentation for [library]. */
  String libraryUrl(Library library) {
    return '${sanitize(library.name)}.html';
  }

  /** Gets the URL for the documentation for [type]. */
  String typeUrl(Type type) {
    if (type.isTop) return '${sanitize(type.library.name)}.html';
    // Always get the generic type to strip off any type parameters or
    // arguments. If the type isn't generic, genericType returns `this`, so it
    // works for non-generic types too.
    return '${sanitize(type.library.name)}/${type.genericType.name}.html';
  }

  /** Gets the URL for the documentation for [member]. */
  String memberUrl(Member member) {
    final typeUrl = typeUrl(member.declaringType);
    if (!member.isConstructor) return '$typeUrl#${member.name}';
    if (member.constructorName == '') return '$typeUrl#new:${member.name}';
    return '$typeUrl#new:${member.name}.${member.constructorName}';
  }

  /** Gets the anchor id for the document for [member]. */
  String memberAnchor(Member member) {
    return '${member.name}';
  }

  /**
   * Creates a hyperlink. Handles turning the [href] into an appropriate
   * relative path from the current file.
   */
  String a(String href, String contents, [String css]) {
    // Mark outgoing external links, mainly so we can style them.
    final rel = isAbsolute(href) ? ' ref="external"' : '';
    final cssClass = css == null ? '' : ' class="$css"';
    return '<a href="${relativePath(href)}"$cssClass$rel>$contents</a>';
  }

  /**
   * Writes a type annotation for the given type and (optional) parameter name.
   */
  annotateType(Type enclosingType, Type type, [String paramName = null]) {
    // Don't bother explicitly displaying Dynamic.
    if (type.isVar) {
      if (paramName !== null) write(paramName);
      return;
    }

    // For parameters, handle non-typedefed function types.
    if (paramName !== null) {
      final call = type.getCallMethod();
      if (call != null) {
        annotateType(enclosingType, call.returnType);
        write(paramName);

        docParamList(enclosingType, call);
        return;
      }
    }

    linkToType(enclosingType, type);

    write(' ');
    if (paramName !== null) write(paramName);
  }

  /** Writes a link to a human-friendly string representation for a type. */
  linkToType(Type enclosingType, Type type) {
    if (type is ParameterType) {
      // If we're using a type parameter within the body of a generic class then
      // just link back up to the class.
      write(a(typeUrl(enclosingType), type.name));
      return;
    }

    // Link to the type.
    // Use .genericType to avoid writing the <...> here.
    write(a(typeUrl(type), type.genericType.name));

    // See if it's a generic type.
    if (type.isGeneric) {
      // TODO(rnystrom): This relies on a weird corner case of frog. Currently,
      // the only time we get into this case is when we have a "raw" generic
      // that's been instantiated with Dynamic for all type arguments. It's kind
      // of strange that frog works that way, but we take advantage of it to
      // show raw types without any type arguments.
      return;
    }

    // See if it's an instantiation of a generic type.
    final typeArgs = type.typeArgsInOrder;
    if (typeArgs.length > 0) {
      write('&lt;');
      bool first = true;
      for (final arg in typeArgs) {
        if (!first) write(', ');
        first = false;
        linkToType(enclosingType, arg);
      }
      write('&gt;');
    }
  }

  /** Creates a linked cross reference to [type]. */
  typeReference(Type type) {
    // TODO(rnystrom): Do we need to handle ParameterTypes here like
    // annotation() does?
    return a(typeUrl(type), typeName(type), css: 'crossref');
  }

  /** Generates a human-friendly string representation for a type. */
  typeName(Type type, [bool showBounds = false]) {
    // See if it's a generic type.
    if (type.isGeneric) {
      final typeParams = [];
      for (final typeParam in type.genericType.typeParameters) {
        if (showBounds &&
            (typeParam.extendsType != null) &&
            !typeParam.extendsType.isObject) {
          final bound = typeName(typeParam.extendsType, showBounds: true);
          typeParams.add('${typeParam.name} extends $bound');
        } else {
          typeParams.add(typeParam.name);
        }
      }

      final params = Strings.join(typeParams, ', ');
      return '${type.name}&lt;$params&gt;';
    }

    // See if it's an instantiation of a generic type.
    final typeArgs = type.typeArgsInOrder;
    if (typeArgs.length > 0) {
      final args = Strings.join(map(typeArgs, (arg) => typeName(arg)), ', ');
      return '${type.genericType.name}&lt;$args&gt;';
    }

    // Regular type.
    return type.name;
  }

  /**
   * Remove leading indentation to line up with first line.
   */
  unindentCode(SourceSpan span) {
    final column = getSpanColumn(span);
    final lines = span.text.split('\n');
    // TODO(rnystrom): Dirty hack.
    for (var i = 1; i < lines.length; i++) {
      lines[i] = unindent(lines[i], column);
    }

    final code = Strings.join(lines, '\n');
    return code;
  }

  /**
   * Takes a string of Dart code and turns it into sanitized HTML.
   */
  formatCode(SourceSpan span) {
    final code = unindentCode(span);

    // Syntax highlight.
    return classifySource(new SourceFile('', code));
  }

  /**
   * This will be called whenever a doc comment hits a `[name]` in square
   * brackets. It will try to figure out what the name refers to and link or
   * style it appropriately.
   */
  md.Node resolveNameReference(String name, [Member member = null,
      Type type = null, Library library = null]) {
    makeLink(String href) {
      final anchor = new md.Element.text('a', name);
      anchor.attributes['href'] = relativePath(href);
      anchor.attributes['class'] = 'crossref';
      return anchor;
    }

    findMember(Type type, String memberName) {
      final member = type.members[memberName];
      if (member == null) return null;

      // Special case: if the member we've resolved is a property (i.e. it wraps
      // a getter and/or setter then *that* member itself won't be on the docs,
      // just the getter or setter will be. So pick one of those to link to.
      if (member.isProperty) {
        return member.canGet ? member.getter : member.setter;
      }

      return member;
    }

    // See if it's a parameter of the current method.
    if (member != null) {
      for (final parameter in member.parameters) {
        if (parameter.name == name) {
          final element = new md.Element.text('span', name);
          element.attributes['class'] = 'param';
          return element;
        }
      }
    }

    // See if it's another member of the current type.
    if (type != null) {
      final member = findMember(type, name);
      if (member != null) {
        return makeLink(memberUrl(member));
      }
    }

    // See if it's another type or a member of another type in the current
    // library.
    if (library != null) {
      // See if it's a constructor
      final constructorLink = (() {
        final match = new RegExp(@'new (\w+)(?:\.(\w+))?').firstMatch(name);
        if (match == null) return;
        final type = library.types[match[1]];
        if (type == null) return;
        final constructor = type.getConstructor(
            match[2] == null ? '' : match[2]);
        if (constructor == null) return;
        return makeLink(memberUrl(constructor));
      })();
      if (constructorLink != null) return constructorLink;

      // See if it's a member of another type
      final foreignMemberLink = (() {
        final match = new RegExp(@'(\w+)\.(\w+)').firstMatch(name);
        if (match == null) return;
        final type = library.types[match[1]];
        if (type == null) return;
        final member = findMember(type, match[2]);
        if (member == null) return;
        return makeLink(memberUrl(member));
      })();
      if (foreignMemberLink != null) return foreignMemberLink;

      final type = library.types[name];
      if (type != null) {
        return makeLink(typeUrl(type));
      }

      // See if it's a top-level member in the current library.
      final member = findMember(library.topType, name);
      if (member != null) {
        return makeLink(memberUrl(member));
      }
    }

    // TODO(rnystrom): Should also consider:
    // * Names imported by libraries this library imports.
    // * Type parameters of the enclosing type.

    return new md.Element.text('code', name);
  }

  // TODO(rnystrom): Move into SourceSpan?
  int getSpanColumn(SourceSpan span) {
    final line = span.file.getLine(span.start);
    return span.file.getColumn(line, span.start);
  }

  generateAppCacheManifest() {
    print('Generating app cache manifest from output $outputDir');
    startFile('appcache.manifest');
    write("CACHE MANIFEST\n\n");
    write("# VERSION: ${new Date.now()}\n\n");
    write("NETWORK:\n*\n\n");
    write("CACHE:\n");
    var toCache = new Directory(outputDir);
    var pathPrefix = new File(outputDir).fullPathSync();
    var pathPrefixLength = pathPrefix.length;
    toCache.onFile = (filename) {
      if (filename.endsWith('appcache.manifest')) {
        return;
      }
      var relativePath = filename.substring(pathPrefixLength + 1);
      write("$relativePath\n");
    };
    toCache.onDone = (done) => endFile();
    toCache.list(recursive: true);
  }
}
