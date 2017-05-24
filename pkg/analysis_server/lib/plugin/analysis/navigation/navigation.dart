// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Support for client code that extends the analysis server by adding new
 * navigation contributors.
 *
 * Plugins can register navigation contributors. The registered contributors
 * will be used to get navigation regions any time a client issues an
 * 'analysis.getNavigation' request or the server is about to send an
 * 'analysis.navigation' notification.
 *
 * If a plugin wants to add navigation regions, it should implement the class
 * [NavigationContributor] and then register the contributor by including code
 * like the following in the plugin's registerExtensions method:
 *
 *     @override
 *     void registerExtensions(RegisterExtension registerExtension) {
 *       ...
 *       registerExtension(
 *           NAVIGATION_CONTRIBUTOR_EXTENSION_POINT_ID,
 *           new MyNavigationContributor());
 *       ...
 *     }
 */
import 'package:analysis_server/plugin/analysis/navigation/navigation_core.dart';
import 'package:analysis_server/src/plugin/server_plugin.dart';
import 'package:plugin/plugin.dart';

/**
 * The identifier of the extension point that allows plugins to register
 * navigation contributors. The object used as an extension must be
 * a [NavigationContributor].
 */
final String NAVIGATION_CONTRIBUTOR_EXTENSION_POINT_ID = Plugin.join(
    ServerPlugin.UNIQUE_IDENTIFIER,
    ServerPlugin.NAVIGATION_CONTRIBUTOR_EXTENSION_POINT);
