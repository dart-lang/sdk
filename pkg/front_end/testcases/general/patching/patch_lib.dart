// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore: import_internal_library
import 'dart:_internal';

@patch
int get topLevelGetter => 42;

int get _injectedTopLevelGetter => 42;

@patch
void set topLevelSetter(int value) {}

void set _injectedTopLevelSetter(int value) {}

@patch
void topLevelMethod(int value) {}

void _injectedTopLevelMethod(int value) {
  _injectedTopLevelSetter = _injectedTopLevelGetter;
  _injectedTopLevelMethod(42);
  _injectedTopLevelMethod;
  var i = _InjectedClass(42);
  _InjectedClass.new;
  _InjectedClass.redirecting(42);
  _InjectedClass.redirecting;
  _InjectedClass.factory(42);
  _InjectedClass.factory;
  _InjectedClass.redirectingFactory(42);
  _InjectedClass.redirectingFactory;
  i.instanceSetter = i.instanceGetter;
  i.instanceMethod(42);
  i.instanceMethod;
  _InjectedClass.staticSetter = _InjectedClass.staticGetter;
  _InjectedClass.staticMethod(42);
  _InjectedClass.staticMethod;
  var c = Class(42);
  Class._injectedGenerative(42);
  Class._injectedGenerative;
  Class._injectedRedirecting(42);
  Class._injectedRedirecting;
  Class._injectedFactory(42);
  Class._injectedFactory;
  Class._injectedRedirectingFactory(42);
  Class._injectedRedirectingFactory;
  c._injectedInstanceSetter = c._injectedInstanceGetter;
  c._injectedInstanceMethod(42);
  c._injectedInstanceMethod;
  Class._injectedStaticSetter = Class._injectedStaticGetter;
  Class._injectedStaticMethod(42);
  Class._injectedStaticMethod;
  c._injectedExtensionInstanceSetter = c._injectedExtensionInstanceGetter;
  c._injectedExtensionInstanceMethod(42);
  c._injectedExtensionInstanceMethod;
  Extension._injectedExtensionStaticSetter =
      Extension._injectedExtensionStaticGetter;
  Extension._injectedExtensionStaticMethod(42);
  Extension._injectedExtensionStaticMethod;
}

@patch
class Class {
  @patch
  Class(int value);

  Class._injectedGenerative(int value);

  @patch
  Class.redirecting(int value) : this(value);

  Class._injectedRedirecting(int value) : this(value);

  @patch
  factory Class.factory(int value) => Class(value);

  factory Class._injectedFactory(int value) => Class(value);

  @patch
  factory Class.redirectingFactory(int value) = Class;

  factory Class._injectedRedirectingFactory(int value) = Class;

  @patch
  int get instanceGetter => 42;

  int get _injectedInstanceGetter => 42;

  @patch
  void set instanceSetter(int value) {}

  void set _injectedInstanceSetter(int value) {}

  @patch
  void instanceMethod(int value) {}

  void _injectedInstanceMethod(int value) {}

  @patch
  Class operator +(Class a) => this;

  @patch
  static int get staticGetter => 42;

  static int get _injectedStaticGetter => 42;

  @patch
  static void set staticSetter(int value) {}

  static void set _injectedStaticSetter(int value) {}

  @patch
  static void staticMethod(int value) {}

  static void _injectedStaticMethod(int value) {}
}

class _InjectedClass {
  _InjectedClass(int value);
  _InjectedClass.redirecting(int value) : this(value);
  factory _InjectedClass.factory(int value) => _InjectedClass(value);
  factory _InjectedClass.redirectingFactory(int value) = _InjectedClass;
  int instanceField = 42;
  int get instanceGetter => 42;
  void set instanceSetter(int value) {}
  void instanceMethod(int value) {}
  static int staticField = 42;
  static int get staticGetter => 42;
  static void set staticSetter(int value) {}
  static void staticMethod(int value) {}
}

@patch
extension Extension on Class {
  @patch
  int get extensionInstanceGetter => 42;

  int get _injectedExtensionInstanceGetter => 42;

  @patch
  void set extensionInstanceSetter(int value) {}

  void set _injectedExtensionInstanceSetter(int value) {}

  @patch
  void extensionInstanceMethod(int value) {}

  void _injectedExtensionInstanceMethod(int value) {}

  @patch
  Class operator -(Class a) => this;

  static int _injectedExtensionStaticField = 42;

  @patch
  static int get extensionStaticGetter => 42;

  static int get _injectedExtensionStaticGetter => 42;

  @patch
  static void set extensionStaticSetter(int value) {}

  static void set _injectedExtensionStaticSetter(int value) {}

  @patch
  static void extensionStaticMethod(int value) {}

  static void _injectedExtensionStaticMethod(int value) {}
}
