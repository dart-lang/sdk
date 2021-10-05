// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class RawMaterialButton extends StatefulWidget {
  final Widget? child;
  final VoidCallback? onPressed;

  const RawMaterialButton({ Key? key, required this.onPressed, this.child });
}
