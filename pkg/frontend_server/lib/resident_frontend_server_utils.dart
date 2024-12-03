// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert' show jsonDecode;
import 'dart:io' show Directory, File, InternetAddress, Platform, Socket;

import 'package:path/path.dart' as path;

final class ResidentCompilerInfo {
  final String? _sdkHash;
  final InternetAddress _address;
  final int _port;

  /// The SDK hash that kernel files compiled using the Resident Frontend
  /// Compiler associated with this object will be stamped with.
  String? get sdkHash => _sdkHash;

  /// The address that the Resident Frontend Compiler associated with this
  /// object is listening from.
  InternetAddress get address => _address;

  /// The port number that the Resident Frontend Compiler associated with this
  /// object is listening on.
  int get port => _port;

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
    required String? sdkHash,
    required int port,
    required InternetAddress address,
  })  : _sdkHash = sdkHash,
        _port = port,
        _address = address;
}

/// Returns the absolute path to the cached kernel file associated with
/// [canonicalizedLibraryPath].
String computeCachedDillPath(
  final String canonicalizedLibraryPath,
) {
  final int lastSeparatorPosInCanonicalizedLibraryPath =
      canonicalizedLibraryPath.lastIndexOf(Platform.pathSeparator);
  final String dirname = canonicalizedLibraryPath.substring(
    0,
    lastSeparatorPosInCanonicalizedLibraryPath,
  );
  final String basename = canonicalizedLibraryPath.substring(
    lastSeparatorPosInCanonicalizedLibraryPath + 1,
  );

  final String cachedKernelDirectoryPath = path.join(
    path.join(
      Directory.systemTemp.path,
      'dart_resident_compiler_kernel_cache',
    ),
    dirname.replaceAll('/', '_').replaceAll(r'\', '_'),
  );

  try {
    new Directory(cachedKernelDirectoryPath).createSync(recursive: true);
  } catch (e) {
    throw new Exception(
      'Failed to create directory for storing cached kernel files',
    );
  }

  return path.join(cachedKernelDirectoryPath, '$basename.dill');
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
