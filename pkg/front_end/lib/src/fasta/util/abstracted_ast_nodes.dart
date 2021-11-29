// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:front_end/src/fasta/util/parser_ast_helper.dart';

enum Coloring { Untouched, Marked }

abstract class AstNode {
  Map<String, List<AstNode>> scope = {};
  Container? parent;
  ParserAstNode get node;
  Token get startInclusive;
  Token get endInclusive;

  Coloring marked = Coloring.Untouched;

  StringBuffer toStringInternal(StringBuffer sb, int indent);

  void buildScope();
  Map<String, AstNode> selfScope();

  List<AstNode>? findInScope(String name) {
    return scope[name] ?? parent?.findInScope(name);
  }
}

abstract class Container extends AstNode {
  List<AstNode> _children = [];
  Iterable<AstNode> get children => _children;

  void addChild(AstNode child, Map<ParserAstNode, AstNode> map) {
    child.parent = this;
    _children.add(child);
    map[child.node] = child;
  }
}

class TopLevel extends Container {
  final String sourceText;
  final Uri uri;

  @override
  final ParserAstNode node;

  final Map<ParserAstNode, AstNode> map;

  TopLevel(this.sourceText, this.uri, this.node, this.map);

  @override
  String toString() => toStringInternal(new StringBuffer(), 0).toString();

  @override
  StringBuffer toStringInternal(StringBuffer sb, int indent) {
    String stringIndent = " " * (indent * 2);
    if (_children.isEmpty) {
      String stringIndent = " " * ((indent + 1) * 2);
      sb.write(stringIndent);
      sb.writeln("(empty)");
    } else {
      for (AstNode node in _children) {
        sb.write(stringIndent);
        node.toStringInternal(sb, indent + 1);
      }
    }
    return sb;
  }

  @override
  void buildScope() {
    for (AstNode child in _children) {
      child.buildScope();
      for (MapEntry<String, AstNode> entry in child.selfScope().entries) {
        (scope[entry.key] ??= []).add(entry.value);
      }
    }
  }

  @override
  Map<String, AstNode> selfScope() {
    return const {};
  }

  @override
  Token get endInclusive => throw new UnimplementedError();

  @override
  Token get startInclusive => throw new UnimplementedError();
}

class Class extends Container {
  @override
  final TopLevelDeclarationEnd node;
  final String name;
  @override
  final Token startInclusive;
  @override
  final Token endInclusive;

  Class(this.node, this.name, this.startInclusive, this.endInclusive);

  @override
  StringBuffer toStringInternal(StringBuffer sb, int indent) {
    String stringIndent = " " * (indent * 2);
    sb.write(stringIndent);
    if (marked != Coloring.Untouched) {
      sb.write("(marked) ");
    }
    sb.writeln("Class $name");
    if (_children.isEmpty) {
      String stringIndent = " " * ((indent + 1) * 2);
      sb.write(stringIndent);
      sb.writeln("(empty)");
    } else {
      for (AstNode node in _children) {
        node.toStringInternal(sb, indent + 1);
      }
    }
    return sb;
  }

  @override
  void buildScope() {
    for (AstNode child in _children) {
      child.buildScope();
      for (MapEntry<String, AstNode> entry in child.selfScope().entries) {
        (scope[entry.key] ??= []).add(entry.value);
      }
    }
  }

  @override
  Map<String, AstNode> selfScope() {
    return {name: this};
  }
}

class Mixin extends Container {
  @override
  final TopLevelDeclarationEnd node;
  final String name;
  @override
  final Token startInclusive;
  @override
  final Token endInclusive;

  Mixin(this.node, this.name, this.startInclusive, this.endInclusive);

  @override
  StringBuffer toStringInternal(StringBuffer sb, int indent) {
    String stringIndent = " " * (indent * 2);
    sb.write(stringIndent);
    if (marked != Coloring.Untouched) {
      sb.write("(marked) ");
    }
    sb.writeln("Mixin $name");
    if (_children.isEmpty) {
      String stringIndent = " " * ((indent + 1) * 2);
      sb.write(stringIndent);
      sb.writeln("(empty)");
    } else {
      for (AstNode node in _children) {
        node.toStringInternal(sb, indent + 1);
      }
    }
    return sb;
  }

  @override
  void buildScope() {
    for (AstNode child in _children) {
      child.buildScope();
      for (MapEntry<String, AstNode> entry in child.selfScope().entries) {
        (scope[entry.key] ??= []).add(entry.value);
      }
    }
  }

  @override
  Map<String, AstNode> selfScope() {
    return {name: this};
  }
}

class Extension extends Container {
  @override
  final TopLevelDeclarationEnd node;
  final String? name;
  @override
  final Token startInclusive;
  @override
  final Token endInclusive;

  Extension(this.node, this.name, this.startInclusive, this.endInclusive);

  @override
  StringBuffer toStringInternal(StringBuffer sb, int indent) {
    String stringIndent = " " * (indent * 2);
    sb.write(stringIndent);
    if (marked != Coloring.Untouched) {
      sb.write("(marked) ");
    }
    sb.writeln("Extension $name");
    if (_children.isEmpty) {
      String stringIndent = " " * ((indent + 1) * 2);
      sb.write(stringIndent);
      sb.writeln("(empty)");
    } else {
      for (AstNode node in _children) {
        node.toStringInternal(sb, indent + 1);
      }
    }
    return sb;
  }

  @override
  void buildScope() {
    for (AstNode child in _children) {
      child.buildScope();
      for (MapEntry<String, AstNode> entry in child.selfScope().entries) {
        (scope[entry.key] ??= []).add(entry.value);
      }
    }
  }

  @override
  Map<String, AstNode> selfScope() {
    if (name != null) {
      return {name!: this};
    } else {
      return const {};
    }
  }
}

class ClassConstructor extends AstNode {
  @override
  final ClassConstructorEnd node;
  final String name;
  @override
  final Token startInclusive;
  @override
  final Token endInclusive;

  ClassConstructor(
      this.node, this.name, this.startInclusive, this.endInclusive);

  @override
  StringBuffer toStringInternal(StringBuffer sb, int indent) {
    String stringIndent = " " * (indent * 2);
    sb.write(stringIndent);
    if (marked != Coloring.Untouched) {
      sb.write("(marked) ");
    }
    sb.writeln("Class constructor $name");
    return sb;
  }

  @override
  void buildScope() {}

  @override
  Map<String, AstNode> selfScope() {
    // TODO: Possibly this should be different...
    return {name: this};
  }
}

class ClassFactoryMethod extends AstNode {
  @override
  final ClassFactoryMethodEnd node;
  final String name;
  @override
  final Token startInclusive;
  @override
  final Token endInclusive;

  ClassFactoryMethod(
      this.node, this.name, this.startInclusive, this.endInclusive);

  @override
  StringBuffer toStringInternal(StringBuffer sb, int indent) {
    String stringIndent = " " * (indent * 2);
    sb.write(stringIndent);
    if (marked != Coloring.Untouched) {
      sb.write("(marked) ");
    }
    sb.writeln("Class factory constructor $name");
    return sb;
  }

  @override
  void buildScope() {}

  @override
  Map<String, AstNode> selfScope() {
    // TODO: Possibly this should be different...
    return {name: this};
  }
}

class ClassMethod extends AstNode {
  @override
  final ClassMethodEnd node;
  final String name;
  @override
  final Token startInclusive;
  @override
  final Token endInclusive;

  ClassMethod(this.node, this.name, this.startInclusive, this.endInclusive);

  @override
  StringBuffer toStringInternal(StringBuffer sb, int indent) {
    String stringIndent = " " * (indent * 2);
    sb.write(stringIndent);
    if (marked != Coloring.Untouched) {
      sb.write("(marked) ");
    }
    sb.writeln("Class method $name");
    return sb;
  }

  @override
  void buildScope() {}

  @override
  Map<String, AstNode> selfScope() {
    return {name: this};
  }
}

class ExtensionMethod extends AstNode {
  @override
  final ExtensionMethodEnd node;
  final String name;
  @override
  final Token startInclusive;
  @override
  final Token endInclusive;

  ExtensionMethod(this.node, this.name, this.startInclusive, this.endInclusive);

  @override
  StringBuffer toStringInternal(StringBuffer sb, int indent) {
    String stringIndent = " " * (indent * 2);
    sb.write(stringIndent);
    if (marked != Coloring.Untouched) {
      sb.write("(marked) ");
    }
    sb.writeln("Extension method $name");
    return sb;
  }

  @override
  void buildScope() {}

  @override
  Map<String, AstNode> selfScope() {
    return {name: this};
  }
}

class MixinMethod extends AstNode {
  @override
  final MixinMethodEnd node;
  final String name;
  @override
  final Token startInclusive;
  @override
  final Token endInclusive;

  MixinMethod(this.node, this.name, this.startInclusive, this.endInclusive);

  @override
  StringBuffer toStringInternal(StringBuffer sb, int indent) {
    String stringIndent = " " * (indent * 2);
    sb.write(stringIndent);
    if (marked != Coloring.Untouched) {
      sb.write("(marked) ");
    }
    sb.writeln("Mixin method $name");
    return sb;
  }

  @override
  void buildScope() {}

  @override
  Map<String, AstNode> selfScope() {
    return {name: this};
  }
}

class Enum extends AstNode {
  @override
  final EnumEnd node;
  final String name;
  final List<String> members;
  @override
  final Token startInclusive;
  @override
  final Token endInclusive;

  Enum(this.node, this.name, this.members, this.startInclusive,
      this.endInclusive);

  @override
  StringBuffer toStringInternal(StringBuffer sb, int indent) {
    String stringIndent = " " * (indent * 2);
    sb.write(stringIndent);
    if (marked != Coloring.Untouched) {
      sb.write("(marked) ");
    }
    sb.writeln("Enum $name with members $members");
    return sb;
  }

  @override
  void buildScope() {
    for (String child in members) {
      scope[child] = [this];
    }
  }

  @override
  Map<String, AstNode> selfScope() {
    return {name: this};
  }
}

class Import extends AstNode {
  @override
  final ImportEnd node;
  final Uri firstUri;
  final List<Uri>? conditionalUris;
  final String? asName;
  @override
  final Token startInclusive;
  @override
  final Token endInclusive;

  Import(this.node, this.firstUri, this.conditionalUris, this.asName,
      this.startInclusive, this.endInclusive);

  List<Uri> get uris => [firstUri, ...?conditionalUris];

  @override
  StringBuffer toStringInternal(StringBuffer sb, int indent) {
    String stringIndent = " " * (indent * 2);
    sb.write(stringIndent);
    if (marked != Coloring.Untouched) {
      sb.write("(marked) ");
    }
    if (asName == null) {
      sb.writeln("Import of $uris");
    } else {
      sb.writeln("Import of $uris as '$asName'");
    }
    return sb;
  }

  @override
  void buildScope() {}

  @override
  Map<String, AstNode> selfScope() {
    if (asName != null) {
      return {asName!: this};
    }
    return const {};
  }
}

class Export extends AstNode {
  @override
  final ExportEnd node;
  final Uri firstUri;
  final List<Uri>? conditionalUris;
  @override
  final Token startInclusive;
  @override
  final Token endInclusive;

  Export(this.node, this.firstUri, this.conditionalUris, this.startInclusive,
      this.endInclusive);

  List<Uri> get uris => [firstUri, ...?conditionalUris];

  @override
  StringBuffer toStringInternal(StringBuffer sb, int indent) {
    String stringIndent = " " * (indent * 2);
    sb.write(stringIndent);
    if (marked != Coloring.Untouched) {
      sb.write("(marked) ");
    }
    sb.writeln("Export of $uris");
    return sb;
  }

  @override
  void buildScope() {}

  @override
  Map<String, AstNode> selfScope() {
    return const {};
  }
}

class Part extends AstNode {
  @override
  final PartEnd node;
  final Uri uri;
  @override
  final Token startInclusive;
  @override
  final Token endInclusive;

  Part(this.node, this.uri, this.startInclusive, this.endInclusive);

  @override
  StringBuffer toStringInternal(StringBuffer sb, int indent) {
    String stringIndent = " " * (indent * 2);
    sb.write(stringIndent);
    if (marked != Coloring.Untouched) {
      sb.write("(marked) ");
    }
    sb.writeln("Part $uri");
    return sb;
  }

  @override
  void buildScope() {}

  @override
  Map<String, AstNode> selfScope() {
    return const {};
  }
}

class TopLevelFields extends AstNode {
  @override
  final TopLevelFieldsEnd node;
  final List<String> names;
  @override
  final Token startInclusive;
  @override
  final Token endInclusive;

  TopLevelFields(this.node, this.names, this.startInclusive, this.endInclusive);

  @override
  StringBuffer toStringInternal(StringBuffer sb, int indent) {
    String stringIndent = " " * (indent * 2);
    sb.write(stringIndent);
    if (marked != Coloring.Untouched) {
      sb.write("(marked) ");
    }
    sb.writeln("Top level field(s) ${names.join(", ")}");
    return sb;
  }

  @override
  void buildScope() {}

  @override
  Map<String, AstNode> selfScope() {
    Map<String, AstNode> scope = {};
    for (String name in names) {
      scope[name] = this;
    }
    return scope;
  }
}

class TopLevelMethod extends AstNode {
  @override
  final TopLevelMethodEnd node;
  final String name;
  @override
  final Token startInclusive;
  @override
  final Token endInclusive;

  TopLevelMethod(this.node, this.name, this.startInclusive, this.endInclusive);

  @override
  StringBuffer toStringInternal(StringBuffer sb, int indent) {
    String stringIndent = " " * (indent * 2);
    sb.write(stringIndent);
    if (marked != Coloring.Untouched) {
      sb.write("(marked) ");
    }
    sb.writeln("Top level method $name");
    return sb;
  }

  @override
  void buildScope() {}

  @override
  Map<String, AstNode> selfScope() {
    return {name: this};
  }
}

class Typedef extends AstNode {
  @override
  final TypedefEnd node;
  final String name;
  @override
  final Token startInclusive;
  @override
  final Token endInclusive;

  Typedef(this.node, this.name, this.startInclusive, this.endInclusive);

  @override
  StringBuffer toStringInternal(StringBuffer sb, int indent) {
    String stringIndent = " " * (indent * 2);
    sb.write(stringIndent);
    if (marked != Coloring.Untouched) {
      sb.write("(marked) ");
    }
    sb.writeln("Top level method $name");
    return sb;
  }

  @override
  void buildScope() {}

  @override
  Map<String, AstNode> selfScope() {
    return {name: this};
  }
}

class ClassFields extends AstNode {
  @override
  final ClassFieldsEnd node;
  final List<String> names;
  @override
  final Token startInclusive;
  @override
  final Token endInclusive;

  ClassFields(this.node, this.names, this.startInclusive, this.endInclusive);

  @override
  StringBuffer toStringInternal(StringBuffer sb, int indent) {
    String stringIndent = " " * (indent * 2);
    sb.write(stringIndent);
    if (marked != Coloring.Untouched) {
      sb.write("(marked) ");
    }
    sb.writeln("Class field(s) ${names.join(", ")}");
    return sb;
  }

  @override
  void buildScope() {}

  @override
  Map<String, AstNode> selfScope() {
    Map<String, AstNode> scope = {};
    for (String name in names) {
      scope[name] = this;
    }
    return scope;
  }
}

class MixinFields extends AstNode {
  @override
  final MixinFieldsEnd node;
  final List<String> names;
  @override
  final Token startInclusive;
  @override
  final Token endInclusive;

  MixinFields(this.node, this.names, this.startInclusive, this.endInclusive);

  @override
  StringBuffer toStringInternal(StringBuffer sb, int indent) {
    String stringIndent = " " * (indent * 2);
    sb.write(stringIndent);
    if (marked != Coloring.Untouched) {
      sb.write("(marked) ");
    }
    sb.writeln("Mixin field(s) ${names.join(", ")}");
    return sb;
  }

  @override
  void buildScope() {}

  @override
  Map<String, AstNode> selfScope() {
    Map<String, AstNode> scope = {};
    for (String name in names) {
      scope[name] = this;
    }
    return scope;
  }
}

class ExtensionFields extends AstNode {
  @override
  final ExtensionFieldsEnd node;
  final List<String> names;
  @override
  final Token startInclusive;
  @override
  final Token endInclusive;

  ExtensionFields(
      this.node, this.names, this.startInclusive, this.endInclusive);

  @override
  StringBuffer toStringInternal(StringBuffer sb, int indent) {
    String stringIndent = " " * (indent * 2);
    sb.write(stringIndent);
    if (marked != Coloring.Untouched) {
      sb.write("(marked) ");
    }
    sb.writeln("Extension field(s) ${names.join(", ")}");
    return sb;
  }

  @override
  void buildScope() {}

  @override
  Map<String, AstNode> selfScope() {
    Map<String, AstNode> scope = {};
    for (String name in names) {
      scope[name] = this;
    }
    return scope;
  }
}

class Metadata extends AstNode {
  @override
  final MetadataEnd node;
  @override
  final Token startInclusive;
  @override
  final Token endInclusive;

  Metadata(this.node, this.startInclusive, this.endInclusive);

  @override
  StringBuffer toStringInternal(StringBuffer sb, int indent) {
    String stringIndent = " " * (indent * 2);
    sb.write(stringIndent);
    if (marked != Coloring.Untouched) {
      sb.write("(marked) ");
    }
    sb.writeln("metadata");
    return sb;
  }

  @override
  void buildScope() {}

  @override
  Map<String, AstNode> selfScope() {
    return const {};
  }
}

class LibraryName extends AstNode {
  @override
  final LibraryNameEnd node;
  @override
  final Token startInclusive;
  @override
  final Token endInclusive;

  LibraryName(this.node, this.startInclusive, this.endInclusive);

  @override
  StringBuffer toStringInternal(StringBuffer sb, int indent) {
    String stringIndent = " " * (indent * 2);
    sb.write(stringIndent);
    if (marked != Coloring.Untouched) {
      sb.write("(marked) ");
    }
    sb.writeln("library name");
    return sb;
  }

  @override
  void buildScope() {}

  @override
  Map<String, AstNode> selfScope() {
    return const {};
  }
}

class PartOf extends AstNode {
  @override
  final PartOfEnd node;
  @override
  final Token startInclusive;
  @override
  final Token endInclusive;
  final Uri partOfUri;

  PartOf(this.node, this.partOfUri, this.startInclusive, this.endInclusive);

  @override
  StringBuffer toStringInternal(StringBuffer sb, int indent) {
    String stringIndent = " " * (indent * 2);
    sb.write(stringIndent);
    if (marked != Coloring.Untouched) {
      sb.write("(marked) ");
    }
    sb.writeln("part of");
    return sb;
  }

  @override
  void buildScope() {}

  @override
  Map<String, AstNode> selfScope() {
    return const {};
  }
}

class LanguageVersion extends AstNode {
  @override
  final ParserAstNode node;
  @override
  final Token startInclusive;
  @override
  final Token endInclusive;

  LanguageVersion(this.node, this.startInclusive, this.endInclusive);

  @override
  StringBuffer toStringInternal(StringBuffer sb, int indent) {
    String stringIndent = " " * (indent * 2);
    sb.write(stringIndent);
    if (marked != Coloring.Untouched) {
      sb.write("(marked) ");
    }
    sb.writeln("$startInclusive");
    return sb;
  }

  @override
  void buildScope() {}

  @override
  Map<String, AstNode> selfScope() {
    return const {};
  }
}
