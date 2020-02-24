// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

/// This binary can generate and update an integrated workspace for upgrading
/// individual packages and their dependencies simultaneously.

import 'package:nnbd_migration/src/fantasyland/fantasy_workspace.dart';
import 'package:path/path.dart' as path;
import 'package:args/args.dart';

final parser = ArgParser()
  ..addMultiOption('extra-packages', abbr: 'e', splitCommas: true)
  ..addOption('package-name', abbr: 'p')
  ..addFlag('allow-update',
      defaultsTo: false,
      negatable: true,
      help:
          'Try to update an existing repository in place.  Does not work for unclean repositories.')
  ..addFlag('analysis-options-hack', defaultsTo: true, negatable: true)
  ..addFlag('strip-sdk-constraint-hack', defaultsTo: false, negatable: true)
  ..addFlag('force-migrate-deps',
      defaultsTo: false,
      negatable: true,
      help: 'Use dartfix to update all dependencies')
  ..addFlag('force-migrate-package',
      defaultsTo: false,
      negatable: true,
      help: 'Use dartfix to update the base package name')
  ..addFlag('force-migrate-extras',
      defaultsTo: false,
      negatable: true,
      help: 'Use dartfix to update extra packages')
  ..addOption('sdk')
  ..addFlag('help', abbr: 'h');

Future<void> main(List<String> args) async {
  ArgResults results = parser.parse(args);

  if (results['help'] as bool) {
    _showHelp(null, useStdError: false);
    exit(0);
  }

  if (results.rest.length != 1) {
    _showHelp('error: only one argument allowed for workspace directory');
    exit(1);
  }

  List<String> extraPackages = results['extra-packages'] as List<String>;
  String packageName = results['package-name'] as String;

  if (packageName == null) {
    _showHelp('error: --package_name required');
    exit(1);
  }
  assert(packageName != null);
  assert(extraPackages != null);

  FantasyWorkspace workspace = await buildFantasyLand(
      packageName,
      extraPackages,
      path.canonicalize(results.rest.first),
      results['allow-update'] as bool);
  workspace.makeAllSymlinks();

  if (results['analysis-options-hack'] as bool) {
    await Future.wait([
      for (FantasySubPackage p in workspace.subPackages.values)
        p.enableExperimentHack()
    ]);
  }

  Set<FantasySubPackage> upgradedSubPackages = {};
  Set<FantasySubPackage> upgradedSubPackagesLibOnly = {};

  if (results['force-migrate-deps'] as bool ||
      results['force-migrate-package'] as bool ||
      results['force-migrate-extras'] as bool) {
    if (results['force-migrate-package'] as bool) {
      upgradedSubPackages.addAll(
          workspace.subPackages.values.where((s) => s.name == packageName));
    }

    if (results['force-migrate-extras'] as bool) {
      upgradedSubPackages.addAll(workspace.subPackages.values
          .where((s) => extraPackages.contains(s.name)));
    }

    if (results['force-migrate-deps'] as bool) {
      upgradedSubPackagesLibOnly.addAll(workspace.subPackages.values.where(
          (s) => s.name != packageName && !extraPackages.contains(s.name)));
    }

    if (results['sdk'] as String == null) {
      _showHelp('error: --sdk required with force-migrate options');
      exit(1);
    }
    await workspace.forceMigratePackages(upgradedSubPackages,
        upgradedSubPackagesLibOnly, results['sdk'] as String, [
      Platform.resolvedExecutable,
      path.normalize(path.join(Platform.script.toFilePath(), '..', '..', '..',
          'dartfix', 'bin', 'dartfix.dart'))
    ]);
  }

  if (results['strip-sdk-constraint-hack'] as bool) {
    await Future.wait([
      for (FantasySubPackage p
          in upgradedSubPackages.followedBy(upgradedSubPackagesLibOnly))
        () async {
          await p.removeSdkConstraintHack();
          await workspace.rewritePackageConfigWith(p);
        }()
    ]);
  }
}

// TODO(jcollins-g): add symbolic link support to analyzer filesystem.
extension _Symlinks on FantasyWorkspace {
  void makeAllSymlinks() {
    for (var package in subPackages.values) {
      Link l = Link(path.join(workspaceRootPath, package.name));
      if (!l.existsSync()) {
        l.createSync(
            path.relative(package.packageRoot.path, from: workspaceRootPath));
      }
    }
  }
}

void _showHelp(String message, {bool useStdError = true}) {
  var writer = useStdError ? stderr : stdout;

  writer.writeln(message ?? '');
  writer.writeln(
      'Usage: dart ${Platform.script.toFilePath()} [options] workspace_dir');
  writer.writeln();
  writer.writeln(parser.usage);
}
