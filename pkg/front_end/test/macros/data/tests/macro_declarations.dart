// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: 
 compilationSequence=[main.dart|package:_fe_analyzer_shared/src/macros/api.dart],
 declaredMacros=[
  Extends,
  ExtendsAlias,
  Implements,
  ImplementsAlias,
  Mixin,
  MixinAlias,
  NamedMixin1,
  NamedMixin2],
 macrosAreAvailable
*/

import 'package:_fe_analyzer_shared/src/macros/api.dart';

macro class Extends extends Macro {}

macro class Implements implements Macro {}

macro class Mixin with Macro {}

mixin _Mixin {}

macro class NamedMixin1 = Macro with _Mixin;

macro class NamedMixin2 = Object with Macro;

typedef Alias = Macro;

macro class ExtendsAlias extends Alias {}

macro class ImplementsAlias implements Alias {}

macro class MixinAlias with Alias {}

class ExtendsNoKeyword extends Macro {}

class ImplementsNoKeyword implements Macro {}

class MixinNoKeyword with Macro {}

class ExtendsAliasNoKeyword extends Alias {}

class ImplementsAliasNoKeyword implements Alias {}

class MixinAliasNoKeyword with Alias {}

class NamedMixin1NoKeyword = Macro with _Mixin;

class NamedMixin2NoKeyword = Object with Macro;

void main() {}
