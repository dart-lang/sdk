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
