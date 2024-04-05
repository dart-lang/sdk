// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:args/args.dart';

abstract class DartDevelopmentServiceOptions {
  static const vmServiceUriOption = 'vm-service-uri';
  static const bindAddressOption = 'bind-address';
  static const bindPortOption = 'bind-port';
  static const disableServiceAuthCodesFlag = 'disable-service-auth-codes';
  static const serveDevToolsFlag = 'serve-devtools';
  static const enableServicePortFallbackFlag = 'enable-service-port-fallback';

  static ArgParser createArgParser({
    int? usageLineLength,
    bool includeHelp = false,
  }) {
    final args = ArgParser(usageLineLength: usageLineLength)
      ..addOption(
        vmServiceUriOption,
        help: 'The VM service URI DDS will connect to.',
        valueHelp: 'uri',
        mandatory: true,
      )
      ..addOption(bindAddressOption,
          help: 'The address DDS should bind to.',
          valueHelp: 'address',
          defaultsTo: 'localhost')
      ..addOption(
        bindPortOption,
        help: 'The port DDS should be served on.',
        valueHelp: 'port',
        defaultsTo: '0',
      )
      ..addFlag(
        disableServiceAuthCodesFlag,
        help: 'Disables authentication codes.',
      )
      ..addFlag(
        serveDevToolsFlag,
        help: 'If provided, DDS will serve DevTools.',
      )
      ..addFlag(
        enableServicePortFallbackFlag,
        help: 'Bind to a random port if DDS fails to bind to the provided '
            'port.',
      );
    if (includeHelp) {
      args.addFlag('help', negatable: false);
    }
    return args;
  }
}
