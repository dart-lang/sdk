// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:observatory/service_io.dart';
import 'package:test/test.dart';

import 'test_helper.dart';

Future getFlagValue(VM vm, String flagName) async {
  var result = await vm.invokeRpcNoUpgrade('getFlagList', {});
  expect(result['type'], equals('FlagList'));
  final flags = result['flags'];
  for (final flag in flags) {
    if (flag['name'] == flagName) {
      return flag['valueAsString'];
    }
  }
}

var tests = <VMTest>[
  (VM vm) async {
    var result = await vm.invokeRpcNoUpgrade('getFlagList', {});
    expect(result['type'], equals('FlagList'));
    // TODO(turnidge): Make this test a bit beefier.
  },

  // Modify a flag which does not exist.
  (VM vm) async {
    var params = {
      'name': 'does_not_really_exist',
      'value': 'true',
    };
    var result = await vm.invokeRpcNoUpgrade('setFlag', params);
    expect(result['type'], equals('Error'));
    expect(result['message'], equals('Cannot set flag: flag not found'));
  },

  // Modify a flag with the wrong value type.
  (VM vm) async {
    var params = {
      'name': 'pause_isolates_on_start',
      'value': 'not-a-boolean',
    };
    var result = await vm.invokeRpcNoUpgrade('setFlag', params);
    expect(result['type'], equals('Error'));
    expect(result['message'], equals('Cannot set flag: invalid value'));
  },

  // Modify a flag with the right value type.
  (VM vm) async {
    var params = {
      'name': 'pause_isolates_on_start',
      'value': 'false',
    };
    var result = await vm.invokeRpcNoUpgrade('setFlag', params);
    expect(result['type'], equals('Success'));
  },

  // Modify a flag which cannot be set at runtime.
  (VM vm) async {
    var params = {
      'name': 'random_seed',
      'value': '42',
    };
    var result = await vm.invokeRpcNoUpgrade('setFlag', params);
    expect(result['type'], equals('Error'));
    expect(
        result['message'], equals('Cannot set flag: cannot change at runtime'));
  },

  // Modify the profile_period at runtime.
  (VM vm) async {
    final kProfilePeriod = 'profile_period';
    final kValue = 100;
    expect(await getFlagValue(vm, kProfilePeriod), '1000');
    final params = {
      'name': '$kProfilePeriod',
      'value': '$kValue',
    };
    final completer = Completer();
    final stream = await vm.getEventStream(VM.kVMStream);
    var subscription;
    subscription = stream.listen((ServiceEvent event) {
      if (event.kind == ServiceEvent.kVMFlagUpdate) {
        expect(event.owner!.type, 'VM');
        expect(event.flag, kProfilePeriod);
        expect(event.newValue, kValue.toString());
        subscription.cancel();
        completer.complete();
      }
    });
    final result = await vm.invokeRpcNoUpgrade('setFlag', params);
    expect(result['type'], equals('Success'));
    await completer.future;
    expect(await getFlagValue(vm, kProfilePeriod), kValue.toString());
  },

  // Start and stop the profiler at runtime.
  (VM vm) async {
    final kProfiler = 'profiler';
    if (await getFlagValue(vm, kProfiler) == 'false') {
      // Either in release or product modes and the profiler is disabled.
      return;
    }
    final params = {
      'name': kProfiler,
      'value': 'false',
    };

    var result = await vm.invokeRpcNoUpgrade('setFlag', params);
    expect(result['type'], equals('Success'));
    expect(await getFlagValue(vm, kProfiler), 'false');
    try {
      // Arbitrary RPC which checks whether or not the profiler is enabled.
      await vm.isolates.first.invokeRpcNoUpgrade('getCpuSamples', {});
      fail('Profiler is disabled and request should fail');
    } on ServerRpcException catch (_) {/* Expected */}

    // Clear CPU samples.
    result = await vm.isolates.first.invokeRpcNoUpgrade('clearCpuSamples', {});
    expect(result['type'], equals('Success'));

    params['value'] = 'true';
    result = await vm.invokeRpcNoUpgrade('setFlag', params);
    expect(result['type'], equals('Success'));
    expect(await getFlagValue(vm, kProfiler), 'true');

    try {
      // Arbitrary RPC which checks whether or not the profiler is enabled.
      result = await vm.isolates.first.invokeRpcNoUpgrade('getCpuSamples', {});
    } on ServerRpcException catch (e) {
      fail('Profiler is enabled and request should succeed. Error:\n$e');
    }
  },
];

main(args) async => runVMTests(args, tests);
