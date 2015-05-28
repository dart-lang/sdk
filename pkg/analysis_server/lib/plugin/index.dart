// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Support for client code that extends the analysis server by adding new index
 * contributors.
 */
library analysis_server.plugin.index;

import 'package:analysis_server/analysis/index/index_core.dart';
import 'package:analysis_server/src/plugin/server_plugin.dart';
import 'package:plugin/plugin.dart';

/**
 * The identifier of the extension point that allows plugins to register index
 * contributors. The object used as an extension must be an [IndexContributor].
 */
final String INDEX_CONTRIBUTOR_EXTENSION_POINT_ID = Plugin.join(
    ServerPlugin.UNIQUE_IDENTIFIER,
    ServerPlugin.INDEX_CONTRIBUTOR_EXTENSION_POINT);
