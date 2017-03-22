// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.correction.flutter_util;

String flutterPkgLibPath = '/packages/flutter/lib';

String get flutter_framework_code => '''
class Widget {}
class RenderObjectWidget extends Widget {}
class StatelessWidget extends Widget {}
class SingleChildRenderObjectWidget extends RenderObjectWidget {}
class Transform extends SingleChildRenderObjectWidget {}
class ClipRect extends SingleChildRenderObjectWidget { ClipRect.rect(){} }
class AspectRatio extends SingleChildRenderObjectWidget {}
class Container extends StatelessWidget { Container({child: null, width: null, height: null}){}}
class Center extends StatelessWidget { Center({child: null, key: null}){}}
class DefaultTextStyle extends StatelessWidget { DefaultTextStyle({child: null}){}}
class Row extends Widget { Row({List<Widget> children: null}){}}
class GestureDetector extends SingleChildRenderObjectWidget { GestureDetector({child: null, onTap: null}){}}
class Scaffold extends Widget { Scaffold({body: null}){}}
''';
