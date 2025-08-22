// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

final x = 'scope-marker';

extension Extension on int {
  empty() {
    /*
     member=Extension|empty,
     static,
     variables=[#this]
    */
    x;
  }

  oneParameter(a) {
    /*
     member=Extension|oneParameter,
     static,
     variables=[
      #this,
      a]
    */
    x;
  }

  twoParameters(a, b) {
    /*
     member=Extension|twoParameters,
     static,
     variables=[
      #this,
      a,
      b]
    */
    x;
  }

  optionalParameter(a, [b]) {
    /*
     member=Extension|optionalParameter,
     static,
     variables=[
      #this,
      a,
      b]
    */
    x;
  }

  namedParameter(a, {b}) {
    /*
     member=Extension|namedParameter,
     static,
     variables=[
      #this,
      a,
      b]
    */
    x;
  }

  oneTypeParameter<T>() {
    /*
     member=Extension|oneTypeParameter,
     static,
     typeParameters=[Extension|oneTypeParameter.T],
     variables=[#this]
    */
    x;
  }
}

extension GenericExtension<T> on T {
  classTypeParameter() {
    /*
     member=GenericExtension|classTypeParameter,
     static,
     typeParameters=[GenericExtension|classTypeParameter.T],
     variables=[#this]
    */
    x;
  }

  mixedTypeParameter<S>() {
    /*
     member=GenericExtension|mixedTypeParameter,
     static,
     typeParameters=[
      GenericExtension|mixedTypeParameter.S,
      GenericExtension|mixedTypeParameter.T],
     variables=[#this]
    */
    x;
  }

  static var field = /*member=GenericExtension|field*/
      x;

  static empty() {
    /*
     member=GenericExtension|empty,
     static
    */
    x;
  }

  static oneParameter(a) {
    /*
     member=GenericExtension|oneParameter,
     static,
     variables=[a]
    */
    x;
  }

  static twoParameters(a, b) {
    /*
     member=GenericExtension|twoParameters,
     static,
     variables=[
      a,
      b]
    */
    x;
  }

  static optionalParameter(a, [b]) {
    /*
     member=GenericExtension|optionalParameter,
     static,
     variables=[
      a,
      b]
    */
    x;
  }

  static namedParameter(a, {b}) {
    /*
     member=GenericExtension|namedParameter,
     static,
     variables=[
      a,
      b]
    */
    x;
  }

  static oneTypeParameter<T>() {
    /*
     member=GenericExtension|oneTypeParameter,
     static,
     typeParameters=[GenericExtension|oneTypeParameter.T]
    */
    x;
  }
}
