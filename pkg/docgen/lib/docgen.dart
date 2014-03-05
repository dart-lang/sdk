// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// **docgen** is a tool for creating machine readable representations of Dart
/// code metadata, including: classes, members, comments and annotations.
///
/// docgen is run on a `.dart` file or a directory containing `.dart` files.
///
///      $ dart docgen.dart [OPTIONS] [FILE/DIR]
///
/// This creates files called `docs/<library_name>.yaml` in your current
/// working directory.
library docgen;

import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:logging/logging.dart';
import 'package:markdown/markdown.dart' as markdown;
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

import 'dart2yaml.dart';
import 'src/io.dart';
import '../../../sdk/lib/_internal/compiler/compiler.dart' as api;
import '../../../sdk/lib/_internal/compiler/implementation/filenames.dart';
import '../../../sdk/lib/_internal/compiler/implementation/mirrors/dart2js_mirrors.dart'
    as dart2js_mirrors;
import '../../../sdk/lib/_internal/compiler/implementation/mirrors/analyze.dart'
    as dart2js;
import '../../../sdk/lib/_internal/compiler/implementation/mirrors/source_mirrors.dart';
import '../../../sdk/lib/_internal/compiler/implementation/mirrors/mirrors_util.dart'
    as dart2js_util;
import '../../../sdk/lib/_internal/compiler/implementation/source_file_provider.dart';
import '../../../sdk/lib/_internal/libraries.dart';

const _DEFAULT_OUTPUT_DIRECTORY = 'docs';

/// Annotations that we do not display in the viewer.
const List<String> _SKIPPED_ANNOTATIONS = const [
    'metadata.DocsEditable', '_js_helper.JSName', '_js_helper.Creates',
    '_js_helper.Returns'];

/// Support for [:foo:]-style code comments to the markdown parser.
List<markdown.InlineSyntax> _MARKDOWN_SYNTAXES =
  [new markdown.CodeSyntax(r'\[:\s?((?:.|\n)*?)\s?:\]')];

/// If we can't find the SDK introduction text, which will happen if running
/// from a snapshot and using --parse-sdk or --include-sdk, then use this
/// hard-coded version. This should be updated to be consistent with the text
/// in docgen/doc/sdk-introduction.md
const _DEFAULT_SDK_INTRODUCTION = """
Welcome to the Dart API reference documentation,
covering the official Dart API libraries.
Some of the most fundamental Dart libraries include:

* [dart:core](#dart:core):
  Core functionality such as strings, numbers, collections, errors,
  dates, and URIs.
* [dart:html](#dart:html):
  DOM manipulation for web apps.
* [dart:io](#dart:io):
  I/O for command-line apps.

Except for dart:core, you must import a library before you can use it.
Here's an example of importing dart:html, dart:math, and a
third popular library called
[polymer.dart](http://www.dartlang.org/polymer-dart/):

    import 'dart:html';
    import 'dart:math';
    import 'package:polymer/polymer.dart';

Polymer.dart is an example of a library that isn't
included in the Dart download,
but is easy to get and update using the _pub package manager_.
For information on finding, using, and publishing libraries (and more)
with pub, see
[pub.dartlang.org](http://pub.dartlang.org).

The main site for learning and using Dart is
[www.dartlang.org](http://www.dartlang.org).
Check out these pages:

  * [Dart homepage](http://www.dartlang.org)
  * [Tutorials](http://www.dartlang.org/docs/tutorials/)
  * [Programmer's Guide](http://www.dartlang.org/docs/)
  * [Samples](http://www.dartlang.org/samples/)
  * [A Tour of the Dart Libraries](http://www.dartlang.org/docs/dart-up-and-running/contents/ch03.html)

This API reference is automatically generated from the source code in the
[Dart project](https://code.google.com/p/dart/).
If you'd like to contribute to this documentation, see
[Contributing](https://code.google.com/p/dart/wiki/Contributing)
and
[Writing API Documentation](https://code.google.com/p/dart/wiki/WritingApiDocumentation).
""";

/// Docgen constructor initializes the link resolver for markdown parsing.
/// Also initializes the command line arguments.
///
/// [packageRoot] is the packages directory of the directory being analyzed.
/// If [includeSdk] is `true`, then any SDK libraries explicitly imported will
/// also be documented.
/// If [parseSdk] is `true`, then all Dart SDK libraries will be documented.
/// This option is useful when only the SDK libraries are needed.
/// If [compile] is `true`, then after generating the documents, compile the
/// viewer with dart2js.
/// If [serve] is `true`, then after generating the documents we fire up a
/// simple server to view the documentation.
///
/// Returned Future completes with true if document generation is successful.
Future<bool> docgen(List<String> files, {String packageRoot,
    bool outputToYaml: false, bool includePrivate: false, bool includeSdk: false,
    bool parseSdk: false, bool append: false, String introFileName: '',
    String out: _DEFAULT_OUTPUT_DIRECTORY,
    List<String> excludeLibraries : const [],
    bool includeDependentPackages: false, bool compile: false,
    bool serve: false, bool noDocs: false, String startPage, String pubScript,
    String dartBinary}) {
  var result;
  if (!noDocs) {
    _Viewer.ensureMovedViewerCode();
    result = _Generator.generateDocumentation(files, packageRoot: packageRoot,
        outputToYaml: outputToYaml, includePrivate: includePrivate,
        includeSdk: includeSdk, parseSdk: parseSdk, append: append,
        introFileName: introFileName, out: out,
        excludeLibraries: excludeLibraries,
        includeDependentPackages: includeDependentPackages,
        startPage: startPage, pubScript: pubScript, dartBinary: dartBinary);
    _Viewer.addBackViewerCode();
    if (compile || serve) {
      result.then((success) {
        if (success) {
          _createViewer(serve);
        }
      });
    }
  } else if (compile || serve) {
    _createViewer(serve);
  }
  return result;
}

void _createViewer(bool serve) {
  _Viewer._clone();
  _Viewer._compile();
  if (serve) {
     _Viewer._runServer();
   }
}

/// Analyzes set of libraries by getting a mirror system and triggers the
/// documentation of the libraries.
Future<MirrorSystem> getMirrorSystem(List<Uri> libraries,
    {String packageRoot, bool parseSdk: false}) {
  if (libraries.isEmpty) throw new StateError('No Libraries.');

  // Finds the root of SDK library based off the location of docgen.
  // We have two different places to look, depending if we're in a development
  // repo or in a built SDK, either sdk or dart-sdk respectively
  var root = _Generator._rootDirectory;
  var sdkRoot = path.normalize(path.absolute(path.join(root, 'sdk')));
  if (!new Directory(sdkRoot).existsSync()) {
    sdkRoot = path.normalize(path.absolute(path.join(root, 'dart-sdk')));
  }
  _Generator.logger.info('SDK Root: ${sdkRoot}');
  return _Generator._analyzeLibraries(libraries, sdkRoot,
      packageRoot: packageRoot);
}

/// For types that we do not explicitly create or have not yet created in our
/// entity map (like core types).
class DummyMirror implements Indexable {
  DeclarationMirror mirror;
  /// The library that contains this element, if any. Used as a hint to help
  /// determine which object we're referring to when looking up this mirror in
  /// our map.
  Indexable owner;
  DummyMirror(this.mirror, [this.owner]);

  String get docName {
    if (mirror == null) return '';
    if (mirror is LibraryMirror) {
      return dart2js_util.qualifiedNameOf(mirror).replaceAll('.','-');
    }
    var mirrorOwner = mirror.owner;
    if (mirrorOwner == null) return dart2js_util.qualifiedNameOf(mirror);
    var simpleName = dart2js_util.nameOf(mirror);
    if (mirror is MethodMirror && (mirror as MethodMirror).isConstructor) {
      // We name constructors specially -- repeating the class name and a
      // "-" to separate the constructor from its name (if any).
      simpleName = '${dart2js_util.nameOf(mirrorOwner)}-$simpleName';
    }
    return Indexable.getDocgenObject(mirrorOwner, owner).docName + '.' +
        simpleName;
  }

  bool get isPrivate => mirror == null? false : mirror.isPrivate;

  String get packageName {
    var libMirror = _getOwningLibraryFromMirror(mirror);
    if (libMirror != null) {
      return Library._packageName(libMirror);
    }
    return '';
  }

  String get packagePrefix => packageName == null || packageName.isEmpty ?
      '' : '$packageName/';

  LibraryMirror _getOwningLibraryFromMirror(DeclarationMirror mirror) {
    if (mirror is LibraryMirror) return mirror;
    if (mirror == null) return null;
    return _getOwningLibraryFromMirror(mirror.owner);
  }
}

/// Docgen representation of an item to be documented, that wraps around a
/// dart2js mirror.
abstract class MirrorBased {
  /// The original dart2js mirror around which this object wraps.
  DeclarationMirror get mirror;

  /// Returns a list of meta annotations assocated with a mirror.
  static List<Annotation> _createAnnotations(DeclarationMirror mirror,
      Library owningLibrary) {
    var annotationMirrors = mirror.metadata.where((e) =>
        e is dart2js_mirrors.Dart2JsConstructedConstantMirror);
    var annotations = [];
    annotationMirrors.forEach((annotation) {
      var docgenAnnotation = new Annotation(annotation, owningLibrary);
      if (!_SKIPPED_ANNOTATIONS.contains(
          dart2js_util.qualifiedNameOf(docgenAnnotation.mirror))) {
        annotations.add(docgenAnnotation);
      }
    });
    return annotations;
  }
}

/// Top level documentation traversal and generation object.
///
/// Yes, everything in this class is used statically so this technically doesn't
/// need to be its own class, but it's grouped together for semantic separation
/// from the other classes and functionality in this library.
class _Generator {
  /// The directory where the output docs are generated.
  static String _outputDirectory;

  /// This is set from the command line arguments flag --include-private
  static bool _includePrivate = false;

  /// Library names to explicitly exclude.
  ///
  ///   Set from the command line option
  /// --exclude-lib.
  static List<String> _excluded;

  /// The path of the pub script.
  static String _pubScript;

  /// The path of Dart binary.
  static String _dartBinary;

  /// Logger for printing out progress of documentation generation.
  static Logger logger = new Logger('Docgen');

  /// Docgen constructor initializes the link resolver for markdown parsing.
  /// Also initializes the command line arguments.
  ///
  /// [packageRoot] is the packages directory of the directory being analyzed.
  /// If [includeSdk] is `true`, then any SDK libraries explicitly imported will
  /// also be documented.
  /// If [parseSdk] is `true`, then all Dart SDK libraries will be documented.
  /// This option is useful when only the SDK libraries are needed.
  ///
  /// Returned Future completes with true if document generation is successful.
  static Future<bool> generateDocumentation(List<String> files,
      {String packageRoot, bool outputToYaml: true, bool includePrivate: false,
       bool includeSdk: false, bool parseSdk: false, bool append: false,
       String introFileName: '', out: _DEFAULT_OUTPUT_DIRECTORY,
       List<String> excludeLibraries : const [],
       bool includeDependentPackages: false, String startPage,
       String dartBinary, String pubScript}) {
    _excluded = excludeLibraries;
    _includePrivate = includePrivate;
    _pubScript = pubScript;
    _dartBinary = dartBinary;

    logger.onRecord.listen((record) => print(record.message));

    _ensureOutputDirectory(out, append);
    var updatedPackageRoot = _obtainPackageRoot(packageRoot, parseSdk, files);

    var requestedLibraries = _findLibrariesToDocument(files,
        includeDependentPackages);

    var allLibraries = []..addAll(requestedLibraries);
    if (includeSdk) {
      allLibraries.addAll(_listSdk());
    }

    return getMirrorSystem(allLibraries, packageRoot: updatedPackageRoot,
        parseSdk: parseSdk)
      .then((MirrorSystem mirrorSystem) {
        if (mirrorSystem.libraries.isEmpty) {
          throw new StateError('No library mirrors were created.');
        }
        Indexable._initializeTopLevelLibraries(mirrorSystem);

        var availableLibraries = mirrorSystem.libraries.values.where(
            (each) => each.uri.scheme == 'file');
        var availableLibrariesByPath = new Map.fromIterables(
            availableLibraries.map((each) => each.uri),
            availableLibraries);
        var librariesToDocument = requestedLibraries.map(
            (each) => availableLibrariesByPath.putIfAbsent(each,
                () => throw "Missing library $each")).toList();
        librariesToDocument.addAll(
            (includeSdk || parseSdk) ? Indexable._sdkLibraries : []);
        librariesToDocument.removeWhere(
            (x) => _excluded.contains(dart2js_util.nameOf(x)));
        _documentLibraries(librariesToDocument, includeSdk: includeSdk,
            outputToYaml: outputToYaml, append: append, parseSdk: parseSdk,
            introFileName: introFileName, startPage: startPage);
        return true;
      });
  }

  /// Writes [text] to a file in the output directory.
  static void _writeToFile(String text, String filename, {bool append: false}) {
    if (text == null) return;
    Directory dir = new Directory(_outputDirectory);
    if (!dir.existsSync()) {
      dir.createSync();
    }
    if (path.split(filename).length > 1) {
      var splitList = path.split(filename);
      for (int i = 0; i < splitList.length; i++) {
        var level = splitList[i];
      }
      for (var level in path.split(filename)) {
        var subdir = new Directory(path.join(_outputDirectory,
                                             path.dirname(filename)));
        if (!subdir.existsSync()) {
          subdir.createSync();
        }
      }
    }
    File file = new File(path.join(_outputDirectory, filename));
    file.writeAsStringSync(text,
        mode: append ? FileMode.APPEND : FileMode.WRITE);
  }

  /// Resolve all the links in the introductory comments for a given library or
  /// package as specified by [filename].
  static String _readIntroductionFile(String fileName, bool includeSdk) {
    var linkResolver = (name) => Indexable.globalFixReference(name);
    var defaultText = includeSdk ? _DEFAULT_SDK_INTRODUCTION : '';
    var introText = defaultText;
    if (fileName.isNotEmpty) {
      var introFile = new File(fileName);
      introText = introFile.existsSync() ? introFile.readAsStringSync() :
        defaultText;
    }
    return markdown.markdownToHtml(introText,
        linkResolver: linkResolver, inlineSyntaxes: _MARKDOWN_SYNTAXES);
  }

  /// Creates documentation for filtered libraries.
  static void _documentLibraries(List<LibraryMirror> libs,
      {bool includeSdk: false, bool outputToYaml: true, bool append: false,
       bool parseSdk: false, String introFileName: '', String startPage}) {
    libs.forEach((lib) {
      // Files belonging to the SDK have a uri that begins with 'dart:'.
      if (includeSdk || !lib.uri.toString().startsWith('dart:')) {
        var library = generateLibrary(lib);
      }
    });

    var filteredEntities = new Set<Indexable>();
    for (Map<String, Set<Indexable>> firstLevel in
        Indexable._mirrorToDocgen.values) {
      for (Set<Indexable> items in firstLevel.values) {
        for (Indexable item in items) {
          if (_isFullChainVisible(item)) {
            if (item is! Method ||
                (item is Method && item.methodInheritedFrom == null)) {
              filteredEntities.add(item);
            }
          }
        }
      }
    }

    // Outputs a JSON file with all libraries and their preview comments.
    // This will help the viewer know what libraries are available to read in.
    var libraryMap;

    if (append) {
      var docsDir = listDir(_outputDirectory);
      if (!docsDir.contains('$_outputDirectory/library_list.json')) {
        throw new StateError('No library_list.json');
      }
      libraryMap =
          JSON.decode(new File(
              '$_outputDirectory/library_list.json').readAsStringSync());
      libraryMap['libraries'].addAll(filteredEntities
          .where((e) => e is Library)
          .map((e) => e.previewMap));
      var intro = libraryMap['introduction'];
      var spacing = intro.isEmpty ? '' : '<br/><br/>';
      libraryMap['introduction'] =
          "$intro$spacing${_readIntroductionFile(introFileName, includeSdk)}";
      outputToYaml = libraryMap['filetype'] == 'yaml';
    } else {
      libraryMap = {
        'libraries' : filteredEntities.where((e) =>
            e is Library).map((e) => e.previewMap).toList(),
        'introduction' : _readIntroductionFile(introFileName, includeSdk),
        'filetype' : outputToYaml ? 'yaml' : 'json'
      };
    }
    _writeOutputFiles(libraryMap, filteredEntities, outputToYaml, append,
        startPage);
  }

  /// Output all of the libraries and classes into json or yaml files for
  /// consumption by a viewer.
  static void _writeOutputFiles(libraryMap,
      Iterable<Indexable> filteredEntities, bool outputToYaml, bool append,
      String startPage) {
    if (startPage != null) libraryMap['start-page'] = startPage;

    _writeToFile(JSON.encode(libraryMap), 'library_list.json');

    // Output libraries and classes to file after all information is generated.
    filteredEntities.where((e) => e is Class || e is Library).forEach((output) {
      _writeIndexableToFile(output, outputToYaml);
    });

    // Outputs all the qualified names documented with their type.
    // This will help generate search results.
    var sortedEntities = filteredEntities.map((e) =>
        '${e.qualifiedName} ${e.typeName}').toList()..sort();

    _writeToFile(sortedEntities.join('\n') + '\n',
        'index.txt', append: append);
    var index = new Map.fromIterables(
        filteredEntities.map((e) => e.qualifiedName),
        filteredEntities.map((e) => e.typeName));
    if (append) {
      var previousIndex =
          JSON.decode(new File(
              '$_outputDirectory/index.json').readAsStringSync());
      index.addAll(previousIndex);
    }
    _writeToFile(JSON.encode(index), 'index.json');
  }

  /// Helper method to serialize the given Indexable out to a file.
  static void _writeIndexableToFile(Indexable result, bool outputToYaml) {
    var outputFile = result.fileName;
    var output;
    if (outputToYaml) {
      output = getYamlString(result.toMap());
      outputFile = outputFile + '.yaml';
    } else {
      output = JSON.encode(result.toMap());
      outputFile = outputFile + '.json';
    }
    _writeToFile(output, outputFile);
  }

  /// Set the location of the ouput directory, and ensure that the location is
  /// available on the file system.
  static void _ensureOutputDirectory(String outputDirectory, bool append) {
    _outputDirectory = outputDirectory;
    if (!append) {
      var dir = new Directory(_outputDirectory);
      if (dir.existsSync()) dir.deleteSync(recursive: true);
     }
  }

  /// Helper accessor to determine the full pathname of the root of the dart
  /// checkout. We can be in one of three situations:
  /// 1) Running from pkg/docgen/bin/docgen.dart
  /// 2) Running from a snapshot in a build,
  ///   e.g. xcodebuild/ReleaseIA32/dart-sdk/bin
  /// 3) Running from a built distribution,
  ///   e.g. ...somename/dart-sdk/bin/snapshots
  static String get _rootDirectory {
    var scriptDir = path.absolute(path.dirname(Platform.script.toFilePath()));
    var root = scriptDir;
    var base = path.basename(root);
    // When we find dart-sdk or sdk we are one level below the root.
    while (base != 'dart-sdk' && base != 'sdk' && base != 'pkg') {
      root = path.dirname(root);
      base = path.basename(root);
      if (root == base) {
        // We have reached the root of the filesystem without finding anything.
        throw new FileSystemException(
            "Cannot find SDK directory starting from ",
            scriptDir);
        }
    }
    return path.dirname(root);
  }

  /// Analyzes set of libraries and provides a mirror system which can be used
  /// for static inspection of the source code.
  static Future<MirrorSystem> _analyzeLibraries(List<Uri> libraries,
        String libraryRoot, {String packageRoot}) {
    SourceFileProvider provider = new CompilerSourceFileProvider();
    api.DiagnosticHandler diagnosticHandler =
        (new FormattingDiagnosticHandler(provider)
          ..showHints = false
          ..showWarnings = false)
            .diagnosticHandler;
    Uri libraryUri = new Uri.file(appendSlash(libraryRoot));
    Uri packageUri = null;
    if (packageRoot != null) {
      packageUri = new Uri.file(appendSlash(packageRoot));
    }
    return dart2js.analyze(libraries, libraryUri, packageUri,
        provider.readStringFromUri, diagnosticHandler,
        ['--preserve-comments', '--categories=Client,Server'])
        ..catchError((error) {
          logger.severe('Error: Failed to create mirror system. ');
          // TODO(janicejl): Use the stack trace package when bug is resolved.
          // Currently, a string is thrown when it fails to create a mirror
          // system, and it is not possible to use the stack trace. BUG(#11622)
          // To avoid printing the stack trace.
          exit(1);
        });
  }

  /// For this run of docgen, determine the packageRoot value.
  ///
  /// If packageRoot is not explicitly passed, we examine the files we're
  /// documenting to attempt to find a package root.
  static String _obtainPackageRoot(String packageRoot, bool parseSdk,
      List<String> files) {
    if (packageRoot == null && !parseSdk) {
      var type = FileSystemEntity.typeSync(files.first);
      if (type == FileSystemEntityType.DIRECTORY) {
        var files2 = listDir(files.first, recursive: true);
        // Return '' means that there was no pubspec.yaml and therefor no p
        // ackageRoot.
        packageRoot = files2.firstWhere((f) =>
            f.endsWith('${path.separator}pubspec.yaml'), orElse: () => '');
        if (packageRoot != '') {
          packageRoot = path.join(path.dirname(packageRoot), 'packages');
        }
      } else if (type == FileSystemEntityType.FILE) {
        logger.warning('WARNING: No package root defined. If Docgen fails, try '
            'again by setting the --package-root option.');
      }
     }
    logger.info('Package Root: ${packageRoot}');
    return path.normalize(path.absolute(packageRoot));
  }

  /// Given the user provided list of items to document, expand all directories
  /// to document out into specific files and add any dependent packages for
  /// documentation if desired.
  static List<Uri> _findLibrariesToDocument(List<String> args,
      bool includeDependentPackages) {
    if (includeDependentPackages) {
      args.addAll(_allDependentPackageDirs(args.first));
    }

    var libraries = new List<Uri>();
    for (var arg in args) {
      if (FileSystemEntity.typeSync(arg) == FileSystemEntityType.FILE) {
        if (arg.endsWith('.dart')) {
          libraries.add(new Uri.file(path.absolute(arg)));
          logger.info('Added to libraries: ${libraries.last}');
        }
      } else {
        libraries.addAll(_findFilesToDocumentInPackage(arg));
      }
    }
    return libraries;
  }

  /// Given a package name, explore the directory and pull out all top level
  /// library files in the "lib" directory to document.
  static List<Uri> _findFilesToDocumentInPackage(String packageName) {
    var libraries = [];
    // To avoid anaylzing package files twice, only files with paths not
    // containing '/packages' will be added. The only exception is if the file
    // to analyze already has a '/package' in its path.
    var files = listDir(packageName, recursive: true).where(
        (f) => f.endsWith('.dart') && (!f.contains('${path.separator}packages')
            || packageName.contains('${path.separator}packages'))).toList();

    files.forEach((String f) {
      // Only include libraries at the top level of "lib"
      if (path.basename(path.dirname(f)) == 'lib') {
        // Only add the file if it does not contain 'part of'
        // TODO(janicejl): Remove when Issue(12406) is resolved.
        var contents = new File(f).readAsStringSync();
        if (!(contents.contains(new RegExp('\npart of ')) ||
            contents.startsWith(new RegExp('part of ')))) {
          libraries.add(new Uri.file(path.normalize(path.absolute(f))));
          logger.info('Added to libraries: $f');
        }
      }
    });
    return libraries;
  }

  /// All of the directories for our dependent packages
  /// If this is not a package, return an empty list.
  static List<String> _allDependentPackageDirs(String packageDirectory) {
    var packageName = Library.packageNameFor(packageDirectory);
    if (packageName == '') return [];
    var dependentsJson = Process.runSync(_pubScript, ['list-package-dirs'],
        workingDirectory: packageDirectory, runInShell: true);
    if (dependentsJson.exitCode != 0) {
      print(dependentsJson.stderr);
     }
    var dependents = JSON.decode(dependentsJson.stdout)['packages'];
    return dependents.values.toList();
  }

  /// For all the libraries, return a list of the libraries that are part of
  /// the SDK.
  static List<Uri> _listSdk() {
    var sdk = new List<Uri>();
    LIBRARIES.forEach((String name, LibraryInfo info) {
      if (info.documented) {
        sdk.add(Uri.parse('dart:$name'));
        logger.info('Add to SDK: ${sdk.last}');
      }
    });
    return sdk;
  }

  /// Return true if this item and all of its owners are all visible.
  static bool _isFullChainVisible(Indexable item) {
    return _includePrivate || (!item.isPrivate && (item.owner != null ?
        _isFullChainVisible(item.owner) : true));
  }

  /// Currently left public for testing purposes. :-/
  static Library generateLibrary(dart2js_mirrors.Dart2JsLibraryMirror library) {
    var result = new Library(library);
    result._findPackage(library);
    logger.fine('Generated library for ${result.name}');
    return result;
  }
}

/// Convenience methods wrapped up in a class to pull down the docgen viewer for
/// a viewable website, and start up a server for viewing.
class _Viewer {
  static String _dartdocViewerString = path.join(Directory.current.path,
      'dartdoc-viewer');
  static Directory _dartdocViewerDir = new Directory(_dartdocViewerString);
  static Directory _topLevelTempDir;
  static Directory _webDocsDir;
  static bool movedViewerCode = false;

  static String _viewerCodePath;

  /*
   * dartdoc-viewer currently has the web app code under a 'client' directory
   *
   * This is confusing for folks that want to clone and modify the code.
   * It also includes a number of python files and other content related to
   * app engine hosting that are not needed.
   *
   * This logic exists to support the current model and a (future) updated
   * dartdoc-viewer repo where the 'client' content exists at the root of the
   * project and the other content is removed.
   */
  static String get viewerCodePath {
    if(_viewerCodePath == null) {
      var pubspecFileName = 'pubspec.yaml';

      var thePath = _dartdocViewerDir.path;

      if(!FileSystemEntity.isFileSync(path.join(thePath, pubspecFileName))) {
        thePath = path.join(thePath, 'client');
        if (!FileSystemEntity.isFileSync(path.join(thePath, pubspecFileName))) {
          throw new StateError('Could not find a pubspec file');
        }
      }

      _viewerCodePath = thePath;
    }
    return _viewerCodePath;
  }

  /// If our dartdoc-viewer code is already checked out, move it to a temporary
  /// directory outside of the package directory, so we don't try to process it
  /// for documentation.
  static void ensureMovedViewerCode() {
    // TODO(efortuna): This will need to be modified to run on anyone's package
    // outside of the checkout!
    if (_dartdocViewerDir.existsSync()) {
      _topLevelTempDir = new Directory(
          _Generator._rootDirectory).createTempSync();
      _dartdocViewerDir.renameSync(_topLevelTempDir.path);
    }
  }

  /// Move the dartdoc-viewer code back into place for "webpage deployment."
  static void addBackViewerCode() {
    if (movedViewerCode) _dartdocViewerDir.renameSync(_dartdocViewerString);
  }

  /// Serve up our generated documentation for viewing in a browser.
  static void _clone() {
    // If the viewer code is already there, then don't clone again.
    if (_dartdocViewerDir.existsSync()) {
      _moveDirectoryAndServe();
    }
    else {
      var processResult = Process.runSync('git', ['clone', '-b', 'master',
          'git://github.com/dart-lang/dartdoc-viewer.git'],
          runInShell: true);

      if (processResult.exitCode == 0) {
        /// Move the generated json/yaml docs directory to the dartdoc-viewer
        /// directory, to run as a webpage.
        var processResult = Process.runSync(_Generator._pubScript,
            ['upgrade'], runInShell: true,
            workingDirectory: viewerCodePath);
        print('process output: ${processResult.stdout}');
        print('process stderr: ${processResult.stderr}');

        var dir = new Directory(_Generator._outputDirectory == null? 'docs' :
            _Generator._outputDirectory);
        _webDocsDir = new Directory(path.join(viewerCodePath, 'web', 'docs'));
        if (dir.existsSync()) {
          // Move the docs folder to dartdoc-viewer/client/web/docs
          dir.renameSync(_webDocsDir.path);
        }
      } else {
        print('Error cloning git repository:');
        print('process output: ${processResult.stdout}');
        print('process stderr: ${processResult.stderr}');
      }
    }
  }

  /// Move the generated json/yaml docs directory to the dartdoc-viewer
  /// directory, to run as a webpage.
  static void _moveDirectoryAndServe() {
    var processResult = Process.runSync(_Generator._pubScript, ['upgrade'],
        runInShell: true, workingDirectory: path.join(_dartdocViewerDir.path,
        'client'));
    print('process output: ${processResult.stdout}');
    print('process stderr: ${processResult.stderr}');

    var dir = new Directory(_Generator._outputDirectory == null? 'docs' :
        _Generator._outputDirectory);
    var webDocsDir = new Directory(path.join(_dartdocViewerDir.path, 'client',
        'web', 'docs'));
    if (dir.existsSync()) {
      // Move the docs folder to dartdoc-viewer/client/web/docs
      dir.renameSync(webDocsDir.path);
    }

    if (webDocsDir.existsSync()) {
      // Compile the code to JavaScript so we can run on any browser.
      print('Compile app to JavaScript for viewing.');
      var processResult = Process.runSync(_Generator._dartBinary,
          ['deploy.dart'], workingDirectory : path.join(_dartdocViewerDir.path,
          'client'), runInShell: true);
      print('process output: ${processResult.stdout}');
      print('process stderr: ${processResult.stderr}');
      _runServer();
    }
  }

  static void _compile() {
    if (_webDocsDir.existsSync()) {
      // Compile the code to JavaScript so we can run on any browser.
      print('Compile app to JavaScript for viewing.');
      var processResult = Process.runSync(_Generator._dartBinary,
          ['deploy.dart'], workingDirectory: viewerCodePath, runInShell: true);
      print('process output: ${processResult.stdout}');
      print('process stderr: ${processResult.stderr}');
      var outputDir = path.join(viewerCodePath, 'out', 'web');
      print('Docs are available at $outputDir');
    }
  }

  /// A simple HTTP server. Implemented here because this is part of the SDK,
  /// so it shouldn't have any external dependencies.
  static void _runServer() {
    // Launch a server to serve out of the directory dartdoc-viewer/client/web.
    HttpServer.bind(InternetAddress.ANY_IP_V6, 8080).then((HttpServer httpServer) {
      print('Server launched. Navigate your browser to: '
          'http://localhost:${httpServer.port}');
      httpServer.listen((HttpRequest request) {
        var response = request.response;
        var basePath = path.join(viewerCodePath, 'out', 'web');
        var requestPath = path.join(basePath, request.uri.path.substring(1));
        bool found = true;
        var file = new File(requestPath);
        if (file.existsSync()) {
          // Set the correct header type.
          if (requestPath.endsWith('.html')) {
            response.headers.set('Content-Type', 'text/html');
          } else if (requestPath.endsWith('.js')) {
            response.headers.set('Content-Type', 'application/javascript');
          } else if (requestPath.endsWith('.dart')) {
            response.headers.set('Content-Type', 'application/dart');
          } else if (requestPath.endsWith('.css')) {
            response.headers.set('Content-Type', 'text/css');
          }
        } else {
          if (requestPath == basePath) {
            response.headers.set('Content-Type', 'text/html');
            file = new File(path.join(basePath, 'index.html'));
          } else {
            print('Path not found: $requestPath');
            found = false;
            response.statusCode = HttpStatus.NOT_FOUND;
            response.close();
          }
        }

        if (found) {
          // Serve up file contents.
          file.openRead().pipe(response).catchError((e) {
            print('HttpServer: error while closing the response stream $e');
          });
        }
      },
      onError: (e) {
        print('HttpServer: an error occured $e');
      });
    });
  }
}

/// An item that is categorized in our mirrorToDocgen map, as a distinct,
/// searchable element.
///
/// These are items that refer to concrete entities (a Class, for example,
/// but not a Type, which is a "pointer" to a class) that we wish to be
/// globally resolvable. This includes things such as class methods and
/// variables, but parameters for methods are not "Indexable" as we do not want
/// the user to be able to search for a method based on its parameter names!
/// The set of indexable items also includes Typedefs, since the user can refer
/// to them as concrete entities in a particular scope.
abstract class Indexable extends MirrorBased {
  /// The dart:core library, which contains all types that are always available
  /// without import.
  static Library _coreLibrary;

  /// Set of libraries declared in the SDK, so libraries that can be accessed
  /// when running dart by default.
  static Iterable<LibraryMirror> _sdkLibraries;

  String get qualifiedName => fileName;
  bool isPrivate;
  DeclarationMirror mirror;
  /// The comment text pre-resolution. We keep this around because inherited
  /// methods need to resolve links differently from the superclass.
  String _unresolvedComment = '';

  // TODO(janicejl): Make MDN content generic or pluggable. Maybe move
  // MDN-specific code to its own library that is imported into the default
  // impl?
  /// Map of all the comments for dom elements from MDN.
  static Map _mdn;

  /// Index of all the dart2js mirrors examined to corresponding MirrorBased
  /// docgen objects.
  ///
  /// Used for lookup because of the dart2js mirrors exports
  /// issue. The second level map is indexed by owner docName for faster lookup.
  /// Why two levels of lookup? Speed, man. Speed.
  static Map<String, Map<String, Set<Indexable>>> _mirrorToDocgen =
      new Map<String, Map<String, Set<Indexable>>>();

  Indexable(this.mirror) {
    this.isPrivate = _isHidden(mirror);

    var map = _mirrorToDocgen[dart2js_util.qualifiedNameOf(this.mirror)];
    if (map == null) map = new Map<String, Set<Indexable>>();

    var set = map[owner.docName];
    if (set == null) set = new Set<Indexable>();
    set.add(this);
    map[owner.docName] = set;
    _mirrorToDocgen[dart2js_util.qualifiedNameOf(this.mirror)] = map;
  }

  /** Walk up the owner chain to find the owning library. */
  Library _getOwningLibrary(Indexable indexable) {
    if (indexable is Library) return indexable;
    return _getOwningLibrary(indexable.owner);
  }

  static _initializeTopLevelLibraries(MirrorSystem mirrorSystem) {
    _sdkLibraries = mirrorSystem.libraries.values.where(
        (each) => each.uri.scheme == 'dart');
    _coreLibrary = new Library(_sdkLibraries.singleWhere((lib) =>
        lib.uri.toString().startsWith('dart:core')));
  }

  /// Returns this object's qualified name, but following the conventions
  /// we're using in Dartdoc, which is that library names with dots in them
  /// have them replaced with hyphens.
  String get docName;

  /// Converts all [foo] references in comments to <a>libraryName.foo</a>.
  markdown.Node fixReference(String name) {
    // Attempt the look up the whole name up in the scope.
    String elementName = findElementInScope(name);
    if (elementName != null) {
      return new markdown.Element.text('a', elementName);
    }
    return _fixComplexReference(name);
  }

  /// Look for the specified name starting with the current member, and
  /// progressively working outward to the current library scope.
  String findElementInScope(String name) =>
      _findElementInScope(name, packagePrefix);

  /// For a given name, determine if we need to resolve it as a qualified name
  /// or a simple name in the source mirors.
  static determineLookupFunc(name) => name.contains('.') ?
      dart2js_util.lookupQualifiedInScope :
        (mirror, name) => mirror.lookupInScope(name);

  /// The reference to this element based on where it is printed as a
  /// documentation file and also the unique URL to refer to this item.
  ///
  /// The qualified name (for URL purposes) and the file name are the same,
  /// of the form packageName/ClassName or packageName/ClassName.methodName.
  /// This defines both the URL and the directory structure.
  String get fileName =>  packagePrefix + ownerPrefix + name;

  /// The full docName of the owner element, appended with a '.' for this
  /// object's name to be appended.
  String get ownerPrefix => owner.docName != '' ? owner.docName + '.' : '';

  /// The prefix String to refer to the package that this item is in, for URLs
  /// and comment resolution.
  ///
  /// The prefix can be prepended to a qualified name to get a fully unique
  /// name among all packages.
  String get packagePrefix => '';

  /// Documentation comment with converted markdown and all links resolved.
  String _comment;

  /// Accessor to documentation comment with markdown converted to html and all
  /// links resolved.
  String get comment {
    if (_comment != null) return _comment;

    _comment = _commentToHtml();
    if (_comment.isEmpty) {
      _comment = _mdnComment();
    }
    return _comment;
  }

  set comment(x) => _comment = x;

  /// The simple name to refer to this item.
  String get name => dart2js_util.nameOf(mirror);

  /// Accessor to the parent item that owns this item.
  ///
  /// "Owning" is defined as the object one scope-level above which this item
  /// is defined. Ex: The owner for a top level class, would be its enclosing
  /// library. The owner of a local variable in a method would be the enclosing
  /// method.
  Indexable get owner => new DummyMirror(mirror.owner);

  /// Generates MDN comments from database.json.
  String _mdnComment();

  /// Generates the MDN Comment for variables and method DOM elements.
  String _mdnMemberComment(String type, String member) {
    var mdnType = _mdn[type];
    if (mdnType == null) return '';
    var mdnMember = mdnType['members'].firstWhere((e) => e['name'] == member,
        orElse: () => null);
    if (mdnMember == null) return '';
    if (mdnMember['help'] == null || mdnMember['help'] == '') return '';
    if (mdnMember['url'] == null) return '';
    return _htmlifyMdn(mdnMember['help'], mdnMember['url']);
  }

  /// Generates the MDN Comment for class DOM elements.
  String _mdnTypeComment(String type) {
    var mdnType = _mdn[type];
    if (mdnType == null) return '';
    if (mdnType['summary'] == null || mdnType['summary'] == "") return '';
    if (mdnType['srcUrl'] == null) return '';
    return _htmlifyMdn(mdnType['summary'], mdnType['srcUrl']);
  }

  /// Encloses the given content in an MDN div and the original source link.
  String _htmlifyMdn(String content, String url) {
    return '<div class="mdn">' + content.trim() + '<p class="mdn-note">'
        '<a href="' + url.trim() + '">from Mdn</a></p></div>';
  }

  /// The type of this member to be used in index.txt.
  String get typeName => '';

  /// Creates a [Map] with this [Indexable]'s name and a preview comment.
  Map get previewMap {
    var finalMap = { 'name' : name, 'qualifiedName' : qualifiedName };
    var preview = _preview;
    if(preview != null) finalMap['preview'] = preview;
    return finalMap;
  }

  String get _preview {
    if (comment != '') {
      var index = comment.indexOf('</p>');
      return index > 0 ?
          '${comment.substring(0, index)}</p>' :
          '<p><i>Comment preview not available</i></p>';
    }
    return null;
  }

  /// Accessor to obtain the raw comment text for a given item, _without_ any
  /// of the links resolved.
  String get _commentText {
    String commentText;
    mirror.metadata.forEach((metadata) {
      if (metadata is CommentInstanceMirror) {
        CommentInstanceMirror comment = metadata;
        if (comment.isDocComment) {
          if (commentText == null) {
            commentText = comment.trimmedText;
          } else {
            commentText = '$commentText\n${comment.trimmedText}';
          }
        }
      }
    });
    return commentText;
  }

  /// Returns any documentation comments associated with a mirror with
  /// simple markdown converted to html.
  ///
  /// By default we resolve any comment references within our own scope.
  /// However, if a method is inherited, we want the inherited comments, but
  /// links to the subclasses's version of the methods.
  String _commentToHtml([Indexable resolvingScope]) {
    if (resolvingScope == null) resolvingScope = this;
    var commentText = _commentText;
    _unresolvedComment = commentText;

    var linkResolver = (name) => resolvingScope.fixReference(name);
    commentText = commentText == null ? '' :
        markdown.markdownToHtml(commentText.trim(), linkResolver: linkResolver,
            inlineSyntaxes: _MARKDOWN_SYNTAXES);
    return commentText;
  }

  /// Returns a map of [Variable] objects constructed from [mirrorMap].
  /// The optional parameter [containingLibrary] is contains data for variables
  /// defined at the top level of a library (potentially for exporting
  /// purposes).
  Map<String, Variable> _createVariables(Iterable<VariableMirror> mirrors,
      Indexable owner) {
    var data = {};
    // TODO(janicejl): When map to map feature is created, replace the below
    // with a filter. Issue(#9590).
    mirrors.forEach((VariableMirror mirror) {
      if (_Generator._includePrivate || !_isHidden(mirror)) {
        var mirrorName = dart2js_util.nameOf(mirror);
        data[mirrorName] = new Variable(mirrorName, mirror, owner);
      }
    });
    return data;
  }

  /// Returns a map of [Method] objects constructed from [mirrorMap].
  /// The optional parameter [containingLibrary] is contains data for variables
  /// defined at the top level of a library (potentially for exporting
  /// purposes).
  Map<String, Method> _createMethods(Iterable<MethodMirror> mirrors,
      Indexable owner) {
    var group = new Map<String, Method>();
    mirrors.forEach((MethodMirror mirror) {
      if (_Generator._includePrivate || !mirror.isPrivate) {
        group[dart2js_util.nameOf(mirror)] = new Method(mirror, owner);
      }
    });
    return group;
  }

  /// Returns a map of [Parameter] objects constructed from [mirrorList].
  Map<String, Parameter> _createParameters(List<ParameterMirror> mirrorList,
      Indexable owner) {
    var data = {};
    mirrorList.forEach((ParameterMirror mirror) {
      data[dart2js_util.nameOf(mirror)] =
          new Parameter(mirror, _getOwningLibrary(owner));
    });
    return data;
  }

  /// Returns a map of [Generic] objects constructed from the class mirror.
  Map<String, Generic> _createGenerics(TypeMirror mirror) {
    return new Map.fromIterable(mirror.typeVariables,
        key: (e) => dart2js_util.nameOf(e),
        value: (e) => new Generic(e));
  }

  /// Return an informative [Object.toString] for debugging.
  String toString() => "${super.toString()}(${name.toString()})";

  /// Return a map representation of this type.
  Map toMap();

  /// A declaration is private if itself is private, or the owner is private.
  // Issue(12202) - A declaration is public even if it's owner is private.
  bool _isHidden(DeclarationMirror mirror) {
    if (mirror is LibraryMirror) {
      return _isLibraryPrivate(mirror);
    } else if (mirror.owner is LibraryMirror) {
      return (mirror.isPrivate || _isLibraryPrivate(mirror.owner)
          || mirror.isNameSynthetic);
    } else {
      return (mirror.isPrivate || _isHidden(mirror.owner)
          || owner.mirror.isNameSynthetic);
    }
  }

  /// Returns true if a library name starts with an underscore, and false
  /// otherwise.
  ///
  /// An example that starts with _ is _js_helper.
  /// An example that contains ._ is dart._collection.dev
  bool _isLibraryPrivate(LibraryMirror mirror) {
    // This method is needed because LibraryMirror.isPrivate returns `false` all
    // the time.
    var sdkLibrary = LIBRARIES[dart2js_util.nameOf(mirror)];
    if (sdkLibrary != null) {
      return !sdkLibrary.documented;
    } else if (dart2js_util.nameOf(mirror).startsWith('_') ||
        dart2js_util.nameOf(mirror).contains('._')) {
      return true;
    }
    return false;
  }

  ////// Top level resolution functions
  /// Converts all [foo] references in comments to <a>libraryName.foo</a>.
  static markdown.Node globalFixReference(String name) {
    // Attempt the look up the whole name up in the scope.
    String elementName = _findElementInScope(name, '');
    if (elementName != null) {
      return new markdown.Element.text('a', elementName);
    }
    return _fixComplexReference(name);
  }

  /// This is a more complex reference. Try to break up if its of the form A<B>
  /// where A is an alphanumeric string and B is an A, a list of B ("B, B, B"),
  /// or of the form A<B>. Note: unlike other the other markdown-style links,
  /// all text inside the square brackets is treated as part of the link (aka
  /// the * is interpreted literally as a *, not as a indicator for bold <em>.
  ///
  /// Example: [foo&lt;_bar_>] will produce
  /// <a>resolvedFoo</a>&lt;<a>resolved_bar_</a>> rather than an italicized
  /// version of resolvedBar.
  static markdown.Node _fixComplexReference(String name) {
    // Parse into multiple elements we can try to resolve.
    var tokens = _tokenizeComplexReference(name);

    // Produce an html representation of our elements. Group unresolved and
    // plain text are grouped into "link" elements so they display as code.
    final textElements = [' ', ',', '>', _LESS_THAN];
    var accumulatedHtml = '';

    for (var token in tokens) {
      bool added = false;
      if (!textElements.contains(token)) {
        String elementName = _findElementInScope(token, '');
        if (elementName != null) {
          accumulatedHtml += markdown.renderToHtml([new markdown.Element.text(
              'a', elementName)]);
          added = true;
        }
      }
      if (!added) {
        accumulatedHtml += token;
       }
     }
    return new markdown.Text(accumulatedHtml);
  }


  // HTML escaped version of '<' character.
  static final _LESS_THAN = '&lt;';

  /// Chunk the provided name into individual parts to be resolved. We take a
  /// simplistic approach to chunking, though, we break at " ", ",", "&lt;"
  /// and ">". All other characters are grouped into the name to be resolved.
  /// As a result, these characters will all be treated as part of the item to
  /// be resolved (aka the * is interpreted literally as a *, not as an
  /// indicator for bold <em>.
  static List<String> _tokenizeComplexReference(String name) {
    var tokens = [];
    var append = false;
    var index = 0;
    while(index < name.length) {
      if (name.indexOf(_LESS_THAN, index) == index) {
        tokens.add(_LESS_THAN);
        append = false;
        index += _LESS_THAN.length;
      } else if (name[index] == ' ' || name[index] == ',' ||
          name[index] == '>') {
        tokens.add(name[index]);
        append = false;
        index++;
      } else {
        if (append) {
          tokens[tokens.length - 1] = tokens.last + name[index];
        } else {
          tokens.add(name[index]);
          append = true;
        }
        index++;
      }
    }
    return tokens;
  }

  static String _findElementInScope(String name, String packagePrefix) {
    var lookupFunc = determineLookupFunc(name);
    // Look in the dart core library scope.
    var coreScope = _coreLibrary == null? null :
        lookupFunc(_coreLibrary.mirror, name);
    if (coreScope != null) return packagePrefix + _coreLibrary.docName;

    // If it's a reference that starts with a another library name, then it
    // looks for a match of that library name in the other sdk libraries.
    if(name.contains('.')) {
      var index = name.indexOf('.');
      var libraryName = name.substring(0, index);
      var remainingName = name.substring(index + 1);
      foundLibraryName(library) => library.uri.pathSegments[0] == libraryName;

      if (_sdkLibraries.any(foundLibraryName)) {
        var library = _sdkLibraries.singleWhere(foundLibraryName);
        // Look to see if it's a fully qualified library name.
        var scope = determineLookupFunc(remainingName)(library, remainingName);
        if (scope != null) {
          var result = getDocgenObject(scope);
          if (result is DummyMirror) {
            return packagePrefix + result.docName;
          } else {
            return result.packagePrefix + result.docName;
          }
        }
      }
     }
    return null;
  }

  /// Expand the method map [mapToExpand] into a more detailed map that
  /// separates out setters, getters, constructors, operators, and methods.
  Map _expandMethodMap(Map<String, Method> mapToExpand) => {
    'setters': recurseMap(_filterMap(mapToExpand,
        (key, val) => val.mirror.isSetter)),
    'getters': recurseMap(_filterMap(mapToExpand,
        (key, val) => val.mirror.isGetter)),
    'constructors': recurseMap(_filterMap(mapToExpand,
        (key, val) => val.mirror.isConstructor)),
    'operators': recurseMap(_filterMap(mapToExpand,
        (key, val) => val.mirror.isOperator)),
    'methods': recurseMap(_filterMap(mapToExpand,
        (key, val) => val.mirror.isRegularMethod && !val.mirror.isOperator))
  };

  /// Transforms the map by calling toMap on each value in it.
  Map recurseMap(Map inputMap) {
    var outputMap = {};
    inputMap.forEach((key, value) {
      if (value is Map) {
        outputMap[key] = recurseMap(value);
      } else {
        outputMap[key] = value.toMap();
      }
    });
    return outputMap;
  }

  Map _filterMap(Map map, Function test) {
    var exported = new Map();
    map.forEach((key, value) {
      if (test(key, value)) exported[key] = value;
    });
    return exported;
  }

  /// Accessor to determine if this item and all of its owners are visible.
  bool get _isVisible => _Generator._isFullChainVisible(this);

  /// Given a Dart2jsMirror, find the corresponding Docgen [MirrorBased] object.
  ///
  /// We have this global lookup function to avoid re-implementing looking up
  /// the scoping rules for comment resolution here (it is currently done in
  /// mirrors). If no corresponding MirrorBased object is found, we return a
  /// [DummyMirror] that simply returns the original mirror's qualifiedName
  /// while behaving like a MirrorBased object.
  static Indexable getDocgenObject(DeclarationMirror mirror,
    [Indexable owner]) {
    Map<String, Set<Indexable>> docgenObj =
        _mirrorToDocgen[dart2js_util.qualifiedNameOf(mirror)];
    if (docgenObj == null) {
      return new DummyMirror(mirror, owner);
    }

    var setToExamine = new Set();
    if (owner != null) {
      var firstSet = docgenObj[owner.docName];
      if (firstSet != null) setToExamine.addAll(firstSet);
      if (_coreLibrary != null &&
          docgenObj[_coreLibrary.docName] != null) {
        setToExamine.addAll(docgenObj[_coreLibrary.docName]);
      }
    } else {
      for (var value in docgenObj.values) {
        setToExamine.addAll(value);
      }
    }

    Set<Indexable> results = new Set<Indexable>();
    for(Indexable indexable in setToExamine) {
      if (indexable.mirror.qualifiedName == mirror.qualifiedName &&
          indexable._isValidMirror(mirror)) {
        results.add(indexable);
      }
    }

    if (results.length > 0) {
      // This might occur if we didn't specify an "owner."
      return results.first;
    }
    return new DummyMirror(mirror, owner);
  }

  /// Returns true if [mirror] is the correct type of mirror that this Docgen
  /// object wraps. (Workaround for the fact that Types are not first class.)
  bool _isValidMirror(DeclarationMirror mirror);
}

/// A class containing contents of a Dart library.
class Library extends Indexable {

  /// Top-level variables in the library.
  Map<String, Variable> variables;

  /// Top-level functions in the library.
  Map<String, Method> functions;

  Map<String, Class> classes = {};
  Map<String, Typedef> typedefs = {};
  Map<String, Class> errors = {};

  String packageName = '';
  bool _hasBeenCheckedForPackage = false;
  String packageIntro;

  /// Returns the [Library] for the given [mirror] if it has already been
  /// created, else creates it.
  factory Library(LibraryMirror mirror) {
    var library = Indexable.getDocgenObject(mirror);
    if (library is DummyMirror) {
      library = new Library._(mirror);
    }
    return library;
  }

  Library._(LibraryMirror libraryMirror) : super(libraryMirror) {
    var exported = _calcExportedItems(libraryMirror);
    var exportedClasses = _addAll(exported['classes'],
        dart2js_util.typesOf(libraryMirror.declarations));
    _findPackage(mirror);
    classes = {};
    typedefs = {};
    errors = {};
    exportedClasses.forEach((String mirrorName, TypeMirror mirror) {
        if (mirror is TypedefMirror) {
          // This is actually a Dart2jsTypedefMirror, and it does define value,
          // but we don't have visibility to that type.
          if (_Generator._includePrivate || !mirror.isPrivate) {
            typedefs[dart2js_util.nameOf(mirror)] = new Typedef(mirror, this);
          }
        } else if (mirror is ClassMirror) {
          var clazz = new Class(mirror, this);

          if (clazz.isError()) {
            errors[dart2js_util.nameOf(mirror)] = clazz;
          } else {
            classes[dart2js_util.nameOf(mirror)] = clazz;
          }
        } else {
          throw new ArgumentError(
              '${dart2js_util.nameOf(mirror)} - no class type match. ');
        }
    });
    this.functions = _createMethods(_addAll(exported['methods'],
        libraryMirror.declarations.values.where(
            (mirror) => mirror is MethodMirror)).values, this);
    this.variables = _createVariables(_addAll(exported['variables'],
        dart2js_util.variablesOf(libraryMirror.declarations)).values, this);
  }

  /// Look for the specified name starting with the current member, and
  /// progressively working outward to the current library scope.
  String findElementInScope(String name) {
    var lookupFunc = Indexable.determineLookupFunc(name);
    var libraryScope = lookupFunc(mirror, name);
    if (libraryScope != null) {
      var result = Indexable.getDocgenObject(libraryScope, this);
      if (result is DummyMirror) return packagePrefix + result.docName;
      return result.packagePrefix + result.docName;
    }
    return super.findElementInScope(name);
  }

  String _mdnComment() => '';

  /// Helper that maps [mirrors] to their simple name in map.
  Map _addAll(Map map, Iterable<DeclarationMirror> mirrors) {
    for (var mirror in mirrors) {
      map[dart2js_util.nameOf(mirror)] = mirror;
    }
    return map;
  }

  /// For a library's [mirror], determine the name of the package (if any) we
  /// believe it came from (because of its file URI).
  ///
  /// If no package could be determined, we return an empty string.
  String _findPackage(LibraryMirror mirror) {
    if (mirror == null) return '';
    if (_hasBeenCheckedForPackage) return packageName;
    _hasBeenCheckedForPackage = true;
    if (mirror.uri.scheme != 'file') return '';
    packageName = _packageName(mirror);
    // Associate the package readme with all the libraries. This is a bit
    // wasteful, but easier than trying to figure out which partial match
    // is best.
    packageIntro = _packageIntro(_getPackageDirectory(mirror));
    return packageName;
  }

  String _packageIntro(packageDir) {
    if (packageDir == null) return null;
    var dir = new Directory(packageDir);
    var files = dir.listSync();
    var readmes = files.where((FileSystemEntity each) => (each is File &&
        each.path.substring(packageDir.length + 1, each.path.length)
          .startsWith('README'))).toList();
    if (readmes.isEmpty) return '';
    // If there are multiples, pick the shortest name.
    readmes.sort((a, b) => a.path.length.compareTo(b.path.length));
    var readme = readmes.first;
    var linkResolver = (name) => Indexable.globalFixReference(name);
    var contents = markdown.markdownToHtml(readme
      .readAsStringSync(), linkResolver: linkResolver,
      inlineSyntaxes: _MARKDOWN_SYNTAXES);
    return contents;
  }

  /// Given a LibraryMirror that is a library, return the name of the directory
  /// holding the package information for that library. If the library is not
  /// part of a package, return null.
  static String _getPackageDirectory(LibraryMirror mirror) {
    var file = mirror.uri.toFilePath();
    // Any file that's in a package will be in a directory of the form
    // packagename/lib/.../filename.dart, so we know that a possible
    // package directory is at least in the directory above the one containing
    // [file]
    var directoryAbove = path.dirname(path.dirname(file));
    var possiblePackage = _packageDirectoryFor(directoryAbove);
    // We only want components that are somewhere underneath the lib directory.
    var subPath = path.relative(file, from: possiblePackage);
    var subPathComponents = path.split(subPath);
    if (subPathComponents.isNotEmpty && subPathComponents.first == 'lib') {
      return possiblePackage;
    } else {
      return null;
    }
  }

  /// Read a pubspec and return the library name given a [LibraryMirror].
  static String _packageName(LibraryMirror mirror) {
    if (mirror.uri.scheme != 'file') return '';
    var rootdir = _getPackageDirectory(mirror);
    if (rootdir == null) return '';
    return packageNameFor(rootdir);
  }

  /// Recursively walk up from directory name looking for a pubspec. Return
  /// the directory that contains it, or null if none is found.
  static String _packageDirectoryFor(String directoryName) {
    var dir = directoryName;
    while (!_pubspecFor(dir).existsSync()) {
      var newDir = path.dirname(dir);
      if (newDir == dir) return null;
      dir = newDir;
    }
    return dir;
  }

  static File _pubspecFor(String directoryName) =>
      new File(path.join(directoryName, 'pubspec.yaml'));

  /// Read a pubspec and return the library name, given a directory
  static String packageNameFor(String directoryName) {
    var pubspecName = path.join(directoryName, 'pubspec.yaml');
    File pubspec = new File(pubspecName);
    if (!pubspec.existsSync()) return '';
    var contents = pubspec.readAsStringSync();
    var spec = loadYaml(contents);
    return spec["name"];
  }

  String get packagePrefix => packageName == null || packageName.isEmpty ?
      '' : '$packageName/';

  Map get previewMap {
    var basic = super.previewMap;
    basic['packageName'] = packageName;
    if (packageIntro != null) {
      basic['packageIntro'] = packageIntro;
    }
    return basic;
  }

  String get name => docName;

  String get docName {
    return dart2js_util.qualifiedNameOf(mirror).replaceAll('.','-');
  }

  /// For the given library determine what items (if any) are exported.
  ///
  /// Returns a Map with three keys: "classes", "methods", and "variables" the
  /// values of which point to a map of exported name identifiers with values
  /// corresponding to the actual DeclarationMirror.
  Map<String, Map<String, DeclarationMirror>> _calcExportedItems(
      LibrarySourceMirror library) {
    var exports = {};
    exports['classes'] = {};
    exports['methods'] = {};
    exports['variables'] = {};

    // Determine the classes, variables and methods that are exported for a
    // specific dependency.
    _populateExports(LibraryDependencyMirror export, bool showExport) {
      if (!showExport) {
        // Add all items, and then remove the hidden ones.
        // Ex: "export foo hide bar"
        _addAll(exports['classes'],
            dart2js_util.typesOf(export.targetLibrary.declarations));
        _addAll(exports['methods'],
            export.targetLibrary.declarations.values.where(
                (mirror) => mirror is MethodMirror));
        _addAll(exports['variables'],
            dart2js_util.variablesOf(export.targetLibrary.declarations));
      }
      for (CombinatorMirror combinator in export.combinators) {
        for (String identifier in combinator.identifiers) {
          DeclarationMirror declaration =
              export.targetLibrary.lookupInScope(identifier);
          if (declaration == null) {
            // Technically this should be a bug, but some of our packages
            // (such as the polymer package) are curently broken in this
            // way, so we just produce a warning.
            print('Warning identifier $identifier not found in library '
                '${dart2js_util.qualifiedNameOf(export.targetLibrary)}');
          } else {
            var subMap = exports['classes'];
            if (declaration is MethodMirror) {
              subMap = exports['methods'];
            } else if (declaration is VariableMirror) {
              subMap = exports['variables'];
            }
            if (showExport) {
              subMap[identifier] = declaration;
            } else {
              subMap.remove(identifier);
            }
          }
        }
      }
    }

    Iterable<LibraryDependencyMirror> exportList =
        library.libraryDependencies.where((lib) => lib.isExport);
    for (LibraryDependencyMirror export in exportList) {
      // If there is a show in the export, add only the show items to the
      // library. Ex: "export foo show bar"
      // Otherwise, add all items, and then remove the hidden ones.
      // Ex: "export foo hide bar"
      _populateExports(export,
          export.combinators.any((combinator) => combinator.isShow));
    }
    return exports;
  }

  /// Checks if the given name is a key for any of the Class Maps.
  bool containsKey(String name) =>
      classes.containsKey(name) || errors.containsKey(name);

  /// Generates a map describing the [Library] object.
  Map toMap() => {
    'name': name,
    'qualifiedName': qualifiedName,
    'comment': comment,
    'variables': recurseMap(variables),
    'functions': _expandMethodMap(functions),
    'classes': {
      'class': classes.values.where((c) => c._isVisible)
        .map((e) => e.previewMap).toList(),
      'typedef': recurseMap(typedefs),
      'error': errors.values.where((e) => e._isVisible)
          .map((e) => e.previewMap).toList()
    },
    'packageName': packageName,
    'packageIntro' : packageIntro
  };

  String get typeName => 'library';

  bool _isValidMirror(DeclarationMirror mirror) => mirror is LibraryMirror;
}

abstract class OwnedIndexable extends Indexable {
  /// The object one scope-level above which this item is defined.
  ///
  /// Ex: The owner for a top level class, would be its enclosing library.
  /// The owner of a local variable in a method would be the enclosing method.
  Indexable owner;

  /// List of the meta annotations on this item.
  List<Annotation> annotations;

  /// Returns this object's qualified name, but following the conventions
  /// we're using in Dartdoc, which is that library names with dots in them
  /// have them replaced with hyphens.
  String get docName => owner.docName + '.' + dart2js_util.nameOf(mirror);

  OwnedIndexable(DeclarationMirror mirror, this.owner) : super(mirror);

  /// Generates MDN comments from database.json.
  String _mdnComment() {
    //Check if MDN is loaded.
    if (Indexable._mdn == null) {
      // Reading in MDN related json file.
      var root = _Generator._rootDirectory;
      var mdnPath = path.join(root, 'utils/apidoc/mdn/database.json');
      var mdnFile = new File(mdnPath);
      if (mdnFile.existsSync()) {
        Indexable._mdn = JSON.decode(mdnFile.readAsStringSync());
      } else {
        _Generator.logger.warning("Cannot find MDN docs expected at $mdnPath");
        Indexable._mdn = {};
      }
    }
    var domAnnotation = this.annotations.firstWhere(
        (e) => e.mirror.qualifiedName == #metadata.DomName,
        orElse: () => null);
    if (domAnnotation == null) return '';
    var domName = domAnnotation.parameters.single;
    var parts = domName.split('.');
    if (parts.length == 2) return _mdnMemberComment(parts[0], parts[1]);
    if (parts.length == 1) return _mdnTypeComment(parts[0]);

    throw new StateError('More than two items is not supported: $parts');
  }

  String get packagePrefix => owner.packagePrefix;
}

/// A class containing contents of a Dart class.
class Class extends OwnedIndexable implements Comparable {

  /// List of the names of interfaces that this class implements.
  List<Class> interfaces = [];

  /// Names of classes that extends or implements this class.
  Set<Class> subclasses = new Set<Class>();

  /// Top-level variables in the class.
  Map<String, Variable> variables;

  /// Inherited variables in the class.
  Map<String, Variable> inheritedVariables;

  /// Methods in the class.
  Map<String, Method> methods;

  Map<String, Method> inheritedMethods;

  /// Generic infomation about the class.
  Map<String, Generic> generics;

  Class superclass;
  bool isAbstract;

  /// Make sure that we don't check for inherited comments more than once.
  bool _commentsEnsured = false;

  /// Returns the [Class] for the given [mirror] if it has already been created,
  /// else creates it.
  factory Class(ClassMirror mirror, Library owner) {
    var clazz = Indexable.getDocgenObject(mirror, owner);
    if (clazz is DummyMirror) {
      clazz = new Class._(mirror, owner);
    }
    return clazz;
  }

  /// Called when we are constructing a superclass or interface class, but it
  /// is not known if it belongs to the same owner as the original class. In
  /// this case, we create an object whose owner is what the original mirror
  /// says it is.
  factory Class._possiblyDifferentOwner(ClassMirror mirror,
      Library originalOwner) {
    if (mirror.owner is LibraryMirror) {
      var realOwner = Indexable.getDocgenObject(mirror.owner);
      if (realOwner is Library) {
        return new Class(mirror, realOwner);
      } else {
        return new Class(mirror, originalOwner);
      }
    } else {
      return new Class(mirror, originalOwner);
    }
  }

  Class._(ClassSourceMirror classMirror, Indexable owner) :
      super(classMirror, owner) {
    inheritedVariables = {};

    // The reason we do this madness is the superclass and interface owners may
    // not be this class's owner!! Example: BaseClient in http pkg.
    var superinterfaces = classMirror.superinterfaces.map(
        (interface) => new Class._possiblyDifferentOwner(interface, owner));
    this.superclass = classMirror.superclass == null? null :
        new Class._possiblyDifferentOwner(classMirror.superclass, owner);

    interfaces = superinterfaces.toList();
    variables = _createVariables(
        dart2js_util.variablesOf(classMirror.declarations), this);
    methods = _createMethods(classMirror.declarations.values.where(
        (mirror) => mirror is MethodMirror), this);
    annotations = MirrorBased._createAnnotations(classMirror, _getOwningLibrary(owner));
    generics = _createGenerics(classMirror);
    isAbstract = classMirror.isAbstract;
    inheritedMethods = new Map<String, Method>();

    // Tell superclass that you are a subclass, unless you are not
    // visible or an intermediary mixin class.
    if (!classMirror.isNameSynthetic && _isVisible && superclass != null) {
      superclass.addSubclass(this);
    }

    if (this.superclass != null) addInherited(superclass);
    interfaces.forEach((interface) => addInherited(interface));
  }

  String _lookupInClassAndSuperclasses(String name) {
    var lookupFunc = Indexable.determineLookupFunc(name);
    var classScope = this;
    while (classScope != null) {
      var classFunc = lookupFunc(classScope.mirror, name);
      if (classFunc != null) {
        return packagePrefix + Indexable.getDocgenObject(classFunc, owner).docName;
      }
      classScope = classScope.superclass;
    }
    return null;
  }

  /// Look for the specified name starting with the current member, and
  /// progressively working outward to the current library scope.
  String findElementInScope(String name) {
    var lookupFunc = Indexable.determineLookupFunc(name);
    var result = _lookupInClassAndSuperclasses(name);
    if (result != null) {
      return result;
    }
    result = owner.findElementInScope(name);
    return result == null ? super.findElementInScope(name) : result;
  }

  String get typeName => 'class';

  /// Add all inherited variables and methods from the provided superclass.
  /// If [_includePrivate] is true, it also adds the variables and methods from
  /// the superclass.
  void addInherited(Class superclass) {
    inheritedVariables.addAll(superclass.inheritedVariables);
    inheritedVariables.addAll(_allButStatics(superclass.variables));
    addInheritedMethod(superclass, this);
  }

  /** [newParent] refers to the actual class is currently using these methods.
   * which may be different because with the mirror system, we only point to the
   * original canonical superclasse's method.
   */
  void addInheritedMethod(Class parent, Class newParent) {
    parent.inheritedMethods.forEach((name, method) {
      if(!method.mirror.isConstructor){
        inheritedMethods[name] = new Method(method.mirror, newParent, method);
      }}
    );
    _allButStatics(parent.methods).forEach((name, method) {
      if (!method.mirror.isConstructor) {
        inheritedMethods[name] = new Method(method.mirror, newParent, method);
      }}
    );
  }

  /// Remove statics from the map of inherited items before adding them.
  Map _allButStatics(Map items) {
    var result = {};
    items.forEach((name, item) {
      if (!item.isStatic) {
        result[name] = item;
      }
    });
    return result;
  }

  /// Add the subclass to the class.
  ///
  /// If [this] is private (or an intermediary mixin class), it will add the
  /// subclass to the list of subclasses in the superclasses.
  void addSubclass(Class subclass) {
    if (docName == 'dart-core.Object') return;

    if (!_Generator._includePrivate && isPrivate || mirror.isNameSynthetic) {
      if (superclass != null) superclass.addSubclass(subclass);
      interfaces.forEach((interface) {
        interface.addSubclass(subclass);
      });
    } else {
      subclasses.add(subclass);
    }
  }

  /// Check if this [Class] is an error or exception.
  bool isError() {
    if (qualifiedName == 'dart-core.Error' ||
        qualifiedName == 'dart-core.Exception')
      return true;
    for (var interface in interfaces) {
      if (interface.isError()) return true;
    }
    if (superclass == null) return false;
    return superclass.isError();
  }

  /// Makes sure that all methods with inherited equivalents have comments.
  void ensureComments() {
    if (_commentsEnsured) return;
    _commentsEnsured = true;
    if (superclass != null) superclass.ensureComments();
    inheritedMethods.forEach((qualifiedName, inheritedMethod) {
      var method = methods[qualifiedName];
      if (method != null) {
        // if we have overwritten this method in this class, we still provide
        // the opportunity to inherit the comments.
        method.ensureCommentFor(inheritedMethod);
      }
    });
    // we need to populate the comments for all methods. so that the subclasses
    // can get for their inherited versions the comments.
    methods.forEach((qualifiedName, method) {
      if (!method.mirror.isConstructor) method.ensureCommentFor(method);
    });
  }

  /// If a class extends a private superclass, find the closest public
  /// superclass of the private superclass.
  String validSuperclass() {
    if (superclass == null) return 'dart-core.Object';
    if (superclass._isVisible) return superclass.qualifiedName;
    return superclass.validSuperclass();
  }

  /// Generates a map describing the [Class] object.
  Map toMap() => {
    'name': name,
    'qualifiedName': qualifiedName,
    'comment': comment,
    'isAbstract' : isAbstract,
    'superclass': validSuperclass(),
    'implements': interfaces.where((i) => i._isVisible)
        .map((e) => e.qualifiedName).toList(),
    'subclass': (subclasses.toList()..sort())
        .map((x) => x.qualifiedName).toList(),
    'variables': recurseMap(variables),
    'inheritedVariables': recurseMap(inheritedVariables),
    'methods': _expandMethodMap(methods),
    'inheritedMethods': _expandMethodMap(inheritedMethods),
    'annotations': annotations.map((a) => a.toMap()).toList(),
    'generics': recurseMap(generics)
  };

  int compareTo(aClass) => name.compareTo(aClass.name);

  bool _isValidMirror(DeclarationMirror mirror) => mirror is ClassMirror;
}

class Typedef extends OwnedIndexable {
  String returnType;

  Map<String, Parameter> parameters;

  /// Generic information about the typedef.
  Map<String, Generic> generics;

  /// Returns the [Library] for the given [mirror] if it has already been
  /// created, else creates it.
  factory Typedef(TypedefMirror mirror, Library owningLibrary) {
    var aTypedef = Indexable.getDocgenObject(mirror, owningLibrary);
    if (aTypedef is DummyMirror) {
      aTypedef = new Typedef._(mirror, owningLibrary);
    }
    return aTypedef;
  }

  Typedef._(TypedefMirror mirror, Library owningLibrary) :
      super(mirror, owningLibrary) {
    returnType = Indexable.getDocgenObject(mirror.referent.returnType).docName;
    generics = _createGenerics(mirror);
    parameters = _createParameters(mirror.referent.parameters, owningLibrary);
    annotations = MirrorBased._createAnnotations(mirror, owningLibrary);
  }

  Map toMap() {
    var map = {
      'name': name,
      'qualifiedName': qualifiedName,
      'comment': comment,
      'return': returnType,
      'parameters': recurseMap(parameters),
      'annotations': annotations.map((a) => a.toMap()).toList(),
      'generics': recurseMap(generics)
    };

    // Typedef is displayed on the library page as a class, so a preview is
    // added manually
    var preview = _preview;
    if(preview != null) map['preview'] = preview;

    return map;
  }

  markdown.Node fixReference(String name) => null;

  String get typeName => 'typedef';

  bool _isValidMirror(DeclarationMirror mirror) => mirror is TypedefMirror;
}

/// A class containing properties of a Dart variable.
class Variable extends OwnedIndexable {

  bool isFinal;
  bool isStatic;
  bool isConst;
  Type type;
  String _variableName;

  factory Variable(String variableName, VariableMirror mirror,
      Indexable owner) {
    var variable = Indexable.getDocgenObject(mirror);
    if (variable is DummyMirror) {
      return new Variable._(variableName, mirror, owner);
    }
    return variable;
  }

  Variable._(this._variableName, VariableMirror mirror, Indexable owner) :
      super(mirror, owner) {
    isFinal = mirror.isFinal;
    isStatic = mirror.isStatic;
    isConst = mirror.isConst;
    type = new Type(mirror.type, _getOwningLibrary(owner));
    annotations = MirrorBased._createAnnotations(mirror, _getOwningLibrary(owner));
  }

  String get name => _variableName;

  /// Generates a map describing the [Variable] object.
  Map toMap() => {
    'name': name,
    'qualifiedName': qualifiedName,
    'comment': comment,
    'final': isFinal,
    'static': isStatic,
    'constant': isConst,
    'type': new List.filled(1, type.toMap()),
    'annotations': annotations.map((a) => a.toMap()).toList()
  };

  String get typeName => 'property';

  get comment {
    if (_comment != null) return _comment;
    if (owner is Class) {
      (owner as Class).ensureComments();
    }
    return super.comment;
  }

  String findElementInScope(String name) {
    var lookupFunc = Indexable.determineLookupFunc(name);
    var result = lookupFunc(mirror, name);
    if (result != null) {
      result = Indexable.getDocgenObject(result);
      if (result is DummyMirror) return packagePrefix + result.docName;
      return result.packagePrefix + result.docName;
    }

    if (owner != null) {
      var result = owner.findElementInScope(name);
      if (result != null) {
        return result;
      }
    }
    return super.findElementInScope(name);
  }

  bool _isValidMirror(DeclarationMirror mirror) => mirror is VariableMirror;
}

/// A class containing properties of a Dart method.
class Method extends OwnedIndexable {

  /// Parameters for this method.
  Map<String, Parameter> parameters;

  bool isStatic;
  bool isAbstract;
  bool isConst;
  Type returnType;
  Method methodInheritedFrom;

  /// Qualified name to state where the comment is inherited from.
  String commentInheritedFrom = "";

  factory Method(MethodMirror mirror, Indexable owner,
      [Method methodInheritedFrom]) {
    var method = Indexable.getDocgenObject(mirror, owner);
    if (method is DummyMirror) {
      method = new Method._(mirror, owner, methodInheritedFrom);
    }
    return method;
  }

  Method._(MethodMirror mirror, Indexable owner, this.methodInheritedFrom)
      : super(mirror, owner) {
    isStatic = mirror.isStatic;
    isAbstract = mirror.isAbstract;
    isConst = mirror.isConstConstructor;
    returnType = new Type(mirror.returnType, _getOwningLibrary(owner));
    parameters = _createParameters(mirror.parameters, owner);
    annotations = MirrorBased._createAnnotations(mirror, _getOwningLibrary(owner));
  }

  Method get originallyInheritedFrom => methodInheritedFrom == null ?
      this : methodInheritedFrom.originallyInheritedFrom;

  /// Look for the specified name starting with the current member, and
  /// progressively working outward to the current library scope.
  String findElementInScope(String name) {
    var lookupFunc = Indexable.determineLookupFunc(name);

    var memberScope = lookupFunc(this.mirror, name);
    if (memberScope != null) {
      // do we check for a dummy mirror returned here and look up with an owner
      // higher ooooor in getDocgenObject do we include more things in our
      // lookup
      var result = Indexable.getDocgenObject(memberScope, owner);
      if (result is DummyMirror && owner.owner != null
          && owner.owner is! DummyMirror) {
        var aresult = Indexable.getDocgenObject(memberScope, owner.owner);
        if (aresult is! DummyMirror) result = aresult;
      }
      if (result is DummyMirror) return packagePrefix + result.docName;
      return result.packagePrefix + result.docName;
    }

    if (owner != null) {
      var result = owner.findElementInScope(name);
      if (result != null) return result;
    }
    return super.findElementInScope(name);
  }

  String get docName {
    if ((mirror as MethodMirror).isConstructor) {
      // We name constructors specially -- including the class name again and a
      // "-" to separate the constructor from its name (if any).
      return '${owner.docName}.${dart2js_util.nameOf(mirror.owner)}-'
             '${dart2js_util.nameOf(mirror)}';
    }
    return super.docName;
  }

  String get fileName => packagePrefix + docName;

  /// Makes sure that the method with an inherited equivalent have comments.
  void ensureCommentFor(Method inheritedMethod) {
    if (comment.isNotEmpty) return;

    comment = inheritedMethod._commentToHtml(this);
    _unresolvedComment = inheritedMethod._unresolvedComment;
    commentInheritedFrom = inheritedMethod.commentInheritedFrom == '' ?
        new DummyMirror(inheritedMethod.mirror).docName :
        inheritedMethod.commentInheritedFrom;
  }

  /// Generates a map describing the [Method] object.
  Map toMap() => {
    'name': name,
    'qualifiedName': qualifiedName,
    'comment': comment,
    'commentFrom': (methodInheritedFrom != null &&
        commentInheritedFrom == methodInheritedFrom.docName ? ''
        : commentInheritedFrom),
    'inheritedFrom': (methodInheritedFrom == null? '' :
        originallyInheritedFrom.docName),
    'static': isStatic,
    'abstract': isAbstract,
    'constant': isConst,
    'return': new List.filled(1, returnType.toMap()),
    'parameters': recurseMap(parameters),
    'annotations': annotations.map((a) => a.toMap()).toList()
  };

  String get typeName {
    MethodMirror theMirror = mirror;
    if (theMirror.isConstructor) return 'constructor';
    if (theMirror.isGetter) return 'getter';
    if (theMirror.isSetter) return'setter';
    if (theMirror.isOperator) return 'operator';
    return 'method';
  }

  get comment {
    if (_comment != null) return _comment;
    if (owner is Class) {
      (owner as Class).ensureComments();
    }
    var result = super.comment;
    if (result == '' && methodInheritedFrom != null) {
      // This should be NOT from the MIRROR, but from the COMMENT.
      methodInheritedFrom.comment; // Ensure comment field has been populated.
      _unresolvedComment = methodInheritedFrom._unresolvedComment;

      var linkResolver = (name) => fixReference(name);
      comment = _unresolvedComment == null ? '' :
        markdown.markdownToHtml(_unresolvedComment.trim(),
            linkResolver: linkResolver, inlineSyntaxes: _MARKDOWN_SYNTAXES);
      commentInheritedFrom = comment != '' ?
          methodInheritedFrom.commentInheritedFrom : '';
      result = comment;
    }
    return result;
  }

  bool _isValidMirror(DeclarationMirror mirror) => mirror is MethodMirror;
}

/// Docgen wrapper around the dart2js mirror for a Dart
/// method/function parameter.
class Parameter extends MirrorBased {
  final ParameterMirror mirror;
  final String name;
  final bool isOptional;
  final bool isNamed;
  final bool hasDefaultValue;
  final Type type;
  final String defaultValue;
  /// List of the meta annotations on the parameter.
  final List<Annotation> annotations;

  Parameter(ParameterMirror mirror, Library owningLibrary)
      : this.mirror = mirror,
        name = dart2js_util.nameOf(mirror),
        isOptional = mirror.isOptional,
        isNamed = mirror.isNamed,
        hasDefaultValue = mirror.hasDefaultValue,
        defaultValue = '${mirror.defaultValue}',
        type = new Type(mirror.type, owningLibrary),
        annotations = MirrorBased._createAnnotations(mirror, owningLibrary);

  /// Generates a map describing the [Parameter] object.
  Map toMap() => {
    'name': name,
    'optional': isOptional,
    'named': isNamed,
    'default': hasDefaultValue,
    'type': new List.filled(1, type.toMap()),
    'value': defaultValue,
    'annotations': annotations.map((a) => a.toMap()).toList()
  };
}

/// A Docgen wrapper around the dart2js mirror for a generic type.
class Generic extends MirrorBased {
  final TypeVariableMirror mirror;
  Generic(this.mirror);
  Map toMap() => {
    'name': dart2js_util.nameOf(mirror),
    'type': dart2js_util.qualifiedNameOf(mirror.upperBound)
  };
}

/// Docgen wrapper around the mirror for a return type, and/or its generic
/// type parameters.
///
/// Return types are of a form [outer]<[inner]>.
/// If there is no [inner] part, [inner] will be an empty list.
///
/// For example:
///        int size()
///          "return" :
///            - "outer" : "dart-core.int"
///              "inner" :
///
///        List<String> toList()
///          "return" :
///            - "outer" : "dart-core.List"
///              "inner" :
///                - "outer" : "dart-core.String"
///                  "inner" :
///
///        Map<String, List<int>>
///          "return" :
///            - "outer" : "dart-core.Map"
///              "inner" :
///                - "outer" : "dart-core.String"
///                  "inner" :
///                - "outer" : "dart-core.List"
///                  "inner" :
///                    - "outer" : "dart-core.int"
///                      "inner" :
class Type extends MirrorBased {
  final TypeMirror mirror;
  final Library owningLibrary;

  Type(this.mirror, this.owningLibrary);

  /// Returns a list of [Type] objects constructed from TypeMirrors.
  List<Type> _createTypeGenerics(TypeMirror mirror) {
    if (mirror is ClassMirror) {
      var innerList = [];
      mirror.typeArguments.forEach((e) {
        innerList.add(new Type(e, owningLibrary));
      });
      return innerList;
    }
    return [];
  }

  Map toMap() {
    var result = Indexable.getDocgenObject(mirror, owningLibrary);
    return {
      // We may encounter types whose corresponding library has not been
      // processed yet, so look up with the owningLibrary at the last moment.
      'outer': result.packagePrefix + result.docName,
      'inner': _createTypeGenerics(mirror).map((e) => e.toMap()).toList(),
    };
  }
}

/// Holds the name of the annotation, and its parameters.
class Annotation extends MirrorBased {
  /// The class of this annotation.
  final ClassMirror mirror;
  final Library owningLibrary;
  List<String> parameters;

  Annotation(InstanceMirror originalMirror, this.owningLibrary)
      : mirror = originalMirror.type {
    parameters = dart2js_util.variablesOf(originalMirror.type.declarations)
        .where((e) => e.isFinal)
        .map((e) => originalMirror.getField(e.simpleName).reflectee)
        .where((e) => e != null)
        .toList();
  }

  Map toMap() => {
    'name': Indexable.getDocgenObject(mirror, owningLibrary).docName,
    'parameters': parameters
  };
}
