// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';

/**
 * [ByteStore] that stores values as [File]s.
 *
 * TODO(scheglov) Add some eviction policies.
 */
class FileByteStore implements ByteStore {
  final Folder folder;

  FileByteStore(this.folder);

  @override
  List<int> get(String key) {
    try {
      File file = folder.getChildAssumingFile(key);
      return file.readAsBytesSync();
    } catch (_) {
      return null;
    }
  }

  @override
  void put(String key, List<int> bytes) {
    try {
      File file = folder.getChildAssumingFile(key);
      file.writeAsBytesSync(bytes);
    } catch (_) {}
  }
}
