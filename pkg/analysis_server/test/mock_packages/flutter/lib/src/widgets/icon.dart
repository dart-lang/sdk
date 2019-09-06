// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'framework.dart';

class Icon extends StatelessWidget {
  final IconData icon;

  const Icon(
    this.icon, {
    Key key,
  }) : super(key: key);
}

class IconData {
  final int codePoint;
  final String fontFamily;

  const IconData(
    this.codePoint, {
    this.fontFamily,
  });
}
