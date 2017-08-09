// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*
Usage:

  $ tools/test.py -m release                         \
      -c dart2js -r d8 --dart2js-batch --report      \
      --host-checked                                 \
      --dart2js_options="--library-root=out/ReleaseX64/dart-sdk/ --use-kernel" \
      language corelib library_2 corelib_2           \
      dart2js_native dart2js_extra                   \
      2>&1 > LOG

  $ sdk/bin/dart pkg/compiler/tool/status_files/rank_stacks.dart LOG > STACKS.txt
*/

import 'dart:io';

import 'log_parser.dart';
import 'record.dart';

// TODO(sra): Allow command-line setting of these parameters.
const STACK_PRINT_LENGTH = 12;
const HOW_MANY_STACKS = 30;

main(args) {
  String text;

  for (String arg in args) {
    // Parse options.

    if (text == null) {
      var uri = Uri.base.resolve(arg);
      var file = new File.fromUri(uri);
      if (!file.existsSync()) {
        print('File not found: $file.');
        exit(1);
      }
      text = file.readAsStringSync();
    } else {
      print("Extra file argument '$arg'.");
      exit(1);
    }
  }

  if (text == null) {
    print('No input file.');
    exit(1);
  }

  var records = parse(text);
  var trie = new TrieNode(null);
  for (var record in records) {
    enter(record, 0, trie);
  }

  var leaves = trieLeaves(trie).toList();
  leaves.sort((a, b) => b.length.compareTo(a.length));
  for (var leaf in leaves.take(HOW_MANY_STACKS)) {
    print('');
    var examples = leaf.members.map((r) => r.fullReason).toSet().toList();
    examples.sort();
    print('${leaf.length} of:');
    for (var example in examples) {
      var count = leaf.members.where((r) => r.fullReason == example).length;
      var countAligned = '$count'.padLeft(6);
      if (examples.length == 1) countAligned = '     .';
      var indentedExample = '\t' + example.replaceAll('\n', '\n\t');
      print('${countAligned}${indentedExample}');
    }

    for (var line in leaf.members.first.stack.take(STACK_PRINT_LENGTH)) {
      print('  $line');
    }
  }
}

class TrieNode {
  final int depth;
  final String key;
  final Map<String, TrieNode> map = <String, TrieNode>{};
  final List<Record> members = <Record>[];

  int get length => members.length;

  TrieNode(this.key, [this.depth = 0]);

  String toString() => 'TrieNode(#$length)';
}

void enter(Record record, int depth, TrieNode root) {
  root.members.add(record);
  if (depth >= record.stack.length) return;
  var key = record.stack[depth];
  var node = root.map[key] ??= new TrieNode(key, depth + 1);
  enter(record, depth + 1, node);
}

void printTrie(TrieNode node) {
  var indent = '  ' * node.depth;
  print('${indent} ${node.length} ${node.key}');
  for (var key in node.map.keys) {
    printTrie(node.map[key]);
  }
}

trieLeaves(node) sync* {
  if (node.map.isEmpty) {
    yield node;
  } else {
    for (var v in node.map.values) {
      yield* trieLeaves(v);
    }
  }
}
