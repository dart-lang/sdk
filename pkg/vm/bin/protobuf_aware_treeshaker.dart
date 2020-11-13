#!/usr/bin/env dart
// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This program will take a .dill file and do a protobuf aware tree-shaking.
///
/// All fields of GeneratedMessage subclasses that are not accessed with their
/// getter or setter will have their metadata removed from the class definition.
///
/// Then a general treeshaking will be run, and
/// all GeneratedMessage subclasses that are never used directly will be
/// removed.
///
/// The processed program will have observable differences: The tree-shaken
/// fields will be parsed as unknown fields.
/// The toString method will treat the unknown fields as missing.
///
/// Using the `GeneratedMessage.info_` field to reflect on fields will have
/// unpredictable behavior.
///
/// Constants are evaluated, this is mainly to enable detecting
/// `@pragma('vm:entry-point')`.
library vm.protobuf_aware_treeshaker;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:args/args.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/binary/ast_to_binary.dart';
import 'package:vm/kernel_front_end.dart'
    show runGlobalTransformations, ErrorDetector;
import 'package:kernel/target/targets.dart' show TargetFlags, getTarget;
import 'package:meta/meta.dart';
import 'package:vm/target/install.dart' show installAdditionalTargets;
import 'package:vm/transformations/protobuf_aware_treeshaker/transformer.dart'
    as treeshaker;

ArgResults parseArgs(List<String> args) {
  ArgParser argParser = ArgParser()
    ..addOption('platform',
        valueHelp: "path/to/vm_platform.dill",
        help: 'A platform.dill file to append to the input. If not given, no '
            'platform.dill will be appended.')
    ..addOption('target',
        allowed: ['dart_runner', 'flutter', 'flutter-runner', 'vm'],
        defaultsTo: 'vm',
        help: 'Target platform.')
    ..addFlag('aot',
        help: 'If set, produces kernel file for AOT compilation (enables '
            'global transformations). Otherwise, writes regular dill.',
        defaultsTo: false)
    ..addFlag('write-txt',
        help: 'Also write the result in kernel-text format as <out.dill>.txt',
        defaultsTo: false)
    ..addFlag('remove-core-libs',
        help: 'If set, the output dill file will not include `dart:` libraries',
        defaultsTo: false)
    ..addMultiOption('define',
        abbr: 'D',
        help: 'Perform constant evaluation with this environment define set.',
        valueHelp: 'variable=value')
    ..addFlag('remove-source',
        help: 'Removes source code from the emitted dill', defaultsTo: false)
    ..addFlag('verbose',
        help: 'Write to stdout about what classes and fields where remeoved')
    ..addFlag('help', help: 'Prints this help', negatable: false);

  ArgResults argResults;
  try {
    argResults = argParser.parse(args);
  } on FormatException catch (e) {
    print(e.message);
  }

  if (argResults == null || argResults['help'] || argResults.rest.length != 2) {
    String script = 'protobuf_aware_treeshaker.dart';
    print(
        'A tool for removing protobuf messages types that are never referred by a program');
    print('Usage: $script [args] <input.dill> <output.dill>');

    print(argParser.usage);
    exit(-1);
  }

  if (argResults['aot'] && argResults['remove-core-libs']) {
    print('The `--aot` option is incompatible with `--remove-core-libs`');
    exit(-1);
  }

  return argResults;
}

Future main(List<String> args) async {
  ArgResults argResults = parseArgs(args);

  final input = argResults.rest[0];
  final output = argResults.rest[1];

  final Map<String, String> environment = Map.fromIterable(
      argResults['define'].map((x) => x.split('=')),
      key: (x) => x[0],
      value: (x) => x[1]);

  var bytes = File(input).readAsBytesSync();
  final platformFile = argResults['platform'];
  if (platformFile != null) {
    bytes = concatenate(File(platformFile).readAsBytesSync(), bytes);
  }
  final component = loadComponentFromBytes(bytes);

  installAdditionalTargets();

  final target = getTarget(argResults['target'], TargetFlags());

  // The [component] is treeshaken and has TFA annotations. Write output.
  if (argResults['aot']) {
    const bool useGlobalTypeFlowAnalysis = true;
    const bool enableAsserts = false;
    const bool useProtobufAwareTreeShaker = true;
    const bool useProtobufAwareTreeShakerV2 = false;
    final nopErrorDetector = ErrorDetector();
    runGlobalTransformations(
      target,
      component,
      useGlobalTypeFlowAnalysis,
      enableAsserts,
      useProtobufAwareTreeShaker,
      useProtobufAwareTreeShakerV2,
      nopErrorDetector,
    );
  } else {
    treeshaker.TransformationInfo info = treeshaker.transformComponent(
        component, environment, target,
        collectInfo: argResults['verbose']);

    if (argResults['verbose']) {
      for (String fieldName in info.removedMessageFields) {
        print('Removed $fieldName');
      }
      for (Class removedClass in info.removedMessageClasses) {
        print('Removed $removedClass');
      }
    }
  }

  if (argResults['aot']) {
    // Write kernel file for AOT compilation.
    final sink = File(output).openWrite();
    final printer = BinaryPrinter(sink);
    printer.writeComponentFile(component);
    await sink.close();
  } else {
    // Clean out the AOT-only TFA annotations and write regular dill.
    component.metadata.clear();
    await writeComponent(component, output,
        removeCoreLibs: argResults['remove-core-libs'],
        removeSource: argResults['remove-source']);
  }
  if (argResults['write-txt']) {
    writeComponentToText(component, path: output + '.txt');
  }
}

Uint8List concatenate(Uint8List a, Uint8List b) {
  final bytes = Uint8List(a.length + b.length);
  bytes.setRange(0, a.length, a);
  bytes.setRange(a.length, a.length + b.length, b);
  return bytes;
}

Future writeComponent(Component component, String filename,
    {@required bool removeCoreLibs, @required bool removeSource}) async {
  if (removeSource) {
    component.uriToSource.clear();
  }

  for (final lib in component.libraries) {
    lib.dependencies.clear();
    lib.additionalExports.clear();
    lib.parts.clear();
  }

  final sink = File(filename).openWrite();
  final printer = BinaryPrinter(sink, libraryFilter: (lib) {
    if (removeCoreLibs && isCoreLibrary(lib)) return false;
    if (isLibEmpty(lib)) return false;
    return true;
  }, includeSources: !removeSource);

  printer.writeComponentFile(component);
  await sink.close();
}

bool isLibEmpty(Library lib) {
  return lib.classes.isEmpty &&
      lib.procedures.isEmpty &&
      lib.fields.isEmpty &&
      lib.typedefs.isEmpty;
}

bool isCoreLibrary(Library library) {
  return library.importUri.scheme == 'dart';
}
