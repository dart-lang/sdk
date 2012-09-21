// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** A simple pipeline task to delete a file. */
class DeleteTask extends PipelineTask {
  final String _filenameTemplate;

  DeleteTask(this._filenameTemplate);

  execute(Path testfile, List stdout, List stderr, bool logging,
              Function exitHandler) {
    var fname = expandMacros(_filenameTemplate, testfile);
    deleteFile(fname);
    if (logging) {
      stdout.add('Removing $fname');
    }
    exitHandler(0);
  }
}
