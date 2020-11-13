// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:math' as math;

import 'package:path/path.dart' as p;
import 'package:stagehand/stagehand.dart' as stagehand;

import '../core.dart';
import '../sdk.dart';

/// A command to create a new project from a set of templates.
class CreateCommand extends DartdevCommand {
  static const String cmdName = 'create';

  static String defaultTemplateId = 'console-simple';

  static List<String> legalTemplateIds = [
    'console-simple',
    'console-full',
    'package-simple',
    'web-simple'
  ];

  static Iterable<stagehand.Generator> get generators =>
      legalTemplateIds.map(retrieveTemplateGenerator);

  static stagehand.Generator retrieveTemplateGenerator(String templateId) =>
      stagehand.getGenerator(templateId);

  CreateCommand({bool verbose = false})
      : super(cmdName, 'Create a new project.') {
    argParser.addOption(
      'template',
      allowed: legalTemplateIds,
      help: 'The project template to use.',
      defaultsTo: defaultTemplateId,
      abbr: 't',
    );
    argParser.addFlag('pub',
        defaultsTo: true,
        help: "Whether to run 'pub get' after the project has been created.");
    argParser.addFlag(
      'list-templates',
      negatable: false,
      hide: !verbose,
      help: 'List the available templates in JSON format.',
    );
    argParser.addFlag(
      'force',
      negatable: false,
      help: 'Force project generation, even if the target directory already '
          'exists.',
    );
  }

  @override
  String get invocation => '${super.invocation} <directory>';

  @override
  FutureOr<int> run() async {
    if (argResults['list-templates']) {
      log.stdout(_availableTemplatesJson());
      return 0;
    }

    if (argResults.rest.isEmpty) {
      printUsage();
      return 1;
    }

    String templateId = argResults['template'];

    String dir = argResults.rest.first;
    var targetDir = io.Directory(dir);
    if (targetDir.existsSync() && !argResults['force']) {
      log.stderr(
        "Directory '$dir' already exists "
        "(use '--force' to force project generation).",
      );
      return 73;
    }

    log.stdout(
      'Creating ${log.ansi.emphasized(p.absolute(dir))} '
      'using template $templateId...',
    );
    log.stdout('');

    var generator = retrieveTemplateGenerator(templateId);
    await generator.generate(
      p.basename(dir),
      DirectoryGeneratorTarget(generator, io.Directory(dir)),
    );

    if (argResults['pub']) {
      if (!Sdk.checkArtifactExists(sdk.pubSnapshot)) {
        return 255;
      }
      log.stdout('');
      var progress = log.progress('Running pub get');
      var process = await startDartProcess(
        sdk,
        [sdk.pubSnapshot, 'get', '--no-precompile'],
        cwd: dir,
      );

      // Run 'pub get'. We display output from the pub command, but keep the
      // output terse. This is to give the user a sense of the work that pub
      // did without scrolling the previous stdout sections off the screen.
      var buffer = StringBuffer();
      routeToStdout(
        process,
        logToTrace: true,
        listener: (str) {
          // Filter lines like '+ multi_server_socket 1.0.2'.
          if (!str.startsWith('+ ')) {
            buffer.writeln('  $str');
          }
        },
      );
      int code = await process.exitCode;
      if (code != 0) return code;
      progress.finish(showTiming: true);
      log.stdout(buffer.toString().trimRight());
    }

    log.stdout('');
    log.stdout('Created project $dir! In order to get started, type:');
    log.stdout('');
    log.stdout(log.ansi.emphasized('  cd ${p.relative(dir)}'));
    // TODO(devoncarew): Once we have a 'run' command, print out here how to run
    // the app.
    log.stdout('');

    return 0;
  }

  @override
  String get usageFooter {
    int width = legalTemplateIds.map((s) => s.length).reduce(math.max);
    String desc = generators.map((g) {
      String suffix = g.id == defaultTemplateId ? ' (default)' : '';
      return '  ${g.id.padLeft(width)}: ${g.description}$suffix';
    }).join('\n');
    return '\nAvailable templates:\n$desc';
  }

  String _availableTemplatesJson() {
    var items = generators.map((stagehand.Generator generator) {
      var m = {
        'name': generator.id,
        'label': generator.label,
        'description': generator.description,
        'categories': generator.categories
      };

      if (generator.entrypoint != null) {
        m['entrypoint'] = generator.entrypoint.path;
      }

      return m;
    });

    JsonEncoder encoder = const JsonEncoder.withIndent('  ');
    return encoder.convert(items.toList());
  }
}

class DirectoryGeneratorTarget extends stagehand.GeneratorTarget {
  final stagehand.Generator generator;
  final io.Directory dir;

  DirectoryGeneratorTarget(this.generator, this.dir) {
    dir.createSync();
  }

  @override
  Future createFile(String path, List<int> contents) async {
    io.File file = io.File(p.join(dir.path, path));

    String name = p.relative(file.path, from: dir.path);
    log.stdout('  $name');

    await file.create(recursive: true);
    await file.writeAsBytes(contents);
  }
}
