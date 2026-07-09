// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:dwds/shared/batched_stream.dart';
import 'package:dwds/src/debugging/chrome_inspector.dart';
import 'package:dwds/src/debugging/debugger.dart';
import 'package:dwds/src/debugging/location.dart';
import 'package:dwds/src/debugging/modules.dart';
import 'package:dwds/src/services/expression_compiler.dart';
import 'package:dwds/src/services/expression_evaluator.dart';
import 'package:dwds/src/utilities/shared.dart';
import 'package:logging/logging.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

class EvaluateRequest {
  final String isolateId;
  final String? libraryUri;
  final String expression;
  final Map<String, String>? scope;
  final completer = Completer<RemoteObject>();

  EvaluateRequest(this.isolateId, this.libraryUri, this.expression, this.scope);
}

class BatchedExpressionEvaluator extends ExpressionEvaluator {
  final _logger = Logger('BatchedExpressionEvaluator');
  final ChromeAppInspector _inspector;
  final _requestController = BatchedStreamController<EvaluateRequest>(
    delay: 200,
  );
  bool _closed = false;

  BatchedExpressionEvaluator(
    String entrypoint,
    this._inspector,
    Debugger debugger,
    Locations locations,
    Modules modules,
    ExpressionCompiler compiler,
  ) : super(entrypoint, _inspector, debugger, locations, modules, compiler) {
    _requestController.stream.listen(_processRequest);
  }

  @override
  void close() {
    if (_closed) return;
    _logger.fine('Closed');
    _requestController.close();
    _closed = true;
  }

  @override
  Future<RemoteObject> evaluateExpression(
    String isolateId,
    String? libraryUri,
    String expression,
    Map<String, String>? scope,
  ) async {
    if (_closed) {
      return createError(
        EvaluationErrorKind.internal,
        'Batched expression evaluator closed',
      );
    }
    final request = EvaluateRequest(isolateId, libraryUri, expression, scope);
    _requestController.sink.add(request);
    return request.completer.future;
  }

  void _processRequest(List<EvaluateRequest> requests) {
    String? libraryUri;
    String? isolateId;
    Map<String, String>? scope;
    var currentRequests = <EvaluateRequest>[];

    for (final request in requests) {
      libraryUri ??= request.libraryUri;
      isolateId ??= request.isolateId;
      scope ??= request.scope;

      if (libraryUri != request.libraryUri ||
          isolateId != request.isolateId ||
          !const MapEquality<String, String>().equals(scope, request.scope)) {
        _logger.fine('New batch due to');
        if (libraryUri != request.libraryUri) {
          _logger.fine(' - library uri: $libraryUri != ${request.libraryUri}');
        }
        if (isolateId != request.isolateId) {
          _logger.fine(' - isolateId: $isolateId != ${request.isolateId}');
        }
        if (!const MapEquality<String, String>().equals(scope, request.scope)) {
          _logger.fine(' - scope: $scope != ${request.scope}');
        }

        safeUnawaited(_evaluateBatch(currentRequests));
        currentRequests = [];
        libraryUri = request.libraryUri;
        isolateId = request.isolateId;
        scope = request.scope;
      }
      currentRequests.add(request);
    }
    safeUnawaited(_evaluateBatch(currentRequests));
  }

  Future<void> _evaluateBatch(List<EvaluateRequest> requests) async {
    if (requests.isEmpty) return;

    final first = requests.first;
    if (requests.length == 1) {
      if (first.completer.isCompleted) return;
      return super
          .evaluateExpression(
            first.isolateId,
            first.libraryUri,
            first.expression,
            first.scope,
          )
          .then(requests.first.completer.complete);
    }

    final expressions = requests.map((r) => r.expression).join(', ');
    final batchedExpression = '[ $expressions ]';

    _logger.fine('Evaluating batch of expressions $batchedExpression');

    final list = await super.evaluateExpression(
      first.isolateId,
      first.libraryUri,
      batchedExpression,
      first.scope,
    );

    final listId = list.objectId;
    if (listId == null) {
      for (final request in requests) {
        safeUnawaited(_evaluateBatch([request]));
      }
      return;
    }

    for (var i = 0; i < requests.length; i++) {
      final request = requests[i];
      if (request.completer.isCompleted) continue;
      _logger.fine('Getting result out of a batch for ${request.expression}');

      safeUnawaited(
        _inspector
            .getProperties(listId, offset: i, count: 1, length: requests.length)
            .then((v) {
              final result = v.first.value!;
              _logger.fine(
                'Got result out of a batch for ${request.expression}: $result',
              );
              request.completer.complete(result);
            }),
        onError: request.completer.completeError,
      );
    }
  }
}
