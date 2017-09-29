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
///    [
///      ['input1.dart', 'black', 'green'],
///      ['input1.dart', '30px', '10px'],
///      ['input2.dart', 'a.toString()', '"$a"']
///    ],
///    [
///      ['input1.dart', 'green', 'blue']
///    ],
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
import 'package:front_end/file_system.dart' show FileSystemEntity;
import 'package:front_end/front_end.dart';
import 'package:front_end/incremental_kernel_generator.dart';
import 'package:front_end/memory_file_system.dart';
import 'package:front_end/physical_file_system.dart';
import 'package:kernel/target/flutter_fasta.dart';
import 'package:kernel/target/targets.dart';

main(List<String> args) async {
  var options = argParser.parse(args);
  if (options.rest.length != 2) {
    print('usage: incremental_perf.dart [options] <entry.dart> <edits.json>');
    print(argParser.usage);
    exit(1);
  }

  var entryUri = _resolveOverlayUri(options.rest[0]);
  var editsUri = Uri.base.resolve(options.rest[1]);
  var edits = parse(JSON.decode(new File.fromUri(editsUri).readAsStringSync()));

  var overlayFs = new OverlayFileSystem();
  var compilerOptions = new CompilerOptions()..fileSystem = overlayFs;

  if (options['sdk-summary'] != null) {
    compilerOptions.sdkSummary = _resolveOverlayUri(options["sdk-summary"]);
  } else if (options['sdk-library-specification'] != null) {
    compilerOptions.librariesSpecificationUri =
        _resolveOverlayUri(options["sdk-library-specification"]);
  }
  if (options['target'] == 'flutter') {
    compilerOptions..target = new FlutterFastaTarget(new TargetFlags());
  }

  var timer1 = new Stopwatch()..start();
  var generator =
      await IncrementalKernelGenerator.newInstance(compilerOptions, entryUri);

  var delta = await generator.computeDelta();
  generator.acceptLastDelta();
  timer1.stop();
  print("Libraries changed: ${delta.newProgram.libraries.length}");
  print("Initial compilation took: ${timer1.elapsedMilliseconds}ms");

  for (var iteration in edits) {
    await applyEdits(iteration, overlayFs, generator);
    var iterTimer = new Stopwatch()..start();
    delta = await generator.computeDelta();
    generator.acceptLastDelta();
    iterTimer.stop();
    print("Libraries changed: ${delta.newProgram.libraries.length}");
    print("Incremental compilation took: ${iterTimer.elapsedMilliseconds}ms");
  }
}

/// Apply all edits of a single iteration by updating the copy of the file in
/// the memory file system.
applyEdits(List<Edit> edits, OverlayFileSystem fs,
    IncrementalKernelGenerator generator) async {
  for (var edit in edits) {
    print('update ${edit.uri}');
    generator.invalidate(edit.uri);
    OverlayFileSystemEntity entity = fs.entityForUri(edit.uri);
    var contents = await entity.readAsString();
    entity.writeAsStringSync(
        contents.replaceAll(edit.original, edit.replacement));
  }
}

/// Parse a set of edits from a JSON array. See library comment above for
/// details on the format.
List<List<Edit>> parse(List json) {
  var edits = <List<Edit>>[];
  for (var jsonIteration in json) {
    var iteration = <Edit>[];
    edits.add(iteration);
    for (var jsonEdit in jsonIteration) {
      iteration.add(new Edit(jsonEdit[0], jsonEdit[1], jsonEdit[2]));
    }
  }
  return edits;
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
    if (uri.scheme != 'org-dartlang-overlay') {
      throw "Unsupported scheme: ${uri.scheme}."
          " The OverlayFileSystem only accepts URIs"
          " with the 'org-dartlang-overlay' scheme";
    }
    return new OverlayFileSystemEntity(uri, this);
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
}

_resolveOverlayUri(uriString) =>
    Uri.base.resolve(uriString).replace(scheme: 'org-dartlang-overlay');

ArgParser argParser = new ArgParser()
  ..addOption('target',
      help: 'target platform', defaultsTo: 'vm', allowed: ['vm', 'flutter'])
  ..addOption('sdk-summary', help: 'Location of the sdk outline.dill file')
  ..addOption('sdk-library-specification',
      help: 'Location of the '
          'sdk/lib/libraries.json file');
