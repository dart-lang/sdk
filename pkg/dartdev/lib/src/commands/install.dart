// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dartdev/src/commands/build.dart';
import 'package:dartdev/src/install/file_system.dart';
import 'package:dartdev/src/install/pub_formats.dart';
import 'package:path/path.dart' as p;
import 'package:pub/pub.dart';
import 'package:pub_formats/pub_formats.dart';

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

You can specify three different values for the <package> argument:
1. A package name. This will install the package from pub.dev. (hosted)
   The [version-constraint] argument can only be passed to 'hosted'.
2. A git url. This will install the package from a git repository. (git)
3. A path on your machine. This will install the package from that path. (path)''';
  static const int genericErrorExitCode = 255;

  @override
  String get invocation {
    final superNoArguments = super.invocation.replaceAll(' [arguments]', '');
    return '$superNoArguments <package> [version-constraint]';
  }

  @override
  CommandCategory get commandCategory => CommandCategory.global;

  InstallCommand({bool verbose = false})
      : super(cmdName, cmdDescription, verbose) {
    argParser.addOption(
      'git-path',
      help: 'Path of git package in repository. '
          'Only applies when using a git url for <package>.',
    );

    argParser.addOption(
      'git-ref',
      help: 'Git branch or commit to be retrieved. '
          'Only applies when using a git url for <package>.',
    );

    argParser.addFlag(
      'overwrite',
      negatable: false,
      help: 'Overwrite executables from other packages with the same name.',
    );

    argParser.addOption(
      'hosted-url',
      abbr: 'u',
      help: 'A custom pub server URL for the package. '
          'Only applies when using a package name for <package>.',
    );
  }

  /// Parses the arguments.
  ///
  /// Reports usage errors to user if the wrong number or arguments or the wrong
  /// flags are passed.
  _InstallCommandParsedArguments _parseArguments() {
    final argResults = this.argResults!;

    final overwrite = argResults.flag('overwrite');

    Iterable<String> args = argResults.rest;

    String readArg([String error = '']) {
      if (args.isEmpty) usageException(error);
      final arg = args.first;
      args = args.skip(1);
      return arg;
    }

    final argument = readArg('No package source given.');
    final sourceKind = _SourceKind.fromArgument(argument);

    final gitPath = argResults.option('git-path');
    var gitRef = argResults.option('git-ref');
    if (sourceKind != _SourceKind.git && (gitPath != null || gitRef != null)) {
      usageException(
        'Options `--git-path` and `--git-ref` '
        'can only be used with a git source.',
      );
    }

    final hostedUrl = argResults.option('hosted-url');
    if (sourceKind != _SourceKind.hosted && hostedUrl != null) {
      usageException(
        'Option `--hosted-url` can only be used with a hosted source.',
      );
    }

    String? versionConstraint;
    switch (sourceKind) {
      case _SourceKind.git:
      case _SourceKind.path:
        break;
      case _SourceKind.hosted:
        versionConstraint = args.isEmpty ? 'any' : readArg();
    }
    if (args.isNotEmpty) {
      usageException(
        'Too many arguments, did not expect "${args.join(' ')}"',
      );
    }
    return _InstallCommandParsedArguments._(
      source: argument,
      sourceKind: sourceKind,
      versionConstraint: versionConstraint,
      gitPath: gitPath,
      gitRef: gitRef,
      hostedUrl: hostedUrl,
      overwrite: overwrite,
    );
  }

  Future<String> _findPackageName(
    _InstallCommandParsedArguments parsedArgs,
  ) async {
    switch (parsedArgs.sourceKind) {
      case _SourceKind.git:
        return await getPackageNameFromGitRepo(
          parsedArgs.source,
          ref: parsedArgs.gitRef,
          path: parsedArgs.gitPath,
          relativeTo: Directory.current.path,
          tagPattern: null,
        );
      case _SourceKind.hosted:
        return parsedArgs.source;
      case _SourceKind.path:
        final pubspecFile = File.fromUri(
            Directory(parsedArgs.source).absolute.uri.resolve('pubspec.yaml'));
        if (!await pubspecFile.exists()) {
          usageException('No pubspec found in ${pubspecFile.path}.');
        }
        final pubspecYaml = PubspecYamlFile.loadSync(pubspecFile);
        return pubspecYaml.name;
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
  void _createHelperPackagePubspec({
    required _InstallCommandParsedArguments parsedArgs,
    required String packageName,
    required Directory helperPackageDir,
  }) {
    final tempPubspec =
        File.fromUri(helperPackageDir.uri.resolve('pubspec.yaml'));
    final helperPackagePubspec = PubspecYamlFileSyntax(
      name: _helperPackageName,
      environment: EnvironmentSyntax(
        sdk: '^${Platform.version.split(' ').first}',
      ),
      dependencies: {
        packageName: switch (parsedArgs.sourceKind) {
          _SourceKind.git => GitDependencySourceSyntax(
              git: GitSyntax(
                url: parsedArgs.source,
                path$: parsedArgs.gitPath,
                ref: parsedArgs.gitRef,
              ),
            ),
          _SourceKind.hosted => HostedDependencySourceSyntax(
              hosted: parsedArgs.hostedUrl,
              version: parsedArgs.versionConstraint!,
            ),
          _SourceKind.path =>
            // Re-resolve dependencies for path activate, behave like it would work
            // for users of the package if the activate via hosted or git.
            PathDependencySourceSyntax(
              path$: Directory(parsedArgs.source).absolute.path,
            ),
        }
      },
    );
    helperPackagePubspec.writeSync(tempPubspec);
  }

  static const _helperPackageName = 'dart_install_helper_package';

  Future<void> _resolveHelperPackage(Directory helperPackageDir) async {
    try {
      await ensurePubspecResolved(helperPackageDir.path);
    } on ResolutionFailedException catch (e) {
      _installException(e.message);
    }
  }

  /// The executables that should be placed on the user's PATH when this
  /// package is installed.
  DartBuildExecutables _loadDeclaredExecutables(
    File sourcePackagePubspecFile,
    Directory sourcePackageRootDirectory,
  ) {
    final pubspecSyntax = PubspecYamlFile.loadSync(sourcePackagePubspecFile);

    final errors = pubspecSyntax.validateExecutables();
    if (errors.isNotEmpty) {
      _installException([
        'The pubspec.yaml contains the following errors:',
        ...errors
      ].join('\n'));
    }
    // This is a map of strings to string. Each key is the name of the command
    // that will be placed on the user's PATH. The value is the name of the
    // .dart script (without extension) in the package's `bin` directory that
    // should be run for that command. If the value is null, it defaults to the
    // key.
    final executablesSyntax = pubspecSyntax.executables;
    if (executablesSyntax == null) {
      _installException('The pubspec.yaml contained no executables section.');
    }
    if (executablesSyntax.isEmpty) {
      _installException(
          'The pubspec.yaml executables section contained no executables.');
    }

    return [
      for (final executable in executablesSyntax.entries)
        (
          name: executable.key,
          sourceEntryPoint: sourcePackageRootDirectory.uri
              .resolve('bin/${executable.value ?? executable.key}.dart')
        )
    ];
  }

  Future<void> _doBuild(
    DartBuildExecutables executables,
    Directory buildDirectory,
    File helperPackageConfigFile,
    File sourcePackagePubspecFile,
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
      verbosity: 'all',
    );
    if (buildResult != 0) {
      _installException('Build failed.', exitCode: buildResult);
    }
  }

  void _uniinstallAllPackageVersions(String packageName) {
    final bundles =
        DartInstallDirectory().allAppBundlesSync(packageName: packageName);

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
      _installException('Deletion failed. The application might be in use.');
    }
  }

  AppBundleDirectory _selectAppBundleDirectory(
    _InstallCommandParsedArguments parsedArgs,
    String packageName,
    Directory helperPackageDir,
    File helperPackageLockFile,
  ) {
    final AppBundleDirectory outputDir;
    switch (parsedArgs.sourceKind) {
      case _SourceKind.git:
        final resolvedGitRef = parsedArgs.gitRef ??
            GitPackageDescriptionSyntax.fromJson(
              PubspecLockFile.loadSync(helperPackageLockFile)
                  .packages![packageName]!
                  .description
                  .json,
            ).resolvedRef;
        outputDir = DartInstallDirectory().gitAppBundle(
          packageName,
          resolvedGitRef,
        );
      case _SourceKind.hosted:
        final packageGraphJson = PackageGraphFile.loadSync(File.fromUri(
          helperPackageDir.uri.resolve('.dart_tool/package_graph.json'),
        ));
        final resolvedVersion = packageGraphJson.packages
            .firstWhere((e) => e.name == packageName)
            .version;
        outputDir = DartInstallDirectory().hostedAppBundle(
          packageName,
          resolvedVersion,
        );
      case _SourceKind.path:
        outputDir = DartInstallDirectory().localAppBundle(packageName);
    }
    return outputDir;
  }

  Future<void> _createAppBundleDirectory(
      AppBundleDirectory appBundleDirectory,
      Directory buildDirectory,
      File helperPackageLockFile,
      File sourcePackagePubspecFile) async {
    if (appBundleDirectory.directory.existsSync()) {
      try {
        appBundleDirectory.directory.deleteSync(recursive: true);
      } on PathAccessException {
        _installException(
          'Failed to delete: ${appBundleDirectory.directory.path}. '
          'The application might be in use.',
        );
      }
    }
    appBundleDirectory.directory.createSync(recursive: true);
    final bundleDirectory =
        Directory.fromUri(buildDirectory.uri.resolve('bundle/'));
    await bundleDirectory.rename(
        appBundleDirectory.directory.uri.resolve('bundle/').toFilePath());
    await helperPackageLockFile.copy(appBundleDirectory.pubspecLock.path);
    await sourcePackagePubspecFile.copy(appBundleDirectory.pubspec.path);
  }

  void _installExecutablesOnPath(
      DartBuildExecutables executables,
      AppBundleDirectory appBundleDirectory,
      String packageName,
      _InstallCommandParsedArguments parsedArgs) {
    final errors = <String>[];
    for (final executable in executables) {
      final executableName = executable.name;
      final executableFile = appBundleDirectory.executable(executableName);
      final executableOnPath =
          DartInstallDirectory().bin.executable(executableName);
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
            _installException(
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
      _installException(errors.join('\n'));
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
      final result = Process.runSync(
        'command',
        [
          '-v',
          installed,
        ],
        runInShell: true,
      );
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
    return await _inTempDir((tempDirectory) async {
      try {
        final helperPackageDirectory =
            Directory.fromUri(tempDirectory.uri.resolve('helperPackage/'));
        helperPackageDirectory.createSync();
        _createHelperPackagePubspec(
          helperPackageDir: helperPackageDirectory,
          packageName: packageName,
          parsedArgs: parsedArgs,
        );
        await _resolveHelperPackage(helperPackageDirectory);

        final helperPackageLockFile =
            File.fromUri(helperPackageDirectory.uri.resolve('pubspec.lock'));
        final helperPackageConfigFile = File.fromUri(helperPackageDirectory.uri
            .resolve('.dart_tool/package_config.json'));

        final sourcePackageRootDirectory = Directory(Uri.parse(
          PackageConfigFile.loadSync(helperPackageConfigFile)
              .packages
              .firstWhere((e) => e.name == packageName)
              .rootUri,
        ).toFilePath())
            .ensureEndWithSeparator;

        final sourcePackagePubspecFile = File.fromUri(
            sourcePackageRootDirectory.uri.resolve('pubspec.yaml'));

        final executables = _loadDeclaredExecutables(
          sourcePackagePubspecFile,
          sourcePackageRootDirectory,
        );

        final buildDirectory =
            Directory.fromUri(tempDirectory.uri.resolve('build/'));
        await _doBuild(
          executables,
          buildDirectory,
          helperPackageConfigFile,
          sourcePackagePubspecFile,
        );

        _uniinstallAllPackageVersions(packageName);

        AppBundleDirectory appBundleDirectory = _selectAppBundleDirectory(
          parsedArgs,
          packageName,
          helperPackageDirectory,
          helperPackageLockFile,
        );
        await _createAppBundleDirectory(
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
      } on _InstallException catch (e) {
        stderr.writeln(e.message);
        return genericErrorExitCode;
      }

      return 0;
    });
  }

  /// Throws a [_InstallException] with [message].
  ///
  /// This enables similar coding style to using [usageException]s.
  Never _installException(String message, {int? exitCode}) =>
      throw _InstallException(message, exitCode: exitCode);

  static Future<T> _inTempDir<T>(
      Future<T> Function(Directory tempDirectory) fun) async {
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

final class _InstallCommandParsedArguments {
  final String source;
  final _SourceKind sourceKind;
  final String? versionConstraint;
  final String? gitPath;
  final String? gitRef;
  final String? hostedUrl;
  final bool overwrite;

  _InstallCommandParsedArguments._({
    required this.source,
    required this.sourceKind,
    required this.versionConstraint,
    required this.gitPath,
    required this.gitRef,
    required this.hostedUrl,
    required this.overwrite,
  });
}

enum _SourceKind {
  git,
  hosted,
  path;

  static _SourceKind fromArgument(String argument) {
    if (_packageNameRegExp.hasMatch(argument)) {
      return hosted;
    }
    final parsedUri = Uri.tryParse(argument);
    if (parsedUri != null) {
      switch (parsedUri.scheme.toLowerCase()) {
        case 'git':
        case 'http':
        case 'https':
          return git;
      }
    }
    final parsedGitSshUrl = _GitSshUrl.tryParse(argument);
    if (parsedGitSshUrl != null) {
      return git;
    }
    return path;
  }

  /// A regular expression matching a Dart identifier.
  ///
  /// This also matches a package name, since they must be Dart identifiers.
  static final _identifierRegExp = RegExp(r'[a-zA-Z_]\w*');

  /// A regular expression matching allowed package names.
  ///
  /// This allows dot-separated valid Dart identifiers. The dots are there for
  /// compatibility with Google's internal Dart packages, but they may not be used
  /// when publishing a package to pub.dev.
  static final _packageNameRegExp = RegExp(
    '^${_identifierRegExp.pattern}(\\.${_identifierRegExp.pattern})*\$',
  );
}

// Expected format: git@host:owner/repository.git
class _GitSshUrl {
  final String user;
  final String host;
  final String owner;
  final String repository;
  final String fullUrl;

  _GitSshUrl({
    required this.user,
    required this.host,
    required this.owner,
    required this.repository,
    required this.fullUrl,
  });

  static _GitSshUrl? tryParse(String url) {
    final regex = RegExp(r'^(\w+)@([^:]+):([^/]+)/(.+?)(?:\.git)?$');
    final match = regex.firstMatch(url);

    if (match == null) {
      return null;
    }

    return _GitSshUrl(
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
class _InstallException implements Exception {
  final String message;
  final int? exitCode;

  _InstallException(
    this.message, {
    this.exitCode,
  });

  @override
  String toString() => message;
}
