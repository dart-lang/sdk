// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Support for client code that extends the analysis server by adding new
 * occurrences contributors.
 *
 * Plugins can register occurrences contributors. The registered contributors
 * will be used to get occurrence information any time the server is about to
 * send an 'analysis.occurrences' notification.
 *
 * If a plugin wants to add occurrence information, it should implement the
 * class [OccurrencesContributor] and then register the contributor by including
 * code like the following in the plugin's registerExtensions method:
 *
 *     @override
 *     void registerExtensions(RegisterExtension registerExtension) {
 *       ...
 *       registerExtension(
 *           OCCURRENCES_CONTRIBUTOR_EXTENSION_POINT_ID,
 *           new MyOccurrencesContributor());
 *       ...
 *     }
 */
library analysis_server.plugin.analysis.occurrences.occurrences;

import 'package:analysis_server/plugin/analysis/occurrences/occurrences_core.dart';
import 'package:analysis_server/src/plugin/server_plugin.dart';
import 'package:plugin/plugin.dart';

/**
 * The identifier of the extension point that allows plugins to register
 * occurrence information. The object used as an extension must be an
 * [OccurrencesContributor].
 */
final String OCCURRENCES_CONTRIBUTOR_EXTENSION_POINT_ID = Plugin.join(
    ServerPlugin.UNIQUE_IDENTIFIER,
    ServerPlugin.OCCURRENCES_CONTRIBUTOR_EXTENSION_POINT);
