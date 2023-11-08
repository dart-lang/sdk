// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CloseSinksTest);
  });
}

@reflectiveTest
class CloseSinksTest extends LintRuleTest {
  @override
  String get lintRule => 'close_sinks';

  test_field_closed() async {
    await assertNoDiagnostics(r'''
import 'dart:io';
class C {
  IOSink _sink;

  C(this._sink);

  void init() {
    _sink = File('').openWrite();
  }

  void dispose(filename) {
    _sink.close();
  }
}
''');
  }

  test_field_closed_explicitThis() async {
    await assertNoDiagnostics(r'''
import 'dart:io';
class C {
  IOSink _sink;

  C(this._sink);

  void m1(filename) {
    _sink = File(filename).openWrite();
  }

  void m2(filename) {
    this._sink.close();
  }
}
''');
  }

  test_field_initializedFromExistingSink_explicitThis_notClosed() async {
    await assertNoDiagnostics(r'''
import 'dart:io';
class C {
  // ignore: unused_field
  IOSink _sink;

  C(this._sink);

  void m(IOSink sink) {
    this._sink = sink;
  }
}
''');
  }

  test_field_initializedFromExistingSink_notClosed() async {
    await assertNoDiagnostics(r'''
import 'dart:io';
class C {
  // ignore: unused_field
  late IOSink _sink;

  void m(IOSink sink) {
    _sink = sink;
  }
}
''');
  }

  test_field_initializedInConstructorInitializer_fromExistingSink() async {
    await assertNoDiagnostics(r'''
import 'dart:io';
class C {
  // ignore: unused_field
  final IOSink _sink;

  C(IOSink sink) : this._sink = sink;
}
''');
  }

  test_field_initializedInFieldFormalParameter() async {
    await assertNoDiagnostics(r'''
import 'dart:io';
class C {
  // ignore: unused_field
  final IOSink _sink;

  C(this._sink);
}
''');
  }

  test_field_initializedInMethod_notClosed() async {
    await assertDiagnostics(r'''
import 'dart:io';
class C {
  // ignore: unused_field
  late IOSink _sink;
  void init() {
    _sink = File('').openWrite();
  }
}
''', [
      lint(68, 5),
    ]);
  }

  test_localVariable_closed() async {
    await assertNoDiagnostics(r'''
import 'dart:io';
void f() {
  IOSink sink = File('').openWrite();
  sink.close();
}
''');
  }

  test_localVariable_inFunction_notInitialized() async {
    await assertDiagnostics(r'''
import 'dart:io';
void someFunction() {
  IOSink sink;
}
''', [
      lint(49, 4),
    ]);
  }

  test_localVariable_inMethod_returned_notClosed() async {
    await assertNoDiagnostics(r'''
import 'dart:io';
class C {
  IOSink m(String filename) {
    IOSink sink = File(filename).openWrite();
    return sink;
  }
}
''');
  }

  test_socket_destroyed() async {
    await assertNoDiagnostics(r'''
import 'dart:io';
class C {
  Socket _socket;

  C(this._socket);

  Future m1() async {
    _socket = await Socket.connect(null /*address*/, 1234);
  }

  void m2() {
    _socket.destroy();
  }
}
''');
  }
}
