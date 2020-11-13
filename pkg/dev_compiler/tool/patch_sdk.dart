#!/usr/bin/env dart
// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

/// Command line tool to merge the SDK libraries and our patch files.
/// This is currently designed as an offline tool, but we could automate it.

import 'dart:io';

import 'package:_fe_analyzer_shared/src/util/relativize.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:args/args.dart';
import 'package:front_end/src/base/libraries_specification.dart';
import 'package:front_end/src/fasta/resolve_input_uri.dart';
import 'package:pub_semver/pub_semver.dart';

void main(List<String> argv) {
  var args = _parser.parse(argv);
  if (args['libraries'] == null || args['out'] == null) {
    var self = relativizeUri(Uri.base, Platform.script, isWindows);
    var librariesJson = relativizeUri(Uri.base,
        Platform.script.resolve('../../../sdk/lib/libraries.json'), isWindows);
    print('Usage: $self [other options]'
        ' --libraries <libraries.json> --out <output-dir>');
    print('For example:');
    print('\$ $self --nnbd --libraries $librariesJson --out patched-sdk-dir');
    exit(1);
  }

  var useNnbd = args['nnbd'] as bool;
  var target = args['target'] as String;
  var jsonUri = resolveInputUri(args['libraries'] as String);
  var libRoot = jsonUri.resolve('./');
  var outPath = args['out'] as String;
  var outDir = resolveInputUri(outPath.endsWith('/') ? outPath : '$outPath/');
  var outLibRoot = outDir.resolve('lib/');

  var inputVersion = Uri.file(Platform.executable).resolve('../version');
  var outVersion = outDir.resolve('version');

  var specification = LibrariesSpecification.parse(
          jsonUri, File.fromUri(jsonUri).readAsStringSync())
      .specificationFor(target);

  // Copy libraries.dart and version
  _writeSync(outVersion, File.fromUri(inputVersion).readAsStringSync());

  // Enumerate sdk libraries and apply patches
  for (var library in specification.allLibraries) {
    var libraryFile = File.fromUri(library.uri);
    var libraryOut =
        outLibRoot.resolve(relativizeLibraryUri(libRoot, library.uri, useNnbd));
    if (libraryFile.existsSync()) {
      var outUris = <Uri>[libraryOut];
      var libraryContents = libraryFile.readAsStringSync();
      var contents = <String>[libraryContents];

      for (var part
          in _parseString(libraryContents, useNnbd: useNnbd).unit.directives) {
        if (part is PartDirective) {
          var partPath = part.uri.stringValue;
          outUris.add(libraryOut.resolve(partPath));
          contents.add(
              File.fromUri(library.uri.resolve(partPath)).readAsStringSync());
        }
      }

      if (args['merge-parts'] as bool && outUris.length > 1) {
        outUris.length = 1;
        contents = [
          contents
              .join('\n')
              .replaceAll(RegExp('^part [^\n]*\$', multiLine: true), '')
        ];
      }

      var buffer = StringBuffer();
      for (var patchUri in library.patches) {
        // Note: VM targets enumerate more than one patch file, they are
        // currently written so that the first file is a valid patch file and
        // all other files can be appended at the end.
        buffer.write(File.fromUri(patchUri).readAsStringSync());
      }
      var patchContents = '$buffer';

      if (patchContents.isNotEmpty) {
        contents = _patchLibrary(contents, patchContents, useNnbd: useNnbd);
      }

      if (contents != null) {
        for (var i = 0; i < outUris.length; i++) {
          _writeSync(outUris[i], contents[i]);
        }
      } else {
        exitCode = 2;
      }
    }
  }

  var outLibrariesDart =
      outLibRoot.resolve('_internal/sdk_library_metadata/lib/libraries.dart');
  _writeSync(outLibrariesDart,
      _generateLibrariesDart(libRoot, specification, useNnbd));

  var experimentsPath = '_internal/allowed_experiments.json';
  _writeSync(
    outLibRoot.resolve(experimentsPath),
    File.fromUri(libRoot.resolve(experimentsPath)).readAsStringSync(),
  );
}

/// Writes a file, creating the directory if needed.
void _writeSync(Uri fileUri, String contents) {
  var outDir = Directory.fromUri(fileUri.resolve('.'));
  if (!outDir.existsSync()) outDir.createSync(recursive: true);

  File.fromUri(fileUri).writeAsStringSync(contents);
}

final _parser = ArgParser()
  ..addFlag('nnbd',
      help: 'Whether to enable the nnbd feature.', defaultsTo: false)
  ..addFlag('merge-parts',
      help: 'Whether to merge part files. '
          'Technically this is not necessary, but dartanalyzer '
          'produces less warnings when enabling this flag.',
      defaultsTo: false)
  ..addOption('libraries',
      help: 'Path to a libraries.json specification file (required). '
          'All libary URIs within libraries.json are expected to be somewhere '
          'under the directory containing the libraries.json file. Reaching '
          'out above such directory is generally not supported. Today it is '
          'only allowed for the nnbd sdk to reuse libraries of the non-nnbd '
          'sdk, in which case the path starts with "../../sdk/lib/".')
  ..addOption('out', help: 'Path to an output folder (required).')
  ..addOption('target',
      help: 'The target tool. '
          'This name matches one of the possible targets in libraries.json '
          'and it is used to pick which patch files will be applied.',
      allowed: ['dartdevc', 'dart2js', 'dart2js_server', 'vm', 'flutter']);

/// Merges dart:* library code with code from *_patch.dart file.
///
/// Takes a list of the library's parts contents, with the main library contents
/// first in the list, and the contents of the patch file.
///
/// The result will have `@patch` implementations merged into the correct place
/// (e.g. the class or top-level function declaration) and all other
/// declarations introduced by the patch will be placed into the main library
/// file.
///
/// This is purely a syntactic transformation. Unlike dart2js patch files, there
/// is no semantic meaning given to the *_patch files, and they do not magically
/// get their own library scope, etc.
///
/// Editorializing: the dart2js approach requires a Dart front end such as
/// package:analyzer to semantically model a feature beyond what is specified
/// in the Dart language. Since this feature is only for the convenience of
/// writing the dart:* libraries, and not a tool given to Dart developers, it
/// seems like a non-ideal situation. Instead we keep the preprocessing simple.
List<String> _patchLibrary(List<String> partsContents, String patchContents,
    {bool useNnbd = false}) {
  var results = <StringEditBuffer>[];

  // Parse the patch first. We'll need to extract bits of this as we go through
  // the other files.
  var patchFinder = PatchFinder.parseAndVisit(patchContents, useNnbd: useNnbd);

  // Merge `external` declarations with the corresponding `@patch` code.
  var failed = false;
  for (var partContent in partsContents) {
    var partEdits = StringEditBuffer(partContent);
    var partUnit = _parseString(partContent, useNnbd: useNnbd).unit;
    var patcher = PatchApplier(partEdits, patchFinder);
    partUnit.accept(patcher);
    if (!failed) failed = patcher.patchWasMissing;
    results.add(partEdits);
  }
  if (failed) return null;
  return List<String>.from(results.map((e) => e.toString()));
}

/// Merge `@patch` declarations into `external` declarations.
class PatchApplier extends GeneralizingAstVisitor<void> {
  final StringEditBuffer edits;
  final PatchFinder patch;

  bool _isLibrary = true; // until proven otherwise.
  bool patchWasMissing = false;

  PatchApplier(this.edits, this.patch);

  @override
  void visitCompilationUnit(CompilationUnit node) {
    super.visitCompilationUnit(node);
    if (_isLibrary) _mergeUnpatched(node);
  }

  void _merge(AstNode node, int pos) {
    var code = patch.contents.substring(node.offset, node.end);
    edits.insert(pos, '\n' + code);
  }

  /// Merges directives and declarations that are not `@patch` into the library.
  void _mergeUnpatched(CompilationUnit unit) {
    // Merge imports from the patch
    // TODO(jmesserly): remove duplicate imports

    // To patch a library, we must have a library directive
    var libDir = unit.directives.first as LibraryDirective;
    var importPos = unit.directives
        .lastWhere((d) => d is ImportDirective, orElse: () => libDir)
        .end;
    for (var d in patch.unit.directives.whereType<ImportDirective>()) {
      _merge(d, importPos);
    }

    var partPos = unit.directives.last.end;
    for (var d in patch.unit.directives.whereType<PartDirective>()) {
      _merge(d, partPos);
    }

    // Merge declarations from the patch
    var declPos = edits.original.length;
    for (var d in patch.mergeDeclarations) {
      _merge(d, declPos);
    }
  }

  @override
  void visitPartOfDirective(PartOfDirective node) {
    _isLibrary = false;
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _maybePatch(node);
  }

  /// Merge patches and extensions into the class
  @override
  void visitClassDeclaration(ClassDeclaration node) {
    node.members.forEach(_maybePatch);

    var mergeMembers = patch.mergeMembers[_qualifiedName(node)];
    if (mergeMembers == null) return;

    // Merge members from the patch
    var pos = node.members.last.end;
    for (var member in mergeMembers) {
      var code = patch.contents.substring(member.offset, member.end);
      edits.insert(pos, '\n\n  ' + code);
    }
  }

  void _maybePatch(Declaration node) {
    if (node is FieldDeclaration) return;

    var externalKeyword = (node as dynamic).externalKeyword as Token;
    if (externalKeyword == null) return;

    var name = _qualifiedName(node);
    var patchNode = patch.patches[name];
    if (patchNode == null) {
      // *.fromEnvironment are left unpatched by dart2js and are handled via
      // codegen.
      if (name != 'bool.fromEnvironment' &&
          name != 'int.fromEnvironment' &&
          name != 'String.fromEnvironment') {
        print('warning: patch not found for $name: $node');
        // TODO(sigmund): delete this fail logic? Rather than emit an empty
        // file, it's more useful to emit a file with missing patches.
        // patchWasMissing = true;
      }
      return;
    }

    var patchMeta = patchNode.metadata.lastWhere(_isPatchAnnotation);
    var start = patchMeta.endToken.next.offset;
    var code = patch.contents.substring(start, patchNode.end);

    // Const factory constructors can't be legally parsed from the patch file,
    // so we need to omit the "const" there, but still preserve it.
    if (node is ConstructorDeclaration &&
        node.constKeyword != null &&
        patchNode is ConstructorDeclaration &&
        patchNode.constKeyword == null) {
      code = 'const $code';
    }

    // For some node like static fields, the node's offset doesn't include
    // the external keyword. Also starting from the keyword lets us preserve
    // documentation comments.
    edits.replace(externalKeyword.offset, node.end, code);
  }
}

class PatchFinder extends GeneralizingAstVisitor<void> {
  final String contents;
  final CompilationUnit unit;

  final patches = <String, Declaration>{};
  final mergeMembers = <String, List<ClassMember>>{};
  final mergeDeclarations = <CompilationUnitMember>[];

  PatchFinder.parseAndVisit(String contents, {bool useNnbd})
      : contents = contents,
        unit = _parseString(contents, useNnbd: useNnbd).unit {
    visitCompilationUnit(unit);
  }

  @override
  void visitCompilationUnitMember(CompilationUnitMember node) {
    mergeDeclarations.add(node);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    if (_isPatch(node)) {
      var members = <ClassMember>[];
      for (var member in node.members) {
        if (_isPatch(member)) {
          patches[_qualifiedName(member)] = member;
        } else {
          members.add(member);
        }
      }
      if (members.isNotEmpty) {
        mergeMembers[_qualifiedName(node)] = members;
      }
    } else {
      mergeDeclarations.add(node);
    }
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (_isPatch(node)) {
      patches[_qualifiedName(node)] = node;
    } else {
      mergeDeclarations.add(node);
    }
  }

  @override
  void visitFunctionBody(node) {} // skip method bodies
}

String _qualifiedName(Declaration node) {
  var result = '';

  var parent = node.parent;
  if (parent is ClassDeclaration) {
    result = '${parent.name.name}.';
  }

  var name = (node as dynamic).name as SimpleIdentifier;
  if (name != null) result += name.name;

  // Make sure setters and getters don't collide.
  if (node is FunctionDeclaration && node.isSetter ||
      node is MethodDeclaration && node.isSetter) {
    result += '=';
  }

  return result;
}

bool _isPatch(AnnotatedNode node) => node.metadata.any(_isPatchAnnotation);

bool _isPatchAnnotation(Annotation m) =>
    m.name.name == 'patch' && m.constructorName == null && m.arguments == null;

/// Editable string buffer.
///
/// Applies a series of edits (insertions, removals, replacements) using
/// original location information, and composes them into the edited string.
///
/// For example, starting with a parsed AST with original source locations,
/// this type allows edits to be made without regards to other edits.
class StringEditBuffer {
  final String original;
  final _edits = <_StringEdit>[];

  /// Creates a new transaction.
  StringEditBuffer(this.original);

  bool get hasEdits => _edits.isNotEmpty;

  /// Edit the original text, replacing text on the range [begin] and
  /// exclusive [end] with the [replacement] string.
  void replace(int begin, int end, String replacement) {
    _edits.add(_StringEdit(begin, end, replacement));
  }

  /// Insert [string] at [offset].
  /// Equivalent to `replace(offset, offset, string)`.
  void insert(int offset, String string) => replace(offset, offset, string);

  /// Remove text from the range [begin] to exclusive [end].
  /// Equivalent to `replace(begin, end, '')`.
  void remove(int begin, int end) => replace(begin, end, '');

  /// Applies all pending [edit]s and returns a new string.
  ///
  /// This method is non-destructive: it does not discard existing edits or
  /// change the [original] string. Further edits can be added and this method
  /// can be called again.
  ///
  /// Throws [UnsupportedError] if the edits were overlapping. If no edits were
  /// made, the original string will be returned.
  @override
  String toString() {
    var sb = StringBuffer();
    if (_edits.isEmpty) return original;

    // Sort edits by start location.
    _edits.sort();

    var consumed = 0;
    for (var edit in _edits) {
      if (consumed > edit.begin) {
        sb = StringBuffer();
        sb.write('overlapping edits. Insert at offset ');
        sb.write(edit.begin);
        sb.write(' but have consumed ');
        sb.write(consumed);
        sb.write(' input characters. List of edits:');
        for (var e in _edits) {
          sb.write('\n    ');
          sb.write(e);
        }
        throw UnsupportedError(sb.toString());
      }

      // Add characters from the original string between this edit and the last
      // one, if any.
      var betweenEdits = original.substring(consumed, edit.begin);
      sb.write(betweenEdits);
      sb.write(edit.replace);
      consumed = edit.end;
    }

    // Add any text from the end of the original string that was not replaced.
    sb.write(original.substring(consumed));
    return sb.toString();
  }
}

class _StringEdit implements Comparable<_StringEdit> {
  final int begin;
  final int end;
  final String replace;

  _StringEdit(this.begin, this.end, this.replace);

  int get length => end - begin;

  @override
  String toString() => '(Edit @ $begin,$end: "$replace")';

  @override
  int compareTo(_StringEdit other) {
    var diff = begin - other.begin;
    if (diff != 0) return diff;
    return end - other.end;
  }
}

ParseStringResult _parseString(String source, {bool useNnbd}) {
  var features = FeatureSet.fromEnableFlags2(
    sdkLanguageVersion: Version.parse('2.10.0'),
    flags: [if (useNnbd) 'non-nullable'],
  );
  return parseString(content: source, featureSet: features);
}

/// Use the data from a libraries.json specification to generate the contents
/// of `sdk/lib/_internal/sdk_library_metadata/lib/libraries.dart`, which is
/// needed by dartdevc-legacy and dartanalyzer.
String _generateLibrariesDart(
    Uri libBaseUri, TargetLibrariesSpecification specification, bool usdNnbd) {
  var contents = StringBuffer();
  contents.write(_LIBRARIES_DART_PREFIX);
  for (var library in specification.allLibraries) {
    var path = relativizeLibraryUri(libBaseUri, library.uri, usdNnbd);
    contents.write('  "${library.name}": \n'
        '      const LibraryInfo("$path",\n'
        '          categories: "Client,Server"),\n');
  }
  contents.write(_LIBRARIES_DART_SUFFIX);
  return '$contents';
}

String relativizeLibraryUri(Uri libRoot, Uri uri, bool useNnbd) {
  var relativePath = relativizeUri(libRoot, uri, isWindows);
  // During the nnbd-migration we may have paths that reach out into the
  // non-nnbd directory.
  if (relativePath.startsWith('..')) {
    if (!useNnbd || !relativePath.startsWith('../../sdk/lib/')) {
      print("error: can't handle libraries that live out of the sdk folder"
          ': $relativePath');
      exit(1);
    }
    relativePath = relativePath.replaceFirst('../../sdk/lib/', '');
  }
  return relativePath;
}

final _LIBRARIES_DART_PREFIX = r'''
library libraries;

const int DART2JS_PLATFORM = 1;
const int VM_PLATFORM = 2;

enum Category { client, server, embedded }

Category parseCategory(String name) {
  switch (name) {
    case "Client":
      return Category.client;
    case "Server":
      return Category.server;
    case "Embedded":
      return Category.embedded;
  }
  return null;
}

const Map<String, LibraryInfo> libraries = const {
''';

final _LIBRARIES_DART_SUFFIX = r'''
};

class LibraryInfo {
  final String path;
  final String _categories;
  final String dart2jsPath;
  final String dart2jsPatchPath;
  final bool documented;
  final int platforms;
  final bool implementation;
  final Maturity maturity;

  const LibraryInfo(this.path,
      {String categories: "",
      this.dart2jsPath,
      this.dart2jsPatchPath,
      this.implementation: false,
      this.documented: true,
      this.maturity: Maturity.UNSPECIFIED,
      this.platforms: DART2JS_PLATFORM | VM_PLATFORM})
      : _categories = categories;

  bool get isDart2jsLibrary => (platforms & DART2JS_PLATFORM) != 0;
  bool get isVmLibrary => (platforms & VM_PLATFORM) != 0;
  List<Category> get categories {
    // `"".split(,)` returns [""] not [], so we handle that case separately.
    if (_categories == "") return const <Category>[];
    return _categories.split(",").map(parseCategory).toList();
  }

  bool get isInternal => categories.isEmpty;
  String get categoriesString => _categories;
}

class Maturity {
  final int level;
  final String name;
  final String description;

  const Maturity(this.level, this.name, this.description);

  String toString() => "$name: $level\n$description\n";

  static const Maturity DEPRECATED = const Maturity(0, "Deprecated",
      "This library will be remove before next major release.");

  static const Maturity EXPERIMENTAL = const Maturity(
      1,
      "Experimental",
      "This library is experimental and will likely change or be removed\n"
          "in future versions.");

  static const Maturity UNSTABLE = const Maturity(
      2,
      "Unstable",
      "This library is in still changing and have not yet endured\n"
          "sufficient real-world testing.\n"
          "Backwards-compatibility is NOT guaranteed.");

  static const Maturity WEB_STABLE = const Maturity(
      3,
      "Web Stable",
      "This library is tracking the DOM evolution as defined by WC3.\n"
          "Backwards-compatibility is NOT guaranteed.");

  static const Maturity STABLE = const Maturity(
      4,
      "Stable",
      "The library is stable. API backwards-compatibility is guaranteed.\n"
          "However implementation details might change.");

  static const Maturity LOCKED = const Maturity(5, "Locked",
      "This library will not change except when serious bugs are encountered.");

  static const Maturity UNSPECIFIED = const Maturity(-1, "Unspecified",
      "The maturity for this library has not been specified.");
}
''';
