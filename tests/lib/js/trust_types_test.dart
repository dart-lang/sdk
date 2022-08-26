// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that the [trustTypes] annotation has the same semantics as the older
// style of js interop.

import 'package:js/js.dart';
import 'package:expect/expect.dart';

class NonExistent {}

@JS()
@staticInterop
@trustTypes
class TrustMe {
  external factory TrustMe();
}

extension TrustMeExtension on TrustMe {
  external List<NonExistent> get foos;
  external List<NonExistent> callFoos();
  external List<NonExistent> callFoos1(int ignored);
  external List<NonExistent> callFoos2(int ignored1, int ignored2);
  external List<NonExistent> callFoos3(
      int ignored1, int ignored2, int ignored3);
  external List<NonExistent> callFoos4(
      int ignored1, int ignored2, int ignored3, int ignored4);
  external List<NonExistent> callFoos5(
      int ignored1, int ignored2, int ignored3, int ignored4, int ignored5);
  external String get fooPrimitive;
}

@JS()
external void eval(String code);

void main() {
  eval(r'''
      TrustMe = function TrustMe() {
        this.foos = 'not a list 1';
        this.fooPrimitive = 5;
        this.callFoos = function() {
          return 'not a list 2';
        }
        this.callFoos1 = function(a) {
          return 'not a list 3';
        }
        this.callFoos2 = function(a, b) {
          return 'not a list 4';
        }
        this.callFoos3 = function(a, b, c) {
          return 'not a list 5';
        }
        this.callFoos4 = function(a, b, c, d) {
          return 'not a list 6';
        }
        this.callFoos5 = function(a, b, c, d, e) {
          return 'not a list 7';
        }
      }
      ''');
  final trusted = TrustMe();
  Expect.equals('not a list 1', trusted.foos.toString());
  Expect.equals('not a list 2', trusted.callFoos().toString());
  Expect.equals('not a list 3', trusted.callFoos1(1).toString());
  Expect.equals('not a list 4', trusted.callFoos2(1, 1).toString());
  Expect.equals('not a list 5', trusted.callFoos3(1, 1, 1).toString());
  Expect.equals('not a list 6', trusted.callFoos4(1, 1, 1, 1).toString());

  final falseList = trusted.callFoos5(1, 1, 1, 1, 1);
  Expect.equals('not a list 7', falseList.toString());
  Expect.throws(() => falseList.removeAt(0));

  final falseString = trusted.fooPrimitive;
  Expect.equals(5, falseString);
  Expect.throws(() => falseString.codeUnitAt(0));
}
