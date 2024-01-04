import 'dart:io';
import 'package:dart2wasm/compiler_options.dart';
import 'package:dart2wasm/compile.dart';
import 'package:front_end/src/api_unstable/vm.dart' show printDiagnosticMessage;
export 'package:dart2wasm/compiler_options.dart';

typedef PrintError = void Function(String error);

Future<int> generateWasm(WasmCompilerOptions options,
    {bool verbose = false, PrintError errorPrinter = print}) async {
  if (verbose) {
    print('Running dart compile wasm...');
    print('  - input file name   = ${options.mainUri}');
    print('  - output file name  = ${options.outputFile}');
    print('  - sdkPath           = ${options.sdkPath}');
    print('  - librariesSpecPath = ${options.librariesSpecPath}');
    print('  - packagesPath file = ${options.packagesPath}');
    print('  - platformPath file = ${options.platformPath}');
  }

  CompilerOutput? output = await compileToModule(
      options, (message) => printDiagnosticMessage(message, errorPrinter));

  if (output == null) {
    return 1;
  }

  final File outFile = File(options.outputFile);
  outFile.parent.createSync(recursive: true);
  await outFile.writeAsBytes(output.wasmModule);

  final jsFile = options.outputJSRuntimeFile ??
      '${options.outputFile.substring(0, options.outputFile.lastIndexOf('.'))}.mjs';
  await File(jsFile).writeAsString(output.jsRuntime);

  return 0;
}
