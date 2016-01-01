// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Support for client code that extends the analysis server by adding new index
 * contributors.
 *
 * Plugins can register index contributors. The registered contributors will be
 * used to contribute relationships to the index when the analysis of a file has
 * been completed.
 *
 * Typical relationships include things like "this variable is referenced here"
 * or "this method is invoked here". The index is used to improve the
 * performance of operations such as search or building a type hierarchy by
 * pre-computing some of the information needed by those operations.
 *
 * If a plugin wants to contribute information to the index, it should implement
 * the class [IndexContributor] and then register the contributor by including
 * code like the following in the plugin's registerExtensions method:
 *
 *     @override
 *     void registerExtensions(RegisterExtension registerExtension) {
 *       ...
 *       registerExtension(
 *           INDEX_CONTRIBUTOR_EXTENSION_POINT_ID,
 *           new MyIndexContributor());
 *       ...
 *     }
 */
library analysis_server.plugin.index.index;

import 'package:analysis_server/src/plugin/server_plugin.dart';
import 'package:analysis_server/src/provisional/index/index_core.dart';
import 'package:plugin/plugin.dart';

/**
 * The identifier of the extension point that allows plugins to register index
 * contributors. The object used as an extension must be an [IndexContributor].
 */
final String INDEX_CONTRIBUTOR_EXTENSION_POINT_ID = Plugin.join(
    ServerPlugin.UNIQUE_IDENTIFIER,
    ServerPlugin.INDEX_CONTRIBUTOR_EXTENSION_POINT);
