// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:vm_service/vm_service.dart' as vm;

/// Extension methods for invoking private VM service RPCs on [vm.VmService].
extension DdsPrivateVmServiceExtensions on vm.VmService {
  /// Invokes the private `_buildExpressionEvaluationScope` RPC on [isolateId].
  Future<Map<String, Object?>> buildExpressionEvaluationScope({
    required String isolateId,
    int? frameIndex,
    Map<String, String>? scope,
    String? targetId,
  }) async {
    final response = await callMethod(
      '_buildExpressionEvaluationScope',
      args: <String, Object?>{
        'frameIndex': ?frameIndex,
        'isolateId': isolateId,
        'scope': ?scope,
        'targetId': ?targetId,
      },
    );
    return (response.json ?? response.toJson()).cast<String, Object?>();
  }

  /// Invokes the private `_evaluateCompiledExpression` RPC on [isolateId].
  Future<Map<String, Object?>> evaluateCompiledExpression({
    required String isolateId,
    required String kernelBytes,
    bool? disableBreakpoints,
    int? frameIndex,
    String? idZoneId,
    Map<String, String>? scope,
    String? targetId,
  }) async {
    final response = await callMethod(
      '_evaluateCompiledExpression',
      args: <String, Object?>{
        'disableBreakpoints': ?disableBreakpoints,
        'frameIndex': ?frameIndex,
        'idZoneId': ?idZoneId,
        'isolateId': isolateId,
        'kernelBytes': kernelBytes,
        'scope': ?scope,
        'targetId': ?targetId,
      },
    );
    return (response.json ?? response.toJson()).cast<String, Object?>();
  }
}
