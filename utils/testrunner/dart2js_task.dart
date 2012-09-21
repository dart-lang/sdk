// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** A pipeline task to run the compiler. */
class Dart2jsTask extends RunProcessTask {
  final String _jsFileTemplate;

  Dart2jsTask.checked(String dartFileTemplate, jsFileTemplate) :
    super(config.dart2jsPath,
        ['--enable_checked_mode', '--out=$jsFileTemplate', dartFileTemplate],
        config.timeout),
    _jsFileTemplate = jsFileTemplate;

  Dart2jsTask(String dartFileTemplate, jsFileTemplate) :
    super(config.dart2jsPath, ['--out=$jsFileTemplate', dartFileTemplate],
         config.timeout),
    _jsFileTemplate = jsFileTemplate;

  void cleanup(Path testfile, List stdout, List stderr,
               bool logging, bool keepFiles) {
    deleteFiles([_jsFileTemplate ], testfile, logging, keepFiles, stdout);
  }
}
