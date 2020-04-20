// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A runner that executes a pipeline on a folder containing modular tests.
import 'dart:io';

import 'package:args/args.dart';
import 'package:modular_test/src/io_pipeline.dart';
import 'package:modular_test/src/loader.dart';
import 'package:modular_test/src/suite.dart';

import 'generic_runner.dart' as generic;

Uri relativize(Uri uri, Uri base) {
  return Uri.parse(uri.path.substring(base.path.length));
}

Future<void> runSuite(Uri suiteFolder, String suiteName, Options options,
    IOPipeline pipeline) async {
  var dir = Directory.fromUri(suiteFolder);
  var entries = (await dir.list(recursive: false).toList())
      .where((e) => e is Directory)
      .map((e) => new _PipelineTest(e.uri, suiteFolder, options, pipeline))
      .toList();

  await generic.runSuite(
      entries,
      new generic.RunnerOptions()
        ..suiteName = suiteName
        ..configurationName = options.configurationName
        ..filter = options.filter
        ..logDir = options.outputDirectory
        ..shard = options.shard
        ..shards = options.shards
        ..verbose = options.verbose
        ..reproTemplate = '%executable %script --verbose --filter %name');
  await pipeline.cleanup();
}

class _PipelineTest implements generic.Test {
  final String name;
  final Uri uri;
  final Options options;
  final IOPipeline pipeline;

  _PipelineTest(this.uri, Uri suiteFolder, this.options, this.pipeline)
      // Use the name of the folder as the test name by trimming out the prefix
      // from the suite and the trailing `/`.
      : name = uri.path.substring(suiteFolder.path.length, uri.path.length - 1);

  Future<void> run() async {
    ModularTest test = await loadTest(uri);
    if (options.verbose) print(test.debugString());
    await pipeline.run(test);
  }
}

class Options {
  bool showSkipped = false;
  bool verbose = false;
  String filter = null;
  int shards = 1;
  int shard = 1;
  String configurationName;
  Uri outputDirectory;
  bool useSdk = false;

  static Options parse(List<String> args) {
    var parser = new ArgParser()
      ..addFlag('verbose',
          abbr: 'v',
          defaultsTo: false,
          help: 'print detailed information about the test and modular steps')
      ..addFlag('show-skipped',
          defaultsTo: false,
          help: 'print the name of the tests skipped by the filtering option')
      ..addFlag('use-sdk',
          defaultsTo: false, help: 'whether to use snapshots from a built sdk')
      ..addOption('filter',
          help: 'only run tests containing this filter as a substring')
      ..addOption('shards',
          help: 'total number of shards a suite is going to be split into.',
          defaultsTo: '1')
      ..addOption('shard',
          help: 'which shard this script is executing. This should be between 0'
              ' and `shards - 1`.')
      ..addOption('output-directory',
          help: 'location where to emit the jsonl result and log files')
      ..addOption('named-configuration',
          abbr: 'n',
          help: 'configuration name to use for emitting jsonl result files.');
    ArgResults argResults = parser.parse(args);
    int shards = int.tryParse(argResults['shards']) ?? 1;
    int shard;
    if (shards > 1) {
      shard = int.tryParse(argResults['shard']) ?? 1;
      if (shard <= 0 || shard >= shards) {
        print('Error: shard should be between 0 and ${shards - 1},'
            ' but got $shard');
        exit(1);
      }
    }
    Uri toUri(s) => s == null ? null : Uri.base.resolveUri(Uri.file(s));
    return Options()
      ..showSkipped = argResults['show-skipped']
      ..verbose = argResults['verbose']
      ..useSdk = argResults['use-sdk']
      ..filter = argResults['filter']
      ..shards = shards
      ..shard = shard
      ..configurationName = argResults['named-configuration']
      ..outputDirectory = toUri(argResults['output-directory']);
  }
}
