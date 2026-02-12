// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:dartdev/src/commands/build.dart';
import 'package:dartdev/src/install/file_system.dart';
import 'package:dartdev/src/install/pub_formats.dart';
import 'package:front_end/src/api_prototype/compiler_options.dart'
    show Verbosity;
import 'package:path/path.dart' as p;
import 'package:pub/pub.dart';
import 'package:pub_formats/pub_formats.dart';
import 'package:yaml/yaml.dart';

import '../core.dart';

class InstallCommand extends DartdevCommand {
  static const cmdName = 'install';
  static const cmdDescription =
      '''Install or upgrade a Dart CLI tool for global use.

Install all executables specified in a package's pubspec.yaml executables
section (https://dart.dev/tools/pub/pubspec#executables) on the PATH. If the
executables section doesn't exist, installs all `bin/*.dart` entry points as
executables.

If the same package has been previously installed, it will be overwritten.

You can specify a package to install from pub.dev, a git repository, or a
local path using the `<package>[@<descriptor>]` syntax.

The `@<descriptor>` can be a version constraint (for hosted packages) or a
pub descriptor (consistent with pubspec.yaml).

Examples:
  dart install <pkg>
  dart install <pkg>@^3.0.0
  dart install '<pkg>@{hosted: https://pub.dev, version: ^3.0.0}'
  dart install '<pkg>@{git: {url: https://github.com/<owner>/<repo>, path: <path>}}'
  dart install '<pkg>@{path: /path/to/<pkg>}'

See https://dart.dev/go/pub-descriptors for more details.''';
  static const int genericErrorExitCode = 255;

  static const gitRefOption = 'git-ref';
  static const gitPathOption = 'git-path';

  @override
  String get invocation {
    final superNoArguments = super.invocation.replaceAll(' [arguments]', '');
    return '$superNoArguments <package>[@<descriptor>]';
  }

  @override
  CommandCategory get commandCategory => CommandCategory.global;

  InstallCommand({bool verbose = false})
    : super(cmdName, cmdDescription, verbose) {
    argParser.addOption(
      gitPathOption,
      help:
          'Path of git package in repository. '
          'Only applies when using a git url for <package>.',
      hide: true,
    );

    argParser.addOption(
      gitRefOption,
      help:
          'Git branch or commit to be retrieved. '
          'Only applies when using a git url for <package>.',
      hide: true,
    );

    argParser.addFlag(
      'overwrite',
      negatable: false,
      help: 'Overwrite executables from other packages with the same name.',
    );

    argParser.addOption(
      'hosted-url',
      abbr: 'u',
      help:
          'A custom pub server URL for the package. '
          'Only applies when using a package name for <package>.',
      hide: true,
    );
  }

  /// Parses the arguments.
  ///
  /// Reports usage errors to user if the wrong number or arguments or the wrong
  /// flags are passed.
  InstallCommandParsedArguments _parseArguments() {
    final argResults = this.argResults!;

    final overwrite = argResults.flag('overwrite');

    Iterable<String> args = argResults.rest;

    String readArg([String error = '']) {
      if (args.isEmpty) usageException(error);
      final arg = args.first;
      args = args.skip(1);
      return arg;
    }

    final firstArgument = readArg('Specify a package to install.');
    final gitPath = argResults.option(gitPathOption);
    var gitRef = argResults.option(gitRefOption);

    final atIndex = firstArgument.indexOf('@');
    if (firstArgument.startsWith('git@') || atIndex == -1) {
      final sourceKind = _sourceKindFromArgument(firstArgument);
      final versionConstraint = sourceKind == RemoteSourceKind.hosted
          ? (args.isEmpty ? 'any' : readArg())
          : null;

      if (sourceKind != RemoteSourceKind.git &&
          (gitPath != null || gitRef != null)) {
        usageException(
          'Options `--$gitPathOption` and `--$gitRefOption` '
          'can only be used with a git source.',
        );
      }

      final hostedUrl = argResults.option('hosted-url');
      if (sourceKind != RemoteSourceKind.hosted && hostedUrl != null) {
        usageException(
          'Option `--hosted-url` can only be used with a hosted source.',
        );
      }

      if (args.isNotEmpty) {
        usageException(
          'Too many arguments, did not expect "${args.join(' ')}"',
        );
      }
      return NonDescriptorInstallCommandParsedArguments(
        source: firstArgument,
        sourceKind: sourceKind,
        versionConstraint: versionConstraint,
        gitPath: gitPath,
        gitRef: gitRef,
        hostedUrl: hostedUrl,
        overwrite: overwrite,
      );
    } else {
      if (gitPath != null || gitRef != null) {
        usageException(
          'Options `--$gitPathOption` and `--$gitRefOption` '
          'cannot be used with the @ descriptor syntax.',
        );
      }
      final Object? descriptor;
      final packageName = firstArgument.substring(0, atIndex);
      final descriptorString = firstArgument.substring(atIndex + 1);
      try {
        descriptor = loadYaml(descriptorString);
      } on FormatException catch (e) {
        usageException(
          'Could not parse (what comes after @) "$descriptorString": $e',
        );
      }
      return DescriptorInstallCommandParsedArguments(
        packageName: packageName,
        descriptor: descriptor,
        overwrite: overwrite,
      );
    }
  }

  Future<String> _findPackageName(
    InstallCommandParsedArguments parsedArgs,
  ) async {
    switch (parsedArgs) {
      case DescriptorInstallCommandParsedArguments _:
        return parsedArgs.packageName;
      case NonDescriptorInstallCommandParsedArguments _:
        switch (parsedArgs.sourceKind) {
          case RemoteSourceKind.git:
            return await getPackageNameFromGitRepo(
              parsedArgs.source,
              ref: parsedArgs.gitRef,
              path: parsedArgs.gitPath,
              relativeTo: Directory.current.path,
              tagPattern: null,
            );
          case RemoteSourceKind.hosted:
            return parsedArgs.source;
          case RemoteSourceKind.path:
            final pubspecFile = File.fromUri(
              Directory(parsedArgs.source).absolute.uri.resolve('pubspec.yaml'),
            );
            if (!await pubspecFile.exists()) {
              usageException('No pubspec found in ${pubspecFile.path}.');
            }
            final pubspecYaml = PubspecYamlFile.loadSync(pubspecFile);
            return pubspecYaml.name;
        }
    }
  }

  /// Creates a helper package to pull in the requested package as a dependency.
  ///
  /// The user provides us either with (1) a package name plus optional version
  /// constraint, (2) a git repo, or (3) a local path. In order to avoid
  /// reimplementing pub's knowledge about how to pull in (1) and (2), we create
  /// a package with a dependency on the package that the user wants to install.
  /// Subsequently, we run `pub get` to let pub pull in dependencies, and we use
  /// the `package_graph.json` to find the root of the package that was pulled
  /// in by pub.
  static void createHelperPackagePubspec({
    required InstallCommandParsedArguments parsedArgs,
    required String packageName,
    required Directory helperPackageDir,
  }) {
    final tempPubspec = File.fromUri(
      helperPackageDir.uri.resolve('pubspec.yaml'),
    );
    final descriptor = switch (parsedArgs) {
      DescriptorInstallCommandParsedArguments _ => parsedArgs.descriptor,
      NonDescriptorInstallCommandParsedArguments _ =>
        switch (parsedArgs.sourceKind) {
          RemoteSourceKind.git => {
            'git': {
              'url': parsedArgs.source,
              if (parsedArgs.gitPath != null) 'path': parsedArgs.gitPath!,
              if (parsedArgs.gitRef != null) 'ref': parsedArgs.gitRef!,
            },
          },
          RemoteSourceKind.hosted => {
            'hosted': ?parsedArgs.hostedUrl,
            'version': parsedArgs.versionConstraint!,
          },
          RemoteSourceKind.path => {
            'path': Directory(parsedArgs.source).absolute.path,
          },
        },
    };

    final helperPackagePubspec = <String, Object?>{
      'name': _helperPackageName,
      'environment': {'sdk': '^${Platform.version.split(' ').first}'},
      'dependencies': {packageName: descriptor},
    };
    tempPubspec.writeAsStringSync(
      JsonEncoder.withIndent('  ').convert(helperPackagePubspec),
    );
  }

  static const _helperPackageName = 'dart_install_helper_package';

  static Future<void> resolveHelperPackage(Directory helperPackageDir) async {
    try {
      await ensurePubspecResolved(helperPackageDir.path);
    } on ResolutionFailedException catch (e) {
      installException(e.message);
    }
  }

  /// The executables that should be placed on the user's PATH when this
  /// package is installed.
  static DartBuildExecutables loadDeclaredExecutables(
    File sourcePackagePubspecFile,
    Directory sourcePackageRootDirectory,
  ) {
    final pubspecSyntax = PubspecYamlFile.loadSync(sourcePackagePubspecFile);

    final errors = pubspecSyntax.validateExecutables();
    if (errors.isNotEmpty) {
      installException(
        [
          'The pubspec.yaml contains the following errors:',
          ...errors,
        ].join('\n'),
      );
    }
    // This is a map of strings to string. Each key is the name of the command
    // that will be placed on the user's PATH. The value is the name of the
    // .dart script (without extension) in the package's `bin` directory that
    // should be run for that command. If the value is null, it defaults to the
    // key.
    final executablesSyntax = pubspecSyntax.executables;
    if (executablesSyntax == null) {
      installException('The pubspec.yaml contained no executables section.');
    }
    if (executablesSyntax.isEmpty) {
      installException(
        'The pubspec.yaml executables section contained no executables.',
      );
    }

    return [
      for (final executable in executablesSyntax.entries)
        (
          name: executable.key,
          sourceEntryPoint: sourcePackageRootDirectory.uri.resolve(
            'bin/${executable.value ?? executable.key}.dart',
          ),
        ),
    ];
  }

  static Future<void> doBuild(
    DartBuildExecutables executables,
    Directory buildDirectory,
    File helperPackageConfigFile,
    File sourcePackagePubspecFile,
    bool verbose,
    String verbosity,
  ) async {
    // TODO(https://github.com/dart-lang/native/issues/2465): Add a test for
    // user-defines in the source package pubspec.
    final buildResult = await BuildCliSubcommand.doBuild(
      executables: executables,
      enabledExperiments: [],
      outputUri: buildDirectory.uri,
      packageConfigUri: helperPackageConfigFile.uri,
      pubspecUri: sourcePackagePubspecFile.uri,
      recordUseEnabled: false,
      dataAssetsExperimentEnabled: false,
      verbose: verbose,
      verbosity: verbosity,
    );
    if (buildResult != 0) {
      installException('Build failed.', exitCode: buildResult);
    }
  }

  void _uniinstallAllPackageVersions(String packageName) {
    final bundles = DartInstallDirectory().allAppBundlesSync(
      packageName: packageName,
    );

    try {
      for (final bundle in bundles) {
        print('Uninstalling ${bundle.directory.path}.');
        final links = bundle.executablesOnPathSync;
        for (final link in links) {
          print('Deleting ${link.entity.path}');
          link.deleteSync();
        }
        print('Deleting ${bundle.directory.path}');
        bundle.directory.deleteSync(recursive: true);
      }
    } on PathAccessException {
      installException('Deletion failed. The application might be in use.');
    } on PathNotFoundException {
      print(
        'Bundle not found when uninstalling. '
        'Earlier installation may have failed.',
      );
      // Continue installing
    }
  }

  static AppBundleDirectory selectAppBundleDirectory(
    String packageName,
    Directory helperPackageDir,
    File helperPackageLockFile,
  ) {
    final lockFile = PubspecLockFile.loadSync(helperPackageLockFile);
    final resolvedPackage = lockFile.packages![packageName]!;
    final source = resolvedPackage.source;

    if (source == PackageSourceSyntax.git) {
      final resolvedGitRef = GitPackageDescriptionSyntax.fromJson(
        resolvedPackage.description.json,
      ).resolvedRef;
      return DartInstallDirectory().gitAppBundle(packageName, resolvedGitRef);
    } else if (source == PackageSourceSyntax.path$) {
      return DartInstallDirectory().localAppBundle(packageName);
    } else {
      return DartInstallDirectory().hostedAppBundle(
        packageName,
        resolvedPackage.version,
      );
    }
  }

  static Future<void> createAppBundleDirectory(
    AppBundleDirectory appBundleDirectory,
    Directory buildDirectory,
    File helperPackageLockFile,
    File sourcePackagePubspecFile,
  ) async {
    if (appBundleDirectory.directory.existsSync()) {
      try {
        appBundleDirectory.directory.deleteSync(recursive: true);
      } on PathAccessException {
        installException(
          'Failed to delete: ${appBundleDirectory.directory.path}. '
          'The application might be in use.',
        );
      }
    }
    appBundleDirectory.directory.createSync(recursive: true);
    final bundleDirectory = Directory.fromUri(
      buildDirectory.uri.resolve('bundle/'),
    );
    await _renameSafe(
      bundleDirectory,
      appBundleDirectory.directory.uri.resolve('bundle/'),
    );
    await helperPackageLockFile.copy(appBundleDirectory.pubspecLock.path);
    await sourcePackagePubspecFile.copy(appBundleDirectory.pubspec.path);
  }

  /// This allows us to rename files across different filesystems.
  ///
  /// Tries to use the basic [Directory.rename] method but if that fails then
  /// fall back to copying each entity and then deleting it.
  static Future<void> _renameSafe(Directory from, Uri to) async {
    try {
      await from.rename(to.toFilePath());
    } on FileSystemException {
      // The rename failed, possibly because `from` and `to` are on different
      // filesystems. Fall back to copy and delete.
      await _renameSafeCopyAndDelete(from, to);
    }
  }

  static Future<void> _renameSafeCopyAndDelete(Directory from, Uri to) async {
    await Directory.fromUri(to).create(recursive: true);
    await for (final child in from.list()) {
      final newChildPath = to.resolve(p.relative(child.path, from: from.path));
      if (child is File) {
        await child.copy(newChildPath.toFilePath());
      } else if (child is Directory) {
        await _renameSafeCopyAndDelete(child, Uri.parse('$newChildPath/'));
      } else {
        await Link.fromUri(
          newChildPath,
        ).create(await (child as Link).resolveSymbolicLinks());
      }
      await child.delete(recursive: false);
    }
  }

  void _installExecutablesOnPath(
    DartBuildExecutables executables,
    AppBundleDirectory appBundleDirectory,
    String packageName,
    InstallCommandParsedArguments parsedArgs,
  ) {
    final errors = <String>[];
    for (final executable in executables) {
      final executableName = executable.name;
      final executableFile = appBundleDirectory.executable(executableName);
      final executableOnPath = DartInstallDirectory().bin.executable(
        executableName,
      );
      var createLink = true;

      if (executableOnPath.existsSync()) {
        final targetExecutable = executableOnPath.targetSync();
        final targetPackageName = targetExecutable.appBundle.tryPackageName;
        if (targetPackageName == null ||
            targetPackageName == packageName ||
            parsedArgs.overwrite) {
          try {
            executableOnPath.deleteSync();
          } on PathAccessException {
            installException(
              'Failed to delete: ${executableOnPath.entity.path}. '
              'The application might be in use.',
            );
          }
        } else {
          errors.add(
            'Refusing to overwrite executable $executableName from package:$targetPackageName. '
            'Pass --overwrite to override.',
          );
          createLink = false;
        }
      }
      if (createLink) {
        executableOnPath.createSync(executableFile);
        print('Installed: ${executableOnPath.entity.path}');
      }
    }
    if (errors.isNotEmpty) {
      installException(errors.join('\n'));
    }
  }

  /// Checks to see if the binstubs are on the user's PATH and, if not, suggests
  /// that the user add the directory to their PATH.
  ///
  /// [installed] should be the name of an installed executable that can be used
  /// to test whether accessing it on the path works.
  static void _suggestIfNotOnPath(String installed) {
    final binDirPath = DartInstallDirectory().bin.directory.path;
    if (Platform.isWindows) {
      // See if the shell can find one of the binstubs.
      // "\q" means return exit code 0 if found or 1 if not.
      final result = Process.runSync('where', [r'\q', '$installed.bat']);
      if (result.exitCode == 0) return;

      stdout.writeln(
        'Warning: Dart installs executables into '
        '$binDirPath, which is not on your path.\n'
        "You can fix that by adding that directory to your system's "
        '"Path" environment variable.\n'
        'A web search for "configure windows path" will show you how.',
      );
    } else {
      // See if the shell can find one of the binstubs.
      //
      // The "command" builtin is more reliable than the "which" executable. See
      // http://unix.stackexchange.com/questions/85249/why-not-use-which-what-to-use-then
      final result = Process.runSync('command', [
        '-v',
        installed,
      ], runInShell: true);
      if (result.exitCode == 0) return;

      var binDir = binDirPath;
      if (binDir.startsWith(Platform.environment['HOME']!)) {
        binDir = p.join(
          r'$HOME',
          p.relative(binDir, from: Platform.environment['HOME']),
        );
      }
      final shellConfigFiles = Platform.isMacOS
          // zsh is default on mac - mention that first.
          ? '(.zshrc, .bashrc, .bash_profile, etc.)'
          : '(.bashrc, .bash_profile, .zshrc, etc.)';
      stdout.writeln(
        "'Warning: Dart installs executables into "
        '$binDir, which is not on your path.\n'
        "You can fix that by adding this to your shell's config file "
        '$shellConfigFiles:\n'
        '\n'
        '  export PATH="\$PATH":"$binDir"\n'
        '\n',
      );
    }
  }

  @override
  Future<int> run() async {
    final parsedArgs = _parseArguments();
    final packageName = await _findPackageName(parsedArgs);
    return await inTempDir((tempDirectory) async {
      try {
        final helperPackageDirectory = Directory.fromUri(
          tempDirectory.uri.resolve('helperPackage/'),
        );
        helperPackageDirectory.createSync();
        createHelperPackagePubspec(
          helperPackageDir: helperPackageDirectory,
          packageName: packageName,
          parsedArgs: parsedArgs,
        );
        await resolveHelperPackage(helperPackageDirectory);

        final helperPackageLockFile = File.fromUri(
          helperPackageDirectory.uri.resolve('pubspec.lock'),
        );
        final helperPackageConfigFile = File.fromUri(
          helperPackageDirectory.uri.resolve('.dart_tool/package_config.json'),
        );

        final sourcePackageRootDirectory = Directory(
          Uri.parse(
            PackageConfigFile.loadSync(
              helperPackageConfigFile,
            ).packages.firstWhere((e) => e.name == packageName).rootUri,
          ).toFilePath(),
        ).ensureEndWithSeparator;

        final sourcePackagePubspecFile = File.fromUri(
          sourcePackageRootDirectory.uri.resolve('pubspec.yaml'),
        );

        final executables = loadDeclaredExecutables(
          sourcePackagePubspecFile,
          sourcePackageRootDirectory,
        );

        final buildDirectory = Directory.fromUri(
          tempDirectory.uri.resolve('build/'),
        );

        await doBuild(
          executables,
          buildDirectory,
          helperPackageConfigFile,
          sourcePackagePubspecFile,
          verbose,
          Verbosity.all.name,
        );

        _uniinstallAllPackageVersions(packageName);

        AppBundleDirectory appBundleDirectory = selectAppBundleDirectory(
          packageName,
          helperPackageDirectory,
          helperPackageLockFile,
        );
        await createAppBundleDirectory(
          appBundleDirectory,
          buildDirectory,
          helperPackageLockFile,
          sourcePackagePubspecFile,
        );

        _installExecutablesOnPath(
          executables,
          appBundleDirectory,
          packageName,
          parsedArgs,
        );
        _suggestIfNotOnPath(executables.first.name);
      } on InstallException catch (e) {
        stderr.writeln(e.message);
        return genericErrorExitCode;
      }

      return 0;
    });
  }

  /// Throws a [InstallException] with [message].
  ///
  /// This enables similar coding style to using [usageException]s.
  static Never installException(String message, {int? exitCode}) =>
      throw InstallException(message, exitCode: exitCode);

  static Future<T> inTempDir<T>(
    Future<T> Function(Directory tempDirectory) fun,
  ) async {
    final tempDir = await Directory.systemTemp.createTemp();
    // Deal with Windows temp folder aliases.
    final tempDirResolved = Directory.fromUri(
      Directory(await tempDir.resolveSymbolicLinks()).uri.normalizePath(),
    );
    try {
      return await fun(tempDirResolved);
    } finally {
      try {
        await tempDir.delete(recursive: true);
      } on PathAccessException {
        if (Platform.isWindows) {
          // Don't fail on Windows having files in use.
        } else {
          rethrow;
        }
      }
    }
  }
}

sealed class InstallCommandParsedArguments {
  final bool overwrite;
  InstallCommandParsedArguments({required this.overwrite});
}

class DescriptorInstallCommandParsedArguments
    extends InstallCommandParsedArguments {
  final String packageName;
  final Object? descriptor;

  DescriptorInstallCommandParsedArguments({
    required this.packageName,
    required this.descriptor,
    required super.overwrite,
  });
}

class NonDescriptorInstallCommandParsedArguments
    extends InstallCommandParsedArguments {
  /// Package name, git url, or file path, depending on [sourceKind].
  final String source;
  final RemoteSourceKind sourceKind;
  final String? versionConstraint;
  final String? gitPath;
  final String? gitRef;
  final String? hostedUrl;

  NonDescriptorInstallCommandParsedArguments({
    required this.source,
    required this.sourceKind,
    required this.versionConstraint,
    required this.gitPath,
    required this.gitRef,
    required this.hostedUrl,
    required super.overwrite,
  });
}

enum RemoteSourceKind { git, hosted, path }

RemoteSourceKind _sourceKindFromArgument(String argument) {
  if (_packageNameRegExp.hasMatch(argument)) {
    return RemoteSourceKind.hosted;
  }
  final parsedUri = Uri.tryParse(argument);
  if (parsedUri != null) {
    switch (parsedUri.scheme.toLowerCase()) {
      case 'git':
      case 'http':
      case 'https':
        return RemoteSourceKind.git;
    }
  }
  final parsedGitSshUrl = GitSshUrl.tryParse(argument);
  if (parsedGitSshUrl != null) {
    return RemoteSourceKind.git;
  }

  if (argument.endsWith('.git') ||
      argument.endsWith('.git/') ||
      argument.endsWith('.git\\')) {
    return RemoteSourceKind.git;
  }
  return RemoteSourceKind.path;
}

/// A regular expression matching a Dart identifier.
///
/// This also matches a package name, since they must be Dart identifiers.
final _identifierRegExp = RegExp(r'[a-zA-Z_]\w*');

/// A regular expression matching allowed package names.
///
/// This allows dot-separated valid Dart identifiers. The dots are there for
/// compatibility with Google's internal Dart packages, but they may not be used
/// when publishing a package to pub.dev.
final _packageNameRegExp = RegExp(
  '^${_identifierRegExp.pattern}(\\.${_identifierRegExp.pattern})*\$',
);

// Expected format: git@host:owner/repository.git
class GitSshUrl {
  final String user;
  final String host;
  final String owner;
  final String repository;
  final String fullUrl;

  GitSshUrl({
    required this.user,
    required this.host,
    required this.owner,
    required this.repository,
    required this.fullUrl,
  });

  static GitSshUrl? tryParse(String url) {
    final regex = RegExp(r'^(\w+)@([^:]+):([^/]+)/(.+?)(?:\.git)?$');
    final match = regex.firstMatch(url);

    if (match == null) {
      return null;
    }

    return GitSshUrl(
      user: match.group(1)!,
      host: match.group(2)!,
      owner: match.group(3)!,
      repository: match.group(4)!,
      fullUrl: url,
    );
  }

  @override
  String toString() {
    return 'GitSshUrl(user: $user, host: $host, owner: $owner, repository: $repository, fullUrl: $fullUrl)';
  }
}

/// An exception during the installation process.
class InstallException implements Exception {
  final String message;
  final int? exitCode;

  InstallException(this.message, {this.exitCode});

  @override
  String toString() => message;
}
