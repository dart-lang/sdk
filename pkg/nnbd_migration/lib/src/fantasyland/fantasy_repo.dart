// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;

const _github = 'git@github.com';

final Map<String, FantasyRepoSettings> _repoTable = {
  'archive':
      FantasyRepoSettings('archive', '$_github:brendan-duncan/archive.git'),
  'build_verify': FantasyRepoSettings(
      'build_verify', '$_github:brendan-duncan/build_verify.git'),
  'build_version':
      FantasyRepoSettings('build_version', '$_github:kevmoo/build_version.git'),
  'csv': FantasyRepoSettings('csv', '$_github:close2/csv.git'),
  'git': FantasyRepoSettings('git', '$_github:kevmoo/git.git'),
  'node_interop': FantasyRepoSettings(
      'node_interop', '$_github:pulyaevskiy/node-interop.git'),
  'node_preamble': FantasyRepoSettings(
      'package_config', '$_github:mbullington/node_preamble.dart.git'),
  'package_config': FantasyRepoSettings(
      'package_config', '$_github:dart-lang/package_config', 'master', '1.1.0'),
  'source_gen_test': FantasyRepoSettings(
      'source_gen_test', '$_github:kevmoo/source_gen_test.git'),
  'quiver-dart':
      FantasyRepoSettings('quiver-dart', '$_github:google/quiver-dart.git'),
  'uuid': FantasyRepoSettings('uuid', '$_github:Daegalus/dart-uuid.git'),
};

/// Data class to contain settings for a given repository.
///
/// A repository can be referred to by one or more [FantasySubPackageSettings].
class FantasyRepoSettings {
  final String name;
  final String clone;
  final String branch;
  final String revision;

  FantasyRepoSettings(this.name, this.clone,
      [this.branch = 'master', this.revision = 'master']);

  static RegExp _dotDart = RegExp(r'[.]dart$');

  /// Build repository settings from a hard-coded repository name.
  factory FantasyRepoSettings.fromName(String repoName) {
    if (_repoTable.containsKey(repoName)) {
      return _repoTable[repoName];
    }
    if (_dotDart.hasMatch(repoName)) {
      return FantasyRepoSettings(repoName, '$_github:google/$repoName.git');
    }
    return FantasyRepoSettings(
        repoName, '$_github:dart-lang/$repoName.git', 'master', 'master');
  }

  @override
  int get hashCode => toString().hashCode;

  @override
  bool operator ==(other) {
    return other is FantasyRepoSettings &&
        (other.name == name &&
            other.clone == clone &&
            other.branch == branch &&
            other.revision == revision);
  }

  @override
  String toString() =>
      'FantasyRepoSettings("$name", "$clone", "$branch", "$revision")';
}

const _repoSubDir = '_repo';

/// Represent a single git clone that may be referred to by one or more
/// [FantasySubPackage]s.
class FantasyRepo {
  final String name;
  final FantasyRepoSettings repoSettings;
  final Directory repoRoot;

  FantasyRepo._(this.repoSettings, this.repoRoot) : name = repoSettings.name;

  static Future<FantasyRepo> buildFrom(
      FantasyRepoSettings repoSettings, Directory workspaceRoot) async {
    Directory repoRoot = Directory(path.canonicalize(
        path.join(workspaceRoot.path, _repoSubDir, repoSettings.name)));
    // TODO(jcollins-g): implement git operations, cloning, etc.
    return FantasyRepo._(repoSettings, repoRoot);
  }
}
