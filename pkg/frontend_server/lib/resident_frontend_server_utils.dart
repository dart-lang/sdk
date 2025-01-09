// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert' show jsonDecode, jsonEncode;
import 'dart:io' show Directory, File, InternetAddress, Socket;

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
      new RegExp('$key:' r'(\S+)(\s|$)').allMatches(entries).first[1]!;

  static ResidentCompilerInfo fromFile(File file) {
    final String fileContents = file.readAsStringSync();

    return new ResidentCompilerInfo._(
      sdkHash: fileContents.contains('sdkHash:')
          ? _extractValueAssociatedWithKey(fileContents, 'sdkHash')
          : null,
      address: new InternetAddress(
        _extractValueAssociatedWithKey(
          fileContents,
          'address',
        ),
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
  String cachedCompilerOptionsPath
});

/// Returns the absolute paths to the cached kernel file and the cached compiler
/// options file associated with [canonicalizedLibraryPath].
CachedDillAndCompilerOptionsPaths computeCachedDillAndCompilerOptionsPaths(
  final String canonicalizedLibraryPath,
) {
  final String dirname = path.dirname(canonicalizedLibraryPath);
  final String basename = path.basename(canonicalizedLibraryPath);

  final String cachedKernelDirectoryPath = path.join(
    path.join(
      Directory.systemTemp.path,
      'dart_resident_compiler_kernel_cache',
    ),
    dirname.replaceAll(new RegExp(r':|\\|\/'), '_'),
  );

  try {
    new Directory(cachedKernelDirectoryPath).createSync(recursive: true);
  } catch (e) {
    throw new Exception(
      'Failed to create directory for storing cached kernel files',
    );
  }

  final String cachedDillPath =
      path.join(cachedKernelDirectoryPath, '$basename.dill');
  final String cachedCompilerOptionsPath =
      path.join(cachedKernelDirectoryPath, '${basename}_options.json');
  return (
    cachedDillPath: cachedDillPath,
    cachedCompilerOptionsPath: cachedCompilerOptionsPath
  );
}

/// Sends a compilation [request] to the resident frontend compiler associated
/// with [serverInfoFile], and returns the compiler's JSON response.
///
/// Throws a [FileSystemException] if [serverInfoFile] cannot be accessed.
Future<Map<String, dynamic>> sendAndReceiveResponse(
  String request,
  File serverInfoFile,
) async {
  Socket? client;
  Map<String, dynamic> jsonResponse;
  final ResidentCompilerInfo residentCompilerInfo =
      ResidentCompilerInfo.fromFile(serverInfoFile);

  try {
    client = await Socket.connect(
      residentCompilerInfo.address,
      residentCompilerInfo.port,
    );
    client.write(request);
    final String data = new String.fromCharCodes(await client.first);
    jsonResponse = jsonDecode(data);
  } catch (e) {
    jsonResponse = <String, dynamic>{
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
  final Map<String, dynamic> response = await sendAndReceiveResponse(
    jsonEncode({
      'command': 'replaceCachedDill',
      'replacementDillPath': replacementDillPath,
    }),
    serverInfoFile,
  );
  return response['success'];
}
