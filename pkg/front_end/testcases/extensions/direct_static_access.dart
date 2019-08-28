// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class<T> {
  static var field;
}

extension Extension<T> on Class<T> {

  static get property => Class.field;

  static set property(value) {
    Class.field = value;
  }

  static var field;

  static readGetter() {
    return property;
  }

  static writeSetterRequired(value) {
    property = value;
  }

  static writeSetterOptional([value]) {
    property = value;
  }

  static writeSetterNamed({value}) {
    property = value;
  }

  static genericWriteSetterRequired<S>(S value) {
    property = value;
  }

  static genericWriteSetterOptional<S>([S value]) {
    property = value;
  }

  static genericWriteSetterNamed<S>({S value}) {
    property = value;
  }

  static get tearOffGetterNoArgs => readGetter;
  static get tearOffGetterRequired => writeSetterRequired;
  static get tearOffGetterOptional => writeSetterOptional;
  static get tearOffGetterNamed => writeSetterNamed;
  static get tearOffGetterGenericRequired => genericWriteSetterRequired;
  static get tearOffGetterGenericOptional => genericWriteSetterOptional;
  static get tearOffGetterGenericNamed => genericWriteSetterNamed;

  static invocationsFromStaticContext(int value) {
    readGetter();
    writeSetterRequired(value);
    writeSetterOptional();
    writeSetterOptional(value);
    writeSetterNamed();
    writeSetterNamed(value: value);
    genericWriteSetterRequired(value);
    genericWriteSetterRequired<int>(value);
    genericWriteSetterOptional();
    genericWriteSetterOptional<int>();
    genericWriteSetterOptional(value);
    genericWriteSetterOptional<int>(value);
    genericWriteSetterNamed();
    genericWriteSetterNamed<int>();
    genericWriteSetterNamed(value: value);
    genericWriteSetterNamed<int>(value: value);
  }

  static tearOffsFromStaticContext(int value) {
    var tearOffNoArgs = readGetter;
    tearOffNoArgs();
    var tearOffRequired = writeSetterRequired;
    tearOffRequired(value);
    var tearOffOptional = writeSetterOptional;
    tearOffOptional();
    tearOffOptional(value);
    var tearOffNamed = writeSetterNamed;
    tearOffNamed();
    tearOffNamed(value: value);
    var tearOffGenericRequired = genericWriteSetterRequired;
    tearOffGenericRequired(value);
    tearOffGenericRequired<int>(value);
    var tearOffGenericOptional = genericWriteSetterOptional;
    tearOffGenericOptional();
    tearOffGenericOptional<int>();
    tearOffGenericOptional(value);
    tearOffGenericOptional<int>(value);
    var tearOffGenericNamed = genericWriteSetterNamed;
    tearOffGenericNamed();
    tearOffGenericNamed<int>();
    tearOffGenericNamed(value: value);
    tearOffGenericNamed<int>(value: value);
  }

  static fieldAccessFromStaticContext() {
    field = property;
    property = field;
  }

  static getterCallsFromStaticContext(int value) {
    tearOffGetterNoArgs();
    tearOffGetterRequired(value);
    tearOffGetterOptional();
    tearOffGetterOptional(value);
    tearOffGetterNamed();
    tearOffGetterNamed(value: value);
    tearOffGetterGenericRequired(value);
    tearOffGetterGenericRequired<int>(value);
    tearOffGetterGenericOptional();
    tearOffGetterGenericOptional<int>();
    tearOffGetterGenericOptional(value);
    tearOffGetterGenericOptional<int>(value);
    tearOffGetterGenericNamed();
    tearOffGetterGenericNamed<int>();
    tearOffGetterGenericNamed(value: value);
    tearOffGetterGenericNamed<int>(value: value);
  }

  invocationsFromInstanceContext(T value) {
    readGetter();
    writeSetterRequired(value);
    writeSetterOptional();
    writeSetterOptional(value);
    writeSetterNamed();
    writeSetterNamed(value: value);
    genericWriteSetterRequired(value);
    genericWriteSetterRequired<T>(value);
    genericWriteSetterOptional();
    genericWriteSetterOptional<T>();
    genericWriteSetterOptional(value);
    genericWriteSetterOptional<T>(value);
    genericWriteSetterNamed();
    genericWriteSetterNamed<T>();
    genericWriteSetterNamed(value: value);
    genericWriteSetterNamed<T>(value: value);
  }

  tearOffsFromInstanceContext(T value) {
    var tearOffNoArgs = readGetter;
    tearOffNoArgs();
    var tearOffRequired = writeSetterRequired;
    tearOffRequired(value);
    var tearOffOptional = writeSetterOptional;
    tearOffOptional();
    tearOffOptional(value);
    var tearOffNamed = writeSetterNamed;
    tearOffNamed();
    tearOffNamed(value: value);
    var tearOffGenericRequired = genericWriteSetterRequired;
    tearOffGenericRequired(value);
    tearOffGenericRequired<T>(value);
    var tearOffGenericOptional = genericWriteSetterOptional;
    tearOffGenericOptional();
    tearOffGenericOptional<T>();
    tearOffGenericOptional(value);
    tearOffGenericOptional<T>(value);
    var tearOffGenericNamed = genericWriteSetterNamed;
    tearOffGenericNamed();
    tearOffGenericNamed<T>();
    tearOffGenericNamed(value: value);
    tearOffGenericNamed<T>(value: value);
  }

  fieldAccessFromInstanceContext() {
    field = property;
    property = field;
  }

  getterCallsFromInstanceContext(T value) {
    tearOffGetterNoArgs();
    tearOffGetterRequired(value);
    tearOffGetterOptional();
    tearOffGetterOptional(value);
    tearOffGetterNamed();
    tearOffGetterNamed(value: value);
    tearOffGetterGenericRequired(value);
    tearOffGetterGenericRequired<T>(value);
    tearOffGetterGenericOptional();
    tearOffGetterGenericOptional<T>();
    tearOffGetterGenericOptional(value);
    tearOffGetterGenericOptional<T>(value);
    tearOffGetterGenericNamed();
    tearOffGetterGenericNamed<T>();
    tearOffGetterGenericNamed(value: value);
    tearOffGetterGenericNamed<T>(value: value);
  }
}

main() {}