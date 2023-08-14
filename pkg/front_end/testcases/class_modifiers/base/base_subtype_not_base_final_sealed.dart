// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

base class BaseClass {} /* Ok */

base mixin BaseMixin {} /* Ok */

final class FinalClass extends BaseClass {} /* Ok */

sealed class SubtypeOfBase extends BaseClass {} /* Ok */

class RegularClass {} /* Ok */

base mixin BaseMixin2 {} /* Ok */

class Extends extends BaseClass {} /* Error */

class Implements implements BaseClass {} /* Error */

mixin MixinImplements implements BaseMixin {} /* Error */

mixin MixinImplementsIndirect implements SubtypeOfBase {} /* Error */

class With with BaseMixin {} /* Error */

class With2 with BaseMixin, BaseMixin2 {} /* Error */

mixin On on BaseClass {} /* Error */

// Only report errors on the nearest erroneous subtype.
class ExtendsExtends extends Extends {} /* Ok */

class Multiple extends FinalClass implements BaseMixin {} /* Error */

class Multiple2 extends RegularClass implements BaseClass {} /* Error */

class IndirectSubtype extends SubtypeOfBase {} /* Error */
