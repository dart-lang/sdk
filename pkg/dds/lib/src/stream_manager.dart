// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:vm_service/vm_service.dart';

import 'client.dart';
import 'dds_impl.dart';
import 'logging_repository.dart';
import 'rpc_error_codes.dart';
import 'utils/mutex.dart';

class StreamManager {
  StreamManager(this.dds);
  String loggingString = '';

  /// Send `streamNotify` notifications to clients subscribed to `streamId`.
  ///
  /// If `data` is of type `Uint8List`, the notification is assumed to be a
  /// binary event and is forwarded directly over the subscriber's websocket.
  /// Otherwise, the event is sent via the JSON RPC client.
  ///
  /// If `excludedClient` is provided, the notification will be sent to all
  /// clients subscribed to `streamId` except for `excludedClient`.
  void streamNotify(
    String streamId,
    data, {
    DartDevelopmentServiceClient? excludedClient,
  }) {
    var listeners = streamListeners[streamId];
    listeners ??= customStreamListeners[streamId];
    if (listeners != null) {
      final isBinaryData = data is Uint8List;
      for (final listener in listeners) {
        if (listener == excludedClient) {
          continue;
        }
        if (isBinaryData) {
          listener.connection.sink.add(data);
        } else {
          Map<String, dynamic> processed = data;
          if (streamId == kProfilerStream) {
            processed = _processProfilerEvents(listener, data);
          }
          try {
            listener.sendNotification('streamNotify', processed);
          } on json_rpc.RpcException catch (e) {
            debugMessage(
              "YES caught on the streamNotify ${e.code} ${e.message}",
            );
          }
        }
      }
    }
  }

  void debugMessage(String message) {
    developer.postEvent('DAKE_DEBUG', {'message': message});
    // var listeners = customStreamListeners['Dake_Debug'];
    // if (listeners != null) {
    //   for (final listener in listeners) {
    //     Map<String, dynamic> processed = {
    //       'streamId': 'Dake_Debug',
    //       'event': {
    //         'type': 'Event',
    //         'kind': 'Logging',
    //         'timestamp': DateTime.now().millisecondsSinceEpoch,
    //         'service': 'service',
    //         'extensionData': message
    //       }
    //     };
    //     listener.sendNotification('streamNotify', processed);
    //   }
    // }
  }

  static Map<String, dynamic> _processProfilerEvents(
    DartDevelopmentServiceClient client,
    Map<String, dynamic> data,
  ) {
    final event = Event.parse(data['event'])!;
    if (event.kind != EventKind.kCpuSamples) {
      return data;
    }
    final cpuSamplesEvent = event.cpuSamples!;
    cpuSamplesEvent.samples = cpuSamplesEvent.samples!
        .where(
          (e) => client.profilerUserTagFilters.contains(e.userTag),
        )
        .toList();
    cpuSamplesEvent.sampleCount = cpuSamplesEvent.samples!.length;
    final updated = Map<String, dynamic>.from(data);
    updated['event']['cpuSamples'] = cpuSamplesEvent.toJson();
    return updated;
  }

  static Map<String, dynamic> _buildStreamRegisteredEvent(
          String namespace, String service, String alias) =>
      {
        'streamId': kServiceStream,
        'event': {
          'type': 'Event',
          'kind': 'ServiceRegistered',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'service': service,
          'method': namespace + '.' + service,
          'alias': alias,
        }
      };

  void sendServiceRegisteredEvent(
    DartDevelopmentServiceClient client,
    String service,
    String alias,
  ) {
    final namespace = dds.getNamespace(client)!;
    streamNotify(
      kServiceStream,
      _buildStreamRegisteredEvent(namespace, service, alias),
      excludedClient: client,
    );
  }

  void _sendServiceUnregisteredEvents(
    DartDevelopmentServiceClient client,
  ) {
    final namespace = dds.getNamespace(client);
    for (final service in client.services.keys) {
      streamNotify(
        kServiceStream,
        {
          'streamId': kServiceStream,
          'event': {
            'type': 'Event',
            'kind': 'ServiceUnregistered',
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'service': service,
            'method': namespace! + '.' + service,
          },
        },
        excludedClient: client,
      );
    }
  }

  /// Start listening for `streamNotify` events from the VM service and forward
  /// them to the clients which have subscribed to the stream.
  Future<void> listen() async {
    // The IsolateManager requires information from both the Debug and
    // Isolate streams, so they must always be subscribed to by DDS.
    for (final stream in ddsCoreStreams) {
      try {
        await streamListen(null, stream);
        if (loggingRepositoryStreams.contains(stream)) {
          loggingRepositories[stream] = LoggingRepository();
        }
      } on json_rpc.RpcException {
        // Stdout and Stderr streams may not exist.
      }
    }
    if (dds.cachedUserTags.isNotEmpty) {
      await streamListen(null, EventStreams.kProfiler);
    }
    dds.vmServiceClient.registerMethod(
      'streamNotify',
      (json_rpc.Parameters parameters) async {
        final streamId = parameters['streamId'].asString;
        final event =
            Event.parse(parameters['event'].asMap.cast<String, dynamic>())!;
        final destinationStreamId =
            event.extensionData?.data['__destinationStream']!;

        if (destinationStreamId != 'Extension' && destinationStreamId != null) {
          if (streamListeners.containsKey(destinationStreamId)) {
            // __destinationStream is only used by developer.postEvent.
            // We don't want to allow posting to streamListeners since those are
            // subscribed to by the VM, so return early here.
            return;
          }
          final values = parameters.value;

          values['streamId'] = destinationStreamId;
          (values['event']['extensionData'] as Map<String, dynamic>)
              .remove('__destinationStream');

          streamNotify(destinationStreamId, values);
          return;
        }
        // Forward events from the streams IsolateManager subscribes to.
        if (isolateManagerStreams.contains(streamId)) {
          dds.isolateManager.handleIsolateEvent(event);
        }
        // Keep a history of messages to send to clients when they first
        // subscribe to a stream with an event history.
        if (loggingRepositories.containsKey(streamId)) {
          loggingRepositories[streamId]!.add(
            parameters.asMap.cast<String, dynamic>(),
          );
        }
        // If the event contains an isolate, forward the event to the
        // corresponding isolate to be handled.
        if (event.isolate != null) {
          dds.isolateManager.routeEventToIsolate(event);
        }
        streamNotify(streamId, parameters.value);
      },
    );
  }

  /// Subscribes `client` to a stream.
  ///
  /// If `client` is the first client to listen to `stream`, DDS will send a
  /// `streamListen` request for `stream` to the VM service.
  Future<void> streamListen(
    DartDevelopmentServiceClient? client,
    String stream, {
    bool? includePrivates,
  }) async {
    // Weakly guard stream listening as it's safe to perform multiple listens
    // on a stream concurrently. However, cancelling streams while listening
    // to them concurrently can put things in a bad state. Use weak guarding to
    // improve latency of stream subscription.
    await _streamSubscriptionMutex.runGuardedWeak(
      () async {
        assert(stream.isNotEmpty);
        bool streamNewlySubscribed = false;
        bool isNewCustomStream = false;

        if (!streamListeners.containsKey(stream) &&
            !customStreamListeners.containsKey(stream)) {
          // Initialize the list of clients for the new stream before we do
          // anything else to ensure multiple clients registering for the same
          // stream in quick succession doesn't result in multiple streamListen
          // requests being sent to the VM service.
          streamNewlySubscribed = true;
          if ((stream == kDebugStream && client == null) ||
              stream != kDebugStream) {
            // This will return an RPC exception if the stream doesn't exist. This
            // will throw and the exception will be forwarded to the client.
            try {
              final result =
                  await dds.vmServiceClient.sendRequest('streamListen', {
                'streamId': stream,
                if (includePrivates != null)
                  '_includePrivateMembers': includePrivates,
              });
              assert(result['type'] == 'Success');
            } on json_rpc.RpcException catch (e) {
              if (e.code == RpcErrorCodes.kInvalidParams) {
                isNewCustomStream = true;
              } else {
                rethrow;
              }
            }
            if (isNewCustomStream) {
              customStreamListeners[stream] = <DartDevelopmentServiceClient>[];
            } else {
              streamListeners[stream] = <DartDevelopmentServiceClient>[];
            }
          }
        }
        if (streamListeners[stream]?.contains(client) == true ||
            customStreamListeners[stream]?.contains(client) == true) {
          throw kStreamAlreadySubscribedException;
        } else if (!streamNewlySubscribed && includePrivates != null) {
          try {
            await dds.vmServiceClient.sendRequest(
                '_setStreamIncludePrivateMembers',
                {'streamId': stream, 'includePrivateMembers': includePrivates});
          } on json_rpc.RpcException catch (e) {
            // This private RPC might not be present. If it's not, we're communicating with an older
            // VM that doesn't support filtering private members, so they will always be included in
            // responses. Handle the method not found exception so the streamListen call doesn't
            // fail for older VMs.
            if (e.code != RpcErrorCodes.kMethodNotFound) {
              rethrow;
            }
          }
        }
        if (client != null) {
          if (isNewCustomStream || customStreamListeners[stream] != null) {
            customStreamListeners[stream]?.add(client);
          } else {
            streamListeners[stream]!.add(client);
          }
          if (loggingRepositories.containsKey(stream)) {
            loggingRepositories[stream]!.sendHistoricalLogs(client);
          } else if (stream == kServiceStream) {
            // Send all previously registered service extensions when a client
            // subscribes to the Service stream.
            for (final c in dds.clientManager.clients) {
              if (c == client) {
                continue;
              }
              final namespace = dds.getNamespace(c);
              for (final service in c.services.keys) {
                client.sendNotification(
                  'streamNotify',
                  _buildStreamRegisteredEvent(
                    namespace!,
                    service,
                    c.services[service]!,
                  ),
                );
              }
            }
          }
        }
      },
    );
  }

  List<Map<String, dynamic>>? getStreamHistory(String stream) {
    if (!loggingRepositories.containsKey(stream)) {
      return null;
    }
    return [
      for (final event in loggingRepositories[stream]!()) event['event'],
    ];
  }

  /// Unsubscribes `client` from a stream.
  ///
  /// If `client` is the last client to unsubscribe from `stream`, DDS will
  /// send a `streamCancel` request for `stream` to the VM service.
  Future<void> streamCancel(
    DartDevelopmentServiceClient? client,
    String stream, {
    bool cancelCoreStream = false,
  }) async {
    await _streamSubscriptionMutex.runGuarded(
      () async {
        assert(stream.isNotEmpty);
        var listeners = streamListeners[stream];
        listeners ??= customStreamListeners[stream];
        if (listeners == null ||
            client != null && !listeners.contains(client)) {
          throw kStreamNotSubscribedException;
        }
        listeners.remove(client);
        // Don't cancel streams DDS needs to function.
        if (listeners.isEmpty &&
            (!ddsCoreStreams.contains(stream) || cancelCoreStream)) {
          streamListeners.remove(stream);
          // Ensure the VM service hasn't shutdown.
          if (dds.vmServiceClient.isClosed) {
            return;
          }
          final result = await dds.vmServiceClient.sendRequest('streamCancel', {
            'streamId': stream,
          });
          assert(result['type'] == 'Success');
        } else {
          streamListeners[stream] = listeners;
        }
      },
    );
  }

  Future<void> updateUserTagSubscriptions(
      [List<String> userTags = const []]) async {
    await _profilerUserTagSubscriptionsMutex.runGuarded(() async {
      _profilerUserTagSubscriptions.addAll(userTags);
      for (final subscribedTag in _profilerUserTagSubscriptions.toList()) {
        bool hasSubscriber = false;
        for (final c in dds.clientManager.clients) {
          if (c.profilerUserTagFilters.contains(subscribedTag)) {
            hasSubscriber = true;
            break;
          }
        }
        if (!hasSubscriber) {
          _profilerUserTagSubscriptions.remove(subscribedTag);
        }
      }
      await dds.vmServiceClient.sendRequest('streamCpuSamplesWithUserTag', {
        'userTags': _profilerUserTagSubscriptions.toList(),
      });
    });
  }

  /// Cleanup stream subscriptions for `client` when it has disconnected.
  void clientDisconnect(DartDevelopmentServiceClient client) {
    for (final streamId in streamListeners.keys.toList()) {
      streamCancel(client, streamId).catchError(
        (_) => null,
        // Ignore 'stream not subscribed' errors and StateErrors which arise
        // when DDS is shutting down.
        test: (e) => (e is json_rpc.RpcException) || (e is StateError),
      );
    }
    updateUserTagSubscriptions().catchError(
      (_) => null,
      test: (e) => (e is json_rpc.RpcException) || (e is StateError),
    );

    // Notify other service clients of service extensions that are being
    // unregistered.
    _sendServiceUnregisteredEvents(client);
  }

  static const kServiceStream = 'Service';

  static final kStreamAlreadySubscribedException =
      RpcErrorCodes.buildRpcException(
    RpcErrorCodes.kStreamAlreadySubscribed,
  );

  static final kStreamNotSubscribedException = RpcErrorCodes.buildRpcException(
    RpcErrorCodes.kStreamNotSubscribed,
  );
  json_rpc.RpcException kDANTESTEXCEPTION(String message, Object? data) =>
      json_rpc.RpcException(
        66666,
        message,
        data: data,
      );

  static const kDebugStream = 'Debug';
  static const kExtensionStream = 'Extension';
  static const kIsolateStream = 'Isolate';
  static const kLoggingStream = 'Logging';
  static const kProfilerStream = 'Profiler';
  static const kStderrStream = 'Stderr';
  static const kStdoutStream = 'Stdout';

  static Map<String, LoggingRepository> loggingRepositories = {};

  // Never cancel the Debug or Isolate stream as `IsolateManager` requires
  // them for isolate state notifications.
  static const isolateManagerStreams = <String>{
    kDebugStream,
    kIsolateStream,
  };

  // Never cancel the logging and extension event streams as `LoggingRepository`
  // requires them keep history.
  static const loggingRepositoryStreams = <String>{
    kExtensionStream,
    kLoggingStream,
    kStderrStream,
    kStdoutStream,
  };

  // Never cancel the profiler stream as `CpuSampleRepository` requires
  // `UserTagChanged` events to enable/disable sample caching.
  static const cpuSampleRepositoryStreams = <String>{
    kProfilerStream,
  };

  // The set of streams that DDS requires to function.
  static final ddsCoreStreams = <String>{
    ...isolateManagerStreams,
    ...loggingRepositoryStreams,
  };

  static final protectedStreams = <String>{
    'VM',
    'Isolate',
    'Debug',
    'GC',
    '_Echo',
    'HeapSnapshot',
    'Logging',
    'Extension',
    'Timeline',
    'Profiler',
  };
  static final allStandardStreams = <String>{
    ...isolateManagerStreams,
    ...loggingRepositoryStreams,
    ...cpuSampleRepositoryStreams,
  };
  final DartDevelopmentServiceImpl dds;
  final streamListeners = <String, List<DartDevelopmentServiceClient>>{};
  final customStreamListeners = <String, List<DartDevelopmentServiceClient>>{};
  final _profilerUserTagSubscriptions = <String>{};
  final _streamSubscriptionMutex = Mutex();
  final _profilerUserTagSubscriptionsMutex = Mutex();
}
