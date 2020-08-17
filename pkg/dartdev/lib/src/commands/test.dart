// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:args/args.dart';

import '../core.dart';
import '../experiments.dart';
import '../sdk.dart';
import '../vm_interop_handler.dart';

class TestCommand extends DartdevCommand<int> {
  TestCommand() : super('test', 'Runs tests in this project.') {
    generateParser(argParser);
  }

  @override
  void printUsage() {
    if (!Sdk.checkArtifactExists(sdk.pub)) {
      return;
    }
    super.printUsage();
  }

  @override
  FutureOr<int> run() async {
    if (!Sdk.checkArtifactExists(sdk.pub)) {
      return 255;
    }
    // "Could not find package "test". Did you forget to add a dependency?"
    if (project.hasPackageConfigFile) {
      if ((project.packageConfig != null) &&
          !project.packageConfig.hasDependency('test')) {
        _printPackageTestInstructions();
        return 65;
      }
    }

    final command = sdk.pub;
    final testArgs = argResults.arguments.toList();

    final args = [
      'run',
      if (wereExperimentsSpecified)
        '--$experimentFlagName=${specifiedExperiments.join(',')}',
      'test',
      ...testArgs,
    ];

    log.trace('$command ${args.join(' ')}');
    VmInteropHandler.run(command, args);
    return 0;
  }

  void _printPackageTestInstructions() {
    log.stdout('');

    final ansi = log.ansi;

    log.stdout('''
In order to run tests, you need to add a dependency on package:test in your
pubspec.yaml file:

${ansi.emphasized('dev_dependencies:\n  test: ^1.0.0')}

See https://pub.dev/packages/test#-installing-tab- for more information on
adding package:test, and https://dart.dev/guides/testing for general
information on testing.''');
  }

  /// This content has been copied from and kept in sync with
  /// https://github.com/dart-lang/test, by having a copy in dartdev itself,
  /// help is faster and more robust, see
  /// https://github.com/dart-lang/sdk/issues/42014.
  void generateParser(ArgParser parser) {
    // Set in test/pkgs/test_core/lib/src/runner/configuration/values.dart:
    final defaultConcurrency = math.max(1, Platform.numberOfProcessors ~/ 2);

    /// The parser used to parse the command-line arguments.
    var allRuntimes = Runtime.builtIn.toList()..remove(Runtime.vm);
    if (!Platform.isMacOS) allRuntimes.remove(Runtime.safari);
    if (!Platform.isWindows) allRuntimes.remove(Runtime.internetExplorer);

//    parser.addFlag('help',
//        abbr: 'h', negatable: false, help: 'Shows this usage information.');
    parser.addFlag('version',
        negatable: false, help: "Shows the package's version.");

    // Note that defaultsTo declarations here are only for documentation
    // purposes.
    // We pass null instead of the default so that it merges properly with the
    // config file.

    parser.addSeparator('======== Selecting Tests');
    parser.addMultiOption('name',
        abbr: 'n',
        help: 'A substring of the name of the test to run.\n'
            'Regular expression syntax is supported.\n'
            'If passed multiple times, tests must match all substrings.',
        splitCommas: false);
    parser.addMultiOption('plain-name',
        abbr: 'N',
        help: 'A plain-text substring of the name of the test to run.\n'
            'If passed multiple times, tests must match all substrings.',
        splitCommas: false);
    parser.addMultiOption('tags',
        abbr: 't',
        help: 'Run only tests with all of the specified tags.\n'
            'Supports boolean selector syntax.');
    parser.addMultiOption('tag', hide: true);
    parser.addMultiOption('exclude-tags',
        abbr: 'x',
        help: "Don't run tests with any of the specified tags.\n"
            'Supports boolean selector syntax.');
    parser.addMultiOption('exclude-tag', hide: true);
    parser.addFlag('run-skipped',
        help: 'Run skipped tests instead of skipping them.');

    parser.addSeparator('======== Running Tests');

    // The UI term "platform" corresponds with the implementation term "runtime".
    // The [Runtime] class used to be called [TestPlatform], but it was changed to
    // avoid conflicting with [SuitePlatform]. We decided not to also change the
    // UI to avoid a painful migration.
    parser.addMultiOption('platform',
        abbr: 'p',
        help: 'The platform(s) on which to run the tests.\n'
            '[vm (default), '
            '${allRuntimes.map((runtime) => runtime.identifier).join(", ")}]');
    parser.addMultiOption('preset',
        abbr: 'P', help: 'The configuration preset(s) to use.');
    parser.addOption('concurrency',
        abbr: 'j',
        help: 'The number of concurrent test suites run.',
        defaultsTo: defaultConcurrency.toString(),
        valueHelp: 'threads');
    parser.addOption('total-shards',
        help: 'The total number of invocations of the test runner being run.');
    parser.addOption('shard-index',
        help: 'The index of this test runner invocation (of --total-shards).');
    parser.addOption('pub-serve',
        help: 'The port of a pub serve instance serving "test/".',
        valueHelp: 'port');
    parser.addOption('timeout',
        help: 'The default test timeout. For example: 15s, 2x, none',
        defaultsTo: '30s');
    parser.addFlag('pause-after-load',
        help: 'Pauses for debugging before any tests execute.\n'
            'Implies --concurrency=1, --debug, and --timeout=none.\n'
            'Currently only supported for browser tests.',
        negatable: false);
    parser.addFlag('debug',
        help: 'Runs the VM and Chrome tests in debug mode.', negatable: false);
    parser.addOption('coverage',
        help: 'Gathers coverage and outputs it to the specified directory.\n'
            'Implies --debug.',
        valueHelp: 'directory');
    parser.addFlag('chain-stack-traces',
        help: 'Chained stack traces to provide greater exception details\n'
            'especially for asynchronous code. It may be useful to disable\n'
            'to provide improved test performance but at the cost of\n'
            'debuggability.',
        defaultsTo: true);
    parser.addFlag('no-retry',
        help: "Don't re-run tests that have retry set.",
        defaultsTo: false,
        negatable: false);
    parser.addOption('test-randomize-ordering-seed',
        help: 'The seed to randomize the execution order of test cases.\n'
            'Must be a 32bit unsigned integer or "random".\n'
            'If "random", pick a random seed to use.\n'
            'If not passed, do not randomize test case execution order.');

    var defaultReporter = 'compact';
    var reporterDescriptions = <String, String>{
      'compact': 'A single line, updated continuously.',
      'expanded': 'A separate line for each update.',
      'json': 'A machine-readable format (see https://goo.gl/gBsV1a).'
    };

    parser.addSeparator('======== Output');
    parser.addOption('reporter',
        abbr: 'r',
        help: 'The runner used to print test results.',
        defaultsTo: defaultReporter,
        allowed: reporterDescriptions.keys.toList(),
        allowedHelp: reporterDescriptions);
    parser.addOption('file-reporter',
        help: 'The reporter used to write test results to a file.\n'
            'Should be in the form <reporter>:<filepath>, '
            'e.g. "json:reports/tests.json"');
    parser.addFlag('verbose-trace',
        negatable: false,
        help: 'Whether to emit stack traces with core library frames.');
    parser.addFlag('js-trace',
        negatable: false,
        help: 'Whether to emit raw JavaScript stack traces for browser tests.');
    parser.addFlag('color',
        help: 'Whether to use terminal colors.\n(auto-detected by default)');

    /// The following options are used only by the internal Google test runner.
    /// They're hidden and not supported as stable API surface outside Google.
    parser.addOption('configuration',
        help: 'The path to the configuration file.', hide: true);
    parser.addOption('dart2js-path',
        help: 'The path to the dart2js executable.', hide: true);
    parser.addMultiOption('dart2js-args',
        help: 'Extra arguments to pass to dart2js.', hide: true);

    // If we're running test/dir/my_test.dart, we'll look for
    // test/dir/my_test.dart.html in the precompiled directory.
    parser.addOption('precompiled',
        help: 'The path to a mirror of the package directory containing HTML '
            'that points to precompiled JS.',
        hide: true);
  }
}

/// An enum of all Dart runtimes supported by the test runner.
class Runtime {
  // When adding new runtimes, be sure to update the baseline and derived
  // variable tests in test/backend/platform_selector/evaluate_test.

  /// The command-line Dart VM.
  static const Runtime vm = Runtime('VM', 'vm', isDartVM: true);

  /// Google Chrome.
  static const Runtime chrome =
      Runtime('Chrome', 'chrome', isBrowser: true, isJS: true, isBlink: true);

  /// PhantomJS.
  static const Runtime phantomJS = Runtime('PhantomJS', 'phantomjs',
      isBrowser: true, isJS: true, isBlink: true, isHeadless: true);

  /// Mozilla Firefox.
  static const Runtime firefox =
      Runtime('Firefox', 'firefox', isBrowser: true, isJS: true);

  /// Apple Safari.
  static const Runtime safari =
      Runtime('Safari', 'safari', isBrowser: true, isJS: true);

  /// Microsoft Internet Explorer.
  static const Runtime internetExplorer =
      Runtime('Internet Explorer', 'ie', isBrowser: true, isJS: true);

  /// The command-line Node.js VM.
  static const Runtime nodeJS = Runtime('Node.js', 'node', isJS: true);

  /// The platforms that are supported by the test runner by default.
  static const List<Runtime> builtIn = [
    Runtime.vm,
    Runtime.chrome,
    Runtime.phantomJS,
    Runtime.firefox,
    Runtime.safari,
    Runtime.internetExplorer,
    Runtime.nodeJS
  ];

  /// The human-friendly name of the platform.
  final String name;

  /// The identifier used to look up the platform.
  final String identifier;

  /// The parent platform that this is based on, or `null` if there is no
  /// parent.
  final Runtime parent;

  /// Returns whether this is a child of another platform.
  bool get isChild => parent != null;

  /// Whether this platform runs the Dart VM in any capacity.
  final bool isDartVM;

  /// Whether this platform is a browser.
  final bool isBrowser;

  /// Whether this platform runs Dart compiled to JavaScript.
  final bool isJS;

  /// Whether this platform uses the Blink rendering engine.
  final bool isBlink;

  /// Whether this platform has no visible window.
  final bool isHeadless;

  /// Returns the platform this is based on, or [this] if it's not based on
  /// anything.
  ///
  /// That is, returns [parent] if it's non-`null` or [this] if it's `null`.
  Runtime get root => parent ?? this;

  const Runtime(this.name, this.identifier,
      {this.isDartVM = false,
      this.isBrowser = false,
      this.isJS = false,
      this.isBlink = false,
      this.isHeadless = false})
      : parent = null;

  Runtime._child(this.name, this.identifier, Runtime parent)
      : isDartVM = parent.isDartVM,
        isBrowser = parent.isBrowser,
        isJS = parent.isJS,
        isBlink = parent.isBlink,
        isHeadless = parent.isHeadless,
        parent = parent;

  /// Converts a JSON-safe representation generated by [serialize] back into a
  /// [Runtime].
  factory Runtime.deserialize(Object serialized) {
    if (serialized is String) {
      return builtIn
          .firstWhere((platform) => platform.identifier == serialized);
    }

    var map = serialized as Map;
    var parent = map['parent'];
    if (parent != null) {
      // Note that the returned platform's [parent] won't necessarily be `==` to
      // a separately-deserialized parent platform. This should be fine, though,
      // since we only deserialize platforms in the remote execution context
      // where they're only used to evaluate platform selectors.
      return Runtime._child(map['name'] as String, map['identifier'] as String,
          Runtime.deserialize(parent as Object));
    }

    return Runtime(map['name'] as String, map['identifier'] as String,
        isDartVM: map['isDartVM'] as bool,
        isBrowser: map['isBrowser'] as bool,
        isJS: map['isJS'] as bool,
        isBlink: map['isBlink'] as bool,
        isHeadless: map['isHeadless'] as bool);
  }

  /// Converts [this] into a JSON-safe object that can be converted back to a
  /// [Runtime] using [Runtime.deserialize].
  Object serialize() {
    if (builtIn.contains(this)) return identifier;

    if (parent != null) {
      return {
        'name': name,
        'identifier': identifier,
        'parent': parent.serialize()
      };
    }

    return {
      'name': name,
      'identifier': identifier,
      'isDartVM': isDartVM,
      'isBrowser': isBrowser,
      'isJS': isJS,
      'isBlink': isBlink,
      'isHeadless': isHeadless
    };
  }

  /// Returns a child of [this] that counts as both this platform's identifier
  /// and the new [identifier].
  ///
  /// This may not be called on a platform that's already a child.
  Runtime extend(String name, String identifier) {
    if (parent == null) return Runtime._child(name, identifier, this);
    throw StateError('A child platform may not be extended.');
  }

  @override
  String toString() => name;
}
