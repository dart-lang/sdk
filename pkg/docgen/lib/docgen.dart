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
import '../../../sdk/lib/_internal/compiler/implementation/mirrors/dart2js_mirror.dart'
    as dart2js;
import '../../../sdk/lib/_internal/compiler/implementation/mirrors/mirrors.dart';
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

// TODO(efortuna): The use of this field is odd (this is based on how it was
// originally used. Try to cleanup.
/// Index of all indexable items. This also ensures that no class is
/// created more than once.
Map<String, Indexable> entityMap = new Map<String, Indexable>();

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
Future<bool> docgen(List<String> files, {String packageRoot,
    bool outputToYaml: true, bool includePrivate: false, bool includeSdk: false,
    bool parseSdk: false, bool append: false, String introFileName: '',
    out: _DEFAULT_OUTPUT_DIRECTORY, List<String> excludeLibraries : const [],
    bool includeDependentPackages: false}) {
  return _Generator.generateDocumentation(files, packageRoot: packageRoot,
      outputToYaml: outputToYaml, includePrivate: includePrivate,
      includeSdk: includeSdk, parseSdk: parseSdk, append: append,
      introFileName: introFileName, out: out,
      excludeLibraries: excludeLibraries,
      includeDependentPackages: includeDependentPackages);
}

/// Analyzes set of libraries by getting a mirror system and triggers the
/// documentation of the libraries.
Future<MirrorSystem> getMirrorSystem(List<Uri> libraries,
    {String packageRoot, bool parseSdk: false}) {
  if (libraries.isEmpty) throw new StateError('No Libraries.');

  // Finds the root of SDK library based off the location of docgen.
  var root = _Generator._rootDirectory;
  var sdkRoot = path.normalize(path.absolute(path.join(root, 'sdk')));
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
      return mirror.qualifiedName.replaceAll('.','-');
    }
    var mirrorOwner = mirror.owner;
    if (mirrorOwner == null) return mirror.qualifiedName;
    var simpleName = mirror.simpleName;
    if (mirror is MethodMirror && (mirror as MethodMirror).isConstructor) {
      // We name constructors specially -- repeating the class name and a
      // "-" to separate the constructor from its name (if any).
      simpleName = '${mirrorOwner.simpleName}-$simpleName';
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
  DeclarationMirror get mirror;

  /// Returns a list of meta annotations assocated with a mirror.
  List<Annotation> _createAnnotations(DeclarationMirror mirror,
      Library owningLibrary) {
    var annotationMirrors = mirror.metadata.where((e) =>
        e is dart2js.Dart2JsConstructedConstantMirror);
    var annotations = [];
    annotationMirrors.forEach((annotation) {
      var docgenAnnotation = new Annotation(annotation, owningLibrary);
      if (!_SKIPPED_ANNOTATIONS.contains(
          docgenAnnotation.mirror.qualifiedName)) {
        annotations.add(docgenAnnotation);
      }
    });
    return annotations;
  }
}

class _Generator {
  static var _outputDirectory;

  /// This is set from the command line arguments flag --include-private
  static bool _includePrivate = false;

  /// Library names to explicitly exclude.
  ///
  ///   Set from the command line option
  /// --exclude-lib.
  static List<String> _excluded;

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
       bool includeDependentPackages: false}) {
    _excluded = excludeLibraries;
    _includePrivate = includePrivate;
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
        Indexable.initializeTopLevelLibraries(mirrorSystem);

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
            (x) => _excluded.contains(x.simpleName));
        _documentLibraries(librariesToDocument, includeSdk: includeSdk,
            outputToYaml: outputToYaml, append: append, parseSdk: parseSdk,
            introFileName: introFileName);
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

  /// Creates documentation for filtered libraries.
  static void _documentLibraries(List<LibraryMirror> libs,
      {bool includeSdk: false, bool outputToYaml: true, bool append: false,
       bool parseSdk: false, String introFileName: ''}) {
    libs.forEach((lib) {
      // Files belonging to the SDK have a uri that begins with 'dart:'.
      if (includeSdk || !lib.uri.toString().startsWith('dart:')) {
        var library = generateLibrary(lib);
        entityMap[library.name] = library;
      }
    });

    var filteredEntities = entityMap.values.where(_isFullChainVisible);

    /*var filteredEntities2 = new Set<MirrorBased>();
    for (Map<String, Set<MirrorBased>> firstLevel in mirrorToDocgen.values) {
      for (Set<MirrorBased> items in firstLevel.values) {
        for (MirrorBased item in items) {
          if (_isFullChainVisible(item)) {
            filteredEntities2.add(item);
          }
        }
      }
    }*/

    /*print('THHHHHEEE DIFFERENCE IS');
    var set1 = new Set.from(filteredEntities);
    var set2 = new Set.from(filteredEntities2);
    var aResult = set2.difference(set1);
    for (MirrorBased r in aResult) {
      print('     a result is $r and ${r.docName}');
    }*/
    //print(set1.difference(set2));

    // Outputs a JSON file with all libraries and their preview comments.
    // This will help the viewer know what libraries are available to read in.
    var libraryMap;
    var linkResolver = (name) => Indexable.globalFixReference(name);

    String readIntroductionFile(String fileName, includeSdk) {
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
          "$intro$spacing${readIntroductionFile(introFileName, includeSdk)}";
      outputToYaml = libraryMap['filetype'] == 'yaml';
    } else {
      libraryMap = {
        'libraries' : filteredEntities.where((e) =>
            e is Library).map((e) => e.previewMap).toList(),
        'introduction' : readIntroductionFile(introFileName, includeSdk),
        'filetype' : outputToYaml ? 'yaml' : 'json'
      };
    }
    _writeToFile(JSON.encode(libraryMap), 'library_list.json');

    // Output libraries and classes to file after all information is generated.
    filteredEntities.where((e) => e is Class || e is Library).forEach((output) {
      _writeIndexableToFile(output, outputToYaml);
    });

    // Outputs all the qualified names documented with their type.
    // This will help generate search results.
    _writeToFile(filteredEntities.map((e) =>
        '${e.qualifiedName} ${e.typeName}').join('\n') + '\n',
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


  static String get _rootDirectory {
    var scriptDir = path.absolute(path.dirname(Platform.script.toFilePath()));
    var root = scriptDir;
    while(path.basename(root) != 'dart') {
      root = path.dirname(root);
    }
    return root;
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
      // TODO(efortuna): This logic seems not very robust, but it's from the
      // original version of the code, pre-refactor, so I'm leavingt it for now.
      // Revisit to make more robust.
      // TODO(efortuna): See lines 303-311 in
      // https://codereview.chromium.org/116043013/diff/390001/pkg/docgen/lib/docgen.dart
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
  static List<String> _allDependentPackageDirs(String packageDirectory) {
    var dependentsJson = Process.runSync('pub', ['list-package-dirs'],
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

  static bool _isFullChainVisible(Indexable item) {
    // TODO: reconcile with isVisible.
    // TODO: Also should be able to take MirrorBased items in general probably.
    var result = _includePrivate || (!item.isPrivate && (item.owner != null ?
        _isFullChainVisible(item.owner) : true));
    return result;
  }

  /// Currently left public for testing purposes. :-/
  static Library generateLibrary(dart2js.Dart2JsLibraryMirror library) {
    var result = new Library(library);
    result._findPackage(library);
    logger.fine('Generated library for ${result.name}');
    return result;
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

    var map = _mirrorToDocgen[this.mirror.qualifiedName];
    if (map == null) map = new Map<String, Set<Indexable>>();

    var set = map[owner.docName];
    if (set == null) set = new Set<Indexable>();
    set.add(this);
    map[owner.docName] = set;
    _mirrorToDocgen[this.mirror.qualifiedName] = map;
  }

  /** Walk up the owner chain to find the owning library. */
  Library _getOwningLibrary(Indexable indexable) {
    if (indexable is Library) return indexable;
    return _getOwningLibrary(indexable.owner);
  }

  static initializeTopLevelLibraries(MirrorSystem mirrorSystem) {
    _sdkLibraries = mirrorSystem.libraries.values.where(
        (each) => each.uri.scheme == 'dart');
    _coreLibrary = new Library(_sdkLibraries.singleWhere((lib) =>
        lib.uri.toString().startsWith('dart:core')));
  }

  /// Returns this object's qualified name, but following the conventions
  /// we're using in Dartdoc, which is that library names with dots in them
  /// have them replaced with hyphens.
  String get docName;

  markdown.Node fixReferenceWithScope(String name) => null;

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

  static determineLookupFunc(name) => name.contains('.') ?
      dart2js_util.lookupQualifiedInScope :
        (mirror, name) => mirror.lookupInScope(name);

  // The qualified name (for URL purposes) and the file name are the same,
  // of the form packageName/ClassName or packageName/ClassName.methodName.
  // This defines both the URL and the directory structure.
  String get fileName {
    return packagePrefix + ownerPrefix + name;
  }

  String get ownerPrefix => owner.docName != '' ? owner.docName + '.' : '';

  String get packagePrefix => '';

  /// Documentation comment with converted markdown.
  String _comment;

  String get comment {
    if (_comment != null) return _comment;

    _comment = _commentToHtml();
    if (_comment.isEmpty) {
      _comment = _mdnComment();
    }
    return _comment;
  }

  set comment(x) => _comment = x;

  String get name => mirror.simpleName;

  Indexable get owner => new DummyMirror(mirror.owner);

  /// Generates MDN comments from database.json.
  String _mdnComment() {
    //Check if MDN is loaded.
    if (_mdn == null) {
      // Reading in MDN related json file.
      var root = _Generator._rootDirectory;
      var mdnPath = path.join(root, 'utils/apidoc/mdn/database.json');
      _mdn = JSON.decode(new File(mdnPath).readAsStringSync());
    }
    // TODO: refactor OOP
    if (this is Library) return '';
    var domAnnotation = this.annotations.firstWhere(
        (e) => e.mirror.qualifiedName == 'metadata.DomName',
        orElse: () => null);
    if (domAnnotation == null) return '';
    var domName = domAnnotation.parameters.single;
    var parts = domName.split('.');
    if (parts.length == 2) return _mdnMemberComment(parts[0], parts[1]);
    if (parts.length == 1) return _mdnTypeComment(parts[0]);
  }

  /// Generates the MDN Comment for variables and method DOM elements.
  String _mdnMemberComment(String type, String member) {
    var mdnType = _mdn[type];
    if (mdnType == null) return '';
    var mdnMember = mdnType['members'].firstWhere((e) => e['name'] == member,
        orElse: () => null);
    if (mdnMember == null) return '';
    if (mdnMember['help'] == null || mdnMember['help'] == '') return '';
    if (mdnMember['url'] == null) return '';
    return _htmlMdn(mdnMember['help'], mdnMember['url']);
  }

  /// Generates the MDN Comment for class DOM elements.
  String _mdnTypeComment(String type) {
    var mdnType = _mdn[type];
    if (mdnType == null) return '';
    if (mdnType['summary'] == null || mdnType['summary'] == "") return '';
    if (mdnType['srcUrl'] == null) return '';
    return _htmlMdn(mdnType['summary'], mdnType['srcUrl']);
  }

  String _htmlMdn(String content, String url) {
    return '<div class="mdn">' + content.trim() + '<p class="mdn-note">'
        '<a href="' + url.trim() + '">from Mdn</a></p></div>';
  }

  /// The type of this member to be used in index.txt.
  String get typeName => '';

  /// Creates a [Map] with this [Indexable]'s name and a preview comment.
  Map get previewMap {
    var finalMap = { 'name' : name, 'qualifiedName' : qualifiedName };
    if (comment != '') {
      var index = comment.indexOf('</p>');
      finalMap['preview'] = '${comment.substring(0, index)}</p>';
    }
    return finalMap;
  }

  String _getCommentText() {
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
    var commentText = _getCommentText();
    _unresolvedComment = commentText;

    var linkResolver = (name) => resolvingScope.fixReferenceWithScope(name);
    commentText = commentText == null ? '' :
        markdown.markdownToHtml(commentText.trim(), linkResolver: linkResolver,
            inlineSyntaxes: _MARKDOWN_SYNTAXES);
    return commentText;
  }

  /// Returns a map of [Variable] objects constructed from [mirrorMap].
  /// The optional parameter [containingLibrary] is contains data for variables
  /// defined at the top level of a library (potentially for exporting
  /// purposes).
  Map<String, Variable> _createVariables(Map<String, VariableMirror> mirrorMap,
      Indexable owner) {
    var data = {};
    // TODO(janicejl): When map to map feature is created, replace the below
    // with a filter. Issue(#9590).
    mirrorMap.forEach((String mirrorName, VariableMirror mirror) {
      if (_Generator._includePrivate || !_isHidden(mirror)) {
        var variable = new Variable(mirrorName, mirror, owner);
        entityMap[variable.docName] = variable;
        data[mirrorName] = entityMap[variable.docName];
      }
    });
    return data;
  }

  /// Returns a map of [Method] objects constructed from [mirrorMap].
  /// The optional parameter [containingLibrary] is contains data for variables
  /// defined at the top level of a library (potentially for exporting
  /// purposes).
  Map<String, Method> _createMethods(Map<String, MethodMirror> mirrorMap,
      Indexable owner) {
    var group = new Map<String, Method>();
    mirrorMap.forEach((String mirrorName, MethodMirror mirror) {
      if (_Generator._includePrivate || !mirror.isPrivate) {
        var method = new Method(mirror, owner);
        entityMap[method.docName] = method;
        group[mirror.simpleName] = method;
      }
    });
    return group;
  }

  /// Returns a map of [Parameter] objects constructed from [mirrorList].
  Map<String, Parameter> _createParameters(List<ParameterMirror> mirrorList,
      Indexable owner) {
    var data = {};
    mirrorList.forEach((ParameterMirror mirror) {
      data[mirror.simpleName] = new Parameter(mirror, _getOwningLibrary(owner));
    });
    return data;
  }

  /// Returns a map of [Generic] objects constructed from the class mirror.
  Map<String, Generic> _createGenerics(ClassMirror mirror) {
    return new Map.fromIterable(mirror.typeVariables,
        key: (e) => e.toString(),
        value: (e) => new Generic(e));
  }

  /// Return an informative [Object.toString] for debugging.
  String toString() => "${super.toString()}(${name.toString()})";

  /// Return a map representation of this type.
  Map toMap() {}


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
  // This is because LibraryMirror.isPrivate returns `false` all the time.
  bool _isLibraryPrivate(LibraryMirror mirror) {
    var sdkLibrary = LIBRARIES[mirror.simpleName];
    if (sdkLibrary != null) {
      return !sdkLibrary.documented;
    } else if (mirror.simpleName.startsWith('_') ||
        mirror.simpleName.contains('._')) {
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

  Map expandMethodMap(Map<String, Method> mapToExpand) => {
    'setters': recurseMap(_filterMap(new Map(), mapToExpand,
        (key, val) => val.mirror.isSetter)),
    'getters': recurseMap(_filterMap(new Map(), mapToExpand,
        (key, val) => val.mirror.isGetter)),
    'constructors': recurseMap(_filterMap(new Map(), mapToExpand,
        (key, val) => val.mirror.isConstructor)),
    'operators': recurseMap(_filterMap(new Map(), mapToExpand,
        (key, val) => val.mirror.isOperator)),
    'methods': recurseMap(_filterMap(new Map(), mapToExpand,
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

  Map _filterMap(exported, map, test) {
    map.forEach((key, value) {
      if (test(key, value)) exported[key] = value;
    });
    return exported;
  }

  bool get _isVisible => _Generator._includePrivate || !isPrivate;

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
        _mirrorToDocgen[mirror.qualifiedName];
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
  bool hasBeenCheckedForPackage = false;
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
    var exportedClasses = exported['classes']..addAll(libraryMirror.classes);
    _findPackage(mirror);
    classes = {};
    typedefs = {};
    errors = {};
    exportedClasses.forEach((String mirrorName, ClassMirror classMirror) {
        if (classMirror.isTypedef) {
          // This is actually a Dart2jsTypedefMirror, and it does define value,
          // but we don't have visibility to that type.
          var mirror = classMirror;
          if (_Generator._includePrivate || !mirror.isPrivate) {
            var aTypedef = new Typedef(mirror, this);
            entityMap[Indexable.getDocgenObject(mirror).docName] = aTypedef;
            typedefs[mirror.simpleName] = aTypedef;
          }
        } else {
          var clazz = new Class(classMirror, this);

          if (clazz.isError()) {
            errors[classMirror.simpleName] = clazz;
          } else if (classMirror.isClass) {
            classes[classMirror.simpleName] = clazz;
          } else {
            throw new ArgumentError(
                '${classMirror.simpleName} - no class type match. ');
          }
        }
    });
    this.functions =  _createMethods(exported['methods']
      ..addAll(libraryMirror.functions), this);
    this.variables = _createVariables(exported['variables']
      ..addAll(libraryMirror.variables), this);
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

  /// For a library's [mirror], determine the name of the package (if any) we
  /// believe it came from (because of its file URI).
  ///
  /// If no package could be determined, we return an empty string.
  String _findPackage(LibraryMirror mirror) {
    if (mirror == null) return '';
    if (hasBeenCheckedForPackage) return packageName;
    hasBeenCheckedForPackage = true;
    if (mirror.uri.scheme != 'file') return '';
    // We assume that we are documenting only libraries under package/lib
    packageName = _packageName(mirror);
    // Associate the package readme with all the libraries. This is a bit
    // wasteful, but easier than trying to figure out which partial match
    // is best.
    packageIntro = _packageIntro(_getRootdir(mirror));
    return packageName;
  }

  String _packageIntro(packageDir) {
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
  /// holding that library.
  static String _getRootdir(LibraryMirror mirror) =>
      path.dirname(path.dirname(mirror.uri.toFilePath()));

  /// Read a pubspec and return the library name.
  static String _packageName(LibraryMirror mirror) {
    if (mirror.uri.scheme != 'file') return '';
    var rootdir = _getRootdir(mirror);
    var pubspecName = path.join(rootdir, 'pubspec.yaml');
    File pubspec = new File(pubspecName);
    if (!pubspec.existsSync()) return '';
    var contents = pubspec.readAsStringSync();
    var spec = loadYaml(contents);
    return spec["name"];
  }

  markdown.Node fixReferenceWithScope(String name) => fixReference(name);

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

  String get docName => mirror.qualifiedName.replaceAll('.','-');

  /// For the given library determine what items (if any) are exported.
  ///
  /// Returns a Map with three keys: "classes", "methods", and "variables" the
  /// values of which point to a map of exported name identifiers with values
  /// corresponding to the actual DeclarationMirror.
  Map<String, Map<String, DeclarationMirror>> _calcExportedItems(
      LibraryMirror library) {
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
        exports['classes'].addAll(export.targetLibrary.classes);
        exports['methods'].addAll(export.targetLibrary.functions);
        exports['variables'].addAll(export.targetLibrary.variables);
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
                '${export.targetLibrary.qualifiedName}');
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
  bool containsKey(String name) {
    return classes.containsKey(name) || errors.containsKey(name);
  }

  /// Generates a map describing the [Library] object.
  Map toMap() => {
    'name': name,
    'qualifiedName': qualifiedName,
    'comment': comment,
    'variables': recurseMap(variables),
    'functions': expandMethodMap(functions),
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
  Indexable owner;

  /// Returns this object's qualified name, but following the conventions
  /// we're using in Dartdoc, which is that library names with dots in them
  /// have them replaced with hyphens.
  String get docName => owner.docName + '.' + mirror.simpleName;

  OwnedIndexable(DeclarationMirror mirror, this.owner) : super(mirror);
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

  /// List of the meta annotations on the class.
  List<Annotation> annotations;

  /// Make sure that we don't check for inherited comments more than once.
  bool _commentsEnsured = false;

  /// Returns the [Class] for the given [mirror] if it has already been created,
  /// else creates it.
  factory Class(ClassMirror mirror, Library owner) {
    var clazz = Indexable.getDocgenObject(mirror, owner);
    if (clazz is DummyMirror) {
      clazz = new Class._(mirror, owner);
      entityMap[clazz.docName] = clazz;
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

  Class._(ClassMirror classMirror, Indexable owner) :
      super(classMirror, owner) {
    inheritedVariables = {};

    // The reason we do this madness is the superclass and interface owners may
    // not be this class's owner!! Example: BaseClient in http pkg.
    var superinterfaces = classMirror.superinterfaces.map(
        (interface) => new Class._possiblyDifferentOwner(interface, owner));
    this.superclass = classMirror.superclass == null? null :
        new Class._possiblyDifferentOwner(classMirror.superclass, owner);

    interfaces = superinterfaces.toList();
    variables = _createVariables(classMirror.variables, this);
    methods = _createMethods(classMirror.methods, this);
    annotations = _createAnnotations(classMirror, _getOwningLibrary(owner));
    generics = _createGenerics(classMirror);
    isAbstract = classMirror.isAbstract;
    inheritedMethods = new Map<String, Method>();

    // Tell all superclasses that you are a subclass, unless you are not
    // visible or an intermediary mixin class.
    if (!classMirror.isNameSynthetic && _isVisible) {
      parentChain().forEach((parentClass) {
          parentClass.addSubclass(this);
      });
    }

    if (this.superclass != null) addInherited(superclass);
    interfaces.forEach((interface) => addInherited(interface));
  }

  String get packagePrefix => owner.packagePrefix;

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

  markdown.Node fixReferenceWithScope(String name) => fixReference(name);

  String get typeName => 'class';

  /// Returns a list of all the parent classes.
  List<Class> parentChain() {
    // TODO(efortuna): Seems like we can get rid of this method.
    var parent = superclass == null ? [] : [superclass];
    return parent;
  }

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
    if (superclass == null) return 'dart.core.Object';
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
    'methods': expandMethodMap(methods),
    'inheritedMethods': expandMethodMap(inheritedMethods),
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

  /// List of the meta annotations on the typedef.
  List<Annotation> annotations;

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
    returnType = Indexable.getDocgenObject(mirror.value.returnType).docName;
    generics = _createGenerics(mirror);
    parameters = _createParameters(mirror.value.parameters, owningLibrary);
    annotations = _createAnnotations(mirror, owningLibrary);
  }

  Map toMap() => {
    'name': name,
    'qualifiedName': qualifiedName,
    'comment': comment,
    'return': returnType,
    'parameters': recurseMap(parameters),
    'annotations': annotations.map((a) => a.toMap()).toList(),
    'generics': recurseMap(generics)
  };

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

  /// List of the meta annotations on the variable.
  List<Annotation> annotations;

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
    annotations = _createAnnotations(mirror, _getOwningLibrary(owner));
  }

  String get name => _variableName;

  /// Generates a map describing the [Variable] object.
  Map toMap() => {
    'name': name,
    'qualifiedName': qualifiedName,
    'comment': comment,
    'final': isFinal.toString(),
    'static': isStatic.toString(),
    'constant': isConst.toString(),
    'type': new List.filled(1, type.toMap()),
    'annotations': annotations.map((a) => a.toMap()).toList()
  };

  String get packagePrefix => owner.packagePrefix;

  String get typeName => 'property';

  get comment {
    if (_comment != null) return _comment;
    if (owner is Class) {
      (owner as Class).ensureComments();
    }
    return super.comment;
  }

  markdown.Node fixReferenceWithScope(String name) => fixReference(name);

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

  /// List of the meta annotations on the method.
  List<Annotation> annotations;

  factory Method(MethodMirror mirror, Indexable owner, // Indexable newOwner.
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
    annotations = _createAnnotations(mirror, _getOwningLibrary(owner));
  }

  String get packagePrefix => owner.packagePrefix;

  Method get originallyInheritedFrom => methodInheritedFrom == null ?
      this : methodInheritedFrom.originallyInheritedFrom;

  markdown.Node fixReferenceWithScope(String name) => fixReference(name);

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
      return '${owner.docName}.${mirror.owner.simpleName}-${mirror.simpleName}';
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
    'static': isStatic.toString(),
    'abstract': isAbstract.toString(),
    'constant': isConst.toString(),
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
      // this should be NOT from the MIRROR, but from the COMMENT
      _unresolvedComment = methodInheritedFrom._unresolvedComment;

      var linkResolver = (name) => fixReferenceWithScope(name);
      comment = _unresolvedComment == null ? '' :
        markdown.markdownToHtml(_unresolvedComment.trim(),
            linkResolver: linkResolver, inlineSyntaxes: _MARKDOWN_SYNTAXES);
      commentInheritedFrom = methodInheritedFrom.commentInheritedFrom;
      result = comment;
    }
    return result;
  }

  bool _isValidMirror(DeclarationMirror mirror) => mirror is MethodMirror;
}

/// Docgen wrapper around the dart2js mirror for a Dart
/// method/function parameter.
class Parameter extends MirrorBased {
  ParameterMirror mirror;
  String name;
  bool isOptional;
  bool isNamed;
  bool hasDefaultValue;
  Type type;
  String defaultValue;
  /// List of the meta annotations on the parameter.
  List<Annotation> annotations;

  Parameter(this.mirror, Library owningLibrary) {
    name = mirror.simpleName;
    isOptional = mirror.isOptional;
    isNamed = mirror.isNamed;
    hasDefaultValue = mirror.hasDefaultValue;
    defaultValue = mirror.defaultValue;
    type = new Type(mirror.type, owningLibrary);
    annotations = _createAnnotations(mirror, owningLibrary);
  }

  /// Generates a map describing the [Parameter] object.
  Map toMap() => {
    'name': name,
    'optional': isOptional.toString(),
    'named': isNamed.toString(),
    'default': hasDefaultValue.toString(),
    'type': new List.filled(1, type.toMap()),
    'value': defaultValue,
    'annotations': annotations.map((a) => a.toMap()).toList()
  };
}

/// A Docgen wrapper around the dart2js mirror for a generic type.
class Generic extends MirrorBased {
  TypeVariableMirror mirror;
  Generic(this.mirror);
  Map toMap() => {
    'name': mirror.toString(),
    'type': mirror.upperBound.qualifiedName
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
  TypeMirror mirror;
  Library owningLibrary;

  Type(this.mirror, this.owningLibrary);

  /// Returns a list of [Type] objects constructed from TypeMirrors.
  List<Type> _createTypeGenerics(TypeMirror mirror) {
    if (mirror is ClassMirror && !mirror.isTypedef) {
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
  List<String> parameters;
  /// The class of this annotation.
  ClassMirror mirror;
  Library owningLibrary;

  Annotation(InstanceMirror originalMirror, this.owningLibrary) {
    mirror = originalMirror.type;
    parameters = originalMirror.type.variables.values
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