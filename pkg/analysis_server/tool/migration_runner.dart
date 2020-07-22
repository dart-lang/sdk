// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This executable provides the ability to run the migration tool in process
/// on a single package.  It should be invoked with two command-line arguments:
/// a path to a configuration file and the name of a package to migrate.
///
/// The configuration file format is a JSON map, with the following keys:
/// - `sdk_root`: path to the SDK source code on the user's machine (this is the
///   directory that contains `pkg`, `third_party`, `tests`, etc.
/// - `output_root`: if present, path to the directory on the user's machine
///   where output HTML files should go.  A subdirectory will be created for
///   each package that is migrated.
/// - `external_packages`: a map (name => path) of additional non-SDK packages
///   that may need to be migrated.
/// - `port`: if present, the port where a server should be spawned serving HTML
///   pages.
library migration_runner;

import 'dart:convert';
import 'dart:io' as io;

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/server/crash_reporting_attachments.dart';
import 'package:analysis_server/src/utilities/mocks.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:cli_util/cli_util.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

Future<void> main(List<String> args) async {
  if (args.length != 2) {
    throw StateError(
        'Exactly two arguments are required: the path to a JSON configuration '
        'file, and the name of the package to migrate');
  }
  var testInfoJsonPath = args[0];
  var testInfoJson = json.decode(io.File(testInfoJsonPath).readAsStringSync());
  var packageName = args[1];
  var testInfo = TestInfo(testInfoJson);
  var packageRoot = testInfo.packageRoot(packageName);
  var port = testInfo.port;
  print('Preparing to migrate');
  var migrationTest = MigrationTest();
  migrationTest.setUp();
  print('Migrating');
  await migrationTest.run(packageRoot, port);
  if (port == null) {
    print('Done');
    io.exit(0);
  } else {
    print('Done.  Please point your browser to localhost:$port/\$filePath');
  }
}

class MigrationBase {
  ResourceProvider resourceProvider = PhysicalResourceProvider.INSTANCE;
  MockServerChannel serverChannel;
  AnalysisServer server;

  AnalysisServer createAnalysisServer() {
    //
    // Create server
    //
    var options = AnalysisServerOptions();
    var sdkPath = getSdkPath();
    return AnalysisServer(
        serverChannel,
        resourceProvider,
        options,
        DartSdkManager(sdkPath),
        CrashReportingAttachmentsBuilder.empty,
        InstrumentationService.NULL_SERVICE);
  }

  void processNotification(Notification notification) {
    if (notification.event == SERVER_NOTIFICATION_ERROR) {
      fail('${notification.toJson()}');
    }
  }

  Future<Response> sendAnalysisSetAnalysisRoots(List<String> directories) {
    var request =
        AnalysisSetAnalysisRootsParams(directories, []).toRequest('0');
    return waitResponse(request);
  }

  Future<Response> sendEditDartfix(List<String> directories, int port) {
    var request = EditDartfixParams(directories,
            includedFixes: ['non-nullable'], port: port)
        .toRequest('1');
    return waitResponse(request);
  }

  void setUp() {
    serverChannel = MockServerChannel();
    server = createAnalysisServer();
    server.pluginManager = TestPluginManager();
    // listen for notifications
    var notificationStream = serverChannel.notificationController.stream;
    notificationStream.listen((Notification notification) {
      processNotification(notification);
    });
  }

  void tearDown() {
    server.done();
    server = null;
    serverChannel = null;
  }

  /// Returns a [Future] that completes when the server's analysis is complete.
  Future waitForTasksFinished() {
    return server.onAnalysisComplete;
  }

  /// Completes with a successful [Response] for the given [request].
  Future<Response> waitResponse(Request request,
      {bool throwOnError = true}) async {
    return serverChannel.sendRequest(request, throwOnError: throwOnError);
  }
}

class MigrationTest extends MigrationBase {
  Future<void> run(String packageRoot, int port) async {
    var packageRoots = <String>[packageRoot];
    await sendAnalysisSetAnalysisRoots(packageRoots);
    await sendEditDartfix(packageRoots, port);
  }
}

class TestInfo {
  static const Set<String> thirdPartyPackages = {
    'charcode',
    'collection',
    'logging',
    'meta',
    'pedantic',
    'typed_data'
  };

  static const Set<String> builtInPackages = {'meta', 'path'};

  final Map<String, Object> testInfoJson;

  TestInfo(this.testInfoJson);

  Map<String, String> get externalPackages =>
      ((testInfoJson['external_packages'] ?? {}) as Map).cast<String, String>();

  String get outputRoot => testInfoJson['output_root'];

  int get port => testInfoJson['port'];

  String get sdkRoot => testInfoJson['sdk_root'];

  String packageRoot(String packageName) {
    if (thirdPartyPackages.contains(packageName)) {
      return path.join(sdkRoot, 'third_party', 'pkg', packageName);
    } else if (builtInPackages.contains(packageName)) {
      return path.join(sdkRoot, 'pkg', packageName);
    } else if (externalPackages.containsKey(packageName)) {
      return externalPackages[packageName];
    } else {
      throw StateError('Unrecognized package $packageName');
    }
  }
}
