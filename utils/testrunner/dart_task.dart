// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** A pipeline task for running the Dart VM. */
class DartTask extends RunProcessTask {

  DartTask.checked(String dartFileTemplate) {
    init(config.dartPath,
        ['--enable_asserts', '--enable_type_checks', dartFileTemplate],
        config.timeout);
  }

  DartTask(String dartFileTemplate) {
    init(config.dartPath, [dartFileTemplate], config.timeout);
  }
}
