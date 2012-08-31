// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** A pipeline task for running DumpRenderTree. */
class DrtTask extends RunProcessTask {

  DrtTask(String htmlFileTemplate) {
    init(config.drtPath, ['--no-timeout', htmlFileTemplate], config.timeout);
  }
}
