// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/instrumentation/service.dart';

/// Implementation of [InstrumentationService] that throws on [logException].
class TestInstrumentationService implements InstrumentationService {
  @override
  void logException(
    exception, [
    StackTrace stackTrace,
    List<InstrumentationServiceAttachment> attachments,
  ]) {
    throw CaughtException(exception, stackTrace);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}
