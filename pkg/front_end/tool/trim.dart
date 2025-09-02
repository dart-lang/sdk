#!/usr/bin/env dart
// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';
import 'package:front_end/src/util/trim.dart';
import 'package:kernel/target/targets.dart';
import 'package:vm/modular/target/flutter.dart';

/// Helper script to invoke [createTrimmedCopy] as a command-line tool given a
/// `dynamic_interface.yaml` input file.
Future<void> main(List<String> args) async {
  ArgResults argResults;
  try {
    argResults = _argParser.parse(args);
  } on ArgParserException catch (e) {
    print(e.message);
    print(_argParser.usage);
    exit(1);
  }

  if (args.length < 2) {
    print(_argParser.usage);
    exit(1);
  }
  String? dynamicInterfacePath = argResults['dynamic-interface'] as String?;
  File? dynamicInterface = dynamicInterfacePath != null
      ? File(dynamicInterfacePath)
      : null;
  await createTrimmedCopy(
    TrimOptions(
      inputAppPath: argResults['input'] as String,
      inputPlatformPath: argResults['platform'] as String,
      outputAppPath: argResults['output'] as String,
      outputPlatformPath: argResults['output-platform'] as String?,
      dynamicInterfaceUri: dynamicInterface?.uri,
      dynamicInterfaceContents: dynamicInterface?.readAsStringSync(),
      requiredUserLibraries:
          (argResults['required-user-libraries'] as List<String>).toSet(),
      requiredDartLibraries: FlutterTarget(
        TargetFlags(),
      ).extraRequiredLibraries.toSet(),
      librariesToClear: (argResults['clear-dart-library-body'] as List<String>)
          .toSet(),
    ),
  );
}

final ArgParser _argParser = ArgParser()
  ..addOption(
    'input',
    help: 'Input application dill file path',
    mandatory: true,
  )
  ..addOption(
    'platform',
    help: 'Input platform dill file path',
    mandatory: true,
  )
  ..addOption(
    'output',
    help: 'Output application dill file path',
    mandatory: true,
  )
  ..addOption('output-platform', help: 'Output platform dill file path')
  ..addOption(
    'dynamic-interface',
    help: 'Path to the dynamic_interface.yaml file',
  )
  ..addMultiOption(
    'clear-dart-library-body',
    abbr: 'c',
    help:
        'List of `dart:` that, even though are required, can be cleared '
        'internally since they are only included for compatibility with '
        '"extraRequiredLibraries", but are not needed for compilation',
    defaultsTo: defaultNonProductionLibraries,
  )
  ..addMultiOption(
    'required-user-libraries',
    abbr: 'u',
    help:
        'Alternative to providing a dynamic_interface.yaml input. '
        'Specifies the list of necessary user written '
        'libraries. Can be a full `package:` URI or a prefix pattern, '
        'like `package:foo/*`.',
    defaultsTo: const [],
  );

/// Libraries that are not needed for production builds and that should
/// be possible to clear when trimming .dill files.
const List<String> defaultNonProductionLibraries = [
  'dart:mirrors',
  'dart:developer',
  'dart:ffi',
  'dart:vmservice_io',
  'dart:isolate ',
  'dart:_vmservice',
  'dart:cli',
];
