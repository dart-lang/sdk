// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:nnbd_migration/src/fantasyland/fantasy_repo_impl.dart';

const githubHost = 'git@github.com';

final Map<String, FantasyRepoSettings> _repoTable = {
  'archive':
      FantasyRepoSettings('archive', '$githubHost:brendan-duncan/archive.git'),
  'build_verify': FantasyRepoSettings(
      'build_verify', '$githubHost:brendan-duncan/build_verify.git'),
  'build_version': FantasyRepoSettings(
      'build_version', '$githubHost:kevmoo/build_version.git'),
  'csv': FantasyRepoSettings('csv', '$githubHost:close2/csv.git'),
  'git': FantasyRepoSettings('git', '$githubHost:kevmoo/git.git'),
  'node_interop': FantasyRepoSettings(
      'node_interop', '$githubHost:pulyaevskiy/node-interop.git'),
  'node_preamble': FantasyRepoSettings(
      'package_config', '$githubHost:mbullington/node_preamble.dart.git'),
  'package_config': FantasyRepoSettings('package_config',
      '$githubHost:dart-lang/package_config', 'master', '1.1.0'),
  'source_gen_test': FantasyRepoSettings(
      'source_gen_test', '$githubHost:kevmoo/source_gen_test.git'),
  'quiver-dart':
      FantasyRepoSettings('quiver-dart', '$githubHost:google/quiver-dart.git'),
  'uuid': FantasyRepoSettings('uuid', '$githubHost:Daegalus/dart-uuid.git'),
};

class FantasyRepoCloneException extends FantasyRepoException {
  FantasyRepoCloneException(String message) : super(message);

  String toString() {
    if (message == null) return "FantasyRepoCloneException";
    return "FantasyRepoCloneException: $message";
  }
}

class FantasyRepoUpdateException extends FantasyRepoException {
  FantasyRepoUpdateException(String message) : super(message);

  String toString() {
    if (message == null) return "FantasyRepoUpdateException";
    return "FantasyRepoUpdateException: $message";
  }
}

class FantasyRepoException implements Exception {
  final message;

  FantasyRepoException(this.message);

  String toString() {
    if (message == null) return "FantasyRepoException";
    return "FantasyRepoException: $message";
  }
}

/// Data class to contain settings for a given repository.
///
/// A repository can be referred to by one or more [FantasySubPackageSettings].
class FantasyRepoSettings {
  final String name;
  final String clone;
  final String branch;
  final String revision;

  FantasyRepoSettings(this.name, this.clone,
      // TODO(jcollins-g): revision should follow master
      [this.branch = 'master',
      this.revision = 'master']);

  static RegExp _dotDart = RegExp(r'[.]dart$');

  /// Build repository settings from a hard-coded repository name.
  factory FantasyRepoSettings.fromName(String repoName) {
    if (_repoTable.containsKey(repoName)) {
      return _repoTable[repoName];
    }
    if (_dotDart.hasMatch(repoName)) {
      return FantasyRepoSettings(repoName, '$githubHost:google/$repoName.git');
    }
    return FantasyRepoSettings(
        repoName, '$githubHost:dart-lang/$repoName.git', 'master', 'master');
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

/// Base class for all repository types.
abstract class FantasyRepo {
  String get name;
  FantasyRepoSettings get repoSettings;
  Folder get repoRoot;

  static Future<FantasyRepo> buildGitRepoFrom(
      FantasyRepoSettings repoSettings, String repoRootPath,
      {FantasyRepoDependencies fantasyRepoDependencies}) async {
    FantasyRepoGitImpl newRepo = FantasyRepoGitImpl(repoSettings, repoRootPath,
        fantasyRepoDependencies: fantasyRepoDependencies);
    await newRepo.init();
    return newRepo;
  }
}
