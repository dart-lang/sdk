#!/usr/bin/env dart
// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Command line tool to merge the SDK libraries and our patch files.
/// This is currently designed as an offline tool, but we could automate it.

import 'dart:io';
import 'dart:isolate' show RawReceivePort;
import 'dart:async';
import 'dart:math' as math;
import 'dart:convert' show JSON;

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:path/path.dart' as path;

import 'package:front_end/front_end.dart';
import 'package:front_end/src/base/processed_options.dart';
import 'package:front_end/src/kernel_generator_impl.dart';
import 'package:front_end/src/fasta/util/relativize.dart' show relativizeUri;

import 'package:front_end/src/fasta/fasta.dart' as fasta show getDependencies;
import 'package:front_end/src/fasta/kernel/utils.dart' show writeProgramToFile;

import 'package:kernel/target/targets.dart';
import 'package:kernel/target/vm_fasta.dart';
import 'package:kernel/target/flutter_fasta.dart';
import 'package:compiler/src/kernel/dart2js_target.dart' show Dart2jsTarget;

/// Set of input files that were read by this script to generate patched SDK.
/// We will dump it out into the depfile for ninja to use.
///
/// For more information see GN and Ninja references:
///    https://chromium.googlesource.com/chromium/src/+/56807c6cb383140af0c03da8f6731d77785d7160/tools/gn/docs/reference.md#depfile_string_File-name-for-input-dependencies-for-actions
///    https://ninja-build.org/manual.html#_depfile
///
final deps = new Set<Uri>();

/// Create [File] object from the given path and register it as a dependency.
File getInputFile(String path, {canBeMissing: false}) {
  final file = new File(path);
  if (!file.existsSync()) {
    if (!canBeMissing) throw "patch_sdk.dart expects all inputs to exist";
    return null;
  }
  deps.add(Uri.base.resolveUri(file.uri));
  return file;
}

/// Read the given file synchronously as a string and register this path as
/// a dependency.
String readInputFile(String path, {canBeMissing: false}) =>
    getInputFile(path, canBeMissing: canBeMissing)?.readAsStringSync();

Future main(List<String> argv) async {
  var port = new RawReceivePort();
  try {
    await _main(argv);
  } finally {
    port.close();
  }
}

void usage(String mode) {
  var base = path.fromUri(Platform.script);
  final self = path.relative(base);
  print('Usage: $self $mode SDK_DIR PATCH_DIR OUTPUT_DIR PACKAGES');

  final repositoryDir = path.relative(path.dirname(path.dirname(base)));
  final sdkExample = path.relative(path.join(repositoryDir, 'sdk'));
  final patchExample = path.relative(
      path.join(repositoryDir, 'out', 'DebugX64', 'obj', 'gen', 'patch'));
  final outExample = path.relative(
      path.join(repositoryDir, 'out', 'DebugX64', 'obj', 'gen', 'patched_sdk'));
  final packagesExample = path.relative(path.join(repositoryDir, '.packages'));
  print('For example:');
  print('\$ $self vm $sdkExample $patchExample $outExample $packagesExample');

  exit(1);
}

const validModes = const ['vm', 'dart2js', 'flutter'];
String mode;
bool get forVm => mode == 'vm';
bool get forFlutter => mode == 'flutter';
bool get forDart2js => mode == 'dart2js';

Future _main(List<String> argv) async {
  if (argv.isEmpty) usage('[${validModes.join('|')}]');
  mode = argv.first;
  if (!validModes.contains(mode)) usage('[${validModes.join('|')}]');
  if (argv.length != 5) usage(mode);

  var input = argv[1];
  var sdkLibIn = path.join(input, 'lib');
  var patchIn = argv[2];
  var outDir = argv[3];
  var outDirUri = Uri.base.resolveUri(new Uri.directory(outDir));
  var sdkOut = path.join(outDir, 'lib');
  var packagesFile = argv[4];

  // Parse libraries.dart
  var libContents = readInputFile(path.join(
      sdkLibIn, '_internal', 'sdk_library_metadata', 'lib', 'libraries.dart'));
  libContents = _updateLibraryMetadata(sdkOut, libContents);
  var sdkLibraries = _getSdkLibraries(libContents);

  Map<String, String> locations = <String, String>{};

  // Enumerate core libraries and apply patches
  for (SdkLibrary library in sdkLibraries) {
    if (forDart2js && library.isVmLibrary) continue;
    if (!forDart2js && library.isDart2JsLibrary) continue;
    _applyPatch(library, sdkLibIn, patchIn, sdkOut, locations);
  }

  _copyExtraLibraries(sdkOut, locations);

  Uri platform = outDirUri.resolve('platform.dill.tmp');
  Uri outline = outDirUri.resolve('outline.dill');
  Uri librariesJson = outDirUri.resolve("lib/libraries.json");
  Uri packages = Uri.base.resolveUri(new Uri.file(packagesFile));

  await _writeSync(
      librariesJson.toFilePath(), JSON.encode({"libraries": locations}));

  var flags = new TargetFlags();
  var target = forVm
      ? new VmFastaTarget(flags)
      : (forFlutter ? new FlutterFastaTarget(flags) : new Dart2jsTarget(flags));
  var platformDeps =
      await compilePlatform(outDirUri, target, packages, platform, outline);
  deps.addAll(platformDeps);

  if (forVm) {
    // TODO(sigmund): add support for the flutter vmservice_sky as well.
    var vmserviceName = 'vmservice_io';
    var base = path.fromUri(Platform.script);
    Uri dartDir =
        new Uri.directory(path.dirname(path.dirname(path.absolute(base))));
    var program = await kernelForProgram(
        Uri.parse('dart:$vmserviceName'),
        new CompilerOptions()
          ..sdkSummary = outline
          ..dartLibraries = <String, Uri>{
            '_vmservice': outDirUri.resolve('lib/vmservice/vmservice.dart'),
            'vmservice_io':
                dartDir.resolve('runtime/bin/vmservice/vmservice_io.dart'),
          }
          ..packagesFileUri = packages);
    Uri vmserviceUri = outDirUri.resolve('$vmserviceName.dill');
    await writeProgramToFile(program, vmserviceUri);
  }

  Uri platformFinalLocation = outDirUri.resolve('platform.dill');

  // We generate a dependency file for GN to properly regenerate the patched sdk
  // folder, outline.dill and platform.dill files when necessary: either when
  // the sdk sources change or when this script is updated. In particular:
  //
  //  - sdk changes: we track the actual sources we are compiling. If we are
  //    building the dart2js sdk, this includes the dart2js-specific patch
  //    files.
  //
  //    These files are tracked by [deps] and passed below to [writeDepsFile] in
  //    the extraDependencies argument.
  //
  //  - script updates: we track this script file and any code it imports (even
  //    sdk libraries). Note that this script runs on the standalone VM, so any
  //    sdk library used by this script indirectly depends on a VM-specific
  //    patch file.
  //
  //    These set of files is discovered by `getDependencies` below, and the
  //    [platformForDeps] is always the VM-specific `platform.dill` file.
  var platformForDeps = platform;
  var sdkDir = outDirUri;
  if (forDart2js || forFlutter) {
    // Note: this would fail if `../patched_sdk/platform.dill` doesn't exist. We
    // added an explicit dependency in the .GN rules so patched_dart2js_sdk (and
    // patched_flutter_sdk) depend on patched_sdk to ensure that it exists.
    platformForDeps = outDirUri.resolve('../patched_sdk/platform.dill');
    sdkDir = outDirUri.resolve('../patched_sdk/');
  }
  deps.addAll(await fasta.getDependencies(Platform.script,
      sdk: sdkDir, packages: packages, platform: platformForDeps));
  await writeDepsFile(Uri.base.resolveUri(new Uri.file("$outDir.d")),
      platformFinalLocation, deps);
  await new File.fromUri(platform).rename(platformFinalLocation.toFilePath());
}

/// Generates an outline.dill and platform.dill file containing the result of
/// compiling a platform's SDK.
///
/// Returns a list of dependencies read by the compiler. This list can be used
/// to create GN dependency files.
Future<List<Uri>> compilePlatform(Uri patchedSdk, Target target, Uri packages,
    Uri fullOutput, Uri outlineOutput) async {
  var options = new CompilerOptions()
    ..strongMode = false
    ..compileSdk = true
    ..sdkRoot = patchedSdk
    ..packagesFileUri = packages
    ..chaseDependencies = true
    ..target = target;

  var result = await generateKernel(
      new ProcessedOptions(
          options,
          // TODO(sigmund): pass all sdk libraries needed here, and make this
          // hermetic.
          false,
          [Uri.parse('dart:core')]),
      buildSummary: true,
      buildProgram: true);
  new File.fromUri(outlineOutput).writeAsBytesSync(result.summary);
  await writeProgramToFile(result.program, fullOutput);
  return result.deps;
}

Future writeDepsFile(
    Uri output, Uri depsFile, Iterable<Uri> allDependencies) async {
  if (allDependencies.isEmpty) return;
  String toRelativeFilePath(Uri uri) {
    // Ninja expects to find file names relative to the current working
    // directory. We've tried making them relative to the deps file, but that
    // doesn't work for downstream projects. Making them absolute also
    // doesn't work.
    //
    // We can test if it works by running ninja twice, for example:
    //
    //     ninja -C xcodebuild/ReleaseX64 runtime_kernel -d explain
    //     ninja -C xcodebuild/ReleaseX64 runtime_kernel -d explain
    //
    // The second time, ninja should say:
    //
    //     ninja: Entering directory `xcodebuild/ReleaseX64'
    //     ninja: no work to do.
    //
    // It's broken if it says something like this:
    //
    //     ninja explain: expected depfile 'patched_sdk.d' to mention
    //     'patched_sdk/platform.dill', got
    //     '/.../xcodebuild/ReleaseX64/patched_sdk/platform.dill'
    return Uri.parse(relativizeUri(uri, base: Uri.base)).toFilePath();
  }

  StringBuffer sb = new StringBuffer();
  sb.write(toRelativeFilePath(output));
  sb.write(":");
  for (Uri uri in allDependencies) {
    sb.write(" ");
    sb.write(toRelativeFilePath(uri));
  }
  sb.writeln();
  await new File.fromUri(depsFile).writeAsString("$sb");
}

/// Updates the contents of
/// sdk/lib/_internal/sdk_library_metadata/lib/libraries.dart to include
/// declarations for vm internal libraries.
String _updateLibraryMetadata(String sdkOut, String libContents) {
  if (!forVm && !forFlutter) return libContents;
  var extraLibraries = new StringBuffer();
  extraLibraries.write('''
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
  ''');

  if (forFlutter) {
    extraLibraries.write('''
      "ui": const LibraryInfo(
          "ui/ui.dart",
          categories: "Client,Server",
          implementation: true,
          documented: false,
          platforms: VM_PLATFORM),
    ''');
  }

  libContents = libContents.replaceAll(
      ' libraries = const {', ' libraries = const { $extraLibraries');
  _writeSync(
      path.join(
          sdkOut, '_internal', 'sdk_library_metadata', 'lib', 'libraries.dart'),
      libContents);
  return libContents;
}

/// Copy internal libraries that are developed outside the sdk folder into the
/// patched_sdk folder. For the VM< this includes files under 'runtime/bin/',
/// for flutter, this is includes also the ui library.
_copyExtraLibraries(String sdkOut, Map<String, String> locations) {
  if (forDart2js) return;
  var base = path.fromUri(Platform.script);
  var dartDir = path.dirname(path.dirname(path.absolute(base)));

  var builtinLibraryIn = path.join(dartDir, 'runtime', 'bin', 'builtin.dart');
  var builtinLibraryOut = path.join(sdkOut, '_builtin', '_builtin.dart');
  _writeSync(builtinLibraryOut, readInputFile(builtinLibraryIn));
  locations['_builtin'] = path.join('_builtin', '_builtin.dart');

  if (forFlutter) {
    // Flutter repo has this layout:
    //  engine/src/
    //       dart/
    //       flutter/
    var srcDir = path.dirname(path.dirname(path.dirname(path.absolute(base))));
    var uiLibraryInDir = path.join(srcDir, 'flutter', 'lib', 'ui');
    for (var file in new Directory(uiLibraryInDir).listSync()) {
      if (!file.path.endsWith('.dart')) continue;
      var name = path.basename(file.path);
      var uiLibraryOut = path.join(sdkOut, 'ui', name);
      _writeSync(uiLibraryOut, readInputFile(file.path));
    }
    locations['ui'] = 'ui/ui.dart';
  }
}

_applyPatch(SdkLibrary library, String sdkLibIn, String patchIn, String sdkOut,
    Map<String, String> locations) {
  var libraryOut = path.join(sdkLibIn, library.path);
  var libraryIn = libraryOut;

  var libraryFile = getInputFile(libraryIn, canBeMissing: true);
  if (libraryFile != null) {
    locations[Uri.parse(library.shortName).path] =
        path.relative(libraryOut, from: sdkLibIn);
    var outPaths = <String>[libraryOut];
    var libraryContents = libraryFile.readAsStringSync();

    int inputModifyTime = libraryFile.lastModifiedSync().millisecondsSinceEpoch;
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
      inputModifyTime = math.max(
          inputModifyTime, patchFile.lastModifiedSync().millisecondsSinceEpoch);
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
          outFile.lastModifiedSync().millisecondsSinceEpoch < inputModifyTime) {
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
  var libraryBuilder = new SdkLibrariesReader_LibraryBuilder(forDart2js);
  parseCompilationUnit(contents).accept(libraryBuilder);
  return libraryBuilder.librariesMap.sdkLibraries;
}
