// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.binary.loader;

import '../repository.dart';
import '../ast.dart';
import 'tag.dart';
import 'dart:io';
import 'ast_from_binary.dart';

abstract class BinaryReferenceLoader {
  Library getLibraryReference(Library from, String relativePath);
  Class getClassReference(Library library, int tag, int index);
  Member getMemberReference(TreeNode classOrLibrary, int tag, int index);
  Member getLibraryMemberReference(Library library, int tag, int index);
  Member getClassMemberReference(Class classNode, int tag, int index);
}

class BinaryLoader implements BinaryReferenceLoader {
  final Repository repository;

  BinaryLoader(this.repository);

  Library getLibraryReference(Library from, String relativePath) {
    var fullUri = from.importUri.resolve(relativePath);
    return repository.getLibraryReference(fullUri);
  }

  static int _pow2roundup(int x) {
    --x;
    x |= x >> 1;
    x |= x >> 2;
    x |= x >> 4;
    x |= x >> 8;
    x |= x >> 16;
    return x + 1;
  }

  TreeNode _extendList(
      TreeNode parent, List<TreeNode> items, int index, TreeNode build()) {
    if (items.length <= index) {
      // Avoid excessive resizing by growing the list in steps.
      items.length = _pow2roundup(index + 1);
    }
    return items[index] ??= build()..parent = parent;
  }

  Class getClassReference(Library library, int tag, int index) {
    return _extendList(
        library, library.classes, index, () => _buildClassReference(tag));
  }

  Class _buildClassReference(int tag) {
    return new Class();
  }

  Field _buildFieldReference() {
    return new Field(null);
  }

  Constructor _buildConstructorReference() {
    return new Constructor(null);
  }

  Procedure _buildProcedureReference() {
    return new Procedure(null, null, null);
  }

  Member getMemberReference(TreeNode classOrLibrary, int tag, int index) {
    if (classOrLibrary is Class) {
      return getClassMemberReference(classOrLibrary, tag, index);
    } else {
      return getLibraryMemberReference(classOrLibrary, tag, index);
    }
  }

  Member getLibraryMemberReference(Library library, int tag, int index) {
    switch (tag) {
      case Tag.LibraryFieldReference:
      case Tag.Field:
        return _extendList(
            library, library.fields, index, _buildFieldReference);
      case Tag.LibraryProcedureReference:
      case Tag.Procedure:
        return _extendList(
            library, library.procedures, index, _buildProcedureReference);
      default:
        throw 'Invalid library member reference tag: $tag';
    }
  }

  Member getClassMemberReference(Class classNode, int tag, int index) {
    switch (tag) {
      case Tag.ClassFieldReference:
      case Tag.Field:
        return _extendList(
            classNode, classNode.fields, index, _buildFieldReference);
      case Tag.ClassConstructorReference:
      case Tag.Constructor:
        return _extendList(classNode, classNode.constructors, index,
            _buildConstructorReference);
      case Tag.ClassProcedureReference:
      case Tag.Procedure:
        return _extendList(
            classNode, classNode.procedures, index, _buildProcedureReference);
      default:
        throw 'Invalid library member reference tag: $tag';
    }
  }

  Program loadProgram(String filename) {
    var bytes = new File(filename).readAsBytesSync();
    return new BinaryBuilder(this, bytes, filename).readProgramFile();
  }
}
