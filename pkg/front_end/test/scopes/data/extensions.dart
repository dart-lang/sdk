// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

final x = 'scope-marker';

extension Extension on int {
  empty() {
    /*cfe.
     member=Extension|empty,
     static,
     variables=[#this]
    */
    /*ddc.
     member=Extension|get#empty,
     static,
     variables=[#this]
    */
    x;
  }

  oneParameter(a) {
    /*cfe.
     member=Extension|oneParameter,
     static,
     variables=[
      #this,
      a]
    */
    /*ddc.
     member=Extension|get#oneParameter,
     static,
     variables=[
      #this,
      a]
    */
    x;
  }

  twoParameters(a, b) {
    /*cfe.
     member=Extension|twoParameters,
     static,
     variables=[
      #this,
      a,
      b]
    */
    /*ddc.
     member=Extension|get#twoParameters,
     static,
     variables=[
      #this,
      a,
      b]
    */
    x;
  }

  optionalParameter(a, [b]) {
    /*cfe.
     member=Extension|optionalParameter,
     static,
     variables=[
      #this,
      a,
      b]
    */
    /*ddc.
     member=Extension|get#optionalParameter,
     static,
     variables=[
      #this,
      a,
      b]
    */
    x;
  }

  namedParameter(a, {b}) {
    /*cfe.
     member=Extension|namedParameter,
     static,
     variables=[
      #this,
      a,
      b]
    */
    /*ddc.
     member=Extension|get#namedParameter,
     static,
     variables=[
      #this,
      a,
      b]
    */
    x;
  }

  oneTypeParameter<T>() {
    /*cfe.
     member=Extension|oneTypeParameter,
     static,
     typeParameters=[Extension|oneTypeParameter.T],
     variables=[#this]
    */
    /*ddc.
     member=Extension|get#oneTypeParameter,
     static,
     typeParameters=[
      Extension|oneTypeParameter.T,
      T],
     variables=[#this]
    */
    x;
  }
}

extension GenericExtension<T> on T {
  classTypeParameter() {
    /*cfe.
     member=GenericExtension|classTypeParameter,
     static,
     typeParameters=[GenericExtension|classTypeParameter.T],
     variables=[#this]
    */
    /*ddc.
     member=GenericExtension|get#classTypeParameter,
     static,
     typeParameters=[
      GenericExtension|classTypeParameter.T,
      GenericExtension|get#classTypeParameter.T],
     variables=[#this]
    */
    x;
  }

  mixedTypeParameter<S>() {
    /*cfe.
     member=GenericExtension|mixedTypeParameter,
     static,
     typeParameters=[
      GenericExtension|mixedTypeParameter.S,
      GenericExtension|mixedTypeParameter.T],
     variables=[#this]
    */
    /*ddc.
     member=GenericExtension|get#mixedTypeParameter,
     static,
     typeParameters=[
      GenericExtension|get#mixedTypeParameter.T,
      GenericExtension|mixedTypeParameter.S,
      GenericExtension|mixedTypeParameter.T,
      S],
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
