// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConfigurationTest);
  });
}

@reflectiveTest
class ConfigurationTest extends AbstractLspAnalysisServerTest {
  /// When we tell the server config has changed, we expect it to immediately
  /// ask for the updated config.
  Future<void> test_configChange() async {
    setDidChangeConfigurationDynamicRegistration();
    await provideConfig(
      initialize,
      {'dart.foo': false},
    );

    // The updateConfig helper will only complete after the server requests the config.
    await updateConfig({'dart.foo': true});
  }

  Future<void> test_configurationDidChange_notSupported() async {
    // Initialize with some other dynamic capabilities just to force
    // a dynamic registration request to come through. Otherwise we'd have
    // to test that the request never came, which means waiting around for
    // some period and making the test slower.
    setTextSyncDynamicRegistration();

    final registrations = <Registration>[];
    await monitorDynamicRegistrations(
      registrations,
      () => initialize(),
    );

    final registration =
        registrationFor(registrations, Method.workspace_didChangeConfiguration);
    expect(registration, isNull);
  }

  Future<void> test_configurationDidChange_refreshesRoots() async {
    setDidChangeConfigurationDynamicRegistration();

    await provideConfig(
      initialize,
      {}, // Empty config
    );

    // Ensure the roots are as expected before we update the config.
    expect(server.contextManager.includedPaths, equals([projectFolderPath]));
    expect(server.contextManager.excludedPaths, isEmpty);

    // Notify the server of updated config that includes an excluded path.
    final excludedFolderPath = join(projectFolderPath, 'excluded');
    await updateConfig({
      'analysisExcludedFolders': [excludedFolderPath]
    });

    // Ensure the roots were updated by the config change.
    expect(server.contextManager.includedPaths, equals([projectFolderPath]));
    expect(server.contextManager.excludedPaths, equals([excludedFolderPath]));
  }

  Future<void> test_configurationDidChange_supported() async {
    setDidChangeConfigurationDynamicRegistration();

    final registrations = <Registration>[];
    await monitorDynamicRegistrations(
      registrations,
      initialize,
    );

    final registration =
        registrationFor(registrations, Method.workspace_didChangeConfiguration);
    expect(registration, isNotNull);
  }

  Future<void> test_configurationRequest_notSupported() async {
    var didGetConfigRequest = false;
    requestsFromServer
        .where((n) => n.method == Method.workspace_configuration)
        .listen((_) => didGetConfigRequest = true);

    await initialize();
    await pumpEventQueue();

    expect(didGetConfigRequest, isFalse);
  }

  Future<void> test_configurationRequest_supported() async {
    setConfigurationSupport();

    final configRequest = requestsFromServer
        .firstWhere((n) => n.method == Method.workspace_configuration);
    expect(configRequest, completes);

    await initialize();
    await pumpEventQueue();
  }
}
