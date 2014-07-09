// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library function_view_element;

import 'observatory_element.dart';
import 'package:observatory/service.dart';

import 'package:polymer/polymer.dart';

@CustomTag('function-view')
class FunctionViewElement extends ObservatoryElement {
  @published ServiceMap function;
  FunctionViewElement.created() : super.created();

  // TODO(turnidge): Once we create a Function object, these fields
  // should move there.
  @published String qualifiedName;
  @published String kind;

  String _getQualifiedName(ServiceMap function) {
    var parent = (function != null && function['parent'] != null
                  ? function['parent'] : null);
    if (parent != null) {
      return "${_getQualifiedName(parent)}.${function['user_name']}";
    }
    Class cls = (function != null &&
                 function['owner'] != null &&
                 function['owner'].serviceType == 'Class'
                   ? function['owner'] : null);
    if (cls != null) {
      return "${cls.name}.${function['user_name']}";
    }
    return "${function['user_name']}";
  }

  void functionChanged(oldValue) {
    notifyPropertyChange(#qualifiedName, 0, 1);
    notifyPropertyChange(#kind, 0, 1);
    qualifiedName = _getQualifiedName(function);
    switch(function['kind']) {
      case 'kRegularFunction':
        kind = 'function';
        break;
      case 'kClosureFunction':
        kind = 'closure function';
        break;
      case 'kSignatureFunction':
        kind = 'signature function';
        break;
      case 'kGetterFunction':
        kind = 'getter function';
        break;
      case 'kSetterFunction':
        kind = 'setter function';
        break;
      case 'kConstructor':
        kind = 'constructor';
        break;
      case 'kImplicitGetterFunction':
        kind = 'implicit getter function';
        break;
      case 'kImplicitSetterFunction':
        kind = 'implicit setter function';
        break;
      case 'kStaticInitializer':
        kind = 'static initializer';
        break;
      case 'kMethodExtractor':
        kind = 'method extractor';
        break;
      case 'kNoSuchMethodDispatcher':
        kind = 'noSuchMethod dispatcher';
        break;
      case 'kInvokeFieldDispatcher':
        kind = 'invoke field dispatcher';
        break;
      default:
        kind = 'UNKNOWN';
        break;
    }
  }

  void refresh(var done) {
    function.reload().whenComplete(done);
  }
}
