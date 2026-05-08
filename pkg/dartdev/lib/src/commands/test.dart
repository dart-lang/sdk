// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:dartdev/src/experiments.dart';
import 'package:dartdev/src/progress.dart';
import 'package:pub/pub.dart';

import '../core.dart';
import '../native_assets.dart';
import '../vm_interop_handler.dart';

/// Implement `dart test`.
///
/// This command largely delegates to `pub run test`.
class TestCommand extends DartdevCommand {
  static const String cmdName = 'test';

  final bool nativeAssetsExperimentEnabled;
  final bool dataAssetsExperimentEnabled;

  TestCommand({
    this.nativeAssetsExperimentEnabled = false,
    this.dataAssetsExperimentEnabled = false,
  }) : super(cmdName, 'Run tests for a project.', false);

  // This argument parser is here solely to ensure that VM specific flags are
  // provided before any command and to provide a more consistent help message
  // with the rest of the tool.
  @override
  ArgParser createArgParser() {
    return ArgParser.allowAnything();
  }

  @override
  CommandCategory get commandCategory => CommandCategory.project;

  @override
  void printUsage() {
    print('''Usage: dart test [arguments]

Note: flags and options for this command are provided by the project's package:test dependency.
If package:test is not included as a dev_dependency in the project's pubspec.yaml, no flags or options will be listed.

Run "${runner!.executableName} help" to see global options.''');
  }

  @override
  FutureOr<int> run() async {
    final args = argResults!;

    String? nativeAssets;
    final packageConfigUri = await DartNativeAssetsBuilder.ensurePackageConfig(
      Directory.current.uri,
    );
    if (packageConfigUri != null) {
      final packageConfig = await DartNativeAssetsBuilder.loadPackageConfig(
        packageConfigUri,
      );
      if (packageConfig == null) {
        return DartdevCommand.errorExitCode;
      }
      final runPackageName = await DartNativeAssetsBuilder.findRootPackageName(
        Directory.current.uri,
      );
      if (runPackageName != null) {
        final pubspecUri = await DartNativeAssetsBuilder.findWorkspacePubspec(
          packageConfigUri,
        );
        final builder = DartNativeAssetsBuilder(
          pubspecUri: pubspecUri,
          packageConfigUri: packageConfigUri,
          packageConfig: packageConfig,
          runPackageName: runPackageName,
          includeDevDependencies: true,
          verbose: verbose,
          dataAssetsExperimentEnabled: dataAssetsExperimentEnabled,
        );
        if (!nativeAssetsExperimentEnabled) {
          if (await builder.warnOnNativeAssets()) {
            return DartdevCommand.errorExitCode;
          }
        } else if (await builder.hasHooks()) {
          final assetsYamlFileUri = await progress(
            'Running build hooks',
            builder.compileNativeAssetsJitYamlFile,
          );
          if (assetsYamlFileUri == null) {
            log.stderr('Error: Running build hooks failed.');
            return DartdevCommand.errorExitCode;
          }
          // TODO(https://github.com/dart-lang/sdk/issues/60489): Add a way to
          // package:test to explicitly provide the native_assets.yaml path
          // instead of copying to the workspace .dart_tool.
          final expectedPackageTestLocation = packageConfigUri.resolve(
            'native_assets.yaml',
          );
          if (expectedPackageTestLocation != assetsYamlFileUri) {
            await File.fromUri(
              assetsYamlFileUri,
            ).copy(expectedPackageTestLocation.toFilePath());
          }
          nativeAssets = expectedPackageTestLocation.toFilePath();
        }
      }
    }

    try {
      final testExecutable = await getExecutableForCommand(
        'test:test',
        nativeAssets: nativeAssets,
      );
      final argsRestNoExperimentOrSuppressAnalytics = args.rest
          .where(
            (e) =>
                !e.startsWith('--$experimentFlagName=') &&
                e != '--suppress-analytics',
          )
          .toList();
      log.trace(
        'dart $testExecutable ${argsRestNoExperimentOrSuppressAnalytics.join(' ')}',
      );
      VmInteropHandler.run(
        testExecutable.executable,
        argsRestNoExperimentOrSuppressAnalytics,
        packageConfigOverride: testExecutable.packageConfig!,
        useExecProcess: true,
        // TODO(bkonyi): remove once DartDev moves to AOT and this flag can be
        // provided directly to the process spawned by `dart run` and
        // `dart test`.
        //
        // See https://github.com/dart-lang/sdk/issues/53576
        markMainIsolateAsSystemIsolate: true,
      );
      return 0;
    } on CommandResolutionFailedException catch (e) {
      if (project.hasPubspecFile) {
        print(e.message);
        if (e.issue == CommandResolutionIssue.packageNotFound) {
          print('You need to add a dev_dependency on package:test.');
          print('Try running `dart pub add --dev test`.');
        }
      } else {
        print(
          'No pubspec.yaml file found - run this command in your project folder.',
        );
      }
      if (args.rest.contains('-h') || args.rest.contains('--help')) {
        print('');
        printUsage();
      }
      return DartdevCommand.errorExitCode;
    }
  }
}
