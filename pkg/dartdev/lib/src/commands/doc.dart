// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

import 'package:dartdoc/dartdoc.dart';
import 'package:dartdoc/options.dart';
import 'package:path/path.dart' as path;

import '../core.dart';

/// A command to create a new project from a set of templates.
class DocCommand extends DartdevCommand {
  static const String cmdName = 'doc';
  String outputPath;

  DocCommand({bool verbose = false})
      : super(
          cmdName,
          'Generate HTML API documentation from Dart documentation comments.',
          verbose,
        ) {
    outputPath = path.join('.', 'doc', 'api');
    argParser.addOption(
      'output-dir',
      abbr: 'o',
      defaultsTo: outputPath,
      help: 'Output directory',
    );
    argParser.addFlag(
      'validate-links',
      negatable: true,
      help: 'Display context aware warnings for broken links (slow)',
    );
  }

  @override
  String get invocation => '${super.invocation} <input directory>';

  @override
  FutureOr<int> run() async {
    // At least one argument, the input directory, is required.
    if (argResults.rest.isEmpty) {
      usageException("Error: Input directory not specified");
    }

    // Determine input directory.
    final dir = io.Directory(argResults.rest[0]);
    if (!dir.existsSync()) {
      usageException("Error: Input directory doesn't exist: ${dir.path}");
    }

    // Parse options.
    final options = [
      '--input=${dir.path}',
      '--output=${argResults['output-dir']}',
    ];
    if (argResults['validate-links']) {
      options.add('--validate-links');
    } else {
      options.add('--no-validate-links');
    }
    final config = await parseOptions(pubPackageMetaProvider, options);
    if (config == null) {
      // There was an error while parsing options.
      return 2;
    }

    // Call DartDoc.
    if (verbose) {
      log.stdout('Calling DartDoc with the following options: $options');
    }
    final packageConfigProvider = PhysicalPackageConfigProvider();
    final packageBuilder = PubPackageBuilder(
        config, pubPackageMetaProvider, packageConfigProvider);
    final dartdoc = config.generateDocs
        ? await Dartdoc.fromContext(config, packageBuilder)
        : await Dartdoc.withEmptyGenerator(config, packageBuilder);
    dartdoc.executeGuarded();
    return 0;
  }
}
