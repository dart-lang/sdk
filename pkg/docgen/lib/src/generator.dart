// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library docgen.generator;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:markdown/markdown.dart' as markdown;
import 'package:path/path.dart' as path;

import '../../../../sdk/lib/_internal/compiler/compiler.dart' as api;
import '../../../../sdk/lib/_internal/compiler/implementation/filenames.dart';
import '../../../../sdk/lib/_internal/compiler/implementation/mirrors/analyze.dart'
    as dart2js;
import '../../../../sdk/lib/_internal/compiler/implementation/mirrors/dart2js_mirrors.dart'
    as dart2js_mirrors;
import '../../../../sdk/lib/_internal/compiler/implementation/mirrors/mirrors_util.dart'
    as dart2js_util;
import '../../../../sdk/lib/_internal/compiler/implementation/mirrors/source_mirrors.dart';
import '../../../../sdk/lib/_internal/compiler/implementation/source_file_provider.dart';
import '../../../../sdk/lib/_internal/libraries.dart';

import 'dart2yaml.dart';
import 'io.dart';
import 'library_helpers.dart';
import 'models.dart';
import 'package_helpers.dart' show packageNameFor, rootDirectory;

const String DEFAULT_OUTPUT_DIRECTORY = 'docs';

/// The directory where the output docs are generated.
String get outputDirectory => _outputDirectory;
String _outputDirectory;

/// Library names to explicitly exclude.
///
///   Set from the command line option
/// --exclude-lib.
List<String> _excluded;

/// The path of the pub script.
String get pubScript => _pubScript;
String _pubScript;

/// The path of Dart binary.
String get dartBinary => _dartBinary;
String _dartBinary;

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
Future<bool> generateDocumentation(List<String> files, {String packageRoot, bool
    outputToYaml: true, bool includePrivate: false, bool includeSdk: false, bool
    parseSdk: false, bool append: false, String introFileName: '', out:
    DEFAULT_OUTPUT_DIRECTORY, List<String> excludeLibraries: const [], bool
    includeDependentPackages: false, String startPage, String dartBinary, String
    pubScript}) {
  _excluded = excludeLibraries;
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

  return getMirrorSystem(allLibraries, includePrivate,
      packageRoot: updatedPackageRoot, parseSdk: parseSdk)
      .then((MirrorSystem mirrorSystem) {
    if (mirrorSystem.libraries.isEmpty) {
      throw new StateError('No library mirrors were created.');
    }
    initializeTopLevelLibraries(mirrorSystem);

    var availableLibraries = mirrorSystem.libraries.values
        .where((each) => each.uri.scheme == 'file');
    var availableLibrariesByPath =
        new Map.fromIterables(availableLibraries.map((each) => each.uri),
            availableLibraries);
    var librariesToDocument = requestedLibraries
          .map((each) {
            return availableLibrariesByPath
                .putIfAbsent(each, () => throw "Missing library $each");
    }).toList();
    librariesToDocument.addAll((includeSdk || parseSdk) ? sdkLibraries : []);
    librariesToDocument.removeWhere((x) => _excluded.contains(
        dart2js_util.nameOf(x)));
    _documentLibraries(librariesToDocument, includeSdk: includeSdk,
        outputToYaml: outputToYaml, append: append, parseSdk: parseSdk,
        introFileName: introFileName, startPage: startPage);
    return true;
  });
}


/// Analyzes set of libraries by getting a mirror system and triggers the
/// documentation of the libraries.
Future<MirrorSystem> getMirrorSystem(List<Uri> libraries,
    bool includePrivate, {String packageRoot, bool parseSdk: false}) {
  if (libraries.isEmpty) throw new StateError('No Libraries.');

  includePrivateMembers = includePrivate;

  // Finds the root of SDK library based off the location of docgen.
  // We have two different places to look, depending if we're in a development
  // repo or in a built SDK, either sdk or dart-sdk respectively
  var root = rootDirectory;
  var sdkRoot = path.normalize(path.absolute(path.join(root, 'sdk')));
  if (!new Directory(sdkRoot).existsSync()) {
    sdkRoot = path.normalize(path.absolute(path.join(root, 'dart-sdk')));
  }
  logger.info('SDK Root: ${sdkRoot}');
  return analyzeLibraries(libraries, sdkRoot,
      packageRoot: packageRoot);
}

/// Writes [text] to a file in the output directory.
void _writeToFile(String text, String filename, {bool append: false}) {
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
      var subdir = new Directory(path.join(_outputDirectory, path.dirname(
          filename)));
      if (!subdir.existsSync()) {
        subdir.createSync();
      }
    }
  }
  File file = new File(path.join(_outputDirectory, filename));
  file.writeAsStringSync(text, mode: append ? FileMode.APPEND : FileMode.WRITE);
}

/// Resolve all the links in the introductory comments for a given library or
/// package as specified by [filename].
String _readIntroductionFile(String fileName, bool includeSdk) {
  var linkResolver = (name) => globalFixReference(name);
  var defaultText = includeSdk ? _DEFAULT_SDK_INTRODUCTION : '';
  var introText = defaultText;
  if (fileName.isNotEmpty) {
    var introFile = new File(fileName);
    introText = introFile.existsSync() ? introFile.readAsStringSync() :
        defaultText;
  }
  return markdown.markdownToHtml(introText, linkResolver: linkResolver,
      inlineSyntaxes: MARKDOWN_SYNTAXES);
}

/// Creates documentation for filtered libraries.
void _documentLibraries(List<LibraryMirror> libs, {bool includeSdk: false, bool
    outputToYaml: true, bool append: false, bool parseSdk: false, String
    introFileName: '', String startPage}) {
  libs.forEach((lib) {
    // Files belonging to the SDK have a uri that begins with 'dart:'.
    if (includeSdk || !lib.uri.toString().startsWith('dart:')) {
      generateLibrary(lib);
    }
  });

  var filteredEntities = new Set<Indexable>();
  for (Map<String, Set<Indexable>> firstLevel in mirrorToDocgen.values) {
    for (Set<Indexable> items in firstLevel.values) {
      for (Indexable item in items) {
        if (isFullChainVisible(item)) {
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
  Map<String, dynamic> libraryMap;

  if (append) {
    var docsDir = listDir(_outputDirectory);
    if (!docsDir.contains('$_outputDirectory/library_list.json')) {
      throw new StateError('No library_list.json');
    }
    libraryMap = JSON.decode(new File('$_outputDirectory/library_list.json'
        ).readAsStringSync());
    libraryMap['libraries'].addAll(filteredEntities.where((e) => e is Library
        ).map((e) => e.previewMap));
    var intro = libraryMap['introduction'];
    var spacing = intro.isEmpty ? '' : '<br/><br/>';
    libraryMap['introduction'] =
        "$intro$spacing${_readIntroductionFile(introFileName, includeSdk)}";
    outputToYaml = libraryMap['filetype'] == 'yaml';
  } else {
    libraryMap = {
      'libraries': filteredEntities.where((e) => e is Library).map((e) =>
          e.previewMap).toList(),
      'introduction': _readIntroductionFile(introFileName, includeSdk),
      'filetype': outputToYaml ? 'yaml' : 'json'
    };
  }
  _writeOutputFiles(libraryMap, filteredEntities, outputToYaml, append,
      startPage);
}

/// Output all of the libraries and classes into json or yaml files for
/// consumption by a viewer.
void _writeOutputFiles(Map<String, dynamic> libraryMap, Iterable<Indexable>
    filteredEntities, bool outputToYaml, bool append, String startPage) {
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

  _writeToFile(sortedEntities.join('\n') + '\n', 'index.txt', append: append);
  var index = new Map.fromIterables(filteredEntities.map((e) => e.qualifiedName
      ), filteredEntities.map((e) => e.typeName));
  if (append) {
    var previousIndex = JSON.decode(new File('$_outputDirectory/index.json'
        ).readAsStringSync());
    index.addAll(previousIndex);
  }
  _writeToFile(JSON.encode(index), 'index.json');
}

/// Helper method to serialize the given Indexable out to a file.
void _writeIndexableToFile(Indexable result, bool outputToYaml) {
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
void _ensureOutputDirectory(String outputDirectory, bool append) {
  _outputDirectory = outputDirectory;
  if (!append) {
    var dir = new Directory(_outputDirectory);
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  }
}

/// Analyzes set of libraries and provides a mirror system which can be used
/// for static inspection of the source code.
Future<MirrorSystem> analyzeLibraries(List<Uri> libraries, String
    libraryRoot, {String packageRoot}) {
  SourceFileProvider provider = new CompilerSourceFileProvider();
  api.DiagnosticHandler diagnosticHandler = (new FormattingDiagnosticHandler(
      provider)
      ..showHints = false
      ..showWarnings = false).diagnosticHandler;
  Uri libraryUri = new Uri.file(appendSlash(libraryRoot));
  Uri packageUri = null;
  if (packageRoot != null) {
    packageUri = new Uri.file(appendSlash(packageRoot));
  }
  return dart2js.analyze(libraries, libraryUri, packageUri,
      provider.readStringFromUri, diagnosticHandler, ['--preserve-comments',
      '--categories=Client,Server'])..catchError((error) {
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
String _obtainPackageRoot(String packageRoot, bool parseSdk, List<String> files)
    {
  if (packageRoot == null && !parseSdk) {
    var type = FileSystemEntity.typeSync(files.first);
    if (type == FileSystemEntityType.DIRECTORY) {
      var files2 = listDir(files.first, recursive: true);
      // Return '' means that there was no pubspec.yaml and therefor no p
      // ackageRoot.
      packageRoot = files2.firstWhere((f) => f.endsWith(
          '${path.separator}pubspec.yaml'), orElse: () => '');
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
List<Uri> _findLibrariesToDocument(List<String> args, bool
    includeDependentPackages) {
  if (includeDependentPackages) {
    args.addAll(_allDependentPackageDirs(args.first));
  }

  var libraries = new List<Uri>();
  for (var arg in args) {
    if (FileSystemEntity.typeSync(arg) == FileSystemEntityType.FILE) {
      if (arg.endsWith('.dart')) {
        var lib = new Uri.file(path.absolute(arg));
        libraries.add(lib);
        logger.info('Added to libraries: $lib');
      }
    } else {
      libraries.addAll(_findFilesToDocumentInPackage(arg));
    }
  }
  return libraries;
}

/// Given a package name, explore the directory and pull out all top level
/// library files in the "lib" directory to document.
List<Uri> _findFilesToDocumentInPackage(String packageName) {
  var libraries = [];
  // To avoid anaylzing package files twice, only files with paths not
  // containing '/packages' will be added. The only exception is if the file
  // to analyze already has a '/package' in its path.
  var files = listDir(packageName, recursive: true, listDir: _packageDirList)
      .where((f) => f.endsWith('.dart') &&
        (!f.contains('${path.separator}packages') ||
            packageName.contains('${path.separator}packages')))
      .toList();

  files.forEach((String lib) {
    // Only include libraries at the top level of "lib"
    if (path.basename(path.dirname(lib)) == 'lib') {
      // Only add the file if it does not contain 'part of'
      // TODO(janicejl): Remove when Issue(12406) is resolved.
      var contents = new File(lib).readAsStringSync();
      if (!(contents.contains(new RegExp('\npart of ')) ||
          contents.startsWith(new RegExp('part of ')))) {
        libraries.add(new Uri.file(path.normalize(path.absolute(lib))));
        logger.info('Added to libraries: $lib');
      }
    }
  });
  return libraries;
}

/// If [dir] contains both a `lib` directory and a `pubspec.yaml` file treat
/// it like a package and only return the `lib` dir.
///
/// This ensures that packages don't have non-`lib` content documented.
List<FileSystemEntity> _packageDirList(Directory dir) {
  var entities = dir.listSync();

  var pubspec = entities.firstWhere((e) => e is File &&
      path.basename(e.path) == 'pubspec.yaml', orElse: () => null);

  var libDir = entities.firstWhere((e) => e is Directory &&
      path.basename(e.path) == 'lib', orElse: () => null);

  if (pubspec != null && libDir != null) {
    return [libDir];
  } else {
    return entities;
  }
}

/// All of the directories for our dependent packages
/// If this is not a package, return an empty list.
List<String> _allDependentPackageDirs(String packageDirectory) {
  var packageName = packageNameFor(packageDirectory);
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
List<Uri> _listSdk() {
  var sdk = new List<Uri>();
  LIBRARIES.forEach((String name, LibraryInfo info) {
    if (info.documented) {
      sdk.add(Uri.parse('dart:$name'));
      logger.info('Add to SDK: ${sdk.last}');
    }
  });
  return sdk;
}

/// Currently left public for testing purposes. :-/
void generateLibrary(dart2js_mirrors.Dart2JsLibraryMirror library) {
  var result = new Library(library);
  result.updateLibraryPackage(library);
  logger.fine('Generated library for ${result.name}');
}


/// If we can't find the SDK introduction text, which will happen if running
/// from a snapshot and using --parse-sdk or --include-sdk, then use this
/// hard-coded version. This should be updated to be consistent with the text
/// in docgen/doc/sdk-introduction.md
const _DEFAULT_SDK_INTRODUCTION =
    """
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
