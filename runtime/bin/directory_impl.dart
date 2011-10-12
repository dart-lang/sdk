// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


class DirectoryException {
  const DirectoryException(String this.message);
  final String message;
}


class _DirectoryListingIsolate extends Isolate {

  _DirectoryListingIsolate() : super.heavy();

  void main() {
    port.receive((message, replyTo) {
       _list(message['dir'],
             message['recursive'],
             message['dirPort'],
             message['filePort'],
             message['donePort'],
             message['errorPort']);
       replyTo.send(true);
    });
  }

  void _list(String dir,
             bool recursive,
             SendPort dirPort,
             SendPort filePort,
             SendPort donePort,
             SendPort errorPort) native "Directory_List";
}


class _Directory implements Directory {

  _Directory(String this._dir);

  void list([bool recursive = false]) {
    new _DirectoryListingIsolate().spawn().then((port) {
      // Build a map of parameters to the directory listing isolate.
      Map listingParameters = new Map();
      listingParameters['dir'] = _dir;
      listingParameters['recursive'] = recursive;

      // Setup ports to receive messages from listing.
      // TODO(ager): Do not explicitly transform to send ports when
      // implicit conversions are implemented.
      ReceivePort dirPort;
      ReceivePort filePort;
      ReceivePort donePort;
      ReceivePort errorPort;
      if (_dirHandler !== null) {
        dirPort = new ReceivePort();
        dirPort.receive((String dir, ignored) {
          _dirHandler(dir);
        });
        listingParameters['dirPort'] = dirPort.toSendPort();
      }
      if (_fileHandler !== null) {
        filePort = new ReceivePort();
        filePort.receive((String file, ignored) {
          _fileHandler(file);
        });
        listingParameters['filePort'] = filePort.toSendPort();
      }
      if (_doneHandler !== null) {
        donePort = new ReceivePort();
        donePort.receive((bool completed, ignored) {
          _doneHandler(completed);
        });
        listingParameters['donePort'] = donePort.toSendPort();
      }
      if (_errorHandler !== null) {
        errorPort = new ReceivePort();
        errorPort.receive((String error, ignored) {
          _errorHandler(error);
        });
        listingParameters['errorPort'] = errorPort.toSendPort();
      }

      // Close ports when listing is done.
      ReceivePort closePortsPort = new ReceivePort();
      closePortsPort.receive((message, replyTo) {
        _closePort(dirPort);
        _closePort(filePort);
        _closePort(donePort);
        _closePort(errorPort);
        _closePort(closePortsPort);
      });

      // Send the listing parameters to the isolate.
      port.send(listingParameters, closePortsPort.toSendPort());
    });
  }

  void setDirHandler(void dirHandler(String dir)) {
    _dirHandler = dirHandler;
  }

  void setFileHandler(void fileHandler(String file)) {
    _fileHandler = fileHandler;
  }

  void setDoneHandler(void doneHandler(bool completed)) {
    _doneHandler = doneHandler;
  }

  void setErrorHandler(void errorHandler(String error)) {
    _errorHandler = errorHandler;
  }

  void _closePort(ReceivePort port) {
    if (port !== null) {
      port.close();
    }
  }

  var _dirHandler;
  var _fileHandler;
  var _doneHandler;
  var _errorHandler;

  String _dir;
}
