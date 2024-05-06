// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:analysis_server_client/handler/connection_handler.dart';
import 'package:analysis_server_client/handler/notification_handler.dart';
import 'package:analysis_server_client/protocol.dart';
import 'package:analysis_server_client/server.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:path/path.dart' as pathos;
import 'package:test/test.dart';

void main() async {
  var provider = PhysicalResourceProvider.INSTANCE;
  var normalizedRoot = provider.pathContext.normalize(packageRoot);
  var packagePath =
      provider.pathContext.join(normalizedRoot, 'analysis_server_client');

  group('validate member sort order', () {
    late Server server;

    setUpAll(() async {
      server = await connectToServer(packagePath);
    });

    tearDownAll(() async {
      await server.stop();
    });

    // define tests
    for (var file in listPackageDartFiles(provider.getFolder(packagePath))) {
      var relativePath =
          provider.pathContext.relative(file.path, from: packagePath);

      test(relativePath, () async {
        var response = await server.send(EDIT_REQUEST_SORT_MEMBERS,
            EditSortMembersParams(file.path).toJson());
        var result = EditSortMembersResult.fromJson(
            ResponseDecoder(null), 'result', response);

        expect(result.edit.edits, isEmpty);
      });
    }
  });
}

/// Returns a path to the pkg directory.
String get packageRoot {
  var scriptPath = pathos.fromUri(Platform.script);
  var parts = pathos.split(scriptPath);
  var pkgIndex = parts.indexOf('pkg');
  return pathos.joinAll(parts.sublist(0, pkgIndex + 1)) + pathos.separator;
}

Future<Server> connectToServer(String packagePath) async {
  // start the server
  var server = Server();
  await server.start();

  // connect to the server
  var handler = StatusHandler(server);
  server.listenToOutput(notificationProcessor: handler.handleEvent);
  if (!await handler.serverConnected(timeLimit: const Duration(seconds: 15))) {
    stderr.writeln('server failed to start');
    exit(1);
  }

  // start analysis
  await server.send(SERVER_REQUEST_SET_SUBSCRIPTIONS,
      ServerSetSubscriptionsParams([ServerService.STATUS]).toJson());
  await server.send(ANALYSIS_REQUEST_SET_ANALYSIS_ROOTS,
      AnalysisSetAnalysisRootsParams([packagePath], const []).toJson());

  // wait for initial analysis to complete
  await handler.initialAnalysis.future;

  return server;
}

Iterable<File> listPackageDartFiles(Folder folder) sync* {
  // TODO(brianwilkerson) Fix the generator to sort the generated files and
  // remove these exclusions.
  const exclusions = <String>{
    'protocol_common.dart',
    'protocol_constants.dart',
    'protocol_generated.dart',
  };

  var children = folder.getChildren()
    ..sort((a, b) => a.shortName.compareTo(b.shortName));

  for (var child in children) {
    if (child is File && child.shortName.endsWith('.dart')) {
      if (!exclusions.contains(child.shortName)) {
        yield child;
      }
    } else if (child is Folder) {
      yield* listPackageDartFiles(child);
    }
  }
}

class StatusHandler with NotificationHandler, ConnectionHandler {
  @override
  final Server server;

  final Completer<bool> initialAnalysis = Completer();

  StatusHandler(this.server);

  @override
  void onServerStatus(ServerStatusParams params) {
    if (params.analysis != null) {
      if (!params.analysis!.isAnalyzing && !initialAnalysis.isCompleted) {
        initialAnalysis.complete(true);
      }
    }
  }
}
