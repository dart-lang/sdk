// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Custom HTML tags, data binding, and templates for building
 * structured, encapsulated, client-side web apps.
 *
 * Polymer.dart, the next evolution of Web UI,
 * is an in-progress Dart port of the
 * [Polymer project](http://www.polymer-project.org/).
 * Polymer.dart compiles to JavaScript and runs across the modern web.
 *
 * To use polymer.dart in your application,
 * first add a
 * [dependency](http://pub.dartlang.org/doc/dependencies.html)
 * to the app's pubspec.yaml file.
 * Instead of using the open-ended `any` version specifier,
 * we recommend using a range of version numbers, as in this example:
 *
 *     dependencies:
 *       polymer: '>=0.7.1 <0.8'
 *
 * Then import the library into your application:
 *
 *     import 'package:polymer/polymer.dart';
 *
 * ## Other resources
 *
 * * [Polymer.dart homepage](http://www.dartlang.org/polymer-dart/):
 * Example code, project status, and
 * information about how to get started using Polymer.dart in your apps.
 *
 * * [polymer.dart package](http://pub.dartlang.org/packages/polymer):
 * More details, such as the current major release number.
 *
 * * [Upgrading to Polymer.dart](http://www.dartlang.org/polymer-dart/upgrading-to-polymer-from-web-ui.html):
 * Tips for converting your apps from Web UI to Polymer.dart.
 */
library polymer;

import 'dart:async';
import 'dart:collection' show HashMap;
import 'dart:html';
import 'dart:js' as js;

@MirrorsUsed(metaTargets:
    const [Reflectable, ObservableProperty, CustomTag, _InitMethodAnnotation],
    override: const ['polymer', 'polymer.deserialize'])
import 'dart:mirrors';

import 'package:custom_element/polyfill.dart' show customElementsReady;
import 'package:logging/logging.dart' show Logger, Level;
import 'package:observe/observe.dart';
import 'package:observe/src/dirty_check.dart' show dirtyCheckZone;
import 'package:path/path.dart' as path;
import 'package:polymer_expressions/polymer_expressions.dart'
    show PolymerExpressions;
import 'package:template_binding/template_binding.dart';

import 'deserialize.dart' as deserialize;

export 'package:observe/observe.dart';
export 'package:observe/html.dart';

part 'src/boot.dart';
part 'src/declaration.dart';
part 'src/instance.dart';
part 'src/job.dart';
part 'src/loader.dart';
