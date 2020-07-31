// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--serialize_flow_graphs_to=il_tmp.txt
// VMOptions=--serialize_flow_graphs_to=il_tmp.txt --populate_llvm_constant_pool
// VMOptions=--serialize_flow_graphs_to=il_tmp.txt --no_serialize_flow_graph_types
// VMOptions=--serialize_flow_graphs_to=il_tmp.txt --verbose_flow_graph_serialization
// VMOptions=--serialize_flow_graphs_to=il_tmp.txt --no_serialize_flow_graph_types --verbose_flow_graph_serialization

class A {
  const A();
}

class B {
  Object a = const A();
}

foo(int i) {
  if (i == 3) {
    new B();
  }
}

main(args) {
  foo(4);
}
