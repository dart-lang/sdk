// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that the behavior of forwarding stubs to call noSuchMethod is
// restricted to public members and members from the same library; forwarding
// stubs for private members from other libraries always throw.
//
// Without this, field promotion would not be sound.  For example, in the code
// below, each attempt to get `_i` from an instance of class `B` would result in
// an invocation of `B.noSuchMethod`, so evaluation of `a._i` at (1) would yield
// `0`, and evaluation of `a._i` at (2) would yield `null`.
//
//     main.dart:
//       import 'other.dart';
//       class B implements A {
//         bool b = false;
//         @override
//         dynamic noSuchMethod(Invocation invocation) => (b = !b) ? 0 : null;
//       }
//       main() => foo(new B());
//     other.dart:
//       class A {
//         final int? _i;
//         A(this._i);
//       }
//       void foo(A a) {
//         if (a._i != null) { // (1)
//           print(a._i + 1);  // (2)
//         }
//       }
//
// Whereas with the restriction, any attempt to get `_i` from an instance of
// class `B` would result in an exception, so the code would never reach (2).
//
// Since this behavior involves interactions among libraries, we have to think
// carefully about how it is affected by language versioning.  There are two
// issues to consider:
//
// 1. Should the forwarding stub throw even if the language feature
//    "inference-update-2" is disabled in the library containing the class
//    that's causing the forwarding stub to be generated?  We need to answer
//    this question with a "yes", otherwise a class declaration in a library
//    with an older language version could still ruin the soundness of field
//    promotion in some other library.
//
// 2. Should the forwarding stub throw even if the language feature
//    "inference-update-2" is disabled in the library containing the private
//    member in question?  Our answer to this question doesn't affect soundness,
//    because field promotion can't happen in libraries for which the language
//    feature is disabled.  However, we still answer "yes", because otherwise an
//    attempt to upgrade to a newer language version in one library might cause
//    unexpected behavior changes in other libraries that import it, and we
//    don't want that to happen.
//
// This file covers cases where the language feature "inference-update-2" is
// disabled.

// @dart=2.17

import 'package:expect/expect.dart';

import 'no_such_method_restriction_disabled_lib.dart' as lib;

class Interface {
  static int interfaceCount = 0;

  int _privateField = 100;

  int get _privateGetter {
    interfaceCount++;
    return 101;
  }

  set _privateSetter(int value) {
    interfaceCount++;
  }

  int _privateMethod() {
    interfaceCount++;
    return 102;
  }

  int publicField = 103;

  int get publicGetter {
    interfaceCount++;
    return 104;
  }

  set publicSetter(int value) {
    interfaceCount++;
  }

  int publicMethod() {
    interfaceCount++;
    return 105;
  }

  static int getPrivateField(Interface x) => x._privateField;

  static void setPrivateField(Interface x) => x._privateField = 106;

  static int callPrivateGetter(Interface x) => x._privateGetter;

  static void callPrivateSetter(Interface x) => x._privateSetter = 107;

  static int callPrivateMethod(Interface x) => x._privateMethod();

  static int getPublicField(Interface x) => x.publicField;

  static void setPublicField(Interface x) => x.publicField = 108;

  static int callPublicGetter(Interface x) => x.publicGetter;

  static void callPublicSetter(Interface x) => x.publicSetter = 109;

  static int callPublicMethod(Interface x) => x.publicMethod();
}

class Dynamic {
  static int getPrivateField(dynamic x) => x._privateField;

  static void setPrivateField(dynamic x) => x._privateField = 103;

  static int callPrivateGetter(dynamic x) => x._privateGetter;

  static void callPrivateSetter(dynamic x) => x._privateSetter = 104;

  static int callPrivateMethod(dynamic x) => x._privateMethod();

  static int getPublicField(dynamic x) => x.publicField;

  static void setPublicField(dynamic x) => x.publicField = 108;

  static int callPublicGetter(dynamic x) => x.publicGetter;

  static void callPublicSetter(dynamic x) => x.publicSetter = 109;

  static int callPublicMethod(dynamic x) => x.publicMethod();
}

/// The tests in this class cover the case where the members are in the same
/// library as the forwarding stubs.  All member invocations should be
/// dispatched to noSuchMethod.
class Local implements Interface {
  int _localNsmCount = 0;

  @override
  noSuchMethod(Invocation invocation) {
    return _localNsmCount++;
  }

  static void testPrivate() {
    var x = Local();
    Expect.equals(0, Interface.getPrivateField(x));
    Expect.equals(1, x._localNsmCount);
    Interface.setPrivateField(x);
    Expect.equals(2, x._localNsmCount);
    Expect.equals(2, Interface.callPrivateGetter(x));
    Expect.equals(3, x._localNsmCount);
    Interface.callPrivateSetter(x);
    Expect.equals(4, x._localNsmCount);
    Expect.equals(4, Interface.callPrivateMethod(x));
    Expect.equals(5, x._localNsmCount);
    Expect.equals(0, Interface.interfaceCount);
  }

  static void testPublic() {
    var x = Local();
    Expect.equals(0, Interface.getPublicField(x));
    Expect.equals(1, x._localNsmCount);
    Interface.setPublicField(x);
    Expect.equals(2, x._localNsmCount);
    Expect.equals(2, Interface.callPublicGetter(x));
    Expect.equals(3, x._localNsmCount);
    Interface.callPublicSetter(x);
    Expect.equals(4, x._localNsmCount);
    Expect.equals(4, Interface.callPublicMethod(x));
    Expect.equals(5, x._localNsmCount);
    Expect.equals(0, Interface.interfaceCount);
  }

  static void testPrivateDynamic() {
    var x = Local();
    Expect.equals(0, Dynamic.getPrivateField(x));
    Expect.equals(1, x._localNsmCount);
    Dynamic.setPrivateField(x);
    Expect.equals(2, x._localNsmCount);
    Expect.equals(2, Dynamic.callPrivateGetter(x));
    Expect.equals(3, x._localNsmCount);
    Dynamic.callPrivateSetter(x);
    Expect.equals(4, x._localNsmCount);
    Expect.equals(4, Dynamic.callPrivateMethod(x));
    Expect.equals(5, x._localNsmCount);
  }

  static void testPublicDynamic() {
    var x = Local();
    Expect.equals(0, Dynamic.getPublicField(x));
    Expect.equals(1, x._localNsmCount);
    Dynamic.setPublicField(x);
    Expect.equals(2, x._localNsmCount);
    Expect.equals(2, Dynamic.callPublicGetter(x));
    Expect.equals(3, x._localNsmCount);
    Dynamic.callPublicSetter(x);
    Expect.equals(4, x._localNsmCount);
    Expect.equals(4, Dynamic.callPublicMethod(x));
    Expect.equals(5, x._localNsmCount);
  }
}

/// The tests in this class cover the case where both noSuchMethod and the other
/// members are in the same library as the forwarding stubs, but that library is
/// not the same as the library containing this class.  All member invocations
/// should be dispatched to noSuchMethod.
class RemoteStubs extends lib.Stubs {
  static void testPrivate() {
    var x = RemoteStubs();
    Expect.equals(0, lib.Interface.getPrivateField(x));
    Expect.equals(1, x.stubsNsmCount);
    lib.Interface.setPrivateField(x);
    Expect.equals(2, x.stubsNsmCount);
    Expect.equals(2, lib.Interface.callPrivateGetter(x));
    Expect.equals(3, x.stubsNsmCount);
    lib.Interface.callPrivateSetter(x);
    Expect.equals(4, x.stubsNsmCount);
    Expect.equals(4, lib.Interface.callPrivateMethod(x));
    Expect.equals(5, x.stubsNsmCount);
    Expect.equals(0, lib.Interface.interfaceCount);
  }

  static void testPublic() {
    var x = RemoteStubs();
    Expect.equals(0, lib.Interface.getPublicField(x));
    Expect.equals(1, x.stubsNsmCount);
    lib.Interface.setPublicField(x);
    Expect.equals(2, x.stubsNsmCount);
    Expect.equals(2, lib.Interface.callPublicGetter(x));
    Expect.equals(3, x.stubsNsmCount);
    lib.Interface.callPublicSetter(x);
    Expect.equals(4, x.stubsNsmCount);
    Expect.equals(4, lib.Interface.callPublicMethod(x));
    Expect.equals(5, x.stubsNsmCount);
    Expect.equals(0, lib.Interface.interfaceCount);
  }

  static void testPrivateDynamic() {
    var x = RemoteStubs();
    Expect.equals(0, lib.Dynamic.getPrivateField(x));
    Expect.equals(1, x.stubsNsmCount);
    lib.Dynamic.setPrivateField(x);
    Expect.equals(2, x.stubsNsmCount);
    Expect.equals(2, lib.Dynamic.callPrivateGetter(x));
    Expect.equals(3, x.stubsNsmCount);
    lib.Dynamic.callPrivateSetter(x);
    Expect.equals(4, x.stubsNsmCount);
    Expect.equals(4, lib.Dynamic.callPrivateMethod(x));
    Expect.equals(5, x.stubsNsmCount);
  }

  static void testPublicDynamic() {
    var x = RemoteStubs();
    Expect.equals(0, lib.Dynamic.getPublicField(x));
    Expect.equals(1, x.stubsNsmCount);
    lib.Dynamic.setPublicField(x);
    Expect.equals(2, x.stubsNsmCount);
    Expect.equals(2, lib.Dynamic.callPublicGetter(x));
    Expect.equals(3, x.stubsNsmCount);
    lib.Dynamic.callPublicSetter(x);
    Expect.equals(4, x.stubsNsmCount);
    Expect.equals(4, lib.Dynamic.callPublicMethod(x));
    Expect.equals(5, x.stubsNsmCount);
  }
}

/// The tests in this class cover the case where noSuchMember is local, but the
/// other members are in a different library from the forwarding stubs.  All
/// public member invocations should be dispatched to noSuchMethod; all private
/// member invocations should throw.
class LocalNsm implements lib.Interface {
  int _localNsmCount = 0;

  @override
  noSuchMethod(Invocation invocation) {
    return _localNsmCount++;
  }

  static void testPrivate() {
    var x = LocalNsm();
    Expect.throwsNoSuchMethodError(() => lib.Interface.getPrivateField(x));
    Expect.throwsNoSuchMethodError(() => lib.Interface.setPrivateField(x));
    Expect.throwsNoSuchMethodError(() => lib.Interface.callPrivateGetter(x));
    Expect.throwsNoSuchMethodError(() => lib.Interface.callPrivateSetter(x));
    Expect.throwsNoSuchMethodError(() => lib.Interface.callPrivateMethod(x));
    Expect.equals(0, x._localNsmCount);
    Expect.equals(0, lib.Interface.interfaceCount);
  }

  static void testPublic() {
    var x = LocalNsm();
    Expect.equals(0, lib.Interface.getPublicField(x));
    Expect.equals(1, x._localNsmCount);
    lib.Interface.setPublicField(x);
    Expect.equals(2, x._localNsmCount);
    Expect.equals(2, lib.Interface.callPublicGetter(x));
    Expect.equals(3, x._localNsmCount);
    lib.Interface.callPublicSetter(x);
    Expect.equals(4, x._localNsmCount);
    Expect.equals(4, lib.Interface.callPublicMethod(x));
    Expect.equals(5, x._localNsmCount);
    Expect.equals(0, lib.Interface.interfaceCount);
  }

  static void testPrivateDynamic() {
    var x = LocalNsm();
    Expect.throwsNoSuchMethodError(() => lib.Dynamic.getPrivateField(x));
    Expect.throwsNoSuchMethodError(() => lib.Dynamic.setPrivateField(x));
    Expect.throwsNoSuchMethodError(() => lib.Dynamic.callPrivateGetter(x));
    Expect.throwsNoSuchMethodError(() => lib.Dynamic.callPrivateSetter(x));
    Expect.throwsNoSuchMethodError(() => lib.Dynamic.callPrivateMethod(x));
    Expect.equals(0, x._localNsmCount);
  }

  static void testPublicDynamic() {
    var x = LocalNsm();
    Expect.equals(0, lib.Dynamic.getPublicField(x));
    Expect.equals(1, x._localNsmCount);
    lib.Dynamic.setPublicField(x);
    Expect.equals(2, x._localNsmCount);
    Expect.equals(2, lib.Dynamic.callPublicGetter(x));
    Expect.equals(3, x._localNsmCount);
    lib.Dynamic.callPublicSetter(x);
    Expect.equals(4, x._localNsmCount);
    Expect.equals(4, lib.Dynamic.callPublicMethod(x));
    Expect.equals(5, x._localNsmCount);
  }
}

/// The tests in this class cover the case where both noSuchMember and the other
/// members are in a different library from the forwarding stubs.  All public
/// member invocations should be dispatched to noSuchMethod; all private member
/// invocations should throw.
class RemoteNsm extends lib.Nsm implements lib.Interface {
  static void testPrivate() {
    var x = RemoteNsm();
    Expect.throwsNoSuchMethodError(() => lib.Interface.getPrivateField(x));
    Expect.throwsNoSuchMethodError(() => lib.Interface.setPrivateField(x));
    Expect.throwsNoSuchMethodError(() => lib.Interface.callPrivateGetter(x));
    Expect.throwsNoSuchMethodError(() => lib.Interface.callPrivateSetter(x));
    Expect.throwsNoSuchMethodError(() => lib.Interface.callPrivateMethod(x));
    Expect.equals(0, x.otherNsmCount);
    Expect.equals(0, lib.Interface.interfaceCount);
  }

  static void testPublic() {
    var x = RemoteNsm();
    Expect.equals(0, lib.Interface.getPublicField(x));
    Expect.equals(1, x.otherNsmCount);
    lib.Interface.setPublicField(x);
    Expect.equals(2, x.otherNsmCount);
    Expect.equals(2, lib.Interface.callPublicGetter(x));
    Expect.equals(3, x.otherNsmCount);
    lib.Interface.callPublicSetter(x);
    Expect.equals(4, x.otherNsmCount);
    Expect.equals(4, lib.Interface.callPublicMethod(x));
    Expect.equals(5, x.otherNsmCount);
    Expect.equals(0, lib.Interface.interfaceCount);
  }

  static void testPrivateDynamic() {
    var x = RemoteNsm();
    Expect.throwsNoSuchMethodError(() => lib.Dynamic.getPrivateField(x));
    Expect.throwsNoSuchMethodError(() => lib.Dynamic.setPrivateField(x));
    Expect.throwsNoSuchMethodError(() => lib.Dynamic.callPrivateGetter(x));
    Expect.throwsNoSuchMethodError(() => lib.Dynamic.callPrivateSetter(x));
    Expect.throwsNoSuchMethodError(() => lib.Dynamic.callPrivateMethod(x));
    Expect.equals(0, x.otherNsmCount);
  }

  static void testPublicDynamic() {
    var x = RemoteNsm();
    Expect.equals(0, lib.Dynamic.getPublicField(x));
    Expect.equals(1, x.otherNsmCount);
    lib.Dynamic.setPublicField(x);
    Expect.equals(2, x.otherNsmCount);
    Expect.equals(2, lib.Dynamic.callPublicGetter(x));
    Expect.equals(3, x.otherNsmCount);
    lib.Dynamic.callPublicSetter(x);
    Expect.equals(4, x.otherNsmCount);
    Expect.equals(4, lib.Dynamic.callPublicMethod(x));
    Expect.equals(5, x.otherNsmCount);
  }
}

main() {
  Local.testPrivate();
  Local.testPublic();
  Local.testPrivateDynamic();
  Local.testPublicDynamic();
  RemoteStubs.testPrivate();
  RemoteStubs.testPublic();
  RemoteStubs.testPrivateDynamic();
  RemoteStubs.testPublicDynamic();
  LocalNsm.testPrivate();
  LocalNsm.testPublic();
  LocalNsm.testPrivateDynamic();
  LocalNsm.testPublicDynamic();
  RemoteNsm.testPrivate();
  RemoteNsm.testPublic();
  RemoteNsm.testPrivateDynamic();
  RemoteNsm.testPublicDynamic();
}
