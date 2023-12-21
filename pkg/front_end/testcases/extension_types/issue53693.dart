// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type MetadataIndex(Map<String, dynamic> map) {
  Map<String, dynamic> get key => map['key'];
}

test(MetadataIndex index) {
  final MetadataIndex(:key) = index;
}

