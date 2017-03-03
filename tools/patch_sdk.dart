#!/usr/bin/env dart
// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Command line tool to merge the SDK libraries and our patch files.
/// This is currently designed as an offline tool, but we could automate it.

import 'dart:io';
import 'dart:async';
import 'dart:math' as math;

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:path/path.dart' as path;
import 'package:front_end/src/fasta/compile_platform.dart' as compile_platform;

import 'package:front_end/src/fasta/outline.dart' show CompileTask;

import 'package:front_end/src/fasta/compiler_command_line.dart'
    show CompilerCommandLine;

import 'package:front_end/src/fasta/compiler_context.dart' show CompilerContext;

import 'package:front_end/src/fasta/ticker.dart' show Ticker;

/// Set of input files that were read by this script to generate patched SDK.
/// We will dump it out into the depfile for ninja to use.
///
/// For more information see GN and Ninja references:
///    https://chromium.googlesource.com/chromium/src/+/56807c6cb383140af0c03da8f6731d77785d7160/tools/gn/docs/reference.md#depfile_string_File-name-for-input-dependencies-for-actions
///    https://ninja-build.org/manual.html#_depfile
///
final deps = new Set<String>();

/// Create [File] object from the given path and register it as a dependency.
File getInputFile(String path, {canBeMissing: false}) {
  final file = new File(path);
  if (!file.existsSync()) {
    if (!canBeMissing) throw "patch_sdk.dart expects all inputs to exist";
    return null;
  }
  deps.add(file.absolute.path);
  return file;
}

/// Read the given file synchronously as a string and register this path as
/// a dependency.
String readInputFile(String path, {canBeMissing: false}) =>
    getInputFile(path, canBeMissing: canBeMissing)?.readAsStringSync();

Future main(List<String> argv) async {
  var base = path.fromUri(Platform.script);
  var dartDir = path.dirname(path.dirname(path.absolute(base)));

  if (argv.length != 5 || argv.first != 'vm') {
    final self = path.relative(base);
    print('Usage: $self vm SDK_DIR PATCH_DIR OUTPUT_DIR PACKAGES');

    final repositoryDir = path.relative(path.dirname(path.dirname(base)));
    final sdkExample = path.relative(path.join(repositoryDir, 'sdk'));
    final patchExample = path.relative(
        path.join(repositoryDir, 'out', 'DebugX64', 'obj', 'gen', 'patch'));
    final outExample = path.relative(path.join(
        repositoryDir, 'out', 'DebugX64', 'obj', 'gen', 'patched_sdk'));
    print('For example:');
    print('\$ $self vm $sdkExample $patchExample $outExample');

    exit(1);
  }

  var mode = argv[0];
  assert(mode == "vm");
  var input = argv[1];
  var sdkLibIn = path.join(input, 'lib');
  var patchIn = argv[2];
  var outDir = argv[3];
  var sdkOut = path.join(outDir, 'lib');
  var packagesFile = argv[4];

  var privateIn = path.join(input, 'private');
  var INTERNAL_PATH = '_internal/compiler/js_lib/';

  // Copy and patch libraries.dart and version
  var libContents = readInputFile(path.join(
      sdkLibIn, '_internal', 'sdk_library_metadata', 'lib', 'libraries.dart'));
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
  _writeSync(
      path.join(
          sdkOut, '_internal', 'sdk_library_metadata', 'lib', 'libraries.dart'),
      libContents);

  // Parse libraries.dart
  var sdkLibraries = _getSdkLibraries(libContents);

  // Enumerate core libraries and apply patches
  for (SdkLibrary library in sdkLibraries) {
    if (library.isDart2JsLibrary) {
      continue;
    }

    var libraryOut = path.join(sdkLibIn, library.path);
    var libraryIn = libraryOut;

    var libraryFile = getInputFile(libraryIn, canBeMissing: true);
    if (libraryFile != null) {
      var outPaths = <String>[libraryOut];
      var libraryContents = libraryFile.readAsStringSync();

      int inputModifyTime =
          libraryFile.lastModifiedSync().millisecondsSinceEpoch;
      var partFiles = <File>[];
      for (var part in parseDirectives(libraryContents).directives) {
        if (part is PartDirective) {
          var partPath = part.uri.stringValue;
          outPaths.add(path.join(path.dirname(libraryOut), partPath));

          var partFile =
              getInputFile(path.join(path.dirname(libraryIn), partPath));
          partFiles.add(partFile);
          inputModifyTime = math.max(inputModifyTime,
              partFile.lastModifiedSync().millisecondsSinceEpoch);
        }
      }

      // See if we can find a patch file.
      var patchPath = path.join(
          patchIn, path.basenameWithoutExtension(libraryIn) + '_patch.dart');

      var patchFile = getInputFile(patchPath, canBeMissing: true);
      if (patchFile != null) {
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
        if (patchFile != null) {
          var patchContents = patchFile.readAsStringSync();
          contents = _patchLibrary(patchFile.path, contents, patchContents);
        }

        for (var i = 0; i < outPaths.length; i++) {
          _writeSync(outPaths[i], contents[i]);
        }
      }
    }
  }

  for (var tuple in [
    ['_builtin', 'builtin.dart']
  ]) {
    var vmLibrary = tuple[0];
    var dartFile = tuple[1];

    // The "dart:_builtin" library is only available for the DartVM.
    var builtinLibraryIn = path.join(dartDir, 'runtime', 'bin', dartFile);
    var builtinLibraryOut = path.join(sdkOut, vmLibrary, '${vmLibrary}.dart');
    _writeSync(builtinLibraryOut, readInputFile(builtinLibraryIn));
  }

  for (var file in ['loader.dart', 'server.dart', 'vmservice_io.dart']) {
    var libraryIn = path.join(dartDir, 'runtime', 'bin', 'vmservice', file);
    var libraryOut = path.join(sdkOut, 'vmservice_io', file);
    _writeSync(libraryOut, readInputFile(libraryIn));
  }

  // TODO(kustermann): We suppress compiler hints/warnings/errors temporarily
  // because everyone building the `runtime` target will get these now.
  // We should remove the suppression again once the underlying issues have
  // been fixed (either in fasta or the dart files in the patched_sdk).
  final capturedLines = <String>[];
  try {
    final platform = path.join(outDir, 'platform.dill');

    await runZoned(() async {
      await compile_platform.mainEntryPoint(<String>[
        '--packages',
        new Uri.file(packagesFile).toString(),
        new Uri.directory(outDir).toString(),
        platform,
      ]);

      // platform.dill was generated, now generate platform.dill.d depfile
      // that captures all dependencies that participated in the generation.
      // There are two types of dependencies:
      //   (1) all Dart sources that constitute this tool itself
      //   (2) Dart SDK and patch sources.
      // We already collected all inputs from the second category in the deps
      // set. To collect inputs from the first category we actually use Fasta:
      // we ask Fasta to outline patch_sdk.dart and generate a depfile which
      // would list all the sources.
      final depfile = "${outDir}.d";
      await CompilerCommandLine.withGlobalOptions("outline", [
        '--packages',
        new Uri.file(packagesFile).toString(),
        '--platform',
        platform, // platform.dill that was just generated
        Platform.script.toString() // patch_sdk.dart
      ], (CompilerContext c) async {
        CompileTask task =
            new CompileTask(c, new Ticker(isVerbose: c.options.verbose));
        final kernelTarget = await task.buildOutline(null);
        await kernelTarget.writeDepsFile(
            new Uri.file(platform), new Uri.file(depfile));
      });

      // Read depfile generated by Fasta and append deps that we have collected
      // during generation of patched_sdk to it.
      final list = new File(depfile).readAsStringSync().split(':');
      assert(list.length == 2);
      deps.addAll(list[1].split(' ').where((str) => str.isNotEmpty));
      assert(list[0] == 'patched_sdk/platform.dill');
      new File(depfile).writeAsStringSync("${list[0]}: ${deps.join(' ')}\n");
    }, zoneSpecification: new ZoneSpecification(print: (_, _2, _3, line) {
      capturedLines.add(line);
    }));
  } catch (_) {
    for (final line in capturedLines) {
      print(line);
    }
    rethrow;
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
List<String> _patchLibrary(
    String name, List<String> partsContents, String patchContents) {
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

final String injectedCidFields = [
  'Array',
  'ExternalOneByteString',
  'GrowableObjectArray',
  'ImmutableArray',
  'OneByteString',
  'TwoByteString',
  'Bigint'
].map((name) => "static final int cid${name} = 0;").join('\n');

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

    // We inject a number of static fields into dart:internal.ClassID class.
    // These fields represent various VM class ids and are only used to
    // make core libraries compile. Kernel reader will actually ignore these
    // fields and instead inject concrete constants into this class.
    if (node is ClassDeclaration && node.name.name == 'ClassID') {
      code = code.replaceFirst(new RegExp(r'}$'), injectedCidFields + '}');
    }
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
    if (node.isGetter)
      accessor = 'get:';
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
