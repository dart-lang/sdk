// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// The directory and file structure for `dart install` on the host machine.
library;

import 'dart:io';

import 'package:dart_data_home/dart_data_home.dart';
import 'package:dartdev/src/utils.dart';

/// The root directory for Dart installations.
///
/// This directory contains various subdirectories for binaries and app bundles.
///
/// <pre>
/// [DartInstallDirectory]
/// ├── [bin]/
/// │   └── (executables)
/// └── app-bundles/
///     └── (packageName)/
///         ├── git/
///         │   └── (gitHash)/
///         │       └── [AppBundleDirectory] (e.g., 'my_package/git/abcdef123/')
///         ├── hosted/
///         │   └── (version)/
///         │       └── [AppBundleDirectory] (e.g., 'my_package/hosted/1.0.0/')
///         └── local/
///             └── [AppBundleDirectory]     (e.g., 'my_package/local/')
/// </pre>
extension type DartInstallDirectory._(Directory directory) {
  static final DartInstallDirectory _singleton = DartInstallDirectory._(
    Directory(getDartDataHome('install')),
  );

  factory DartInstallDirectory() {
    return _singleton;
  }

  BinOnPathDirectory get bin =>
      BinOnPathDirectory._(Directory.fromUri(directory.uri.resolve('bin/')));

  Directory get _appBundles =>
      Directory.fromUri(directory.uri.resolve('app-bundles/'));

  AppBundleDirectory gitAppBundle(String packageName, String gitHash) =>
      AppBundleDirectory._(
        Directory.fromUri(
          _appBundles.uri.resolve('$packageName/git/$gitHash/'),
        ),
      );

  AppBundleDirectory hostedAppBundle(String packageName, String version) =>
      AppBundleDirectory._(
        Directory.fromUri(
          _appBundles.uri.resolve('$packageName/hosted/$version/'),
        ),
      );

  AppBundleDirectory localAppBundle(String packageName) => AppBundleDirectory._(
    Directory.fromUri(_appBundles.uri.resolve('$packageName/local/')),
  );

  List<AppBundleDirectory> allAppBundlesSync({String? packageName}) {
    final dartInstallAppbundlesDir = _appBundles;
    if (!dartInstallAppbundlesDir.existsSync()) {
      return [];
    }
    final packageDirs = dartInstallAppbundlesDir
        .listSync()
        .whereType<Directory>();
    final result = <AppBundleDirectory>[];
    for (final packageDir in packageDirs) {
      if (packageName != null && packageDir.name != packageName) {
        continue;
      }
      final gitDir = Directory.fromUri(packageDir.uri.resolve('git/'));
      final hostedDir = Directory.fromUri(packageDir.uri.resolve('hosted/'));
      final localDir = Directory.fromUri(packageDir.uri.resolve('local/'));
      if (gitDir.existsSync()) {
        result.addAll(
          gitDir.listSync().whereType<Directory>().map(
            (d) => AppBundleDirectory._(d.ensureEndWithSeparator),
          ),
        );
      }
      if (hostedDir.existsSync()) {
        result.addAll(
          hostedDir.listSync().whereType<Directory>().map(
            (d) => AppBundleDirectory._(d.ensureEndWithSeparator),
          ),
        );
      }
      if (localDir.existsSync()) {
        result.add(AppBundleDirectory._(localDir.ensureEndWithSeparator));
      }
    }
    return result;
  }
}

/// The directory that contains all executables available on `PATH`.
///
/// <pre>
/// [BinOnPathDirectory]
/// └── [executable]s
/// </pre>
extension type BinOnPathDirectory._(Directory directory) {
  /// An executable with [name] in the bin directory.
  ///
  /// The parameter [name] must not contain an extension.
  ExecutableOnPath executable(String name) {
    if (Platform.isLinux || Platform.isMacOS) {
      return ExecutableOnPath._unix(Link.fromUri(directory.uri.resolve(name)));
    }
    if (Platform.isWindows) {
      return ExecutableOnPath._windows(
        File.fromUri(directory.uri.resolve('$name.bat')),
      );
    }
    throw UnsupportedError('Unsupported OS: ${Platform.operatingSystem}.');
  }
}

/// An executable in [BinOnPathDirectory] available on `PATH`.
///
/// [entity] is a [Link] on Linux and MacOS, and a [File] on Windows.
extension type ExecutableOnPath._(FileSystemEntity entity) {
  factory ExecutableOnPath._unix(Link link) => ExecutableOnPath._(link);

  Link get unix {
    if (Platform.isLinux || Platform.isMacOS) {
      return entity as Link;
    }
    throw UnsupportedError('Wrong OS: ${Platform.operatingSystem}.');
  }

  factory ExecutableOnPath._windows(File file) => ExecutableOnPath._(file);

  File get windows {
    if (Platform.isWindows) {
      return entity as File;
    }
    throw UnsupportedError('Wrong OS: ${Platform.operatingSystem}.');
  }

  bool existsSync() => entity.existsSync();

  void deleteSync() => entity.deleteSync();

  static const _marker = 'target_file_path_marker';

  void createSync(ExecutableInBundle target) {
    if (Platform.isLinux || Platform.isMacOS) {
      return unix.createSync(target.file.path, recursive: true);
    }
    if (Platform.isWindows) {
      final wrapperScriptContents =
          '''
@ECHO OFF
REM $_marker
"${target.file.path}" %*
EXIT /B %ERRORLEVEL%
''';
      if (!windows.existsSync()) {
        windows.createSync(recursive: true);
      }
      return windows.writeAsStringSync(wrapperScriptContents);
    }
    throw UnsupportedError('Unsupported OS: ${Platform.operatingSystem}.');
  }

  ExecutableInBundle targetSync() {
    if (Platform.isLinux || Platform.isMacOS) {
      return ExecutableInBundle._(File(unix.targetSync()));
    }
    if (Platform.isWindows) {
      final wrapperScriptContents = windows.readAsStringSync();
      final iterator = wrapperScriptContents.split('\n').iterator..moveNext();
      while (!iterator.current.contains(_marker)) {
        iterator.moveNext();
      }
      iterator.moveNext();
      final line = iterator.current;
      final path = line.split('"')[1];
      return ExecutableInBundle._(File(path));
    }
    throw UnsupportedError('Unsupported OS: ${Platform.operatingSystem}.');
  }

  bool equals(ExecutableOnPath other) => entity.path == other.entity.path;
}

/// A directory containing an app bundle and its installation data.
///
/// This directory is structured as follows:
///
/// <pre>
/// [AppBundleDirectory]
/// ├── bundle/                      (Contains the application code and assets)
/// │   ├── bin/                     (Executables that can be run directly)
/// │   │   └── [ExecutableInBundle] (Specific executable files for the app bundle)
/// │   └── lib/                     (Dynamic libraries required by the executables)
/// │       └── (dynamic libraries)  (Platform-specific shared libraries)
/// ├── pubspec.lock                 (Generated by pub, locks package dependencies to specific versions)
/// └── pubspec.yaml                 (Declares project dependencies and metadata)
/// </pre>
extension type AppBundleDirectory._(Directory directory) {
  String get packageName {
    final result = tryPackageName;
    if (result != null) {
      return result;
    }
    throw StateError('${directory.path} is not a valid app bundle directory.');
  }

  String? get tryPackageName {
    if (!directory.path.startsWith(DartInstallDirectory()._appBundles.path)) {
      throw StateError(
        '${directory.path} does not start with ${DartInstallDirectory()._appBundles.path}.',
      );
      // return null;
    }
    final relativeSegments = directory.uri.pathSegments
        .skip(
          DartInstallDirectory()._appBundles.uri.pathSegments
              .where((e) => e.isNotEmpty)
              .length,
        )
        .toList();
    if (relativeSegments.length < 2) {
      throw StateError(
        '$directory, $relativeSegments does not contain at least two path segments.',
      );
      // return null;
    }
    if (relativeSegments[1] != 'hosted' &&
        relativeSegments[1] != 'git' &&
        relativeSegments[1] != 'local') {
      throw StateError(
        '$directory, $relativeSegments, ${relativeSegments[1]} is not hosted, git or local.',
      );
      // return null;
    }
    return relativeSegments[0];
  }

  Directory get _binDirectory =>
      Directory.fromUri(directory.uri.resolve('bundle/bin/'));

  List<ExecutableInBundle> get executablesSync {
    final binaries = _binDirectory
        .listSync()
        .whereType<File>()
        .map((e) => ExecutableInBundle._(e))
        .toList();
    return binaries;
  }

  /// The executables from this bundle which are available on `PATH`.
  List<ExecutableOnPath> get executablesOnPathSync {
    final result = <ExecutableOnPath>[];
    for (final executable in executablesSync) {
      final onPath = executable.onPath;
      if (onPath.existsSync() && onPath.targetSync().equals(executable)) {
        result.add(onPath);
      }
    }
    return result;
  }

  /// An executable with [name] in the app bundle.
  ///
  /// The parameter [name] most not contain an extension.
  ExecutableInBundle executable(String name) {
    return ExecutableInBundle._(
      File.fromUri(
        _binDirectory.uri.resolve(Platform.isWindows ? '$name.exe' : name),
      ),
    );
  }

  File get pubspec => File.fromUri(directory.uri.resolve('pubspec.yaml'));

  File get pubspecLock => File.fromUri(directory.uri.resolve('pubspec.lock'));

  bool pubspecLockIsIdenticalTo(File otherLockFile) {
    final pubspecLockStat = pubspecLock.statSync();
    final otherLockFileStat = otherLockFile.statSync();
    if (pubspecLockStat.type != FileSystemEntityType.file ||
        otherLockFileStat.type != FileSystemEntityType.file) {
      return false;
    }
    if (pubspecLockStat.size != otherLockFileStat.size) {
      return false;
    }
    return pubspecLock.readAsStringSync() == otherLockFile.readAsStringSync();
  }
}

/// An executable inside an [AppBundleDirectory].
extension type ExecutableInBundle._(File file) {
  AppBundleDirectory get appBundle {
    return AppBundleDirectory._(Directory.fromUri(file.uri.resolve('../../')));
  }

  ExecutableOnPath get onPath =>
      DartInstallDirectory().bin.executable(file.basenameWithoutExtension);

  bool equals(ExecutableInBundle other) => file.path == other.file.path;
}

extension DirectoryExtension on Directory {
  Directory get ensureEndWithSeparator => Directory.fromUri(uri);
}
