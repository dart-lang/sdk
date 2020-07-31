// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../core.dart';
import '../sdk.dart';
import '../utils.dart';
import 'analyze_impl.dart';

// TODO: Support enable-experiment for 'dart analyze'.

class AnalyzeCommand extends DartdevCommand<int> {
  AnalyzeCommand() : super('analyze', "Analyze the project's Dart code.") {
    argParser
      ..addFlag('fatal-infos',
          help: 'Treat info level issues as fatal.', negatable: false)
      ..addFlag('fatal-warnings',
          help: 'Treat warning level issues as fatal.', defaultsTo: true);
  }

  @override
  String get invocation => '${super.invocation} [<directory>]';

  @override
  FutureOr<int> run() async {
    if (argResults.rest.length > 1) {
      usageException('Only one directory is expected.');
    }

    // find directory from argResults.rest
    var dir = argResults.rest.isEmpty
        ? Directory.current
        : Directory(argResults.rest.single);
    if (!dir.existsSync()) {
      usageException("Directory doesn't exist: ${dir.path}");
    }

    final Completer<void> analysisCompleter = Completer<void>();
    final List<AnalysisError> errors = <AnalysisError>[];

    var progress = log.progress('Analyzing ${path.basename(dir.path)}');

    final AnalysisServer server = AnalysisServer(
      Directory(sdk.sdkPath),
      [dir],
    );

    StreamSubscription<bool> subscription;
    subscription = server.onAnalyzing.listen((bool isAnalyzing) {
      if (!isAnalyzing) {
        analysisCompleter.complete();
        subscription.cancel();
      }
    });
    server.onErrors.listen((FileAnalysisErrors fileErrors) {
      // Record the issues found (but filter out to do comments).
      errors.addAll(fileErrors.errors
          .where((AnalysisError error) => error.type != 'TODO'));
    });

    await server.start();
    // Completing the future in the callback can't fail.
    //ignore: unawaited_futures
    server.onExit.then((int exitCode) {
      if (!analysisCompleter.isCompleted) {
        analysisCompleter.completeError('analysis server exited: $exitCode');
      }
    });

    await analysisCompleter.future;

    progress.finish(showTiming: true);

    errors.sort();

    if (errors.isNotEmpty) {
      final bullet = log.ansi.bullet;

      log.stdout('');

      bool hasErrors = false;
      bool hasWarnings = false;
      bool hasInfos = false;

      for (final AnalysisError error in errors) {
        // error • Message ... at path.dart:line:col • (code)

        var filePath = path.relative(error.file, from: dir.path);
        var severity = error.severity.toLowerCase().padLeft(7);
        if (error.isError) {
          severity = log.ansi.error(severity);
        }

        log.stdout(
          '$severity $bullet '
          '${log.ansi.emphasized(error.messageSentenceFragment)} '
          'at $filePath:${error.startLine}:${error.startColumn} $bullet '
          '(${error.code})',
        );

        if (verbose) {
          var padding = ' '.padLeft(error.severity.length + 2);
          for (var message in error.contextMessages) {
            log.stdout('$padding${message.message} '
                'at ${message.filePath}:${message.line}:${message.column}');
          }
          if (error.correction != null) {
            log.stdout('$padding${error.correction}');
          }
          if (error.url != null) {
            log.stdout('$padding${error.url}');
          }
        }

        hasErrors |= error.isError;
        hasWarnings |= error.isWarning;
        hasInfos |= error.isInfo;
      }

      log.stdout('');

      final errorCount = errors.length;
      log.stdout('$errorCount ${pluralize('issue', errorCount)} found.');

      // Return an error code in the range [0-3] dependent on the severity of
      // the issue(s) found.
      if (hasErrors) {
        return 3;
      }

      bool fatalWarnings = argResults['fatal-warnings'];
      bool fatalInfos = argResults['fatal-infos'];

      if (fatalWarnings && hasWarnings) {
        return 2;
      } else if (fatalInfos && hasInfos) {
        return 1;
      } else {
        return 0;
      }
    } else {
      log.stdout('No issues found!');
      return 0;
    }
  }
}
