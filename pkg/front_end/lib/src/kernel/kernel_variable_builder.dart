// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../base/lookup_result.dart';
import '../builder/builder.dart';
import '../builder/variable_builder.dart';
import 'internal_ast.dart';

class VariableBuilderImpl extends NamedBuilderImpl
    with LookupResultMixin
    implements VariableBuilder {
  @override
  final String name;

  @override
  final Uri fileUri;

  @override
  final InternalVariable variable;

  new(this.name, this.variable, this.fileUri);

  @override
  // Coverage-ignore(suite): Not run.
  Builder? get parent => null;

  @override
  int get fileOffset => variable.fileOffset;

  @override
  bool get isConst => variable.isConst;

  @override
  bool get isAssignable => variable.isAssignable;

  @override
  NamedBuilder get getable => this;

  @override
  NamedBuilder? get setable => isAssignable ? this : null;

  @override
  // Coverage-ignore(suite): Not run.
  String get fullNameForErrors => variable.cosmeticName ?? "<unnamed>";

  @override
  bool get isPrimaryConstructorParameter => false;

  @override
  bool get isFinal => variable.isFinal;

  @override
  bool get isLate => variable.isLate;

  @override
  String toString() => 'VariableBuilderImpl($fullNameForErrors)';
}
