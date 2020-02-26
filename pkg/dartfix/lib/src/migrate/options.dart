// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:args/args.dart';
import 'package:args/src/arg_parser.dart';

class MigrateOptions {
  static const ignoreErrorsOption = 'ignore-errors';
  static const applyChangesOption = 'apply-changes';

  final String directory;
  final bool applyChanges;
  final bool ignoreErrors;
  final bool webPreview;

  MigrateOptions(ArgResults argResults, this.directory)
      : applyChanges = argResults[applyChangesOption] as bool,
        ignoreErrors = argResults[ignoreErrorsOption] as bool,
        webPreview = argResults['web-preview'] as bool;

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
      ignoreErrorsOption,
      defaultsTo: false,
      negatable: false,
      help: 'Attempt to perform null safety analysis even if there are '
          'analysis errors in the project.',
    );
    argParser.addFlag(
      'web-preview',
      defaultsTo: true,
      negatable: true,
      help: 'Show an interactive preview of the proposed null safety changes '
          'in a browser window.\n'
          'With --no-web-preview, the proposed changes are instead printed to '
          'the console.',
    );
  }
}
