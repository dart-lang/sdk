// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.resolution;

import '../common.dart';
import '../common/tasks.dart' show CompilerTask, Measurer;
import '../elements/elements.dart';
import 'tree_elements.dart';

class ResolverTask extends CompilerTask {
  ResolverTask(Measurer measurer) : super(measurer);
}

abstract class AnalyzableElementX implements AnalyzableElement {
  TreeElements _treeElements;

  bool get hasTreeElements => _treeElements != null;

  TreeElements get treeElements {
    assert(_treeElements != null,
        failedAt(this, "TreeElements have not been computed for $this."));
    return _treeElements;
  }

  void reuseElement() {
    _treeElements = null;
  }
}
