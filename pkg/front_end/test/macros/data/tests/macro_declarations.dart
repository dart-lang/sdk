// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: 
 compilationSequence=[
  package:macro_builder/src/macro.dart,
  main.dart|package:macro_builder/macro_builder.dart],
 declaredMacros=[
  Extends,
  ExtendsAlias,
  Implements,
  ImplementsAlias,
  Mixin,
  MixinAlias,
  _Mixin&Object&Macro,
  _MixinAlias&Object&Alias],
 macrosAreAvailable
*/

import 'package:macro_builder/macro_builder.dart';

class Extends extends Macro {}

class Implements implements Macro {}

class Mixin with Macro {}

typedef Alias = Macro;

class ExtendsAlias extends Alias {}

class ImplementsAlias implements Alias {}

class MixinAlias with Alias {}

void main() {}
