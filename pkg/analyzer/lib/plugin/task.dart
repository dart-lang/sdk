// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Support for client code that extends the analysis engine by adding new
 * analysis tasks.
 */
library analyzer.plugin.task;

import 'package:analyzer/plugin/plugin.dart';
import 'package:analyzer/src/plugin/engine_plugin.dart';
import 'package:analyzer/task/model.dart';

/**
 * The identifier of the extension point that allows plugins to register new
 * analysis tasks with the analysis engine. The object used as an extension must
 * be a [TaskDescriptor].
 */
final String TASK_EXTENSION_POINT_ID = Plugin.join(
    EnginePlugin.UNIQUE_IDENTIFIER, EnginePlugin.TASK_EXTENSION_POINT);
