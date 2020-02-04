// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:nnbd_migration/src/utilities/subprocess_launcher.dart';
import 'package:path/path.dart' as path;

const _github = 'git@github.com';
const _httpGithub = 'https://github.com';

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

/// Represent a single git clone that may be referred to by one or more
/// [FantasySubPackage]s.
class FantasyRepo {
  final String name;
  final FantasyRepoSettings repoSettings;
  final Directory repoRoot;
  final File Function(String) fileBuilder;

  FantasyRepo._(this.repoSettings, this.repoRoot,
      {File Function(String) fileBuilder})
      : name = repoSettings.name,
        fileBuilder = fileBuilder ?? ((s) => File(s));

  static Future<FantasyRepo> buildFrom(
      FantasyRepoSettings repoSettings, Directory repoRoot,
      {SubprocessLauncher launcher, File Function(String) fileBuilder}) async {
    FantasyRepo newRepo =
        FantasyRepo._(repoSettings, repoRoot, fileBuilder: fileBuilder);
    if (launcher == null) {
      launcher = SubprocessLauncher('FantasyRepo.buildFrom-${newRepo.name}');
    }
    await newRepo._init(launcher);
    return newRepo;
  }

  bool _isInitialized = false;

  /// Call exactly once per [FantasyRepo].
  ///
  /// May throw [FantasyRepoException] in the event of problems and does
  /// not clean up filesystem state.
  Future<void> _init(SubprocessLauncher launcher) async {
    assert(_isInitialized == false);
    if (await repoRoot.exists()) {
      await _update(launcher);
      // TODO(jcollins-g): handle "update" of pinned revision edge case
    } else {
      await _clone(launcher);
    }
    _isInitialized = true;
    return;
  }

  /// Configure a git repository locally and initialize it.
  ///
  /// Throws [FantasyRepoCloneException] in the event we can not finish
  /// initializing.
  Future<void> _clone(SubprocessLauncher launcher) async {
    assert(_isInitialized == false);
    if (!await repoRoot.parent.exists()) {
      await repoRoot.parent.create(recursive: true);
    }
    await launcher.runStreamed('git', ['init', repoRoot.path]);
    await launcher.runStreamed(
        'git',
        [
          'remote',
          'add',
          'origin',
          '-t',
          repoSettings.branch,
          repoSettings.clone
        ],
        workingDirectory: repoRoot.path);

    String cloneHttp =
        repoSettings.clone.replaceFirst('$_github:', '$_httpGithub/');
    await launcher.runStreamed('git',
        ['remote', 'add', 'originHTTP', '-t', repoSettings.branch, cloneHttp],
        workingDirectory: repoRoot.path);

    // Do not get the working directory wrong on this command or it could
    // alter a user's repository config based on the CWD, which is bad.  Other
    // commands in [FantasyRepo] will not fail silently with permanent,
    // confusing results, but this one can.
    await launcher.runStreamed('git', ['config', 'core.sparsecheckout', 'true'],
        workingDirectory: repoRoot.path);

    File sparseCheckout = fileBuilder(
        path.join(repoRoot.path, '.git', 'info', 'sparse-checkout'));
    await sparseCheckout.writeAsString([
      '**\n',
      '!**/.packages\n',
      '!**/pubspec.lock\n',
      '!**/.dart_tool/package_config.json\n'
    ].join());
    try {
      await _update(launcher);
    } catch (e) {
      if (e is FantasyRepoUpdateException) {
        throw FantasyRepoCloneException(
            'Unable to initialize clone for: $repoSettings');
      }
      // Other kinds of exceptions are not expected, so rethrow.
      rethrow;
    }
  }

  Future<void> _update(SubprocessLauncher launcher) async {
    assert(_isInitialized == false);
    try {
      List<String> args;
      if (repoSettings.branch == 'master') {
        args = [
          'pull',
          '--depth=1',
          '--rebase',
          'originHTTP',
          repoSettings.revision
        ];
      } else {
        args = ['pull', '--rebase', 'originHTTP', repoSettings.revision];
      }
      await launcher.runStreamed('git', args, workingDirectory: repoRoot.path);
    } catch (e) {
      if (e is ProcessException) {
        throw FantasyRepoUpdateException(
            'Unable to update clone for: $repoSettings');
      }
      rethrow;
    }
  }
}
