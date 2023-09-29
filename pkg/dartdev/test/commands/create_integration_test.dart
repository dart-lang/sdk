// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dartdev/src/commands/create.dart';
import 'package:dartdev/src/templates.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../utils.dart';

void main() {
  ensureRunFromSdkBinDart();

  group('create integration', defineCreateTests, timeout: longTimeout);
}

void defineCreateTests() {
  // Create tests for each template.
  for (String templateId
      in CreateCommand.legalTemplateIds(includeDeprecated: true)) {
    test(templateId, () async {
      const projectName = 'template_project';
      final p = project();
      final templateGenerator = getGenerator(templateId)!;

      print('$templateId: creating template');
      ProcessResult createResult = await p.run([
        'create',
        '--force',
        '--template',
        templateId,
        projectName,
      ]);
      expect(createResult.exitCode, 0, reason: createResult.stderr);

      // Validate that the project analyzes cleanly.
      print('$templateId: analyzing generated project');
      ProcessResult analyzeResult = await p.runAnalyze(
        ['--fatal-infos', projectName],
        workingDir: p.dir.path,
      );
      expect(analyzeResult.exitCode, 0, reason: analyzeResult.stdout);

      // Validate that the code is well formatted.
      print('$templateId: checking formatting');
      ProcessResult formatResult = await p.run([
        'format',
        '--output',
        'none',
        '--set-exit-if-changed',
        projectName,
      ]);
      expect(formatResult.exitCode, 0, reason: formatResult.stdout);

      // Process the execution instructions provided by the template.
      final runCommands = templateGenerator
          .getInstallInstructions(
            projectName,
            scriptPath: projectName,
          )
          .split('\n')
          // Remove directory change instructions.
          .sublist(1)
          .map((command) => command.trim())
          .map((command) {
        final commandParts = command.split(' ');
        if (command.startsWith('dart ')) {
          return commandParts.sublist(1);
        }
        return commandParts;
      }).toList();

      print('$templateId: running the following commands:');
      for (final command in runCommands) {
        print('  $command');
      }

      final isServerTemplate = templateGenerator.categories.contains('server');
      final isWebTemplate = templateGenerator.categories.contains('web');
      final workingDir = path.join(p.dirPath, projectName);

      // Execute the templates run instructions.
      for (int i = 0; i < runCommands.length; ++i) {
        // The last command is always the command to execute the code generated
        // by the template.
        final isLastCommand = i == runCommands.length - 1;
        final command = runCommands[i];
        Process process;
        print('[${i + 1} / ${runCommands.length}] Running "$command"...');
        if (isLastCommand && isWebTemplate) {
          // The web template uses `webdev` to execute, not `dart`, so don't
          // run the test through the project utility method.
          process = await Process.start(
              path.join(
                p.pubCacheBinPath,
                Platform.isWindows ? '${command.first}.bat' : command.first,
              ),
              [
                ...command.sublist(1),
                'web:0', // Allow for binding to a random available port.
              ],
              workingDirectory: workingDir,
              environment: {
                'PUB_CACHE': p.pubCachePath,
                'PATH': path.dirname(Platform.resolvedExecutable) +
                    (Platform.isWindows ? ';' : ':') +
                    Platform.environment['PATH']!,
              });
        } else {
          process = await p.start(
            command,
            workingDir: workingDir,
          );
        }

        if (isLastCommand && (isServerTemplate || isWebTemplate)) {
          final completer = Completer<void>();
          late StreamSubscription stdoutSub;
          late StreamSubscription stderrSub;
          // Listen for well-known output from specific templates to determine
          // if they've executed correctly. These templates won't exit on their
          // own, so we'll need to terminate the process once we've verified it
          // runs correctly.
          var hasError = false;
          stdoutSub = process.stdout.transform(utf8.decoder).listen((e) {
            print('stdout: $e');
            if (e.contains('[SEVERE]') ||
                (isServerTemplate && e.contains('Server listening on port')) ||
                (isWebTemplate && e.contains('Succeeded after'))) {
              if (e.contains('[SEVERE]')) {
                hasError = true;
              }
              stderrSub.cancel();
              stdoutSub.cancel();
              process.kill();
              completer.complete();
            }
          });
          stderrSub = process.stderr.transform(utf8.decoder).listen((e) {
            print('stderr: $e');
            hasError = true;
            stderrSub.cancel();
            stdoutSub.cancel();
            process.kill();
            completer.complete();
          });
          await completer.future;
          expect(hasError, isFalse, reason: 'Command $command failed.');

          // Since we had to terminate the process manually, we aren't certain
          // as to what the exit code will be on all platforms (should be -15
          // for POSIX systems), so we'll just wait for the process to exit
          // here.
          await process.exitCode;
        } else {
          final output = <String>[];
          final errors = <String>[];
          process.stdout.transform(utf8.decoder).listen(output.add);
          process.stderr.transform(utf8.decoder).listen(errors.add);

          // If the sample should exit on its own, it should always result in
          // an exit code of 0.
          final duration = const Duration(seconds: 60);
          final exitCode =
              await process.exitCode.timeout(duration, onTimeout: () {
            print('Command $command timed out');
            return -1;
          });
          if (exitCode != 0) {
            print('Command $command exited with code $exitCode');
            print('Output: \n${output.join('\n')}');
            print('Errors: \n${errors.join('\n')}');
          }
          expect(exitCode, 0);
        }
        print('[${i + 1} / ${runCommands.length}] Done "$command".');
      }
    });
  }
}
