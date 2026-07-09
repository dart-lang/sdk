// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_testing/src/mock_packages/mock_library.dart';

final paintingBorderRadiusLibrary = MockLibraryUnit(
  'lib/src/painting/border_radius.dart',
  r'''
import 'package:flutter/foundation.dart';
import 'basic_types.dart';

class BorderRadius extends BorderRadiusGeometry {
  static const BorderRadius zero = BorderRadius.all(Radius.zero);

  final Radius topLeft;

  final Radius topRight;

  final Radius bottomLeft;

  final Radius bottomRight;

  const BorderRadius.all(Radius radius)
    : this.only(
        topLeft: radius,
        topRight: radius,
        bottomLeft: radius,
        bottomRight: radius,
      );

  BorderRadius.circular(double radius);

  const BorderRadius.horizontal({
    Radius left = Radius.zero,
    Radius right = Radius.zero,
  }) : this.only(
         topLeft: left,
         topRight: right,
         bottomLeft: left,
         bottomRight: right,
       );

  const BorderRadius.only({
    this.topLeft = Radius.zero,
    this.topRight = Radius.zero,
    this.bottomLeft = Radius.zero,
    this.bottomRight = Radius.zero,
  });

  const BorderRadius.vertical({
    Radius top = Radius.zero,
    Radius bottom = Radius.zero,
  }) : this.only(
         topLeft: top,
         topRight: top,
         bottomLeft: bottom,
         bottomRight: bottom,
       );
}

class BorderRadiusDirectional extends BorderRadiusGeometry {
  static const BorderRadiusDirectional zero = BorderRadiusDirectional.all(
    Radius.zero,
  );

  final Radius topStart;

  final Radius topEnd;

  final Radius bottomStart;

  final Radius bottomEnd;

  const BorderRadiusDirectional.all(Radius radius)
    : this.only(
        topStart: radius,
        topEnd: radius,
        bottomStart: radius,
        bottomEnd: radius,
      );

  BorderRadiusDirectional.circular(double radius);

  const BorderRadiusDirectional.horizontal({
    Radius start = Radius.zero,
    Radius end = Radius.zero,
  }) : this.only(
         topStart: start,
         topEnd: end,
         bottomStart: start,
         bottomEnd: end,
       );

  const BorderRadiusDirectional.only({
    this.topStart = Radius.zero,
    this.topEnd = Radius.zero,
    this.bottomStart = Radius.zero,
    this.bottomEnd = Radius.zero,
  });

  const BorderRadiusDirectional.vertical({
    Radius top = Radius.zero,
    Radius bottom = Radius.zero,
  }) : this.only(
         topStart: top,
         topEnd: top,
         bottomStart: bottom,
         bottomEnd: bottom,
       );
}

@immutable
abstract class BorderRadiusGeometry {
  const BorderRadiusGeometry();
}
''',
);
