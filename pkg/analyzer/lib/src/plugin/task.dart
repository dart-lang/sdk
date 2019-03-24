// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Support for client code that extends the analysis engine by adding new
 * analysis tasks.
 */
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/task/api/model.dart';

/**
 * A function that will create a new [WorkManager] for the given [context].
 */
typedef WorkManager WorkManagerFactory(InternalAnalysisContext context);
