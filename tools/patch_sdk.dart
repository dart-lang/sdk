#!/usr/bin/env dart
// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Command line tool to merge the SDK libraries and our patch files.
/// This is currently designed as an offline tool, but we could automate it.

import 'dart:io';
import 'dart:math' as math;

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:path/path.dart' as path;

void main(List<String> argv) {
  var base = path.fromUri(Platform.script);
  var dartDir = path.dirname(path.dirname(path.absolute(base)));

  if (argv.length != 4 ||
      !argv.isEmpty && argv.first != 'vm' && argv.first != 'ddc') {
    var self = path.relative(base);
    print('Usage: $self MODE SDK_DIR PATCH_DIR OUTPUT_DIR');
    print('MODE must be one of ddc or vm.');

    var toolDir = path.relative(path.dirname(base));
    var sdkExample = path.join(toolDir, 'input_sdk');
    var patchExample = path.join(sdkExample, 'patch');
    var outExample =
        path.relative(path.normalize(path.join('gen', 'patched_sdk')));
    print('For example:');
    print('\$ $self ddc $sdkExample $patchExample $outExample');

    var repositoryDir = path.relative(path.dirname(path.dirname(base)));
    sdkExample = path.relative(path.join(repositoryDir, 'sdk'));
    patchExample = path.relative(path.join(repositoryDir, 'out', 'DebugX64',
                                           'obj', 'gen', 'patch'));
    outExample = path.relative(path.join(repositoryDir, 'out', 'DebugX64',
                                         'obj', 'gen', 'patched_sdk'));
    print('or:');
    print('\$ $self vm $sdkExample $patchExample $outExample');

    exit(1);
  }

  var mode = argv[0];
  var input = argv[1];
  var sdkLibIn = path.join(input, 'lib');
  var patchIn = argv[2];
  var sdkOut = path.join(argv[3], 'lib');

  var privateIn = path.join(input, 'private');
  var INTERNAL_PATH = '_internal/compiler/js_lib/';

  // Copy and patch libraries.dart and version
  var libContents = new File(path.join(sdkLibIn, '_internal',
      'sdk_library_metadata', 'lib', 'libraries.dart')).readAsStringSync();
  var patchedLibContents = libContents;
  if (mode == 'vm') {
    libContents = libContents.replaceAll(
        ' libraries = const {',
        ''' libraries = const {

  "_builtin": const LibraryInfo(
      "_builtin/_builtin.dart",
      categories: "Client,Server",
      implementation: true,
      documented: false,
      platforms: VM_PLATFORM),

  "profiler": const LibraryInfo(
      "profiler/profiler.dart",
      maturity: Maturity.DEPRECATED,
      documented: false),

  "_vmservice": const LibraryInfo(
      "vmservice/vmservice.dart",
      implementation: true,
      documented: false,
      platforms: VM_PLATFORM),

  "vmservice_io": const LibraryInfo(
      "vmservice_io/vmservice_io.dart",
      implementation: true,
      documented: false,
      platforms: VM_PLATFORM),

''');
  }
  _writeSync(
      path.join(
          sdkOut, '_internal', 'sdk_library_metadata', 'lib', 'libraries.dart'),
      libContents);
  if (mode == 'ddc') {
    _writeSync(path.join(sdkOut, '..', 'version'),
        new File(path.join(sdkLibIn, '..', 'version')).readAsStringSync());
  }

  // Parse libraries.dart
  var sdkLibraries = _getSdkLibraries(libContents);

  // Enumerate core libraries and apply patches
  for (SdkLibrary library in sdkLibraries) {
    // TODO(jmesserly): analyzer does not handle the default case of
    // "both platforms" correctly, and treats it as being supported on neither.
    // So instead we skip explicitly marked as either VM or dart2js libs.
    if (mode == 'ddc' ? libary.isVmLibrary : library.isDart2JsLibrary) {
      continue;
    }

    var libraryOut = path.join(sdkLibIn, library.path);
    var libraryIn;
    if (mode == 'vm' && library.path.contains('typed_data.dart')) {
      // dart:typed_data is unlike the other libraries in the SDK. The VM does
      // not apply a patch to the base SDK implementation of the library.
      // Instead, the VM provides a replacement implementation and ignores the
      // sources in the SDK.
      libraryIn =
          path.join(dartDir, 'runtime', 'lib', 'typed_data.dart');
    } else if (mode == 'ddc' && library.path.contains(INTERNAL_PATH)) {
      libraryIn =
          path.join(privateIn, library.path.replaceAll(INTERNAL_PATH, ''));
    } else {
      libraryIn = libraryOut;
    }

    var libraryFile = new File(libraryIn);
    if (libraryFile.existsSync()) {
      var outPaths = <String>[libraryOut];
      var libraryContents = libraryFile.readAsStringSync();

      int inputModifyTime =
          libraryFile.lastModifiedSync().millisecondsSinceEpoch;
      var partFiles = <File>[];
      for (var part in parseDirectives(libraryContents).directives) {
        if (part is PartDirective) {
          var partPath = part.uri.stringValue;
          outPaths.add(path.join(path.dirname(libraryOut), partPath));

          var partFile = new File(path.join(path.dirname(libraryIn), partPath));
          partFiles.add(partFile);
          inputModifyTime = math.max(inputModifyTime,
              partFile.lastModifiedSync().millisecondsSinceEpoch);
        }
      }

      // See if we can find a patch file.
      var patchPath = path.join(
          patchIn, path.basenameWithoutExtension(libraryIn) + '_patch.dart');

      var patchFile = new File(patchPath);
      bool patchExists = patchFile.existsSync();
      if (patchExists) {
        inputModifyTime = math.max(inputModifyTime,
            patchFile.lastModifiedSync().millisecondsSinceEpoch);
      }

      // Compute output paths
      outPaths = outPaths
          .map((p) => path.join(sdkOut, path.relative(p, from: sdkLibIn)))
          .toList();

      // Compare output modify time with input modify time.
      bool needsUpdate = false;
      for (var outPath in outPaths) {
        var outFile = new File(outPath);
        if (!outFile.existsSync() ||
            outFile.lastModifiedSync().millisecondsSinceEpoch <
                inputModifyTime) {
          needsUpdate = true;
          break;
        }
      }

      if (needsUpdate) {
        var contents = <String>[libraryContents];
        contents.addAll(partFiles.map((f) => f.readAsStringSync()));
        if (patchExists) {
          var patchContents = patchFile.readAsStringSync();
          contents = _patchLibrary(
              patchFile.path, contents, patchContents);
        }

        for (var i = 0; i < outPaths.length; i++) {
          if (path.basename(outPaths[i]) == 'internal.dart') {
            contents[i] += '''

/// Marks a function as an external implementation ("native" in the Dart VM).
///
/// Provides a backend-specific String that can be used to identify the
/// function's implementation
class ExternalName {
  final String name;
  const ExternalName(this.name);
}
''';
          }

          _writeSync(outPaths[i], contents[i]);
        }
      }
    }
  }
  if (mode == 'vm') {

    for (var tuple in [['_builtin', 'builtin.dart']]) {
      var vmLibrary = tuple[0];
      var dartFile = tuple[1];

      // The "dart:_builtin" library is only available for the DartVM.
      var builtinLibraryIn  = path.join(dartDir, 'runtime', 'bin', dartFile);
      var builtinLibraryOut = path.join(sdkOut, vmLibrary, '${vmLibrary}.dart');
      _writeSync(builtinLibraryOut, new File(builtinLibraryIn).readAsStringSync());
    }

    for (var file in ['loader.dart', 'server.dart', 'vmservice_io.dart']) {
      var libraryIn  = path.join(dartDir, 'runtime', 'bin', 'vmservice', file);
      var libraryOut = path.join(sdkOut, 'vmservice_io', file);
      _writeSync(libraryOut, new File(libraryIn).readAsStringSync());
    }
  }
}

/// Writes a file, creating the directory if needed.
void _writeSync(String filePath, String contents) {
  var outDir = new Directory(path.dirname(filePath));
  if (!outDir.existsSync()) outDir.createSync(recursive: true);

  new File(filePath).writeAsStringSync(contents);
}

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
List<String> _patchLibrary(String name,
                           List<String> partsContents,
                           String patchContents) {
  var results = <StringEditBuffer>[];

  // Parse the patch first. We'll need to extract bits of this as we go through
  // the other files.
  final patchFinder = new PatchFinder.parseAndVisit(name, patchContents);

  // Merge `external` declarations with the corresponding `@patch` code.
  for (var partContent in partsContents) {
    var partEdits = new StringEditBuffer(partContent);
    var partUnit = parseCompilationUnit(partContent);
    partUnit.accept(new PatchApplier(partEdits, patchFinder));
    results.add(partEdits);
  }

  if (patchFinder.patches.length != patchFinder.applied.length) {
    print('Some elements marked as @patch do not have corresponding elements:');
    for (var patched in patchFinder.patches.keys) {
      if (!patchFinder.applied.contains(patched)) {
        print('*** ${patched}');
      }
    }
    throw "Failed to apply all @patch-es";
  }

  return new List<String>.from(results.map((e) => e.toString()));
}

/// Merge `@patch` declarations into `external` declarations.
class PatchApplier extends GeneralizingAstVisitor {
  final StringEditBuffer edits;
  final PatchFinder patch;

  bool _isLibrary = true; // until proven otherwise.

  PatchApplier(this.edits, this.patch);

  @override
  visitCompilationUnit(CompilationUnit node) {
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
    int importPos = unit.directives
        .lastWhere((d) => d is ImportDirective, orElse: () => libDir)
        .end;
    for (var d in patch.unit.directives.where((d) => d is ImportDirective)) {
      _merge(d, importPos);
    }

    int partPos = unit.directives.last.end;
    for (var d in patch.unit.directives.where((d) => d is PartDirective)) {
      _merge(d, partPos);
    }

    // Merge declarations from the patch
    int declPos = edits.original.length;
    for (var d in patch.mergeDeclarations) {
      _merge(d, declPos);
    }
  }

  @override
  visitPartOfDirective(PartOfDirective node) {
    _isLibrary = false;
  }

  @override
  visitFunctionDeclaration(FunctionDeclaration node) {
    _maybePatch(node);
  }

  /// Merge patches and extensions into the class
  @override
  visitClassDeclaration(ClassDeclaration node) {
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

  void _maybePatch(AstNode node) {
    if (node is FieldDeclaration) return;

    var externalKeyword = (node as dynamic).externalKeyword;

    var name = _qualifiedName(node);
    var patchNode = patch.patches[name];
    if (patchNode == null) {
      if (externalKeyword != null) {
        print('warning: patch not found for $name: $node');
      }
      return;
    }
    patch.applied.add(name);

    Annotation patchMeta = patchNode.metadata.lastWhere(_isPatchAnnotation);
    int start = patchMeta.endToken.next.offset;
    var code = patch.contents.substring(start, patchNode.end);

    // For some node like static fields, the node's offset doesn't include
    // the external keyword. Also starting from the keyword lets us preserve
    // documentation comments.
    edits.replace(externalKeyword?.offset ?? node.offset, node.end, code);
  }
}

class PatchFinder extends GeneralizingAstVisitor {
  final String contents;
  final CompilationUnit unit;

  final Map patches = <String, Declaration>{};
  final Map mergeMembers = <String, List<ClassMember>>{};
  final List mergeDeclarations = <CompilationUnitMember>[];
  final Set<String> applied = new Set<String>();

  PatchFinder.parseAndVisit(String name, String contents)
      : contents = contents,
        unit = parseCompilationUnit(contents, name: name) {
    visitCompilationUnit(unit);
  }

  @override
  visitCompilationUnitMember(CompilationUnitMember node) {
    mergeDeclarations.add(node);
  }

  @override
  visitClassDeclaration(ClassDeclaration node) {
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
  visitFunctionDeclaration(FunctionDeclaration node) {
    if (_isPatch(node)) {
      patches[_qualifiedName(node)] = node;
    } else {
      mergeDeclarations.add(node);
    }
  }

  @override
  visitFunctionBody(node) {} // skip method bodies
}

String _qualifiedName(Declaration node) {
  var parent = node.parent;
  var className = '';
  if (parent is ClassDeclaration) {
    className = parent.name.name + '.';
  }
  var name = (node as dynamic).name;
  name = (name != null ? name.name : '');

  var accessor = '';
  if (node is MethodDeclaration) {
    if (node.isGetter) accessor = 'get:';
    else if (node.isSetter) accessor = 'set:';
  }
  return className + accessor + name;
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

  bool get hasEdits => _edits.length > 0;

  /// Edit the original text, replacing text on the range [begin] and
  /// exclusive [end] with the [replacement] string.
  void replace(int begin, int end, String replacement) {
    _edits.add(new _StringEdit(begin, end, replacement));
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
  String toString() {
    var sb = new StringBuffer();
    if (_edits.length == 0) return original;

    // Sort edits by start location.
    _edits.sort();

    int consumed = 0;
    for (var edit in _edits) {
      if (consumed > edit.begin) {
        sb = new StringBuffer();
        sb.write('overlapping edits. Insert at offset ');
        sb.write(edit.begin);
        sb.write(' but have consumed ');
        sb.write(consumed);
        sb.write(' input characters. List of edits:');
        for (var e in _edits) {
          sb.write('\n    ');
          sb.write(e);
        }
        throw new UnsupportedError(sb.toString());
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

  String toString() => '(Edit @ $begin,$end: "$replace")';

  int compareTo(_StringEdit other) {
    int diff = begin - other.begin;
    if (diff != 0) return diff;
    return end - other.end;
  }
}

List<SdkLibrary> _getSdkLibraries(String contents) {
  var libraryBuilder = new SdkLibrariesReader_LibraryBuilder(true);
  parseCompilationUnit(contents).accept(libraryBuilder);
  return libraryBuilder.librariesMap.sdkLibraries;
}
