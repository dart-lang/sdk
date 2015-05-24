// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Support for client code that extends the set of files being analyzed by the
 * analysis server.
 *
 * Plugins can register a function that takes a [File] and returns a [bool]
 * indicating whether the plugin is interested in having that file be analyzed.
 * The analysis server will invoke the contributed functions and analyze the
 * file if at least one of the functions returns `true`. (The server is not
 * required to invoke every function with every file.)
 */
library analysis_server.plugin.analyzed_files;

import 'package:analysis_server/src/plugin/server_plugin.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:plugin/plugin.dart';

/**
 * The identifier of the extension point that allows plugins to register
 * functions that can cause files to be analyzed. The object used as an
 * extension must be a [ShouldAnalyzeFile] function.
 */
final String ANALYZE_FILE_EXTENSION_POINT_ID = Plugin.join(
    ServerPlugin.UNIQUE_IDENTIFIER, ServerPlugin.ANALYZE_FILE_EXTENSION_POINT);

/**
 * A function that returns `true` if the given [file] should be analyzed.
 */
typedef bool ShouldAnalyzeFile(File file);
