// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:vm_service/vm_service.dart';

import 'clients.dart';
import 'dart_runtime_service.dart';
import 'rpc_exceptions.dart';
import 'utils.dart';

/// A helper class which handles `evaluate` and `evaluateInFrame` calls by
/// potentially forwarding compilation requests to an external compilation
/// service like Flutter Tools.
abstract base class ExpressionEvaluator {
  ExpressionEvaluator({required this.clients});

  @protected
  final logger = Logger('$ExpressionEvaluator');

  /// The set of [Client]s connected to the service.
  final UnmodifiableClientNamedLookup clients;

  /// The [evaluate] RPC is used to evaluate an expression in the context of
  /// some target.
  ///
  /// `targetId` may refer to a [Library], [Class], or [Instance].
  ///
  /// If `targetId` is a temporary ID which has expired, then an expired
  /// [Sentinel] is returned.
  ///
  /// If `targetId` refers to an object which has been collected, then a
  /// collected [Sentinel] is returned.
  ///
  /// If `isolateId` refers to an isolate which has exited, then a collected
  /// [Sentinel] is returned.
  ///
  /// If `scope` is provided, it should be a map from identifiers to object
  /// IDs. These bindings will be added to the scope in which the expression
  /// is evaluated, which is a child scope of the class or library for
  /// instance/class or library targets respectively. This means bindings
  /// provided in scope may shadow instance members, class members and top-level
  /// members.
  ///
  /// If `disableBreakpoints` is provided and set to true, any breakpoints hit
  /// as a result of this evaluation are ignored. Defaults to false if not
  /// provided.
  ///
  /// If `idZoneId` is provided, temporary IDs for [InstanceRef]s and
  /// [Instance]s in the RPC response will be allocated in the specified ID
  /// zone. If `idZoneId` is omitted, ID allocations will be performed in the
  /// default ID zone for the isolate.
  ///
  /// If the expression fails to parse and compile, then
  /// [RpcException.expressionCompilationError] will be thrown.
  ///
  /// If an error occurs while evaluating the expression, an [ErrorRef] will be
  /// returned.
  ///
  /// If the expression is evaluated successfully, an [InstanceRef] will be
  /// returned.
  Future<RpcResponse> evaluate(json_rpc.Parameters parameters);

  /// The [evaluateInFrame] RPC is used to evaluate an expression in the context
  /// of a particular stack frame.
  ///
  /// `frameIndex` is the index of the desired [Frame], with an index of 0
  /// indicating the top (most recent) frame.
  ///
  /// If `isolateId` refers to an isolate which has exited, then a collected
  /// [Sentinel] is returned.
  ///
  /// If `scope` is provided, it should be a map from identifiers to object
  /// IDs. These bindings will be added to the scope in which the expression
  /// is evaluated, which is a child scope of the class or library for
  /// instance/class or library targets respectively. This means bindings
  /// provided in scope may shadow instance members, class members and top-level
  /// members.
  ///
  /// If `disableBreakpoints` is provided and set to true, any breakpoints hit
  /// as a result of this evaluation are ignored. Defaults to false if not
  /// provided.
  ///
  /// If `idZoneId` is provided, temporary IDs for [InstanceRef]s and
  /// [Instance]s in the RPC response will be allocated in the specified ID
  /// zone. If `idZoneId` is omitted, ID allocations will be performed in the
  /// default ID zone for the isolate.
  ///
  /// If the expression fails to parse and compile, then
  /// [RpcException.expressionCompilationError] will be thrown.
  ///
  /// If an error occurs while evaluating the expression, an [ErrorRef] will be
  /// returned.
  ///
  /// If the expression is evaluated successfully, an [InstanceRef] will be
  /// returned.
  Future<RpcResponse> evaluateInFrame(json_rpc.Parameters parameters);
}
