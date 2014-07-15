// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.index.local_file_index;

import 'dart:io';

import 'package:analysis_services/index/index.dart';
import 'package:analysis_services/src/index/local_index.dart';
import 'package:analysis_services/src/index/store/codec.dart';
import 'package:analysis_services/src/index/store/separate_file_manager.dart';
import 'package:analysis_services/src/index/store/split_store.dart';
import 'package:analyzer/src/generated/engine.dart';


Index createLocalFileIndex(Directory directory) {
  var fileManager = new SeparateFileManager(directory);
  var stringCodec = new StringCodec();
  var nodeManager = new FileNodeManager(fileManager,
      AnalysisEngine.instance.logger, stringCodec, new ContextCodec(),
      new ElementCodec(stringCodec), new RelationshipCodec(stringCodec));
  return new LocalIndex(nodeManager);
}
