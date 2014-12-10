/// Tests JavaScript code generation.
/// Runs Dart Dev Compiler on all input in the `codengen` directory and checks
/// that the JavaScript output is what we expected.
library ddc.test.codegen_test;

import 'dart:io';
import 'package:ddc/devc.dart';
import 'package:ddc/src/dart_sdk.dart' show dartSdkDirectory;
import 'package:ddc/src/resolver.dart' show TypeResolver;
import 'package:logging/logging.dart' show Level;
import 'package:path/path.dart' as path;
import 'package:unittest/unittest.dart';

main(arguments) {
  if (arguments == null) arguments = [];
  var script = Platform.script.path;
  var filePattern = new RegExp(arguments.length > 0 ? arguments[0] : '.');

  var compilerMessages = new StringBuffer();
  var loggerSub;

  setUp(() {
    compilerMessages.clear();
    loggerSub =
        setupLogger(Level.CONFIG, compilerMessages.writeln, useColors: false);
  });

  tearDown(() {
    if (loggerSub != null) {
      loggerSub.cancel();
      loggerSub = null;
    }
  });

  var testDir = path.absolute(path.dirname(script));
  var inputDir = path.join(testDir, 'codegen');
  var expectDir = path.join(inputDir, 'expect');
  var actualDir = path.join(inputDir, 'actual');

  var paths = new Directory(inputDir)
      .listSync()
      .where((f) => f is File)
      .map((f) => f.path)
      .where((p) => p.endsWith('.dart') && filePattern.hasMatch(p));

  var sdkResolver =
      new TypeResolver(TypeResolver.sdkResolverFromDir(dartSdkDirectory));

  // Validate that old output is gone before running.
  // TODO(jmesserly): it'd be nice to do all cleanup here, including removing
  // pub's 'packages' symlinks which mess up the diff. That way this test
  // can be self contained instead of depending on a shell script.
  if (new Directory(actualDir).existsSync()) {
    throw 'Old compiler output should be cleaned up first. Use ./test/test.sh';
  }

  for (var filePath in paths) {
    var filename = path.basenameWithoutExtension(filePath);

    test('ddc $filename.dart', () {
      compilerMessages.writeln('// Messages from compiling $filename.dart');

      return compile(filePath, sdkResolver, outputDir: actualDir,
          useColors: false).then((success) {

        // Write compiler messages to disk.
        new File(path.join(actualDir, '$filename.txt'))
            .writeAsStringSync(compilerMessages.toString());

        var outputDir = new Directory(path.join(actualDir, filename));
        expect(outputDir.existsSync(), success,
            reason: '${outputDir.path} was created iff compilation succeeds');

        // TODO(jmesserly): ideally we'd diff the output here. For now it
        // happens in the containing shell script.
      });
    });
  }
}
