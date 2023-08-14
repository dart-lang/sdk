// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

final class FinalClass {} /* Ok */

base class BaseClass extends FinalClass {} /* Ok */

sealed class SubtypeOfFinal extends FinalClass {} /* Ok */

class RegularClass {} /* Ok */

class Extends extends FinalClass {} /* Error */

class Implements implements FinalClass {} /* Error */

mixin MixinImplements implements FinalClass {} /* Error */

mixin MixinImplementsIndirect implements SubtypeOfFinal {} /* Error */

mixin On on FinalClass {} /* Error */

// Only report errors on the nearest erroneous subtype.
class ExtendsExtends extends Extends {} /* Ok */

class Multiple extends RegularClass implements FinalClass {} /* Error */

class IndirectSubtype extends SubtypeOfFinal {} /* Error */
