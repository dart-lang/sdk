// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
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
library dartdoc;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:path/path.dart' as path;

import 'classify.dart';
import 'markdown.dart' as md;
import 'universe_serializer.dart';

import 'src/dartdoc/nav.dart';
import 'src/dartdoc/utils.dart';
import 'src/export_map.dart';
import 'src/json_serializer.dart' as json_serializer;

// TODO(rnystrom): Use "package:" URL (#4968).
import 'src/dart2js_mirrors.dart' as dart2js;
import '../../compiler/implementation/mirrors/mirrors.dart';
import '../../compiler/implementation/mirrors/mirrors_util.dart';
import '../../libraries.dart';

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
String get scriptDir => path.dirname(Platform.script.toFilePath());

/**
 * Deletes and recreates the output directory at [path] if it exists.
 */
void cleanOutputDirectory(String path) {
  final outputDir = new Directory(path);
  if (outputDir.existsSync()) {
    outputDir.deleteSync(recursive: true);
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
Future copyDirectory(String from, String to) {
  print('Copying static files...');
  final completer = new Completer();
  final fromDir = new Directory(from);
  var futureList = [];
  fromDir.list(recursive: false).listen(
      (FileSystemEntity entity) {
        if (entity is File) {
          final name = path.basename(entity.path);
          // TODO(rnystrom): Hackish. Ignore 'hidden' files like .DS_Store.
          if (name.startsWith('.')) return;

          File fromFile = entity;
          File toFile = new File(path.join(to, name));
          futureList.add(fromFile.openRead().pipe(toFile.openWrite()));
        }
      },
      onDone: () => Future.wait(futureList).then((_) => completer.complete()),
      onError: completer.completeError);
  return completer.future;
}

/**
 * Compiles the dartdoc client-side code to JavaScript using Dart2js.
 */
Future compileScript(int mode, String outputDir, String libPath, String tmpPath) {
  print('Compiling client JavaScript...');
  var clientScript = (mode == MODE_STATIC) ?  'static' : 'live-nav';
  var dartdocLibPath = path.join(libPath, 'lib', '_internal', 'dartdoc', 'lib');
  var dartPath = mode == MODE_STATIC ?
    path.join(tmpPath, 'client.dart') :
    path.join(dartdocLibPath, 'src', 'client', 'client-live-nav.dart');

  var jsPath = path.join(outputDir, 'client-$clientScript.js');

  // dart2js takes a String, but it expects that to be a Uri, not a file
  // system path.
  libPath = path.toUri(libPath).toString();
  dartPath = path.toUri(dartPath).toString();

  return dart2js.compile(
      dartPath, libPath,
      options: const <String>['--categories=Client,Server', '--minify'])
  .then((jsCode) {
    if (jsCode == null) throw new StateError("No javascript was generated.");
    writeString(new File(jsPath), jsCode);
  });
}

/**
 * Package manifest containing all information required to render the main page
 * for a package.
 *
 * The manifest specifies where to load the [LibraryElement]s describing each
 * library rather than including them directly.
 * For our purposes we treat the core Dart libraries as a package.
 */
class PackageManifest {
  /** Package name. */
  final name;
  /** Package description */
  final description;
  /** Libraries contained in this package. */
  final List<Reference> libraries = <Reference>[];
  /**
   * Descriptive string describing the version# of the package.
   *
   * The current format for dart-sdk versions is
   * $MAJOR.$MINOR.$BUILD.$PATCH$revisionString$userNameString
   * For example: 0.1.2.0_r18233_johndoe
   */
  final String fullVersion;
  /**
   * Source control revision number for the package. For SVN this is a number
   * while for GIT it is a hash.
   */
  final String revision;
  /**
   * Path to the directory containing data files for each library.
   *
   * Currently this is the serialized json version of the LibraryElement for
   * the library.
   */
  String location;
  /**
   * Packages depended on by this package.
   * We currently store the entire manifest for the depency here the manifests
   * are small.  We may want to change this to a reference in the future.
   */
  final List<PackageManifest> dependencies = <PackageManifest>[];

  PackageManifest(this.name, this.description, this.fullVersion, this.revision);
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
  String dartdocPath;

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
  String footerText = null;

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

  /** Version of the sdk or package docs are being generated for. */
  String version;

  /** Set this to select the libraries to include in the documentation. */
  List<String> includedLibraries = const <String>[];

  /** Set this to select the libraries to exclude from the documentation. */
  List<String> excludedLibraries = const <String>[];

  /** The package root for `package:` imports. */
  String _packageRoot;

  /** The map containing all the exports for each library. */
  ExportMap _exports;

  /** The path to a temporary directory used by Dartdoc. */
  String tmpPath;

  /**
   * This list contains the libraries sorted in by the library name.
   */
  List<LibraryMirror> _sortedLibraries;

  /** A map from absolute paths of libraries to the libraries at those paths. */
  Map<String, LibraryMirror> _librariesByPath;

  /**
   * A map from absolute paths of hidden libraries to lists of [Export]s that
   * export those libraries from visible libraries. This is used to determine
   * what public library any given entity belongs to.
   *
   * The lists of exports are sorted so that exports that hide the fewest number
   * of members come first.
   */
  Map<String, List<Export>> _hiddenLibraryExports;

  /** The library that we're currently generating docs for. */
  LibraryMirror _currentLibrary;

  /** The type that we're currently generating docs for. */
  ClassMirror _currentType;

  /** The member that we're currently generating docs for. */
  MemberMirror _currentMember;

  /** The path to the file currently being written to, relative to [outdir]. */
  String _filePath;

  /** The file currently being written to. */
  StringBuffer _file;

  int _totalLibraries = 0;
  int _totalTypes = 0;
  int _totalMembers = 0;

  int get totalLibraries => _totalLibraries;
  int get totalTypes => _totalTypes;
  int get totalMembers => _totalMembers;

  // Check if the compilation has started and finished.
  bool _started = false;
  bool _finished = false;

  /**
   * Prints the status of dartdoc.
   *
   * Prints whether dartdoc is running, whether dartdoc has finished
   * succesfully or not, and how many libraries, types, and members were
   * documented.
   */
  String get status {
    // TODO(amouravski): Make this more full featured and remove all other
    // prints and put them under verbose flag.
    if (!_started) {
      return 'Documentation has not yet started.';
    } else if (!_finished) {
      return 'Documentation in progress -- documented $_statisticsSummary so far.';
    } else {
      if (totals == 0) {
        return 'Documentation complete -- warning: nothing was documented!';
      } else {
        return 'Documentation complete -- documented $_statisticsSummary.';
      }
    }
  }

  int get totals => totalLibraries + totalTypes + totalMembers;

  String get _statisticsSummary =>
      '${totalLibraries} libraries, ${totalTypes} types, and '
      '${totalMembers} members';

  static const List<String> COMPILER_OPTIONS =
      const <String>['--preserve-comments', '--categories=Client,Server'];

  /// Resolves Dart links to the correct Node.
  md.Resolver dartdocResolver;

  // Add support for [:...:]-style code to the markdown parser.
  List<md.InlineSyntax> dartdocSyntaxes =
    [new md.CodeSyntax(r'\[:\s?((?:.|\n)*?)\s?:\]')];

  Dartdoc() {
    tmpPath = Directory.systemTemp.createTempSync('dartdoc_').path;
    dartdocResolver = (String name) => resolveNameReference(name,
        currentLibrary: _currentLibrary, currentType: _currentType,
        currentMember: _currentMember);
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
    Uri uri = library.uri;
    if (uri.scheme == 'dart') {
      String suffix = uri.path;
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
      Uri uri = library.uri;
      if (uri.scheme == 'dart') {
        String suffix = uri.path;
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
      footerItems.add("This page was generated at ${new DateTime.now()}");
    }
    if (footerText != null) {
      footerItems.add(footerText);
    }
    var content = '';
    for (int i = 0; i < footerItems.length; i++) {
      if (i > 0) {
        content += '\n';
      }
      content += '<div>${footerItems[i]}</div>';
    }
    return content;
  }

  Future documentLibraries(List<Uri> libraryList, String libPath,
      String packageRoot) {
    _packageRoot = packageRoot;
    _exports = new ExportMap.parse(libraryList, packageRoot);
    var librariesToAnalyze =
        _exports.allExportedFiles
                .map((file) => new Uri.file(file).toString())
                .toList();
    librariesToAnalyze.addAll(libraryList.map((uri) => uri.toString()));

    // dart2js takes a String, but it expects that to be a Uri, not a file
    // system path.
    libPath = path.toUri(libPath).toString();

    if (packageRoot != null) {
      packageRoot = path.toUri(packageRoot).toString();
    }

    // TODO(amouravski): make all of these print statements into logging
    // statements.
    print('Analyzing libraries...');
    return dart2js.analyze(
        librariesToAnalyze.toList(), libPath,
        packageRoot: packageRoot, options: COMPILER_OPTIONS)
      .then((MirrorSystem mirrors) {
        print('Generating documentation...');
        _document(mirrors);
      });
  }

  void _document(MirrorSystem mirrors) {
    _started = true;


    // Remove duplicated libraries. This is a hack because libraries can
    // get picked up multiple times (dartbug.com/11826) which will go away
    // with the new docgen. The reason we hit this issue is that we attempt
    // to dart2js.analyze all packages in the repo together, which results
    // in packages getting referenced with different URI's (../../pkg versus
    // ../../out/ReleaseIA32/packages versus package:).
    _sortedLibraries = new Map.fromIterable(
        mirrors.libraries.values.where(shouldIncludeLibrary),
        key: displayName).values.toList();

    // Sort the libraries by name (not key).
    _sortedLibraries.sort((x, y) {
      return displayName(x).toUpperCase().compareTo(
          displayName(y).toUpperCase());
    });

    _librariesByPath = <String, LibraryMirror>{};
    for (var library in mirrors.libraries.values) {
      var libraryPath = _libraryPath(library);
      if (libraryPath == null) continue;
      libraryPath = path.normalize(path.absolute(libraryPath));
      _librariesByPath[libraryPath] = library;
    }

    _hiddenLibraryExports = _generateHiddenLibraryExports();

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

    // TODO(nweiz): properly handle exports when generating JSON.
    // TODO(jacobr): handle arbitrary pub packages rather than just the system
    // libraries.
    var revision = '0';
    if (version != null) {
      var match = new RegExp(r"_r(\d+)").firstMatch(version);
      if (match != null) {
        revision = match.group(1);
      } else {
        print("Warning: could not parse version: $version");
      }
    }
    var packageManifest = new PackageManifest('dart:', 'Dart System Libraries',
        version, revision);

    for (final lib in _sortedLibraries) {
      var libraryElement = new LibraryElement(
          lib, lookupMdnComment: lookupMdnComment)
          ..stripDuplicateUris(null, null);
      packageManifest.libraries.add(new Reference.fromElement(libraryElement));
      startFile("$revision/${libraryElement.id}.json");
      write(json_serializer.serialize(libraryElement));
      endFile();
    }

    startFile("$revision/apidoc.json");
    write(json_serializer.serialize(packageManifest));
    endFile();

    // Write out top level json file with a relative path to the library json
    // files.
    startFile("apidoc.json");
    packageManifest.location = revision;
    write(json_serializer.serialize(packageManifest));
    endFile();

    _finished = true;
  }

  /**
   * Generate [_hiddenLibraryExports] from [_exports] and [_librariesByPath].
   */
  Map<String, List<Export>> _generateHiddenLibraryExports() {
    // First generate a map `exported path => exporter path => Export`. The
    // inner map makes it easier to merge multiple exports of the same library
    // by the same exporter.
    var hiddenLibraryExportMaps = <String, Map<String, Export>>{};
    _exports.exports.forEach((exporter, exports) {
      var library = _librariesByPath[exporter];
      // TODO(nweiz): remove this check when issue 9645 is fixed.
      if (library == null) return;
      if (!shouldIncludeLibrary(library)) return;
      for (var export in exports) {
        var library = _librariesByPath[export.path];
        // TODO(nweiz): remove this check when issue 9645 is fixed.
        if (library == null) continue;
        if (shouldIncludeLibrary(library)) continue;

        var hiddenExports = _exports.transitiveExports(export.path)
            .map((transitiveExport) => export.compose(transitiveExport))
            .toList();
        hiddenExports.add(export);

        for (var hiddenExport in hiddenExports) {
          var exportsByExporterPath = hiddenLibraryExportMaps
              .putIfAbsent(hiddenExport.path, () => <String, Export>{});
          addOrMergeExport(exportsByExporterPath, exporter, hiddenExport);
        }
      }
    });

    // Now sort the values of the inner maps of `hiddenLibraryExportMaps` to get
    // the final value of `_hiddenLibraryExports`.
    var hiddenLibraryExports = <String, List<Export>>{};
    hiddenLibraryExportMaps.forEach((exporteePath, exportsByExporterPath) {
      int rank(Export export) {
        if (export.show.isEmpty && export.hide.isEmpty) return 0;
        if (export.show.isEmpty) return export.hide.length;
        // Multiply by 1000 to ensure this sorts after an export with hides.
        return 1000 * export.show.length;
      }

      var exports = exportsByExporterPath.values.toList();
      exports.sort((export1, export2) {
        var comparison = Comparable.compare(rank(export1), rank(export2));
        if (comparison != 0) return comparison;

        var library1 = _librariesByPath[export1.exporter];
        var library2 = _librariesByPath[export2.exporter];
        return Comparable.compare(displayName(library1), displayName(library2));
      });
      hiddenLibraryExports[exporteePath] = exports;
    });
    return hiddenLibraryExports;
  }

  MdnComment lookupMdnComment(Mirror mirror) => null;

  void startFile(String path) {
    _filePath = path;
    _file = new StringBuffer();
  }

  void endFile() {
    final outPath = path.join(outputDir, _filePath);
    final dir = new Directory(path.dirname(outPath));
    if (!dir.existsSync()) {
      // TODO(3914): Hack to avoid 'file already exists' exception
      // thrown due to invalid result from dir.existsSync() (probably due to
      // race conditions).
      try {
        dir.createSync();
      } on FileSystemException catch (e) {
        // Ignore.
      }
    }

    writeString(new File(outPath), _file.toString());
    _filePath = null;
    _file = null;
  }

  void write(String s) {
    _file.write(s);
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
        <link href="//fonts.googleapis.com/css?family=Open+Sans:400,600,700,800" rel="stylesheet" type="text/css">
        <link rel="shortcut icon" href="${relativePath('favicon.ico')}">
        ''');
  }

  void writeFooter() {
    writeln(
        '''
        </div>
        <div class="clear"></div>
        </div>
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
    writeln(JSON.encode(createNavigationInfo()));
    endFile();
  }
  /// Whether dartdoc is running from within the Dart SDK or the
  /// Dart source repository.
  bool get runningFromSdk =>
      path.extension(Platform.script.toFilePath()) == '.snapshot';

  /// Gets the path to the root directory of the SDK.
  String get sdkDir =>
    path.dirname(path.dirname(Platform.executable));

  /// Gets the path to the dartdoc directory normalized for running in different
  /// places.
  String get normalizedDartdocPath => path.normalize(
      path.absolute(runningFromSdk ?
          path.join(sdkDir, 'lib', '_internal', 'dartdoc') :
          dartdocPath.toString()));

  void docNavigationDart() {
    var tmpDir = new Directory(tmpPath);
    if (!tmpDir.existsSync()) {
        tmpDir.createSync();
    }
    String jsonString = JSON.encode(createNavigationInfo());
    String dartString = jsonString.replaceAll(r"$", r"\$");
    var filePath = path.join(tmpPath, 'client.dart');

    var clientDir = path.join(normalizedDartdocPath,'lib', 'src', 'client');

    writeString(new File(filePath),
        '''library client;
        import 'dart:html';
        import r'${path.toUri(path.join(clientDir, 'client-shared.dart'))}';
        import r'${path.toUri(path.join(clientDir, 'dropdown.dart'))}';

        main() {
          setup();
          setupSearch(json);
        }

        get json => $dartString;''');
  }

  void cleanup() {
    var tmpDir = new Directory(tmpPath);
    if (tmpDir.existsSync()) {
      tmpDir.deleteSync(recursive: true);
    }
    tmpPath = null;
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
    final List members = docMembersJson(library.members);
    if (!members.isEmpty) {
      libraryInfo[MEMBERS] = members;
    }

    final types = [];
    for (ClassMirror type in orderByName(library.classes.values)) {
      if (!showPrivate && type.isPrivate) continue;

      var typeInfo = {};
      typeInfo[NAME] = displayName(type);
      if (type.isClass) {
        typeInfo[KIND] = CLASS;
      } else {
        assert(type.isTypedef);
        typeInfo[KIND] = TYPEDEF;
      }
      final List typeMembers = docMembersJson(type.members);
      if (!typeMembers.isEmpty) {
        typeInfo[MEMBERS] = typeMembers;
      }

      if (!type.originalDeclaration.typeVariables.isEmpty) {
        final typeVariables = [];
        for (final typeVariable in type.originalDeclaration.typeVariables) {
          typeVariables.add(displayName(typeVariable));
        }
        typeInfo[ARGS] = typeVariables.join(', ');
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
      if (member.isVariable) {
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
      memberInfo[NAME] = displayName(member);
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
    final types = <ClassMirror>[];
    final exceptions = <ClassMirror>[];

    for (ClassMirror type in orderByName(library.classes.values)) {
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
  void docTypeNavigation(ClassMirror type) {
    var icon = 'interface';
    if (isException(type)) {
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

    startFile(libraryUrl(library));
    writeHeader('${displayName(library)} Library',
        [displayName(library), libraryUrl(library)]);
    writeln('<h2><strong>${displayName(library)}</strong> library</h2>');

    // Look for a comment for the entire library.
    final comment = getLibraryComment(library);
    if (comment != null) {
      writeln('<div class="doc">${comment.html}</div>');
    }

    // Document the visible libraries exported by this library.
    docExports(library);

    // Document the top-level members.
    docMembers(library);

    // Document the types.
    final abstractClasses = <ClassMirror>[];
    final classes = <ClassMirror>[];
    final typedefs = <TypedefMirror>[];
    final exceptions = <ClassMirror>[];

    var allClasses = _libraryClasses(library);
    for (ClassMirror type in orderByName(allClasses)) {
      if (!showPrivate && type.isPrivate) continue;

      if (isException(type)) {
        exceptions.add(type);
      } else if (type.isClass) {
        if (type.isAbstract) {
          abstractClasses.add(type);
        } else {
          classes.add(type);
        }
      } else if (type is TypedefMirror) {
        typedefs.add(type);
      } else {
        throw new InternalError("internal error: unknown type $type.");
      }
    }

    docTypes(abstractClasses, 'Abstract Classes');
    docTypes(classes, 'Classes');
    docTypes(typedefs, 'Typedefs');
    docTypes(exceptions, 'Exceptions');

    writeFooter();
    endFile();

    for (final type in allClasses) {
      if (!showPrivate && type.isPrivate) continue;

      docType(type);
    }

    _currentLibrary = null;
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

  void docType(ClassMirror type) {
    if (verbose) {
      print('- ${type.simpleName}');
    }
    _totalTypes++;
    _currentType = type;

    startFile(typeUrl(type));

    var kind;
    if (type.isTypedef) {
      kind = 'typedef';
    } else {
      assert(type.isClass);
      if (type.isAbstract) {
        kind = 'abstract class';
      } else {
        kind = 'class';
      }
    }

    final typeTitle =
      '${typeName(type)} ${kind}';
    var library = _libraryFor(type);
    writeHeader('$typeTitle / ${displayName(library)} Library',
        [displayName(library), libraryUrl(library),
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

    _currentType = null;
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
  void typeSpan(ClassMirror type) {
    var icon = 'interface';
    if (isException(type)) {
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
  void docInheritance(ClassMirror type) {
    // Don't show the inheritance details for Object. It doesn't have any base
    // class (obviously) and it has too many subclasses to be useful.
    if (type.isObject) return;
    if (type.isTypedef) return;

    // Writes an unordered list of references to types with an optional header.
    listTypes(types, header) {
      if (types == null) return;

      // Filter out injected types. (JavaScriptIndexingBehavior)
      types = new List.from(types.where((t) => t.library != null));

      var publicTypes;
      if (showPrivate) {
        publicTypes = types;
      } else {
        // Skip private types.
        publicTypes = new List.from(types.where((t) => !t.isPrivate));
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

    // Show the chain of superclasses.
    var superclass = getSuperclass(type);
    if (!superclass.isObject) {
      final supertypes = [];
      var thisType = superclass;
      do {
        supertypes.add(thisType);
        thisType = getSuperclass(thisType);
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
    listTypes(getAppliedMixins(type), 'Mixins');
    listTypes(getExplicitInterfaces(type), 'Implements');
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
    annotateType(type, type.value, type.simpleName);

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

  void docExports(LibraryMirror library) {
    // TODO(nweiz): show `dart:` library exports.
    var exportLinks = _exports.transitiveExports(_libraryPath(library))
        .map((export) {
      var library = _librariesByPath[export.path];
      // TODO(nweiz): remove this check when issue 9645 is fixed.
      if (library == null) return null;
      // Only link to publically visible libraries.
      if (!shouldIncludeLibrary(library)) return null;

      var memberNames = export.show.isEmpty ? export.hide : export.show;
      var memberLinks = memberNames.map((name) {
        return md.renderToHtml([resolveNameReference(
            name, currentLibrary: library)]);
      }).join(', ');
      var combinator = '';
      if (!export.show.isEmpty) {
        combinator = ' show $memberLinks';
      } else if (!export.hide.isEmpty) {
        combinator = ' hide $memberLinks';
      }

      return '<ul>${a(libraryUrl(library), displayName(library))}'
        '$combinator</ul>';
    }).where((link) => link != null);

    if (!exportLinks.isEmpty) {
      writeln('<h3>Exports</h3>');
      writeln('<ul>');
      writeln(exportLinks.join('\n'));
      writeln('</ul>');
    }
  }

  void docMembers(ContainerMirror host) {
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

    var hostMembers = host is LibraryMirror ?
        _libraryMembers(host) : host.members.values;
    for (var member in hostMembers) {
      if (!showPrivate && member.isPrivate) continue;
      if (host is LibraryMirror || member.isStatic) {
        if (member is MethodMirror) {
          if (member.isGetter) {
            staticGetters[displayName(member)] = member;
          } else if (member.isSetter) {
            staticSetters[displayName(member)] = member;
          } else {
            staticMethods.add(member);
          }
        } else if (member is VariableMirror) {
          staticGetters[displayName(member)] = member;
        }
      }
    }

    if (host is ClassMirror) {
      var iterable = new HierarchyIterable(host, includeType: true);
      for (ClassMirror type in iterable) {
        if (!host.isObject && !inheritFromObject && type.isObject) continue;

        type.members.forEach((_, MemberMirror member) {
          if (member.isStatic) return;
          if (!showPrivate && member.isPrivate) return;

          bool inherit = true;
          if (type != host) {
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

          if (member.isVariable) {
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
          instanceGetters[displayName(member)] = member;
          if (_ownerFor(member) == host) {
            allPropertiesInherited = false;
          }
        } else if (member.isSetter) {
          instanceSetters[displayName(member)] = member;
          if (_ownerFor(member) == host) {
            allPropertiesInherited = false;
          }
        } else if (member.isOperator) {
          instanceOperators.add(member);
          if (_ownerFor(member) == host) {
            allOperatorsInherited = false;
          }
        } else {
          instanceMethods.add(member);
          if (_ownerFor(member) == host) {
            allMethodsInherited = false;
          }
        }
      } else if (member is VariableMirror) {
        instanceGetters[displayName(member)] = member;
        if (_ownerFor(member) == host) {
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
  void docProperties(ContainerMirror host, String title,
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
        if (getter is VariableMirror) {
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
        if (_ownerFor(getter) != _ownerFor(setter) ||
            getterComment != null && setterComment != null) {
          // Both have comments or are not declared in the same class
          // => Documents separately.
          if (getter is VariableMirror) {
            // Document field as a getter (setter is inherited).
            docField(host, getter, asGetter: true);
          } else {
            docMethod(host, getter);
          }
          if (setter is VariableMirror) {
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

  void docMethods(ContainerMirror host, String title, List<Mirror> methods,
                  {bool allInherited}) {
    if (methods.length > 0) {
      writeln('<div${allInherited ? ' class="inherited"' : ''}>');
      writeln('<h3>$title</h3>');
      for (MethodMirror method in methods) {
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
  void docMethod(ContainerMirror host, MemberMirror member,
                 {bool asGetter: false}) {
    _totalMembers++;
    _currentMember = member;

    bool isAbstract = false;
    String name = displayName(member);
    if (member is VariableMirror) {
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
    bool inherited = host != member.owner && member.owner is! LibraryMirror;

    writeln('<div class="method${inherited ? ' inherited': ''}">'
            '<h4 id="${memberAnchor(member)}">');

    if (showCode) {
      writeln('<button class="show-code">Code</button>');
    }

    if (member is MethodMirror) {
      if (member.isConstructor) {
        if (member.isFactoryConstructor) {
          write('factory ');
        } else {
          write(member.isConstConstructor ? 'const ' : 'new ');
        }
      } else if (member.isAbstract) {
        write('abstract ');
      }

      if (!member.isConstructor) {
        annotateDynamicType(host, member.returnType);
      }
    } else {
      assert(member is VariableMirror);
      if (asGetter) {
        annotateDynamicType(host, member.type);
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
      assert(member is VariableMirror);
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
      docInherited(host, member.owner);
    }

    writeln('<div class="doc">');
    docComment(host, getMemberComment(member));
    if (showCode) {
      docCode(member.location);
    }
    writeln('</div>');

    writeln('</div>');

    _currentMember = null;
  }

  /**
   * Annotate a member as inherited or mixed in from [owner].
   */
  void docInherited(ContainerMirror host, ClassMirror owner) {
    if (isMixinApplication(owner)) {
      write('<div class="inherited-from">mixed in from ');
      annotateType(host, owner.mixin);
      write('</div>');
    } else {
      write('<div class="inherited-from">inherited from ');
      annotateType(host, owner);
      write('</div>');
    }
  }

  void docField(ContainerMirror host, VariableMirror field,
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
  void docProperty(ContainerMirror host,
                   MemberMirror getter, MemberMirror setter) {
    assert(getter != null);
    _totalMembers++;
    _currentMember = getter;

    bool inherited = host != getter.owner && getter.owner is! LibraryMirror;

    writeln('<div class="field${inherited ? ' inherited' : ''}">'
            '<h4 id="${memberAnchor(getter)}">');

    if (includeSource) {
      writeln('<button class="show-code">Code</button>');
    }

    bool isConst = false;
    bool isFinal;
    TypeMirror type;
    if (getter is VariableMirror) {
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
      docInherited(host, getter.owner);
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

    _currentMember = null;
  }

  void docParamList(ContainerMirror enclosingType,
                    List<ParameterMirror> parameters) {
    write('(');
    bool first = true;
    bool inOptionals = false;
    bool isNamed = false;
    for (final parameter in parameters) {
      if (!first) write(', ');

      if (!inOptionals && parameter.isOptional) {
        isNamed = parameter.isNamed;
        write(isNamed ? '{' : '[');
        inOptionals = true;
      }

      annotateType(enclosingType, parameter.type, parameter.simpleName);

      // Show the default value for named optional parameters.
      if (parameter.isOptional && parameter.hasDefaultValue) {
        write(isNamed ? ': ' : ' = ');
        write(parameter.defaultValue);
      }

      first = false;
    }

    if (inOptionals) {
      write(isNamed ? '}' : ']');
    }
    write(')');
  }

  void docComment(ContainerMirror host, DocComment comment) {
    if (comment != null) {
      var html = comment.html;

      if (comment.inheritedFrom != null) {
        writeln('<div class="inherited">');
        writeln(html);
        write('<div class="docs-inherited-from">docs inherited from ');
        annotateType(host, comment.inheritedFrom);
        write('</div>');
        writeln('</div>');
      } else {
        writeln(html);
      }
    }
  }

  /**
   * Documents the source code contained within [location].
   */
  void docCode(SourceLocation location) {
    if (includeSource) {
      writeln('<pre class="source">');
      writeln(md.escapeHtml(unindentCode(location)));
      writeln('</pre>');
    }
  }

  /** Get the doc comment associated with the given library. */
  DocComment getLibraryComment(LibraryMirror library) => getComment(library);

  /** Get the doc comment associated with the given type. */
  DocComment getTypeComment(TypeMirror type) => getComment(type);

  /**
   * Get the doc comment associated with the given member.
   *
   * If no comment was found on the member, the hierarchy is traversed to find
   * an inherited comment, favouring comments inherited from classes over
   * comments inherited from interfaces.
   */
  DocComment getMemberComment(MemberMirror member) => getComment(member);

  /**
   * Get the doc comment associated with the given declaration.
   *
   * If no comment was found on a member, the hierarchy is traversed to find
   * an inherited comment, favouring comments inherited from classes over
   * comments inherited from interfaces.
   */
  DocComment getComment(DeclarationMirror mirror) {
    String comment = computeComment(mirror);
    ClassMirror inheritedFrom = null;
    if (comment == null) {
      if (mirror.owner is ClassMirror) {
        var iterable =
            new HierarchyIterable(mirror.owner,
                                  includeType: false);
        for (ClassMirror type in iterable) {
          var inheritedMember = type.members[mirror.simpleName];
          if (inheritedMember is MemberMirror) {
            comment = computeComment(inheritedMember);
            if (comment != null) {
              inheritedFrom = type;
              break;
            }
          }
        }
      }
    }
    if (comment == null) return null;
    if (isMixinApplication(inheritedFrom)) {
      inheritedFrom = inheritedFrom.mixin;
    }
    return new DocComment(comment, inheritedFrom, dartdocSyntaxes,
        dartdocResolver);
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
    return new RegExp(r'^\w+:').hasMatch(url);
  }

  /** Gets the URL to the documentation for [library]. */
  String libraryUrl(LibraryMirror library) {
    return '${sanitize(displayName(library))}.html';
  }

  /** Gets the URL for the documentation for [type]. */
  String typeUrl(ContainerMirror type) {
    if (type is LibraryMirror) {
      return '${sanitize(type.simpleName)}.html';
    }
    if (type.library == null) {
      return '';
    }
    // Always get the generic type to strip off any type parameters or
    // arguments. If the type isn't generic, genericType returns `this`, so it
    // works for non-generic types too.
    return '${sanitize(displayName(_libraryFor(type)))}/'
           '${type.originalDeclaration.simpleName}.html';
  }

  /** Gets the URL for the documentation for [member]. */
  String memberUrl(MemberMirror member) {
    String url = typeUrl(_ownerFor(member));
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
   * Writes a type annotation, preferring to print dynamic.
   */
  annotateDynamicType(ContainerMirror enclosingType,
                      TypeMirror type) {
    annotateType(enclosingType, type, type.isDynamic ? 'dynamic ' : null);
  }

  /**
   * Writes a type annotation for the given type and (optional) parameter name.
   */
  annotateType(ContainerMirror enclosingType,
               TypeMirror type,
               [String paramName = null]) {
    // Don't bother explicitly displaying dynamic.
    if (type.isDynamic) {
      if (paramName != null) write(paramName);
      return;
    }

    // For parameters, handle non-typedefed function types.
    if (paramName != null && type is FunctionTypeMirror) {
      annotateType(enclosingType, type.returnType);
      write(paramName);

      docParamList(enclosingType, type.parameters);
      return;
    }

    linkToType(enclosingType, type);

    write(' ');
    if (paramName != null) write(paramName);
  }

  /** Writes a link to a human-friendly string representation for a type. */
  linkToType(ContainerMirror enclosingType, TypeMirror type) {
    if (type.isVoid) {
      // Do not generate links for void.
      // TODO(johnniwinter): Generate span for specific style?
      write('void');
      return;
    }
    if (type.isDynamic) {
      // Do not generate links for dynamic.
      write('dynamic');
      return;
    }

    if (type.isTypeVariable) {
      // If we're using a type parameter within the body of a generic class then
      // just link back up to the class.
      write(a(typeUrl(enclosingType), type.simpleName));
      return;
    }

    assert(type is ClassMirror);

    // Link to the type.
    var library = _libraryFor(type);
    if (shouldLinkToPublicApi(library)) {
      write('<a href="$API_LOCATION${typeUrl(type)}">${type.simpleName}</a>');
    } else if (shouldIncludeLibrary(library)) {
      write(a(typeUrl(type), type.simpleName));
    } else {
      write(type.simpleName);
    }

    if (type.isOriginalDeclaration) {
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
  typeReference(ClassMirror type) {
    // TODO(rnystrom): Do we need to handle ParameterTypes here like
    // annotation() does?
    return a(typeUrl(type), typeName(type), 'crossref');
  }

  /** Generates a human-friendly string representation for a type. */
  typeName(TypeMirror type, {bool showBounds: false}) {
    if (type.isVoid) {
      return 'void';
    }
    if (type.isDynamic) {
      return 'dynamic';
    }
    if (type is TypeVariableMirror) {
      return type.simpleName;
    }
    assert(type is ClassMirror);

    // See if it's a generic type.
    if (type.isOriginalDeclaration) {
      final typeParams = [];
      for (final typeParam in type.originalDeclaration.typeVariables) {
        if (showBounds &&
            (typeParam.upperBound != null) &&
            !typeParam.upperBound.isObject) {
          final bound = typeName(typeParam.upperBound, showBounds: true);
          typeParams.add('${typeParam.simpleName} extends $bound');
        } else {
          typeParams.add(typeParam.simpleName);
        }
      }
      if (typeParams.isEmpty) {
        return type.simpleName;
      }
      final params = typeParams.join(', ');
      return '${type.simpleName}&lt;$params&gt;';
    }

    // See if it's an instantiation of a generic type.
    final typeArgs = type.typeArguments;
    if (typeArgs.length > 0) {
      final args = typeArgs.map((arg) => typeName(arg)).join(', ');
      return '${type.originalDeclaration.simpleName}&lt;$args&gt;';
    }

    // Regular type.
    return type.simpleName;
  }

  /**
   * Remove leading indentation to line up with first line.
   */
  unindentCode(SourceLocation span) {
    final column = span.column;
    final lines = span.text.split('\n');
    // TODO(rnystrom): Dirty hack.
    for (var i = 1; i < lines.length; i++) {
      lines[i] = unindent(lines[i], column);
    }

    final code = lines.join('\n');
    return code;
  }

  /**
   * Takes a string of Dart code and turns it into sanitized HTML.
   */
  formatCode(SourceLocation span) {
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
                                ContainerMirror currentType,
                                LibraryMirror currentLibrary}) {
    makeLink(String href) {
      final anchor = new md.Element.text('a', name);
      anchor.attributes['href'] = relativePath(href);
      anchor.attributes['class'] = 'crossref';
      return anchor;
    }

    DeclarationMirror declaration = currentMember;
    if (declaration == null) declaration = currentType;
    if (declaration == null) declaration = currentLibrary;
    if (declaration != null) {
      declaration = lookupQualifiedInScope(declaration, name);
    }

    if (declaration != null) {
      if (declaration is TypeVariableMirror) {
        return makeLink(typeUrl(declaration.owner));
      } if (declaration is TypeMirror) {
        return makeLink(typeUrl(declaration));
      } else if (declaration is MethodMirror) {
        return makeLink(memberUrl(declaration));
      }
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
      final foundMember = currentType.members[name];
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
        ClassMirror foundtype = currentLibrary.classes[typeName];
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
        ClassMirror foundtype = currentLibrary.classes[match[1]];
        if (foundtype == null) return;
        MemberMirror foundMember = foundtype.members[match[2]];
        if (foundMember == null) return;
        return makeLink(memberUrl(foundMember));
      })();
      if (foreignMemberLink != null) return foreignMemberLink;

      ClassMirror foundType = currentLibrary.classes[name];
      if (foundType != null) {
        return makeLink(typeUrl(foundType));
      }

      // See if it's a top-level member in the current library.
      MemberMirror foundMember = currentLibrary.members[name];
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
    write("# VERSION: ${new DateTime.now()}\n\n");
    write("NETWORK:\n*\n\n");
    write("CACHE:\n");
    var toCache = new Directory(outputDir);
    toCache.list(recursive: true).listen(
        (FileSystemEntity entity) {
          if (entity is File) {
            var filename = entity.path;
            if (filename.endsWith('appcache.manifest')) {
              return;
            }
            String relativeFilePath = path.relative(filename, from: outputDir);
            write("$relativeFilePath\n");
          }
        },
        onDone: () => endFile());
  }

  /**
   * Returns [:true:] if [type] should be regarded as an exception.
   */
  bool isException(TypeMirror type) {
    return type.simpleName.endsWith('Exception') ||
        type.simpleName.endsWith('Error');
  }

  /**
   * Returns the absolute path to [library] on the filesystem, or `null` if the
   * library doesn't exist on the local filesystem.
   */
  String _libraryPath(LibraryMirror library) =>
    importUriToPath(library.uri, packageRoot: _packageRoot);

  /**
   * Returns a list of classes in [library], including classes it exports from
   * hidden libraries.
   */
  List<ClassMirror> _libraryClasses(LibraryMirror library) =>
    _libraryContents(library, (lib) => lib.classes.values);

  /**
   * Returns a list of top-level members in [library], including members it
   * exports from hidden libraries.
   */
  List<MemberMirror> _libraryMembers(LibraryMirror library) =>
    _libraryContents(library, (lib) => lib.members.values);


  /**
   * Returns a list of elements in [library], including elements it exports from
   * hidden libraries. [fn] should return the element list for a single library,
   * which will then be merged across all exported libraries.
   */
  List<DeclarationMirror> _libraryContents(LibraryMirror library,
      List<DeclarationMirror> fn(LibraryMirror)) {
    var contents = fn(library).toList();
    var path = _libraryPath(library);
    if (path == null || _exports.exports[path] == null) return contents;


    contents.addAll(_exports.exports[path].expand((export) {
      var exportedLibrary = _librariesByPath[export.path];
      // TODO(nweiz): remove this check when issue 9645 is fixed.
      if (exportedLibrary == null) return [];
      if (shouldIncludeLibrary(exportedLibrary)) return [];
      return fn(exportedLibrary).where((declaration) =>
          export.isMemberVisible(displayName(declaration)));
    }));
    return contents;
  }

  /**
   * Returns the library in which [type] was defined. If [type] was defined in a
   * hidden library that was exported by another library, this returns the
   * exporter.
   */
  LibraryMirror _libraryFor(TypeMirror type) =>
    _visibleLibrary(type.library, displayName(type));

  /**
   * Returns the owner of [declaration]. If [declaration]'s owner is a hidden
   * library that was exported by another library, this returns the exporter.
   */
  DeclarationMirror _ownerFor(DeclarationMirror declaration) {
    var owner = declaration.owner;
    if (owner is! LibraryMirror) return owner;
    return _visibleLibrary(owner, displayName(declaration));
  }

  /**
   * Returns the best visible library that exports [name] from [library]. If
   * [library] is public, it will be returned.
   */
  LibraryMirror _visibleLibrary(LibraryMirror library, String name) {
    if (library == null) return null;

    var exports = _hiddenLibraryExports[_libraryPath(library)];
    if (exports == null) return library;

    var export = exports.firstWhere(
        (exp) => exp.isMemberVisible(name),
        orElse: () => null);
    if (export == null) return library;
    return _librariesByPath[export.exporter];
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

/**
 * Computes the doc comment for the declaration mirror.
 *
 * Multiple comments are concatenated with newlines in between.
 */
String computeComment(DeclarationMirror mirror) {
  String text;
  for (InstanceMirror metadata in mirror.metadata) {
    if (metadata is CommentInstanceMirror) {
      CommentInstanceMirror comment = metadata;
      if (comment.isDocComment) {
        if (text == null) {
          text = comment.trimmedText;
        } else {
          text = '$text\n${comment.trimmedText}';
        }
      }
    }
  }
  return text;
}

/**
 * Computes the doc comment for the declaration mirror as a list.
 */
List<String> computeUntrimmedCommentAsList(DeclarationMirror mirror) {
  var text = <String>[];
  for (InstanceMirror metadata in mirror.metadata) {
    if (metadata is CommentInstanceMirror) {
      CommentInstanceMirror comment = metadata;
      if (comment.isDocComment) {
        text.add(comment.text);
      }
    }
  }
  return text;
}

class DocComment {
  final String text;
  md.Resolver dartdocResolver;
  List<md.InlineSyntax> dartdocSyntaxes;

  /**
   * Non-null if the comment is inherited from another declaration.
   */
  final ClassMirror inheritedFrom;

  DocComment(this.text, [this.inheritedFrom = null, this.dartdocSyntaxes,
      this.dartdocResolver]) {
    assert(text != null && !text.trim().isEmpty);
  }

  String toString() => text;

  String get html {
    return md.markdownToHtml(text,
        inlineSyntaxes: dartdocSyntaxes,
        linkResolver: dartdocResolver);
  }
}

class MdnComment implements DocComment {
  final String mdnComment;
  final String mdnUrl;

  MdnComment(String this.mdnComment, String this.mdnUrl);

  String get text => mdnComment;

  ClassMirror get inheritedFrom => null;

  String get html {
    // Wrap the mdn comment so we can highlight it and so we handle MDN scraped
    // content that lacks a top-level block tag.
   return '''
        <div class="mdn">
        $mdnComment
        <div class="mdn-note"><a href="$mdnUrl">from MDN</a></div>
        </div>
        ''';
  }

  String toString() => mdnComment;
}
