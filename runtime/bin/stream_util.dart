// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void _pipe(InputStream input, OutputStream output, [bool close]) {
  Function pipeDataHandler;
  Function pipeCloseHandler;
  Function pipeNoPendingWriteHandler;

  Function _inputCloseHandler;

  pipeDataHandler = () {
    List<int> data;
    while ((data = input.read()) !== null) {
      if (!output.write(data)) {
        input.dataHandler = null;
        output.noPendingWriteHandler = pipeNoPendingWriteHandler;
        break;
      }
    }
  };

  pipeCloseHandler = () {
    if (close) output.close();
    if (_inputCloseHandler !== null) _inputCloseHandler();
  };

  pipeNoPendingWriteHandler = () {
    input.dataHandler = pipeDataHandler;
    output.noPendingWriteHandler = null;
  };

  _inputCloseHandler = input._clientCloseHandler;
  input.dataHandler = pipeDataHandler;
  input.closeHandler = pipeCloseHandler;
  output.noPendingWriteHandler = null;
}

