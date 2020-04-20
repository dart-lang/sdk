// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';
import 'package:args/src/arg_parser.dart';
import 'package:path/path.dart' as path;

class MigrateOptions {
  static const applyChangesOption = 'apply-changes';
  static const debugOption = 'debug';
  static const ignoreErrorsOption = 'ignore-errors';
  static const previewPortOption = 'preview-port';
  static const sdkPathOption = 'sdk-path';
  static const serverPathOption = 'server-path';
  static const webPreviewOption = 'web-preview';

  final bool applyChanges;
  final bool debug;
  final String directory;
  final bool ignoreErrors;
  final int previewPort;
  final String serverPath;
  final String sdkPath;
  final bool webPreview;

  MigrateOptions(ArgResults argResults, this.directory)
      : applyChanges = argResults[applyChangesOption] as bool,
        debug = argResults[debugOption] as bool,
        ignoreErrors = argResults[ignoreErrorsOption] as bool,
        previewPort =
            int.tryParse(argResults[previewPortOption] as String) ?? 0,
        sdkPath = argResults[sdkPathOption] as String,
        serverPath = argResults[serverPathOption] as String,
        webPreview = argResults['web-preview'] as bool;

  String get directoryAbsolute => Directory(path.canonicalize(directory)).path;

  @override
  String toString() {
    return '[$directory]';
  }

  static void defineOptions(ArgParser argParser) {
    argParser.addFlag(
      applyChangesOption,
      defaultsTo: false,
      negatable: false,
      help: 'Apply the proposed null safety changes to the files on disk.',
    );
    argParser.addFlag(
      debugOption,
      defaultsTo: false,
      hide: true,
      negatable: true,
      help: 'Show (very verbose) debugging information to stdout during '
          'migration',
    );
    argParser.addFlag(
      ignoreErrorsOption,
      defaultsTo: false,
      negatable: false,
      help: 'Attempt to perform null safety analysis even if there are '
          'analysis errors in the project.',
    );
    argParser.addOption(
      sdkPathOption,
      hide: true,
      help: 'Override the SDK path used for migration.',
    );
    argParser.addOption(
      previewPortOption,
      defaultsTo: '0',
      help: 'Run the preview server on the specified port.  If not specified '
          'or invalid, dynamically allocate a port.',
    );
    argParser.addOption(
      serverPathOption,
      hide: true,
      help: 'Override the analysis server path used for migration.',
    );
    argParser.addFlag(
      webPreviewOption,
      defaultsTo: true,
      negatable: true,
      help: 'Show an interactive preview of the proposed null safety changes '
          'in a browser window.\n'
          'With --no-web-preview, the proposed changes are instead printed to '
          'the console.',
    );
  }
}
