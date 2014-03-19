// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library function_ref_element;

import 'package:polymer/polymer.dart';
import 'service_ref.dart';

@CustomTag('function-ref')
class FunctionRefElement extends ServiceRefElement {
  @published bool qualified = true;

  void refChanged(oldValue) {
    super.refChanged(oldValue);
    notifyPropertyChange(#hasParent, 0, 1);
    notifyPropertyChange(#hasClass, 0, 1);
    hasParent = (ref != null && ref['parent'] != null);
    hasClass = (ref != null &&
                ref['class'] != null &&
                ref['class']['name'] != null &&
                ref['class']['name'] != '::');
  }

  @observable bool hasParent = false;
  @observable bool hasClass = false;

  FunctionRefElement.created() : super.created();
}
