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
#import('dart:math');
#import('dart:uri');
#import('dart:json');

// TODO(rnystrom): Use "package:" URL (#4968).
#import('mirrors.dart');
#import('mirrors_util.dart');
#import('src/mirrors/dart2js_mirror.dart', prefix: 'dart2js');
#import('classify.dart');
#import('markdown.dart', prefix: 'md');
#import('../../../lib/compiler/implementation/scanner/scannerlib.dart',
        prefix: 'dart2js');
#import('../../../lib/_internal/libraries.dart');

// TODO(rnystrom): Use "package:" URL (#4968).
#source('src/dartdoc/comment_map.dart');
#source('src/dartdoc/nav.dart');
#source('src/dartdoc/utils.dart');

/**
 * Generates completely static HTML containing everything you need to browse
 * the docs. The only client side behavior is trivial stuff like syntax
 * highlighting code.
 */
const MODE_STATIC = 0;

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
const MODE_LIVE_NAV = 1;

const API_LOCATION = 'http://api.dartlang.org/';

/**
 * Gets the full path to the directory containing the entrypoint of the current
 * script. In other words, if you invoked dartdoc, directly, it will be the
 * path to the directory containing `dartdoc.dart`. If you're running a script
 * that imports dartdoc, it will be the path to that script.
 */
// TODO(johnniwinther): Convert to final (lazily initialized) variables when
// the feature is supported.
Path get scriptDir =>
    new Path.fromNative(new Options().script).directoryPath;

/**
 * Deletes and recreates the output directory at [path] if it exists.
 */
void cleanOutputDirectory(Path path) {
  final outputDir = new Directory.fromPath(path);
  if (outputDir.existsSync()) {
    outputDir.deleteRecursivelySync();
  }

  try {
    // TODO(3914): Hack to avoid 'file already exists' exception thrown
    // due to invalid result from dir.existsSync() (probably due to race
    // conditions).
    outputDir.createSync();
  } on DirectoryIOException catch (e) {
    // Ignore.
  }
}

/**
 * Returns the display name of the library. This is necessary to account for
 * dart: libraries.
 */
String displayName(LibraryMirror library) {
  var uri = library.uri.toString();
  return uri.startsWith('dart:') ?  uri.toString() : library.simpleName;
}

/**
 * Copies all of the files in the directory [from] to [to]. Does *not*
 * recursively copy subdirectories.
 *
 * Note: runs asynchronously, so you won't see any files copied until after the
 * event loop has had a chance to pump (i.e. after `main()` has returned).
 */
Future copyDirectory(Path from, Path to) {
  final completer = new Completer();
  final fromDir = new Directory.fromPath(from);
  final lister = fromDir.list(recursive: false);

  lister.onFile = (String path) {
    final name = new Path.fromNative(path).filename;
    // TODO(rnystrom): Hackish. Ignore 'hidden' files like .DS_Store.
    if (name.startsWith('.')) return;

    File fromFile = new File(path);
    File toFile = new File.fromPath(to.append(name));
    fromFile.openInputStream().pipe(toFile.openOutputStream());
  };
  lister.onDone = (done) => completer.complete(true);
  return completer.future;
}

/**
 * Compiles the dartdoc client-side code to JavaScript using Dart2js.
 */
Future<bool> compileScript(int mode, Path outputDir, Path libPath) {
  var clientScript = (mode == MODE_STATIC) ? 'static' : 'live-nav';
  var dartPath = libPath.append(
      'pkg/dartdoc/lib/src/client/client-$clientScript.dart');
  var jsPath = outputDir.append('client-$clientScript.js');

  var completer = new Completer<bool>();
  var compilation = new Compilation(dartPath, libPath);
  Future<String> result = compilation.compileToJavaScript();
  result.then((jsCode) {
    writeString(new File.fromPath(jsPath), jsCode);
    completer.complete(true);
  });
  result.handleException((e) => completer.completeException(e));
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

  /** Path to the dartdoc directory. */
  Path dartdocPath;

  /** Path to generate HTML files into. */
  Path outputDir = new Path('docs');

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
  String footerText = null;

  /** Set this to add content before the footer */
  String preFooterText = '';

  /** Set this to omit generation timestamp from output */
  bool omitGenerationTime = false;

  /** Set by Dartdoc user to print extra information during generation. */
  bool verbose = false;

  /** Set this to include API libraries in the documentation. */
  bool includeApi = false;

  /** Set this to generate links to the online API. */
  bool linkToApi = false;

  /** Set this to generate docs for private types and members. */
  bool showPrivate = false;

  /** Set this to inherit from Object. */
  bool inheritFromObject = false;

  /** Set this to select the libraries to include in the documentation. */
  List<String> includedLibraries = const <String>[];

  /** Set this to select the libraries to exclude from the documentation. */
  List<String> excludedLibraries = const <String>[];

  /**
   * This list contains the libraries sorted in by the library name.
   */
  List<LibraryMirror> _sortedLibraries;

  CommentMap _comments;

  /** The library that we're currently generating docs for. */
  LibraryMirror _currentLibrary;

  /** The type that we're currently generating docs for. */
  InterfaceMirror _currentType;

  /** The member that we're currently generating docs for. */
  MemberMirror _currentMember;

  /** The path to the file currently being written to, relative to [outdir]. */
  Path _filePath;

  /** The file currently being written to. */
  StringBuffer _file;

  int _totalLibraries = 0;
  int _totalTypes = 0;
  int _totalMembers = 0;

  int get totalLibraries => _totalLibraries;
  int get totalTypes => _totalTypes;
  int get totalMembers => _totalMembers;

  Dartdoc()
      : _comments = new CommentMap() {
    // Patch in support for [:...:]-style code to the markdown parser.
    // TODO(rnystrom): Markdown already has syntax for this. Phase this out?
    md.InlineParser.syntaxes.insertRange(0, 1,
        new md.CodeSyntax(r'\[\:((?:.|\n)*?)\:\]'));

    md.setImplicitLinkResolver((name) => resolveNameReference(name,
            currentLibrary: _currentLibrary, currentType: _currentType,
            currentMember: _currentMember));
  }

  /**
   * Returns `true` if [library] is included in the generated documentation.
   */
  bool shouldIncludeLibrary(LibraryMirror library) {
    if (shouldLinkToPublicApi(library)) {
      return false;
    }
    var includeByDefault = true;
    String libraryName = displayName(library);
    if (excludedLibraries.contains(libraryName)) {
      return false;
    }
    if (!includedLibraries.isEmpty) {
      includeByDefault = false;
      if (includedLibraries.contains(libraryName)) {
        return true;
      }
    }
    if (libraryName.startsWith('dart:')) {
      String suffix = libraryName.substring('dart:'.length);
      LibraryInfo info = LIBRARIES[suffix];
      if (info != null) {
        return info.documented && includeApi;
      }
    }
    return includeByDefault;
  }

  /**
   * Returns `true` if links to the public API should be generated for
   * [library].
   */
  bool shouldLinkToPublicApi(LibraryMirror library) {
    if (linkToApi) {
      String libraryName = displayName(library);
      if (libraryName.startsWith('dart:')) {
        String suffix = libraryName.substring('dart:'.length);
        LibraryInfo info = LIBRARIES[suffix];
        if (info != null) {
          return info.documented;
        }
      }
    }
    return false;
  }

  String get footerContent{
    var footerItems = [];
    if (!omitGenerationTime) {
      footerItems.add("This page was generated at ${new Date.now()}");
    }
    if (footerText != null) {
      footerItems.add(footerText);
    }
    var content = '';
    for (int i = 0; i < footerItems.length; i++) {
      if (i > 0) {
        content = content.concat('\n');
      }
      content = content.concat('<div>${footerItems[i]}</div>');
    }
    return content;
  }

  void documentEntryPoint(Path entrypoint, Path libPath, Path pkgPath) {
    final compilation = new Compilation(entrypoint, libPath, pkgPath);
    _document(compilation);
  }

  void documentLibraries(List<Path> libraryList, Path libPath, Path pkgPath) {
    final compilation = new Compilation.library(libraryList, libPath, pkgPath);
    _document(compilation);
  }

  void _document(Compilation compilation) {
    // Sort the libraries by name (not key).
    _sortedLibraries = new List<LibraryMirror>.from(
        compilation.mirrors.libraries.values.filter(
            shouldIncludeLibrary));
    _sortedLibraries.sort((x, y) {
      return displayName(x).toUpperCase().compareTo(
          displayName(y).toUpperCase());
    });

    // Generate the docs.
    if (mode == MODE_LIVE_NAV) {
      docNavigationJson();
    } else {
      docNavigationDart();
    }

    docIndex();
    for (final library in _sortedLibraries) {
      docLibrary(library);
    }

    if (generateAppCache) {
      generateAppCacheManifest();
    }
  }

  void startFile(String path) {
    _filePath = new Path(path);
    _file = new StringBuffer();
  }

  void endFile() {
    final outPath = outputDir.join(_filePath);
    final dir = new Directory.fromPath(outPath.directoryPath);
    if (!dir.existsSync()) {
      // TODO(3914): Hack to avoid 'file already exists' exception
      // thrown due to invalid result from dir.existsSync() (probably due to
      // race conditions).
      try {
        dir.createSync();
      } on DirectoryIOException catch (e) {
        // Ignore.
      }
    }

    writeString(new File.fromPath(outPath), _file.toString());
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
      data = '$data data-library='
             '"${md.escapeHtml(displayName(_currentLibrary))}"';
    }

    if (_currentType != null) {
      data = '$data data-type="${md.escapeHtml(typeName(_currentType))}"';
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
              class="search-input" placeholder="Search API">
        </form>
        ''');
    } else {
      writeln(
        '''
        <div id="search-box">
          <input type="search" name="q" id="q" autocomplete="off"
              class="search-input" placeholder="Search API">
        </div>
        ''');
    }

    writeln(
      '''
      </div>
      <div class="drop-down" id="drop-down"></div>
      ''');

    docNavigation();
    writeln('<div class="content">');
  }

  String get clientScript {
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
        <div class="footer">
          $footerContent
        </div>
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

  void docIndexLibrary(LibraryMirror library) {
    writeln('<h4>${a(libraryUrl(library), displayName(library))}</h4>');
  }

  /**
   * Walks the libraries and creates a JSON object containing the data needed
   * to generate navigation for them.
   */
  void docNavigationJson() {
    startFile('nav.json');
    writeln(JSON.stringify(createNavigationInfo()));
    endFile();
  }

  void docNavigationDart() {
    final dir = new Directory.fromPath(tmpPath);
    if (!dir.existsSync()) {
      // TODO(3914): Hack to avoid 'file already exists' exception
      // thrown due to invalid result from dir.existsSync() (probably due to
      // race conditions).
      try {
        dir.createSync();
      } on DirectoryIOException catch (e) {
        // Ignore.
      }
    }
    String jsonString = JSON.stringify(createNavigationInfo());
    String dartString = jsonString.replaceAll(r"$", r"\$");
    final filePath = tmpPath.append('nav.dart');
    writeString(new File.fromPath(filePath),
        'get json => $dartString;');
  }

  Path get tmpPath => dartdocPath.append('tmp');

  void cleanup() {
    final dir = new Directory.fromPath(tmpPath);
    if (dir.existsSync()) {
      dir.deleteRecursivelySync();
    }
  }

  List createNavigationInfo() {
    final libraryList = [];
    for (final library in _sortedLibraries) {
      docLibraryNavigationJson(library, libraryList);
    }
    return libraryList;
  }

  void docLibraryNavigationJson(LibraryMirror library, List libraryList) {
    var libraryInfo = {};
    libraryInfo[NAME] = displayName(library);
    final List members = docMembersJson(library.declaredMembers);
    if (!members.isEmpty) {
      libraryInfo[MEMBERS] = members;
    }

    final types = [];
    for (InterfaceMirror type in orderByName(library.types.values)) {
      if (!showPrivate && type.isPrivate) continue;

      var typeInfo = {};
      typeInfo[NAME] = type.displayName;
      if (type.isClass) {
        typeInfo[KIND] = CLASS;
      } else if (type.isInterface) {
        typeInfo[KIND] = INTERFACE;
      } else {
        assert(type.isTypedef);
        typeInfo[KIND] = TYPEDEF;
      }
      final List typeMembers = docMembersJson(type.declaredMembers);
      if (!typeMembers.isEmpty) {
        typeInfo[MEMBERS] = typeMembers;
      }

      if (!type.declaration.typeVariables.isEmpty) {
        final typeVariables = [];
        for (final typeVariable in type.declaration.typeVariables) {
          typeVariables.add(typeVariable.displayName);
        }
        typeInfo[ARGS] = Strings.join(typeVariables, ', ');
      }
      types.add(typeInfo);
    }
    if (!types.isEmpty) {
      libraryInfo[TYPES] = types;
    }

    libraryList.add(libraryInfo);
  }

  List docMembersJson(Map<Object,MemberMirror> memberMap) {
    final members = [];
    for (MemberMirror member in orderByName(memberMap.values)) {
      if (!showPrivate && member.isPrivate) continue;

      var memberInfo = {};
      if (member.isField) {
        memberInfo[KIND] = FIELD;
      } else {
        MethodMirror method = member;
        if (method.isConstructor) {
          memberInfo[KIND] = CONSTRUCTOR;
        } else if (method.isSetter) {
          memberInfo[KIND] = SETTER;
        } else if (method.isGetter) {
          memberInfo[KIND] = GETTER;
        } else {
          memberInfo[KIND] = METHOD;
        }
        if (method.parameters.isEmpty) {
          memberInfo[NO_PARAMS] = true;
        }
      }
      memberInfo[NAME] = member.displayName;
      var anchor = memberAnchor(member);
      if (anchor != memberInfo[NAME]) {
        memberInfo[LINK_NAME] = anchor;
      }
      members.add(memberInfo);
    }
    return members;
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
          write('<strong>${displayName(library)}</strong>');
        } else {
          write('${a(libraryUrl(library), displayName(library))}');
        }
        write('</h2>');

        // Only expand classes in navigation for current library.
        if (_currentLibrary == library) docLibraryNavigation(library);
      }
    }

    writeln('</div>');
  }

  /** Writes the navigation for the types contained by the given library. */
  void docLibraryNavigation(LibraryMirror library) {
    // Show the exception types separately.
    final types = <InterfaceMirror>[];
    final exceptions = <InterfaceMirror>[];

    for (InterfaceMirror type in orderByName(library.types.values)) {
      if (!showPrivate && type.isPrivate) continue;

      if (isException(type)) {
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
  void docTypeNavigation(InterfaceMirror type) {
    var icon = 'interface';
    if (type.simpleName.endsWith('Exception')) {
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

  void docLibrary(LibraryMirror library) {
    if (verbose) {
      print('Library \'${displayName(library)}\':');
    }
    _totalLibraries++;
    _currentLibrary = library;
    _currentType = null;

    startFile(libraryUrl(library));
    writeHeader('${displayName(library)} Library',
        [displayName(library), libraryUrl(library)]);
    writeln('<h2><strong>${displayName(library)}</strong> library</h2>');

    // Look for a comment for the entire library.
    final comment = getLibraryComment(library);
    if (comment != null) {
      writeln('<div class="doc">${comment.html}</div>');
    }

    // Document the top-level members.
    docMembers(library);

    // Document the types.
    final classes = <InterfaceMirror>[];
    final interfaces = <InterfaceMirror>[];
    final typedefs = <TypedefMirror>[];
    final exceptions = <InterfaceMirror>[];

    for (InterfaceMirror type in orderByName(library.types.values)) {
      if (!showPrivate && type.isPrivate) continue;

      if (isException(type)) {
        exceptions.add(type);
      } else if (type.isClass) {
        classes.add(type);
      } else if (type.isInterface){
        interfaces.add(type);
      } else if (type is TypedefMirror) {
        typedefs.add(type);
      } else {
        throw new InternalError("internal error: unknown type $type.");
      }
    }

    docTypes(classes, 'Classes');
    docTypes(interfaces, 'Interfaces');
    docTypes(typedefs, 'Typedefs');
    docTypes(exceptions, 'Exceptions');

    writeFooter();
    endFile();

    for (final type in library.types.values) {
      if (!showPrivate && type.isPrivate) continue;

      docType(type);
    }
  }

  void docTypes(List types, String header) {
    if (types.length == 0) return;

    writeln('<div>');
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
    writeln('</div>');
  }

  void docType(InterfaceMirror type) {
    if (verbose) {
      print('- ${type.simpleName}');
    }
    _totalTypes++;
    _currentType = type;

    startFile(typeUrl(type));

    var kind = 'interface';
    if (type.isTypedef) {
      kind = 'typedef';
    } else if (type.isClass) {
      if (type.isAbstract) {
        kind = 'abstract class';
      } else {
        kind = 'class';
      }
    }

    final typeTitle =
      '${typeName(type)} ${kind}';
    writeHeader('$typeTitle / ${displayName(type.library)} Library',
        [displayName(type.library), libraryUrl(type.library),
         typeName(type), typeUrl(type)]);
    writeln(
        '''
        <h2><strong>${typeName(type, showBounds: true)}</strong>
          $kind
        </h2>
        ''');
    writeln('<button id="show-inherited" class="show-inherited">'
            'Hide inherited</button>');

    writeln('<div class="doc">');
    docComment(type, getTypeComment(type));
    docCode(type.location);
    writeln('</div>');

    docInheritance(type);
    docTypedef(type);

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
  void typeSpan(InterfaceMirror type) {
    var icon = 'interface';
    if (type.simpleName.endsWith('Exception')) {
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
  void docInheritance(InterfaceMirror type) {
    // Don't show the inheritance details for Object. It doesn't have any base
    // class (obviously) and it has too many subclasses to be useful.
    if (type.isObject) return;

    // Writes an unordered list of references to types with an optional header.
    listTypes(types, header) {
      if (types == null) return;

      var publicTypes;
      if (showPrivate) {
        publicTypes = types;
      } else {
        // Skip private types.
        publicTypes = new List.from(types.filter((t) => !t.isPrivate));
      }
      if (publicTypes.length == 0) return;

      writeln('<h3>$header</h3>');
      writeln('<p>');
      bool first = true;
      for (final t in publicTypes) {
        if (!first) write(', ');
        typeSpan(t);
        first = false;
      }
      writeln('</p>');
    }

    final subtypes = [];
    for (final subtype in computeSubdeclarations(type)) {
      subtypes.add(subtype);
    }
    subtypes.sort((x, y) => x.simpleName.compareTo(y.simpleName));
    if (type.isClass) {
      // Show the chain of superclasses.
      if (!type.superclass.isObject) {
        final supertypes = [];
        var thisType = type.superclass;
        // As a sanity check, only show up to five levels of nesting, otherwise
        // the box starts to get hideous.
        do {
          supertypes.add(thisType);
          thisType = thisType.superclass;
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

      listTypes(subtypes, 'Subclasses');
      listTypes(type.interfaces, 'Implements');
    } else {
      // Show the default class.
      if (type.defaultType != null) {
        listTypes([type.defaultType], 'Default class');
      }

      // List extended interfaces.
      listTypes(type.interfaces, 'Extends');

      // List subinterfaces and implementing classes.
      final subinterfaces = [];
      final implementing = [];

      for (final subtype in subtypes) {
        if (subtype.isClass) {
          implementing.add(subtype);
        } else {
          subinterfaces.add(subtype);
        }
      }

      listTypes(subinterfaces, 'Subinterfaces');
      listTypes(implementing, 'Implemented by');
    }
  }

  /**
   * Documents the definition of [type] if it is a typedef.
   */
  void docTypedef(TypeMirror type) {
    if (type is! TypedefMirror) {
      return;
    }
    writeln('<div class="method"><h4 id="${type.simpleName}">');

    if (includeSource) {
      writeln('<button class="show-code">Code</button>');
    }

    write('typedef ');
    annotateType(type, type.definition, type.simpleName);

    write(''' <a class="anchor-link" href="#${type.simpleName}"
              title="Permalink to ${type.simpleName}">#</a>''');
    writeln('</h4>');

    writeln('<div class="doc">');
    docCode(type.location);
    writeln('</div>');

    writeln('</div>');
  }

  static const operatorOrder = const <String>[
      '[]', '[]=', // Indexing.
      '+', Mirror.UNARY_MINUS, '-', '*', '/', '~/', '%', // Arithmetic.
      '&', '|', '^', '~', // Bitwise.
      '<<', '>>', // Shift.
      '<', '<=', '>', '>=', // Relational.
      '==', // Equality.
  ];

  static final Map<String, int> operatorOrderMap = (){
    var map = new Map<String, int>();
    var index = 0;
    for (String operator in operatorOrder) {
      map[operator] = index++;
    }
    return map;
  }();

  void docMembers(ObjectMirror host) {
    // Collect the different kinds of members.
    final staticMethods = [];
    final staticGetters = new Map<String,MemberMirror>();
    final staticSetters = new Map<String,MemberMirror>();
    final memberMap = new Map<String,MemberMirror>();
    final instanceMethods = [];
    final instanceOperators = [];
    final instanceGetters = new Map<String,MemberMirror>();
    final instanceSetters = new Map<String,MemberMirror>();
    final constructors = [];

    host.declaredMembers.forEach((_, MemberMirror member) {
      if (!showPrivate && member.isPrivate) return;
      if (host is LibraryMirror || member.isStatic) {
        if (member is MethodMirror) {
          if (member.isGetter) {
            staticGetters[member.displayName] = member;
          } else if (member.isSetter) {
            staticSetters[member.displayName] = member;
          } else {
            staticMethods.add(member);
          }
        } else if (member is FieldMirror) {
          staticGetters[member.displayName] = member;
        }
      }
    });

    if (host is InterfaceMirror) {
      var iterable = new HierarchyIterable(host, includeType: true);
      for (InterfaceMirror type in iterable) {
        if (!host.isObject && !inheritFromObject && type.isObject) continue;

        type.declaredMembers.forEach((_, MemberMirror member) {
          if (member.isStatic) return;
          if (!showPrivate && member.isPrivate) return;

          bool inherit = true;
          if (type !== host) {
            if (member.isPrivate) {
              // Don't inherit private members.
              inherit = false;
            }
            if (member.isConstructor) {
              // Don't inherit constructors.
              inherit = false;
            }
          }
          if (!inherit) return;

          if (member.isField) {
            // Fields override both getters and setters.
            memberMap.putIfAbsent(member.simpleName, () => member);
            memberMap.putIfAbsent('${member.simpleName}=', () => member);
          } else if (member.isConstructor) {
            constructors.add(member);
          } else {
            memberMap.putIfAbsent(member.simpleName, () => member);
          }
        });
      }
    }

    bool allMethodsInherited = true;
    bool allPropertiesInherited = true;
    bool allOperatorsInherited = true;
    memberMap.forEach((_, MemberMirror member) {
      if (member is MethodMirror) {
        if (member.isGetter) {
          instanceGetters[member.displayName] = member;
          if (member.surroundingDeclaration == host) {
            allPropertiesInherited = false;
          }
        } else if (member.isSetter) {
          instanceSetters[member.displayName] = member;
          if (member.surroundingDeclaration == host) {
            allPropertiesInherited = false;
          }
        } else if (member.isOperator) {
          instanceOperators.add(member);
          if (member.surroundingDeclaration == host) {
            allOperatorsInherited = false;
          }
        } else {
          instanceMethods.add(member);
          if (member.surroundingDeclaration == host) {
            allMethodsInherited = false;
          }
        }
      } else if (member is FieldMirror) {
        instanceGetters[member.displayName] = member;
        if (member.surroundingDeclaration == host) {
          allPropertiesInherited = false;
        }
      }
    });

    instanceOperators.sort((MethodMirror a, MethodMirror b) {
      return operatorOrderMap[a.simpleName].compareTo(
          operatorOrderMap[b.simpleName]);
    });

    docProperties(host,
                  host is LibraryMirror ? 'Properties' : 'Static Properties',
                  staticGetters, staticSetters, allInherited: false);
    docMethods(host,
               host is LibraryMirror ? 'Functions' : 'Static Methods',
               staticMethods, allInherited: false);

    docMethods(host, 'Constructors', orderByName(constructors),
               allInherited: false);
    docProperties(host, 'Properties', instanceGetters, instanceSetters,
                  allInherited: allPropertiesInherited);
    docMethods(host, 'Operators', instanceOperators,
               allInherited: allOperatorsInherited);
    docMethods(host, 'Methods', orderByName(instanceMethods),
               allInherited: allMethodsInherited);
  }

  /**
   * Documents fields, getters, and setters as properties.
   */
  void docProperties(ObjectMirror host, String title,
                     Map<String,MemberMirror> getters,
                     Map<String,MemberMirror> setters,
                     {bool allInherited}) {
    if (getters.isEmpty && setters.isEmpty) return;

    var nameSet = new Set<String>.from(getters.keys);
    nameSet.addAll(setters.keys);
    var nameList = new List<String>.from(nameSet);
    nameList.sort((String a, String b) {
      return a.toLowerCase().compareTo(b.toLowerCase());
    });

    writeln('<div${allInherited ? ' class="inherited"' : ''}>');
    writeln('<h3>$title</h3>');
    for (String name in nameList) {
      MemberMirror getter = getters[name];
      MemberMirror setter = setters[name];
      if (setter == null) {
        if (getter is FieldMirror) {
          // We have a field.
          docField(host, getter);
        } else {
          // We only have a getter.
          assert(getter is MethodMirror);
          docProperty(host, getter, null);
        }
      } else if (getter == null) {
        // We only have a setter => Document as a method.
        assert(setter is MethodMirror);
        docMethod(host, setter);
      } else {
        DocComment getterComment = getMemberComment(getter);
        DocComment setterComment = getMemberComment(setter);
        if (getter.surroundingDeclaration !== setter.surroundingDeclaration ||
            getterComment != null && setterComment != null) {
          // Both have comments or are not declared in the same class
          // => Documents separately.
          if (getter is FieldMirror) {
            // Document field as a getter (setter is inherited).
            docField(host, getter, asGetter: true);
          } else {
            docMethod(host, getter);
          }
          if (setter is FieldMirror) {
            // Document field as a setter (getter is inherited).
            docField(host, setter, asSetter: true);
          } else {
            docMethod(host, setter);
          }
        } else {
          // Document as field.
          docProperty(host, getter, setter);
        }
      }
    }
    writeln('</div>');
  }

  void docMethods(ObjectMirror host, String title, List<MethodMirror> methods,
                  {bool allInherited}) {
    if (methods.length > 0) {
      writeln('<div${allInherited ? ' class="inherited"' : ''}>');
      writeln('<h3>$title</h3>');
      for (final method in methods) {
        docMethod(host, method);
      }
      writeln('</div>');
    }
  }

  /**
   * Documents the [member] declared in [host]. Handles all kinds of members
   * including getters, setters, and constructors. If [member] is a
   * [FieldMirror] it is documented as a getter or setter depending upon the
   * value of [asGetter].
   */
  void docMethod(ObjectMirror host, MemberMirror member,
                 {bool asGetter: false}) {
    _totalMembers++;
    _currentMember = member;

    bool isAbstract = false;
    String name = member.displayName;
    if (member is FieldMirror) {
      if (asGetter) {
        // Getter.
        name = 'get $name';
      } else {
        // Setter.
        name = 'set $name';
      }
    } else {
      assert(member is MethodMirror);
      isAbstract = member.isAbstract;
      if (member.isGetter) {
        // Getter.
        name = 'get $name';
      } else if (member.isSetter) {
        // Setter.
        name = 'set $name';
      }
    }

    bool showCode = includeSource && !isAbstract;
    bool inherited = host != member.surroundingDeclaration;

    writeln('<div class="method${inherited ? ' inherited': ''}">'
            '<h4 id="${memberAnchor(member)}">');

    if (showCode) {
      writeln('<button class="show-code">Code</button>');
    }

    if (member is MethodMirror) {
      if (member.isConstructor) {
        if (member.isFactory) {
          write('factory ');
        } else {
          write(member.isConst ? 'const ' : 'new ');
        }
      } else if (member.isAbstract) {
        write('abstract ');
      }

      if (!member.isConstructor) {
        annotateType(host, member.returnType);
      }
    } else {
      assert(member is FieldMirror);
      if (asGetter) {
        annotateType(host, member.type);
      } else {
        write('void ');
      }
    }

    write('<strong>$name</strong>');

    if (member is MethodMirror) {
      if (!member.isGetter) {
        docParamList(host, member.parameters);
      }
    } else {
      assert(member is FieldMirror);
      if (!asGetter) {
        write('(');
        annotateType(host, member.type);
        write(' value)');
      }
    }

    var prefix = host is LibraryMirror ? '' : '${typeName(host)}.';
    write(''' <a class="anchor-link" href="#${memberAnchor(member)}"
              title="Permalink to $prefix$name">#</a>''');
    writeln('</h4>');

    if (inherited) {
      write('<div class="inherited-from">inherited from ');
      annotateType(host, member.surroundingDeclaration);
      write('</div>');
    }

    writeln('<div class="doc">');
    docComment(host, getMemberComment(member));
    if (showCode) {
      docCode(member.location);
    }
    writeln('</div>');

    writeln('</div>');
  }

  void docField(ObjectMirror host, FieldMirror field,
                {bool asGetter: false, bool asSetter: false}) {
    if (asGetter) {
      docMethod(host, field, asGetter: true);
    } else if (asSetter) {
      docMethod(host, field, asGetter: false);
    } else {
      docProperty(host, field, null);
    }
  }

  /**
   * Documents the property defined by [getter] and [setter] of declared in
   * [host]. If [getter] is a [FieldMirror], [setter] must be [:null:].
   * Otherwise, if [getter] is a [MethodMirror], the property is considered
   * final if [setter] is [:null:].
   */
  void docProperty(ObjectMirror host,
                   MemberMirror getter, MemberMirror setter) {
    assert(getter != null);
    _totalMembers++;
    _currentMember = getter;

    bool inherited = host != getter.surroundingDeclaration;

    writeln('<div class="field${inherited ? ' inherited' : ''}">'
            '<h4 id="${memberAnchor(getter)}">');

    if (includeSource) {
      writeln('<button class="show-code">Code</button>');
    }

    bool isConst = false;
    bool isFinal;
    TypeMirror type;
    if (getter is FieldMirror) {
      assert(setter == null);
      isConst = getter.isConst;
      isFinal = getter.isFinal;
      type = getter.type;
    } else {
      assert(getter is MethodMirror);
      isFinal = setter == null;
      type = getter.returnType;
    }

    if (isConst) {
      write('const ');
    } else if (isFinal) {
      write('final ');
    } else if (type.isDynamic) {
      write('var ');
    }

    annotateType(host, type);
    var prefix = host is LibraryMirror ? '' : '${typeName(host)}.';
    write(
        '''
        <strong>${getter.simpleName}</strong> <a class="anchor-link"
            href="#${memberAnchor(getter)}"
            title="Permalink to $prefix${getter.simpleName}">#</a>
        </h4>
        ''');

    if (inherited) {
      write('<div class="inherited-from">inherited from ');
      annotateType(host, getter.surroundingDeclaration);
      write('</div>');
    }

    DocComment comment = getMemberComment(getter);
    if (comment == null && setter != null) {
      comment = getMemberComment(setter);
    }
    writeln('<div class="doc">');
    docComment(host, comment);
    docCode(getter.location);
    if (setter != null) {
      docCode(setter.location);
    }
    writeln('</div>');

    writeln('</div>');
  }

  void docParamList(ObjectMirror enclosingType,
                    List<ParameterMirror> parameters) {
    write('(');
    bool first = true;
    bool inOptionals = false;
    for (final parameter in parameters) {
      if (!first) write(', ');

      if (!inOptionals && parameter.isOptional) {
        write('[');
        inOptionals = true;
      }

      annotateType(enclosingType, parameter.type, parameter.simpleName);

      // Show the default value for named optional parameters.
      if (parameter.isOptional && parameter.hasDefaultValue) {
        write(' = ');
        write(parameter.defaultValue);
      }

      first = false;
    }

    if (inOptionals) write(']');
    write(')');
  }

  void docComment(ObjectMirror host, DocComment comment) {
    if (comment != null) {
      if (comment.inheritedFrom !== null) {
        writeln('<div class="inherited">');
        writeln(comment.html);
        write('<div class="docs-inherited-from">docs inherited from ');
        annotateType(host, comment.inheritedFrom);
        write('</div>');
        writeln('</div>');
      } else {
        writeln(comment.html);
      }
    }
  }

  /**
   * Documents the source code contained within [location].
   */
  void docCode(Location location) {
    if (includeSource) {
      writeln('<pre class="source">');
      writeln(md.escapeHtml(unindentCode(location)));
      writeln('</pre>');
    }
  }

  DocComment createDocComment(String text, [InterfaceMirror inheritedFrom]) =>
      new DocComment(text, inheritedFrom);


  /** Get the doc comment associated with the given library. */
  DocComment getLibraryComment(LibraryMirror library) {
    // Look for a comment for the entire library.
    final comment = _comments.findLibrary(library.location.source);
    if (comment == null) return null;
    return createDocComment(comment);
  }

  /** Get the doc comment associated with the given type. */
  DocComment getTypeComment(TypeMirror type) {
    String comment = _comments.find(type.location);
    if (comment == null) return null;
    return createDocComment(comment);
  }

  /**
   * Get the doc comment associated with the given member.
   *
   * If no comment was found on the member, the hierarchy is traversed to find
   * an inherited comment, favouring comments inherited from classes over
   * comments inherited from interfaces.
   */
  DocComment getMemberComment(MemberMirror member) {
    String comment = _comments.find(member.location);
    InterfaceMirror inheritedFrom = null;
    if (comment == null) {
      if (member.surroundingDeclaration is InterfaceMirror) {
        var iterable =
            new HierarchyIterable(member.surroundingDeclaration,
                                  includeType: false);
        for (InterfaceMirror type in iterable) {
          var inheritedMember = type.declaredMembers[member.simpleName];
          if (inheritedMember is MemberMirror) {
            comment = _comments.find(inheritedMember.location);
            if (comment != null) {
              inheritedFrom = type;
              break;
            }
          }
        }
      }
    }
    if (comment == null) return null;
    return createDocComment(comment, inheritedFrom);
  }

  /**
   * Converts [fullPath] which is understood to be a full path from the root of
   * the generated docs to one relative to the current file.
   */
  String relativePath(String fullPath) {
    // Don't make it relative if it's an absolute path.
    if (isAbsolute(fullPath)) return fullPath;

    // TODO(rnystrom): Walks all the way up to root each time. Shouldn't do
    // this if the paths overlap.
    return '${repeat('../',
                     countOccurrences(_filePath.toString(), '/'))}$fullPath';
  }

  /** Gets whether or not the given URL is absolute or relative. */
  bool isAbsolute(String url) {
    // TODO(rnystrom): Why don't we have a nice type in the platform for this?
    // TODO(rnystrom): This is a bit hackish. We consider any URL that lacks
    // a scheme to be relative.
    return const RegExp(r'^\w+:').hasMatch(url);
  }

  /** Gets the URL to the documentation for [library]. */
  String libraryUrl(LibraryMirror library) {
    return '${sanitize(displayName(library))}.html';
  }

  /** Gets the URL for the documentation for [type]. */
  String typeUrl(ObjectMirror type) {
    if (type is LibraryMirror) {
      return '${sanitize(type.simpleName)}.html';
    }
    assert (type is TypeMirror);
    // Always get the generic type to strip off any type parameters or
    // arguments. If the type isn't generic, genericType returns `this`, so it
    // works for non-generic types too.
    return '${sanitize(displayName(type.library))}/'
           '${type.declaration.simpleName}.html';
  }

  /** Gets the URL for the documentation for [member]. */
  String memberUrl(MemberMirror member) {
    String url = typeUrl(member.surroundingDeclaration);
    return '$url#${memberAnchor(member)}';
  }

  /** Gets the anchor id for the document for [member]. */
  String memberAnchor(MemberMirror member) {
    return member.simpleName;
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
  annotateType(ObjectMirror enclosingType,
               TypeMirror type,
               [String paramName = null]) {
    // Don't bother explicitly displaying Dynamic.
    if (type.isDynamic) {
      if (paramName !== null) write(paramName);
      return;
    }

    // For parameters, handle non-typedefed function types.
    if (paramName !== null && type is FunctionTypeMirror) {
      annotateType(enclosingType, type.returnType);
      write(paramName);

      docParamList(enclosingType, type.parameters);
      return;
    }

    linkToType(enclosingType, type);

    write(' ');
    if (paramName !== null) write(paramName);
  }

  /** Writes a link to a human-friendly string representation for a type. */
  linkToType(ObjectMirror enclosingType, TypeMirror type) {
    if (type.isVoid) {
      // Do not generate links for void.
      // TODO(johnniwinter): Generate span for specific style?
      write('void');
      return;
    }
    if (type.isDynamic) {
      // Do not generate links for Dynamic.
      write('Dynamic');
      return;
    }

    if (type.isTypeVariable) {
      // If we're using a type parameter within the body of a generic class then
      // just link back up to the class.
      write(a(typeUrl(enclosingType), type.simpleName));
      return;
    }

    assert(type is InterfaceMirror);

    // Link to the type.
    if (shouldLinkToPublicApi(type.library)) {
      write('<a href="$API_LOCATION${typeUrl(type)}">${type.simpleName}</a>');
    } else if (shouldIncludeLibrary(type.library)) {
      write(a(typeUrl(type), type.simpleName));
    } else {
      write(type.simpleName);
    }

    if (type.isDeclaration) {
      // Avoid calling [:typeArguments():] on a declaration.
      return;
    }

    // See if it's an instantiation of a generic type.
    final typeArgs = type.typeArguments;
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
  typeReference(InterfaceMirror type) {
    // TODO(rnystrom): Do we need to handle ParameterTypes here like
    // annotation() does?
    return a(typeUrl(type), typeName(type), css: 'crossref');
  }

  /** Generates a human-friendly string representation for a type. */
  typeName(TypeMirror type, {bool showBounds: false}) {
    if (type.isVoid) {
      return 'void';
    }
    if (type is TypeVariableMirror) {
      return type.simpleName;
    }
    assert(type is InterfaceMirror);

    // See if it's a generic type.
    if (type.isDeclaration) {
      final typeParams = [];
      for (final typeParam in type.declaration.typeVariables) {
        if (showBounds &&
            (typeParam.bound != null) &&
            !typeParam.bound.isObject) {
          final bound = typeName(typeParam.bound, showBounds: true);
          typeParams.add('${typeParam.simpleName} extends $bound');
        } else {
          typeParams.add(typeParam.simpleName);
        }
      }
      if (typeParams.isEmpty) {
        return type.simpleName;
      }
      final params = Strings.join(typeParams, ', ');
      return '${type.simpleName}&lt;$params&gt;';
    }

    // See if it's an instantiation of a generic type.
    final typeArgs = type.typeArguments;
    if (typeArgs.length > 0) {
      final args = Strings.join(typeArgs.map((arg) => typeName(arg)), ', ');
      return '${type.declaration.simpleName}&lt;$args&gt;';
    }

    // Regular type.
    return type.simpleName;
  }

  /**
   * Remove leading indentation to line up with first line.
   */
  unindentCode(Location span) {
    final column = getLocationColumn(span);
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
  formatCode(Location span) {
    final code = unindentCode(span);

    // Syntax highlight.
    return classifySource(code);
  }

  /**
   * This will be called whenever a doc comment hits a `[name]` in square
   * brackets. It will try to figure out what the name refers to and link or
   * style it appropriately.
   */
  md.Node resolveNameReference(String name,
                               {MemberMirror currentMember,
                                ObjectMirror currentType,
                                LibraryMirror currentLibrary}) {
    makeLink(String href) {
      final anchor = new md.Element.text('a', name);
      anchor.attributes['href'] = relativePath(href);
      anchor.attributes['class'] = 'crossref';
      return anchor;
    }

    // See if it's a parameter of the current method.
    if (currentMember is MethodMirror) {
      for (final parameter in currentMember.parameters) {
        if (parameter.simpleName == name) {
          final element = new md.Element.text('span', name);
          element.attributes['class'] = 'param';
          return element;
        }
      }
    }

    // See if it's another member of the current type.
    if (currentType != null) {
      final foundMember = currentType.declaredMembers[name];
      if (foundMember != null) {
        return makeLink(memberUrl(foundMember));
      }
    }

    // See if it's another type or a member of another type in the current
    // library.
    if (currentLibrary != null) {
      // See if it's a constructor
      final constructorLink = (() {
        final match =
            new RegExp(r'new ([\w$]+)(?:\.([\w$]+))?').firstMatch(name);
        if (match == null) return;
        String typeName = match[1];
        InterfaceMirror foundtype = currentLibrary.types[typeName];
        if (foundtype == null) return;
        String constructorName =
            (match[2] == null) ? typeName : '$typeName.${match[2]}';
        final constructor =
            foundtype.constructors[constructorName];
        if (constructor == null) return;
        return makeLink(memberUrl(constructor));
      })();
      if (constructorLink != null) return constructorLink;

      // See if it's a member of another type
      final foreignMemberLink = (() {
        final match = new RegExp(r'([\w$]+)\.([\w$]+)').firstMatch(name);
        if (match == null) return;
        InterfaceMirror foundtype = currentLibrary.types[match[1]];
        if (foundtype == null) return;
        MemberMirror foundMember = foundtype.declaredMembers[match[2]];
        if (foundMember == null) return;
        return makeLink(memberUrl(foundMember));
      })();
      if (foreignMemberLink != null) return foreignMemberLink;

      InterfaceMirror foundType = currentLibrary.types[name];
      if (foundType != null) {
        return makeLink(typeUrl(foundType));
      }

      // See if it's a top-level member in the current library.
      MemberMirror foundMember = currentLibrary.declaredMembers[name];
      if (foundMember != null) {
        return makeLink(memberUrl(foundMember));
      }
    }

    // TODO(rnystrom): Should also consider:
    // * Names imported by libraries this library imports.
    // * Type parameters of the enclosing type.

    return new md.Element.text('code', name);
  }

  generateAppCacheManifest() {
    if (verbose) {
      print('Generating app cache manifest from output $outputDir');
    }
    startFile('appcache.manifest');
    write("CACHE MANIFEST\n\n");
    write("# VERSION: ${new Date.now()}\n\n");
    write("NETWORK:\n*\n\n");
    write("CACHE:\n");
    var toCache = new Directory.fromPath(outputDir);
    var toCacheLister = toCache.list(recursive: true);
    toCacheLister.onFile = (filename) {
      if (filename.endsWith('appcache.manifest')) {
        return;
      }
      // TODO(johnniwinther): If [outputDir] has trailing slashes, [filename]
      // contains double (back)slashes for files in the immediate [toCache]
      // directory. These are not handled by [relativeTo] thus
      // wrongfully producing the path `/foo.html` for a file `foo.html` in
      // [toCache].
      //
      // This can be handled in two ways. 1) By ensuring that
      // [Directory.fromPath] does not receive a path with a trailing slash, or
      // better, by making [Directory.fromPath] handle such trailing slashes.
      // 2) By ensuring that [filePath] does not have double slashes before
      // calling [relativeTo], or better, by making [relativeTo] handle double
      // slashes correctly.
      Path filePath = new Path.fromNative(filename).canonicalize();
      Path relativeFilePath = filePath.relativeTo(outputDir);
      write("$relativeFilePath\n");
    };
    toCacheLister.onDone = (done) => endFile();
  }

  /**
   * Returns [:true:] if [type] should be regarded as an exception.
   */
  bool isException(TypeMirror type) {
    return type.simpleName.endsWith('Exception');
  }
}

/**
 * Used to report an unexpected error in the DartDoc tool or the
 * underlying data
 */
class InternalError {
  final String message;
  const InternalError(this.message);
  String toString() => "InternalError: '$message'";
}

class DocComment {
  final String text;

  /**
   * Non-null if the comment is inherited from another declaration.
   */
  final InterfaceMirror inheritedFrom;

  DocComment(this.text, [this.inheritedFrom = null]) {
    assert(text != null && !text.trim().isEmpty);
  }

  String get html => md.markdownToHtml(text);

  String toString() => text;
}
