// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// An entrypoint used to measure performance of the incremental compiler.
///
/// Given an input a program and a .json file describing edits, this script will
/// first compile the program, then apply edits, recompile the
/// program, and report relevant metrics.
///
/// The edits are encoded as a JSON array:
///  - Each entry in the array is an iteration of edits and holds a list of
///  individual edits. All changes in one iteration are applied at once
///  before calling [IncrementalKernelGenerator.computeDelta].
///
///  - Each edit is a triple declaring a string replacement operation:
///       [uri, from, to]
///
///    Edits are applied in order, so more than on edit is allowed on the same
///    file.
///
///  For example:
///  [
///    {
///      "name" : "big_change",
///      "edits" : [
///        ["input1.dart", "black", "green"],
///        ["input1.dart", "30px", "10px"],
///        ["input2.dart", "a.toString()", ""$a""]
///      ]
///    },
///    {
///      "name" : "small_change",
///      "edits" : [
///        ["input1.dart", "green", "blue"]
///      ]
///    }
///  ]
///
///  Is interpreted as 2 iterations, the first iteration updates input1.dart
///  with 2 changes, and input2.dart with one change. The second iteration
///  updates input1.dart a second time.
library front_end.tool.incremental_perf;

import 'dart:async';
import 'dart:convert';
import 'dart:io' hide FileSystemEntity;

import 'package:args/args.dart';
import 'package:front_end/src/api_prototype/file_system.dart'
    show FileSystemEntity;
import 'package:front_end/src/api_prototype/front_end.dart';
import 'package:front_end/src/api_prototype/incremental_kernel_generator.dart';
import 'package:front_end/src/api_prototype/memory_file_system.dart';
import 'package:front_end/src/api_prototype/standard_file_system.dart';
import 'package:front_end/src/base/processed_options.dart';
import 'package:front_end/src/fasta/uri_translator.dart';

import 'perf_common.dart';

main(List<String> args) async {
  var options = argParser.parse(args);
  if (options.rest.length != 2) {
    throw """
usage: incremental_perf.dart [options] <entry.dart> <edits.json>
${argParser.usage}""";
  }

  var entryUri = _resolveOverlayUri(options.rest[0]);
  var editsUri = Uri.base.resolve(options.rest[1]);
  var changeSets =
      parse(jsonDecode(new File.fromUri(editsUri).readAsStringSync()));
  bool verbose = options["verbose"];
  bool verboseCompilation = options["verbose-compilation"];
  bool isFlutter = options["target"] == "flutter";
  bool useMinimalGenerator = options["implementation"] == "minimal";
  TimingsCollector collector = new TimingsCollector(verbose);

  for (int i = 0; i < 8; i++) {
    await benchmark(
        collector,
        entryUri,
        isFlutter,
        useMinimalGenerator,
        verbose,
        verboseCompilation,
        changeSets,
        options["sdk-summary"],
        options["sdk-library-specification"],
        options["cache"]);
    if (!options["loop"]) break;
  }
  collector.printTimings();
}

Future benchmark(
    TimingsCollector collector,
    Uri entryUri,
    bool isFlutter,
    bool useMinimalGenerator,
    bool verbose,
    bool verboseCompilation,
    List<ChangeSet> changeSets,
    String sdkSummary,
    String sdkLibrarySpecification,
    String cache) async {
  var overlayFs = new OverlayFileSystem();
  var compilerOptions = new CompilerOptions()
    ..verbose = verboseCompilation
    ..fileSystem = overlayFs
    ..onDiagnostic = onDiagnosticMessageHandler()
    ..target = createTarget(isFlutter: isFlutter)
    ..environmentDefines = const {};
  if (sdkSummary != null) {
    compilerOptions.sdkSummary = _resolveOverlayUri(sdkSummary);
  }
  if (sdkLibrarySpecification != null) {
    compilerOptions.librariesSpecificationUri =
        _resolveOverlayUri(sdkLibrarySpecification);
  }

  var dir = Directory.systemTemp.createTempSync("ikg-cache");

  final processedOptions =
      new ProcessedOptions(options: compilerOptions, inputs: [entryUri]);
  final UriTranslator uriTranslator = await processedOptions.getUriTranslator();

  collector.start("Initial compilation");
  var generator = new IncrementalKernelGenerator(compilerOptions, entryUri);

  var component = await generator.computeDelta();
  collector.stop("Initial compilation");
  if (verbose) {
    print("Libraries changed: ${component.libraries.length}");
  }
  if (component.libraries.length < 1) {
    throw "No libraries were changed";
  }

  for (final ChangeSet changeSet in changeSets) {
    String name = "Change '${changeSet.name}' - Incremental compilation";
    await applyEdits(
        changeSet.edits, overlayFs, generator, uriTranslator, verbose);
    collector.start(name);
    component = await generator.computeDelta();
    collector.stop(name);
    if (verbose) {
      print("Change '${changeSet.name}' - "
          "Libraries changed: ${component.libraries.length}");
    }
    if (component.libraries.length < 1) {
      throw "No libraries were changed";
    }
  }

  dir.deleteSync(recursive: true);
}

/// Apply all edits of a single iteration by updating the copy of the file in
/// the memory file system.
applyEdits(
    List<Edit> edits,
    OverlayFileSystem fs,
    IncrementalKernelGenerator generator,
    UriTranslator uriTranslator,
    bool verbose) async {
  for (var edit in edits) {
    if (verbose) {
      print('edit $edit');
    }
    var uri = edit.uri;
    if (uri.scheme == 'package') uri = uriTranslator.translate(uri);
    generator.invalidate(uri);
    OverlayFileSystemEntity entity = fs.entityForUri(uri);
    var contents = await entity.readAsString();
    entity.writeAsStringSync(
        contents.replaceAll(edit.original, edit.replacement));
  }
}

/// Parse a set of edits from a JSON array. See library comment above for
/// details on the format.
List<ChangeSet> parse(List json) {
  final changeSets = <ChangeSet>[];
  for (final Map jsonChangeSet in json) {
    final edits = <Edit>[];
    for (final jsonEdit in jsonChangeSet['edits']) {
      edits.add(new Edit(jsonEdit[0], jsonEdit[1], jsonEdit[2]));
    }
    changeSets.add(new ChangeSet(jsonChangeSet['name'], edits));
  }
  return changeSets;
}

/// An overlay file system that reads the original contents from the physical
/// file system, but performs updates to those files in memory.
///
/// All files in this file system use a custom URI of the form:
///
///   org-dartlang-overlay:///path/to/file.dart
///
/// This special scheme is mainly used to make it clear that the file belongs to
/// this file system and may not correspond to the contents on disk. However,
/// when the file is read for the first time, it will be retrieved from the
/// underlying file system by using the corresponding `file:*` URI:
///
///   file:///path/to/file.dart
class OverlayFileSystem implements FileSystem {
  final MemoryFileSystem memory =
      new MemoryFileSystem(Uri.parse('org-dartlang-overlay:///'));
  final StandardFileSystem physical = StandardFileSystem.instance;

  @override
  FileSystemEntity entityForUri(Uri uri) {
    if (uri.scheme == 'org-dartlang-overlay') {
      return new OverlayFileSystemEntity(uri, this);
    } else if (uri.scheme == 'file') {
      // The IKG compiler reads ".packages" which might contain absolute file
      // URIs (which it will then try to use on the FS).  We therefore replace
      // them with overlay-fs URIs as usual.
      return new OverlayFileSystemEntity(_resolveOverlayUri('$uri'), this);
    } else {
      throw "Unsupported scheme: ${uri.scheme}."
          " The OverlayFileSystem only accepts URIs"
          " with the 'org-dartlang-overlay' scheme";
    }
  }
}

class OverlayFileSystemEntity implements FileSystemEntity {
  final Uri uri;
  FileSystemEntity _delegate;
  final OverlayFileSystem _fs;

  OverlayFileSystemEntity(this.uri, this._fs);

  Future<FileSystemEntity> get delegate async {
    if (_delegate != null) return _delegate;
    FileSystemEntity entity = _fs.memory.entityForUri(uri);
    if (await entity.exists()) {
      _delegate = entity;
      return _delegate;
    }
    return _delegate = _fs.physical.entityForUri(uri.replace(scheme: 'file'));
  }

  @override
  Future<bool> exists() async => (await delegate).exists();

  @override
  Future<List<int>> readAsBytes() async => (await delegate).readAsBytes();

  @override
  Future<String> readAsString() async => (await delegate).readAsString();

  void writeAsStringSync(String contents) =>
      _fs.memory.entityForUri(uri).writeAsStringSync(contents);
}

/// A string replacement edit in a source file.
class Edit {
  final Uri uri;
  final String original;
  final String replacement;

  Edit(String uriString, this.original, this.replacement)
      : uri = _resolveOverlayUri(uriString);

  String toString() => 'Edit($uri, "$original" -> "$replacement")';
}

/// A named set of changes applied together.
class ChangeSet {
  final String name;
  final List<Edit> edits;

  ChangeSet(this.name, this.edits);

  String toString() => 'ChangeSet($name, $edits)';
}

_resolveOverlayUri(String uriString) {
  Uri result = Uri.base.resolve(uriString);
  return result.isScheme("file")
      ? result.replace(scheme: 'org-dartlang-overlay')
      : result;
}

ArgParser argParser = new ArgParser()
  ..addFlag('verbose-compilation',
      help: 'make the compiler verbose', defaultsTo: false)
  ..addFlag('verbose', help: 'print additional information', defaultsTo: false)
  ..addFlag('loop', help: 'run benchmark 8 times', defaultsTo: true)
  ..addOption('target',
      help: 'target platform', defaultsTo: 'vm', allowed: ['vm', 'flutter'])
  ..addOption('cache',
      help: 'caching policy used by the compiler',
      defaultsTo: 'protected',
      allowed: ['evicting', 'memory', 'protected'])
  // TODO(johnniwinther): Remove mode option. Legacy mode is no longer
  // supported.
  ..addOption('mode',
      help: 'whether to run in strong or legacy mode',
      defaultsTo: 'strong',
      allowed: ['legacy', 'strong'])
  ..addOption('implementation',
      help: 'incremental compiler implementation to use',
      defaultsTo: 'default',
      allowed: ['default', 'minimal'])
  ..addOption('sdk-summary', help: 'Location of the sdk outline.dill file')
  ..addOption('sdk-library-specification',
      help: 'Location of the '
          'sdk/lib/libraries.json file');
