// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:isolate';

void main(List<String> args, SendPort sendPort) {
  var receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);
  receivePort.listen((data) async {
    var requestTime = DateTime.now().millisecondsSinceEpoch;
    var requestMap = data as Map<String, Object>;
    var id = requestMap["id"];
    var method = requestMap["method"];

    if (method == "plugin.versionCheck") {
      var jsonObject = <String, Object>{};
      jsonObject["id"] = id!;
      jsonObject["requestTime"] = requestTime;
      Map<String, Object> resultData = {};
      resultData["isCompatible"] = true;
      resultData["name"] = "benchmark_helper_plugin";
      resultData["version"] = "0.0.1";
      resultData["interestingFiles"] = ["**/*.dart"];
      jsonObject["result"] = resultData;
      sendPort.send(jsonObject);
    } else {
      await Future.delayed(const Duration(seconds: 1));
      var jsonObject = <String, Object>{};
      jsonObject["id"] = id!;
      jsonObject["error"] = "too slow working on $method";
      jsonObject["requestTime"] = requestTime;
      sendPort.send(jsonObject);
    }
  });
}
