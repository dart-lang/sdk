// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../compiler_api.dart' as api;

class BinaryOutputSinkAdapter implements Sink<List<int>> {
  api.BinaryOutputSink output;

  BinaryOutputSinkAdapter(this.output);

  @override
  void add(List<int> data) {
    output.write(data);
  }

  @override
  void close() {
    output.close();
  }
}
