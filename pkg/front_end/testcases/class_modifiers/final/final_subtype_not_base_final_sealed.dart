// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

final class FinalClass {} /* Ok */
final mixin FinalMixin {} /* Ok */
base class BaseClass extends FinalClass {} /* Ok */
sealed class SubtypeOfFinal extends FinalClass {} /* Ok */
class RegularClass {} /* Ok */
final mixin FinalMixin2 {} /* Ok */

class Extends extends FinalClass {} /* Error */

class Implements implements FinalClass {} /* Error */

mixin MixinImplements implements FinalMixin {} /* Error */

class With with FinalMixin {} /* Error */

class With2 with FinalMixin, FinalMixin2 {} /* Error */

mixin On on FinalClass {} /* Error */

class ExtendsExtends extends Extends {} /* Error */

class Multiple extends BaseClass implements FinalMixin {} /* Error */

class Multiple2 extends RegularClass implements FinalClass {} /* Error */

class IndirectSubtype extends SubtypeOfFinal {} /* Error */
