// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/lsp/client_configuration.dart';
import 'package:analyzer_testing/resource_provider_mixin.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ClientConfigurationTest);
    defineReflectiveTests(InlayHintsConfigurationTest);
  });
}

@reflectiveTest
class ClientConfigurationTest with ResourceProviderMixin {
  void test_folderConfig() {
    var folder = convertPath('/home/test');
    var file = convertPath('/home/test/file.dart');
    var config = LspClientConfiguration(resourceProvider.pathContext);
    config.replace(
      {'lineLength': 100},
      {
        folder: {'lineLength': 200},
      },
    );
    expect(config.forResource(file).lineLength, equals(200));
  }

  void test_folderConfig_globalFallback() {
    var file = convertPath('/home/test/file.dart');
    var config = LspClientConfiguration(resourceProvider.pathContext);
    config.replace({'lineLength': 100}, {});
    // Should fall back to the global config.
    expect(config.forResource(file).lineLength, equals(100));
  }

  void test_folderConfig_nested() {
    var folderOne = convertPath('/one');
    var folderTwo = convertPath('/one/two');
    var folderThree = convertPath('/one/two/three');
    var file = convertPath('/one/two/three/file.dart');
    var config = LspClientConfiguration(resourceProvider.pathContext);
    config.replace(
      {'lineLength': 50},
      {
        folderOne: {'lineLength': 100},
        folderThree: {'lineLength': 300},
        folderTwo: {'lineLength': 200},
      },
    );
    // Should use the inner-most folder (folderThree).
    expect(config.forResource(file).lineLength, equals(300));
  }

  void test_globalConfig() {
    var config = LspClientConfiguration(resourceProvider.pathContext);
    config.replace({'lineLength': 100}, {});
    expect(config.global.lineLength, equals(100));
  }
}

/// Verifies all the different ways of expressions the config resolve to the
/// same values, so the inlay hint handler tests can simply test one combination
/// for each kind of hint.
@reflectiveTest
class InlayHintsConfigurationTest {
  void test_dotShorthandTypes_disabled() {
    var options = [
      LspClientInlayHintsConfiguration(false),
      LspClientInlayHintsConfiguration({'dotShorthandTypes': false}),
      LspClientInlayHintsConfiguration({
        'dotShorthandTypes': {'enabled': false},
      }),
    ];

    for (var option in options) {
      expect(option.dotShorthandTypesEnabled, false);
    }
  }

  void test_dotShorthandTypes_enabled() {
    var options = [
      LspClientInlayHintsConfiguration(null),
      LspClientInlayHintsConfiguration(true),
      LspClientInlayHintsConfiguration({'dotShorthandTypes': true}),
      LspClientInlayHintsConfiguration({
        'dotShorthandTypes': {'enabled': true},
      }),
    ];

    for (var option in options) {
      expect(option.dotShorthandTypesEnabled, true);
    }
  }

  void test_parameterNames_all() {
    var options = [
      LspClientInlayHintsConfiguration(null),
      LspClientInlayHintsConfiguration(true),
      LspClientInlayHintsConfiguration({'parameterNames': true}),
      LspClientInlayHintsConfiguration({'parameterNames': 'all'}),
      LspClientInlayHintsConfiguration({
        'parameterNames': {'enabled': true},
      }),
      LspClientInlayHintsConfiguration({
        'parameterNames': {'enabled': 'all'},
      }),
    ];

    for (var option in options) {
      expect(option.parameterNamesMode, InlayHintsParameterNamesMode.all);
    }
  }

  void test_parameterNames_literal() {
    var options = [
      LspClientInlayHintsConfiguration({'parameterNames': 'literal'}),
      LspClientInlayHintsConfiguration({
        'parameterNames': {'enabled': 'literal'},
      }),
    ];

    for (var option in options) {
      expect(option.parameterNamesMode, InlayHintsParameterNamesMode.literal);
    }
  }

  void test_parameterNames_none() {
    var options = [
      LspClientInlayHintsConfiguration(false),
      LspClientInlayHintsConfiguration({'parameterNames': false}),
      LspClientInlayHintsConfiguration({'parameterNames': 'none'}),
      LspClientInlayHintsConfiguration({
        'parameterNames': {'enabled': false},
      }),
      LspClientInlayHintsConfiguration({
        'parameterNames': {'enabled': 'none'},
      }),
    ];

    for (var option in options) {
      expect(option.parameterNamesMode, InlayHintsParameterNamesMode.none);
    }
  }

  void test_parameterTypes_disabled() {
    var options = [
      LspClientInlayHintsConfiguration(false),
      LspClientInlayHintsConfiguration({'parameterTypes': false}),
      LspClientInlayHintsConfiguration({
        'parameterTypes': {'enabled': false},
      }),
    ];

    for (var option in options) {
      expect(option.parameterTypesEnabled, false);
    }
  }

  void test_parameterTypes_enabled() {
    var options = [
      LspClientInlayHintsConfiguration(null),
      LspClientInlayHintsConfiguration(true),
      LspClientInlayHintsConfiguration({'parameterTypes': true}),
      LspClientInlayHintsConfiguration({
        'parameterTypes': {'enabled': true},
      }),
    ];

    for (var option in options) {
      expect(option.parameterTypesEnabled, true);
    }
  }

  void test_returnTypes_disabled() {
    var options = [
      LspClientInlayHintsConfiguration(false),
      LspClientInlayHintsConfiguration({'returnTypes': false}),
      LspClientInlayHintsConfiguration({
        'returnTypes': {'enabled': false},
      }),
    ];

    for (var option in options) {
      expect(option.returnTypesEnabled, false);
    }
  }

  void test_returnTypes_enabled() {
    var options = [
      LspClientInlayHintsConfiguration(null),
      LspClientInlayHintsConfiguration(true),
      LspClientInlayHintsConfiguration({'returnTypes': true}),
      LspClientInlayHintsConfiguration({
        'returnTypes': {'enabled': true},
      }),
    ];

    for (var option in options) {
      expect(option.returnTypesEnabled, true);
    }
  }

  void test_typeArguments_disabled() {
    var options = [
      LspClientInlayHintsConfiguration(false),
      LspClientInlayHintsConfiguration({'typeArguments': false}),
      LspClientInlayHintsConfiguration({
        'typeArguments': {'enabled': false},
      }),
    ];

    for (var option in options) {
      expect(option.typeArgumentsEnabled, false);
    }
  }

  void test_typeArguments_enabled() {
    var options = [
      LspClientInlayHintsConfiguration(null),
      LspClientInlayHintsConfiguration(true),
      LspClientInlayHintsConfiguration({'typeArguments': true}),
      LspClientInlayHintsConfiguration({
        'typeArguments': {'enabled': true},
      }),
    ];

    for (var option in options) {
      expect(option.typeArgumentsEnabled, true);
    }
  }

  void test_variableTypes_disabled() {
    var options = [
      LspClientInlayHintsConfiguration(false),
      LspClientInlayHintsConfiguration({'variableTypes': false}),
      LspClientInlayHintsConfiguration({
        'variableTypes': {'enabled': false},
      }),
    ];

    for (var option in options) {
      expect(option.variableTypesEnabled, false);
    }
  }

  void test_variableTypes_enabled() {
    var options = [
      LspClientInlayHintsConfiguration(null),
      LspClientInlayHintsConfiguration(true),
      LspClientInlayHintsConfiguration({'variableTypes': true}),
      LspClientInlayHintsConfiguration({
        'variableTypes': {'enabled': true},
      }),
    ];

    for (var option in options) {
      expect(option.variableTypesEnabled, true);
    }
  }
}
