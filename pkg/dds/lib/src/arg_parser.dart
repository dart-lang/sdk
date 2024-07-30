// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(bkonyi): consider moving to lib/ once this package is no longer shipped
// via pub.

import 'package:args/args.dart';

abstract class DartDevelopmentServiceOptions {
  static const vmServiceUriOption = 'vm-service-uri';
  static const bindAddressOption = 'bind-address';
  static const bindPortOption = 'bind-port';
  static const disableServiceAuthCodesFlag = 'disable-service-auth-codes';
  static const serveDevToolsFlag = 'serve-devtools';
  static const enableServicePortFallbackFlag = 'enable-service-port-fallback';
  static const cachedUserTagsOption = 'cached-user-tags';
  static const devToolsServerAddressOption = 'devtools-server-address';

  static ArgParser createArgParser({
    int? usageLineLength,
    bool verbose = false,
    bool includeHelp = false,
  }) {
    final args = ArgParser(usageLineLength: usageLineLength);
    populateArgParser(
      argParser: args,
      verbose: verbose,
      includeHelp: includeHelp,
    );
    return args;
  }

  static void populateArgParser({
    required ArgParser argParser,
    bool verbose = false,
    bool includeHelp = false,
  }) {
    argParser
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
        help: 'If provided, DDS will serve DevTools. If not specified, '
            '"--$devToolsServerAddressOption" is ignored.',
      )
      ..addOption(
        devToolsServerAddressOption,
        help: 'Redirect to an existing DevTools server. Ignored if '
            '"--$serveDevToolsFlag" is not specified.',
      )
      ..addFlag(
        enableServicePortFallbackFlag,
        help: 'Bind to a random port if DDS fails to bind to the provided '
            'port.',
      )
      ..addMultiOption(
        cachedUserTagsOption,
        help: 'A set of UserTag names used to determine which CPU samples are '
            'cached by DDS.',
        defaultsTo: <String>[],
      );
    if (includeHelp) {
      argParser.addFlag('help', negatable: false);
    }
  }
}
