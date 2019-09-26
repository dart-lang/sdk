// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class {
  var field;
}

extension Extension on Class {
  readGetter() {
    return property;
  }

  writeSetterRequired(value) {
    property = value;
  }

  writeSetterOptional([value]) {
    property = value;
  }

  writeSetterNamed({value}) {
    property = value;
  }

  get tearOffGetterNoArgs => readGetter;
  get tearOffGetterRequired => writeSetterRequired;
  get tearOffGetterOptional => writeSetterOptional;
  get tearOffGetterNamed => writeSetterNamed;

  get property => this.field;

  set property(value) {
    this.field = value;
  }

  invocations(value) {
    readGetter();
    writeSetterRequired(value);
    writeSetterOptional();
    writeSetterOptional(value);
    writeSetterNamed();
    writeSetterNamed(value: value);
  }

  tearOffs(value) {
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
  }

  getterCalls(value) {
    tearOffGetterNoArgs();
    tearOffGetterRequired(value);
    tearOffGetterOptional();
    tearOffGetterOptional(value);
    tearOffGetterNamed();
    tearOffGetterNamed(value: value);
  }
}

class GenericClass<T> {
  T field;
}

extension GenericExtension<T> on GenericClass<T> {
  T readGetter() {
    return property;
  }

  writeSetterRequired(T value) {
    property = value;
  }

  writeSetterOptional([T value]) {
   property = value;
  }

  writeSetterNamed({T value}) {
    property = value;
  }

  genericWriteSetterRequired<S extends T>(S value) {
   property = value;
  }

  genericWriteSetterOptional<S extends T>([S value]) {
    property = value;
  }

  genericWriteSetterNamed<S extends T>({S value}) {
   property = value;
  }

  T get property => this.field;

  void set property(T value) {
    this.field = value;
  }

  get tearOffGetterNoArgs => readGetter;
  get tearOffGetterRequired => writeSetterRequired;
  get tearOffGetterOptional => writeSetterOptional;
  get tearOffGetterNamed => writeSetterNamed;
  get tearOffGetterGenericRequired => genericWriteSetterRequired;
  get tearOffGetterGenericOptional => genericWriteSetterOptional;
  get tearOffGetterGenericNamed => genericWriteSetterNamed;

  invocations<S extends T>(S value) {
    readGetter();
    writeSetterRequired(value);
    writeSetterOptional();
    writeSetterOptional(value);
    writeSetterNamed();
    writeSetterNamed(value: value);
    genericWriteSetterRequired(value);
    genericWriteSetterRequired<T>(value);
    genericWriteSetterRequired<S>(value);
    genericWriteSetterOptional();
    genericWriteSetterOptional<T>();
    genericWriteSetterOptional<S>();
    genericWriteSetterOptional(value);
    genericWriteSetterOptional<T>(value);
    genericWriteSetterOptional<S>(value);
    genericWriteSetterNamed();
    genericWriteSetterNamed<T>();
    genericWriteSetterNamed<S>();
    genericWriteSetterNamed(value: value);
    genericWriteSetterNamed<T>(value: value);
    genericWriteSetterNamed<S>(value: value);
  }

  tearOffs<S extends T>(S value) {
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
    var genericTearOffRequired = genericWriteSetterRequired;
    genericTearOffRequired(value);
    genericTearOffRequired<T>(value);
    genericTearOffRequired<S>(value);
    var genericTearOffOptional = genericWriteSetterOptional;
    genericTearOffOptional();
    genericTearOffOptional<T>();
    genericTearOffOptional<S>();
    genericTearOffOptional(value);
    genericTearOffOptional<T>(value);
    genericTearOffOptional<S>(value);
    var genericTearOffNamed = genericWriteSetterNamed;
    genericTearOffNamed();
    genericTearOffNamed<T>();
    genericTearOffNamed<S>();
    genericTearOffNamed(value: value);
    genericTearOffNamed<T>(value: value);
    genericTearOffNamed<S>(value: value);
  }

  getterCalls<S extends T>(S value) {
    tearOffGetterNoArgs();
    tearOffGetterRequired(value);
    tearOffGetterOptional();
    tearOffGetterOptional(value);
    tearOffGetterNamed();
    tearOffGetterNamed(value: value);
    tearOffGetterGenericRequired(value);
    tearOffGetterGenericRequired<T>(value);
    tearOffGetterGenericRequired<S>(value);
    tearOffGetterGenericOptional();
    tearOffGetterGenericOptional<T>();
    tearOffGetterGenericOptional<S>();
    tearOffGetterGenericOptional(value);
    tearOffGetterGenericOptional<T>(value);
    tearOffGetterGenericOptional<S>(value);
    tearOffGetterGenericNamed();
    tearOffGetterGenericNamed<T>();
    tearOffGetterGenericNamed<S>();
    tearOffGetterGenericNamed(value: value);
    tearOffGetterGenericNamed<T>(value: value);
    tearOffGetterGenericNamed<S>(value: value);
  }
}

main() {}