// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of csslib.visitor;

/**
 * The base type for all nodes in a CSS abstract syntax tree.
 */
abstract class TreeNode {
  /** The source code this [TreeNode] represents. */
  Span span;

  TreeNode(this.span) {}

  TreeNode clone();

  /** Classic double-dispatch visitor for implementing passes. */
  visit(VisitorBase visitor);

  /** A multiline string showing the node and its children. */
  String toDebugString() {
    var to = new TreeOutput();
    var tp = new _TreePrinter(to, true);
    this.visit(tp);
    return to.buf.toString();
  }
}

/** The base type for expressions. */
abstract class Expression extends TreeNode {
  Expression(Span span): super(span);
}

/** Simple class to provide a textual dump of trees for debugging. */
class TreeOutput {
  int depth = 0;
  final StringBuffer buf = new StringBuffer();
  var printer;

  void write(String s) {
    for (int i=0; i < depth; i++) {
      buf.write(' ');
    }
    buf.write(s);
  }

  void writeln(String s) {
    write(s);
    buf.write('\n');
  }

  void heading(String name, [span]) {
    write(name);
    if (span != null) {
      buf.write('  (${span.getLocationMessage('')})');
    }
    buf.write('\n');
  }

  String toValue(value) {
    if (value == null) return 'null';
    else if (value is Identifier) return value.name;
    else return value.toString();
  }

  void writeNode(String label, TreeNode node) {
    write('${label}: ');
    depth += 1;
    if (node != null) node.visit(printer);
    else writeln('null');
    depth -= 1;
  }

  void writeValue(String label, value) {
    var v = toValue(value);
    writeln('${label}: ${v}');
  }

  void writeList(String label, List list) {
    write('${label}: ');
    if (list == null) {
      buf.write('null');
      buf.write('\n');
    } else {
      for (var item in list) {
        buf.write(item.toString());
        buf.write(', ');
      }
      buf.write('\n');
    }
  }

  void writeNodeList(String label, List list) {
    writeln('${label} [');
    if (list != null) {
      depth += 1;
      for (var node in list) {
        if (node != null) {
          node.visit(printer);
        } else {
          writeln('null');
        }
      }
      depth -= 1;
      writeln(']');
    }
  }

  String toString() => buf.toString();
}
