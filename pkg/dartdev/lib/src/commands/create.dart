// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:math' as math;

import 'package:path/path.dart' as p;

import '../core.dart';
import '../sdk.dart';
import '../templates.dart';
import '../utils.dart';

/// A command to create a new project from a set of templates.
class CreateCommand extends DartdevCommand {
  static const String cmdName = 'create';

  static String defaultTemplateId = 'console-simple';

  static final List<String> legalTemplateIds =
      generators.map((generator) => generator.id).toList();

  CreateCommand({bool verbose = false})
      : super(cmdName, 'Create a new Dart project.', verbose) {
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
    final args = argResults!;
    if (args['list-templates']) {
      log.stdout(_availableTemplatesJson());
      return 0;
    }

    if (args.rest.isEmpty) {
      printUsage();
      return 1;
    }

    String templateId = args['template'];

    String dir = args.rest.first;
    var targetDir = io.Directory(dir).absolute;
    dir = targetDir.path;
    if (targetDir.existsSync() && !args['force']) {
      log.stderr(
        "Directory '$dir' already exists "
        "(use '--force' to force project generation).",
      );
      return 73;
    }

    String projectName = p.basename(dir);
    if (projectName == '.') {
      projectName = p.basename(io.Directory.current.path);
    }
    projectName = normalizeProjectName(projectName);

    if (!isValidPackageName(projectName)) {
      log.stderr('"$projectName" is not a valid Dart project name.\n\n'
          'See https://dart.dev/tools/pub/pubspec#name for more information.');
      return 73;
    }

    log.stdout(
      'Creating ${log.ansi.emphasized(projectName)} '
      'using template $templateId...',
    );
    log.stdout('');

    var generator = getGenerator(templateId)!;
    generator.generate(
      projectName,
      DirectoryGeneratorTarget(generator, io.Directory(dir)),
    );

    if (args['pub']) {
      log.stdout('');
      var progress = log.progress('Running pub get');
      var process = await startDartProcess(
        sdk,
        ['pub', 'get'],
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
    log.stdout(
        'Created project $projectName in ${p.relative(dir)}! In order to get '
        'started, run the following commands:');
    log.stdout('');
    log.stdout(generator.getInstallInstructions(
      dir,
      scriptPath: projectName,
    ));
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
    var items = generators.map((Generator generator) {
      var m = {
        'name': generator.id,
        'label': generator.label,
        'description': generator.description,
        'categories': generator.categories
      };

      if (generator.entrypoint != null) {
        m['entrypoint'] = generator.entrypoint!.path;
      }

      return m;
    });

    JsonEncoder encoder = const JsonEncoder.withIndent('  ');
    return encoder.convert(items.toList());
  }
}

class DirectoryGeneratorTarget extends GeneratorTarget {
  final Generator generator;
  final io.Directory dir;

  DirectoryGeneratorTarget(this.generator, this.dir) {
    if (!dir.existsSync()) {
      dir.createSync();
    }
  }

  @override
  void createFile(String path, List<int> contents) {
    io.File file = io.File(p.join(dir.path, path));

    String name = p.relative(file.path, from: dir.path);
    log.stdout('  $name');

    file.createSync(recursive: true);
    file.writeAsBytesSync(contents);
  }
}
