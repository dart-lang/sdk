// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:io';

import 'path.dart';

final _multiHtmlTestGroupRegExp = RegExp(r"\s*[^/]\s*group\('[^,']*");
final _multiHtmlTestRegExp = RegExp(r"useHtmlIndividualConfiguration\(\)");

// TODO(rnystrom): Remove support for "///" once tests have been migrated.
// https://dart-review.googlesource.com/c/sdk/+/106201
// https://github.com/dart-lang/co19/issues/391
/// Require at least one non-space character before '//[/#]'.
final _multitestRegExp = RegExp(r"\S *//[#/] \w+:(.*)");

final _vmOptionsRegExp = RegExp(r"// VMOptions=(.*)");
final _environmentRegExp = RegExp(r"// Environment=(.*)");
final _packageRootRegExp = RegExp(r"// PackageRoot=(.*)");
final _packagesRegExp = RegExp(r"// Packages=(.*)");

List<String> _splitWords(String s) =>
    s.split(' ').where((e) => e != '').toList();

List<String> _parseOption(String filePath, String contents, String name,
    {bool allowMultiple = false}) {
  var matches = RegExp('// $name=(.*)').allMatches(contents);
  if (!allowMultiple && matches.length > 1) {
    throw Exception('More than one "// $name=" line in test $filePath');
  }

  var options = <String>[];
  for (var match in matches) {
    options.addAll(_splitWords(match[1]));
  }

  return options;
}

abstract class _TestFileBase {
  /// The test suite directory containing this test.
  final Path _suiteDirectory;

  /// The full path to the test file.
  final Path path;

  /// The path to the original multitest file this test was generated from.
  ///
  /// If this test was not generated from a multitest, just returns [path].
  Path get originPath;

  String get multitestKey;

  _TestFileBase(this._suiteDirectory, this.path) {
    assert(path.isAbsolute);
  }

  /// The logical name of the test.
  ///
  /// This is its path relative to the test suite directory containing it,
  /// minus any file extension. If this test was split from a multitest,
  /// it contains the multitest key.
  String get name {
    var testNamePath = originPath.relativeTo(_suiteDirectory);
    var directory = testNamePath.directoryPath;
    var filenameWithoutExt = testNamePath.filenameWithoutExtension;

    String concat(String base, String part) {
      if (base == "") return part;
      if (part == "") return base;
      return "$base/$part";
    }

    var result = "$directory";
    result = concat(result, "$filenameWithoutExt");
    result = concat(result, multitestKey);
    return result;
  }
}

/// Represents a single ".dart" file used as a test and the parsed metadata it
/// contains.
///
/// Special options for individual tests are currently specified in various
/// ways: with comments directly in test files, by using certain imports, or
/// by creating additional files in the test directories.
///
/// Here is a list of options that are used by 'test.dart' today:
///
/// *   Flags can be passed to the VM process that runs the test by adding a
///     comment to the test file:
///
///         // VMOptions=--flag1 --flag2
///
/// *   Flags can be passed to dart2js, vm or dartdevc by adding a comment to
///     the test file:
///
///         // SharedOptions=--flag1 --flag2
///
/// *   Flags can be passed to dart2js by adding a comment to the test file:
///
///         // dart2jsOptions=--flag1 --flag2
///
/// *   Flags can be passed to the dart script that contains the test also
///     using comments, as follows:
///
///         // DartOptions=--flag1 --flag2
///
/// *   Extra environment variables can be passed to the process that runs
///     the test by adding comment(s) to the test file:
///
///         // Environment=ENV_VAR1=foo bar
///         // Environment=ENV_VAR2=bazz
///
/// *   Most tests are not web tests, but can (and will be) wrapped within an
///     HTML file and another script file to test them also on browser
///     environments (e.g. language and corelib tests are run this way). We
///     deduce that if a file with the same name as the test, but ending in
///     ".html" instead of ".dart" exists, the test was intended to be a web
///     test and no wrapping is necessary.
///
/// *   This test requires libfoobar.so, libfoobar.dylib or foobar.dll to be in
///     the system linker path of the VM.
///
///         // SharedObjects=foobar
///
/// *   'test.dart' assumes tests fail if the process returns a non-zero exit
///     code (in the case of web tests, we check for PASS/FAIL indications in
///     the test output).
class TestFile extends _TestFileBase {
  /// Read the test file from the given [filePath].
  factory TestFile.read(Path suiteDirectory, String filePath) => TestFile.parse(
      suiteDirectory, filePath, File(filePath).readAsStringSync());

  /// Parse a test file with [contents].
  factory TestFile.parse(
      Path suiteDirectory, String filePath, String contents) {
    if (filePath.endsWith('.dill')) {
      return TestFile._(suiteDirectory, Path(filePath),
          vmOptions: [[]],
          sharedOptions: [],
          dart2jsOptions: [],
          ddcOptions: [],
          dartOptions: [],
          packageRoot: null,
          packages: null,
          hasSyntaxError: false,
          hasCompileError: false,
          hasRuntimeError: false,
          hasStaticWarning: false,
          hasCrash: false,
          isMultitest: false,
          isMultiHtmlTest: false,
          subtestNames: [],
          sharedObjects: [],
          otherResources: []);
    }

    // VM options.
    var vmOptions = <List<String>>[];
    var matches = _vmOptionsRegExp.allMatches(contents);
    for (var match in matches) {
      vmOptions.add(_splitWords(match[1]));
    }
    if (vmOptions.isEmpty) vmOptions.add(<String>[]);

    // Other options.
    var dartOptions = _parseOption(filePath, contents, 'DartOptions');
    var sharedOptions = _parseOption(filePath, contents, 'SharedOptions');
    var dart2jsOptions = _parseOption(filePath, contents, 'dart2jsOptions');
    var ddcOptions = _parseOption(filePath, contents, 'dartdevcOptions');
    var otherResources =
        _parseOption(filePath, contents, 'OtherResources', allowMultiple: true);
    var sharedObjects =
        _parseOption(filePath, contents, 'SharedObjects', allowMultiple: true);

    // Environment.
    Map<String, String> environment;
    matches = _environmentRegExp.allMatches(contents);
    for (var match in matches) {
      var envDef = match[1];
      var pos = envDef.indexOf('=');
      var name = (pos < 0) ? envDef : envDef.substring(0, pos);
      var value = (pos < 0) ? '' : envDef.substring(pos + 1);
      environment ??= {};
      environment[name] = value;
    }

    // Packages.
    String packageRoot;
    String packages;
    matches = _packageRootRegExp.allMatches(contents);
    for (var match in matches) {
      if (packageRoot != null || packages != null) {
        throw Exception('More than one "// Package... line in test $filePath');
      }
      packageRoot = match[1];
      if (packageRoot != 'none') {
        // PackageRoot=none means that no packages or package-root option
        // should be given. Any other value overrides package-root and
        // removes any packages option.  Don't use with // Packages=.
        packageRoot = Uri.file(filePath)
            .resolveUri(Uri.directory(packageRoot))
            .toFilePath();
      }
    }

    matches = _packagesRegExp.allMatches(contents);
    for (var match in matches) {
      if (packages != null || packageRoot != null) {
        throw Exception('More than one "// Package..." line in test $filePath');
      }
      packages = match[1];
      if (packages != 'none') {
        // Packages=none means that no packages or package-root option
        // should be given. Any other value overrides packages and removes
        // any package-root option. Don't use with // PackageRoot=.
        packages =
            Uri.file(filePath).resolveUri(Uri.file(packages)).toFilePath();
      }
    }

    var isMultitest = _multitestRegExp.hasMatch(contents);
    var isMultiHtmlTest = _multiHtmlTestRegExp.hasMatch(contents);

    var subtestNames = <String>[];
    if (isMultiHtmlTest) {
      for (var match in _multiHtmlTestGroupRegExp.allMatches(contents)) {
        var fullMatch = match.group(0);
        subtestNames.add(fullMatch.substring(fullMatch.indexOf("'") + 1));
      }
    }

    // TODO(rnystrom): During the migration of the existing tests to Dart 2.0,
    // we have a number of tests that used to both generate static type warnings
    // and also validate some runtime behavior in an implementation that
    // ignores those warnings. Those warnings are now errors. The test code
    // validates the runtime behavior can and should be removed, but the code
    // that causes the static warning should still be preserved since that is
    // part of our coverage of the static type system.
    //
    // The test needs to indicate that it should have a static error. We could
    // put that in the status file, but that makes it confusing because it
    // would look like implementations that *don't* report the error are more
    // correct. Eventually, we want to have a notation similar to what front_end
    // is using for the inference tests where we can put a comment inside the
    // test that says "This specific static error should be reported right by
    // this token."
    //
    // That system isn't in place yet, so we do a crude approximation here in
    // test.dart. If a test contains `/*@compile-error=`, which matches the
    // beginning of the tag syntax that front_end uses, then we assume that
    // this test must have a static error somewhere in it.
    //
    // Redo this code once we have a more precise test framework for detecting
    // and locating these errors.
    var hasSyntaxError = contents.contains("@syntax-error");
    var hasCompileError = hasSyntaxError || contents.contains("@compile-error");

    return TestFile._(suiteDirectory, Path(filePath),
        packageRoot: packageRoot,
        packages: packages,
        environment: environment,
        isMultitest: isMultitest,
        isMultiHtmlTest: isMultiHtmlTest,
        hasSyntaxError: hasSyntaxError,
        hasCompileError: hasCompileError,
        hasRuntimeError: contents.contains("@runtime-error"),
        hasStaticWarning: contents.contains("@static-warning"),
        hasCrash: false,
        subtestNames: subtestNames,
        sharedOptions: sharedOptions,
        dartOptions: dartOptions,
        dart2jsOptions: dart2jsOptions,
        ddcOptions: ddcOptions,
        vmOptions: vmOptions,
        sharedObjects: sharedObjects,
        otherResources: otherResources);
  }

  /// A special fake test file for representing a VM unit test written in C++.
  TestFile.vmUnitTest(
      {this.hasSyntaxError,
      this.hasCompileError,
      this.hasRuntimeError,
      this.hasStaticWarning,
      this.hasCrash})
      : packageRoot = null,
        packages = null,
        environment = null,
        isMultitest = false,
        isMultiHtmlTest = false,
        subtestNames = [],
        sharedOptions = [],
        dartOptions = [],
        dart2jsOptions = [],
        ddcOptions = [],
        vmOptions = [],
        sharedObjects = [],
        otherResources = [],
        super(null, null);

  TestFile._(Path suiteDirectory, Path path,
      {this.packageRoot,
      this.packages,
      this.environment,
      this.isMultitest,
      this.isMultiHtmlTest,
      this.hasSyntaxError,
      this.hasCompileError,
      this.hasRuntimeError,
      this.hasStaticWarning,
      this.hasCrash,
      this.subtestNames,
      this.sharedOptions,
      this.dartOptions,
      this.dart2jsOptions,
      this.ddcOptions,
      this.vmOptions,
      this.sharedObjects,
      this.otherResources})
      : super(suiteDirectory, path) {
    assert(!isMultitest || dartOptions.isEmpty);
  }

  Path get originPath => path;

  /// The name of the multitest section this file corresponds to if it was
  /// generated from a multitest. Otherwise, returns an empty string.
  String get multitestKey => "";

  final String packageRoot;
  final String packages;

  final Map<String, String> environment;

  final bool isMultitest;
  final bool isMultiHtmlTest;
  final bool hasSyntaxError;
  final bool hasCompileError;
  final bool hasRuntimeError;
  final bool hasStaticWarning;
  final bool hasCrash;

  final List<String> subtestNames;
  final List<String> sharedOptions;
  final List<String> dartOptions;
  final List<String> dart2jsOptions;
  final List<String> ddcOptions;
  final List<List<String>> vmOptions;
  final List<String> sharedObjects;
  final List<String> otherResources;

  /// Derive a multitest test section file from this multitest file with the
  /// given [multitestKey] and expectations.
  TestFile split(Path path, String multitestKey,
          {bool hasCompileError,
          bool hasRuntimeError,
          bool hasStaticWarning,
          bool hasSyntaxError}) =>
      _MultitestFile(this, path, multitestKey,
          hasCompileError: hasCompileError ?? false,
          hasRuntimeError: hasRuntimeError ?? false,
          hasStaticWarning: hasStaticWarning ?? false,
          hasSyntaxError: hasSyntaxError ?? false);

  String toString() => """TestFile(
  packageRoot: $packageRoot
  packages: $packages
  environment: $environment
  isMultitest: $isMultitest
  isMultiHtmlTest: $isMultiHtmlTest
  hasSyntaxError: $hasSyntaxError
  hasCompileError: $hasCompileError
  hasRuntimeError: $hasRuntimeError
  hasStaticWarning: $hasStaticWarning
  hasCrash: $hasCrash
  subtestNames: $subtestNames
  sharedOptions: $sharedOptions
  dartOptions: $dartOptions
  dart2jsOptions: $dart2jsOptions
  ddcOptions: $ddcOptions
  vmOptions: $vmOptions
  sharedObjects: $sharedObjects
  otherResources: $otherResources
)""";
}

/// A [TestFile] for a single section file derived from a multitest.
///
/// This inherits most properties from the original test file, but overrides
/// the error flags based on the multitest section's expectation.
class _MultitestFile extends _TestFileBase implements TestFile {
  /// The authored test file that was split to generate this multitest.
  final TestFile _origin;

  final String multitestKey;

  final bool hasCompileError;
  final bool hasRuntimeError;
  final bool hasStaticWarning;
  final bool hasSyntaxError;
  bool get hasCrash => _origin.hasCrash;

  _MultitestFile(this._origin, Path path, this.multitestKey,
      {this.hasCompileError,
      this.hasRuntimeError,
      this.hasStaticWarning,
      this.hasSyntaxError})
      : super(_origin._suiteDirectory, path);

  Path get originPath => _origin.path;

  String get packageRoot => _origin.packageRoot;
  String get packages => _origin.packages;

  List<String> get dart2jsOptions => _origin.dart2jsOptions;
  List<String> get dartOptions => _origin.dartOptions;
  List<String> get ddcOptions => _origin.ddcOptions;
  Map<String, String> get environment => _origin.environment;

  bool get isMultiHtmlTest => _origin.isMultiHtmlTest;
  bool get isMultitest => _origin.isMultitest;

  List<String> get otherResources => _origin.otherResources;
  List<String> get sharedObjects => _origin.sharedObjects;
  List<String> get sharedOptions => _origin.sharedOptions;
  List<String> get subtestNames => _origin.subtestNames;
  List<List<String>> get vmOptions => _origin.vmOptions;

  TestFile split(Path path, String multitestKey,
          {bool hasCompileError,
          bool hasRuntimeError,
          bool hasStaticWarning,
          bool hasSyntaxError}) =>
      throw UnsupportedError(
          "Can't derive a test from one already derived from a multitest.");
}
