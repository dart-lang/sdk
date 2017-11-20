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
///      "name" : "small_chnage",
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
import 'package:front_end/byte_store.dart';
import 'package:front_end/file_system.dart' show FileSystemEntity;
import 'package:front_end/front_end.dart';
import 'package:front_end/incremental_kernel_generator.dart';
import 'package:front_end/memory_file_system.dart';
import 'package:front_end/physical_file_system.dart';
import 'package:front_end/src/base/processed_options.dart';
import 'package:front_end/src/byte_store/protected_file_byte_store.dart';
import 'package:front_end/src/fasta/uri_translator.dart';
import 'package:kernel/target/flutter.dart';
import 'package:kernel/target/targets.dart';
import 'package:kernel/target/vm.dart';

main(List<String> args) async {
  var options = argParser.parse(args);
  if (options.rest.length != 2) {
    print('usage: incremental_perf.dart [options] <entry.dart> <edits.json>');
    print(argParser.usage);
    exit(1);
  }

  var entryUri = _resolveOverlayUri(options.rest[0]);
  var editsUri = Uri.base.resolve(options.rest[1]);
  var changeSets =
      parse(JSON.decode(new File.fromUri(editsUri).readAsStringSync()));

  var overlayFs = new OverlayFileSystem();
  var targetFlags = new TargetFlags(strongMode: options['mode'] == 'strong');
  var compilerOptions = new CompilerOptions()
    ..fileSystem = overlayFs
    ..strongMode = (options['mode'] == 'strong')
    ..reportMessages = true
    ..onError = onErrorHandler
    ..target = options['target'] == 'flutter'
        ? new FlutterTarget(targetFlags)
        : new VmTarget(targetFlags);

  if (options['sdk-summary'] != null) {
    compilerOptions.sdkSummary = _resolveOverlayUri(options["sdk-summary"]);
  }
  if (options['sdk-library-specification'] != null) {
    compilerOptions.librariesSpecificationUri =
        _resolveOverlayUri(options["sdk-library-specification"]);
  }

  var dir = Directory.systemTemp.createTempSync('ikg-cache');
  compilerOptions.byteStore = createByteStore(options['cache'], dir.path);

  final processedOptions =
      new ProcessedOptions(compilerOptions, false, [entryUri]);
  final UriTranslator uriTranslator = await processedOptions.getUriTranslator();

  var timer1 = new Stopwatch()..start();
  var generator = await IncrementalKernelGenerator.newInstance(
      compilerOptions, entryUri,
      useMinimalGenerator: options['implementation'] == 'minimal');

  var delta = await generator.computeDelta();
  generator.acceptLastDelta();
  timer1.stop();
  print("Libraries changed: ${delta.newProgram.libraries.length}");
  print("Initial compilation took: ${timer1.elapsedMilliseconds}ms");

  for (final ChangeSet changeSet in changeSets) {
    await applyEdits(changeSet.edits, overlayFs, generator, uriTranslator);
    var iterTimer = new Stopwatch()..start();
    delta = await generator.computeDelta();
    generator.acceptLastDelta();
    iterTimer.stop();
    print("Change '${changeSet.name}' - "
        "Libraries changed: ${delta.newProgram.libraries.length}");
    print("Change '${changeSet.name}' - "
        "Incremental compilation took: ${iterTimer.elapsedMilliseconds}ms");
  }

  dir.deleteSync(recursive: true);
}

/// Apply all edits of a single iteration by updating the copy of the file in
/// the memory file system.
applyEdits(List<Edit> edits, OverlayFileSystem fs,
    IncrementalKernelGenerator generator, UriTranslator uriTranslator) async {
  for (var edit in edits) {
    print('edit $edit');
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
  final PhysicalFileSystem physical = PhysicalFileSystem.instance;

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

ByteStore createByteStore(String cachePolicy, String path) {
  switch (cachePolicy) {
    case 'memory':
      return new MemoryByteStore();
    case 'protected':
      return new ProtectedFileByteStore(path);
    case 'evicting':
      return new MemoryCachingByteStore(
          new EvictingFileByteStore(path, 1024 * 1024 * 1024 /* 1G */),
          64 * 1024 * 1024 /* 64M */);
    default:
      throw new UnsupportedError('Unknown cache policy: $cachePolicy');
  }
}

void onErrorHandler(CompilationMessage m) {
  if (m.severity == Severity.internalProblem || m.severity == Severity.error) {
    exitCode = 1;
  }
}

/// A string replacement edit in a source file.
class Edit {
  final Uri uri;
  final String original;
  final String replacement;

  Edit(String uriString, this.original, this.replacement)
      : uri = Uri.base.resolve(uriString);

  String toString() => 'Edit($uri, "$original" -> "$replacement")';
}

/// A named set of changes applied together.
class ChangeSet {
  final String name;
  final List<Edit> edits;

  ChangeSet(this.name, this.edits);

  String toString() => 'ChangeSet($name, $edits)';
}

_resolveOverlayUri(String uriString) =>
    Uri.base.resolve(uriString).replace(scheme: 'org-dartlang-overlay');

ArgParser argParser = new ArgParser()
  ..addOption('target',
      help: 'target platform', defaultsTo: 'vm', allowed: ['vm', 'flutter'])
  ..addOption('cache',
      help: 'caching policy used by the compiler',
      defaultsTo: 'protected',
      allowed: ['evicting', 'memory', 'protected'])
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
