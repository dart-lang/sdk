// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Timeout(Duration(minutes: 2))
library;

import 'package:dwds/src/debugging/metadata/class.dart';
import 'package:test/test.dart';

void main() {
  test('Gracefully handles invalid length objects', () async {
    ClassMetaData createMetadata(dynamic length) => ClassMetaData(
      length: length,
      runtimeKind: RuntimeObjectKind.object,
      classRef: classRefForUnknown,
    );

    var metadata = createMetadata(null);
    expect(metadata.length, isNull);

    metadata = createMetadata(<dynamic, dynamic>{});
    expect(metadata.length, isNull);

    metadata = createMetadata('{}');
    expect(metadata.length, isNull);

    metadata = createMetadata(0);
    expect(metadata.length, equals(0));
  });
}
