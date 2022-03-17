// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `dart test -N use_key_in_widget_constructors`

// todo(pq): re-enable (or migrate) when mocked Flutter packages can be resolved internally
// see: https://github.com/dart-lang/linter/issues/3296

// import 'package:flutter/foundation.dart';
// import 'package:flutter/widgets.dart';
//
// /// https://github.com/flutter/flutter/issues/100297
// class OtherWidget extends StatelessWidget {
//   const OtherWidget({required super.key}); //OK
//
//   @override
//   Widget build(BuildContext context) {
//     return Container();
//   }
// }

