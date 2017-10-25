// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';

String flutterPkgLibPath = '/packages/flutter/lib';

String get flutter_framework_code => '''
class Widget {}
class RenderObjectWidget extends Widget {}
class StatelessWidget extends Widget {}
abstract class StatefulWidget extends Widget { }
class SingleChildRenderObjectWidget extends RenderObjectWidget {}
class Transform extends SingleChildRenderObjectWidget {}
class ClipRect extends SingleChildRenderObjectWidget { ClipRect.rect(){} }
class AspectRatio extends SingleChildRenderObjectWidget {}
class Container extends StatelessWidget { Container({child: null, width: null, height: null}){}}
class Center extends StatelessWidget { Center({child: null, key: null}){}}
class DefaultTextStyle extends StatelessWidget { DefaultTextStyle({child: null}){}}
class Row extends Widget { Row({List<Widget> children: null, key: null}){}}
class GestureDetector extends SingleChildRenderObjectWidget { GestureDetector({child: null, onTap: null}){}}
class AppBar extends StatefulWidget implements PreferredSizeWidget { AppBar(title: null, color: null, key: null) }
class Scaffold extends Widget { Scaffold({body: null, PreferredSizeWidget appBar: null}){}}
class PreferredSizeWidget implements Widget {}
''';

/**
 * Add some Flutter libraries and types to the given [provider] and return
 * the `lib` folder.
 */
Folder configureFlutterPackage(MemoryResourceProvider provider) {
  File newFile(String path, String content) =>
      provider.newFile(provider.convertPath(path), content ?? '');

  Folder newFolder(String path) =>
      provider.newFolder(provider.convertPath(path));

  newFile('/flutter/lib/material.dart', r'''
export 'widgets.dart';
export 'src/material/icons.dart';
''');

  newFile('/flutter/lib/widgets.dart', r'''
export 'src/widgets/basic.dart';
export 'src/widgets/container.dart';
export 'src/widgets/framework.dart';
export 'src/widgets/icon.dart';
export 'src/widgets/text.dart';
''');

  void createSrcMaterial() {
    newFile('/flutter/lib/src/material/icons.dart', r'''
import 'package:flutter/widgets.dart';

class Icons {
  static const IconData alarm =
      const IconData(0xe855, fontFamily: 'MaterialIcons');
  static const IconData book =
      const IconData(0xe865, fontFamily: 'MaterialIcons');
  Icons._();
}
''');
  }

  void createSrcWidgets() {
    newFile('/flutter/lib/src/widgets/basic.dart', r'''
import 'framework.dart';

class Column extends Flex {
  Column({
    Key key,
    List<Widget> children: const <Widget>[],
  });
}

class Row extends Flex {
  Row({
    Key key,
    List<Widget> children: const <Widget>[],
  });
}

class Flex extends Widget {
  Flex({
    Key key,
    List<Widget> children: const <Widget>[],
  });
}
''');

    newFile('/flutter/lib/src/widgets/container.dart', r'''
import 'framework.dart';

class Container extends StatelessWidget {
  final Widget child;
  Container({
    Key key,
    double width,
    double height,
    this.child,
  })
      : super(key: key);

  @override
  Widget build(BuildContext context) => child;
}
''');

    newFile('/flutter/lib/src/widgets/framework.dart', r'''
typedef void VoidCallback();

abstract class BuildContext {
  Widget get widget;
}

abstract class Key {
  const factory Key(String value) = ValueKey<String>;

  const Key._();
}

abstract class LocalKey extends Key {
  const LocalKey() : super._();
}

abstract class State<T extends StatefulWidget> {
  BuildContext get context => null;

  T get widget => null;

  Widget build(BuildContext context) {}

  void dispose() {}

  void setState(VoidCallback fn) {}
}

abstract class StatefulWidget extends Widget {
  const StatefulWidget({Key key}) : super(key: key);

  State createState() => null
}

abstract class StatelessWidget extends Widget {
  const StatelessWidget({Key key}) : super(key: key);

  Widget build(BuildContext context) => null;
}

class ValueKey<T> extends LocalKey {
  final T value;

  const ValueKey(this.value);
}

class Widget {
  final Key key;

  const Widget({this.key});
}
''');

    newFile('/flutter/lib/src/widgets/icon.dart', r'''
import 'framework.dart';

class Icon extends StatelessWidget {
  final IconData icon;
  const Icon(
    this.icon, {
    Key key,
  })
      : super(key: key);
}

class IconData {
  final int codePoint;
  final String fontFamily;
  const IconData(
    this.codePoint, {
    this.fontFamily,
  });
}
''');

    newFile('/flutter/lib/src/widgets/text.dart', r'''
import 'framework.dart';

class Text extends StatelessWidget {
  final String data;
  const Text(
    this.data, {
    Key key,
  })
      : super(key: key);
}
''');
  }

  createSrcMaterial();
  createSrcWidgets();

  return newFolder('/flutter/lib');
}
