// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library code_ref_element;

import 'package:polymer/polymer.dart';
import 'service_ref.dart';
import 'package:observatory/service.dart';

@CustomTag('code-ref')
class CodeRefElement extends ServiceRefElement {
  @observable Code get code => ref;

  refChanged(oldValue) {
    super.refChanged(oldValue);
    notifyPropertyChange(#code, 0, 1);
  }

  CodeRefElement.created() : super.created();
}
