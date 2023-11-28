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
  /*cfe.
   member=ExtensionType|constructor#empty,
   static,
   variables=[#this]
  */
  /*ddc.
   member=ExtensionType|constructor#empty,
   static
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
  /*cfe.
   member=ExtensionType|constructor#oneParameter,
   static,
   variables=[
    #this,
    a]
  */
  /*ddc.
   member=ExtensionType|constructor#oneParameter,
   static,
   variables=[a]
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
  /*cfe.
   member=ExtensionType|constructor#twoParameters,
   static,
   variables=[
    #this,
    a,
    b]
  */
  /*ddc.
   member=ExtensionType|constructor#twoParameters,
   static,
   variables=[
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
  /*cfe.
   member=ExtensionType|constructor#optionalParameter,
   static,
   variables=[
    #this,
    a,
    b]
  */
  /*ddc.
   member=ExtensionType|constructor#optionalParameter,
   static,
   variables=[
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
  /*cfe.
   member=ExtensionType|constructor#namedParameter,
   static,
   variables=[
    #this,
    a,
    b]
  */
  /*ddc.
   member=ExtensionType|constructor#namedParameter,
   static,
   variables=[
    a,
    b]
  */
  x;
  }

  empty() {
    /*cfe.
     member=ExtensionType|empty,
     static,
     variables=[#this]
    */
    /*ddc.
     member=ExtensionType|get#empty,
     static,
     variables=[#this]
    */
    x;
  }

  oneParameter(a) {
    /*cfe.
     member=ExtensionType|oneParameter,
     static,
     variables=[
      #this,
      a]
    */
    /*ddc.
     member=ExtensionType|get#oneParameter,
     static,
     variables=[
      #this,
      a]
    */
    x;
  }

  twoParameters(a, b) {
    /*cfe.
     member=ExtensionType|twoParameters,
     static,
     variables=[
      #this,
      a,
      b]
    */
    /*ddc.
     member=ExtensionType|get#twoParameters,
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
     member=ExtensionType|optionalParameter,
     static,
     variables=[
      #this,
      a,
      b]
    */
    /*ddc.
     member=ExtensionType|get#optionalParameter,
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
     member=ExtensionType|namedParameter,
     static,
     variables=[
      #this,
      a,
      b]
    */
    /*ddc.
     member=ExtensionType|get#namedParameter,
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
     member=ExtensionType|oneTypeParameter,
     static,
     typeParameters=[ExtensionType|oneTypeParameter.T],
     variables=[#this]
    */
    /*ddc.
     member=ExtensionType|get#oneTypeParameter,
     static,
     typeParameters=[
      ExtensionType|oneTypeParameter.T,
      T],
     variables=[#this]
    */
    x;
  }
}

extension type GenericExtension<T>(T field) {
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
