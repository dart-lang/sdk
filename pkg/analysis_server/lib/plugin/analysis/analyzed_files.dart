// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Support for client code that extends the set of files being analyzed by the
 * analysis server.
 *
 * Plugins can contribute a list of file patterns. Any file whose path matches
 * one or more of the contributed patterns will be analyzed. The file patterns
 * are interpreted as glob patterns as defined by the 'glob' package.
 *
 * If a plugin is interested in analyzing a certain kind of file, it needs to
 * ensure that files of that kind will be analyzed. It should register a list of
 * file patterns by including code like the following in the plugin's
 * registerExtensions method:
 *
 *     @override
 *     void registerExtensions(RegisterExtension registerExtension) {
 *       ...
 *       registerExtension(
 *           ANALYZED_FILE_PATTERNS_EXTENSION_POINT_ID,
 *           ['*.yaml']);
 *       ...
 *     }
 */
import 'package:analysis_server/src/plugin/server_plugin.dart';
import 'package:plugin/plugin.dart';

/**
 * The identifier of the extension point that allows plugins to cause certain
 * kinds of files to be analyzed. The object used as an extension must be a list
 * of strings. The strings are interpreted as glob patterns as defined by the
 * 'glob' package.
 */
final String ANALYZED_FILE_PATTERNS_EXTENSION_POINT_ID = Plugin.join(
    ServerPlugin.UNIQUE_IDENTIFIER,
    ServerPlugin.ANALYZED_FILE_PATTERNS_EXTENSION_POINT);
