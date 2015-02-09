/// Tests code generation.
/// Runs Dart Dev Compiler on all input in the `codegen` directory and checks
/// that the output is what we expected.
library ddc.test.codegen_test;

import 'dart:io';
import 'package:args/args.dart';
import 'package:cli_util/cli_util.dart' show getSdkDir;
import 'package:ddc/devc.dart';
import 'package:ddc/src/checker/resolver.dart' show TypeResolver;
import 'package:logging/logging.dart' show Level;
import 'package:path/path.dart' as path;
import 'package:unittest/unittest.dart';

final ArgParser argParser = new ArgParser()
  ..addOption('dart-sdk', help: 'Dart SDK Path', defaultsTo: null)
  ..addFlag('dart-gen',
      abbr: 'd', help: 'Generate dart output', defaultsTo: false);

main(arguments) {
  if (arguments == null) arguments = [];
  ArgResults args = argParser.parse(arguments);
  var script = Platform.script.path;
  var dartGen = args['dart-gen'];
  var filePattern = new RegExp(args.rest.length > 0 ? args.rest[0] : '.');
  var compilerMessages = new StringBuffer();
  var loggerSub;

  setUp(() {
    compilerMessages.clear();
    loggerSub = setupLogger(Level.CONFIG, compilerMessages.writeln);
  });

  tearDown(() {
    if (loggerSub != null) {
      loggerSub.cancel();
      loggerSub = null;
    }
  });

  var testDir = path.absolute(path.dirname(script));
  var inputDir = dartGen
      ? path.join(testDir, 'dart_codegen')
      : path.join(testDir, 'codegen');
  var actualDir = path.join(inputDir, 'actual');
  var paths = new Directory(inputDir)
      .listSync()
      .where((f) => f is File)
      .map((f) => f.path)
      .where((p) => p.endsWith('.dart') && filePattern.hasMatch(p));

  var realSdk = new TypeResolver.fromDir(getSdkDir(arguments).path);

  // Validate that old output is gone before running.
  // TODO(jmesserly): it'd be nice to do all cleanup here, including removing
  // pub's 'packages' symlinks which mess up the diff. That way this test
  // can be self contained instead of depending on a shell script.
  if (new Directory(actualDir).existsSync()) {
    throw 'Old compiler output should be cleaned up first. Use ./test/test.sh';
  }

  for (var filePath in paths) {
    var filename = path.basenameWithoutExtension(filePath);

    test('devc $filename.dart', () {
      compilerMessages.writeln('// Messages from compiling $filename.dart');

      var result = compile(filePath, realSdk,
          outputDir: actualDir,
          useColors: false,
          outputDart: dartGen,
          formatOutput: dartGen);
      var success = !result.failure;

      // Write compiler messages to disk.
      new File(path.join(actualDir, '$filename.txt'))
          .writeAsStringSync(compilerMessages.toString());

      var outputDir = new Directory(path.join(actualDir, filename));
      expect(outputDir.existsSync(), success,
          reason: '${outputDir.path} was created iff compilation succeeds');

      // TODO(jmesserly): ideally we'd diff the output here. For now it
      // happens in the containing shell script.
    });
  }

  test('devc dart:core', () {
    // Get the test SDK. We use a checked in copy so test expectations can be
    // generated against a specific SDK version.
    // TODO(jmesserly): eventually we should track compiler messages.
    // For now we're just trying to get decent code generation.
    var testSdk = new TypeResolver.fromDir(path.join(testDir, 'sdk'));

    var result = compile('dart:core', testSdk,
        outputDir: actualDir,
        checkSdk: true,
        forceCompile: true,
        outputDart: dartGen,
        formatOutput: dartGen);

    var coreDir = dartGen ? 'dart.core' : 'core';
    var outputDir = new Directory(path.join(actualDir, coreDir));
    expect(outputDir.existsSync(), true,
        reason: '${outputDir.path} was created for dart:core');
  });
}
