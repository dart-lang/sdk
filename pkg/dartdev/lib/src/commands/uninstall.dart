// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dartdev/src/core.dart';
import 'package:dartdev/src/install/file_system.dart';

class UninstallCommand extends DartdevCommand {
  static const cmdName = 'uninstall';
  static const cmdDescription = '''Remove a globally installed Dart CLI tool.

Completely deletes all installed versions of <package> and all executables from
<package> placed on PATH.''';

  @override
  String get invocation {
    final superNoArguments = super.invocation.replaceAll(' [arguments]', '');
    return '$superNoArguments <package>';
  }

  @override
  CommandCategory get commandCategory => CommandCategory.global;

  UninstallCommand({bool verbose = false})
    : super(cmdName, cmdDescription, verbose);

  @override
  Future<int> run() async {
    final argResults = this.argResults!;
    Iterable<String> args = argResults.rest;
    if (args.length != 1) {
      final arguments = args.isEmpty ? 'none' : '"${args.join(' ')}"';
      usageException(
        'Wrong number of arguments, expected "<package>", got $arguments.',
      );
    }
    final package = args.single;

    final bundles = DartInstallDirectory().allAppBundlesSync(
      packageName: package,
    );
    if (bundles.isEmpty) {
      print('Did not find any packages named "$package".');
      return 255;
    }

    try {
      for (final bundle in bundles) {
        final links = bundle.executablesOnPathSync;
        for (final link in links) {
          print('Deleting ${link.entity.path}');
          link.deleteSync();
        }
        print('Deleting ${bundle.directory.path}');
        bundle.directory.deleteSync(recursive: true);
      }
    } on PathAccessException {
      stderr.writeln('Deletion failed. The application might be in use.');
      return 255;
    }

    return 0;
  }
}
