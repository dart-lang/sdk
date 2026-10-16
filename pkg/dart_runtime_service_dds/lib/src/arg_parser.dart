// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:args/args.dart';

/// Command-line argument names and parser helpers for configuring the Dart
/// Development Service (DDS).
abstract final class DartDevelopmentServiceOptions {
  /// The VM service WebSocket or HTTP URI that DDS will connect to.
  static const vmServiceUriOption = 'vm-service-uri';

  /// The IP or hostname DDS should bind to.
  static const bindAddressOption = 'bind-address';

  /// The port DDS should bind to.
  static const bindPortOption = 'bind-port';

  /// Disables authentication code requirements on DDS endpoints.
  static const disableServiceAuthCodesFlag = 'disable-service-auth-codes';

  /// Enables serving DevTools static assets.
  static const serveDevToolsFlag = 'serve-devtools';

  /// Enables binding to a random available port if the specified port is
  /// already in use.
  static const enableServicePortFallbackFlag = 'enable-service-port-fallback';

  /// Deprecated option for cached user tags.
  static const cachedUserTagsOption = 'cached-user-tags';

  /// The address of an external DevTools server instance to redirect to.
  static const devToolsServerAddressOption = 'devtools-server-address';

  /// Google3 workspace root path used for google3:// URI resolution.
  static const google3WorkspaceRootOption = 'google3-workspace-root';

  /// A short, user-focused name describing the application connecting to DDS.
  static const appNameOption = 'app-name';

  /// Creates a new [ArgParser] populated with standard DDS options.
  static ArgParser createArgParser({
    bool includeHelp = false,
    int? usageLineLength,
    bool verbose = false,
  }) {
    final args = ArgParser(usageLineLength: usageLineLength);
    populateArgParser(
      argParser: args,
      includeHelp: includeHelp,
      verbose: verbose,
    );
    return args;
  }

  /// Populates the given [argParser] with standard DDS options and flags.
  static void populateArgParser({
    required ArgParser argParser,
    bool includeHelp = false,
    bool verbose = false,
  }) {
    argParser
      ..addOption(
        vmServiceUriOption,
        help: 'The VM service URI DDS will connect to.',
        valueHelp: 'uri',
        mandatory: true,
      )
      ..addOption(
        bindAddressOption,
        help: 'The address DDS should bind to.',
        valueHelp: 'address',
        defaultsTo: 'localhost',
      )
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
        help:
            'If provided, DDS will serve DevTools. If not specified, '
            '"--$devToolsServerAddressOption" is ignored.',
      )
      ..addOption(
        devToolsServerAddressOption,
        help:
            'Redirect to an existing DevTools server. Ignored if '
            '"--$serveDevToolsFlag" is not specified.',
      )
      ..addFlag(
        enableServicePortFallbackFlag,
        help:
            'Bind to a random port if DDS fails to bind to the provided '
            'port.',
      )
      ..addMultiOption(
        cachedUserTagsOption,
        help:
            'This option is deprecated and supplying it will cause no '
            'effect.',
        defaultsTo: <String>[],
        hide: true,
      )
      ..addOption(
        google3WorkspaceRootOption,
        help:
            'Sets the Google3 workspace root used for google3:// URI '
            'resolution.',
        hide: !verbose,
      )
      ..addOption(
        appNameOption,
        help:
            'A short, user focused description of the application that DDS '
            'will connect to.',
      );
    if (includeHelp) {
      argParser.addFlag('help', negatable: false);
    }
  }
}
