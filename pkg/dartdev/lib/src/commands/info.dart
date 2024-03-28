// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:yaml/yaml.dart';

import '../core.dart';
import '../processes.dart';
import '../utils.dart';

/// Print output useful for diagnosing local issues.
class InfoCommand extends DartdevCommand {
  static const String cmdName = 'info';

  static const String cmdDescription =
      'Show diagnostic information about the installed tooling.';

  InfoCommand({bool verbose = false})
      : super(cmdName, cmdDescription, verbose) {
    argParser.addFlag(
      removeFilePathsFlag,
      help: 'Remove file paths in displayed information.',
      defaultsTo: true,
    );
  }

  static const String _message =
      'If providing this information as part of reporting a bug, please review '
      "the information\nbelow to ensure it only contains things you're "
      'comfortable posting publicly.';

  static const String removeFilePathsFlag = 'remove-file-paths';

  @override
  FutureOr<int> run() async {
    final elideFilePaths = argResults!.flag(removeFilePathsFlag);

    print('');
    print(_message);

    print('');
    print('#### General info');
    print('');
    print('- Dart ${Platform.version}');
    print('- on ${Platform.operatingSystem} / '
        '${Platform.operatingSystemVersion}');
    print('- locale is ${Platform.localeName}');

    // project information
    var projectInfo = getProjectInfo(project, onlySimpleDeps: elideFilePaths);
    if (projectInfo != null) {
      print('');
      print('#### Project info');
      print('');
      print("- sdk constraint: '${projectInfo.sdkDependency ?? ''}'");
      print('- dependencies: ${projectInfo.dependencies.join(', ')}');
      print('- dev_dependencies: ${projectInfo.devDependencies.join(', ')}');
      if (projectInfo.elidedDependencies > 0) {
        print('- elided dependencies: ${projectInfo.elidedDependencies}');
      }
    }

    // process information
    var processInfo =
        ProcessInfo.getProcessInfo(elideFilePaths: elideFilePaths);
    if (processInfo != null) {
      print('');
      print('#### Process info');
      print('');

      if (processInfo.isEmpty) {
        print('No Dart processes found.');
      } else {
        var table = MarkdownTable();
        table.startRow()
          ..cell('Memory', right: true)
          ..cell('CPU', right: true)
          ..cell('Elapsed time', right: true)
          ..cell('Command line');

        for (var process in processInfo) {
          var row = table.startRow();
          row.cell('${process.memoryMb} MB', right: true);
          row.cell(
            process.cpuPercent == null
                ? '--'
                : '${process.cpuPercent!.toStringAsFixed(1)}%',
            right: true,
          );
          row.cell(process.elapsedTime ?? '', right: true);
          row.cell(process.commandLine);
        }

        print(table.finish().trimRight());
      }
    }

    return 0;
  }
}

ProjectInfo? getProjectInfo(Project project, {bool onlySimpleDeps = true}) {
  if (!project.hasPubspecFile) {
    return null;
  }

  var pubspec = loadYaml(project.pubspecFile.readAsStringSync()) as Map;
  var elidedDependencies = 0;

  List<String> getDeps(String dependencyType) {
    var deps = pubspec[dependencyType] as Map?;
    var results = <String>[];
    if (deps != null) {
      for (var pkgName in deps.keys) {
        var dep = deps[pkgName];

        // Don't report path: or git: dependencies.
        if (onlySimpleDeps && dep is Map) {
          if (dep.length != 1) {
            elidedDependencies++;
            continue;
          }

          final key = dep.keys.first;
          if (key != 'sdk') {
            elidedDependencies++;
            continue;
          }
        }

        results.add(pkgName);
      }
    }
    return results..sort();
  }

  return ProjectInfo(
    sdkDependency: (pubspec['environment'] as Map?)?['sdk'] as String?,
    dependencies: getDeps('dependencies'),
    devDependencies: getDeps('dev_dependencies'),
    elidedDependencies: elidedDependencies,
  );
}

class ProjectInfo {
  final String? sdkDependency;
  final List<String> dependencies;
  final List<String> devDependencies;
  final int elidedDependencies;

  ProjectInfo({
    required this.sdkDependency,
    required this.dependencies,
    required this.devDependencies,
    required this.elidedDependencies,
  });
}
