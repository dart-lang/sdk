// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Support for client code that extends the analysis server by adding new
 * occurrences contributors.
 */
library analysis_server.plugin.occurrences;

import 'package:analysis_server/analysis/occurrences_core.dart';
import 'package:analysis_server/src/plugin/server_plugin.dart';
import 'package:plugin/plugin.dart';

/**
 * The identifier of the extension point that allows plugins to register
 * element occurrences. The object used as an extension must be
 * a [OccurrencesContributor].
 */
final String OCCURRENCES_CONTRIBUTOR_EXTENSION_POINT_ID = Plugin.join(
    ServerPlugin.UNIQUE_IDENTIFIER,
    ServerPlugin.OCCURRENCES_CONTRIBUTOR_EXTENSION_POINT);
