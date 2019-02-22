// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N diagnostic_describe_all_properties`

class DiagnosticPropertiesBuilder {
  void add(DiagnosticsProperty property) {}
}

class DiagnosticsProperty<T> {}

class StringProperty extends DiagnosticsProperty<String> {
  StringProperty(
    String name,
    String value, {
    String description,
    String tooltip,
    bool showName = true,
    Object defaultValue,
    bool quoted,
    String ifEmpty,
    //DiagnosticLevel level = DiagnosticLevel.info,
  });
}

abstract class Diagnosticable {
  void debugFillProperties(DiagnosticPropertiesBuilder properties);
}

class Widget {}

class MyWidget extends Diagnosticable {
  Widget p0; //Skipped
  List<Widget> p00; //Skipped
  Widget get p000 => null; //Skipped
  String p1; //OK
  String p2; //LINT
  String get p3 => ''; //LINT

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
        .add(StringProperty('property', p1, defaultValue: null, quoted: false));
  }
}
