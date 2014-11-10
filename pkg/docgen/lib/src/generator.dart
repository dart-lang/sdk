// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library docgen.generator;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:markdown/markdown.dart' as markdown;
import 'package:path/path.dart' as path;

import 'package:compiler/compiler.dart' as api;
import 'package:compiler/src/filenames.dart';
import 'package:compiler/src/mirrors/analyze.dart'
    as dart2js;
import 'package:compiler/src/source_file_provider.dart';

import 'exports/dart2js_mirrors.dart' as dart2js_mirrors;
import 'exports/libraries.dart';
import 'exports/mirrors_util.dart' as dart2js_util;
import 'exports/source_mirrors.dart';

import 'io.dart';
import 'library_helpers.dart';
import 'models.dart';
import 'package_helpers.dart';

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
String pubScript;

/// The path of Dart binary.
String dartBinary;

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
Future<bool> generateDocumentation(List<String> files, {String packageRoot,
    bool outputToYaml: true, bool includePrivate: false, bool includeSdk: false,
    bool parseSdk: false, String introFileName: '',
    out: DEFAULT_OUTPUT_DIRECTORY, List<String> excludeLibraries: const [], bool
    includeDependentPackages: false, String startPage, String dartBinaryValue,
    String pubScriptValue, bool indentJSON: false}) {
  _excluded = excludeLibraries;
  dartBinary = dartBinaryValue;
  pubScript = pubScriptValue;

  logger.onRecord.listen((record) => print(record.message));

  _ensureOutputDirectory(out);
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
    _documentLibraries(librariesToDocument, includeSdk, parseSdk, introFileName,
        startPage, indentJSON);
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
  return analyzeLibraries(libraries, sdkRoot, packageRoot: packageRoot);
}

/// Writes [text] to a file in the output directory.
void _writeToFile(String text, String filename) {
  if (text == null) return;

  var filePath = path.join(_outputDirectory, filename);

  var parentDir = new Directory(path.dirname(filePath));
  if (!parentDir.existsSync()) parentDir.createSync(recursive: true);

  try {
    new File(filePath)
        .writeAsStringSync(text, mode: FileMode.WRITE);
  } on FileSystemException catch (e) {
    print('Failed to write to the path $filePath. Do you have write '
        'permissions to that directory? If not, please specify a different '
        'output directory using the --out option.');
    exit(1);
  }
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

int _indexableComparer(Indexable a, Indexable b) {
  if (a is Library && b is Library) {
    var compare = a.packageName.compareTo(b.packageName);
    if (compare == 0) {
      compare = a.name.compareTo(b.name);
    }
    return compare;
  }

  if (a is Library) return -1;
  if (b is Library) return 1;

  return a.qualifiedName.compareTo(b.qualifiedName);
}

/// Creates documentation for filtered libraries.
void _documentLibraries(List<LibraryMirror> libs, bool includeSdk,
  bool parseSdk, String introFileName, String startPage, bool indentJson) {
  libs.forEach((lib) {
    // Files belonging to the SDK have a uri that begins with 'dart:'.
    if (includeSdk || !lib.uri.toString().startsWith('dart:')) {
      generateLibrary(lib);
    }
  });

  var filteredEntities = new SplayTreeSet<Indexable>(_indexableComparer);
  for (Indexable item in allIndexables) {
    if (isFullChainVisible(item)) {
      if (item is! Method ||
          (item is Method && item.methodInheritedFrom == null)) {
        filteredEntities.add(item);
      }
    }
  }

  // Outputs a JSON file with all libraries and their preview comments.
  // This will help the viewer know what libraries are available to read in.
  Map<String, dynamic> libraryMap = {
      'libraries': filteredEntities.where((e) => e is Library).map((e) =>
          e.previewMap).toList(),
      'introduction': _readIntroductionFile(introFileName, includeSdk),
      'filetype': 'json',
      'sdkVersion': packageVersion(coreLibrary.mirror)
    };

  var encoder = new JsonEncoder.withIndent(indentJson ? '  ' : null);

  _writeOutputFiles(libraryMap, filteredEntities, startPage, encoder);
}

/// Output all of the libraries and classes into json files for consumption by a
/// viewer.
void _writeOutputFiles(Map<String, dynamic> libraryMap, Iterable<Indexable>
    filteredEntities, String startPage, JsonEncoder encoder) {
  if (startPage != null) libraryMap['start-page'] = startPage;

  _writeToFile(encoder.convert(libraryMap), 'library_list.json');

  // Output libraries and classes to file after all information is generated.
  filteredEntities.where((e) => e is Class || e is Library).forEach((output) {
    _writeIndexableToFile(output, encoder);
  });

  // Outputs all the qualified names documented with their type.
  // This will help generate search results.
  var sortedEntities = filteredEntities
      .map((e) => '${e.qualifiedName} ${e.typeName}')
      .toList();

  sortedEntities.sort();

  var buffer = new StringBuffer()
      ..writeAll(sortedEntities, '\n')
      ..write('\n');

  _writeToFile(buffer.toString(), 'index.txt');

  var index = new SplayTreeMap.fromIterable(filteredEntities,
      key: (e) => e.qualifiedName, value: (e) => e.typeName);

  _writeToFile(encoder.convert(index), 'index.json');
}

/// Helper method to serialize the given Indexable out to a file.
void _writeIndexableToFile(Indexable result, JsonEncoder encoder) {
  var outputFile = result.fileName + '.json';
  var output = encoder.convert(result.toMap());
  _writeToFile(output, outputFile);
}

/// Set the location of the ouput directory, and ensure that the location is
/// available on the file system.
void _ensureOutputDirectory(String outputDirectory) {
  _outputDirectory = outputDirectory;
  var dir = new Directory(_outputDirectory);
  if (dir.existsSync()) dir.deleteSync(recursive: true);
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
String _obtainPackageRoot(String packageRoot, bool parseSdk,
    List<String> files) {
  if (packageRoot == null && !parseSdk) {
    var type = FileSystemEntity.typeSync(files.first);
    if (type == FileSystemEntityType.DIRECTORY) {
      var files2 = listDir(files.first, recursive: true);
      // Return '' means that there was no pubspec.yaml and therefore no
      // packageRoot.
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
List<Uri> _findFilesToDocumentInPackage(String packageDir) {
  var libraries = [];
  // To avoid anaylzing package files twice, only files with paths not
  // containing '/packages' will be added. The only exception is if the file
  // to analyze already has a '/package' in its path.
  var files = listDir(packageDir, recursive: true, listDir: _packageDirList)
      .where((f) => f.endsWith('.dart') &&
        (!f.contains('${path.separator}packages') ||
            packageDir.contains('${path.separator}packages')))
      .toList();

  var packageLibDir = path.join(packageDir, 'lib');
  var packageLibSrcDir = path.join(packageLibDir, 'src');

  files.forEach((String lib) {
    // Only include libraries within the lib dir that are not in lib/src
    if (path.isWithin(packageLibDir, lib) &&
        !path.isWithin(packageLibSrcDir, lib)) {
      // Only add the file if it does not contain 'part of'
      // TODO(janicejl): Remove when Issue(12406) is resolved.
      var contents = new File(lib).readAsStringSync();


      if (contents.contains(new RegExp('\npart of ')) ||
          contents.startsWith(new RegExp('part of '))) {
        logger.warning('Skipping part "$lib". '
            'Part files should be in "lib/src".');
      } else {
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
  var dependentsJson = Process.runSync(pubScript, ['list-package-dirs'],
      workingDirectory: packageDirectory, runInShell: true);
  if (dependentsJson.exitCode != 0) {
    print(dependentsJson.stderr);
  }
  var dependents = JSON.decode(dependentsJson.stdout)['packages'];
  return dependents != null ? dependents.values.toList() : [];
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
// TODO(alanknight): It would be better if we could resolve the references to
// dart:core etc. at load-time in the viewer. dartbug.com/20112
const _DEFAULT_SDK_INTRODUCTION =
    """
Welcome to the Dart API reference documentation,
covering the official Dart API libraries.
Some of the most fundamental Dart libraries include:

* [dart:core](./dart:core):
  Core functionality such as strings, numbers, collections, errors,
  dates, and URIs.
* [dart:html](./dart:html):
  DOM manipulation for web apps.
* [dart:io](./dart:io):
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
