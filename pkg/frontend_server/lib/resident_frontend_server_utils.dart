// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert' show jsonDecode, jsonEncode;
import 'dart:io'
    show Directory, File, FileSystemException, InternetAddress, Socket;

import 'package:path/path.dart' as path;

final class ResidentCompilerInfo {
  /// The SDK hash that kernel files compiled using the Resident Frontend
  /// Compiler associated with this object will be stamped with.
  final String? sdkHash;

  /// The address that the Resident Frontend Compiler associated with this
  /// object is listening from.
  final InternetAddress address;

  /// The port number that the Resident Frontend Compiler associated with this
  /// object is listening on.
  final int port;

  /// Extracts the value associated with a key from [entries], where [entries]
  /// is a [String] with the format '$key1:$value1 $key2:$value2 ...'.
  static String _extractValueAssociatedWithKey(String entries, String key) =>
      new RegExp(
        '$key:'
        r'(\S+)(\s|$)',
      ).allMatches(entries).first[1]!;

  static ResidentCompilerInfo fromFile(File file) {
    final String fileContents = file.readAsStringSync();

    return new ResidentCompilerInfo._(
      sdkHash: fileContents.contains('sdkHash:')
          ? _extractValueAssociatedWithKey(fileContents, 'sdkHash')
          : null,
      address: new InternetAddress(
        _extractValueAssociatedWithKey(fileContents, 'address'),
      ),
      port: int.parse(_extractValueAssociatedWithKey(fileContents, 'port')),
    );
  }

  ResidentCompilerInfo._({
    required this.sdkHash,
    required this.port,
    required this.address,
  });
}

typedef CachedDillAndCompilerOptionsPaths = ({
  String cachedDillPath,
  String cachedCompilerOptionsPath,
});

/// Returns the absolute paths to the cached kernel file and the cached compiler
/// options file associated with [canonicalizedLibraryPath].
CachedDillAndCompilerOptionsPaths computeCachedDillAndCompilerOptionsPaths(
  String canonicalizedLibraryPath,
) {
  final String dirname = path.dirname(canonicalizedLibraryPath);
  final String basename = path.basename(canonicalizedLibraryPath);

  final String cachedKernelDirectoryPath = path.join(
    path.join(Directory.systemTemp.path, 'dart_resident_compiler_kernel_cache'),
    dirname.replaceAll(new RegExp(r':|\\|\/'), '_'),
  );

  try {
    new Directory(cachedKernelDirectoryPath).createSync(recursive: true);
  } catch (e) {
    throw new Exception(
      'Failed to create directory for storing cached kernel files',
    );
  }

  final String cachedDillPath = path.join(
    cachedKernelDirectoryPath,
    '$basename.dill',
  );
  final String cachedCompilerOptionsPath = path.join(
    cachedKernelDirectoryPath,
    '${basename}_options.json',
  );
  return (
    cachedDillPath: cachedDillPath,
    cachedCompilerOptionsPath: cachedCompilerOptionsPath,
  );
}

/// Sends a compilation [request] to the resident frontend compiler associated
/// with [serverInfoFile], and returns the compiler's JSON response.
///
/// Throws a [FileSystemException] if [serverInfoFile] cannot be accessed.
Future<Map<String, Object?>> sendAndReceiveResponse(
  String request,
  File serverInfoFile,
) async {
  Socket? client;
  Map<String, Object?> jsonResponse;
  final ResidentCompilerInfo residentCompilerInfo =
      ResidentCompilerInfo.fromFile(serverInfoFile);

  try {
    client = await Socket.connect(
      residentCompilerInfo.address,
      residentCompilerInfo.port,
    );
    client.write(request);
    final String data = new String.fromCharCodes(await client.first);
    jsonResponse = (jsonDecode(data) as Map<String, Object?>);
  } catch (e) {
    jsonResponse = <String, Object?>{
      'success': false,
      'errorMessage': e.toString(),
    };
  }
  client?.destroy();
  return jsonResponse;
}

/// Sends a 'replaceCachedDill' request with [replacementDillPath] as the lone
/// argument to the resident frontend compiler associated with [serverInfoFile],
/// and returns a boolean indicating whether or not replacement succeeded.
///
/// Throws a [FileSystemException] if [serverInfoFile] cannot be accessed.
Future<bool> invokeReplaceCachedDill({
  required String replacementDillPath,
  required File serverInfoFile,
}) async {
  final Map<String, Object?> response = await sendAndReceiveResponse(
    jsonEncode({
      'command': 'replaceCachedDill',
      'replacementDillPath': replacementDillPath,
    }),
    serverInfoFile,
  );
  return response['success'] == true;
}

/// The result of a successful compilation request sent to a resident
/// frontend compiler.
final class CompileResult {
  /// The absolute path to the kernel file produced by the compiler.
  final String outputDill;

  /// The number of errors produced by the compiler.
  final int errorCount;

  /// The output lines produced by the compiler, if any.
  final List<String> compilerOutputLines;

  CompileResult({
    required this.outputDill,
    required this.errorCount,
    this.compilerOutputLines = const [],
  });
}

/// The result of a successful expression compilation request sent to a
/// resident frontend compiler.
final class CompileExpressionResult {
  /// The base64 encoded kernel bytes produced by the compiler.
  final String kernelBytes;

  /// The number of errors produced by the compiler.
  final int errorCount;

  /// The output lines produced by the compiler, if any.
  final List<String> compilerOutputLines;

  CompileExpressionResult({
    required this.kernelBytes,
    required this.errorCount,
    this.compilerOutputLines = const [],
  });
}

/// The exception thrown when a compilation request to the resident frontend
/// compiler fails.
final class CompileException implements Exception {
  /// The error message from the compiler.
  final String message;

  CompileException(this.message);

  @override
  String toString() => 'CompileException: $message';
}

/// Sends a 'compile' request to the resident frontend compiler associated with
/// [serverInfoFile], and returns a [CompileResult] on success.
///
/// Throws a [CompileException] if compilation fails.
/// Throws a [FileSystemException] if [serverInfoFile] cannot be accessed.
Future<CompileResult> invokeCompile({
  required String executable,
  required String outputDill,
  required File serverInfoFile,
}) async {
  final Map<String, Object?> response = await sendAndReceiveResponse(
    jsonEncode({
      'command': 'compile',
      'executable': executable,
      'output-dill': outputDill,
      'useCachedCompilerOptionsAsBase': true,
    }),
    serverInfoFile,
  );

  if (response['success'] != true) {
    final String errorMessage = switch (response) {
      {'errorMessage': final String errorMessage} => errorMessage,
      {'compilerOutputLines': final List<Object?> lines} => lines.join('\n'),
      _ => 'Unknown error: $response',
    };
    throw new CompileException(errorMessage);
  }

  return new CompileResult(
    outputDill: response['output-dill'] as String,
    errorCount: response['errorCount'] as int,
    compilerOutputLines:
        (response['compilerOutputLines'] as List<Object?>?)?.cast<String>() ??
        const [],
  );
}

/// Sends a 'compileExpression' request to the resident frontend compiler
/// associated with [serverInfoFile], and returns a [CompileExpressionResult]
/// on success.
///
/// Throws a [CompileException] if compilation fails.
/// Throws a [FileSystemException] if [serverInfoFile] cannot be accessed.
Future<CompileExpressionResult> invokeCompileExpression({
  required String expression,
  required List<String> definitions,
  required List<String> definitionTypes,
  required List<String> typeDefinitions,
  required List<String> typeBounds,
  required List<String> typeDefaults,
  required String libraryUri,
  required String? klass,
  required String? method,
  required int offset,
  required String? scriptUri,
  required bool isStatic,
  required File serverInfoFile,
}) async {
  final Map<String, Object?> response = await sendAndReceiveResponse(
    jsonEncode({
      'command': 'compileExpression',
      'expression': expression,
      'definitions': definitions,
      'definitionTypes': definitionTypes,
      'typeDefinitions': typeDefinitions,
      'typeBounds': typeBounds,
      'typeDefaults': typeDefaults,
      'libraryUri': libraryUri,
      if (klass != null) 'class': klass,
      if (method != null) 'method': method,
      'offset': offset,
      if (scriptUri != null) 'scriptUri': scriptUri,
      'isStatic': isStatic,
      'useCachedCompilerOptionsAsBase': true,
    }),
    serverInfoFile,
  );

  if (response['success'] != true) {
    final String errorMessage = switch (response) {
      {'errorMessage': final String errorMessage} => errorMessage,
      {'compilerOutputLines': final List<Object?> lines} => lines.join('\n'),
      _ => 'Unknown error: $response',
    };
    throw new CompileException(errorMessage);
  }

  return new CompileExpressionResult(
    kernelBytes: response['kernelBytes'] as String,
    errorCount: response['errorCount'] as int,
    compilerOutputLines:
        (response['compilerOutputLines'] as List<Object?>?)?.cast<String>() ??
        const [],
  );
}
