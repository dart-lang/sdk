// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

final x = 'scope-marker';

mixin Mixin {
  var field = /*
   class=Mixin,
   member=field
  */
      x;

  empty() {
    /*
     class=Mixin,
     member=empty
    */
    x;
  }

  oneParameter(a) {
    /*
     class=Mixin,
     member=oneParameter,
     variables=[a]
    */
    x;
  }

  twoParameters(a, b) {
    /*
     class=Mixin,
     member=twoParameters,
     variables=[
      a,
      b]
    */
    x;
  }

  optionalParameter(a, [b]) {
    /*
     class=Mixin,
     member=optionalParameter,
     variables=[
      a,
      b]
    */
    x;
  }

  namedParameter(a, {b}) {
    /*
     class=Mixin,
     member=namedParameter,
     variables=[
      a,
      b]
    */
    x;
  }

  oneTypeParameter<T>() {
    /*
     class=Mixin,
     member=oneTypeParameter,
     typeParameters=[Mixin.oneTypeParameter.T]
    */
    x;
  }
}

mixin GenericMixin<T> {
  classTypeParameter() {
    /*
     class=GenericMixin,
     member=classTypeParameter,
     typeParameters=[GenericMixin.T]
    */
    x;
  }

  mixedTypeParameter<S>() {
    /*
     class=GenericMixin,
     member=mixedTypeParameter,
     typeParameters=[
      GenericMixin.T,
      GenericMixin.mixedTypeParameter.S]
    */
    x;
  }

  static var field = /*
   class=GenericMixin,
   member=field,
   typeParameters=[GenericMixin.T]
  */
      x;

  static empty() {
    /*
     class=GenericMixin,
     member=empty,
     static,
     typeParameters=[GenericMixin.T]
    */
    x;
  }

  static oneParameter(a) {
    /*
     class=GenericMixin,
     member=oneParameter,
     static,
     typeParameters=[GenericMixin.T],
     variables=[a]
    */
    x;
  }

  static twoParameters(a, b) {
    /*
     class=GenericMixin,
     member=twoParameters,
     static,
     typeParameters=[GenericMixin.T],
     variables=[
      a,
      b]
    */
    x;
  }

  static optionalParameter(a, [b]) {
    /*
     class=GenericMixin,
     member=optionalParameter,
     static,
     typeParameters=[GenericMixin.T],
     variables=[
      a,
      b]
    */
    x;
  }

  static namedParameter(a, {b}) {
    /*
     class=GenericMixin,
     member=namedParameter,
     static,
     typeParameters=[GenericMixin.T],
     variables=[
      a,
      b]
    */
    x;
  }

  static oneTypeParameter<T>() {
    /*
     class=GenericMixin,
     member=oneTypeParameter,
     static,
     typeParameters=[
      GenericMixin.T,
      GenericMixin.oneTypeParameter.T]
    */
    x;
  }
}
