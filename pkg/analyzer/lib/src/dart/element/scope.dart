// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/standard_ast_factory.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/scope.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/dart/resolver/scope.dart' as impl;
import 'package:meta/meta.dart';

class LibraryScope implements Scope {
  final LibraryElement _libraryElement;
  final impl.LibraryScope _implScope;

  LibraryScope(LibraryElement libraryElement)
      : _libraryElement = libraryElement,
        _implScope = impl.LibraryScope(libraryElement);

  @override
  Element lookup({@required String id, @required bool setter}) {
    var name = setter ? '$id=' : id;
    var token = SyntheticStringToken(TokenType.IDENTIFIER, name, 0);
    var identifier = astFactory.simpleIdentifier(token);
    return _implScope.lookup(identifier, _libraryElement);
  }
}
