// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of js_ast;

abstract class _TypePrinterBase implements TypeRefVisitor {
  void out(String s);
  void visit(Node node);

  void outSeparated<T extends Node>(String separator, Iterable<T> items,
      [action(T item)]) {
    action ??= visit;
    var first = true;
    for (var item in items) {
      if (first) {
        first = false;
      } else {
        out(separator);
      }
      action(item);
    }
  }

  void outTypeArg(Iterable<TypeRef> typeArgs) {
    if (typeArgs.isNotEmpty) {
      // TODO(ochafik): Double-check precedence issues when we start emitting
      // type arguments outside type literals (generic method call, etc).
      out('<');
      outSeparated(", ", typeArgs);
      out('>');
    }
  }

  @override
  visitQualifiedTypeRef(QualifiedTypeRef node) {
    outSeparated(".", node.path);
  }
}

abstract class TypeScriptTypePrinter extends _TypePrinterBase {
  void _outTypeAnnotation(TypeRef type) {
    if (type is OptionalTypeRef) {
      out("?: ");
      visit(type.type);
    } else {
      out(": ");
      visit(type);
    }
  }

  @override
  visitGenericTypeRef(GenericTypeRef node) {
    if (node.rawType is FunctionTypeRef) {
      outTypeArg(node.typeArgs);
      visit(node.rawType);
    } else {
      visit(node.rawType);
      outTypeArg(node.typeArgs);
    }
  }

  @override
  visitArrayTypeRef(ArrayTypeRef node) {
    if (node.elementType == null) {
      out("Array");
    } else {
      visit(node.elementType);
      out("[]");
    }
  }

  @override
  visitOptionalTypeRef(OptionalTypeRef node) {
    visit(node.type);
  }

  @override
  visitRecordTypeRef(RecordTypeRef node) {
    out('{');
    outSeparated(", ", node.types.keys, (Identifier name) {
      var type = node.types[name];
      visit(name);
      _outTypeAnnotation(type);
    });
    out('}');
  }

  @override
  visitUnionTypeRef(UnionTypeRef node) {
    outSeparated("|", node.types.where((t) => !t.isNull));
  }

  @override
  visitFunctionTypeRef(FunctionTypeRef node) {
    if (node.returnType == null) {
      out('Function');
    } else {
      out('(');
      if (node.paramTypes == null) {
        out('...any');
      } else {
        outSeparated(", ", node.paramTypes.keys, (name) {
          var paramType = node.paramTypes[name];
          visit(name);
          _outTypeAnnotation(paramType);
        });
      }
      out(') => ');
      visit(node.returnType);
    }
  }

  @override
  visitAnyTypeRef(AnyTypeRef node) {
    out("any");
  }

  @override
  visitUnknownTypeRef(UnknownTypeRef node) {
    out("any");
  }
}

class ClosureTypePrinter extends _TypePrinterBase implements NodeVisitor {
  final _buffer = new StringBuffer();

  @override
  void out(String s) => _buffer.write(s);

  @override
  void visit(Node node) => node.accept(this);

  noSuchMethod(Invocation i) => super.noSuchMethod(i);

  @override
  visitGenericTypeRef(GenericTypeRef node) {
    visit(node.rawType);
    outTypeArg(node.typeArgs);
  }

  @override
  visitIdentifier(Identifier node) {
    //out(localNamer.getName(node));
    out(node.name);
  }

  @override
  visitAccess(PropertyAccess node) {
    var selector = node.selector;
    if (selector is LiteralString) {
      visit(node.receiver);
      out(".");
      out(selector.valueWithoutQuotes);
    } else {
      assert(false);
      out("?");
    }
  }

  @override
  toString() => _buffer.toString();

  @override
  visitArrayTypeRef(ArrayTypeRef node) {
    out("Array");
    if (node.elementType != null) {
      out("<");
      visit(node.elementType);
      out(">");
    }
  }

  @override
  visitOptionalTypeRef(OptionalTypeRef node) {
    visit(node.type);
    out("=");
  }

  @override
  visitRecordTypeRef(RecordTypeRef node) {
    out('{');
    outSeparated(", ", node.types.keys, (Identifier name) {
      var type = node.types[name];
      visit(name);
      out(": ");
      visit(type is OptionalTypeRef ? type.orUndefined() : type);
    });
    out('}');
  }

  @override
  visitAnyTypeRef(AnyTypeRef node) {
    out("*");
  }

  @override
  visitUnknownTypeRef(UnknownTypeRef node) {
    out("?");
  }

  @override
  visitUnionTypeRef(UnionTypeRef node) {
    out("(");
    outSeparated("|", node.types);
    out(")");
  }

  @override
  visitFunctionTypeRef(FunctionTypeRef node) {
    if (node.returnType == null) {
      out('Function');
    } else {
      out('function(');
      if (node.paramTypes == null) {
        out("...*");
      } else {
        outSeparated(", ", node.paramTypes.values);
      }
      out(')');
      if (node.returnType != null) {
        out(":");
        visit(node.returnType);
      }
    }
  }
}
