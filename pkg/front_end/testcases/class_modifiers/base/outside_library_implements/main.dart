// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'main_lib.dart';

sealed class SealedClassExtendsBase extends A {} /* Ok */

class ClassImplementsIndirectBase
    implements SealedClassExtendsBase {} /* Error */

final class FinalClassImplementsIndirectBase
    implements SealedClassExtendsBase {} /* Error */

interface class InterfaceClassImplementsIndirectBase
    implements SealedClassExtendsBase {} /* Error */

sealed class SealedClassImplementsIndirectBase
    implements SealedClassExtendsBase {} /* Error */

base class BaseClassImplementsIndirectBase
    implements SealedClassExtendsBase {} /* Error */
