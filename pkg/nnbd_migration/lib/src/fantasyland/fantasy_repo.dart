// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;

const _github = 'git@github.com';

/// Data class to contain settings for a given repository.
///
/// A repository can be referred to by one or more [FantasySubPackageSettings].
class FantasyRepoSettings {
  final String repoName;
  final String clone;
  final String branch;
  final String revision;

  FantasyRepoSettings(this.repoName, this.clone, this.branch, this.revision);

  factory FantasyRepoSettings.fromName(String repoName) {
    switch (repoName) {

      /// TODO(jcollins-g): Port table over from add_repo_to_workspace.
      default:
        return FantasyRepoSettings(
            repoName, '$_github:dart-lang/$repoName.git', 'master', 'master');
    }
  }

  @override
  int get hashCode => toString().hashCode;

  @override
  bool operator ==(other) {
    return other is FantasyRepoSettings &&
        (other.repoName == repoName &&
            other.clone == clone &&
            other.branch == branch &&
            other.revision == revision);
  }

  @override
  String toString() =>
      'FantasyRepoSettings("$repoName", "$clone", "$branch", "$revision")';
}

const _repoSubDir = '_repo';

/// Represent a single git clone that may be referred to by one or more
/// [FantasySubPackage]s.
class FantasyRepo {
  final String name;
  final FantasyRepoSettings repoSettings;
  final Directory repoRoot;

  FantasyRepo._(this.name, this.repoSettings, this.repoRoot);

  static Future<FantasyRepo> buildFrom(
      String repoName, Directory workspaceRoot) async {
    FantasyRepoSettings repoSettings = FantasyRepoSettings.fromName(repoName);
    Directory repoRoot = Directory(path
        .canonicalize(path.join(workspaceRoot.path, _repoSubDir, repoName)));
    // TODO(jcollins-g): implement git operations, cloning, etc.
    return FantasyRepo._(repoName, repoSettings, repoRoot);
  }
}
