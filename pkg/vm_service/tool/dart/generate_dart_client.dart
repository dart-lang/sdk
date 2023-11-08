// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'generate_dart_common.dart';

class VmServiceApi extends Api {
  static const _clientHeaderCode = r'''
// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This is a generated file. To regenerate, run `dart tool/generate.dart`.

/// A library to access the VM Service API.
///
/// The main entry-point for this library is the [VmService] class.
library;

// ignore_for_file: overridden_fields

import 'dart:async';
import 'dart:convert' show base64, jsonDecode, jsonEncode, utf8;
import 'dart:typed_data';

export 'snapshot_graph.dart' show HeapSnapshotClass,
                                  HeapSnapshotExternalProperty,
                                  HeapSnapshotField,
                                  HeapSnapshotGraph,
                                  HeapSnapshotObject,
                                  HeapSnapshotObjectLengthData,
                                  HeapSnapshotObjectNoData,
                                  HeapSnapshotObjectNullData;
''';

  static const _implCode = r'''

  /// Call an arbitrary service protocol method. This allows clients to call
  /// methods not explicitly exposed by this library.
  Future<Response> callMethod(String method, {
    String? isolateId,
    Map<String, dynamic>? args
  }) {
    return callServiceExtension(method, isolateId: isolateId, args: args);
  }

  /// Invoke a specific service protocol extension method.
  ///
  /// See https://api.dart.dev/stable/dart-developer/dart-developer-library.html.
  Future<Response> callServiceExtension(String method, {
    String? isolateId,
    Map<String, dynamic>? args
  }) {
    if (args == null && isolateId == null) {
      return _call(method);
    } else if (args == null) {
      return _call(method, {'isolateId': isolateId!});
    } else {
      args = Map.from(args);
      if (isolateId != null) {
        args['isolateId'] = isolateId;
      }
      return _call(method, args);
    }
  }

  Future<void> dispose() async {
    await _streamSub.cancel();
    _outstandingRequests.forEach((id, request) {
      request._completer.completeError(RPCError(
        request.method,
        RPCErrorKind.kServerError.code,
        'Service connection disposed',
      ));
    });
    _outstandingRequests.clear();
    if (_disposeHandler != null) {
      await _disposeHandler!();
    }
    if (!_onDoneCompleter.isCompleted) {
      _onDoneCompleter.complete();
    }
  }

  /// When overridden, this method wraps [future] with logic.
  ///
  /// [wrapFuture] is called by [_call], which is the method that each VM
  /// service endpoint eventually goes through.
  ///
  /// This method should be overridden if subclasses of [VmService] need to do
  /// anything special upon calling the VM service, like tracking futures or
  /// logging requests.
  Future<T> wrapFuture<T>(String name, Future<T> future) {
    return future;
  }

  Future<T> _call<T>(String method, [Map args = const {}]) {
    return wrapFuture<T>(
      method,
      () {
        final request = _OutstandingRequest<T>(method);
        _outstandingRequests[request.id] = request;
        Map m = {
          'jsonrpc': '2.0',
          'id': request.id,
          'method': method,
          'params': args,
        };
        String message = jsonEncode(m);
        _onSend.add(message);
        _writeMessage(message);
        return request.future;
      }(),
    );
  }

  /// Register a service for invocation.
  void registerServiceCallback(String service, ServiceCallback cb) {
    if (_services.containsKey(service)) {
      throw Exception('Service \'$service\' already registered');
    }
    _services[service] = cb;
  }

  void _processMessage(dynamic message) {
    // Expect a String, an int[], or a ByteData.
    if (message is String) {
      _processMessageStr(message);
    } else if (message is List<int>) {
      final list = Uint8List.fromList(message);
      _processMessageByteData(ByteData.view(list.buffer));
    } else if (message is ByteData) {
      _processMessageByteData(message);
    } else {
      _log.warning('unknown message type: ${message.runtimeType}');
    }
  }

  void _processMessageByteData(ByteData bytes) {
    final int metaOffset = 4;
    final int dataOffset = bytes.getUint32(0, Endian.little);
    final metaLength = dataOffset - metaOffset;
    final dataLength = bytes.lengthInBytes - dataOffset;
    final meta = utf8.decode(Uint8List.view(
        bytes.buffer, bytes.offsetInBytes + metaOffset, metaLength));
    final data = ByteData.view(
        bytes.buffer, bytes.offsetInBytes + dataOffset, dataLength);
    final map = jsonDecode(meta)!;
    if (map['method'] == 'streamNotify') {
      final streamId = map['params']['streamId'];
      final event = map['params']['event'];
      event['data'] = data;
      _getEventController(streamId)
          .add(createServiceObject(event, const ['Event'])! as Event);
    }
  }

  void _processMessageStr(String message) {
    try {
      _onReceive.add(message);
      final json = jsonDecode(message)!;
      if (json.containsKey('method')) {
        if (json.containsKey('id')) {
          _processRequest(json);
        } else {
          _processNotification(json);
        }
      } else if (json.containsKey('id') &&
          (json.containsKey('result') || json.containsKey('error'))) {
        _processResponse(json);
      }
      else {
      _log.severe('unknown message type: $message');
      }
    } catch (e, s) {
      _log.severe('unable to decode message: $message, $e\n$s');
      return;
    }
  }

  void _processResponse(Map<String, dynamic> json) {
    final request = _outstandingRequests.remove(json['id']);
    if (request == null) {
      _log.severe('unmatched request response: ${jsonEncode(json)}');
    } else if (json['error'] != null) {
      request.completeError(RPCError.parse(request.method, json['error']));
    } else {
      final result = json['result'] as Map<String, dynamic>;
      final type = result['type'];
      if (type == 'Sentinel') {
        request.completeError(SentinelException.parse(request.method, result));
      } else if (_typeFactories[type] == null) {
        request.complete(Response.parse(result));
      } else {
        final returnTypes = _methodReturnTypes[request.method] ?? <String>[];
        request.complete(createServiceObject(result, returnTypes));
      }
    }
  }

  Future _processRequest(Map<String, dynamic> json) async {
    final result = await _routeRequest(json['method'], json['params'] ?? <String, dynamic>{});
    result['id'] = json['id'];
    result['jsonrpc'] = '2.0';
    String message = jsonEncode(result);
    _onSend.add(message);
    _writeMessage(message);
  }

  Future _processNotification(Map<String, dynamic> json) async {
    final method = json['method'];
    final params = json['params'] ?? <String, dynamic>{};
    if (method == 'streamNotify') {
      final streamId = params['streamId'];
      _getEventController(streamId).add(createServiceObject(params['event'], const ['Event'])! as Event);
    } else {
      await _routeRequest(method, params);
    }
  }

  Future<Map> _routeRequest(String method, Map<String, dynamic> params) async {
    final service = _services[method];
    if (service == null) {
      final error = RPCError(method, RPCErrorKind.kMethodNotFound.code,
          'method not found \'$method\'');
      return {'error': error.toMap()};
    }

    try {
      return await service(params);
    } catch (e, st) {
      RPCError error = RPCError.withDetails(
        method,
        RPCErrorKind.kServerError.code,
        '$e',
        details: '$st',
      );
      return {'error': error.toMap()};
    }
  }
''';

  static const _rpcError = r'''

typedef DisposeHandler = Future Function();

// These error codes must be kept in sync with those in vm/json_stream.h and
// vmservice.dart.
enum RPCErrorKind {
  /// Application specific error code.
  kServerError(code: -32000, message: 'Application error'),

  /// The JSON sent is not a valid Request object.
  kInvalidRequest(code: -32600, message: 'Invalid request object'),

  /// The method does not exist or is not available.
  kMethodNotFound(code: -32601, message: 'Method not found'),

  /// Invalid method parameter(s), such as a mismatched type.
  kInvalidParams(code: -32602, message: 'Invalid method parameters'),

  /// Internal JSON-RPC error.
  kInternalError(code: -32603, message: 'Internal JSON-RPC error'),

  /// The requested feature is disabled.
  kFeatureDisabled(code: 100, message: 'Feature is disabled'),

  /// The VM must be paused when performing this operation.
  kVmMustBePaused(code: 101, message: 'The VM must be paused'),

  /// Unable to add a breakpoint at the specified line or function.
  kCannotAddBreakpoint(code: 102,
    message: 'Unable to add breakpoint at specified line or function'),

  /// The stream has already been subscribed to.
  kStreamAlreadySubscribed(code: 103, message: 'Stream already subscribed'),

  /// The stream has not been subscribed to.
  kStreamNotSubscribed(code: 104, message: 'Stream not subscribed'),

  /// Isolate must first be runnable.
  kIsolateMustBeRunnable(code: 105, message: 'Isolate must be runnable'),

  /// Isolate must first be paused.
  kIsolateMustBePaused(code: 106, message: 'Isolate must be paused'),

  /// The isolate could not be resumed.
  kIsolateCannotBeResumed(code: 107, message: 'The isolate could not be resumed'),

  /// The isolate is currently reloading.
  kIsolateIsReloading(code: 108, message: 'The isolate is currently reloading'),

  /// The isolate could not be reloaded due to an unhandled exception.
  kIsolateCannotReload(code: 109, message: 'The isolate could not be reloaded'),

  /// The isolate reload resulted in no changes being applied.
  kIsolateNoReloadChangesApplied(code: 110, message: 'No reload changes applied'),

  /// The service has already been registered.
  kServiceAlreadyRegistered(code: 111, message: 'Service already registered'),

  /// The service no longer exists.
  kServiceDisappeared(code: 112, message: 'Service has disappeared'),

  /// There was an error in the expression compiler.
  kExpressionCompilationError(
      code: 113, message: 'Expression compilation error'),

  /// The timeline related request could not be completed due to the current configuration.
  kInvalidTimelineRequest(code: 114,
      message: 'Invalid timeline request for the current timeline configuration'),

  /// The custom stream does not exist.
  kCustomStreamDoesNotExist(code: 130, message: 'Custom stream does not exist'),

  /// The core stream is not allowed.
  kCoreStreamNotAllowed(code: 131, message: 'Core streams are not allowed');

  const RPCErrorKind({required this.code, required this.message});

  final int code;

  final String message;

  static final _codeToErrorMap =
      RPCErrorKind.values.fold(<int, RPCErrorKind>{}, (map, error) {
    map[error.code] = error;
    return map;
  });

  static RPCErrorKind? fromCode(int code) {
    return _codeToErrorMap[code];
  }
}

class RPCError implements Exception {
  static RPCError parse(String callingMethod, dynamic json) {
    return RPCError(callingMethod, json['code'], json['message'], json['data']);
  }

  final String? callingMethod;
  final int code;
  final String message;
  final Map? data;

  RPCError(this.callingMethod, this.code, [message, this.data])
      : message =
            message ?? RPCErrorKind.fromCode(code)?.message ?? 'Unknown error';

  RPCError.withDetails(this.callingMethod, this.code, this.message,
      {Object? details})
      : data = details == null ? null : <String, dynamic>{} {
    if (details != null) {
      data!['details'] = details;
    }
  }

  String? get details => data == null ? null : data!['details'];

  /// Return a map representation of this error suitable for conversion to
  /// json.
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'code': code,
      'message': message,
    };
    if (data != null) {
      map['data'] = data;
    }
    return map;
  }

  @override
  String toString() {
    if (details == null) {
      return '$callingMethod: ($code) $message';
    } else {
      return '$callingMethod: ($code) $message\n$details';
    }
  }
}

/// Thrown when an RPC response is a [Sentinel].
class SentinelException implements Exception {
  final String callingMethod;
  final Sentinel sentinel;

  SentinelException.parse(this.callingMethod, Map<String, dynamic> data) :
    sentinel = Sentinel.parse(data)!;

  @override
  String toString() => '$sentinel from $callingMethod()';
}

/// An `ExtensionData` is an arbitrary map that can have any contents.
class ExtensionData {
  static ExtensionData? parse(Map<String, dynamic>? json) =>
      json == null ? null : ExtensionData._fromJson(json);

  final Map<String, dynamic> data;

  ExtensionData() : data = <String, dynamic>{};

  ExtensionData._fromJson(this.data);

  @override
  String toString() => '[ExtensionData $data]';
}

/// A logging handler you can pass to a [VmService] instance in order to get
/// notifications of non-fatal service protocol warnings and errors.
abstract class Log {
  /// Log a warning level message.
  void warning(String message);

  /// Log an error level message.
  void severe(String message);
}

class _NullLog implements Log {
  @override
  void warning(String message) {}
  @override
  void severe(String message) {}
}
''';

  @override
  void generate(DartGenerator gen) {
    gen.out(_clientHeaderCode);
    gen.writeln("const String vmServiceVersion = '$serviceVersion';");
    gen.writeln();
    gen.writeln('''
/// @optional
const String optional = 'optional';

/// Decode a string in Base64 encoding into the equivalent non-encoded string.
/// This is useful for handling the results of the Stdout or Stderr events.
String decodeBase64(String str) => utf8.decode(base64.decode(str));

// Returns true if a response is the Dart `null` instance.
bool _isNullInstance(Map json) => ((json['type'] == '@Instance') &&
                                  (json['kind'] == 'Null'));

Object? createServiceObject(dynamic json, List<String> expectedTypes) {
  if (json == null) return null;

  if (json is List) {
    return json.map((e) => createServiceObject(e, expectedTypes)).toList();
  } else if (json is Map<String, dynamic>) {
    String? type = json['type'];

    // Not a Response type.
    if (type == null) {
      // If there's only one expected type, we'll just use that type.
      if (expectedTypes.length == 1) {
        type = expectedTypes.first;
      } else {
        return Response.parse(json);
      }
    } else if (_isNullInstance(json) && (!expectedTypes.contains('InstanceRef'))) {
      // Replace null instances with null when we don't expect an instance to
      // be returned.
      return null;
    }
    final typeFactory = _typeFactories[type];
    if (typeFactory == null) {
      return null;
    } else {
      return typeFactory(json);
    }
  } else {
    // Handle simple types.
    return json;
  }
}

dynamic _createSpecificObject(
    dynamic json, dynamic Function(Map<String, dynamic> map) creator) {
  if (json == null) return null;

  if (json is List) {
    return json.map((e) => creator(e)).toList();
  } else if (json is Map) {
    return creator({
      for (String key in json.keys)
        key: json[key],
    });
  } else {
    // Handle simple types.
    return json;
  }
}

void _setIfNotNull(Map<String, dynamic> json, String key, Object? value) {
  if (value == null) return;
  json[key] = value;
}

Future<T> extensionCallHelper<T>(VmService service, String method, Map<String, dynamic> args) {
  return service._call(method, args);
}

typedef ServiceCallback = Future<Map<String, dynamic>> Function(
    Map<String, dynamic> params);

void addTypeFactory(String name, Function factory) {
  if (_typeFactories.containsKey(name)) {
    throw StateError('Factory already registered for \$name');
  }
  _typeFactories[name] = factory;
}

''');
    gen.writeln();
    gen.writeln('final _typeFactories = <String, Function>{');
    for (var type in types) {
      gen.writeln("'${type!.rawName}': ${type.name}.parse,");
    }
    gen.writeln('};');
    gen.writeln();

    gen.writeln('final _methodReturnTypes = <String, List<String>>{');
    for (var method in methods) {
      String returnTypes = typeRefListToString(method.returnType.types);
      gen.writeln("'${method.name}' : $returnTypes,");
    }
    gen.writeln('};');
    gen.writeln();
    gen.write('''
class _OutstandingRequest<T> {
  _OutstandingRequest(this.method);
  static int _idCounter = 0;
  final id = '\${_idCounter++}';
  final String method;
  final _stackTrace = StackTrace.current;
  final _completer = Completer<T>();

  Future<T> get future => _completer.future;

  void complete(T value) => _completer.complete(value);
  void completeError(Object error) =>
      _completer.completeError(error, _stackTrace);
}
''');
    gen.writeln();
    gen.writeln('''
typedef VmServiceFactory<T extends VmService> = T Function({
  required Stream<dynamic> /*String|List<int>*/ inStream,
  required void Function(String message) writeMessage,
  Log? log,
  DisposeHandler? disposeHandler,
  Future? streamClosed,
  String? wsUri,
});
''');

    // The client side service implementation.
    gen.writeStatement('class VmService {');
    gen.writeStatement('late final StreamSubscription _streamSub;');
    gen.writeStatement('late final Function _writeMessage;');
    gen.writeStatement(
        'final _outstandingRequests = <String, _OutstandingRequest>{};');
    gen.writeStatement('final _services = <String, ServiceCallback>{};');
    gen.writeStatement('late final Log _log;');
    gen.write('''

  /// The web socket URI pointing to the target VM service instance.
  final String? wsUri;

  Stream<String> get onSend => _onSend.stream;
  final _onSend = StreamController<String>.broadcast(sync: true);

  Stream<String> get onReceive => _onReceive.stream;
  final _onReceive = StreamController<String>.broadcast(sync: true);

  Future<void> get onDone => _onDoneCompleter.future;
  final _onDoneCompleter = Completer<void>();

  final _eventControllers = <String, StreamController<Event>>{};

  StreamController<Event> _getEventController(String eventName) {
    StreamController<Event>? controller = _eventControllers[eventName];
    if (controller == null) {
      controller = StreamController.broadcast();
      _eventControllers[eventName] = controller;
    }
    return controller;
  }

  late final DisposeHandler? _disposeHandler;

  VmService(
    Stream<dynamic> /*String|List<int>*/ inStream,
    void Function(String message) writeMessage, {
    Log? log,
    DisposeHandler? disposeHandler,
    Future? streamClosed,
    this.wsUri,
  }) {
    _streamSub = inStream.listen(_processMessage,
        onDone: () => _onDoneCompleter.complete());
    _writeMessage = writeMessage;
    _log = log ?? _NullLog();
    _disposeHandler = disposeHandler;
    streamClosed?.then((_) {
      if (!_onDoneCompleter.isCompleted) {
        _onDoneCompleter.complete();
      }
    });
  }

  static VmService defaultFactory({
    required Stream<dynamic> /*String|List<int>*/ inStream,
    required void Function(String message) writeMessage,
    Log? log,
    DisposeHandler? disposeHandler,
    Future? streamClosed,
    String? wsUri,
  }) {
    return VmService(
      inStream,
      writeMessage,
      log: log,
      disposeHandler: disposeHandler,
      streamClosed: streamClosed,
      wsUri: wsUri,
    );
  }

  Stream<Event> onEvent(String streamId) => _getEventController(streamId).stream;
''');

    // streamCategories
    for (var s in streamCategories) {
      s.generate(gen);
    }

    gen.writeln();
    for (var m in methods) {
      m.generate(gen);
    }
    gen.out(_implCode);
    gen.writeStatement('}');
    gen.writeln();
    gen.out(_rpcError);
    gen.writeln();
    gen.writeln('// enums');
    for (var e in enums) {
      if (e.name == 'EventKind') {
        _generateEventStream(gen);
      }
      e.generate(gen);
    }
    gen.writeln();
    gen.writeln('// types');
    types.where((t) => !t!.skip).forEach((t) => t!.generate(gen));
  }

  void setDefaultValue(String typeName, String fieldName, String defaultValue) {
    types
        .firstWhere((t) => t!.name == typeName)!
        .fields
        .firstWhere((f) => f.name == fieldName)
        .defaultValue = defaultValue;
  }

  void _generateEventStream(DartGenerator gen) {
    gen.writeln();
    gen.writeDocs('An enum of available event streams.');
    gen.writeln('abstract class EventStreams {');
    gen.writeln();

    for (var c in streamCategories) {
      gen.writeln("static const String k${c.name} = '${c.name}';");
    }

    gen.writeln('}');
  }
}
