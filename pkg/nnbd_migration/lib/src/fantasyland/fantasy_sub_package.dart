// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:nnbd_migration/src/fantasyland/fantasy_repo.dart';
import 'package:path/path.dart' as path;

/// Data class containing settings for a package within a [FantasyWorkspaceImpl].
class FantasySubPackageSettings {
  final String name;
  final String repoName;
  final String subDir;

  FantasySubPackageSettings(this.name, this.repoName, this.subDir);

  factory FantasySubPackageSettings.fromName(String name) {
    switch (name) {

      /// TODO(jcollins-g): Port table over from add_package_to_workspace.
      default:
        return FantasySubPackageSettings(name, name, '.');
    }
  }

  @override
  int get hashCode => toString().hashCode;

  @override
  bool operator ==(other) {
    return other is FantasySubPackageSettings &&
        (other.name == name &&
            other.repoName == repoName &&
            other.subDir == other.subDir);
  }

  @override
  String toString() =>
      'FantasySubPackageSettings("$name", "$repoName", "$subDir")';
}

/// Represents one package within a [FantasyWorkspaceImpl].
///
/// A `FantasySubPackage` differs from a normal package in that Dart code within
/// it depends on a global .packages file to resolve symbols.
class FantasySubPackage {
  final String name;
  final FantasyRepo containingRepo;
  final FantasySubPackageSettings packageSettings;

  /// The symlink in the workspace directory whose [Link.target] is the root of
  /// the package.
  final Link packageSymlink;

  FantasySubPackage._(this.name, this.containingRepo, this.packageSettings,
      this.packageSymlink);

  static Future<FantasySubPackage> buildFrom(String packageName,
      FantasyRepo containingRepo, Directory workspaceRoot) async {
    FantasySubPackageSettings packageSettings =
        FantasySubPackageSettings.fromName(packageName);
    Link packageSymlink = Link(path.join(workspaceRoot.path, packageName));
    if (!await packageSymlink.exists()) {
      await packageSymlink.create(path.canonicalize(
          path.join(containingRepo.repoRoot.path, packageSettings.subDir)));
    }
    // TODO(jcollins-g): implement .packages file handling here
    return FantasySubPackage._(
        packageName, containingRepo, packageSettings, packageSymlink);
  }
}
