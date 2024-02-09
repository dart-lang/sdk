// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'generate_dart_common.dart';

class VmServiceInterfaceApi extends Api {
  static const _interfaceHeaderCode = r'''
// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This is a generated file. To regenerate, run `dart tool/generate.dart`.

/// A library providing an interface to implement the VM Service Protocol.
library;

// ignore_for_file: overridden_fields

import 'dart:async';

import 'package:vm_service/vm_service.dart';

import 'service_extension_registry.dart';

export 'service_extension_registry.dart' show ServiceExtensionRegistry;
''';

  @override
  void generate(DartGenerator gen) {
    gen.out(_interfaceHeaderCode);
    gen.writeln("const String vmServiceVersion = '$serviceVersion';");
    gen.writeln();
    gen.writeStatement('''
/// A class representation of the Dart VM Service Protocol.
abstract interface class VmServiceInterface {
  /// Returns the stream for a given stream id.
  ///
  /// This is not a part of the spec, but is needed for both the client and
  /// server to get access to the real event streams.
  Stream<Event> onEvent(String streamId);

  /// Handler for calling extra service extensions.
  Future<Response> callServiceExtension(String method, {String? isolateId, Map<String, dynamic>? args});
''');
    for (var m in methods) {
      m.generateDefinition(gen);
      gen.write(';');
    }
    gen.write('}');
    gen.writeln();

    // The server class, takes a VmServiceInterface and delegates to it
    // automatically.
    gen.write('''
class _PendingServiceRequest {
  Future<Map<String, Object?>> get future => _completer.future;
  final _completer = Completer<Map<String, Object?>>();

  final dynamic originalId;

  _PendingServiceRequest(this.originalId);

  void complete(Map<String, Object?> response) {
    response['id'] = originalId;
    _completer.complete(response);
  }
}

/// A Dart VM Service Protocol connection that delegates requests to a
/// [VmServiceInterface] implementation.
///
/// One of these should be created for each client, but they should generally
/// share the same [VmServiceInterface] and [ServiceExtensionRegistry]
/// instances.
class VmServerConnection {
  final Stream<Map<String, Object>> _requestStream;
  final StreamSink<Map<String, Object?>> _responseSink;
  final ServiceExtensionRegistry _serviceExtensionRegistry;
  final VmServiceInterface _serviceImplementation;
  /// Used to create unique ids when acting as a proxy between clients.
  int _nextServiceRequestId = 0;

  /// Manages streams for `streamListen` and `streamCancel` requests.
  final _streamSubscriptions = <String, StreamSubscription>{};

  /// Completes when [_requestStream] is done.
  Future<void> get done => _doneCompleter.future;
  final _doneCompleter = Completer<void>();

  /// Pending service extension requests to this client by id.
  final _pendingServiceExtensionRequests = <dynamic, _PendingServiceRequest>{};

  VmServerConnection(this._requestStream, this._responseSink,
      this._serviceExtensionRegistry, this._serviceImplementation) {
    _requestStream.listen(_delegateRequest, onDone: _doneCompleter.complete);
    done.then((_) {
      for (var sub in _streamSubscriptions.values) {
        sub.cancel();
      }
    });
  }

  /// Invoked when the current client has registered some extension, and
  /// another client sends an RPC request for that extension.
  ///
  /// We don't attempt to do any serialization or deserialization of the
  /// request or response in this case
  Future<Map<String, Object?>> _forwardServiceExtensionRequest(
      Map<String, Object?> request) {
    final originalId = request['id'];
    request = Map<String, Object?>.of(request);
    // Modify the request ID to ensure we don't have conflicts between
    // multiple clients ids.
    final newId = '\${_nextServiceRequestId++}:\$originalId';
    request['id'] = newId;
    var pendingRequest = _PendingServiceRequest(originalId);
    _pendingServiceExtensionRequests[newId] = pendingRequest;
    _responseSink.add(request);
    return pendingRequest.future;
  }

  void _delegateRequest(Map<String, Object?> request) async {
    try {
      var id = request['id'];
      // Check if this is actually a response to a pending request.
      if (_pendingServiceExtensionRequests.containsKey(id)) {
        final pending = _pendingServiceExtensionRequests[id]!;
        pending.complete(Map<String, Object?>.of(request));
        return;
      }
      final method = request['method'] as String?;
      if (method == null) {
        throw RPCError(null, RPCErrorKind.kInvalidRequest.code,
            'Invalid Request', request);
      }
      final params = request['params'] as Map<String, dynamic>?;
      late Response response;

      switch(method) {
        case 'registerService':
          $registerServiceImpl
          break;
''');
    for (var m in methods) {
      if (m.name != 'registerService') {
        gen.writeln("case '${m.name}':");
        if (m.name == 'streamListen') {
          gen.writeln(streamListenCaseImpl);
        } else if (m.name == 'streamCancel') {
          gen.writeln(streamCancelCaseImpl);
        } else {
          bool firstParam = true;
          String nullCheck() {
            final result = firstParam ? '!' : '';
            if (firstParam) {
              firstParam = false;
            }
            return result;
          }

          if (m.deprecated) {
            gen.writeln('// ignore: deprecated_member_use_from_same_package');
          }
          gen.write('response = await _serviceImplementation.${m.name}(');
          // Positional args
          m.args.where((arg) => !arg.optional).forEach((MethodArg arg) {
            if (arg.type.isArray) {
              gen.write(
                  "${arg.type.listCreationRef}.from(params${nullCheck()}['${arg.name}'] ?? []), ");
            } else {
              gen.write("params${nullCheck()}['${arg.name}'], ");
            }
          });
          // Optional named args
          var namedArgs = m.args.where((arg) => arg.optional);
          if (namedArgs.isNotEmpty) {
            for (var arg in namedArgs) {
              if (arg.name == 'scope') {
                gen.writeln(
                    "${arg.name}: params${nullCheck()}['${arg.name}']?.cast<String, String>(), ");
              } else {
                gen.writeln(
                    "${arg.name}: params${nullCheck()}['${arg.name}'], ");
              }
            }
          }
          gen.writeln(');');
        }
        gen.writeln('break;');
      }
    }
    // Handle service extensions
    gen.writeln('default:');
    gen.writeln('''
        final registeredClient = _serviceExtensionRegistry.clientFor(method);
        if (registeredClient != null) {
          // Check for any client which has registered this extension, if we
          // have one then delegate the request to that client.
          _responseSink.add(
              await registeredClient._forwardServiceExtensionRequest(request));
          // Bail out early in this case, we are just acting as a proxy and
          // never get a `Response` instance.
          return;
        } else if (method.startsWith('ext.')) {
          // Remaining methods with `ext.` are assumed to be registered via
          // dart:developer, which the service implementation handles.
          final args = params == null ? null : Map<String, dynamic>.of(params);
          final isolateId = args?.remove('isolateId');
          response = await _serviceImplementation.callServiceExtension(method,
              isolateId: isolateId, args: args);
        } else {
          throw RPCError(method, RPCErrorKind.kMethodNotFound.code,
              'Method not found', request);
        }
''');
    // Terminate the switch
    gen.writeln('}');

    // Generate the json success response
    gen.write("""_responseSink.add({
  'jsonrpc': '2.0',
  'id': id,
  'result': response.toJson(),
});
""");

    // Close the try block, handle errors
    gen.write(r'''
      } on SentinelException catch (e) {
        _responseSink.add({
          'jsonrpc': '2.0',
          'id': request['id'],
          'result': e.sentinel.toJson(),
        });
      } catch (e, st) {
        final error = e is RPCError
            ? e.toMap()
            : {
                'code': RPCErrorKind.kInternalError.code,
                'message': '${request['method']}: $e',
                'data': {'details': '$st'},
              };
        _responseSink.add({
          'jsonrpc': '2.0',
          'id': request['id'],
          'error': error,
        });
      }
''');

    // terminate the _delegateRequest method
    gen.write('}');
    gen.writeln();

    gen.write('}');
    gen.writeln();
  }

  void setDefaultValue(String typeName, String fieldName, String defaultValue) {
    types
        .firstWhere((t) => t!.name == typeName)!
        .fields
        .firstWhere((f) => f.name == fieldName)
        .defaultValue = defaultValue;
  }
}
