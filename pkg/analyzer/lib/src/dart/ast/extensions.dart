// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/ast.dart';

extension FormalParameterExtension on FormalParameter {
  FormalParameter get notDefault {
    var self = this;
    if (self is DefaultFormalParameter) {
      return self.parameter;
    }
    return self;
  }

  AstNode get typeOrSelf {
    var self = this;
    if (self is SimpleFormalParameter) {
      return self.type;
    }
    return self;
  }
}

extension ListOfFormalParameterExtension on List<FormalParameter> {
  Iterable<FormalParameterImpl> get asImpl {
    return cast<FormalParameterImpl>();
  }
}
