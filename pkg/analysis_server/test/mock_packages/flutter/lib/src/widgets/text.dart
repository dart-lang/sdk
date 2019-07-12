// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'framework.dart';

class DefaultTextStyle extends StatelessWidget {
  DefaultTextStyle({Widget child});
}

class Text extends StatelessWidget {
  final String data;

  const Text(
    this.data, {
    Key key,
  }) : super(key: key);
}
