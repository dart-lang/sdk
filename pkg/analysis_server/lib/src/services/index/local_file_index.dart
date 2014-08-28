// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.index.local_file_index;

import 'package:analysis_server/src/services/index/index.dart';
import 'package:analysis_server/src/services/index/local_index.dart';
import 'package:analysis_server/src/services/index/store/codec.dart';
import 'package:analysis_server/src/services/index/store/temporary_folder_file_manager.dart';
import 'package:analysis_server/src/services/index/store/split_store.dart';
import 'package:analyzer/src/generated/engine.dart';


Index createLocalFileIndex() {
  var fileManager = new TemporaryFolderFileManager();
  var stringCodec = new StringCodec();
  var nodeManager =
      new FileNodeManager(
          fileManager,
          AnalysisEngine.instance.logger,
          stringCodec,
          new ContextCodec(),
          new ElementCodec(stringCodec),
          new RelationshipCodec(stringCodec));
  return new LocalIndex(nodeManager);
}
