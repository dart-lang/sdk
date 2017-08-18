// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/channel/channel.dart';
import 'package:analyzer_plugin/plugin/plugin.dart';
import 'package:analyzer_plugin/protocol/protocol.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/src/protocol/protocol_internal.dart';
import 'package:analyzer/src/generated/timestamped_data.dart';
import 'package:test/test.dart';

class MockAnalysisDriver extends AnalysisDriver {
  @override
  Set<String> addedFiles = new HashSet<String>();

  MockAnalysisDriver()
      : super(new AnalysisDriverScheduler(null), null, null, null, null, null,
            new SourceFactory([]), new AnalysisOptionsImpl());

  @override
  bool get hasFilesToAnalyze => false;

  @override
  set priorityFiles(List<String> priorityPaths) {}

  @override
  AnalysisDriverPriority get workPriority => AnalysisDriverPriority.nothing;

  @override
  void addFile(String path) {
    addedFiles.add(path);
  }

  @override
  void dispose() {}

  @override
  Future<Null> performWork() => new Future.value(null);
}

class MockChannel implements PluginCommunicationChannel {
  bool _closed = false;

  void Function(Request) _onRequest;
  Function _onError;
  void Function() _onDone;

  int idCounter = 0;

  Map<String, Completer<Response>> completers = <String, Completer<Response>>{};

  @override
  void close() {
    _closed = true;
  }

  @override
  void listen(void onRequest(Request request),
      {Function onError, void onDone()}) {
    _onRequest = onRequest;
    _onError = onError;
    _onDone = onDone;
  }

  void sendDone() {
    _onDone();
  }

  void sendError(Object exception, StackTrace stackTrace) {
    _onError(exception, stackTrace);
  }

  @override
  void sendNotification(Notification notification) {
    if (_closed) {
      throw new StateError('Sent a notification to a closed channel');
    }
    fail('Unexpected invocation of sendNotification');
  }

  Future<Response> sendRequest(RequestParams params) {
    String id = (idCounter++).toString();
    Request request = params.toRequest(id);
    Completer<Response> completer = new Completer<Response>();
    completers[request.id] = completer;
    _onRequest(request);
    return completer.future;
  }

  @override
  void sendResponse(Response response) {
    if (_closed) {
      throw new StateError('Sent a response to a closed channel');
    }
    Completer<Response> completer = completers.remove(response.id);
    completer.complete(response);
  }
}

/**
 * A concrete implementation of a server plugin that is suitable for testing.
 */
class MockServerPlugin extends ServerPlugin {
  MockServerPlugin(ResourceProvider resourceProvider) : super(resourceProvider);

  @override
  List<String> get fileGlobsToAnalyze => <String>['*.dart'];

  @override
  String get name => 'Test Plugin';

  @override
  String get version => '0.1.0';

  @override
  AnalysisDriverGeneric createAnalysisDriver(ContextRoot contextRoot) {
    return new MockAnalysisDriver();
  }

  @override
  void sendNotificationsForSubscriptions(
      Map<String, List<AnalysisService>> subscriptions) {}
}

class MockSource implements Source {
  @override
  TimestampedData<String> get contents => null;

  @override
  String get encoding => null;

  @override
  String get fullName => '/pkg/lib/test.dart';

  @override
  bool get isInSystemLibrary => false;

  @override
  Source get librarySource => this;

  @override
  int get modificationStamp => 0;

  @override
  String get shortName => 'test.dart';

  @override
  Source get source => this;

  @override
  Uri get uri => Uri.parse('package:test/test.dart');

  @override
  UriKind get uriKind => UriKind.PACKAGE_URI;

  @override
  bool exists() => true;
}
