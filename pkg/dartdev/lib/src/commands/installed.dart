// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dartdev/src/core.dart';
import 'package:dartdev/src/install/file_system.dart';
import 'package:dartdev/src/install/pub_formats.dart';
import 'package:pub_formats/pub_formats.dart';

class InstalledCommand extends DartdevCommand {
  static const cmdName = 'installed';
  static const cmdDescription = 'List globally installed Dart CLI tools.';

  @override
  CommandCategory get commandCategory => CommandCategory.global;

  InstalledCommand({bool verbose = false})
    : super(cmdName, cmdDescription, verbose) {
    argParser.addFlag(
      'all',
      abbr: 'a',
      help: '''Also list packages which are currently not active.
Active package have executables on `PATH`.
App bundles of packages on disk which have no executables
on `PATH` are non-active.''',
    );
  }

  @override
  Future<int> run() async {
    final argResults = this.argResults!;
    final all = argResults.flag('all');

    final installedPackages = getInstalledPackages();
    for (final package in installedPackages) {
      if (package.installed == Installed.not && !all) {
        continue;
      }
      print(package.toString());
    }

    return 0;
  }

  static List<InstalledPackage> getInstalledPackages() {
    final allAppBundles = DartInstallDirectory().allAppBundlesSync();
    final result = <InstalledPackage>[];
    for (final appBundleDir in allAppBundles) {
      final packageName = appBundleDir.packageName;
      final lockFile = appBundleDir.pubspecLock;
      final pubspecLock = PubspecLockFile.loadSync(lockFile);
      final lockInfo = pubspecLock.packages!.entries
          .where(
            (entry) =>
                entry.value.dependency == DependencyTypeSyntax.directMain,
          )
          .single
          .value;
      final binaries = appBundleDir.executablesSync;
      var foundBinary = false;
      var missingBinary = false;
      for (final binary in binaries) {
        final link = binary.onPath;
        if (!link.existsSync()) {
          missingBinary = true;
        } else {
          if (link.targetSync().equals(binary)) {
            foundBinary = true;
          } else {
            missingBinary = true;
          }
        }
      }
      final lastModified = lockFile.lastModifiedSync();
      result.add(
        InstalledPackage(
          name: packageName,
          appBundle: appBundleDir.directory,
          installed: switch ((foundBinary, missingBinary)) {
            (_, false) => Installed.fully,
            (true, true) => Installed.partial,
            (false, true) => Installed.not,
          },
          lockInfo: lockInfo,
          lastModified: lastModified,
        ),
      );
    }
    return result;
  }
}

class InstalledPackage {
  final String name;
  final Directory appBundle;
  final Installed installed;
  final PackageSyntax lockInfo;
  final DateTime lastModified;

  InstalledPackage({
    required this.appBundle,
    required this.installed,
    required this.lastModified,
    required this.lockInfo,
    required this.name,
  });

  @override
  String toString() {
    var result = '$name ${lockInfo.version}';
    switch (lockInfo.source) {
      case PackageSourceSyntax.git:
        final description = GitPackageDescriptionSyntax.fromJson(
          lockInfo.description.json,
        );
        final url = description.url;
        final resolvedRef = description.resolvedRef.substring(0, 8);
        result += ' from Git repository "$url" at "$resolvedRef"';
      case PackageSourceSyntax.hosted:
        break;
      case PackageSourceSyntax.path$:
        final description = PathPackageDescriptionSyntax.fromJson(
          lockInfo.description.json,
        );
        final path = description.path$;
        result += ' from "$path" at $lastModified';
      default:
        result += ' from an unknown source "${lockInfo.source.name}"';
    }
    switch (installed) {
      case Installed.fully:
        break;
      case Installed.partial:
        result += ' (partially active)';
      case Installed.not:
        result += ' (not active)';
    }
    return result;
  }
}

enum Installed { fully, partial, not }
