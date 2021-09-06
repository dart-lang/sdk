// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO:
//  - starting dominator treemap from a group of nodes instead of only a
//    single node

"use strict";

function Graph() {
  // Create all slots up front to prevent V8 map transitions.

  // We extensively use parallel arrays instead of objects like
  //
  // function Vertex {
  //   this.size = 0;
  //   this.successors = new Array();
  //   this.predecessors = new Array();
  //   this.semi = 0;
  //   this.dom = 0;
  //   this.label = 0;
  //   this.parent = 0;
  //   this.ancestor = 0;
  // }
  //
  // This avoids GC work in V8, and it allows us to release the memory for
  // intermediate values that are only needed while computing the dominators.

  // Inputs.
  this.N_ = 0;  // Number of nodes.
  this.E_ = 0;  // Number of edges.
  this.strings_ = null;
  this.name_ = null;
  this.class_ = null;
  this.shallowSize_ = null;
  this.firstSuccessor_ = null;
  this.successors_ = null;
  this.successorName_ = null;

  // Outputs.
  this.shallowSizeSum_ = 0;
  this.firstPredecessor_ = null;
  this.predecessors_ = null;
  this.predecessorName_ = null;
  this.retainedSize_ = null;
  this.dom_ = null;
  this.domHead_ = null;
  this.domNext_ = null;
  this.mergedDomHead_ = null;
  this.mergedDomNext_ = null;

  // Intermediates.
  this.Nconnected_ = 0;  // Number of nodes reachable from root.
  this.vertex_ = null;
  this.semi_ = null;
  this.parent_ = null;
  this.ancestor_ = null;
  this.label_ = null;
  this.bucket_ = null;

  // Recycled memory.
  this.mark_ = null;
  this.stack_ = null;
}

// Load a graph in V8 heap profile format from parsed JSON `data`.
Graph.prototype.loadV8Profile = function(data) {
  console.log("Building successors...");

  const N = data.snapshot.node_count;
  const E = data.snapshot.edge_count;

  const firstSuccessor = new Uint32Array(N + 2);
  const successors = new Uint32Array(E);
  const successorName = new Uint32Array(E);

  const name = new Uint32Array(N + 1);
  const clazz = new Array(N + 1);
  const shallowSize = new Uint32Array(N + 1);
  let shallowSizeSum = 0;

  const node_stride = data.snapshot.meta.node_fields.length;
  const node_type_offset = data.snapshot.meta.node_fields.indexOf("type");
  const node_name_offset = data.snapshot.meta.node_fields.indexOf("name");
  const node_id_offset = data.snapshot.meta.node_fields.indexOf("id");
  const node_size_offset = data.snapshot.meta.node_fields.indexOf("self_size");
  const node_edge_count_offset = data.snapshot.meta.node_fields.indexOf("edge_count");

  const edge_stride = data.snapshot.meta.edge_fields.length;
  const edge_type_offset = data.snapshot.meta.edge_fields.indexOf("type");
  const edge_name_or_index_offset = data.snapshot.meta.edge_fields.indexOf("name_or_index");
  const edge_target_offset = data.snapshot.meta.edge_fields.indexOf("to_node");
  const edge_type_property = data.snapshot.meta.edge_types[0].indexOf("property");

  let nextSuccessorIndex = 0;
  let edge_cursor = 0;
  let i = 1;
  for (let node_cursor = 0;
       node_cursor < data.nodes.length;
       node_cursor += node_stride) {
    let type = data.nodes[node_cursor + node_type_offset];
    let node_name = data.nodes[node_cursor + node_name_offset];
    let id = data.nodes[node_cursor + node_id_offset];
    let self_size = data.nodes[node_cursor + node_size_offset];
    let edge_count = data.nodes[node_cursor + node_edge_count_offset];

    name[i] = node_name;
    clazz[i] = data.snapshot.meta.node_types[0][type];
    shallowSize[i] = self_size;
    shallowSizeSum += self_size;
    firstSuccessor[i] = nextSuccessorIndex;

    for (let j = 0; j < edge_count; j++) {
      let edge_type = data.edges[edge_cursor + edge_type_offset];
      let edge_name_or_index = data.edges[edge_cursor + edge_name_or_index_offset];
      let edge_to_node = (data.edges[edge_cursor + edge_target_offset] / node_stride) + 1;
      edge_cursor += edge_stride;

      if (edge_to_node < 1 || edge_to_node > N) {
        throw "Invalid edge target";
      }

      successors[nextSuccessorIndex] = edge_to_node;

      if (edge_type == edge_type_property) {
        successorName[nextSuccessorIndex] = edge_name_or_index;
      }

      nextSuccessorIndex++;
    }

    i++;
  }
  firstSuccessor[N + 1] = nextSuccessorIndex;

  if (i != (N + 1)) {
    throw "Incorrect node_count!";
  }
  if (nextSuccessorIndex != E) {
    throw "Incorrect edge_count!";
  }

  this.N_ = N;
  this.E_ = E;
  this.strings_ = data.strings;
  this.firstSuccessor_ = firstSuccessor;
  this.successorName_ = successorName;
  this.successors_ = successors;
  this.name_ = name;
  this.class_ = clazz;
  this.shallowSize_ = shallowSize;
  this.shallowSizeSum_ = shallowSizeSum;
};

// Load a graph in Dart heap snapshot format from ArrayBuffer `data`.
Graph.prototype.loadDartHeapSnapshot = function(data) {
  console.log("Building successors...");

  let stream = new Stream(data);

  for (let i = 0; i < 8; i++) {
    if (stream.byte() != 'dartheap'.charCodeAt(i)) {
      throw "Wrong format identifier."
    }
  }

  stream.uleb128();  // Flags.
  stream.utf8();     // Name.
  stream.uleb128();  // Shallow size (used).
  stream.uleb128();  // Capacity.
  stream.uleb128();  // External size.

  const strings = new Array();
  strings.push("???");

  const classCount = stream.uleb128();
  const classNames = new Uint32Array(classCount + 1);
  classNames[0] = strings.length;
  strings.push("Root");
  const classEdges = new Array(classCount + 1);
  for (let cid = 1; cid <= classCount; cid++) {
    stream.uleb128();  // Flags.
    classNames[cid] = strings.length;
    strings.push(stream.utf8());  // Class name.
    stream.utf8();  // Library name.
    stream.utf8();  // Library name.
    stream.utf8();  // Reserved.
    const fieldCount = stream.uleb128();
    const edgeNames = new Array(fieldCount + 1);
    classEdges[cid] = edgeNames;
    for (let j = 0; j < fieldCount; j++) {
      stream.uleb128();  // Flags.
      const fieldIndex = stream.uleb128();
      const fieldName = stream.utf8();
      stream.utf8();  // Reserved.

      edgeNames[fieldIndex] = strings.length;
      strings.push(fieldName);
    }
  }

  const E = stream.uleb128();  // Reference count.
  const N = stream.uleb128();  // Object count.

  const firstSuccessor = new Uint32Array(N + 2);
  const successors = new Uint32Array(E);
  const successorName = new Uint32Array(E);
  const name = new Uint32Array(N + 1);
  const clazz = new Array(N + 1);
  const shallowSize = new Uint32Array(N + 1);

  name[0] = strings.length;
  strings.push("<omitted-object>");
  clazz[0] = "<omitted-object>";
  const unknownEdge = strings.length;
  strings.push("<unknown>");

  let shallowSizeSum = 0;
  let nextSuccessorIndex = 0;
  for (let i = 1; i <= N; i++) {
    const cid = stream.uleb128();
    clazz[i] = strings[classNames[cid]];
    const objShallowSize = stream.uleb128();
    shallowSize[i] = objShallowSize;
    shallowSizeSum += objShallowSize;

    const tag = stream.uleb128();
    switch (tag) {
      case 0:  // NoData
        name[i] = classNames[cid];
        break;
      case 1:  // NullData
        name[i] = strings.length;
        strings.push("null");
        break;
      case 2:  // BoolData
        name[i] = strings.length;
        strings.push(stream.uleb128() == 0 ? "false" : "true");
        break;
      case 3:  // IntegerData
        name[i] = stream.sleb128();
        break;
      case 4:  // DoubleData
        name[i] = stream.float64();
        break;
      case 5:  // Latin1StringData
        stream.uleb128();  // Full length.
        name[i] = strings.length;
        strings.push(stream.latin1());
        break;
      case 6:  // Utf16StringData
        stream.uleb128();  // Full length.
        name[i] = strings.length;
        strings.push(stream.utf16());
        break;
      case 7:  // LengthData
        name[i] = strings.length;
        strings.push(strings[classNames[cid]] + "(" + stream.uleb128() + ")");
        break;
      case 8:  // NameData
        name[i] = strings.length;
        strings.push(stream.utf8());
        break;
      default:
        throw "Unknown tag " + tag;
    }

    firstSuccessor[i] = nextSuccessorIndex;
    const edge_count = stream.uleb128();
    for (let j = 0; j < edge_count; j++) {
      successors[nextSuccessorIndex] = stream.uleb128();
      successorName[nextSuccessorIndex] = unknownEdge;
      const edgeNames = classEdges[cid];
      if (edgeNames !== undefined) {
        const edgeName = classEdges[cid][j];
        if (edgeName !== undefined) {
          successorName[nextSuccessorIndex] = edgeName;
        }
      }
      nextSuccessorIndex++;
    }
  }
  firstSuccessor[N + 1] = nextSuccessorIndex;

  if (nextSuccessorIndex != E) {
    throw "Incorrect edge_count!";
  }

  const externalPropertyCount = stream.uleb128();
  for (let i = 0; i < externalPropertyCount; i++) {
    let object = stream.uleb128();
    let externalSize = stream.uleb128();
    stream.utf8();  // Name.
    shallowSize[object] += externalSize;
    shallowSizeSum += externalSize;
  }

  this.N_ = N;
  this.E_ = E;
  this.strings_ = strings;
  this.firstSuccessor_ = firstSuccessor;
  this.successorName_ = successorName;
  this.successors_ = successors;
  this.name_ = name;
  this.class_ = clazz;
  this.shallowSize_ = shallowSize;
  this.shallowSizeSum_ = shallowSizeSum;
};

// Compute the graph's dominator tree and the retained size of each vertex.
//
// If `rewriteForOwners` is true, for each vertex that has an "owner" edge,
// replace all edges to the vertex with an edge from the owner to the vertex.
// This can be the graph more hierachical and reveal more structure in the
// dominator tree.
Graph.prototype.compute = function(rewriteForOwners) {
  this.computePredecessors();
  if (rewriteForOwners) {
    this.rewriteEdgesForOwners();
  }
  this.computePreorder(1);
  this.computeDominators();
  this.computeRetainedSizes();
  this.linkDominatorChildren();
  this.sortDominatorChildren();
  this.mergeDominatorSiblings(1);

  this.mark_ = new Uint8Array(this.N_ + 1);
  this.stack_ = new Uint32Array(this.E_);
};

Graph.prototype.computePredecessors = function() {
  console.log("Building predecessors...");

  const N = this.N_;
  const E = this.E_;
  const firstSuccessor = this.firstSuccessor_;
  const successors = this.successors_;
  const successorName = this.successorName_;
  const firstPredecessor = new Uint32Array(N + 2);
  const predecessors = new Uint32Array(E);
  const predecessorName = new Uint32Array(E);

  const predecessorCount = new Uint32Array(N + 1);
  for (let i = 1; i <= N; i++) {
    let firstSuccessorIndex = firstSuccessor[i];
    let lastSuccessorIndex = firstSuccessor[i + 1];
    for (let successorIndex = firstSuccessorIndex;
       successorIndex < lastSuccessorIndex;
       successorIndex++) {
      let successor = successors[successorIndex];
      if (successor == 0) continue;  // Omitted object.
      predecessorCount[successor]++;
    }
  }

  let nextPredecessorIndex = 0;
  for (let i = 1; i <= N; i++) {
    firstPredecessor[i] = nextPredecessorIndex;
    nextPredecessorIndex += predecessorCount[i];
  }
  firstPredecessor[N + 1] = nextPredecessorIndex;

  for (let i = 1; i <= N; i++) {
    let firstSuccessorIndex = firstSuccessor[i];
    let lastSuccessorIndex = firstSuccessor[i + 1];
    for (let successorIndex = firstSuccessorIndex;
       successorIndex < lastSuccessorIndex;
       successorIndex++) {
      let successor = successors[successorIndex];
      if (successor == 0) continue;  // Omitted object.
      let count = --predecessorCount[successor];
      let predecessorIndex = firstPredecessor[successor] + count;
      predecessors[predecessorIndex] = i;
      predecessorName[predecessorIndex] = successorName[successorIndex];
    }
  }

  this.firstPredecessor_ = firstPredecessor;
  this.predecessors_ = predecessors;
  this.predecessorName_ = predecessorName;
};

Graph.prototype.rewriteEdgesForOwners = function() {
  console.log("Rewriting edges for owners...");

  // Rewrite some edges to make the graph more hierarchical.
  // If there is an edge A.owner -> B,
  //   - remove all edges to A, and
  //   - add edge B.<unnamed> -> A.

  const N = this.N_;
  const E = this.E_;
  const firstSuccessor = this.firstSuccessor_;
  const successors = this.successors_;
  const successorName = this.successorName_;
  const firstPredecessor = this.firstPredecessor_;
  const predecessors = this.predecessors_;
  const predecessorName = this.predecessorName_;
  const owners = new Uint32Array(N + 1);
  const owneeCount = new Uint32Array(N + 1);

  // Identify owner.
  for (let i = 1; i <= N; i++) {
    let cls = this.class_[i];
    let ownerEdgeName;

    if (cls == "Class") {  // Dart VM
      ownerEdgeName = "library_";
    } else if (cls == "PatchClass") {  // Dart VM
      ownerEdgeName = "patched_class_";
    } else if (cls == "Function") {  // Dart VM
      ownerEdgeName = "owner_";
    } else if (cls == "Field") {  // Dart VM
      ownerEdgeName = "owner_";
    } else if (cls == "Code") {  // Dart VM
      ownerEdgeName = "owner_";
    } else if (cls == "ICData") {  // Dart VM
      ownerEdgeName = "owner_";
    } else if (cls == "Method") {  // Primordial Soup
      ownerEdgeName = "mixin";
    } else if (cls.startsWith("InstanceMixin`")) {  // Primordial Soup
      ownerEdgeName = "_enclosingMixin";
    } else if (cls.startsWith("ClassMixin`")) {  // Primordial Soup
      ownerEdgeName = "_instanceMixin";
    } else {
      continue;
    }

    let firstSuccessorIndex = firstSuccessor[i];
    let lastSuccessorIndex = firstSuccessor[i + 1];
    for (let successorIndex = firstSuccessorIndex;
         successorIndex < lastSuccessorIndex;
         successorIndex++) {
      let edge = this.strings_[this.successorName_[successorIndex]];
      if (edge == ownerEdgeName) {
        let owner = successors[successorIndex];
        owners[i] = owner;
        owneeCount[owner]++;
        break;
      }
    }
  }

  // Remove successors if the target has an owner.
  // Allocate space for extra successors added to owners.
  const newSuccessors = new Uint32Array(E);
  const newSuccessorName = new Uint32Array(E);
  let newSuccessorIndex = 0;
  for (let i = 1; i <= N; i++) {
    let firstSuccessorIndex = firstSuccessor[i];
    let lastSuccessorIndex = firstSuccessor[i + 1];
    firstSuccessor[i] = newSuccessorIndex;
    for (let successorIndex = firstSuccessorIndex;
         successorIndex < lastSuccessorIndex;
         successorIndex++) {
      let successor = successors[successorIndex];
      let name = successorName[successorIndex];

      if (owners[successor] != 0) {
        // Drop successor.
      } else {
        newSuccessors[newSuccessorIndex] = successor;
        newSuccessorName[newSuccessorIndex] = name;
        newSuccessorIndex++;
      }
    }
    newSuccessorIndex += owneeCount[i];
  }
  firstSuccessor[N + 1] = newSuccessorIndex;

  // Remove predecessors if the target has an owner.
  // Add the owner as a predecessor.
  // Add extra successors for owner.
  for (let i = 1; i <= N; i++) {
    let owner = owners[i];
    if (owner == 0) {
      continue;
    }

    let firstPredecessorIndex = firstPredecessor[i];
    let lastPredecessorIndex = firstPredecessor[i + 1];
    for (let predecessorIndex = firstPredecessorIndex;
         predecessorIndex < lastPredecessorIndex;
         predecessorIndex++) {
      predecessors[predecessorIndex] = 0;
    }
    predecessors[firstPredecessorIndex] = owner;

    let nextSuccessorIndex = firstSuccessor[owner + 1] - owneeCount[owner];
    newSuccessors[nextSuccessorIndex] = i;
    owneeCount[owner]--;
  }

  this.successors_ = newSuccessors;
  this.successorName_ = newSuccessorName;
};

// Thomas Lengauer and Robert Endre Tarjan. 1979. A fast algorithm for finding
// dominators in a flowgraph. ACM Trans. Program. Lang. Syst. 1, 1 (January
// 1979), 121-141. DOI: https://doi.org/10.1145/357062.357071

Graph.prototype.computePreorder = function(root) {
  console.log("Computing preorder...");

  // Lengauer and Tarjan Step 1.
  const N = this.N_;
  const firstSuccessor = this.firstSuccessor_;
  const successors = this.successors_;

  const semi = new Uint32Array(N + 1);
  const vertex = new Uint32Array(N + 1);
  const ancestor = new Uint32Array(N + 1);
  const parent = new Uint32Array(N + 1);
  const label = new Uint32Array(N + 1);

  let preorderNumber = 0;

  let stackNodes = new Uint32Array(N + 1);
  let stackEdges = new Uint32Array(N + 1);
  let stackTop = 0;

  // Push root.
  preorderNumber++;
  vertex[preorderNumber] = root;
  semi[root] = preorderNumber;
  label[root] = root;
  ancestor[root] = 0;
  stackNodes[stackTop] = root;
  stackEdges[stackTop] = firstSuccessor[root];

  while (stackTop >= 0) {
    let v = stackNodes[stackTop];
    let e = stackEdges[stackTop];

    if (e < firstSuccessor[v + 1]) {
      // Visit next successor.
      let w = successors[e];
      e++;
      stackEdges[stackTop] = e;

      if (w == 0) {
        // Omitted object.
      } else if (semi[w] != 0) {
        // Already visited.
      } else {
        parent[w] = v;

        preorderNumber++;
        vertex[preorderNumber] = w;
        semi[w] = preorderNumber;
        label[w] = w;
        ancestor[w] = 0;

        // Push successor.
        stackTop++;
        stackNodes[stackTop] = w;
        stackEdges[stackTop] = firstSuccessor[w];
      }
    } else {
      // No more successors: pop.
      stackTop--;
    }
  }

  this.Nconnected_ = preorderNumber;
  if (this.Nconnected_ != N) {
    console.log("Graph is not fully connected: " + this.Nconnected_ +
          " nodes are reachable, but graph has " + this.N_ + " nodes");
  }

  this.semi_ = semi;
  this.vertex_ = vertex;
  this.ancestor_ = ancestor;
  this.parent_ = parent;
  this.label_ = label;
};

Graph.prototype.computeDominators = function() {
  console.log("Computing dominator tree...");

  const N = this.N_;
  const Nconnected = this.Nconnected_;
  const firstPredecessor = this.firstPredecessor_;
  const predecessors = this.predecessors_;
  const vertex = this.vertex_;
  const semi = this.semi_;
  const bucket = new Array(N + 1);
  const parent = this.parent_;
  const dom = new Uint32Array(N + 1);

  for (let i = Nconnected; i > 1; i--) {
    let w = vertex[i];

    // Lengauer and Tarjan Step 2.
    let firstPredecessorIndex = firstPredecessor[w];
    let lastPredecessorIndex = firstPredecessor[w + 1];
    for (let predecessorIndex = firstPredecessorIndex;
         predecessorIndex < lastPredecessorIndex;
         predecessorIndex++) {
      let v = predecessors[predecessorIndex];

      if (semi[v] == 0) {
        // The predecessor was not reachable from the root: ignore
        // this edge.
        continue;
      }

      let u = this.forestEval(v);
      if (semi[u] < semi[w]) {
        semi[w] = semi[u]
      }
    }

    let z = vertex[semi[w]];
    let b = bucket[z];
    if (b == null) {
      b = new Array();
      bucket[z] = b;
    }
    b.push(w);
    this.forestLink(parent[w], w);

    // Lengauer and Tarjan Step 3.
    z = parent[w];
    b = bucket[z];
    bucket[z] = null;
    if (b != null) {
      for (let j = 0; j < b.length; j++) {
        let v = b[j];
        let u = this.forestEval(v);
        dom[v] = semi[u] < semi[v] ? u : parent[w];
      }
    }
  }

  this.ancestor_ = null;
  this.label_ = null;
  this.parent_ = null;
  this.bucket_ = null;

  // Lengauer and Tarjan Step 4.
  for (let i = 2; i <= Nconnected; i++) {
    let w = vertex[i];
    if (dom[w] != vertex[semi[w]]) {
      dom[w] = dom[dom[w]];
    }
  }
  dom[vertex[1]] = 0;

  this.semi_ = null;
  this.dom_ = dom;
};

Graph.prototype.forestCompress = function(v) {
  const ancestor = this.ancestor_;
  if (ancestor[ancestor[v]] != 0) {
    this.forestCompress(ancestor[v]);
    const semi = this.semi_;
    const label = this.label_;
    if (semi[label[ancestor[v]]] < semi[label[v]]) {
      label[v] = label[ancestor[v]];
    }
    ancestor[v] = ancestor[ancestor[v]];
  }
};

Graph.prototype.forestEval = function(v) {
  if (this.ancestor_[v] == 0) {
    return v;
  } else {
    this.forestCompress(v);
    return this.label_[v];
  }
};

Graph.prototype.forestLink = function(v, w) {
  this.ancestor_[w] = v;
};

Graph.prototype.computeRetainedSizes = function() {
  console.log("Computing retained sizes...");

  const N = this.N_;
  const Nconnected = this.Nconnected_;
  const vertex = this.vertex_;
  const dom = this.dom_;
  const shallowSize = this.shallowSize_;
  const retainedSize = new Uint32Array(N + 1);

  let shallowSum = 0;

  for (let i = 1; i <= Nconnected; i++) {
    let w = vertex[i];
    let shallow = shallowSize[w];
    retainedSize[w] = shallow;
    shallowSum += shallow;
  }

  for (let i = Nconnected; i > 1; i--) {
    let w = vertex[i];
    retainedSize[dom[w]] += retainedSize[w];
  }

  if (retainedSize[vertex[1]] != shallowSum) {
    console.log("Retained size mismatch: root retains " + retainedSize[vertex[1]] +
                " but shallow sizes sum to " + shallowSum);
  }

  this.retainedSize_ = retainedSize;
};

Graph.prototype.linkDominatorChildren = function() {
  console.log("Linking dominator tree children...");

  const N = this.N_;
  const Nconnected = this.Nconnected_;

  const vertex = this.vertex_;
  const dom = this.dom_;
  const head = new Uint32Array(N + 1);
  const next = new Uint32Array(N + 1);

  for (let i = 2; i <= Nconnected; i++) {
    let child = vertex[i];
    let parent = dom[child];
    next[child] = head[parent];
    head[parent] = child;
  }

  this.domHead_ = head;
  this.domNext_ = next;
};

// Merge the given lists according to the given key in ascending order.
// Returns the head of the merged list.
function mergeSorted(head1, head2, next, key) {
  let head = head1;
  let beforeInsert = 0;
  let afterInsert = head1;
  let startInsert = head2;

  while (startInsert != 0) {
    while ((afterInsert != 0) &&
           (key[afterInsert] <= key[startInsert])) {
      beforeInsert = afterInsert;
      afterInsert = next[beforeInsert];
    }
    let endInsert = startInsert;
    let peek = next[endInsert];

    while ((peek != 0) && (key[peek] < key[afterInsert])) {
      endInsert = peek;
      peek = next[endInsert];
    }

    if (beforeInsert == 0) {
      head = startInsert;
    } else {
      next[beforeInsert] = startInsert;
    }
    next[endInsert] = afterInsert;

    startInsert = peek;
    beforeInsert = endInsert;
  }

  return head;
}

Graph.prototype.sortDominatorChildren = function() {
  console.log("Sorting dominator tree children...");

  const N = this.N_;
  const Nconnected = this.Nconnected_;
  const cids = this.class_;
  const head = this.domHead_;
  const next = this.domNext_;

  function sort(head) {
    if (head == 0) return 0;
    if (next[head] == 0) return head;

    // Find the middle of the list.
    let head1 = head;
    let slow = head;
    let fast = head;
    while (next[fast] != 0 && next[next[fast]] != 0) {
      slow = next[slow];
      fast = next[next[fast]];
    }

    // Split the list in half.
    let head2 = next[slow];
    next[slow] = 0;

    // Recursively sort the sublists and merge.
    let newHead1 = sort(head1);
    let newHead2 = sort(head2);
    return mergeSorted(newHead1, newHead2, next, cids);
  };

  // Sort all list of dominator tree children by cid.
  for (let parent = 1; parent <= N; parent++) {
    head[parent] = sort(head[parent]);
  }
};

Graph.prototype.mergeDominatorSiblings = function(root) {
  console.log("Merging dominator tree siblings...");

  const N = this.N_;
  const cids = this.class_;
  const head = new Uint32Array(this.domHead_);
  const next = new Uint32Array(this.domNext_);
  const workStack = new Uint32Array(N);
  let workStackTop = 0;

  function mergeChildrenAndSort(parent1, end) {
    if (next[parent1] == end) return;

    // Find the middle of the list.
    let slow = parent1;
    let fast = parent1;
    while (next[fast] != end && next[next[fast]] != end) {
      slow = next[slow];
      fast = next[next[fast]];
    }

    let parent2 = next[slow];

    // Recursively sort the sublists.
    mergeChildrenAndSort(parent1, parent2);
    mergeChildrenAndSort(parent2, end);

    // Merge sorted sublists.
    head[parent1] = mergeSorted(head[parent1], head[parent2], next, cids);

    // Children moved to parent1.
    head[parent2] = 0;
  }

  // Push root.
  workStack[workStackTop++] = root;

  while (workStackTop > 0) {
    let parent = workStack[--workStackTop];

    let child = head[parent];
    while (child != 0) {
      // Push child.
      workStack[workStackTop++] = child;

      // Find next sibling with a different cid.
      let after = child;
      while (after != 0 && cids[after] == cids[child]) {
        after = next[after];
      }

      // From all the siblings between child and after, take their children,
      // merge them and given to child.
      mergeChildrenAndSort(child, after);

      child = after;
    }
  }

  this.mergedDomHead_ = head;
  this.mergedDomNext_ = next;
};

Graph.prototype.getTotalSize = function() {
  return this.shallowSizeSum_;
};

Graph.prototype.getRoot = function() {
  return this.vertex_[1];
};

Graph.prototype.getAll = function() {
  let nodes = new Array();
  for (let v = 1; v <= this.N_; v++) {
    nodes.push(v);
  }
  return nodes;
};

function removeDuplicates(array) {
  let set = new Set(array);
  let result = new Array();
  for (let element of set) {
    result.push(element);
  }
  return result
}

Graph.prototype.successorsOfDo = function(v, action) {
  let cls = this.class_[v];
  let firstSuccessorIndex = this.firstSuccessor_[v];
  let lastSuccessorIndex = this.firstSuccessor_[v + 1];
  for (let successorIndex = firstSuccessorIndex;
     successorIndex < lastSuccessorIndex;
     successorIndex++) {
    let successor = this.successors_[successorIndex];
    let edgeName = this.strings_[this.successorName_[successorIndex]];
    action(successor, cls + "::" + edgeName);
  }
}

Graph.prototype.predecessorsOfDo = function(v, action) {
  let firstPredecessorIndex = this.firstPredecessor_[v];
  let lastPredecessorIndex = this.firstPredecessor_[v + 1];
  for (let predecessorIndex = firstPredecessorIndex;
     predecessorIndex < lastPredecessorIndex;
     predecessorIndex++) {
    let predecessor = this.predecessors_[predecessorIndex];
    let cls = this.class_[predecessor];
    let edgeName = this.strings_[this.predecessorName_[predecessorIndex]];
    action(predecessor, cls + "::" + edgeName);
  }
}

Graph.prototype.parentOf = function(v) {
  return this.dom_[v];
};

Graph.prototype.dominatorChildrenOfDo = function(v, action) {
  for (let w = this.domHead_[v]; w != 0; w = this.domNext_[w]) {
    action(w);
  }
};

Graph.prototype.nameOf = function(v) {
  return this.strings_[this.name_[v]];
};

Graph.prototype.classOf = function(v) {
  return this.class_[v];
};

Graph.prototype.shallowSizeOf = function(v) {
  return this.shallowSize_[v];
};

Graph.prototype.retainedSizeOf = function(v) {
  return this.retainedSize_[v];
};

Graph.prototype.setFrom = function(v) {
  return [v];
};

Graph.prototype.shallowSizeOfSet = function(nodes) {
  let sum = 0;
  for (let i = 0; i < nodes.length; i++) {
    sum += this.shallowSize_[nodes[i]];
  }
  return sum;
};

Graph.prototype.retainedSizeOfSet = function(nodes) {
  const N = this.N_;
  const E = this.E_;
  const mark = this.mark_;
  const stack = this.stack_;

  for (let i = 1; i <= N; i++) {
    mark[i] = 0;
  }

  for (let i = 0; i < nodes.length; i++) {
    let v = nodes[i];
    mark[v] = 1;
  }

  let scan = 0;
  let top = 0;
  stack[top++] = 1;

  while (scan < top) {
    let v = stack[scan++];
    let firstSuccessorIndex = this.firstSuccessor_[v];
    let lastSuccessorIndex = this.firstSuccessor_[v + 1];
    for (let successorIndex = firstSuccessorIndex;
       successorIndex < lastSuccessorIndex;
       successorIndex++) {
      let successor = this.successors_[successorIndex];
      if (mark[successor] == 0) {
        mark[successor] = 1;
        stack[top++] = successor;
      }
    }
  }


  for (let i = 0; i < nodes.length; i++) {
    let v = nodes[i];
    mark[v] = 0;
  }
  for (let i = 0; i < nodes.length; i++) {
    let v = nodes[i];
    if (mark[v] == 0) {
      mark[v] = 1;
      stack[top++] = v;
    }
  }

  let sum = 0;
  while (scan < top) {
    let v = stack[scan++];
    sum += this.shallowSize_[v];
    let firstSuccessorIndex = this.firstSuccessor_[v];
    let lastSuccessorIndex = this.firstSuccessor_[v + 1];
    for (let successorIndex = firstSuccessorIndex;
       successorIndex < lastSuccessorIndex;
       successorIndex++) {
      let successor = this.successors_[successorIndex];
      if (mark[successor] == 0) {
        mark[successor] = 1;
        stack[top++] = successor;
      }
    }
  }
  return sum;
};

Graph.prototype.toggleMerge = function() {
  return new MergedGraph(this);
};

function MergedGraph(graph) {
  this.graph_ = graph;
}

MergedGraph.prototype.nameOf = function(v) {
  const cids = this.graph_.class_;
  const next = this.graph_.mergedDomNext_;
  let count = 0;
  let sibling = v;
  while (sibling != 0 && cids[sibling] == cids[v]) {
    count++;
    sibling = next[sibling];
  }
  return count.toString() + " instances of " + this.graph_.class_[v];
};

MergedGraph.prototype.classOf = function(v) {
  return this.graph_.class_[v];
};

MergedGraph.prototype.shallowSizeOf = function(v) {
  const cids = this.graph_.class_;
  const shallowSize = this.graph_.shallowSize_;
  const next = this.graph_.mergedDomNext_;
  let size = 0;
  let sibling = v;
  while (sibling != 0 && cids[sibling] == cids[v]) {
    size += shallowSize[sibling];
    sibling = next[sibling];
  }
  return size;
};

MergedGraph.prototype.retainedSizeOf = function(v) {
  const cids = this.graph_.class_;
  const retainedSize = this.graph_.retainedSize_;
  const next = this.graph_.mergedDomNext_;
  let size = 0;
  let sibling = v;
  while (sibling != 0 && cids[sibling] == cids[v]) {
    size += retainedSize[sibling];
    sibling = next[sibling];
  }
  return size;
};

MergedGraph.prototype.setFrom = function(v) {
  const cids = this.graph_.class_;
  const next = this.graph_.mergedDomNext_;
  let set = new Array();
  let sibling = v;
  while (sibling != 0 && cids[sibling] == cids[v]) {
    set.push(sibling);
    sibling = next[sibling];
  }
  return set;
};

MergedGraph.prototype.parentOf = function(v) {
  // N.B.: Not dom_[v], which might not be the representative element of the
  // merged group.
  const N = this.graph_.N_;
  const head = this.graph_.mergedDomHead_;
  const next = this.graph_.mergedDomNext_;
  for (let parent = 1; parent <= N; parent++) {
    for (let child = head[parent]; child != 0; child = next[child]) {
      if (child == v) {
        return parent;
      }
    }
  }
  return 0;
};

MergedGraph.prototype.dominatorChildrenOfDo = function(v, action) {
  const next = this.graph_.mergedDomNext_;
  const cids = this.graph_.class_;
  let prev = 0;
  let child = this.graph_.mergedDomHead_[v];
  // Walk the list of children and look for the representative objects, i.e.
  // the first sibling of each cid.
  while (child != 0) {
    if (prev == 0 || cids[prev] != cids[child]) {
      action(child);
    }
    prev = child;
    child = next[child];
  }
};

MergedGraph.prototype.getTotalSize = function() {
  return this.graph_.shallowSizeSum_;
};

MergedGraph.prototype.toggleMerge = function() {
  return this.graph_;
};

function Stream(bytes) {
  this.bytes_ = new Uint8Array(bytes);
  this.position_ = 0;
}

Stream.prototype.byte = function() {
  const position = this.position_;
  const bytes = this.bytes_;
  if ((position >= 0) && (position < bytes.length)) {
    const result = bytes[position];
    this.position_ = position + 1;
    return result;
  }
  throw "Attempt to read past end of stream";
};

Stream.prototype.uleb128 = function() {
  let result = 0;
  let shift = 0;
  for (;;) {
    const part = this.byte();
    result |= (part & 0x7F) << shift;
    if ((part & 0x80) == 0) {
      break;
    }
    shift += 7;
  }
  return result;
};

Stream.prototype.sleb128 = function() {
  let result = 0;
  let shift = 0;
  for (;;) {
    const part = this.byte();
    result |= (part & 0x7F) << shift;
    shift += 7;
    if ((part & 0x80) == 0) {
      if ((part & 0x40) != 0) {
        result |= (-1 << shift);
      }
      break;
    }
  }
  return result;
};

Stream.prototype.float64 = function() {
  const buffer = new ArrayBuffer(8);
  const bytes = new Uint8Array(buffer);
  for (let i = 0; i < 8; i++) {
    bytes[i] = this.byte();
  }
  return new Float64Array(buffer)[0];
};

Stream.prototype.utf8 = function() {
  const length = this.uleb128();
  let result = '';
  for (let i = 0; i < length; i++) {
    // This is incorrect outside of ASCII, but good enough for our purpose
    // since we're mostly interested in identifiers.
    result += String.fromCharCode(this.byte());
  }
  // Can we force flattening of the rope string?
  return result.toString();
};

Stream.prototype.latin1 = function() {
  const length = this.uleb128();
  let result = '';
  for (let i = 0; i < length; i++) {
    result += String.fromCharCode(this.byte());
  }
  // Can we force flattening of the rope string?
  return result.toString();
};

Stream.prototype.utf16 = function() {
  const length = this.uleb128();
  let result = '';
  for (let i = 0; i < length; i++) {
    const lo = this.byte();
    const hi = this.byte();
    result += String.fromCharCode((hi << 8) | lo);
  }
  // Can we force flattening of the rope string?
  return result.toString();
};

function hash(string) {
  // Jenkin's one_at_a_time.
  let h = string.length;
  for (let i = 0; i < string.length; i++) {
    h += string.charCodeAt(i);
    h += h << 10;
    h ^= h >> 6;
  }
  h += h << 3;
  h ^= h >> 11;
  h += h << 15;
  return h;
}

function color(string) {
  let hue = hash(string) % 360;
  return "hsl(" + hue + ",60%,60%)";
}

function prettySize(size) {
  if (size < 1024) return size + "B";
  size /= 1024;
  if (size < 1024) return size.toFixed(1) + "KiB";
  size /= 1024;
  if (size < 1024) return size.toFixed(1) + "MiB";
  size /= 1024;
  return size.toFixed(1) + "GiB";
}

function prettyPercent(fraction) {
  return (fraction * 100).toFixed(1);
}

function createTreemapTile(graph, v, width, height, depth) {
  let div = document.createElement("div");
  div.className = "treemapTile";
  div.style["background-color"] = color(graph.classOf(v));
  div.ondblclick = function(event) {
    event.stopPropagation();
    if (depth == 0) {
      let dom = graph.parentOf(v);
      if (dom == 0) {
        // Already at root.
      } else {
        showDominatorTree(graph, dom);  // Zoom out.
      }
    } else {
      showDominatorTree(graph, v);  // Zoom in.
    }
  };
  div.oncontextmenu = function(event) {
    event.stopPropagation();
    event.preventDefault();
    showTables(graph.setFrom(v));
  };

  let left = 0;
  let top = 0;

  const kPadding = 5;
  const kBorder = 1;
  left += kPadding - kBorder;
  top += kPadding - kBorder;
  width -= 2 * kPadding;
  height -= 2 * kPadding;

  div.title =
    graph.nameOf(v) +
    " \nclass: " + graph.classOf(v) +
    " \nretained: " + graph.retainedSizeOf(v) +
    " \nshallow: " + graph.shallowSizeOf(v);

  if (width < 10 || height < 10) {
    // Too small: don't render label or children.
    return div;
  }

  let label = graph.nameOf(v) + " [" + prettySize(graph.retainedSizeOf(v)) + "]";
  div.appendChild(document.createTextNode(label));
  const kLabelHeight = 9;
  top += kLabelHeight;
  height -= kLabelHeight;

  if (depth > 2) {
    // Too deep: don't render children.
    return div;
  }
  if (width < 4 || height < 4) {
    // Too small: don't render children.
    return div;
  }

  let children = new Array();
  graph.dominatorChildrenOfDo(v, function(c) {
    // Size 0 children seem to confuse the layout algorithm (accumulating
    // rounding errors?).
    if (graph.retainedSizeOf(c) > 0) {
      children.push(c);
    }
  });
  children.sort(function (a, b) {
    return graph.retainedSizeOf(b) - graph.retainedSizeOf(a);
  });

  const scale = width * height / graph.retainedSizeOf(v);

  // Bruls M., Huizing K., van Wijk J.J. (2000) Squarified Treemaps. In: de
  // Leeuw W.C., van Liere R. (eds) Data Visualization 2000. Eurographics.
  // Springer, Vienna.
  for (let rowStart = 0;  // Index of first child in the next row.
       rowStart < children.length;) {
    // Prefer wider rectangles, the better to fit text labels.
    const GOLDEN_RATIO = 1.61803398875;
    let verticalSplit = (width / height) > GOLDEN_RATIO;

    let space;
    if (verticalSplit) {
      space = height;
    } else {
      space = width;
    }

    let rowMin = graph.retainedSizeOf(children[rowStart]) * scale;
    let rowMax = rowMin;
    let rowSum = 0;
    let lastRatio = 0;

    let rowEnd;  // One after index of last child in the next row.
    for (rowEnd = rowStart; rowEnd < children.length; rowEnd++) {
      let size = graph.retainedSizeOf(children[rowEnd]) * scale;
      if (size < rowMin) rowMin = size;
      if (size > rowMax) rowMax = size;
      rowSum += size;

      let ratio = Math.max((space * space * rowMax) / (rowSum * rowSum),
                           (rowSum * rowSum) / (space * space * rowMin));
      if ((lastRatio != 0) && (ratio > lastRatio)) {
        // Adding the next child makes the aspect ratios worse: remove it and
        // add the row.
        rowSum -= size;
        break;
      }
      lastRatio = ratio;
    }

    let rowLeft = left;
    let rowTop = top;
    let rowSpace = rowSum / space;

    for (let i = rowStart; i < rowEnd; i++) {
      let child = children[i];
      let size = graph.retainedSizeOf(child) * scale;

      let childWidth;
      let childHeight;
      if (verticalSplit) {
        childWidth = rowSpace;
        childHeight = size / childWidth;
      } else {
        childHeight = rowSpace;
        childWidth = size / childHeight;
      }

      let childDiv = createTreemapTile(graph, child, childWidth, childHeight, depth + 1);
      childDiv.style.left = rowLeft + "px";
      childDiv.style.top = rowTop + "px";
      // Oversize the final div by kBorder to make the borders overlap.
      childDiv.style.width = (childWidth + kBorder) + "px";
      childDiv.style.height = (childHeight + kBorder) + "px";
      div.appendChild(childDiv);

      if (verticalSplit)
        rowTop += childHeight;
      else
        rowLeft += childWidth;
    }

    if (verticalSplit) {
      left += rowSpace;
      width -= rowSpace;
    } else {
      top += rowSpace;
      height -= rowSpace;
    }

    rowStart = rowEnd;
  }

  return div;
}

function showDominatorTree(graph, v) {
  let title = document.createElement("span");
  title.textContent = "Dominator Tree";
  title.title =
    "Click title to merge/unmerge by class.\n" +
    "Double click a box to zoom in.\n" +
    "Double click the outermost box to zoom out.\n" +
    "Right click a box to view successor and predecessor tables.";
  title.className = "nameCell actionCell";
  title.onclick = function(event) { showDominatorTree(graph.toggleMerge(), v); };

  let filler = document.createElement("span");
  filler.style["flex-grow"] = 1;

  let totalSize = document.createElement("span");
  totalSize.className = "sizeCell";
  totalSize.textContent = graph ? "" + graph.getTotalSize() : "0";

  let totalPercent = document.createElement("span");
  totalPercent.className = "sizePercentCell";
  totalPercent.textContent = prettyPercent(1.0);

  let header = document.createElement("div");
  header.className = "headerRow";
  header.style["border-bottom"] = "solid 1px";
  header.appendChild(title);
  header.appendChild(filler);
  header.appendChild(totalSize);
  header.appendChild(totalPercent);

  let content = document.createElement("div");
  content.style["flex-basis"] = 0;
  content.style["flex-grow"] = 1;

  let column = document.createElement("div");
  column.style["width"] = "100%";
  column.style["height"] = "100%";
  column.style["border"] = "solid 2px";
  column.style["display"] = "flex";
  column.style["flex-direction"] = "column";
  column.appendChild(header);
  column.appendChild(content);

  setBody(column);

  // Add the content div to the document first so the browser will calculate
  // the available width and height.
  let w = content.offsetWidth;
  let h = content.offsetHeight;

  let topTile = createTreemapTile(graph, v, w, h, 0);
  topTile.style.width = w;
  topTile.style.height = h;
  topTile.style.border = "none";
  content.appendChild(topTile);
}

function Group(edge, cls) {
  this.name = "";
  this.edge = edge;
  this.cls = cls;
  this.shallowSize = 0;
  this.retainedSize = 0;
  this.nodes = new Array();
}

Group.prototype.add = function(v, edge, cls) {
  this.nodes.push(v);
  if (this.edge != edge) {
    this.edge = "<multiple>";
  }
  if (this.cls != cls) {
    this.cls = "<multiple>"
  }
};

function asGroupsByClass(labeledNodes) {
  let map = new Map();
  let groups = new Array();
  for (let i = 0; i < labeledNodes.length; i++) {
    let v = labeledNodes[i].node;
    let edge = labeledNodes[i].name;
    let cls = graph.classOf(v);
    let group = map.get(cls);
    if (group === undefined) {
      group = new Group(edge, cls);
      groups.push(group);
      map.set(cls, group);
    }
    group.add(v, edge, cls);
  }
  for (let i = 0; i < groups.length; i++) {
    let group = groups[i];
    group.shallowSize = graph.shallowSizeOfSet(group.nodes);
    group.retainedSize = graph.retainedSizeOfSet(group.nodes);
    group.name = group.nodes.length + " instances of " + group.cls;
  }
  return groups;
}

function LabeledNode(node, name) {
  this.node = node;
  this.name = name;
}

LabeledNode.prototype.addName = function(name) {
  if (this.name != name) {
    this.name = "<multiple>";
  }
};

function Table(title, labeledNodes, byEdges) {
  const self = this;

  this.title = title;
  this.labeledNodes = labeledNodes;
  this.groupsByEdge = byEdges;
  this.groupsByClass = asGroupsByClass(labeledNodes);
  this.grouping = 0;

  this.nom = document.createElement("span");
  this.nom.onclick = function() {
    self.grouping = (self.grouping + 1) % 3;
    self.refreshRows();
  };
  this.nom.className = "nameCell actionCell"
  this.nom.textContent = title;
  this.nom.title = "Toggle grouping by object, class or edge";

  let edge = document.createElement("span");
  edge.onclick = function() { self.sortByEdge(); };
  edge.className = "edgeCell actionCell";
  edge.textContent = "Edge";
  edge.title = "Sort by edge";

  let cls = document.createElement("span");
  cls.onclick = function() { self.sortByClass(); };
  cls.className = "classCell actionCell";
  cls.textContent = "Class";
  cls.title = "Sort by class";

  let shallowSize = document.createElement("span");
  shallowSize.onclick = function() { self.sortByShallowSize(); };
  shallowSize.className = "sizeCell actionCell";
  shallowSize.textContent = "Size";
  shallowSize.title = "Sort by shallow size";

  let shallowPercent = document.createElement("span");
  shallowPercent.className = "sizePercentCell"

  let retainedSize = document.createElement("span");
  retainedSize.onclick = function() { self.sortByRetainedSize(); };
  retainedSize.className = "sizeCell actionCell";
  retainedSize.textContent = "Retained Size";
  retainedSize.title = "Sort by retained size";

  let retainedPercent = document.createElement("span");
  retainedPercent.className = "sizePercentCell";

  let header = document.createElement("div");
  header.className = "headerRow";
  header.style["border-bottom"] = "solid 1px";
  header.appendChild(this.nom);
  header.appendChild(edge);
  header.appendChild(cls);
  header.appendChild(shallowSize);
  header.appendChild(shallowPercent);
  header.appendChild(retainedSize);
  header.appendChild(retainedPercent);

  this.listDiv = document.createElement("div");
  this.listDiv.style["overflow-y"] = "scroll";
  this.listDiv.style["flex-basis"] = "0px";
  this.listDiv.style["flex-grow"] = 1;

  this.div = document.createElement("div");
  this.div.style["border"] = "solid 2px";
  this.div.style["display"] = "flex";
  this.div.style["flex-direction"] = "column";
  this.div.style["background-color"] = "#DDDDDD";

  this.div.appendChild(header);
  this.div.appendChild(this.listDiv);

  this.refreshRows();
}

Table.prototype.sortByEdge = function() {
  this.labeledNodes.sort(function (a, b) {
    return a.name.localeCompare(b.name);
  });
  this.groupsByEdge.sort(function (a, b) {
    return a.edge.localeCompare(b.edge);
  });
  this.groupsByClass.sort(function (a, b) {
    return a.edge.localeCompare(b.edge);
  });
  this.refreshRows();
};

Table.prototype.sortByClass = function() {
  this.labeledNodes.sort(function (a, b) {
    return graph.classOf(a.node).localeCompare(graph.classOf(b.node));
  });
  this.groupsByEdge.sort(function (a, b) {
    return a.cls.localeCompare(b.cls);
  });
  this.groupsByClass.sort(function (a, b) {
    return a.cls.localeCompare(b.cls);
  });
  this.refreshRows();
};

Table.prototype.sortByShallowSize = function() {
  this.labeledNodes.sort(function (a, b) {
    return graph.shallowSizeOf(b.node) - graph.shallowSizeOf(a.node);
  });
  this.groupsByEdge.sort(function (a, b) {
    return b.shallowSize - a.shallowSize;
  });
  this.groupsByClass.sort(function (a, b) {
    return b.shallowSize - a.shallowSize;
  });
  this.refreshRows();
};

Table.prototype.sortByRetainedSize = function() {
  this.labeledNodes.sort(function (a, b) {
    return graph.retainedSizeOf(b.node) - graph.retainedSizeOf(a.node);
  });
  this.groupsByEdge.sort(function (a, b) {
    return b.retainedSize - a.retainedSize;
  });
  this.groupsByClass.sort(function (a, b) {
    return b.retainedSize - a.retainedSize;
  });
  this.refreshRows();
};

Table.prototype.refreshRows = function() {
  while (this.listDiv.firstChild) {
    this.listDiv.removeChild(this.listDiv.firstChild);
  }

  // To prevent rendering lag.
  const MAX_TABLE_ROWS = 500;

  if (this.grouping == 0) {
    let labeledNodes = this.labeledNodes;
    this.nom.textContent = this.title + " (" + labeledNodes.length + " objects)";

    for (let i = 0; i < labeledNodes.length; i++) {
      if (i > MAX_TABLE_ROWS) {
        this.listDiv.appendChild(document.createTextNode((labeledNodes.length - i) + " more objects"));
        break;
      }
      this.listDiv.appendChild(createObjectRow(labeledNodes[i]));
    }
  } else if (this.grouping == 1) {
    let groups = this.groupsByClass;
    this.nom.textContent = this.title + " (" + groups.length + " classes)";

    for (let i = 0; i < groups.length; i++) {
      if (i > MAX_TABLE_ROWS) {
        // Prevent rendering lag.
        this.listDiv.appendChild(document.createTextNode((groups.length - i) + " more classes"));
        break;
      }
      this.listDiv.appendChild(createGroupRow(groups[i]));
    }
  } else {
    let groups = this.groupsByEdge;
    this.nom.textContent = this.title + " (" + groups.length + " edges)";

    for (let i = 0; i < groups.length; i++) {
      if (i > MAX_TABLE_ROWS) {
        // Prevent rendering lag.
        this.listDiv.appendChild(document.createTextNode((groups.length - i) + " more edges"));
        break;
      }
      this.listDiv.appendChild(createGroupRow(groups[i]));
    }
  }
};

function createObjectRow(labeledNode) {
  const v = labeledNode.node;

  let nom = document.createElement("span");
  nom.onclick = function() { showTables([v]); }
  nom.className = "nameCell actionCell";
  nom.textContent = graph.nameOf(v);
  nom.title = "Select this object";

  let edge = document.createElement("span");
  edge.className = "edgeCell";
  edge.textContent = labeledNode.name;

  let cls = document.createElement("span");
  cls.className = "classCell";
  cls.textContent = graph.classOf(v);

  let shallowSize = document.createElement("span");
  shallowSize.className = "sizeCell";
  shallowSize.textContent = graph.shallowSizeOf(v);

  let shallowPercent = document.createElement("span");
  shallowPercent.className = "sizePercentCell";
  shallowPercent.textContent = prettyPercent(graph.shallowSizeOf(v) / graph.getTotalSize());

  function onClickRetained(event) {
    // For the root, default to the merged view for the sake of web browser layout performance.
    showDominatorTree(v == 1 ? graph.toggleMerge() : graph, v);
  }

  let retainedSize = document.createElement("span");
  retainedSize.onclick = onClickRetained;
  retainedSize.className = "sizeCell actionCell";
  retainedSize.textContent = graph.retainedSizeOf(v);
  retainedSize.title = "Show dominator tree";

  let retainedPercent = document.createElement("span");
  retainedPercent.onclick = onClickRetained;
  retainedPercent.className = "sizePercentCell actionCell";
  retainedPercent.textContent = prettyPercent(graph.retainedSizeOf(v) / graph.getTotalSize());
  retainedPercent.title = "Show dominator tree";

  let row = document.createElement("div");
  row.style["display"] = "flex";
  row.style["flex-direction"] = "row";
  row.style["border-bottom"] = "solid 1px";
  row.appendChild(nom);
  row.appendChild(edge);
  row.appendChild(cls);
  row.appendChild(shallowSize);
  row.appendChild(shallowPercent);
  row.appendChild(retainedSize);
  row.appendChild(retainedPercent);
  return row;
}

function createGroupRow(g) {
  let nom = document.createElement("span");
  nom.onclick = function() { showTables(g.nodes); }
  nom.className = "nameCell actionCell";
  nom.textContent = g.name;
  nom.title = "Select these objects";

  let cls = document.createElement("span");
  cls.className = "classCell";
  cls.textContent = g.cls;

  let edge = document.createElement("span");
  edge.className = "edgeCell";
  edge.textContent = g.edge;

  let shallowSize = document.createElement("span");
  shallowSize.className = "sizeCell";
  shallowSize.textContent = g.shallowSize;

  let shallowPercent = document.createElement("span");
  shallowPercent.className = "sizePercentCell";
  shallowPercent.textContent = prettyPercent(g.shallowSize / graph.getTotalSize());

  let retainedSize = document.createElement("span");
  retainedSize.className = "sizeCell";
  retainedSize.textContent = g.retainedSize;

  let retainedPercent = document.createElement("span");
  retainedPercent.className = "sizePercentCell";
  retainedPercent.textContent = prettyPercent(g.retainedSize / graph.getTotalSize());

  let row = document.createElement("div");
  row.style["display"] = "flex";
  row.style["flex-direction"] = "row";
  row.style["border-bottom"] = "solid 1px";
  row.appendChild(nom);
  row.appendChild(edge);
  row.appendChild(cls);
  row.appendChild(shallowSize);
  row.appendChild(shallowPercent);
  row.appendChild(retainedSize);
  row.appendChild(retainedPercent);
  return row;
}

function mapValuesToArray(map) {
  let array = new Array();
  for (let element of map.values()) {
    array.push(element);
  }
  return array;
}

function showTables(nodes) {
  let labeledNodes = new Array();
  let successors = new Map();
  let successorEdges = new Map();
  let successorEdgeGroups = new Array();
  let predecessors = new Map();
  let predecessorEdges = new Map();
  let predecessorEdgeGroups = new Array();
  for (let i = 0; i < nodes.length; i++) {
    let n = nodes[i];
    labeledNodes.push(new LabeledNode(n, "-"));
    graph.successorsOfDo(n, function (child, edgeName) {
      let e = successors.get(child);
      if (e) {
        e.addName(edgeName);
      } else {
        successors.set(child, new LabeledNode(child, edgeName));
      }
      let cls = graph.classOf(child);
      let g = successorEdges.get(edgeName);
      if (!g) {
        g = new Group(edgeName, cls);
        successorEdgeGroups.push(g);
        successorEdges.set(edgeName, g);
      }
      g.add(child, edgeName, cls);
    });
    graph.predecessorsOfDo(n, function (parent, edgeName) {
      let e = predecessors.get(parent);
      if (e) {
        e.addName(edgeName);
      } else {
        predecessors.set(parent, new LabeledNode(parent, edgeName));
      }
      let cls = graph.classOf(parent);
      let g = predecessorEdges.get(edgeName);
      if (!g) {
        g = new Group(edgeName, cls);
        predecessorEdgeGroups.push(g);
        predecessorEdges.set(edgeName, g);
      }
      g.add(parent, edgeName, cls);
    });
  }

  // Computing retained sizes here O((C + E) * N) where
  //   N is the number of objects
  //   C is the number of classes
  //   E is the number of edges
  successors = mapValuesToArray(successors);
  for (let i = 0; i < successorEdgeGroups.length; i++) {
    let group = successorEdgeGroups[i];
    group.nodes = removeDuplicates(group.nodes);
    group.shallowSize = graph.shallowSizeOfSet(group.nodes);
    group.retainedSize = graph.retainedSizeOfSet(group.nodes);
    group.name = group.nodes.length + " targets of " + group.edge;
  }
  predecessors = mapValuesToArray(predecessors);
  for (let i = 0; i < predecessorEdgeGroups.length; i++) {
    let group = predecessorEdgeGroups[i];
    group.nodes = removeDuplicates(group.nodes);
    group.shallowSize = graph.shallowSizeOfSet(group.nodes);
    group.retainedSize = graph.retainedSizeOfSet(group.nodes);
    group.name = group.nodes.length + " sources of " + group.edge;
  }

  let rewrite = document.createElement("input");
  rewrite.setAttribute("type", "checkbox");

  let rewriteLabel = document.createElement("span");
  rewriteLabel.textContent = "Owners ";

  let input = document.createElement("input");
  input.setAttribute("type", "file");
  input.setAttribute("multiple", false);
  input.onchange = function(event) {
    let file = event.target.files[0];
    document.title = file.name;
    let reader = new FileReader();
    reader.readAsText(file, 'UTF-8');
    reader.onload = function(event) {
      let data = JSON.parse(event.target.result);
      let g = new Graph();
      g.loadV8Profile(data);
      data = null; // Release memory
      graph = g;
      g.compute(rewrite.checked);
      showTables([graph.getRoot()]);
    };
    reader = new FileReader();
    reader.readAsArrayBuffer(file);
    reader.onload = function(event) {
      let data = event.target.result;
      let g = new Graph();
      g.loadDartHeapSnapshot(data);
      data = null; // Release memory
      graph = g;
      g.compute(rewrite.checked);
      showTables([graph.getRoot()]);
    };
  };

  let selectRoot = document.createElement("button");
  selectRoot.textContent = "Select Root";
  selectRoot.onclick = function(event) {
    showTables([graph.getRoot()]);
  };

  let selectAll = document.createElement("button");
  selectAll.textContent = "Select All";
  selectAll.onclick = function(event) {
    showTables(graph.getAll());
  };

  let filler = document.createElement("span");
  filler.style["flex-grow"] = 1;

  let totalSize = document.createElement("span");
  totalSize.className = "sizeCell";
  totalSize.textContent = graph ? "" + graph.getTotalSize() : "0";

  let totalPercent = document.createElement("span");
  totalPercent.className = "sizePercentCell";
  totalPercent.textContent = prettyPercent(1.0);

  let topBar = document.createElement("div");
  topBar.className = "headerRow";
  topBar.style["border"] = "solid 2px";
  topBar.style["align-items"] = "center";
  topBar.appendChild(rewrite);
  topBar.appendChild(rewriteLabel);
  topBar.appendChild(input);
  if (graph) {
    topBar.appendChild(selectRoot);
    topBar.appendChild(selectAll);
    topBar.appendChild(filler);
    topBar.appendChild(totalSize);
    topBar.appendChild(totalPercent);
  }

  let selectionTable = new Table("Selection", labeledNodes, []).div;
  selectionTable.style["flex-basis"] = "0px";
  selectionTable.style["flex-grow"] = 1;

  let successorsTable = new Table("Successors", successors, successorEdgeGroups).div;
  successorsTable.style["flex-basis"] = "0px";
  successorsTable.style["flex-grow"] = 1;

  let predecessorsTable = new Table("Predecessors", predecessors, predecessorEdgeGroups).div;
  predecessorsTable.style["flex-basis"] = "0px";
  predecessorsTable.style["flex-grow"] = 1;

  let help1 = document.createElement("p");
  help1.textContent =
      "Create a snapshot profile by passing --write_v8_snapshot_profile_to=example.json to gen_snapshot."
  let help2 = document.createElement("p");
  help2.textContent =
      "In Flutter, run flutter build aot --release --extra-gen-snapshot-options=--write-v8-snapshot-profile-to=example.json";

  let column = document.createElement("div");
  column.style["height"] = "100%";
  column.style["display"] = "flex";
  column.style["flex-direction"] = "column";
  column.appendChild(topBar);
  column.appendChild(document.createElement("br"));
  if (graph) {
    column.appendChild(selectionTable);
    column.appendChild(document.createElement("br"));
    column.appendChild(successorsTable);
    column.appendChild(document.createElement("br"));
    column.appendChild(predecessorsTable);
  } else {
    column.appendChild(help1);
    column.appendChild(help2);
  }

  setBody(column);
}

function setBody(div) {
  let body = document.body;
  while (body.firstChild) {
    body.removeChild(body.firstChild);
  }
  body.appendChild(div);
}

let graph = null;
showTables([]);
