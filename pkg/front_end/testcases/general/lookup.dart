// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'lookup.dart' as prefix;
import 'lookup.dart' deferred as deferred;

typedef Typedef<T> = Class<T>;

Class<T> topLevelMember<T>() {
  return new Class<T>();
}

set topLevelSetter(_) {}

var topLevelField;

topLevelTest<S>(parameter) {
  var local;

  parameter; // Ok
  parameter = null; // Ok

  local; // Ok
  local = null; // Ok

  unresolved; // Error
  Class; // Ok
  ExtensionType; // Ok
  Typedef; // Ok
  S; // Ok
  topLevelMember; // Ok
  topLevelField; // Ok

  unresolved = null; // Error
  topLevelSetter = null; // Ok
  topLevelField = null; // Ok

  prefix; // Error
  prefix.unresolved; // Error
  prefix.Class; // Ok
  prefix.ExtensionType; // Ok
  prefix.Typedef; // Ok
  prefix.topLevelMember; // Ok
  prefix.topLevelField; // Ok
  prefix.unresolved = null; // Error
  prefix.topLevelSetter = null; // Ok
  prefix.topLevelField = null; // Ok

  prefix.loadLibrary(); // Error
  deferred.loadLibrary(); // Ok
}

class SuperClass {
  void superMember() {}
  set superSetter(_) {}
  var superField;
}

class Class<T> extends SuperClass {
  void instanceMember() {}
  set instanceSetter(_) {}
  var instanceField;
  static void staticMember() {}
  static set staticSetter(_) {}
  static var staticField;

  Class([parameter]) {
    var local;

    parameter; // Ok
    parameter = null; // Ok

    local; // Ok
    local = null; // Ok

    unresolved; // Error
    Class; // Ok
    ExtensionType; // Ok
    Typedef; // Ok
    T; // Ok
    instanceMember; // Ok
    instanceField; // Ok
    superMember; // Ok
    superField; // Ok
    staticMember; // Ok
    staticField; // Ok
    topLevelMember; // Ok
    topLevelField; // Ok

    unresolved = null; // Error
    topLevelSetter = null; // Ok
    topLevelField = null; // Ok
    superSetter = null; // Ok
    superField = null; // Ok
    instanceSetter = null; // Ok
    instanceField = null; // Ok
    staticSetter = null; // Ok
    staticField = null; // Ok

    prefix; // Error
    prefix.unresolved; // Error
    prefix.Class; // Ok
    prefix.ExtensionType; // Ok
    prefix.Typedef; // Ok
    prefix.topLevelMember; // Ok
    prefix.topLevelField; // Ok
    prefix.unresolved = null; // Error
    prefix.topLevelSetter = null; // Ok
    prefix.topLevelField = null; // Ok
  }

  factory Class.factory([parameter]) {
    var local;

    parameter; // Ok
    parameter = null; // Ok

    local; // Ok
    local = null; // Ok

    unresolved; // Error
    Class; // Ok
    ExtensionType; // Ok
    Typedef; // Ok
    T; // Ok
    instanceMember; // Error
    instanceField; // Error
    superMember; // Error
    superField; // Error
    staticMember; // Ok
    staticField; // Ok
    topLevelMember; // Ok
    topLevelField; // Ok

    unresolved = null; // Error
    topLevelSetter = null; // Ok
    topLevelField = null; // Ok
    superSetter = null; // Error
    superField = null; // Error
    instanceSetter = null; // Error
    instanceField = null; // Error
    staticSetter = null; // Ok
    staticField = null; // Ok

    prefix; // Error
    prefix.unresolved; // Error
    prefix.Class; // Ok
    prefix.ExtensionType; // Ok
    prefix.Typedef; // Ok
    prefix.topLevelMember; // Ok
    prefix.topLevelField; // Ok
    prefix.unresolved = null; // Error
    prefix.topLevelSetter = null; // Ok
    prefix.topLevelField = null; // Ok

    return new Class();
  }

  instanceTest<S>(parameter) {
    var local;

    parameter; // Ok
    parameter = null; // Ok

    local; // Ok
    local = null; // Ok

    unresolved; // Error
    Class; // Ok
    ExtensionType; // Ok
    Typedef; // Ok
    T; // Ok
    S; // Ok
    instanceMember; // Ok
    instanceField; // Ok
    superMember; // Ok
    superField; // Ok
    staticMember; // Ok
    staticField; // Ok
    topLevelMember; // Ok
    topLevelField; // Ok

    unresolved = null; // Error
    topLevelSetter = null; // Ok
    topLevelField = null; // Ok
    superSetter = null; // Ok
    superField = null; // Ok
    instanceSetter = null; // Ok
    instanceField = null; // Ok
    staticSetter = null; // Ok
    staticField = null; // Ok

    prefix; // Error
    prefix.unresolved; // Error
    prefix.Class; // Ok
    prefix.ExtensionType; // Ok
    prefix.Typedef; // Ok
    prefix.topLevelMember; // Ok
    prefix.topLevelField; // Ok
    prefix.unresolved = null; // Error
    prefix.topLevelSetter = null; // Ok
    prefix.topLevelField = null; // Ok
  }

  static staticTest<S>(parameter) {
    var local;

    parameter; // Ok
    parameter = null; // Ok

    local; // Ok
    local = null; // Ok

    unresolved; // Error
    Class; // Ok
    ExtensionType; // Ok
    Typedef; // Ok
    T; // Error
    S; // Ok
    instanceMember; // Error
    instanceField; // Error
    superMember; // Error
    superField; // Error
    staticMember; // Ok
    staticField; // Ok
    topLevelMember; // Ok
    topLevelField; // Ok

    unresolved = null; // Error
    topLevelSetter = null; // Ok
    topLevelField = null; // Ok
    superSetter = null; // Error
    superField = null; // Error
    instanceSetter = null; // Error
    instanceField = null; // Error
    staticSetter = null; // Ok
    staticField = null; // Ok

    prefix; // Error
    prefix.unresolved; // Error
    prefix.Class; // Ok
    prefix.ExtensionType; // Ok
    prefix.Typedef; // Ok
    prefix.topLevelMember; // Ok
    prefix.topLevelField; // Ok
    prefix.unresolved = null; // Error
    prefix.topLevelSetter = null; // Ok
    prefix.topLevelField = null; // Ok
  }
}

extension Extension<T> on Class<T> {
  void extensionInstanceMember() {}
  set extensionInstanceSetter(_) {}
  static void extensionStaticMember() {}
  static set extensionStaticSetter(_) {}

  instanceTest<S>(parameter) {
    var local;

    parameter; // Ok
    parameter = null; // Ok

    local; // Ok
    local = null; // Ok

    unresolved; // Error
    Class; // Ok
    ExtensionType; // Ok
    Typedef; // Ok
    T; // Ok
    S; // Ok
    instanceMember; // Ok
    instanceField; // Ok
    superMember; // Ok
    superField; // Ok
    extensionInstanceMember; // Ok
    extensionStaticMember; // Ok
    topLevelMember; // Ok
    topLevelField; // Ok

    unresolved = null; // Error
    topLevelSetter = null; // Ok
    topLevelField = null; // Ok
    instanceSetter = null; // Ok
    instanceField = null; // Ok
    superSetter = null; // Ok
    superField = null; // Ok
    extensionInstanceSetter = null; // Ok
    extensionStaticSetter = null; // Ok

    prefix; // Error
    prefix.unresolved; // Error
    prefix.Class; // Ok
    prefix.ExtensionType; // Ok
    prefix.Typedef; // Ok
    prefix.topLevelMember; // Ok
    prefix.topLevelField; // Ok
    prefix.unresolved = null; // Error
    prefix.topLevelSetter = null; // Ok
    prefix.topLevelField = null; // Ok
  }

  static staticTest<S>(parameter) {
    var local;

    parameter; // Ok
    parameter = null; // Ok

    local; // Ok
    local = null; // Ok

    unresolved; // Error
    Class; // Ok
    ExtensionType; // Ok
    Typedef; // Ok
    T; // Error
    S; // Ok
    instanceMember; // Error
    instanceField; // Error
    superMember; // Error
    superField; // Error
    extensionInstanceMember; // Error
    extensionStaticMember; // Ok
    topLevelMember; // Ok
    topLevelField; // Ok

    unresolved = null; // Error
    topLevelSetter = null; // Ok
    topLevelField = null; // Ok
    instanceSetter = null; // Error
    instanceField = null; // Error
    superSetter = null; // Error
    superField = null; // Error
    extensionInstanceSetter = null; // Error
    extensionStaticSetter = null; // Ok

    prefix; // Error
    prefix.unresolved; // Error
    prefix.Class; // Ok
    prefix.ExtensionType; // Ok
    prefix.Typedef; // Ok
    prefix.topLevelMember; // Ok
    prefix.topLevelField; // Ok
    prefix.unresolved = null; // Error
    prefix.topLevelSetter = null; // Ok
    prefix.topLevelField = null; // Ok
  }
}

extension type ExtensionType<T>._(Class<T> c) implements Class<T> {
  void extensionTypeInstanceMember() {}
  set extensionTypeInstanceSetter(_) {}
  static void extensionTypeStaticMember() {}
  static set extensionTypeStaticSetter(_) {}

  ExtensionType([parameter]) : c = topLevelMember() {
    var local;

    parameter; // Ok
    parameter = null; // Ok

    local; // Ok
    local = null; // Ok

    unresolved; // Error
    Class; // Ok
    ExtensionType; // Ok
    Typedef; // Ok
    T; // Ok
    instanceMember; // Ok
    instanceField; // Ok
    superMember; // Ok
    superField; // Ok
    extensionTypeInstanceMember; // Ok
    extensionTypeStaticMember; // Ok
    topLevelMember; // Ok
    topLevelField; // Ok

    unresolved = null; // Error
    topLevelSetter = null; // Ok
    topLevelField = null; // Ok
    instanceSetter = null; // Ok
    instanceField = null; // Ok
    superSetter = null; // Ok
    superField = null; // Ok
    extensionTypeInstanceSetter = null; // Ok
    extensionTypeStaticSetter = null; // Ok

    prefix; // Error
    prefix.unresolved; // Error
    prefix.Class; // Ok
    prefix.ExtensionType; // Ok
    prefix.Typedef; // Ok
    prefix.topLevelMember; // Ok
    prefix.topLevelField; // Ok
    prefix.unresolved = null; // Error
    prefix.topLevelSetter = null; // Ok
    prefix.topLevelField = null; // Ok
  }

  ExtensionType.redirect() : this._(topLevelMember()); // Ok

  factory ExtensionType.factory(parameter) {
    var local;

    parameter; // Ok
    parameter = null; // Ok

    local; // Ok
    local = null; // Ok

    unresolved; // Error
    Class; // Ok
    ExtensionType; // Ok
    Typedef; // Ok
    T; // Ok
    instanceMember; // Error
    instanceField; // Error
    superMember; // Error
    superField; // Error
    extensionTypeInstanceMember; // Error
    extensionTypeStaticMember; // Ok
    topLevelMember; // Ok
    topLevelField; // Ok

    unresolved = null; // Error
    topLevelSetter = null; // Ok
    topLevelField = null; // Ok
    instanceSetter = null; // Error
    instanceField = null; // Error
    superSetter = null; // Error
    superField = null; // Error
    extensionTypeInstanceSetter = null; // Error
    extensionTypeStaticSetter = null; // Ok

    prefix; // Error
    prefix.unresolved; // Error
    prefix.Class; // Ok
    prefix.ExtensionType; // Ok
    prefix.Typedef; // Ok
    prefix.topLevelMember; // Ok
    prefix.topLevelField; // Ok
    prefix.unresolved = null; // Error
    prefix.topLevelSetter = null; // Ok
    prefix.topLevelField = null; // Ok

    return new ExtensionType();
  }

  instanceTest<S>(parameter) {
    var local;

    parameter; // Ok
    parameter = null; // Ok

    local; // Ok
    local = null; // Ok

    unresolved; // Error
    Class; // Ok
    ExtensionType; // Ok
    Typedef; // Ok
    T; // Ok
    S; // Ok
    instanceMember; // Ok
    instanceField; // Ok
    superMember; // Ok
    superField; // Ok
    extensionTypeInstanceMember; // Ok
    extensionTypeStaticMember; // Ok
    topLevelMember; // Ok
    topLevelField; // Ok

    unresolved = null; // Error
    topLevelSetter = null; // Ok
    topLevelField = null; // Ok
    instanceSetter = null; // Ok
    instanceField = null; // Ok
    superSetter = null; // Ok
    superField = null; // Ok
    extensionTypeInstanceSetter = null; // Ok
    extensionTypeStaticSetter = null; // Ok

    prefix; // Error
    prefix.unresolved; // Error
    prefix.Class; // Ok
    prefix.ExtensionType; // Ok
    prefix.Typedef; // Ok
    prefix.topLevelMember; // Ok
    prefix.topLevelField; // Ok
    prefix.unresolved = null; // Error
    prefix.topLevelSetter = null; // Ok
    prefix.topLevelField = null; // Ok
  }

  static staticTest<S>(parameter) {
    var local;

    parameter; // Ok
    parameter = null; // Ok

    local; // Ok
    local = null; // Ok

    unresolved; // Error
    Class; // Ok
    ExtensionType; // Ok
    Typedef; // Ok
    T; // Error
    S; // Ok
    instanceMember; // Error
    instanceField; // Error
    superMember; // Error
    superField; // Error
    extensionTypeInstanceMember; // Error
    extensionTypeStaticMember; // Ok
    topLevelMember; // Ok
    topLevelField; // Ok

    unresolved = null; // Error
    topLevelSetter = null; // Ok
    topLevelField = null; // Ok
    instanceSetter = null; // Error
    instanceField = null; // Error
    superSetter = null; // Error
    superField = null; // Error
    extensionTypeInstanceSetter = null; // Error
    extensionTypeStaticSetter = null; // Ok

    prefix; // Error
    prefix.unresolved; // Error
    prefix.Class; // Ok
    prefix.ExtensionType; // Ok
    prefix.Typedef; // Ok
    prefix.topLevelMember; // Ok
    prefix.topLevelField; // Ok
    prefix.unresolved = null; // Error
    prefix.topLevelSetter = null; // Ok
    prefix.topLevelField = null; // Ok
  }
}
