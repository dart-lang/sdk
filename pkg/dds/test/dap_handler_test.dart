// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:dap/dap.dart';
import 'package:dds/dds.dart';
import 'package:dds/src/dap/constants.dart';
import 'package:dds_service_extensions/dap.dart';
import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';
import 'package:vm_service/vm_service_io.dart';

import 'common/test_helper.dart';

void main() {
  Process? process;
  DartDevelopmentService? dds;
  late VmService service;

  Future<void> createProcess({bool pauseOnStart = true}) async {
    process = await spawnDartProcess(
      'dap_over_dds_script.dart',
      disableServiceAuthCodes: true,
      pauseOnStart: pauseOnStart,
    );
  }

  tearDown(() async {
    await dds?.shutdown();
    process?.kill();
    process = null;
  });

  var nextSeq = 1;
  Future<DapResponse> sendDapRequest(String request, Object? arguments) async {
    final result = await service.sendDapRequest(
      jsonEncode(
        Request(
          command: request,
          seq: nextSeq++,
          arguments: arguments,
        ),
      ),
    );

    expect(result.dapResponse, isNotNull);
    expect(result.dapResponse.type, 'response');
    expect(result.dapResponse.message, isNull);
    expect(result.dapResponse.success, true);
    expect(result.dapResponse.command, request);

    return result;
  }

  Future<String?> instanceToString(String isolateId, String instanceId) async {
    final result = await service.invoke(isolateId, instanceId, 'toString', []);
    return result is InstanceRef ? result.valueAsString : null;
  }

  Future<String> variableToString(int variablesReference) async {
    // Because variables requests are for _child_ variables, a converted
    // Instance->Variable will return an initial container that has a single
    // 'value' field, which contains the string representation of the variable
    // as its value, and a further 'variablesReference' that can be used to
    // fetch child variables.
    final variablesResult = await sendDapRequest(
      'variables',
      VariablesArguments(variablesReference: variablesReference),
    );
    final variablesBody = VariablesResponseBody.fromMap(
      variablesResult.dapResponse.body as Map<String, Object?>,
    );
    expect(variablesBody.variables, hasLength(1));
    final variable = variablesBody.variables.single;
    expect(variable.name, 'value');
    expect(variable.variablesReference, isPositive);
    return variable.value;
  }

  test('DDS responds to DAP message', () async {
    await createProcess();
    dds = await DartDevelopmentService.startDartDevelopmentService(
      remoteVmServiceUri,
    );
    expect(dds!.isRunning, true);
    final serviceUri = dds!.wsUri!;
    service = await vmServiceConnectUri(serviceUri.toString());

    final breakpointArguments = SetBreakpointsArguments(
      breakpoints: [
        SourceBreakpoint(line: 20),
        SourceBreakpoint(line: 30),
      ],
      source: Source(
        name: 'main.dart',
        path: '/file/to/main.dart',
      ),
    );

    final result = await sendDapRequest('setBreakpoints', breakpointArguments);
    final response = SetBreakpointsResponseBody.fromMap(
        result.dapResponse.body as Map<String, Object?>);
    expect(response.breakpoints, hasLength(2));
    expect(response.breakpoints[0].verified, isFalse);
    expect(response.breakpoints[1].verified, isFalse);
  });

  test('DAP can map between variableReferences and InstanceRefs', () async {
    await createProcess(pauseOnStart: false);
    dds = await DartDevelopmentService.startDartDevelopmentService(
      remoteVmServiceUri,
    );
    service = await vmServiceConnectUri(dds!.wsUri!.toString());

    final isolate = (await service.getVM()).isolates!.first;
    final isolateId = isolate.id!;

    // Get the variable for 'myInstance'.
    final originalInstanceRef = (await service.evaluateInFrame(
        isolateId, 0, 'myInstance')) as InstanceRef;
    final originalInstanceId = originalInstanceRef.id!;

    // Ask DAP to make a variableReference for it.
    final createVariableResult = await sendDapRequest(
      Command.createVariableForInstance,
      {
        Parameters.isolateId: isolateId,
        Parameters.instanceId: originalInstanceId,
      },
    );
    final createVariablesBody =
        createVariableResult.dapResponse.body as Map<String, Object?>;
    final variablesReference =
        createVariablesBody[Parameters.variablesReference] as int;

    // And now ask DAP to convert it back to an instance ID.
    final getInstanceResult = await sendDapRequest(
      Command.getVariablesInstanceId,
      {
        Parameters.variablesReference: variablesReference,
      },
    );
    final getInstanceRefBody =
        getInstanceResult.dapResponse.body as Map<String, Object?>;
    final mappedInstanceId =
        getInstanceRefBody[Parameters.instanceId] as String;

    // Now verify that the string value of these are all the same.
    expect(await instanceToString(isolateId, originalInstanceId), 'MyClass');
    expect(await variableToString(variablesReference), 'MyClass');
    expect(await instanceToString(isolateId, mappedInstanceId), 'MyClass');
  });
}
