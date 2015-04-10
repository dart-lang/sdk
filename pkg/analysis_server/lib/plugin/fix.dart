// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Support for client code that extends the analysis server by adding new fix
 * contributors.
 */
library analysis_server.plugin.fix;

import 'package:analysis_server/edit/fix/fix_core.dart';
import 'package:analysis_server/src/plugin/server_plugin.dart';
import 'package:analyzer/plugin/plugin.dart';

/**
 * The identifier of the extension point that allows plugins to register new
 * fix contributors with the server. The object used as an extension must be a
 * [FixContributor].
 */
final String FIX_CONTRIBUTOR_EXTENSION_POINT_ID = Plugin.join(
    ServerPlugin.UNIQUE_IDENTIFIER,
    ServerPlugin.FIX_CONTRIBUTOR_EXTENSION_POINT);
