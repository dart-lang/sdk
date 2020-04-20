// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:isolate';

import 'package:analysis_server/src/server/crash_reporting_attachments.dart';
import 'package:analysis_server/src/server/detachable_filesystem_manager.dart';
import 'package:analysis_server/src/server/driver.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';

/// An object that can be used to start an analysis server. This class exists so
/// that clients can configure an analysis server before starting it.
///
/// Clients may not extend, implement or mix-in this class.
abstract class ServerStarter {
  /// Initialize a newly created starter to start up an analysis server.
  factory ServerStarter() = Driver;

  /// Set the new builder for attachments that should be included into crash
  /// reports.
  set crashReportingAttachmentsBuilder(
      CrashReportingAttachmentsBuilder builder);

  /// An optional manager to handle file systems which may not always be
  /// available.
  set detachableFileSystemManager(DetachableFileSystemManager manager);

  /// Set the instrumentation [service] that is to be used by the analysis
  /// server.
  set instrumentationService(InstrumentationService service);

  /// Use the given command-line [arguments] to start this server.
  void start(List<String> arguments, [SendPort sendPort]);
}
