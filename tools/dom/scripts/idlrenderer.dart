// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

List sorted(Iterable input, [compare, key]) {
  comparator(compare, key) {
    if (compare == null && key == null) return (a, b) => a.compareTo(b);
    if (compare == null) return (a, b) => key(a).compareTo(key(b));
    if (key == null) return compare;
    return (a, b) => compare(key(a), key(b));
  }

  List copy = new List.from(input);
  copy.sort(comparator(compare, key));
  return copy;
}

render(idl_node, [indent_str = '  ']) {
  var output = [''];
  var indent_stack = [];

  // TODO: revert to  indented(action()) {
  indented(action) {
    indent_stack.add(indent_str);
    action();
    indent_stack.removeLast();
  }

  sort(nodes) => sorted(nodes, key: (a) => a.id);

  var w; // For some reason mutually recursive local functions don't work.

  wln([node]) {
    w(node);
    output.add('\n');
  }

  w = (node, [list_separator]) {
    /*
     Writes the given node.

    Args:
      node -- a string, IDLNode instance or a list of such.
      list_separator -- if provided, and node is a list,
        list_separator will be written between the list items.
    */
    if (node == null) {
      return;
    } else if (node is String) {
      if (output.last.endsWith('\n')) output.addAll(indent_stack);
      output.add(node);
    } else if (node is List) {
      var separator = null;
      for (var element in node) {
        w(separator);
        separator = list_separator;
        w(element);
      }
    } else if (node is IDLFile) {
      w(node.modules);
      w(node.interfaces);
    } else if (node is IDLModule) {
      w(node.annotations);
      w(node.extAttrs);
      wln('module ${node.id} {');
      indented(() {
        w(node.interfaces);
        w(node.typedefs);
      });
      wln('};');
    } else if (node is IDLInterface) {
      w(node.annotations);
      w(node.extAttrs);
      w('interface ${node.id}');
      indented(() {
        if (!node.parents.isEmpty) {
          wln(' :');
          w(node.parents, ',\n');
        }
        wln(' {');
        section(list, comment) {
          if (list != null && !list.isEmpty) {
            wln();
            wln(comment);
            w(sort(list));
          }
        }

        section(node.constants, '/* Constants */');
        section(node.attributes, '/* Attributes */');
        section(node.operations, '/* Operations */');
        section(node.snippets, '/* Snippets */');
      });
      wln('};');
    } else if (node is IDLParentInterface) {
      w(node.annotations);
      w(node.type.id);
    } else if (node is IDLAnnotations) {
      for (var name in sorted(node.map.keys)) {
        IDLAnnotation annotation = node.map[name];
        var args = annotation.map;
        if (args.isEmpty) {
          w('@$name');
        } else {
          var formattedArgs = [];
          for (var argName in sorted(args.keys)) {
            var argValue = args[argName];
            if (argValue == null)
              formattedArgs.add(argName);
            else
              formattedArgs.add('$argName=$argValue');
          }
          w('@$name(${formattedArgs.join(',')})');
        }
        w(' ');
      }
    } else if (node is IDLExtAttrs) {
      if (!node.map.isEmpty) {
        w('[');
        var sep = null;
        for (var name in sorted(node.map.keys)) {
          w(sep);
          sep = ', ';
          w(name);
          var value = node.map[name];
          if (value != null) {
            w('=');
            w(value);
          }
        }
        w('] ');
      }
    } else if (node is IDLAttribute) {
      w(node.annotations);
      w(node.extAttrs);
      //if (node.isFcGetter)
      //  w('getter ');
      //if (node.isFcSetter)
      //  w('setter ');
      wln('attribute ${node.type.id} ${node.id};');
    } else if (node is IDLConstant) {
      w(node.annotations);
      w(node.extAttrs);
      wln('const ${node.type.id} ${node.id} = ${node.value};');
    } else if (node is IDLSnippet) {
      w(node.annotations);
      wln('snippet {${node.text}};');
    } else if (node is IDLOperation) {
      w(node.annotations);
      w(node.extAttrs);
      if (node.specials != null && !node.specials.isEmpty) {
        w(node.specials, ' ');
        w(' ');
      }
      w('${node.type.id} ${node.id}');
      w('(');
      w(node.arguments, ', ');
      wln(');');
    } else if (node is IDLArgument) {
      w(node.extAttrs);
      w('in ');
      if (node.isOptional) w('optional ');
      w('${node.type.id} ${node.id}');
    } else if (node is IDLExtAttrFunctionValue) {
      w(node.name);
      w('(');
      w(node.arguments, ', ');
      w(')');
    } else if (node is IDLTypeDef) {
      wln('typedef ${node.type.id} ${node.id};');
    } else {
      w('// $node\n');
    }
  };

  w(idl_node);
  return output.join();
}
