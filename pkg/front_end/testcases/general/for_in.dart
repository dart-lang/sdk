// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'for_in.dart' deferred as defer hide Extension, IndexExtension;

int intTopLevel = 0;
final int finalTopLevel = 0;
const int constTopLevel = 0;
late int lateTopLevel;
late final int lateFinalTopLevel;
num numTopLevel = 0;
String stringTopLevel = '';

test() {
  for (const constLocal in [1]) { // Error
    print(constLocal);
  }
  for (late int lateLocal in [1]) { // Error
    print(lateLocal);
  }
  for (String stringLocal in [1]) { // Error
    print(stringLocal);
  }
  for (String stringLocal in <int>[1]) { // Error
    print(stringLocal);
  }
  print([
    for (const constLocal in [1]) constLocal // Error
  ]);
  print([
    for (late int lateLocal in [1]) lateLocal // Error
  ]);
  print([
    for (String stringLocal in [1]) stringLocal // Error
  ]);
  print([
    for (String stringLocal in <int>[1]) stringLocal // Error
  ]);
  print({
    for (const constLocal in [1]) 0: constLocal // Error
  });
  print({
    for (late int lateLocal in [1]) 0: lateLocal // Error
  });
  print({
    for (String stringLocal in [1]) 0: stringLocal // Error
  });
  print({
    for (String stringLocal in <int>[1]) 0: stringLocal // Error
  });
  for (int? multiLocal1, multiLocal2 in [1]) { // Error
    print(multiLocal1);
    print(multiLocal2);
  }
  for (var varMultiLocal1, varMultiLocal2 in [1]) { // Error
    print(varMultiLocal1);
    print(varMultiLocal2);
  }
  for (num numMultiLocal1, numMultiLocal2 in [1]) { // Error
    print(numMultiLocal1);
    print(numMultiLocal2);
  }
  for (1 in [1]) { // Error

  }
  for (main() in [1]) { // Error

  }
  final int existingFinalLocal;
  for (existingFinalLocal in [1]) { // Error
    print(existingFinalLocal);
  }
  String existingStringLocal;
  for (existingStringLocal in [1]) { // Error
    print(existingStringLocal);
  }
  for (existingStringLocal in <int>[1]) { // Error
    print(existingStringLocal);
  }
  Class c = Class();
  for (c.intField in [1]) { // Error
    print(c.intField);
  }
  for (c.numField in [1]) { // Error
    print(c.numField);
  }
  for (c.lateField in [1]) { // Error
    print(c.lateField);
  }
  for (c?.intField in [1]) { // Error
    print(c?.intField);
  }
  for (c?.numField in [1]) { // Error
    print(c?.numField);
  }
  for (c?.lateField in [1]) { // Error
    print(c?.lateField);
  }
  for (c.stringField in [1]) { // Error
    print(c.stringField);
  }
  for (c.stringField in <int>[1]) { // Error
    print(c.stringField);
  }
  for (c?.stringField in [1]) { // Error
    print(c?.stringField);
  }
  for (c?.stringField in <int>[1]) { // Error
    print(c?.stringField);
  }
  for (c.finalField in [1]) { // Error
    print(c.finalField);
  }
  for (c?.finalField in [1]) { // Error
    print(c?.finalField);
  }
  for (c.lateFinalField in [1]) { // Error
    print(c.lateFinalField);
  }
  for (c?.lateFinalField in [1]) { // Error
    print(c?.lateFinalField);
  }
  for (c[0] in [1]) { // Error
    print(c[0]);
  }
  for (c?[0] in [1]) { // Error
    print(c[0]);
  }
  for (finalTopLevel in [1]) { // Error
    print(finalTopLevel);
  }
  for (constTopLevel in [1]) { // Error
    print(constTopLevel);
  }
  for (stringTopLevel in [1]) { // Error
    print(stringTopLevel);
  }
  for (stringTopLevel in <int>[1]) { // Error
    print(stringTopLevel);
  }
  for (defer.intTopLevel in [1]) { // Error
    print(defer.intTopLevel);
  }
  for (defer.numTopLevel in [1]) { // Error
    print(defer.numTopLevel);
  }
  for (defer.lateTopLevel in [1]) { // Error
    print(defer.lateTopLevel);
  }
  for (defer.lateFinalTopLevel in [1]) { // Error
    print(defer.lateFinalTopLevel);
  }
  for (defer.finalTopLevel in [1]) { // Error
    print(defer.finalTopLevel);
  }
  for (defer.constTopLevel in [1]) { // Error
    print(defer.constTopLevel);
  }
  for (defer.stringTopLevel in [1]) { // Error
    print(defer.stringTopLevel);
  }
  for (defer.stringTopLevel in <int>[1]) { // Error
    print(defer.stringTopLevel);
  }
  for (Class.stringStaticField in [1]) { // Error
    print(Class.stringStaticField);
  }
  for (Class.stringStaticField in <int>[1]) { // Error
    print(Class.stringStaticField);
  }
  for (Class.finalStaticField in [1]) { // Error
    print(Class.finalStaticField);
  }
  for (Class.lateFinalStaticField in [1]) { // Error
    print(Class.lateFinalStaticField);
  }
  for (Extension.stringStaticField in [1]) { // Error
    print(Extension.stringStaticField);
  }
  for (Extension.stringStaticField in <int>[1]) { // Error
    print(Extension.stringStaticField);
  }
  for (Extension.finalStaticField in [1]) { // Error
    print(Extension.finalStaticField);
  }
  for (Extension.lateFinalStaticField in [1]) { // Error
    print(Extension.lateFinalStaticField);
  }
  for (Class.intStaticField in [1]) { // Error
    print(Class.intStaticField);
  }
  for (Class.numStaticField in [1]) { // Error
    print(Class.numStaticField);
  }
  for (Class.lateStaticField in [1]) { // Error
    print(Class.lateStaticField);
  }
  for (Extension.intStaticField in [1]) { // Error
    print(Extension.intStaticField);
  }
  for (Extension.numStaticField in [1]) { // Error
    print(Extension.numStaticField);
  }
  for (Extension.lateStaticField in [1]) { // Error
    print(Extension.lateStaticField);
  }
}

main() {
  for (int intLocal in [1]) { // Ok
    print(intLocal);
  }
  for (num numLocal in [1]) { // Ok
    print(numLocal);
  }
  for (var varLocal in [1]) { // Ok
    print(varLocal);
  }
  for (final finalLocal in [1]) { // Ok
    print(finalLocal);
  }
  print([
    for (int intLocal in [1]) intLocal // Ok
  ]);
  print([
    for (num numLocal in [1]) numLocal // Ok
  ]);
  print([
    for (var varLocal in [1]) varLocal // Ok
  ]);
  print([
    for (final finalLocal in [1]) finalLocal // Ok
  ]);
  print({
    for (int intLocal in [1]) 0: intLocal // Ok
  });
  print({
    for (num numLocal in [1]) 0: numLocal // Ok
  });
  print({
    for (var varLocal in [1]) 0: varLocal // Ok
  });
  print({
    for (final finalLocal in [1]) 0: finalLocal // Ok
  });
  for (var (a, b) in [(1, 2)]) { // Ok
    print(a);
    print(b);
  }
  int existingIntLocal;
  for (existingIntLocal in [1]) { // Ok
    print(existingIntLocal);
  }
  num existingNumLocal;
  for (existingNumLocal in [1]) { // Ok
    print(existingNumLocal);
  }

  Class().method();

  for (intTopLevel in [1]) { // Ok
    print(intTopLevel);
  }
  for (numTopLevel in [1]) { // Ok
    print(numTopLevel);
  }
  for (lateTopLevel in [1]) { // Ok
    print(lateTopLevel);
  }
  for (lateFinalTopLevel in [1]) { // Ok
    print(lateFinalTopLevel);
  }
  Class().extensionMethod();
}

class Class {
  int intField = 0;
  num numField = 0;
  String stringField = '';
  final int finalField = 0;
  late int lateField;
  late final int lateFinalField;

  static int intStaticField = 0;
  static num numStaticField = 0;
  static String stringStaticField = '';
  static final int finalStaticField = 0;
  static late int lateStaticField;
  static late final int lateFinalStaticField;

  operator[]=(int index, int value) {}
  int operator[](int index) => 0;

  test() {
    for (this.intField in [1]) { // Error
      print(this.intField);
    }
    for (this?.intField in [1]) { // Error
      print(this?.intField);
    }
    for (this.numField in [1]) { // Error
      print(this.numField);
    }
    for (this?.numField in [1]) { // Error
      print(this?.numField);
    }
    for (this.lateField in [1]) { // Error
      print(this.lateField);
    }
    for (this?.lateField in [1]) { // Error
      print(this?.lateField);
    }
    for (stringField in [1]) { // Error
      print(stringField);
    }
    for (stringField in <int>[1]) { // Error
      print(stringField);
    }
    for (this.stringField in [1]) { // Error
      print(this.stringField);
    }
    for (this.stringField in <int>[1]) { // Error
      print(this.stringField);
    }
    for (this?.stringField in [1]) { // Error
      print(this.stringField);
    }
    for (this?.stringField in <int>[1]) { // Error
      print(this.stringField);
    }
    for (this[0] in [1]) { // Error
      print(this[0]);
    }
    for (this?[0] in [1]) { // Error
      print(this[0]);
    }
    for (finalField in [1]) { // Error
      print(finalField);
    }
    for (finalField in <int>[1]) { // Error
      print(finalField);
    }
    for (this.finalField in [1]) { // Error
      print(this.finalField);
    }
    for (this.finalField in <int>[1]) { // Error
      print(this.finalField);
    }
    for (this?.finalField in [1]) { // Error
      print(this.finalField);
    }
    for (this?.finalField in <int>[1]) { // Error
      print(this.finalField);
    }
    for (lateFinalField in [1]) { // Ok
      print(lateFinalField);
    }
    for (this.lateFinalField in [1]) { // Error
      print(this.lateFinalField);
    }
    for (this?.lateFinalField in [1]) { // Error
      print(this.lateFinalField);
    }
    for (finalStaticField in [1]) { // Error
      print(finalStaticField);
    }
    for (stringStaticField in [1]) { // Error
      print(stringStaticField);
    }
    for (stringStaticField in <int>[1]) { // Error
      print(stringStaticField);
    }
    for (lateFinalStaticField in [1]) { // Ok
      print(lateFinalStaticField);
    }
    for (this.extensionIntProperty in [1]) { // Error
      print(this.extensionIntProperty);
    }
    for (this?.extensionIntProperty in [1]) { // Error
      print(this?.extensionIntProperty);
    }
    for (this.extensionNumProperty in [1]) { // Error
      print(this.extensionNumProperty);
    }
    for (this?.extensionNumProperty in [1]) { // Error
      print(this?.extensionNumProperty);
    }
    for (Extension(this).extensionIntProperty in [1]) { // Error
      print(Extension(this).extensionIntProperty);
    }
    for (Extension(this)?.extensionIntProperty in [1]) { // Error
      print(Extension(this)?.extensionIntProperty);
    }
    for (Extension(this).extensionNumProperty in [1]) { // Error
      print(Extension(this).extensionNumProperty);
    }
    for (Extension(this)?.extensionNumProperty in [1]) { // Error
      print(Extension(this)?.extensionNumProperty);
    }
    for (Extension(this).extensionStringProperty in [1]) { // Error
      print(Extension(this).extensionStringProperty);
    }
    for (Extension(this)?.extensionStringProperty in [1]) { // Error
      print(Extension(this)?.extensionStringProperty);
    }
    for (Extension(this).extensionStringProperty in <int>[1]) { // Error
      print(Extension(this).extensionStringProperty);
    }
    for (Extension(this)?.extensionStringProperty in <int>[1]) { // Error
      print(Extension(this)?.extensionStringProperty);
    }
    for (Extension(this).extensionReadOnlyProperty in [1]) { // Error
      print(Extension(this).extensionReadOnlyProperty);
    }
    for (Extension(this)?.extensionReadOnlyProperty in [1]) { // Error
      print(Extension(this)?.extensionReadOnlyProperty);
    }
    for (0[0] in [1]) { // Error
      print(0[0]);
    }
    for (0?[0] in [1]) { // Error
      print(0?[0]);
    }
    for (IndexExtension(0)[0] in [1]) { // Error
      print(IndexExtension(0)[0]);
    }
    for (IndexExtension(0)?[0] in [1]) { // Error
      print(IndexExtension(0)?[0]);
    }
  }

  method() {
    for (intField in [1]) { // Ok
      print(intField);
    }
    for (numField in [1]) { // Ok
      print(numField);
    }
    for (lateField in [1]) { // Ok
      print(lateField);
    }
    for (intStaticField in [1]) { // Ok
      print(intStaticField);
    }
    for (numStaticField in [1]) { // Ok
      print(numStaticField);
    }
    for (lateStaticField in [1]) { // Ok
      print(lateStaticField);
    }
    for (extensionIntProperty in [1]) { // Ok
      print(extensionIntProperty);
    }
    for (extensionNumProperty in [1]) { // Ok
      print(extensionNumProperty);
    }
  }
}

class Subclass extends Class {
  test() {
    for (super.stringField in [1]) { // Error
      print(super.stringField);
    }
    for (super.stringField in <int>[1]) { // Error
      print(super.stringField);
    }
    for (super.intField in [1]) { // Error
      print(super.intField);
    }
    for (super.numField in [1]) { // Error
      print(super.numField);
    }
    for (super.lateField in [1]) { // Error
      print(super.lateField);
    }
    for (super[0] in [1]) { // Error
      print(super[0]);
    }
    for (super?[0] in [1]) { // Error
      print(super[0]);
    }
  }
}

extension Extension on Class {
  int get extensionIntProperty => 0;
  void set extensionIntProperty(int value) {}
  num get extensionNumProperty => 0;
  void set extensionNumProperty(num value) {}
  String get extensionStringProperty => '';
  void set extensionStringProperty(String value) {}
  int get extensionReadOnlyProperty => 0;

  static int intStaticField = 0;
  static num numStaticField = 0;
  static String stringStaticField = '';
  static final int finalStaticField = 0;
  static late int lateStaticField;
  static late final int lateFinalStaticField;

  test() {
    for (this.intField in [1]) { // Error
      print(this.intField);
    }
    for (this?.intField in [1]) { // Error
      print(this?.intField);
    }
    for (this.numField in [1]) { // Error
      print(this.numField);
    }
    for (this?.numField in [1]) { // Error
      print(this?.numField);
    }
    for (this.lateField in [1]) { // Error
      print(this.lateField);
    }
    for (this?.lateField in [1]) { // Error
      print(this?.lateField);
    }
    for (this.extensionIntProperty in [1]) { // Error
      print(this.extensionIntProperty);
    }
    for (this?.extensionIntProperty in [1]) { // Error
      print(this?.extensionIntProperty);
    }
    for (this.extensionNumProperty in [1]) { // Error
      print(this.extensionNumProperty);
    }
    for (this?.extensionNumProperty in [1]) { // Error
      print(this?.extensionNumProperty);
    }
    for (extensionStringProperty in [1]) { // Error
      print(extensionStringProperty);
    }
    for (this.extensionStringProperty in [1]) { // Error
      print(this.extensionStringProperty);
    }
    for (this?.extensionStringProperty in [1]) { // Error
      print(this?.extensionStringProperty);
    }
    for (extensionStringProperty in <int>[1]) { // Error
      print(extensionStringProperty);
    }
    for (this.extensionStringProperty in <int>[1]) { // Error
      print(this.extensionStringProperty);
    }
    for (this?.extensionStringProperty in <int>[1]) { // Error
      print(this?.extensionStringProperty);
    }
    for (extensionReadOnlyProperty in [1]) { // Error
      print(extensionReadOnlyProperty);
    }
    for (this.extensionReadOnlyProperty in [1]) { // Error
      print(this.extensionReadOnlyProperty);
    }
    for (this?.extensionReadOnlyProperty in [1]) { // Error
      print(this?.extensionReadOnlyProperty);
    }
    for (finalStaticField in [1]) { // Error
      print(finalStaticField);
    }
    for (stringStaticField in [1]) { // Error
      print(stringStaticField);
    }
    for (stringStaticField in <int>[1]) { // Error
      print(stringStaticField);
    }
    for (lateFinalStaticField in [1]) { // Ok
      print(lateFinalStaticField);
    }
  }

  extensionMethod() {
    for (intField in [1]) { // Ok
      print(intField);
    }
    for (numField in [1]) { // Ok
      print(numField);
    }
    for (lateField in [1]) { // Ok
      print(lateField);
    }
    for (extensionIntProperty in [1]) { // Ok
      print(extensionIntProperty);
    }
    for (extensionNumProperty in [1]) { // Ok
      print(extensionNumProperty);
    }
    for (intStaticField in [1]) { // Ok
      print(intStaticField);
    }
    for (numStaticField in [1]) { // Ok
      print(numStaticField);
    }
    for (lateStaticField in [1]) { // Ok
      print(lateStaticField);
    }
  }
}

extension IndexExtension on int {
  operator[]=(int index, int value) {}
  int operator[](int index) => 0;

  extensionMethod() {
    for (this[0] in [1]) { // Error
      print(this[0]);
    }
    for (this?[0] in [1]) { // Error
      print(this?[0]);
    }
  }
}