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

var logger = new Logger('Docgen');

const DEFAULT_OUTPUT_DIRECTORY = 'docs';

var _outputDirectory;

const String USAGE = 'Usage: dart docgen.dart [OPTIONS] fooDir/barFile';


List<String> skippedAnnotations = const [
    'metadata.DocsEditable', '_js_helper.JSName', '_js_helper.Creates',
    '_js_helper.Returns'];

/// Set of libraries declared in the SDK, so libraries that can be accessed
/// when running dart by default.
Iterable<LibraryMirror> _sdkLibraries;

/// The dart:core library, which contains all types that are always available
/// without import.
LibraryMirror _coreLibrary;

/// Support for [:foo:]-style code comments to the markdown parser.
List<markdown.InlineSyntax> markdownSyntaxes =
  [new markdown.CodeSyntax(r'\[:\s?((?:.|\n)*?)\s?:\]')];

/// Index of all indexable items. This also ensures that no class is
/// created more than once.
Map<String, Indexable> entityMap = new Map<String, Indexable>();

/// This is set from the command line arguments flag --include-private
bool _includePrivate = false;

/// This is set from the command line flag --include-dependent-packages
bool _includeDependentPackages = false;

/// Library names to explicitly exclude.
///
///   Set from the command line option
/// --exclude-lib.
List<String> _excluded;

// TODO(janicejl): Make MDN content generic or pluggable. Maybe move
// MDN-specific code to its own library that is imported into the default impl?
/// Map of all the comments for dom elements from MDN.
Map _mdn;

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
    bool parseSdk: false, bool append: false, String introduction: '',
    out: DEFAULT_OUTPUT_DIRECTORY, List<String> excludeLibraries,
    bool includeDependentPackages}) {
  _excluded = excludeLibraries;
  _includePrivate = includePrivate;
  _outputDirectory = out;
  _includeDependentPackages = includeDependentPackages;
  if (!append) {
    var dir = new Directory(_outputDirectory);
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  }

  if (packageRoot == null && !parseSdk) {
    var type = FileSystemEntity.typeSync(files.first);
    if (type == FileSystemEntityType.DIRECTORY) {
      packageRoot = _findPackageRoot(files.first);
    } else if (type == FileSystemEntityType.FILE) {
      logger.warning('WARNING: No package root defined. If Docgen fails, try '
          'again by setting the --package-root option.');
    }
  }
  logger.info('Package Root: ${packageRoot}');
  if (_includeDependentPackages) {
    files.addAll(allDependentPackageDirs(files.first));
  }
  var requestedLibraries = _listLibraries(files);
  var allLibraries = []..addAll(requestedLibraries);
  if (includeSdk) {
    allLibraries.addAll(_listSdk());
  }

  return getMirrorSystem(allLibraries, packageRoot: packageRoot,
      parseSdk: parseSdk)
    .then((MirrorSystem mirrorSystem) {
      if (mirrorSystem.libraries.isEmpty) {
        throw new StateError('No library mirrors were created.');
      }
      var availableLibraries = mirrorSystem.libraries.values.where(
          (each) => each.uri.scheme == 'file');
      _sdkLibraries = mirrorSystem.libraries.values.where(
          (each) => each.uri.scheme == 'dart');
      _coreLibrary = _sdkLibraries.singleWhere((lib) =>
          lib.uri.toString().startsWith('dart:core'));
      var availableLibrariesByPath = new Map.fromIterables(
          availableLibraries.map((each) => each.uri),
          availableLibraries);
      var librariesToDocument = requestedLibraries.map(
          (each) => availableLibrariesByPath.putIfAbsent(each,
              () => throw "Missing library $each")).toList();
      librariesToDocument.addAll((includeSdk || parseSdk) ? _sdkLibraries : []);
      librariesToDocument.removeWhere((x) => _excluded.contains(x.simpleName));
      _documentLibraries(librariesToDocument, includeSdk: includeSdk,
          outputToYaml: outputToYaml, append: append, parseSdk: parseSdk,
          introduction: introduction);
      return true;
    });
}

/// All of the directories for our dependent packages
List<String> allDependentPackageDirs(String packageDirectory) {
  var dependentsJson = Process.runSync('pub', ['list-package-dirs'],
      workingDirectory: packageDirectory, runInShell: true);
  if (dependentsJson.exitCode != 0) {
    print(dependentsJson.stderr);
  }
  var dependents = JSON.decode(dependentsJson.stdout)['packages'];
  return dependents.values.toList();
}

/// For a library's [mirror], determine the name of the package (if any) we
/// believe it came from (because of its file URI).
///
/// If [library] is specified, we set the packageName field. If no package could
/// be determined, we return an empty string.
String _findPackage(LibraryMirror mirror, [Library library]) {
  if (mirror == null) return '';
  if (library == null) {
    library = entityMap[docName(mirror)];
  }
  if (library != null) {
    if (library.hasBeenCheckedForPackage) return library.packageName;
    library.hasBeenCheckedForPackage = true;
  }
  if (mirror.uri.scheme != 'file') return '';
  var filePath = mirror.uri.toFilePath();
  // We assume that we are documenting only libraries under package/lib
  var rootdir = path.dirname((path.dirname(filePath)));
  var pubspec = path.join(rootdir, 'pubspec.yaml');
  var packageName = _packageName(pubspec);
  if (library != null) {
    library.packageName = packageName;
    // Associate the package readme with all the libraries. This is a bit
    // wasteful, but easier than trying to figure out which partial match
    // is best.
    library.packageIntro = _packageIntro(rootdir);
  }
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
  readmes.sort((a, b) => a.length.compareTo(b.length));
  var readme = readmes.first;
  var linkResolver = (name) => fixReference(name, null, null, null);
  var contents = markdown.markdownToHtml(readme
    .readAsStringSync(), linkResolver: linkResolver,
    inlineSyntaxes: markdownSyntaxes);
  return contents;
}

List<Uri> _listLibraries(List<String> args) {
  var libraries = new List<Uri>();
  for (var arg in args) {
    var type = FileSystemEntity.typeSync(arg);

    if (type == FileSystemEntityType.FILE) {
      if (arg.endsWith('.dart')) {
        libraries.add(new Uri.file(path.absolute(arg)));
        logger.info('Added to libraries: ${libraries.last}');
      }
    } else {
      libraries.addAll(_listDartFromDir(arg));
    }
  }
  return libraries;
}

List<Uri> _listDartFromDir(String args) {
  var libraries = [];
  // To avoid anaylzing package files twice, only files with paths not
  // containing '/packages' will be added. The only exception is if the file to
  // analyze already has a '/package' in its path.
  var files = listDir(args, recursive: true).where((f) => f.endsWith('.dart') &&
      (!f.contains('${path.separator}packages') ||
          args.contains('${path.separator}packages'))).toList();

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

String _findPackageRoot(String directory) {
  var files = listDir(directory, recursive: true);
  // Return '' means that there was no pubspec.yaml and therefor no packageRoot.
  String packageRoot = files.firstWhere((f) =>
      f.endsWith('${path.separator}pubspec.yaml'), orElse: () => '');
  if (packageRoot != '') {
    packageRoot = path.join(path.dirname(packageRoot), 'packages');
  }
  return packageRoot;
}

/// Read a pubspec and return the library name.
String _packageName(String pubspecName) {
  File pubspec = new File(pubspecName);
  if (!pubspec.existsSync()) return '';
  var contents = pubspec.readAsStringSync();
  var spec = loadYaml(contents);
  return spec["name"];
}

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

/// Analyzes set of libraries by getting a mirror system and triggers the
/// documentation of the libraries.
Future<MirrorSystem> getMirrorSystem(List<Uri> libraries,
    {String packageRoot, bool parseSdk: false}) {
  if (libraries.isEmpty) throw new StateError('No Libraries.');
  // Finds the root of SDK library based off the location of docgen.

  var root = findRootDirectory();
  var sdkRoot = path.normalize(path.absolute(path.join(root, 'sdk')));
  logger.info('SDK Root: ${sdkRoot}');
  return _analyzeLibraries(libraries, sdkRoot, packageRoot: packageRoot);
}

String findRootDirectory() {
  var scriptDir = path.absolute(path.dirname(Platform.script.toFilePath()));
  var root = scriptDir;
  while(path.basename(root) != 'dart') {
    root = path.dirname(root);
  }
  return root;
}

/// Analyzes set of libraries and provides a mirror system which can be used
/// for static inspection of the source code.
Future<MirrorSystem> _analyzeLibraries(List<Uri> libraries,
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

/// Creates documentation for filtered libraries.
void _documentLibraries(List<LibraryMirror> libs, {bool includeSdk: false,
    bool outputToYaml: true, bool append: false, bool parseSdk: false,
    String introduction: ''}) {
  libs.forEach((lib) {
    // Files belonging to the SDK have a uri that begins with 'dart:'.
    if (includeSdk || !lib.uri.toString().startsWith('dart:')) {
      var library = generateLibrary(lib);
      entityMap[library.name] = library;
    }
  });
  // After everything is created, do a pass through all classes to make sure no
  // intermediate classes created by mixins are included, all the links to
  // exported members point to the new library.
  entityMap.values.where((e) => e is Class).forEach(
      (c) => c.updateLinksAndRemoveIntermediaryClasses());
  // Everything is a subclass of Object, therefore empty the list to avoid a
  // giant list of subclasses to be printed out.
  if (includeSdk) (entityMap['dart-core.Object'] as Class).subclasses.clear();

  var filteredEntities = entityMap.values.where(_isVisible);

  // Outputs a JSON file with all libraries and their preview comments.
  // This will help the viewer know what libraries are available to read in.
  var libraryMap;
  var linkResolver = (name) => fixReference(name, null, null, null);
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
    if (introduction.isNotEmpty) {
      var intro = libraryMap['introduction'];
      if (intro.isNotEmpty) intro += '<br/><br/>';
      intro += markdown.markdownToHtml(
          new File(introduction).readAsStringSync(),
              linkResolver: linkResolver, inlineSyntaxes: markdownSyntaxes);
      libraryMap['introduction'] = intro;
    }
    outputToYaml = libraryMap['filetype'] == 'yaml';
  } else {
    libraryMap = {
      'libraries' : filteredEntities.where((e) =>
          e is Library).map((e) => e.previewMap).toList(),
      'introduction' : introduction == '' ?
          '' : markdown.markdownToHtml(new File(introduction)
              .readAsStringSync(), linkResolver: linkResolver,
                  inlineSyntaxes: markdownSyntaxes),
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
        JSON.decode(new File('$_outputDirectory/index.json').readAsStringSync());
    index.addAll(previousIndex);
  }
  _writeToFile(JSON.encode(index), 'index.json');
}

Library generateLibrary(dart2js.Dart2JsLibraryMirror library) {
  var result = new Library(library);
  _findPackage(library, result);
  logger.fine('Generated library for ${result.name}');
  return result;
}

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

/// A declaration is private if itself is private, or the owner is private.
// Issue(12202) - A declaration is public even if it's owner is private.
bool _isHidden(DeclarationMirror mirror) {
  if (mirror is LibraryMirror) {
    return _isLibraryPrivate(mirror);
  } else if (mirror.owner is LibraryMirror) {
    return (mirror.isPrivate || _isLibraryPrivate(mirror.owner));
  } else {
    return (mirror.isPrivate || _isHidden(mirror.owner));
  }
}

bool _isVisible(Indexable item) {
  return _includePrivate || !item.isPrivate;
}

/// Generates MDN comments from database.json.
void _mdnComment(Indexable item) {
  //Check if MDN is loaded.
  if (_mdn == null) {
    // Reading in MDN related json file.
    var root = findRootDirectory();
    var mdnPath = path.join(root, 'utils/apidoc/mdn/database.json');
    _mdn = JSON.decode(new File(mdnPath).readAsStringSync());
  }
  if (item is Library) return;
  var domAnnotation = item.annotations.firstWhere(
      (e) => e.qualifiedName == 'metadata.DomName', orElse: () => null);
  if (domAnnotation == null) return;
  var domName = domAnnotation.parameters.single;
  var parts = domName.split('.');
  if (parts.length == 2) item.comment = _mdnMemberComment(parts[0], parts[1]);
  if (parts.length == 1) item.comment = _mdnTypeComment(parts[0]);
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

/// Look for the specified name starting with the current member, and
/// progressively working outward to the current library scope.
String findElementInScope(String name, LibraryMirror currentLibrary,
    ClassMirror currentClass, MemberMirror currentMember) {
  var packagePrefix = _findPackage(currentLibrary);
  if (packagePrefix != '') packagePrefix += '/';

  determineLookupFunc(name) => name.contains('.') ?
      dart2js_util.lookupQualifiedInScope :
      (mirror, name) => mirror.lookupInScope(name);
  var lookupFunc = determineLookupFunc(name);

  var memberScope = currentMember == null ?
      null : lookupFunc(currentMember, name);
  if (memberScope != null) return packagePrefix + docName(memberScope);

  var classScope = currentClass;
  while (classScope != null) {
    var classFunc = lookupFunc(currentClass, name);
    if (classFunc != null) return packagePrefix + docName(classFunc);
    classScope = classScope.superclass;
  }

  var libraryScope = currentLibrary == null ?
      null : lookupFunc(currentLibrary, name);
  if (libraryScope != null) return packagePrefix + docName(libraryScope);

  // Look in the dart core library scope.
  var coreScope = _coreLibrary == null? null : lookupFunc(_coreLibrary, name);
  if (coreScope != null) return packagePrefix + docName(_coreLibrary);

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
      if (scope != null) return packagePrefix + docName(scope);
    }
  }
  return null;
}

// HTML escaped version of '<' character.
final _LESS_THAN = '&lt;';

/// Chunk the provided name into individual parts to be resolved. We take a
/// simplistic approach to chunking, though, we break at " ", ",", "&lt;"
/// and ">". All other characters are grouped into the name to be resolved.
/// As a result, these characters will all be treated as part of the item to be
/// resolved (aka the * is interpreted literally as a *, not as an indicator for
/// bold <em>.
List<String> _tokenizeComplexReference(String name) {
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

/// This is a more complex reference. Try to break up if its of the form A<B>
/// where A is an alphanumeric string and B is an A, a list of B ("B, B, B"),
/// or of the form A<B>. Note: unlike other the other markdown-style links, all
/// text inside the square brackets is treated as part of the link (aka the * is
/// interpreted literally as a *, not as a indicator for bold <em>.
///
/// Example: [foo&lt;_bar_>] will produce
/// <a>resolvedFoo</a>&lt;<a>resolved_bar_</a>> rather than an italicized
/// version of resolvedBar.
markdown.Node _fixComplexReference(String name, LibraryMirror currentLibrary,
    ClassMirror currentClass, MemberMirror currentMember) {
  // Parse into multiple elements we can try to resolve.
  var tokens = _tokenizeComplexReference(name);

  // Produce an html representation of our elements. Group unresolved and plain
  // text are grouped into "link" elements so they display as code.
  final textElements = [' ', ',', '>', _LESS_THAN];
  var accumulatedHtml = '';

  for (var token in tokens) {
    bool added = false;
    if (!textElements.contains(token)) {
      String elementName = findElementInScope(token, currentLibrary,
          currentClass, currentMember);
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

/// Converts all [foo] references in comments to <a>libraryName.foo</a>.
markdown.Node fixReference(String name, LibraryMirror currentLibrary,
    ClassMirror currentClass, MemberMirror currentMember) {
  // Attempt the look up the whole name up in the scope.
  String elementName =
      findElementInScope(name, currentLibrary, currentClass, currentMember);
  if (elementName != null) {
    return new markdown.Element.text('a', elementName);
  }
  return _fixComplexReference(name, currentLibrary, currentClass,
      currentMember);
}

markdown.Node fixReferenceWithScope(String name, DeclarationMirror scope) {
  if (scope is LibraryMirror) return fixReference(name, scope, null, null);
  if (scope is ClassMirror)
      return fixReference(name, scope.library, scope, null);
  if (scope is MemberMirror) {
    var owner = scope.owner;
    if (owner is ClassMirror) {
        return fixReference(name, owner.library, owner, scope);
    } else {
      return fixReference(name, owner, null, scope);
    }
  }
  return null;
}

/// Writes text to a file in the output directory.
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
      var subdir = new Directory(path.join(_outputDirectory,
                                           path.dirname(filename)));
      if (!subdir.existsSync()) {
        subdir.createSync();
      }
    }
  }
  File file = new File(path.join(_outputDirectory, filename));
  file.writeAsStringSync(text, mode: append ? FileMode.APPEND : FileMode.WRITE);
}

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

/// A type for the function that generates a comment from a mirror.
typedef String CommentGenerator(Mirror m);

/// A class representing all programming constructs, like library or class.
class Indexable {
  String get qualifiedName => fileName;
  bool isPrivate;
  DeclarationMirror mirror;

  Indexable(this.mirror) {
    this.isPrivate = _isHidden(mirror);
  }

  // The qualified name (for URL purposes) and the file name are the same,
  // of the form packageName/ClassName or packageName/ClassName.methodName.
  // This defines both the URL and the directory structure.
  String get fileName => packagePrefix + ownerPrefix + name;

  Indexable get owningEntity => entityMap[owner];

  String get ownerPrefix => owningEntity == null ?
      (owner == null || owner.isEmpty ? '' : owner + '.') :
      owningEntity.qualifiedName + '.';

  String get packagePrefix => '';

  /// Documentation comment with converted markdown.
  String _comment;

  String get comment {
    if (_comment != null) return _comment;
    _comment = _commentToHtml(mirror);
    if (_comment.isEmpty) {
      _mdnComment(this);
    }
    return _comment;
  }

  set comment(x) => _comment = x;

  String get name => mirror.simpleName;

  /// Qualified Name of the owner of this Indexable Item.
  String get owner => docName(mirror.owner);

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

  /// Returns any documentation comments associated with a mirror with
  /// simple markdown converted to html.
  ///
  /// It's possible to have a comment that comes from one mirror applied to
  /// another, in the case of an inherited comment.
  String _commentToHtml(itemToDocument) {
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

    var linkResolver = (name) => fixReferenceWithScope(name, itemToDocument);
    commentText = commentText == null ? '' :
        markdown.markdownToHtml(commentText.trim(), linkResolver: linkResolver,
            inlineSyntaxes: markdownSyntaxes);
    return commentText;
  }

  /// Returns a map of [Variable] objects constructed from [mirrorMap].
  /// The optional parameter [containingLibrary] is contains data for variables
  /// defined at the top level of a library (potentially for exporting
  /// purposes).
  Map<String, Variable> _createVariables(Map<String,
      VariableMirror> mirrorMap, [Library containingLibrary]) {
    var data = {};
    // TODO(janicejl): When map to map feature is created, replace the below
    // with a filter. Issue(#9590).
    mirrorMap.forEach((String mirrorName, VariableMirror mirror) {
      if (_includePrivate || !_isHidden(mirror)) {
        if (containingLibrary != null && mirror.owner.qualifiedName !=
            containingLibrary.mirror.qualifiedName) {
          entityMap[docName(mirror)] = new ExportedVariable(mirrorName, mirror,
              containingLibrary);
        } else {
          entityMap[docName(mirror)] = new Variable(mirrorName, mirror);
        }
        data[mirrorName] = entityMap[docName(mirror)];
      }
    });
    return data;
  }

  /// Returns a map of [Method] objects constructed from [mirrorMap].
  /// The optional parameter [containingLibrary] is contains data for variables
  /// defined at the top level of a library (potentially for exporting
  /// purposes).
  MethodGroup _createMethods(Map<String, MethodMirror> mirrorMap,
      [Library containingLibrary]) {
    var group = new MethodGroup();
    mirrorMap.forEach((String mirrorName, MethodMirror mirror) {
      if (_includePrivate || !mirror.isPrivate) {
        group.addMethod(mirror, containingLibrary);
      }
    });
    return group;
  }

  /// Returns a map of [Parameter] objects constructed from [mirrorList].
  Map<String, Parameter> _createParameters(List<ParameterMirror> mirrorList) {
    var data = {};
    mirrorList.forEach((ParameterMirror mirror) {
      data[mirror.simpleName] = new Parameter(mirror.simpleName,
          mirror.isOptional, mirror.isNamed, mirror.hasDefaultValue,
          _createType(mirror.type), mirror.defaultValue,
          _createAnnotations(mirror));
    });
    return data;
  }

  /// Returns a map of [Generic] objects constructed from the class mirror.
  Map<String, Generic> _createGenerics(ClassMirror mirror) {
    return new Map.fromIterable(mirror.typeVariables,
        key: (e) => e.toString(),
        value: (e) => new Generic(e.toString(), e.upperBound.qualifiedName));
  }

  /// Returns a single [Type] object constructed from the Method.returnType
  /// Type mirror.
  Type _createType(TypeMirror mirror) {
    return new Type(docName(mirror), _createTypeGenerics(mirror));
  }

  /// Returns a list of [Type] objects constructed from TypeMirrors.
  List<Type> _createTypeGenerics(TypeMirror mirror) {
    if (mirror is ClassMirror && !mirror.isTypedef) {
      var innerList = [];
      mirror.typeArguments.forEach((e) {
        innerList.add(new Type(docName(e), _createTypeGenerics(e)));
      });
      return innerList;
    }
    return [];
  }

  /// Returns a list of meta annotations assocated with a mirror.
  List<Annotation> _createAnnotations(DeclarationMirror mirror) {
    var annotationMirrors = mirror.metadata.where((e) =>
        e is dart2js.Dart2JsConstructedConstantMirror);
    var annotations = [];
    annotationMirrors.forEach((annotation) {
      var parameterList = annotation.type.variables.values
        .where((e) => e.isFinal)
        .map((e) => annotation.getField(e.simpleName).reflectee)
        .where((e) => e != null)
        .toList();
      if (!skippedAnnotations.contains(docName(annotation.type))) {
        annotations.add(new Annotation(docName(annotation.type),
            parameterList));
      }
    });
    return annotations;
  }

  /// Return an informative [Object.toString] for debugging.
  String toString() => "${super.toString()}(${name.toString()})";

  /// Return a map representation of this type.
  Map toMap() {}
}

/// A class containing contents of a Dart library.
class Library extends Indexable {

  /// Top-level variables in the library.
  Map<String, Variable> variables;

  /// Top-level functions in the library.
  MethodGroup functions;

  /// Classes defined within the library
  ClassGroup classes;

  String packageName = '';
  bool hasBeenCheckedForPackage = false;
  String packageIntro;

  Map<String, Exported> _exportedMembers;

  Library(LibraryMirror libraryMirror) : super(libraryMirror) {
    var exported = _calcExportedItems(libraryMirror);
    _createClasses(exported['classes']..addAll(libraryMirror.classes));
    this.functions = _createMethods(
        exported['methods']..addAll(libraryMirror.functions), this);
    this.variables = _createVariables(
        exported['variables']..addAll(libraryMirror.variables), this);

    var exportedVariables = {};
    variables.forEach((key, value) {
      if (value is ExportedVariable) {
        exportedVariables[key] = value;
      }
    });
    _exportedMembers = new Map.from(this.classes.exported)
        ..addAll(this.functions.exported)
        ..addAll(exportedVariables);
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

  String get owner => '';

  String get name => docName(mirror);

  /// Set our classes field with error, typedef and regular classes.
  void _createClasses(Map<String, ClassMirror> mirrorMap) {
    this.classes = new ClassGroup();
    mirrorMap.forEach((String mirrorName, ClassMirror mirror) {
      this.classes.addClass(mirror, this);
    });
  }

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

  /// Generates a map describing the [Library] object.
  Map toMap() => {
    'name': name,
    'qualifiedName': qualifiedName,
    'comment': comment,
    'variables': recurseMap(variables),
    'functions': functions.toMap(),
    'classes': classes.toMap(),
    'packageName': packageName,
    'packageIntro' : packageIntro
  };

  String get typeName => 'library';
}

/// A class containing contents of a Dart class.
class Class extends Indexable implements Comparable {

  /// List of the names of interfaces that this class implements.
  List<Class> interfaces = [];

  /// Names of classes that extends or implements this class.
  Set<Class> subclasses = new Set<Class>();

  /// Top-level variables in the class.
  Map<String, Variable> variables;

  /// Inherited variables in the class.
  Map<String, Variable> inheritedVariables = {};

  /// Methods in the class.
  MethodGroup methods;

  /// Inherited methods in the class.
  MethodGroup inheritedMethods = new MethodGroup();

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
  factory Class(ClassMirror mirror) {
    var clazz = entityMap[docName(mirror)];
    if (clazz == null) {
      clazz = new Class._(mirror);
      entityMap[docName(mirror)] = clazz;
    }
    return clazz;
  }

  Class._(ClassMirror classMirror) : super(classMirror) {
    var superclass = classMirror.superclass != null ?
        new Class(classMirror.superclass) : null;
    var interfaces = classMirror.superinterfaces.map(
        (interface) => new Class(interface));

    this.superclass = superclass;
    this.interfaces = interfaces.toList();
    this.variables = _createVariables(classMirror.variables);
    this.methods = _createMethods(classMirror.methods);
    this.annotations = _createAnnotations(classMirror);
    this.generics = _createGenerics(classMirror);
    this.isAbstract = classMirror.isAbstract;

    // Tell all superclasses that you are a subclass.
    if (!classMirror.isNameSynthetic && _isVisible(this)) {
      parentChain().forEach((parentClass) {
          parentClass.addSubclass(this);
      });
    }

    if (this.superclass != null) addInherited(superclass);
    interfaces.forEach((interface) => addInherited(interface));
  }

  String get typeName => 'class';

  /// Returns a list of all the parent classes.
  List<Class> parentChain() {
    var parent = superclass == null ? [] : [superclass];
    parent.addAll(interfaces);
    return parent;
  }

  /// Add all inherited variables and methods from the provided superclass.
  /// If [_includePrivate] is true, it also adds the variables and methods from
  /// the superclass.
  void addInherited(Class superclass) {
    inheritedVariables.addAll(superclass.inheritedVariables);
    inheritedVariables.addAll(_filterStatics(superclass.variables));
    inheritedMethods.addInherited(superclass);
  }

  /// Add the subclass to the class.
  ///
  /// If [this] is private, it will add the subclass to the list of subclasses
  /// in the superclasses.
  void addSubclass(Class subclass) {
    if (!_includePrivate && isPrivate) {
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

  /// Check that the class exists in the owner library.
  ///
  /// If it does not exist in the owner library, it is a mixin applciation and
  /// should be removed.
  void updateLinksAndRemoveIntermediaryClasses() {
    var library = entityMap[owner];
    if (library != null) {
      if (!library.classes.containsKey(name) && mirror.isNameSynthetic) {
        // In the mixin case, remove the intermediary classes.
        this.isPrivate = true;
        // Since we are now making the mixin a private class, make all elements
        // with the mixin as an owner private too.
        entityMap.values.where((e) => e.owner == qualifiedName).forEach(
            (element) => element.isPrivate = true);
        // Move the subclass up to the next public superclass
        subclasses.forEach((subclass) => addSubclass(subclass));
      } else {
        // It is an exported item. Loop through each of the exported types,
        // and tell them to update their links, given these other exported
        // names within the library.
        for (Exported member in library._exportedMembers.values) {
          member.updateExports(library._exportedMembers.keys);
        }
      }
    }
  }

  /// Makes sure that all methods with inherited equivalents have comments.
  void ensureComments() {
    if (_commentsEnsured) return;
    _commentsEnsured = true;
    inheritedMethods.forEach((qualifiedName, inheritedMethod) {
      var method = methods[qualifiedName];
      if (method != null) method.ensureCommentFor(inheritedMethod);
    });
  }

  /// If a class extends a private superclass, find the closest public
  /// superclass of the private superclass.
  String validSuperclass() {
    if (superclass == null) return 'dart.core.Object';
    if (_isVisible(superclass)) return superclass.qualifiedName;
    return superclass.validSuperclass();
  }

  /// Generates a map describing the [Class] object.
  Map toMap() => {
    'name': name,
    'qualifiedName': qualifiedName,
    'comment': comment,
    'isAbstract' : isAbstract,
    'superclass': validSuperclass(),
    'implements': interfaces.where(_isVisible)
        .map((e) => e.qualifiedName).toList(),
    'subclass': (subclasses.toList()..sort())
        .map((x) => x.qualifiedName).toList(),
    'variables': recurseMap(variables),
    'inheritedVariables': recurseMap(inheritedVariables),
    'methods': methods.toMap(),
    'inheritedMethods': inheritedMethods.toMap(),
    'annotations': annotations.map((a) => a.toMap()).toList(),
    'generics': recurseMap(generics)
  };

  int compareTo(aClass) => name.compareTo(aClass.name);
}

abstract class Exported {
  void updateExports(Map<String, Indexable> libraryExports);
}

Map _filterMap(exported, map, test) {
  map.forEach((key, value) {
    if (test(value)) exported[key] = value;
  });
  return exported;
}

class ExportedClass extends Class implements Exported {
  Class _originalClass;
  Library _exportingLibrary;

  ExportedClass(ClassMirror originalClass, Library this._exportingLibrary) :
      super._(originalClass) {
    _originalClass = new Class(originalClass);
  }

  // The qualified name (for URL purposes) and the file name are the same,
  // of the form packageName/ClassName or packageName/ClassName.methodName.
  // This defines both the URL and the directory structure.
  String get fileName => path.join(_exportingLibrary.packageName,
      _exportingLibrary.mirror.qualifiedName + '.' + _originalClass.name);

  void updateExports(Map<String, Indexable> libraryExports) {
    // TODO(efortuna): If this class points to another exported class or type
    // of some sort, then that reference needs to be updated here.
    /* these need to be updated:
    'comment': comment,
    'superclass': validSuperclass(),
    'implements': interfaces.where(_isVisible)
        .map((e) => e.qualifiedName).toList(),
    'subclass': (subclasses.toList()..sort())
        .map((x) => x.qualifiedName).toList(),
    'variables': recurseMap(variables),
    'inheritedVariables': recurseMap(inheritedVariables),
    'methods': methods.toMap(),
    'inheritedMethods': inheritedMethods.toMap(),
    'annotations': annotations.map((a) => a.toMap()).toList(),
    'generics': recurseMap(generics)
    */
  }
}

/// A container to categorize classes into the following groups: abstract
/// classes, regular classes, typedefs, and errors.
class ClassGroup {
  Map<String, Class> classes = {};
  Map<String, Typedef> typedefs = {};
  Map<String, Class> errors = {};

  Map<String, Exported> get exported {
    var exported = _filterMap({}, classes, (value) => value is ExportedClass);
    // TODO(efortuna): The line below needs updating.
    exported = _filterMap(exported, typedefs,
        (value) => value is ExportedClass);
    exported = _filterMap(exported, errors,
        (value) => value is ExportedClass);
    return exported;
  }

  void addClass(ClassMirror classMirror, Library containingLibrary) {
    if (classMirror.isTypedef) {
      // This is actually a Dart2jsTypedefMirror, and it does define value,
      // but we don't have visibility to that type.
      var mirror = classMirror;
      if (_includePrivate || !mirror.isPrivate) {
        entityMap[docName(mirror)] = new Typedef(mirror);
        typedefs[mirror.simpleName] = entityMap[docName(mirror)];
      }
    } else {
      var clazz = new Class(classMirror);

      if (classMirror.library.qualifiedName !=
          containingLibrary.mirror.qualifiedName) {
        var exportedClass = new ExportedClass(classMirror, containingLibrary);
        entityMap[clazz.fileName] = exportedClass;
        clazz = exportedClass;
      }

      if (clazz.isError()) {
        errors[classMirror.simpleName] = clazz;
      } else if (classMirror.isClass) {
        classes[classMirror.simpleName] = clazz;
      } else {
        throw new ArgumentError(
            '${classMirror.simpleName} - no class type match. ');
      }
    }
  }

  /// Checks if the given name is a key for any of the Class Maps.
  bool containsKey(String name) {
    return classes.containsKey(name) || errors.containsKey(name);
  }

  Map toMap() => {
    'class': classes.values.where(_isVisible)
      .map((e) => e.previewMap).toList(),
    'typedef': recurseMap(typedefs),
    'error': errors.values.where(_isVisible)
      .map((e) => e.previewMap).toList()
  };
}

class Typedef extends Indexable {
  String returnType;

  Map<String, Parameter> parameters;

  /// Generic information about the typedef.
  Map<String, Generic> generics;

  /// List of the meta annotations on the typedef.
  List<Annotation> annotations;

  Typedef(mirror) : super(mirror) {
    this.returnType = docName(mirror.value.returnType);
    this.generics = _createGenerics(mirror);
    this.parameters = _createParameters(mirror.value.parameters);
    this.annotations = _createAnnotations(mirror);
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
}

/// A class containing properties of a Dart variable.
class Variable extends Indexable {

  bool isFinal;
  bool isStatic;
  bool isConst;
  Type type;
  String _variableName;

  /// List of the meta annotations on the variable.
  List<Annotation> annotations;

  Variable(this._variableName, VariableMirror mirror) : super(mirror) {
    this.isFinal = mirror.isFinal;
    this.isStatic = mirror.isStatic;
    this.isConst = mirror.isConst;
    this.type = _createType(mirror.type);
    this.annotations = _createAnnotations(mirror);
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

  String get typeName => 'property';

  get comment {
    if (_comment != null) return _comment;
    var owningClass = owningEntity;
    if (owningClass is Class) {
      owningClass.ensureComments();
    }
    return super.comment;
  }
}

class ExportedVariable extends Variable implements Exported {
  Library _exportingLibrary;

  ExportedVariable(String variableName, VariableMirror originalVariable,
      Library this._exportingLibrary) : super(variableName, originalVariable);

  String get fileName => path.join(_exportingLibrary.packageName,
          _exportingLibrary.mirror.qualifiedName + '.' + super.name);

  void updateExports(Map<String, Indexable> libraryExports) {
    // TODO(efortuna): if this class points to another exported class or type
    // of some sort, then that reference needs to be updated here.
    /* these need to be updated:
    'comment': comment,
    'type': new List.filled(1, type.toMap()),
    'annotations': annotations.map((a) => a.toMap()).toList()
    */
  }
}

/// A class containing properties of a Dart method.
class Method extends Indexable {

  /// Parameters for this method.
  Map<String, Parameter> parameters;

  bool isStatic;
  bool isAbstract;
  bool isConst;
  bool isConstructor;
  bool isGetter;
  bool isSetter;
  bool isOperator;
  Type returnType;

  /// Qualified name to state where the comment is inherited from.
  String commentInheritedFrom = "";

  /// List of the meta annotations on the method.
  List<Annotation> annotations;

  Method(MethodMirror mirror) : super(mirror) {
    this.isStatic = mirror.isStatic;
    this.isAbstract = mirror.isAbstract;
    this.isConst = mirror.isConstConstructor;
    this.returnType = _createType(mirror.returnType);
    this.parameters = _createParameters(mirror.parameters);
    this.annotations = _createAnnotations(mirror);
    this.isConstructor = mirror.isConstructor;
    this.isGetter = mirror.isGetter;
    this.isSetter = mirror.isSetter;
    this.isOperator = mirror.isOperator;
  }

  /// Makes sure that the method with an inherited equivalent have comments.
  void ensureCommentFor(Method inheritedMethod) {
    if (comment.isNotEmpty) return;
    comment = inheritedMethod._commentToHtml(mirror);
    commentInheritedFrom = inheritedMethod.commentInheritedFrom == '' ?
        inheritedMethod.qualifiedName : inheritedMethod.commentInheritedFrom;
  }

  /// Generates a map describing the [Method] object.
  Map toMap() => {
    'name': name,
    'qualifiedName': qualifiedName,
    'comment': comment,
    'commentFrom': commentInheritedFrom,
    'static': isStatic.toString(),
    'abstract': isAbstract.toString(),
    'constant': isConst.toString(),
    'return': new List.filled(1, returnType.toMap()),
    'parameters': recurseMap(parameters),
    'annotations': annotations.map((a) => a.toMap()).toList()
  };

  String get typeName => isConstructor ? 'constructor' :
    isGetter ? 'getter' : isSetter ? 'setter' :
    isOperator ? 'operator' : 'method';

  get comment {
    if (_comment != null) return _comment;
    var owningClass = owningEntity;
    if (owningClass is Class) {
      owningClass.ensureComments();
    }
    return super.comment;
  }
}

class ExportedMethod extends Method implements Exported {
  Library _exportingLibrary;

  ExportedMethod(MethodMirror originalMethod, Library this._exportingLibrary) :
      super(originalMethod);

  // TODO(efortuna): Refactor this code so the exported items can share this
  // behavior.
  String get fileName => path.join(_exportingLibrary.packageName,
      _exportingLibrary.mirror.qualifiedName + '.' + super.name);

  void updateExports(Map<String, Indexable> libraryExports) {
    // TODO(efortuna): if this class points to another exported class or type
    // of some sort, then that reference needs to be updated here.
    /* these need to be updated:
    'qualifiedName': qualifiedName,
    'comment': comment,
    'commentFrom': commentInheritedFrom,
    'return': new List.filled(1, returnType.toMap()),
    'parameters': recurseMap(parameters),
    'annotations': annotations.map((a) => a.toMap()).toList()
    */
  }
}



/// A container to categorize methods into the following groups: setters,
/// getters, constructors, operators, regular methods.
class MethodGroup {
  Map<String, Method> setters = {};
  Map<String, Method> getters = {};
  Map<String, Method> constructors = {};
  Map<String, Method> operators = {};
  Map<String, Method> regularMethods = {};

  Map<String, Exported> get exported {
    var exported = {};
    for (Map<String, Method> group in [setters, getters, constructors,
      operators, regularMethods]) {
      exported = _filterMap(exported, group,
          (value) => value is ExportedMethod);
    }
    return exported;
  }

  /// The optional parameter [containingLibrary] is contains data for variables
  /// defined at the top level of a library (potentially for exporting
  /// purposes).
  void addMethod(MethodMirror mirror, [Library containingLibrary]) {
    var method;
    if (containingLibrary != null && mirror.owner.qualifiedName !=
        containingLibrary.mirror.qualifiedName) {
      method = new ExportedMethod(mirror, containingLibrary);
    } else {
      method = new Method(mirror);
    }
    entityMap[docName(mirror)] = method;
    if (mirror.isSetter) {
      setters[mirror.simpleName] = method;
    } else if (mirror.isGetter) {
      getters[mirror.simpleName] = method;
    } else if (mirror.isConstructor) {
      constructors[mirror.simpleName] = method;
    } else if (mirror.isOperator) {
      operators[mirror.simpleName] = method;
    } else if (mirror.isRegularMethod) {
      regularMethods[mirror.simpleName] = method;
    } else {
      throw new ArgumentError('${mirror.simpleName} - no method type match');
    }
  }

  void addInherited(Class parent) {
    setters.addAll(parent.inheritedMethods.setters);
    setters.addAll(_filterStatics(parent.methods.setters));
    getters.addAll(parent.inheritedMethods.getters);
    getters.addAll(_filterStatics(parent.methods.getters));
    operators.addAll(parent.inheritedMethods.operators);
    operators.addAll(_filterStatics(parent.methods.operators));
    regularMethods.addAll(parent.inheritedMethods.regularMethods);
    regularMethods.addAll(_filterStatics(parent.methods.regularMethods));
  }

  Map toMap() => {
    'setters': recurseMap(setters),
    'getters': recurseMap(getters),
    'constructors': recurseMap(constructors),
    'operators': recurseMap(operators),
    'methods': recurseMap(regularMethods)
  };

  Method operator [](String qualifiedName) {
    if (setters.containsKey(qualifiedName)) return setters[qualifiedName];
    if (getters.containsKey(qualifiedName)) return getters[qualifiedName];
    if (operators.containsKey(qualifiedName)) return operators[qualifiedName];
    if (regularMethods.containsKey(qualifiedName)) {
      return regularMethods[qualifiedName];
    }
    return null;
  }

  void forEach(void f(String key, Method value)) {
    setters.forEach(f);
    getters.forEach(f);
    operators.forEach(f);
    regularMethods.forEach(f);
  }
}

/// A class containing properties of a Dart method/function parameter.
class Parameter {

  String name;
  bool isOptional;
  bool isNamed;
  bool hasDefaultValue;
  Type type;
  String defaultValue;

  /// List of the meta annotations on the parameter.
  List<Annotation> annotations;

  Parameter(this.name, this.isOptional, this.isNamed, this.hasDefaultValue,
      this.type, this.defaultValue, this.annotations);

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

/// A class containing properties of a Generic.
class Generic {
  String name;
  String type;

  Generic(this.name, this.type);

  Map toMap() => {
    'name': name,
    'type': type
  };
}

/// Holds the name of a return type, and its generic type parameters.
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
class Type {
  String outer;
  List<Type> inner;

  Type(this.outer, this.inner);

  Map toMap() => {
    'outer': outer,
    'inner': inner.map((e) => e.toMap()).toList()
  };
}

/// Holds the name of the annotation, and its parameters.
class Annotation {
  String qualifiedName;
  List<String> parameters;

  Annotation(this.qualifiedName, this.parameters);

  Map toMap() => {
    'name': qualifiedName,
    'parameters': parameters
  };
}

/// Given a mirror, returns its qualified name, but following the conventions
/// we're using in Dartdoc, which is that library names with dots in them
/// have them replaced with hyphens.
String docName(DeclarationMirror m) {
  if (m is LibraryMirror) {
    return m.qualifiedName.replaceAll('.','-');
  }
  var owner = m.owner;
  if (owner == null) return m.qualifiedName;
  var simpleName = m.simpleName;
  if (m is MethodMirror && m.isConstructor) {
    // We name constructors specially -- including the class name again and a
    // "-" to separate the constructor from its name (if any).
    simpleName = '${owner.simpleName}-$simpleName';
  }
  return docName(owner) + '.' + simpleName;
}

/// Remove statics from the map of inherited items before adding them.
Map _filterStatics(Map items) {
  var result = {};
  items.forEach((name, item) {
    if (!item.isStatic) {
      result[name] = item;
    }
  });
  return result;
}
