// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.19

import 'dart:ffi';

// final class Double { ... }

class WithFinal with Double {} /* Error */

class ImplementsFinal implements Double {} /* Error */

class ExtendsFinal extends Double {} /* Error */

// abstract base class Opaque { ... }

// Does not need the base modifier to be propagated.
class ExtendsBase extends Opaque {} /* Ok */

class ImplementsBase implements Opaque {} /* Error */

// abstract interface class Finalizable { ... }

class ExtendsInterface extends Finalizable {} /* Error */
