// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--compile-all --error_on_bad_type --error_on_bad_override

import 'dart:async';

import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';

import 'test_helper.dart';

var tests = [
  (VM vm) async {
    var result = await vm.invokeRpcNoUpgrade('getFlagList', {});
    expect(result['type'], equals('FlagList'));

    // Find an unmodified flag.
    expect(result['unmodifiedFlags'].length, isPositive);
    bool found = false;
    for (var flag in result['unmodifiedFlags']) {
      if (flag['name'] == 'code_comments') {
        found = true;
        expect(flag['flagType'], equals('bool'));
        expect(flag['valueAsString'], equals('false'));
      } 
    }
    expect(found, isTrue);

    // Find a modified flag.
    expect(result['modifiedFlags'].length, isPositive);
    found = false;
    for (var flag in result['modifiedFlags']) {
      if (flag['name'] == 'enable_type_checks') {
        found = true;
        expect(flag['flagType'], equals('bool'));
        expect(flag['valueAsString'], equals('true'));
      } 
    }
    expect(found, isTrue);

    // Modify a flag.
    var params = {
      'name' : 'code_comments',
      'value' : 'true',
    };
    result = await vm.invokeRpcNoUpgrade('setFlag', params);
    expect(result['type'], equals('Success'));
    
    result = await vm.invokeRpcNoUpgrade('getFlagList', {});
    expect(result['type'], equals('FlagList'));

    // Make sure flag has been modified.
    expect(result['modifiedFlags'].length, isPositive);
    found = false;
    for (var flag in result['modifiedFlags']) {
      if (flag['name'] == 'code_comments') {
        found = true;
        expect(flag['valueAsString'], equals('true'));  // changed.
      } 
    }
    expect(found, isTrue);
  },

  // Modify a flag which does not exist.
  (VM vm) async {
    // Modify a flag.
    var params = {
      'name' : 'does_not_really_exist',
      'value' : 'true',
    };
    var result = await vm.invokeRpcNoUpgrade('setFlag', params);
    expect(result['type'], equals('Error'));
    expect(result['message'], equals('Cannot set flag: flag not found'));
  },

  // Modify a flag with the wrong value type.
  (VM vm) async {
    // Modify a flag.
    var params = {
      'name' : 'code_comments',
      'value' : '123',
    };
    var result = await vm.invokeRpcNoUpgrade('setFlag', params);
    expect(result['type'], equals('Error'));
    expect(result['message'], equals('Cannot set flag: invalid value'));
  },
];

main(args) async => runVMTests(args, tests);
