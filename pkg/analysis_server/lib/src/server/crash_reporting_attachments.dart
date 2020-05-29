// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/instrumentation/service.dart';
import 'package:analyzer/src/dart/analysis/driver.dart' show ExceptionResult;

/// A builder for attachments to include into crash reports.
class CrashReportingAttachmentsBuilder {
  static final CrashReportingAttachmentsBuilder empty =
      CrashReportingAttachmentsBuilder();

  /// Return attachments with information about the analysis exception.
  List<InstrumentationServiceAttachment> forException(
    Object exception,
  ) {
    return const [];
  }

  /// Return attachments with information about the analysis exception.
  List<InstrumentationServiceAttachment> forExceptionResult(
    ExceptionResult result,
  ) {
    return const [];
  }
}
