// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Constants used by the DTD-hosted file system service.
extension FileSystemServiceConstants on Never {
  /// Service name for the DTD-hosted file system service.
  static const serviceName = 'FileSystem';

  /// Service method name for the method that returns the IDE workspace roots.
  static const getIDEWorkspaceRoots = 'getIDEWorkspaceRoots';

  /// Service method name for the method that returns the project roots
  /// contained within the current set of IDE workspace roots.
  static const getProjectRoots = 'getProjectRoots';

  /// Service method name for the method that lists the contents of a directory.
  static const listDirectoryContents = 'listDirectoryContents';

  /// Service method name for the method that reads a file as a string.
  static const readFileAsString = 'readFileAsString';

  /// Service method name for the method that sets the IDE workspace roots.
  static const setIDEWorkspaceRoots = 'setIDEWorkspaceRoots';

  /// Service method name for the method that writes a file as a string.
  static const writeFileAsString = 'writeFileAsString';
}

/// The default value for the `depth` parameter in the
/// `DartToolingDaemon.getProjectRoots` API.
///
/// This represents the maximum depth of the directory tree that will be
/// searched for project roots. This is a performance optimization in case
/// the workspace roots being searched are large directories; for example, if
/// a user opened their home directory in their IDE.
const int defaultGetProjectRootsDepth = 4;

/// Constants used by the DTD-hosted unified analytics service.
///
/// This service is intentionally not exposed by package:dtd and should not be
/// used by arbitrary clients.
extension UnifiedAnalyticsServiceConstants on Never {
  /// Service name for the DTD-hosted unified analytics service.
  static const serviceName = 'UnifiedAnalytics';

  /// Service method name for the method that confirms that a unified analytics
  /// client showed the required consent message.
  static const clientShowedMessage = 'clientShowedMessage';

  /// Service method name for the method that returns the unified analytics
  /// consent message to prompt users with.
  static const getConsentMessage = 'getConsentMessage';

  /// Service method name for the method that sends an event to unified
  /// analytics.
  static const send = 'send';

  /// Service method name for the method that sets the enabled status of
  /// unified analytics telemetry.
  static const setTelemetry = 'setTelemetry';

  /// Service method name for the method that determines whether the unified
  /// analytics client should display the consent message.
  static const shouldShowMessage = 'shouldShowMessage';

  /// Service method name for the method that returns whether unified analytics
  /// telemetry is enabled.
  static const telemetryEnabled = 'telemetryEnabled';
}

/// Constants used as parameter names across various DTD APIs.
extension DtdParameters on Never {
  static const capabilities = 'capabilities';
  static const contents = 'contents';
  static const data = 'data';
  static const depth = 'depth';
  static const enable = 'enable';
  static const encoding = 'encoding';
  static const event = 'event';
  static const eventData = 'eventData';
  static const eventKind = 'eventKind';
  static const exposedUri = 'exposedUri';
  static const kind = 'kind';
  static const method = 'method';
  static const name = 'name';
  static const roots = 'roots';
  static const secret = 'secret';
  static const service = 'service';
  static const stream = 'stream';
  static const streamId = 'streamId';
  static const timestamp = 'timestamp';
  static const tool = 'tool';
  static const type = 'type';
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
  static const getVmServices = 'getVmServices';

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

/// Constants used by the core services provided by DTD.
extension CoreDtdServiceConstants on Never {
  /// Service method name for the method that returns all the currently
  /// registered services available on this DTD instance.
  static const getRegisteredServices = 'getRegisteredServices';

  /// Service method name for the method that posts an event to a stream.
  static const postEvent = 'postEvent';

  /// Service method name for the method that a DTD client can call to register
  /// a handler for a service method.
  static const registerService = 'registerService';

  /// The name of the stream for events related to new services/methods being
  /// added and removed.
  ///
  /// This stream is not part of the VM service protocol.
  static const servicesStreamId = 'Service';

  /// The kind of the event sent over the [servicesStreamId] stream when a new
  /// service method is registered.
  static const serviceRegisteredKind = 'ServiceRegistered';

  /// The kind of the event sent over the [servicesStreamId] stream when a
  /// service method is unregistered.
  static const serviceUnregisteredKind = 'ServiceUnregistered';

  /// Service method name for the method that cancels a DTD client's
  /// subscription to a stream.
  static const streamCancel = 'streamCancel';

  /// Service method name for the method that a DTD client can call to subscribe
  /// to a stream.
  static const streamListen = 'streamListen';

  /// Service method name that for the method that notifies any stream
  /// subscriptions that an event was posted to a stream.
  static const streamNotify = 'streamNotify';
}
