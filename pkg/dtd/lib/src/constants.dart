// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Service name for the DTD-hosted file system service.
const String kFileSystemServiceName = 'FileSystem';

/// The default value for the `depth` parameter in the
/// `DartToolingDaemon.getProjectRoots` API.
///
/// This represents the maximum depth of the directory tree that will be
/// searched for project roots. This is a performance optimization in case
/// the workspace roots being searched are large directories; for example, if
/// a user opened their home directory in their IDE.
const int defaultGetProjectRootsDepth = 4;

/// Service name for the DTD-hosted unified analytics service.
const String kUnifiedAnalyticsServiceName = 'UnifiedAnalytics';

/// Constants used as parameter names across various DTD APIs.
extension EventParameters on Never {
  static const eventData = 'eventData';
  static const eventKind = 'eventKind';
  static const exposedUri = 'exposedUri';
  static const name = 'name';
  static const secret = 'secret';
  static const streamId = 'streamId';
  static const timestamp = 'timestamp';
  static const uri = 'uri';
}

/// Constants used by the DTD-hosted connected app service.
extension ConnectedAppServiceConstants on Never {
  /// Service name for the DTD-hosted connected app service.
  ///
  /// This is the same name used for the stream id that the connected app
  /// service sends VM service registered and unregistered events over.
  static const serviceName = 'ConnectedApp';

  /// Service method name for the method that returns a list of VM service URIs
  /// for running applications in the context of a DTD instance.
  static const getVmServiceUris = 'getVmServiceUris';

  /// Service method name for the method that registers a new VM service
  /// connection.
  static const registerVmService = 'registerVmService';

  /// Service method name for the method that unregisters a VM service
  /// connection.
  static const unregisterVmService = 'unregisterVmService';

  /// Event kind for the event that is sent over the [serviceName] stream when a
  /// new VM service is registered.
  static const vmServiceRegistered = 'VmServiceRegistered';

  /// Event kind for the event that is sent over the [serviceName] stream when a
  /// VM service is unregistered, which happens automatically when the VM
  /// service shuts down.
  static const vmServiceUnregistered = 'VmServiceUnregistered';
}
