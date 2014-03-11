// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library service_html;

import 'dart:async';
import 'dart:convert';
import 'dart:html';

import 'package:logging/logging.dart';
import 'package:observatory/service.dart';

// Export the service library.
export 'package:observatory/service.dart';

class HttpVM extends VM {
  final String address;

  HttpVM(this.address) : super();

  Future<String> getString(String id) {
    Logger.root.info('Fetching $id from $address');
    return HttpRequest.getString(address + id).catchError((error) {
      // If we get an error here, the network request has failed.
      Logger.root.severe('HttpRequest.getString failed.');
      return JSON.encode({
          'type': 'Error',
          'id': '',
          'kind': 'NetworkError',
          'message': 'Could not connect to service. Check that you started the'
                     ' VM with the following flags:\n --enable-vm-service'
                    ' --pin-isolates'
        });
    });
  }
}

class DartiumVM extends VM {
  final Map _outstandingRequests = new Map();
  int _requestSerial = 0;

  DartiumVM() : super() {
    window.onMessage.listen(_messageHandler);
    Logger.root.info('Connected to DartiumVM');
  }

  void _messageHandler(msg) {
    var id = msg.data['id'];
    var name = msg.data['name'];
    var data = msg.data['data'];
    if (name != 'observatoryData') {
      return;
    }
    var completer = _outstandingRequests[id];
    assert(completer != null);
    _outstandingRequests.remove(id);
    completer.complete(data);
  }

  Future<String> getString(String path) {
    var idString = '$_requestSerial';
    Map message = {};
    message['id'] = idString;
    message['method'] = 'observatoryQuery';
    message['query'] = '/$path';
    _requestSerial++;
    var completer = new Completer();
    _outstandingRequests[idString] = completer;
    window.parent.postMessage(JSON.encode(message), '*');
    return completer.future;
  }
}
