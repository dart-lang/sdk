// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

final x = 'scope-marker';

extension type ExtensionType(String field) {
  ExtensionType.empty()
      : field = /*
   member=ExtensionType|constructor#empty,
   static
  */
            x {
    /*
   member=ExtensionType|constructor#empty,
   static,
   variables=[#this]
  */
    x;
  }

  ExtensionType.oneParameter(a)
      : field = /*
       member=ExtensionType|constructor#oneParameter,
       static,
       variables=[a]
      */
            x {
    /*
   member=ExtensionType|constructor#oneParameter,
   static,
   variables=[
    #this,
    a]
  */
    x;
  }

  ExtensionType.twoParameters(a, b)
      : field = /*
       member=ExtensionType|constructor#twoParameters,
       static,
       variables=[
        a,
        b]
      */
            x {
    /*
   member=ExtensionType|constructor#twoParameters,
   static,
   variables=[
    #this,
    a,
    b]
  */
    x;
  }

  ExtensionType.optionalParameter(a, [b])
      : field = /*
       member=ExtensionType|constructor#optionalParameter,
       static,
       variables=[
        a,
        b]
      */
            x {
    /*
   member=ExtensionType|constructor#optionalParameter,
   static,
   variables=[
    #this,
    a,
    b]
  */
    x;
  }

  ExtensionType.namedParameter(a, {b})
      : field = /*
       member=ExtensionType|constructor#namedParameter,
       static,
       variables=[
        a,
        b]
      */
            x {
    /*
   member=ExtensionType|constructor#namedParameter,
   static,
   variables=[
    #this,
    a,
    b]
  */
    x;
  }

  empty() {
    /*
     member=ExtensionType|empty,
     static,
     variables=[#this]
    */
    x;
  }

  oneParameter(a) {
    /*
     member=ExtensionType|oneParameter,
     static,
     variables=[
      #this,
      a]
    */
    x;
  }

  twoParameters(a, b) {
    /*
     member=ExtensionType|twoParameters,
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
     member=ExtensionType|optionalParameter,
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
     member=ExtensionType|namedParameter,
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
     member=ExtensionType|oneTypeParameter,
     static,
     typeParameters=[ExtensionType|oneTypeParameter.T],
     variables=[#this]
    */
    x;
  }
}

extension type GenericExtension<T>(T field) {
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

  static var staticField = /*member=GenericExtension|staticField*/
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
