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

import 'package:args/args.dart';

import 'log_parser.dart';
import 'record.dart';

int stackPrintLength;
int howManyStacks;

void die(String why) {
  print(why);
  print('Usage:\n'
      'dart rank_stacks.dart [options] test-logs\n\n'
      '${argParser.usage}');
  exit(1);
}

ArgParser argParser = new ArgParser()
  ..addOption('stacks',
      abbr: 's',
      defaultsTo: '30',
      help: 'Number of highest ranking stacks to print.')
  ..addOption('length',
      abbr: 'l', defaultsTo: '12', help: 'Number of stack frames printed.');

int intOption(ArgResults args, String name) {
  onError(String text) {
    die("Value '$text' is not an integer. "
        "Option '$name' requires an integer value.");
  }

  return int.parse(args[name], onError: onError);
}

main(args) {
  List<String> rest;
  try {
    var argResults = argParser.parse(args);
    howManyStacks = intOption(argResults, 'stacks');
    stackPrintLength = intOption(argResults, 'length');
    rest = argResults.rest;
  } catch (e) {
    die('$e');
  }

  if (rest.isEmpty) die('No input file.');
  var records = <Record>[];
  for (String input in rest) {
    var uri = Uri.base.resolve(input);
    var file = new File.fromUri(uri);
    if (!file.existsSync()) {
      die("File not found: '$input'.");
    }
    String text = file.readAsStringSync();
    records.addAll(parse(text));
  }

  var trie = new TrieNode(null);
  for (var record in records) {
    enter(record, 0, trie);
  }

  var leaves = trieLeaves(trie).toList();
  leaves.sort(compareNodesByCountAndStack);
  for (var leaf in howManyStacks == 0 ? leaves : leaves.take(howManyStacks)) {
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

    for (var line in leaf.members.first.stack.take(stackPrintLength)) {
      print('  $line');
    }
  }
}

int compareNodesByCountAndStack(TrieNode a, TrieNode b) {
  int r = b.length.compareTo(a.length);
  if (r != 0) return r;
  List<String> stackA = a.members.first.stack;
  List<String> stackB = b.members.first.stack;
  int lengthA = stackA.length;
  int lengthB = stackB.length;
  for (int i = 0; i < lengthA && i < lengthB; i++) {
    r = stackA[i].compareTo(stackB[i]);
    if (r != 0) return r;
  }
  return lengthA.compareTo(lengthB);
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
