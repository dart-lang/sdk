// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Common logic to make it easy to run the polymer linter and deploy tool.
///
/// The functions in this library are designed to make it easier to create
/// `build.dart` files. A `build.dart` file is a Dart script that can be invoked
/// from the command line, but that can also invoked automatically by the Dart
/// Editor whenever a file in your project changes or when selecting some menu
/// options, such as 'Reanalyze Sources'.
///
/// To work correctly, place the `build.dart` in the root of your project (where
/// pubspec.yaml lives). The file must be named exactly `build.dart`.
///
/// It's quite likely that in the near future `build.dart` will be replaced with
/// something else.  For example, `pub deploy` will deal with deploying
/// applications automatically, and the Dart Editor might provide other
/// mechanisms to hook linters.
///
/// There are three important functions exposed by this library [build], [lint],
/// and [deploy]. The following examples show common uses of these functions
/// when writing a `build.dart` file.
///
/// **Example 1**: Uses build.dart to run the linter tool.
///
///     import 'dart:io';
///     import 'package:polymer/builder.dart';
///
///     main() {
///        lint();
///     }
///
/// **Example 2**: Runs the linter and creates a deployable version of the app
/// every time.
///
///     import 'dart:io';
///     import 'package:polymer/builder.dart';
///
///     main() {
///        deploy(); // deploy also calls the linter internally.
///     }
///
/// **Example 3**: Always run the linter, but conditionally build a deployable
/// version. See [parseOptions] for a description of options parsed
/// automatically by this helper library.
///
///     import 'dart:io';
///     import 'package:polymer/builder.dart';
///
///     main(args) {
///        var options = parseOptions(args);
///        if (options.forceDeploy) {
///          deploy();
///        } else {
///          lint();
///        }
///     }
///
/// **Example 4**: Same as above, but uses [build] (which internally calls
/// either [lint] or [deploy]).
///
///     import 'dart:io';
///     import 'package:polymer/builder.dart';
///
///     main(args) {
///        build(options: parseOptions(args));
///     }
///
/// **Example 5**: Like the previous example, but indicates to the linter and
/// deploy tool which files are actually used as entry point files. See the
/// documentation of [build] below for more details.
///
///     import 'dart:io';
///     import 'package:polymer/builder.dart';
///
///     main(args) {
///        build(entryPoints: ['web/index.html'], options: parseOptions(args));
///     }
library polymer.builder;

import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';

import 'src/build/linter.dart';
import 'src/build/runner.dart';
import 'src/build/common.dart';

import 'transformer.dart';


/// Runs the polymer linter on any relevant file in your package, such as any
/// .html file under 'lib/', 'asset/', and 'web/'. And, if requested, creates a
/// directory suitable for deploying a Polymer application to a server.
///
/// The [entryPoints] list contains files under web/ that should be treated as
/// entry points. Each entry on this list is a relative path from the package
/// root (for example 'web/index.html'). If null, all files under 'web/' are
/// treated as possible entry points.
///
/// Options must be passed by
/// passing the [options] argument. The deploy operation is run only when the
/// command-line argument `--deploy` is present, or equivalently when
/// `options.forceDeploy` is true.
///
/// The linter and deploy steps needs to know the name of the [currentPackage]
/// and the location where to find the code for any package it depends on
/// ([packageDirs]). This is inferred automatically, but can be overriden if
/// those arguments are provided.
Future build({List<String> entryPoints, CommandLineOptions options,
    String currentPackage, Map<String, String> packageDirs}) {
  if (options == null) {
    print('warning: now that main takes arguments, you need to explicitly pass'
        ' options to build(). Running as if no options were passed.');
    options = parseOptions([]);
  }
  return options.forceDeploy
      ? deploy(entryPoints: entryPoints, options: options,
            currentPackage: currentPackage, packageDirs: packageDirs)
      : lint(entryPoints: entryPoints, options: options,
            currentPackage: currentPackage, packageDirs: packageDirs);
}


/// Runs the polymer linter on any relevant file in your package,
/// such as any .html file under 'lib/', 'asset/', and 'web/'.
///
/// The [entryPoints] list contains files under web/ that should be treated as
/// entry points. Each entry on this list is a relative path from the package
/// root (for example 'web/index.html'). If null, all files under 'web/' are
/// treated as possible entry points.
///
/// Options must be passed by passing the [options] argument.
///
/// The linter needs to know the name of the [currentPackage] and the location
/// where to find the code for any package it depends on ([packageDirs]). This
/// is inferred automatically, but can be overriden by passing the arguments.
Future lint({List<String> entryPoints, CommandLineOptions options,
    String currentPackage, Map<String, String> packageDirs}) {
  if (options == null) {
    print('warning: now that main takes arguments, you need to explicitly pass'
        ' options to lint(). Running as if no options were passed.');
    options = parseOptions([]);
  }
  if (currentPackage == null) currentPackage = readCurrentPackageFromPubspec();
  var linterOptions = new TransformOptions(entryPoints: entryPoints);
  var linter = new Linter(linterOptions);
  return runBarback(new BarbackOptions([[linter]], null,
      currentPackage: currentPackage, packageDirs: packageDirs,
      machineFormat: options.machineFormat));
}

/// Creates a directory suitable for deploying a Polymer application to a
/// server.
///
/// **Note**: this function will be replaced in the future by the `pub deploy`
/// command.
///
/// The [entryPoints] list contains files under web/ that should be treated as
/// entry points. Each entry on this list is a relative path from the package
/// root (for example 'web/index.html'). If null, all files under 'web/' are
/// treated as possible entry points.
///
/// Options must be passed by passing the [options] list.
///
/// The deploy step needs to know the name of the [currentPackage] and the
/// location where to find the code for any package it depends on
/// ([packageDirs]). This is inferred automatically, but can be overriden if
/// those arguments are provided.
Future deploy({List<String> entryPoints, CommandLineOptions options,
    String currentPackage, Map<String, String> packageDirs}) {
  if (options == null) {
    print('warning: now that main takes arguments, you need to explicitly pass'
        ' options to deploy(). Running as if no options were passed.');
    options = parseOptions([]);
  }
  if (currentPackage == null) currentPackage = readCurrentPackageFromPubspec();

  var transformOptions = new TransformOptions(
      entryPoints: entryPoints,
      directlyIncludeJS: options.directlyIncludeJS,
      contentSecurityPolicy: options.contentSecurityPolicy,
      releaseMode: options.releaseMode);

  var phases = new PolymerTransformerGroup(transformOptions).phases;
  var barbackOptions = new BarbackOptions(
      phases, options.outDir, currentPackage: currentPackage,
      packageDirs: packageDirs, machineFormat: options.machineFormat,
      // TODO(sigmund): include here also smoke transformer when it's on by
      // default.
      packagePhases: {'polymer': phasesForPolymer});
  return runBarback(barbackOptions)
      .then((_) => print('Done! All files written to "${options.outDir}"'));
}


/// Options that may be used either in build.dart or by the linter and deploy
/// tools.
class CommandLineOptions {
  /// Files marked as changed.
  final List<String> changedFiles;

  /// Files marked as removed.
  final List<String> removedFiles;

  /// Whether to clean intermediate artifacts, if any.
  final bool clean;

  /// Whether to do a full build (as if all files have changed).
  final bool full;

  /// Whether to print results using a machine parseable format.
  final bool machineFormat;

  /// Whether the force deploy option was passed in the command line.
  final bool forceDeploy;

  /// Location where to generate output files.
  final String outDir;

  /// True to use the CSP-compliant JS file.
  final bool contentSecurityPolicy;

  /// True to include the JS script tag directly, without the
  /// "packages/browser/dart.js" trampoline.
  final bool directlyIncludeJS;

  /// Run transformers in release mode. For instance, uses the minified versions
  /// of the web_components polyfill.
  final bool releaseMode;

  CommandLineOptions(this.changedFiles, this.removedFiles, this.clean,
      this.full, this.machineFormat, this.forceDeploy, this.outDir,
      this.directlyIncludeJS, this.contentSecurityPolicy,
      this.releaseMode);
}

/// Parse command-line arguments and return a [CommandLineOptions] object. The
/// following flags are parsed by this method.
///
///   * `--changed file-path`: notify of a file change.
///   * `--removed file-path`: notify that a file was removed.
///   * `--clean`: remove temporary artifacts (if any)
///   * `--full`: build everything, similar to marking every file as changed
///   * `--machine`: produce output that can be parsed by tools, such as the
///     Dart Editor.
///   * `--deploy`: force deploy.
///   * `--no-js`: deploy replaces *.dart scripts with *.dart.js. You can turn
///     this feature off with --no-js, which leaves "packages/browser/dart.js".
///   * `--csp`: replaces *.dart with *.dart.precompiled.js to comply with
///     Content Security Policy restrictions.
///   * `--help`: print documentation for each option and exit.
///
/// Currently not all the flags are used by [lint] or [deploy] above, but they
/// are available so they can be used from your `build.dart`. For instance, see
/// the top-level library documentation for an example that uses the
/// force-deploy option to conditionally call [deploy].
///
/// If this documentation becomes out of date, the best way to discover which
/// flags are supported is to invoke this function from your build.dart, and run
/// it with the `--help` command-line flag.
CommandLineOptions parseOptions([List<String> args]) {
  if (args == null) {
    print('warning: the list of arguments from main(List<String> args) now '
        'needs to be passed explicitly to parseOptions.');
    args = [];
  }
  var parser = new ArgParser()
    ..addOption('changed', help: 'The file has changed since the last build.',
        allowMultiple: true)
    ..addOption('removed', help: 'The file was removed since the last build.',
        allowMultiple: true)
    ..addFlag('clean', negatable: false,
        help: 'Remove any build artifacts (if any).')
    ..addFlag('full', negatable: false, help: 'perform a full build')
    ..addFlag('machine', negatable: false,
        help: 'Produce warnings in a machine parseable format.')
    ..addFlag('deploy', negatable: false,
        help: 'Whether to force deploying.')
    ..addOption('out', abbr: 'o', help: 'Directory to generate files into.',
        defaultsTo: 'out')
    ..addFlag('js', help:
        'deploy replaces *.dart scripts with *.dart.js. This flag \n'
        'leaves "packages/browser/dart.js" to do the replacement at runtime.',
        defaultsTo: true)
    ..addFlag('csp', help:
        'replaces *.dart with *.dart.precompiled.js to comply with \n'
        'Content Security Policy restrictions.')
    ..addFlag('debug', help:
        'run in debug mode. For example, use the debug polyfill \n'
        'web_components/platform.concat.js instead of the minified one.\n',
        defaultsTo: false)
    ..addFlag('help', abbr: 'h',
        negatable: false, help: 'Displays this help and exit.');

  showUsage() {
    print('Usage: dart build.dart [options]');
    print('\nThese are valid options expected by build.dart:');
    print(parser.getUsage());
  }

  var res;
  try {
    res = parser.parse(args);
  } on FormatException catch (e) {
    print(e.message);
    showUsage();
    exit(1);
  }
  if (res['help']) {
    print('A build script that invokes the polymer linter and deploy tools.');
    showUsage();
    exit(0);
  }
  return new CommandLineOptions(res['changed'], res['removed'], res['clean'],
      res['full'], res['machine'], res['deploy'], res['out'], res['js'],
      res['csp'], !res['debug']);
}
