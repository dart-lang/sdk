// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

/*library: scope=[A2]*/

class A1 {
  int _instanceField;
  int getInstanceField() => _instanceField;
  void setInstanceField(int value) {
    _instanceField = value;
  }
  static int _staticField = 0;
  static int getStaticField() => _staticField;
  static void setStaticField(int value) {
    _staticField = value;
  }
}

/*class: A2:
 builder-name=A2,
 builder-onType=A1,
 extension-members=[
  operator +=A2|+,
  getter instanceProperty=A2|get#instanceProperty,
  setter instanceProperty=A2|set#instanceProperty,
  static field staticField=A2|staticField,
  static getter staticProperty=A2|staticProperty,
  static setter staticProperty=A2|staticProperty=],
 extension-name=A2,
 extension-onType=A1
*/
extension A2 on A1 {
  /*member: A2|get#instanceProperty:
   builder-name=instanceProperty,
   builder-params=[#this],
   member-name=A2|get#instanceProperty,
   member-params=[#this]
  */
  int get instanceProperty => getInstanceField();

  /*member: A2|set#instanceProperty:
   builder-name=instanceProperty,
   builder-params=[#this,value],
   member-name=A2|set#instanceProperty,
   member-params=[#this,value]
  */
  void set instanceProperty(int value) {
    setInstanceField(value);
  }

  // TODO(johnniwinther): Test operator -() and operator -(val).

  /*member: A2|+:
   builder-name=+,
   builder-params=[#this,value],
   member-name=A2|+,
   member-params=[#this,value]
  */
  int operator +(int value) {
    return getInstanceField() + value;
  }

  /*member: A2|staticField:
   builder-name=staticField,
   member-name=A2|staticField
  */
  static int staticField = A1.getStaticField();

  /*member: A2|staticProperty:
   builder-name=staticProperty,
   member-name=A2|staticProperty
  */
  static int get staticProperty => A1.getStaticField();

  /*member: A2|staticProperty=:
   builder-name=staticProperty,
   builder-params=[value],
   member-name=A2|staticProperty=,
   member-params=[value]
  */
  static void set staticProperty(int value) {
    A1.setStaticField(value);
  }
}

main() {}
