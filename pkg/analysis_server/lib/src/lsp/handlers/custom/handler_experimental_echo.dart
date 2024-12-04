// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';

/// A trivial handler for the [CustomMethods.experimentalEcho] custom request.
/// This handler is used by the servers automated tests but can also be used for
/// client testing (if they opt-in to experimental handlers).
class ExperimentalEchoHandler extends SharedMessageHandler<Object?, Object?> {
  ExperimentalEchoHandler(super.server);

  @override
  Method get handlesMessage => CustomMethods.experimentalEcho;

  @override
  LspJsonHandler<Object?> get jsonHandler =>
      LspJsonHandler<void>((_, _) => true, (obj) => obj);

  @override
  bool get requiresTrustedCaller => false;

  @override
  Future<ErrorOr<Object?>> handle(
    Object? params,
    MessageInfo message,
    CancellationToken token,
  ) async {
    // The DTD client automatically converts `null` params to an empty map, but
    // (because of a previous bug) we want to test null results. So if the
    // params are an empty map, return null. This is tested by
    // `test_service_success_echo_nullResponse` in `SharedDtdTests`.
    if (params is Map && params.isEmpty) {
      return success(null);
    }

    return success(params);
  }
}
