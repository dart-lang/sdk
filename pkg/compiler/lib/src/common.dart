// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Library that re-exports libraries used throughout the compiler regardless
/// of phase or subfunctionality.
library dart2js.common;

export 'diagnostics/diagnostic_listener.dart'
    show DiagnosticMessage, DiagnosticReporter;
export 'diagnostics/invariant.dart'
    show assertDebugMode, InternalErrorFunction, invariant, failedAt;
export 'diagnostics/messages.dart' show MessageKind;
export 'diagnostics/source_span.dart' show SourceSpan;
export 'diagnostics/spannable.dart'
    show
        CURRENT_ELEMENT_SPANNABLE,
        NO_LOCATION_SPANNABLE,
        Spannable,
        SpannableAssertionFailure;
export 'helpers/helpers.dart';
