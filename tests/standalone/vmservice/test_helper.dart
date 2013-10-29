// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vmservice_test_helper;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:expect/expect.dart';

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
    } catch (e) {
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
    var dartScript = Platform.script;
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
        if (line.startsWith('VmService listening on port ')) {
          RegExp portExp = new RegExp(r"\d+");
          var port = portExp.stringMatch(line);
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

class IsolateListTester {
  final Map isolateList;

  IsolateListTester(this.isolateList) {
    // The reply is an IsolateList.
    Expect.equals('IsolateList', isolateList['type'], 'Not an IsolateList.');
  }

  void checkIsolateCount(int n) {
    Expect.equals(n, isolateList['members'].length, 'Isolate count not $n');
  }

  void checkIsolateIdExists(int id) {
    var exists = false;
    isolateList['members'].forEach((isolate) {
      if (isolate['id'] == id) {
        exists = true;
      }
    });
    Expect.isTrue(exists, 'No isolate with id: $id');
  }

  int checkIsolateNameContains(String name) {
    var exists = false;
    int id;
    isolateList['members'].forEach((isolate) {
      if (isolate['name'].contains(name)) {
        exists = true;
        id = isolate['id'];
      }
    });
    Expect.isTrue(exists, 'No isolate with name: $name');
    return id;
  }

  void checkIsolateNamePrefix(int id, String name) {
    var exists = false;
    isolateList['members'].forEach((isolate) {
      if (isolate['id'] == id) {
        exists = true;
        Expect.isTrue(isolate['name'].startsWith(name),
                      'Isolate $id does not have name prefix: $name'
                      ' (was ${isolate['name']})');
      }
    });
    Expect.isTrue(exists, 'No isolate with id: $id');
  }
}

class ClassTableHelper {
  final Map classTable;

  ClassTableHelper(this.classTable) {
    Expect.equals('ClassList', classTable['type'], 'Not a ClassTable.');
  }

  bool classExists(String user_name) {
    List members = classTable['members'];
    for (var i = 0; i < members.length; i++) {
      Map klass = members[i];
      if (klass['user_name'] == user_name) {
        return true;
      }
    }
    return false;
  }

  int classId(String user_name) {
    List members = classTable['members'];
    for (var i = 0; i < members.length; i++) {
      Map klass = members[i];
      if (klass['user_name'] == user_name) {
        return klass['id'];
      }
    }
    return -1;
  }
}

class FieldRequestHelper extends VmServiceRequestHelper {
  FieldRequestHelper(port, isolate_id, field_id) :
      super('http://127.0.0.1:$port/isolates/$isolate_id/objects/$field_id');
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
  int isolate_id_;
  ClassFieldRequestHelper(port, isolate_id, class_id, this.fieldNames) :
      super('http://127.0.0.1:$port/isolates/$isolate_id/classes/$class_id') {
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
        if (f['user_name'] == fn) {
          var request = new FieldRequestHelper(port_, isolate_id_, f['id']);
          requests.add(request.makeRequest());
        }
      });
    });
    return Future.wait(requests).then((a) {
      a.forEach((FieldRequestHelper field) {
        fields[field.field['user_name']] = field.field;
      });
      return this;
    });
  }
}
