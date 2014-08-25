// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vmservice_test_helper;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:expect/expect.dart';

abstract class ServiceWebSocketRequestHelper {
  final String url;
  final Completer _completer = new Completer();
  WebSocket _socket;

  ServiceWebSocketRequestHelper(this.url);

  // Returns [this] when connected.
  Future connect() {
    return WebSocket.connect(url).then((ws) {
      _socket = ws;
      _socket.listen((message) {
        var map = JSON.decode(message);
        var response = JSON.decode(map['response']);
        onResponse(map['seq'], response);
      });
      return this;
    });
  }

  void complete() {
    _completer.complete(this);
  }

  Future get completed => _completer.future;

  // Must call complete.
  void onResponse(var seq, Map response);
  void runTest();

  Future sendMessage(var seq, String request) {
    var map = {
      'seq': seq,
      'request': request
    };
    var message = JSON.encode(map);
    _socket.add(message);
    return _completer.future;
  }
}

abstract class VmServiceRequestHelper {
  final Uri uri;
  final HttpClient client;

  VmServiceRequestHelper(String url) :
      uri = Uri.parse(url),
      client = new HttpClient();

  Future makeRequest() {
    print('** GET: $uri');
    return client.getUrl(uri)
      .then((HttpClientRequest request) => request.close())
      .then((HttpClientResponse response) {
        return response
            .fold(new BytesBuilder(), (b, d) => b..add(d))
            .then((builder) {
              return _requestCompleted(builder.takeBytes(), response);
            });
      }).catchError((error) {
        onRequestFailed(error);
      });
  }

  Future _requestCompleted(List<int> data, HttpClientResponse response) {
    Expect.equals(200, response.statusCode, 'Invalid HTTP Status Code');
    var replyAsString;
    try {
      replyAsString = UTF8.decode(data);
    } catch (e) {
      onRequestFailed(e);
      return null;
    }
    print('** Response: $replyAsString');
    var reply;
    try {
      reply = JSON.decode(replyAsString);
    } catch (e, trace) {
      onRequestFailed(e);
      return null;
    }
    if (reply is! Map) {
      onRequestFailed('Reply was not a map: $reply');
      return null;
    }
    if (reply['type'] == null) {
      onRequestFailed('Reply does not contain a type key: $reply');
      return null;
    }
    var r;
    try {
      r = onRequestCompleted(reply);
    } catch (e) {
      r = onRequestFailed('Test callback failed: $e');
    }
    return r;
  }

  Future onRequestFailed(dynamic error) {
    Expect.fail('Failed to make request: $error');
  }

  Future onRequestCompleted(Map response);
}

class TestLauncher {
  final String script;
  Process process;

  TestLauncher(this.script);

  String get scriptPath {
    var dartScript = Platform.script.toFilePath();
    var splitPoint = dartScript.lastIndexOf(Platform.pathSeparator);
    var scriptDirectory = dartScript.substring(0, splitPoint);
    return scriptDirectory + Platform.pathSeparator + script;
  }

  Future<int> launch() {
    String dartExecutable = Platform.executable;
    print('** Launching $scriptPath');
    return Process.start(dartExecutable,
                         ['--enable-vm-service:0', scriptPath]).then((p) {

      Completer completer = new Completer();
      process = p;
      var portNumber;
      var blank;
      var first = true;
      process.stdout.transform(UTF8.decoder)
                    .transform(new LineSplitter()).listen((line) {
        if (line.startsWith('Observatory listening on http://')) {
          RegExp portExp = new RegExp(r"\d+.\d+.\d+.\d+:(\d+)");
          var port = portExp.firstMatch(line).group(1);
          portNumber = int.parse(port);
        }
        if (line == '') {
          // Received blank line.
          blank = true;
        }
        if (portNumber != null && blank == true && first == true) {
          completer.complete(portNumber);
          // Stop repeat completions.
          first = false;
          print('** Signaled to run test queries on $portNumber');
        }
        print(line);
      });
      process.stderr.transform(UTF8.decoder)
                    .transform(new LineSplitter()).listen((line) {
        print(line);
      });
      process.exitCode.then((code) {
        Expect.equals(0, code, 'Launched dart executable exited with error.');
      });
      return completer.future;
    });
  }

  void requestExit() {
    print('** Requesting script to exit.');
    process.stdin.add([32, 13, 10]);
  }
}

class VMTester {
  final Map vm;

  VMTester(this.vm) {
    // The reply is a VM.
    Expect.equals('VM', vm['type'], 'Not an VM.');
  }

  void checkIsolateCount(int n) {
    Expect.equals(n, vm['isolates'].length, 'Isolate count not $n');
  }

  void checkIsolateIdExists(String id) {
    var exists = false;
    vm['isolates'].forEach((isolate) {
      if (isolate['id'] == id) {
        exists = true;
      }
    });
    Expect.isTrue(exists, 'No isolate with id: $id');
  }

  String getIsolateId(int index) {
    return vm['isolates'][index]['id'];
  }
}

class ClassTableHelper {
  final Map classTable;

  ClassTableHelper(this.classTable) {
    Expect.equals('ClassList', classTable['type'], 'Not a ClassTable.');
  }

  bool classExists(String name) {
    List members = classTable['members'];
    for (var i = 0; i < members.length; i++) {
      Map klass = members[i];
      if (klass['name'] == name) {
        return true;
      }
    }
    return false;
  }

  String classId(String name) {
    List members = classTable['members'];
    for (var i = 0; i < members.length; i++) {
      Map klass = members[i];
      if (klass['name'] == name) {
        return klass['id'];
      }
    }
    return null;
  }
}

class FieldRequestHelper extends VmServiceRequestHelper {
  FieldRequestHelper(port, isolate_id, field_id) :
      super('http://127.0.0.1:$port/$isolate_id/$field_id');
  Map field;
  onRequestCompleted(Map reply) {
    Expect.equals('Field', reply['type']);
    field = reply;
    return new Future.value(this);
  }
}

class ClassFieldRequestHelper extends VmServiceRequestHelper {
  final List<String> fieldNames;
  int port_;
  String isolate_id_;
  ClassFieldRequestHelper(port, isolate_id, class_id, this.fieldNames) :
      super('http://127.0.0.1:$port/$isolate_id/$class_id') {
    port_ = port;
    isolate_id_ = isolate_id;
  }
  final Map<String, Map> fields = new Map<String, Map>();

  onRequestCompleted(Map reply) {
    Expect.equals('Class', reply['type']);
    List<Map> class_fields = reply['fields'];
    List<Future> requests = new List<Future>();
    fieldNames.forEach((fn) {
      class_fields.forEach((f) {
        if (f['name'] == fn) {
          var request = new FieldRequestHelper(port_, isolate_id_, f['id']);
          requests.add(request.makeRequest());
        }
      });
    });
    return Future.wait(requests).then((a) {
      a.forEach((FieldRequestHelper field) {
        fields[field.field['name']] = field.field;
      });
      return this;
    });
  }
}
