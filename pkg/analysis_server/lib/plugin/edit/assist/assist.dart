// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Support for client code that extends the analysis server by adding new assist
 * contributors.
 *
 * Plugins can register assist contributors. The registered contributors will be
 * used to get assists any time a client issues an 'edit.getAssists' request.
 *
 * If a plugin wants to add assists, it should implement the class
 * [AssistContributor] and then register the contributor by including code like
 * the following in the plugin's registerExtensions method:
 *
 *     @override
 *     void registerExtensions(RegisterExtension registerExtension) {
 *       ...
 *       registerExtension(
 *           ASSIST_CONTRIBUTOR_EXTENSION_POINT_ID,
 *           new MyAssistContributor());
 *       ...
 *     }
 */
import 'package:analysis_server/plugin/edit/assist/assist_core.dart';
import 'package:analysis_server/src/plugin/server_plugin.dart';
import 'package:plugin/plugin.dart';

/**
 * The identifier of the extension point that allows plugins to register assist
 * contributors. The object used as an extension must be an [AssistContributor].
 */
final String ASSIST_CONTRIBUTOR_EXTENSION_POINT_ID = Plugin.join(
    ServerPlugin.UNIQUE_IDENTIFIER,
    ServerPlugin.ASSIST_CONTRIBUTOR_EXTENSION_POINT);
