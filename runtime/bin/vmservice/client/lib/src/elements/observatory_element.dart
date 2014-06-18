// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library observatory_element;

import 'dart:html';
import 'package:observatory/app.dart';
import 'package:polymer/polymer.dart';

/// Base class for all Observatory custom elements.
@CustomTag('observatory-element')
class ObservatoryElement extends PolymerElement {
  ObservatoryElement.created() : super.created();

  @override
  void attached() {
    super.attached();
  }

  @override
  void attributeChanged(String name, var oldValue, var newValue) {
    super.attributeChanged(name, oldValue, newValue);
  }

  @override
  void detached() {
    super.detached();
  }

  void ready() {
    super.ready();
  }

  void goto(MouseEvent event, var detail, Element target) {
    location.onGoto(event, detail, target);
  }

  String gotoLink(String url) {
    return location.makeLink(url);
  }



  String formatTimePrecise(double time) => Utils.formatTimePrecise(time);

  String formatTime(double time) => Utils.formatTime(time);

  String formatSeconds(double x) => Utils.formatSeconds(x);


  String formatSize(int bytes) => Utils.formatSize(bytes);

  String fileAndLine(Map frame) {
    var file = frame['script']['user_name'];
    var shortFile = file.substring(file.lastIndexOf('/') + 1);
    return "${shortFile}:${frame['line']}";
  }

  bool isNull(String type) {
    return type == 'Null';
  }

  bool isError(String type) {
    return type == 'Error';
  }

  bool isInt(String type) {
    return (type == 'Smi' ||
            type == 'Mint' ||
            type == 'Bigint');
  }

  bool isBool(String type) {
    return type == 'Bool';
  }

  bool isString(String type) {
    return type == 'String';
  }

  bool isInstance(String type) {
    return type == 'Instance';
  }

  bool isDouble(String type) {
    return type == 'Double';
  }

  bool isList(String type) {
    return (type == 'GrowableObjectArray' ||
            type == 'Array');
  }

  bool isType(String type) {
    return (type == 'Type');
  }

  bool isUnexpected(String type) {
    return (!['Null',
              'Smi',
              'Mint',
              'Bigint',
              'Bool',
              'String',
	      'Double',
              'Instance',
              'GrowableObjectArray',
              'Array',
              'Type',
              'Error'].contains(type));
  }
}
