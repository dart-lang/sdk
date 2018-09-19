// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A flag indicating whether analysis driver should work using one-phase,
/// unresolved AST based summaries, or using old unlinked / link process.
const bool enableOnePhaseSummaries =
    const bool.fromEnvironment('enableOnePhaseSummaries', defaultValue: false);
