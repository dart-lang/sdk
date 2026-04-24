// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:developer';
// TODO: https://github.com/dart-lang/webdev/issues/2508
// ignore: deprecated_member_use
import 'dart:html';
// TODO: https://github.com/dart-lang/webdev/issues/2508
// ignore: deprecated_member_use
import 'dart:js';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

part 'part.dart';

// Create a series of top level objects for tests in
// dwds/test/chrome_proxy_service_test.dart

final topLevelList = () {
  final l = List.filled(1001, 5);
  l[4] = 100;
  return l;
}();

final topLevelMap = LinkedHashMap.from(
  Iterable.generate(1001).toList().reversed.toList().asMap(),
);

final myInstance = MyTestClass();

void main() async {
  print(DateFormat());
  // Long running so that we can test the pause / resume behavior.
  Timer.periodic(const Duration(seconds: 1), (_) {});

  print(p.join('Hello', 'World')); // Breakpoint: printHelloWorld

  // long running to test evaluateInFrame
  Timer.periodic(const Duration(seconds: 1), (_) {
    final local = 42;
    print(local); // Breakpoint: printLocal
  });

  context['inspectInstance'] = () {
    inspect(myInstance);
  };

  context['postEvent'] = (String kind) {
    postEvent(kind, {'example': 'data'});
  };

  context['registerExtension'] = (String method) {
    registerExtension(method, (
      String method,
      Map<String, String> parameters,
    ) async {
      return ServiceExtensionResponse.result(jsonEncode(parameters));
    });
  };

  context['registerExtensionWithError'] = (String method) {
    registerExtension(method, (
      String method,
      Map<String, String> parameters,
    ) async {
      return ServiceExtensionResponse.error(
        int.parse(parameters['code']!),
        parameters['details']!,
      );
    });
  };

  context['sendLog'] = (String message) {
    log(message, name: 'testLogCategory');
  };

  context['throwUncaughtException'] = () {
    scheduleMicrotask(() => throw Exception('UncaughtException'));
  };

  Timer.periodic(const Duration(seconds: 1), (timer) {
    printCount(); // Breakpoint: callPrintCount
  });

  Timer.periodic(const Duration(seconds: 1), (_) {
    asyncCall();
  });

  Timer.periodic(const Duration(seconds: 1), (_) {
    throwsException();
  });

  // Register one up front before the proxy connects, the isolate should still
  // recognize this as an available extension.
  registerExtension(
    'ext.hello_world.existing',
    (_, __) => Future.value(ServiceExtensionResponse.error(0, '')),
  );

  window.console.debug('Page Ready');
}

var count = 0;

// An easy location to add a breakpoint.
void printCount() {
  print('The count is ${++count}'); // Breakpoint: inPrintCount
  doSomething();
}

void asyncCall() async {
  final now = DateTime.now();

  await Future.delayed(Duration.zero);

  final then = DateTime.now(); // Breakpoint: asyncCall
  // ignore: unused_local_variable
  final diff = then.difference(now);
}

void throwsException() {
  try {
    throw Exception('new exception');
  } catch (e) {
    // ignore
  }
}

String helloString(String response) => response;

bool helloBool(bool response) => response;

num? helloNum(num? response) => response;

MyTestClass createObject(String message) => MyTestClass(message: message);

String messageFor(MyTestClass instance) => instance.message;

String messagesCombined(MyTestClass a, MyTestClass b) => a.message + b.message;

class MyTestClass {
  final String message;

  String? notFinal;

  static final String staticMessage = 'static';

  static String staticHello() => 'static hello';

  MyTestClass({this.message = 'world'});

  String hello() => message;
}
