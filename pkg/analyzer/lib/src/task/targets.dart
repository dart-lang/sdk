// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.task.targets;

import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/task/model.dart';

/**
 * A `SourceTarget` is a [Source] that can be used as an [AnalysisTarget].
 */
class SourceTarget implements AnalysisTarget {
  /**
   * The source being represented as a target.
   */
  final Source source;

  /**
   * Initialize a newly created target to represent the given [source].
   */
  SourceTarget(this.source);

  @override
  int get hashCode => source.hashCode;

  @override
  bool operator ==(Object object) {
    return object is SourceTarget && object.source == source;
  }
}
