// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library function_ref_element;

import 'package:polymer/polymer.dart';
import 'package:observatory/service.dart';
import 'service_ref.dart';

@CustomTag('function-ref')
class FunctionRefElement extends ServiceRefElement {
  @published bool qualified = true;

  void refChanged(oldValue) {
    super.refChanged(oldValue);
    notifyPropertyChange(#hasParent, 0, 1);
    notifyPropertyChange(#hasClass, 0, 1);
    ServiceMap refMap = ref;
    isDart = (refMap != null) &&
             (refMap['kind'] != 'Collected') &&
             (refMap['kind'] != 'Native') &&
             (refMap['kind'] != 'Tag') &&
             (refMap['kind'] != 'Reused');
    hasParent = (refMap != null && refMap['parent'] != null);
    hasClass = (refMap != null &&
                refMap['owner'] != null &&
                refMap['owner'].serviceType == 'Class');
  }

  @observable bool hasParent = false;
  @observable bool hasClass = false;
  @observable bool isDart = false;

  FunctionRefElement.created() : super.created();
}
