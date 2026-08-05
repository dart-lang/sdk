// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Library which defines some classes and mixins to be used to test behaviors
/// across libraries.

class SimpleClass {}

interface class InterfaceClass {}

base class BaseClass {}
//         ^^^^^^^^^
// [context 1 for base_class_different_library_error_test.dart] The type 'SealedExtend' is a subtype of 'BaseClass', and 'BaseClass' is defined here.
// [context 2 for base_class_different_library_error_test.dart] The type 'SealedExtend' is a subtype of 'BaseClass', and 'BaseClass' is defined here.
// [context 3 for base_class_different_library_error_test.dart] The type 'SealedExtend' is a subtype of 'BaseClass', and 'BaseClass' is defined here.
// [context 4 for base_class_different_library_error_test.dart] The type 'SealedExtend' is a subtype of 'BaseClass', and 'BaseClass' is defined here.
// [context 5 for base_class_different_library_error_test.dart] The type 'SealedExtend' is a subtype of 'BaseClass', and 'BaseClass' is defined here.
// [context 6 for base_class_different_library_error_test.dart] The type 'SealedExtend' is a subtype of 'BaseClass', and 'BaseClass' is defined here.
// [context 7 for base_class_different_library_error_test.dart] The type 'SealedExtend' is a subtype of 'BaseClass', and 'BaseClass' is defined here.
// [context 8 for base_class_different_library_error_test.dart] The type 'SealedExtend' is a subtype of 'BaseClass', and 'BaseClass' is defined here.
// [context 9 for base_class_different_library_error_test.dart] The type 'SealedExtend' is a subtype of 'BaseClass', and 'BaseClass' is defined here.
// [context 10 for base_class_different_library_error_test.dart] The type 'SealedExtend' is a subtype of 'BaseClass', and 'BaseClass' is defined here.
// [context 11 for base_class_different_library_error_test.dart] The type 'SealedExtend' is a subtype of 'BaseClass', and 'BaseClass' is defined here.
// [context 12 for base_class_different_library_error_test.dart] The type 'SealedExtend' is a subtype of 'BaseClass', and 'BaseClass' is defined here.

final class FinalClass {}

sealed class SealedClass {}

base mixin class BaseMixinClass {}
//               ^^^^^^^^^^^^^^
// [context 1 for base_mixin_class_different_library_error_test.dart] The type 'SealedExtend' is a subtype of 'BaseMixinClass', and 'BaseMixinClass' is defined here.
// [context 2 for base_mixin_class_different_library_error_test.dart] The type 'SealedExtend' is a subtype of 'BaseMixinClass', and 'BaseMixinClass' is defined here.
// [context 3 for base_mixin_class_different_library_error_test.dart] The type 'SealedExtend' is a subtype of 'BaseMixinClass', and 'BaseMixinClass' is defined here.
// [context 4 for base_mixin_class_different_library_error_test.dart] The type 'SealedExtend' is a subtype of 'BaseMixinClass', and 'BaseMixinClass' is defined here.
// [context 5 for base_mixin_class_different_library_error_test.dart] The type 'SealedExtend' is a subtype of 'BaseMixinClass', and 'BaseMixinClass' is defined here.
// [context 6 for base_mixin_class_different_library_error_test.dart] The type 'SealedExtend' is a subtype of 'BaseMixinClass', and 'BaseMixinClass' is defined here.
// [context 7 for base_mixin_class_different_library_error_test.dart] The type 'SealedExtend' is a subtype of 'BaseMixinClass', and 'BaseMixinClass' is defined here.
// [context 8 for base_mixin_class_different_library_error_test.dart] The type 'SealedExtend' is a subtype of 'BaseMixinClass', and 'BaseMixinClass' is defined here.
// [context 9 for base_mixin_class_different_library_error_test.dart] The type 'SealedExtend' is a subtype of 'BaseMixinClass', and 'BaseMixinClass' is defined here.
// [context 10 for base_mixin_class_different_library_error_test.dart] The type 'SealedExtend' is a subtype of 'BaseMixinClass', and 'BaseMixinClass' is defined here.
// [context 11 for base_mixin_class_different_library_error_test.dart] The type 'SealedExtend' is a subtype of 'BaseMixinClass', and 'BaseMixinClass' is defined here.
// [context 12 for base_mixin_class_different_library_error_test.dart] The type 'SealedExtend' is a subtype of 'BaseMixinClass', and 'BaseMixinClass' is defined here.
// [context 13 for base_mixin_class_different_library_error_test.dart] The type 'SealedMixinClassApply' is a subtype of 'BaseMixinClass', and 'BaseMixinClass' is defined here.
// [context 14 for base_mixin_class_different_library_error_test.dart] The type 'SealedMixinClassApply' is a subtype of 'BaseMixinClass', and 'BaseMixinClass' is defined here.
// [context 15 for base_mixin_class_different_library_error_test.dart] The type 'SealedMixinClassApply' is a subtype of 'BaseMixinClass', and 'BaseMixinClass' is defined here.
// [context 16 for base_mixin_class_different_library_error_test.dart] The type 'SealedMixinClassApply' is a subtype of 'BaseMixinClass', and 'BaseMixinClass' is defined here.
// [context 17 for base_mixin_class_different_library_error_test.dart] The type 'SealedMixinClassApply' is a subtype of 'BaseMixinClass', and 'BaseMixinClass' is defined here.
// [context 18 for base_mixin_class_different_library_error_test.dart] The type 'SealedMixinClassApply' is a subtype of 'BaseMixinClass', and 'BaseMixinClass' is defined here.
// [context 19 for base_mixin_class_different_library_error_test.dart] The type 'SealedMixinClassApply' is a subtype of 'BaseMixinClass', and 'BaseMixinClass' is defined here.
// [context 20 for base_mixin_class_different_library_error_test.dart] The type 'SealedMixinApplication' is a subtype of 'BaseMixinClass', and 'BaseMixinClass' is defined here.
// [context 21 for base_mixin_class_different_library_error_test.dart] The type 'SealedMixinApplication' is a subtype of 'BaseMixinClass', and 'BaseMixinClass' is defined here.
// [context 22 for base_mixin_class_different_library_error_test.dart] The type 'SealedMixinApplication' is a subtype of 'BaseMixinClass', and 'BaseMixinClass' is defined here.
// [context 23 for base_mixin_class_different_library_error_test.dart] The type 'SealedMixinApplication' is a subtype of 'BaseMixinClass', and 'BaseMixinClass' is defined here.
// [context 24 for base_mixin_class_different_library_error_test.dart] The type 'SealedMixinApplication' is a subtype of 'BaseMixinClass', and 'BaseMixinClass' is defined here.
// [context 25 for base_mixin_class_different_library_error_test.dart] The type 'SealedMixinApplication' is a subtype of 'BaseMixinClass', and 'BaseMixinClass' is defined here.
// [context 26 for base_mixin_class_different_library_error_test.dart] The type 'SealedMixinApplication' is a subtype of 'BaseMixinClass', and 'BaseMixinClass' is defined here.

base mixin BaseMixin {}
//         ^^^^^^^^^
// [context 1 for base_mixin_different_library_error_test.dart] The type 'SealedMixinApply' is a subtype of 'BaseMixin', and 'BaseMixin' is defined here.
// [context 2 for base_mixin_different_library_error_test.dart] The type 'SealedMixinApply' is a subtype of 'BaseMixin', and 'BaseMixin' is defined here.
// [context 3 for base_mixin_different_library_error_test.dart] The type 'SealedMixinApply' is a subtype of 'BaseMixin', and 'BaseMixin' is defined here.
// [context 4 for base_mixin_different_library_error_test.dart] The type 'SealedMixinApply' is a subtype of 'BaseMixin', and 'BaseMixin' is defined here.
// [context 5 for base_mixin_different_library_error_test.dart] The type 'SealedMixinApply' is a subtype of 'BaseMixin', and 'BaseMixin' is defined here.
// [context 6 for base_mixin_different_library_error_test.dart] The type 'SealedMixinApply' is a subtype of 'BaseMixin', and 'BaseMixin' is defined here.
// [context 7 for base_mixin_different_library_error_test.dart] The type 'SealedMixinApply' is a subtype of 'BaseMixin', and 'BaseMixin' is defined here.
// [context 8 for base_mixin_different_library_error_test.dart] The type 'SealedMixinApplication' is a subtype of 'BaseMixin', and 'BaseMixin' is defined here.
// [context 9 for base_mixin_different_library_error_test.dart] The type 'SealedMixinApplication' is a subtype of 'BaseMixin', and 'BaseMixin' is defined here.
// [context 10 for base_mixin_different_library_error_test.dart] The type 'SealedMixinApplication' is a subtype of 'BaseMixin', and 'BaseMixin' is defined here.
// [context 11 for base_mixin_different_library_error_test.dart] The type 'SealedMixinApplication' is a subtype of 'BaseMixin', and 'BaseMixin' is defined here.
// [context 12 for base_mixin_different_library_error_test.dart] The type 'SealedMixinApplication' is a subtype of 'BaseMixin', and 'BaseMixin' is defined here.
// [context 13 for base_mixin_different_library_error_test.dart] The type 'SealedMixinApplication' is a subtype of 'BaseMixin', and 'BaseMixin' is defined here.
// [context 14 for base_mixin_different_library_error_test.dart] The type 'SealedMixinApplication' is a subtype of 'BaseMixin', and 'BaseMixin' is defined here.
