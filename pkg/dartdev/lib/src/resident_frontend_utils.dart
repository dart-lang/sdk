// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io' show File, FileSystemException, InternetAddress, Socket;

import 'package:args/args.dart';
import 'package:path/path.dart' as p;

import 'analytics.dart';
import 'resident_frontend_constants.dart';

/// The Resident Frontend Compiler's shutdown command.
final residentServerShutdownCommand = jsonEncode(
  <String, Object>{
    commandString: shutdownString,
  },
);

// TODO: The current implementation gives 1 server to a user and stores the info
// file in the .dart directory in the user's home. This adds some fragility to
// the --resident command as it expects this environment variable to exist.
//
// If/when the resident frontend compiler is used without requiring the
// --resident flag, this reliance on the environment variable should be
// addressed.

/// The path to the directory that stores the Resident Frontend Compiler's
/// information file, which stores the server's address and port number.
///
/// File has the `form: address:__ port:__`.
File? get defaultResidentServerInfoFile {
  var dartConfigDir = getDartStorageDirectory();
  if (dartConfigDir == null) return null;

  return File(p.join(dartConfigDir.path, 'dartdev_compilation_server_info'));
}

final String packageConfigName = p.join('.dart_tool', 'package_config.json');

/// Get the port number the Resident Frontend Compiler is listening on.
int getPortNumber(String serverInfo) =>
    int.parse(serverInfo.substring(serverInfo.lastIndexOf(':') + 1));

/// Get the address that the Resident Frontend Compiler is listening from.
InternetAddress getAddress(String serverInfo) => InternetAddress(
    serverInfo.substring(serverInfo.indexOf(':') + 1, serverInfo.indexOf(' ')));

/// Removes the [serverInfoFile].
void cleanupResidentServerInfo(File serverInfoFile) {
  if (serverInfoFile.existsSync()) {
    try {
      serverInfoFile.deleteSync();
    } catch (_) {}
  }
}

// TODO: when frontend_server is migrated to null safe Dart, everything
// below this comment can be removed and imported from resident_frontend_server

/// Sends a compilation [request] to the Resident Frontend Compiler, returning
/// it's json response.
///
/// Throws a [FileSystemException] if there is no server running.
Future<Map<String, dynamic>> sendAndReceiveResponse(
  String request,
  File serverInfoFile,
) async {
  Socket? client;
  Map<String, dynamic> jsonResponse;
  final contents = serverInfoFile.readAsStringSync();
  try {
    client =
        await Socket.connect(getAddress(contents), getPortNumber(contents));
    client.write(request);
    final data = String.fromCharCodes(await client.first);
    jsonResponse = jsonDecode(data);
  } catch (e) {
    jsonResponse = <String, dynamic>{
      responseSuccessString: false,
      responseErrorString: e.toString(),
    };
  }
  client?.destroy();
  return jsonResponse;
}

/// Used to create compile requests for the run CLI command.
/// Returns a JSON string that the resident compiler will be able to
/// interpret.
String createCompileJitJson({
  required String executable,
  required String outputDill,
  required ArgResults args,
  String? packages,
  bool verbose = false,
}) {
  return jsonEncode(
    <String, Object?>{
      commandString: compileString,
      sourceString: executable,
      outputString: outputDill,
      if (args.wasParsed(defineOption)) defineOption: args[defineOption],
      if (args.options.contains(enableAssertsOption) &&
          args.wasParsed(enableAssertsOption))
        enableAssertsOption: true,
      if (args.wasParsed(enableExperimentOption))
        enableExperimentOption: args[enableExperimentOption]
            .map((e) => '--enable-experiment=$e')
            .toList(),
      if (packages != null) packageString: packages,
      if (args.wasParsed(verbosityOption))
        verbosityOption: args[verbosityOption],
    },
  );
}
