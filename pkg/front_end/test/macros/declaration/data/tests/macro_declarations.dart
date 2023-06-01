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

macro class Extends extends /*error: error=InterfaceClassExtendedOutsideOfLibrary*/Macro {}

macro class Implements implements Macro {}

macro class Mixin with /*error: error=CantUseClassAsMixin*/Macro {}

mixin _Mixin {}

macro class NamedMixin1 = /*error: error=InterfaceClassExtendedOutsideOfLibrary*/Macro with _Mixin;

macro class NamedMixin2 = Object with /*error: error=CantUseClassAsMixin*/Macro;

typedef Alias = Macro;

macro class ExtendsAlias extends /*error: error=InterfaceClassExtendedOutsideOfLibrary*/Alias {}

macro class ImplementsAlias implements Alias {}

macro class MixinAlias with /*error: error=CantUseClassAsMixin*/Alias {}

class /*error: error=MacroClassNotDeclaredMacro*/ExtendsNoKeyword extends /*error: error=InterfaceClassExtendedOutsideOfLibrary*/Macro {}

class /*error: error=MacroClassNotDeclaredMacro*/ImplementsNoKeyword implements Macro {}

class /*error: error=MacroClassNotDeclaredMacro*/MixinNoKeyword with /*error: error=CantUseClassAsMixin*/Macro {}

class /*error: error=MacroClassNotDeclaredMacro*/ExtendsAliasNoKeyword extends /*error: error=InterfaceClassExtendedOutsideOfLibrary*/Alias {}

class /*error: error=MacroClassNotDeclaredMacro*/ImplementsAliasNoKeyword implements Alias {}

class /*error: error=MacroClassNotDeclaredMacro*/MixinAliasNoKeyword with /*error: error=CantUseClassAsMixin*/Alias {}

class /*error: error=MacroClassNotDeclaredMacro*/NamedMixin1NoKeyword = /*error: error=InterfaceClassExtendedOutsideOfLibrary*/Macro with _Mixin;

class /*error: error=MacroClassNotDeclaredMacro*/NamedMixin2NoKeyword = Object with /*error: error=CantUseClassAsMixin*/Macro;

void main() {}
