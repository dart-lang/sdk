// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Support for client code that extends the analysis engine by adding new
 * analysis tasks.
 */
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/plugin/engine_plugin.dart';
import 'package:analyzer/src/task/api/model.dart';
import 'package:plugin/plugin.dart';

/**
 * The identifier of the extension point that allows plugins to register new
 * analysis error results to compute for a Dart source. The object used as an
 * extension must be a [ResultDescriptor].
 */
final String DART_ERRORS_FOR_SOURCE_EXTENSION_POINT_ID = Plugin.join(
    EnginePlugin.UNIQUE_IDENTIFIER,
    EnginePlugin.DART_ERRORS_FOR_SOURCE_EXTENSION_POINT);

/**
 * The identifier of the extension point that allows plugins to register new
 * analysis error results to compute for a Dart library specific unit. The
 * object used as an extension must be a [ResultDescriptor].
 */
final String DART_ERRORS_FOR_UNIT_EXTENSION_POINT_ID = Plugin.join(
    EnginePlugin.UNIQUE_IDENTIFIER,
    EnginePlugin.DART_ERRORS_FOR_UNIT_EXTENSION_POINT);

/**
 * The identifier of the extension point that allows plugins to register new
 * analysis error results to compute for an HTML source. The object used as an
 * extension must be a [ResultDescriptor].
 */
final String HTML_ERRORS_EXTENSION_POINT_ID = Plugin.join(
    EnginePlugin.UNIQUE_IDENTIFIER, EnginePlugin.HTML_ERRORS_EXTENSION_POINT);

/**
 * The identifier of the extension point that allows plugins to register new
 * work managers with the analysis engine. The object used as an extension must
 * be a [WorkManagerFactory].
 */
final String WORK_MANAGER_EXTENSION_POINT_ID = Plugin.join(
    EnginePlugin.UNIQUE_IDENTIFIER,
    EnginePlugin.WORK_MANAGER_FACTORY_EXTENSION_POINT);

/**
 * A function that will create a new [WorkManager] for the given [context].
 */
typedef WorkManager WorkManagerFactory(InternalAnalysisContext context);
