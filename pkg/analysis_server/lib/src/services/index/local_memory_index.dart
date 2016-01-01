// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.index.memory_file_index;

import 'package:analysis_server/src/provisional/index/index_core.dart';
import 'package:analysis_server/src/services/index/index.dart';
import 'package:analysis_server/src/services/index/index_contributor.dart';
import 'package:analysis_server/src/services/index/local_index.dart';
import 'package:analysis_server/src/services/index/store/memory_node_manager.dart';

Index createLocalMemoryIndex() {
  MemoryNodeManager nodeManager = new MemoryNodeManager();
  LocalIndex index = new LocalIndex(nodeManager);
  index.contributors = <IndexContributor>[new DartIndexContributor()];
  return index;
}
