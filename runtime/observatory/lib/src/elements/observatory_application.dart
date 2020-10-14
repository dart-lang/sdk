// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library observatory_application_element;

import 'package:observatory/app.dart';
import 'package:observatory/src/elements/helpers/custom_element.dart';

/// Main application tag. Responsible for instantiating an instance of
/// [ObservatoryApplication] which is passed declaratively to all child
/// elements.
class ObservatoryApplicationElement extends CustomElement {
  late ObservatoryApplication app;

  ObservatoryApplicationElement.created()
      : super.created('observatory-application');

  @override
  void attached() {
    super.attached();
    app = new ObservatoryApplication(this);
  }
}
