// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Support for client code that extends the analysis server by adding new fix
 * contributors.
 *
 * Plugins can register fix contributors. The registered contributors will be
 * used to get fixes any time a client issues an 'edit.getFixes' request.
 *
 * If a plugin wants to add fixes, it should implement the class
 * [FixContributor] and then register the contributor by including code like the
 * following in the plugin's registerExtensions method:
 *
 *     @override
 *     void registerExtensions(RegisterExtension registerExtension) {
 *       ...
 *       registerExtension(
 *           FIX_CONTRIBUTOR_EXTENSION_POINT_ID,
 *           new MyFixContributor());
 *       ...
 *     }
 */
library analysis_server.plugin.edit.fix.fix;

import 'package:analysis_server/plugin/edit/fix/fix_core.dart';
import 'package:analysis_server/src/plugin/server_plugin.dart';
import 'package:plugin/plugin.dart';

/**
 * The identifier of the extension point that allows plugins to register fix
 * contributors. The object used as an extension must be a [FixContributor].
 */
final String FIX_CONTRIBUTOR_EXTENSION_POINT_ID = Plugin.join(
    ServerPlugin.UNIQUE_IDENTIFIER,
    ServerPlugin.FIX_CONTRIBUTOR_EXTENSION_POINT);
