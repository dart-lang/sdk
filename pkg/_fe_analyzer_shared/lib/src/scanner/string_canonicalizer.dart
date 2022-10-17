// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library _fe_analyzer_shared.scanner.string_canonicalizer;

import 'dart:convert';

abstract class Node {
  final String payload;
  Node? next;

  Node(this.payload, this.next);

  int get hash;
}

class StringNode extends Node {
  StringNode(super.payload, super.next);

  int get hash =>
      StringCanonicalizer.hashString(payload, /* start = */ 0, payload.length);
}

class Utf8Node extends Node {
  final List<int> data;
  final int start;
  final int end;

  Utf8Node(this.data, this.start, this.end, String payload, Node? next)
      : super(payload, next);

  int get hash => StringCanonicalizer.hashBytes(data, start, end);
}

/// A hash table for triples:
/// (list of bytes, start, end) --> canonicalized string
/// Using triples avoids allocating string slices before checking if they
/// are canonical.
///
/// Gives about 3% speedup on dart2js.
class StringCanonicalizer {
  /// Mask away top bits to keep hash calculation within 32-bit SMI range.
  static const int MASK = 16 * 1024 * 1024 - 1;

  static const int INITIAL_SIZE = 8 * 1024;

  /// Linear size of a hash table.
  int _size = INITIAL_SIZE;

  /// Items in a hash table.
  int _count = 0;

  /// The table itself.
  List<Node?> _nodes = new List<Node?>.filled(INITIAL_SIZE, /* fill = */ null);

  static String decode(List<int> data, int start, int end, bool asciiOnly) {
    String s;
    if (asciiOnly) {
      s = new String.fromCharCodes(data, start, end);
    } else {
      s = const Utf8Decoder(allowMalformed: true).convert(data, start, end);
    }
    return s;
  }

  static int hashBytes(List<int> data, int start, int end) {
    int h = 5381;
    for (int i = start; i < end; i++) {
      h = ((h << 5) + h + data[i]) & MASK;
    }
    return h;
  }

  static int hashString(String data, int start, int end) {
    int h = 5381;
    for (int i = start; i < end; i++) {
      h = ((h << 5) + h + data.codeUnitAt(i)) & MASK;
    }
    return h;
  }

  rehash() {
    int newSize = _size * 2;
    List<Node?> newNodes = new List<Node?>.filled(newSize, /* fill = */ null);
    for (int i = 0; i < _size; i++) {
      Node? t = _nodes[i];
      while (t != null) {
        Node? n = t.next;
        int newIndex = t.hash & (newSize - 1);
        Node? s = newNodes[newIndex];
        t.next = s;
        newNodes[newIndex] = t;
        t = n;
      }
    }
    _size = newSize;
    _nodes = newNodes;
  }

  String canonicalize(data, int start, int end, bool asciiOnly) {
    if (data is String) {
      if (start == 0 && (end == data.length - 1)) {
        return canonicalizeString(data);
      }
      return canonicalizeSubString(data, start, end);
    }
    return canonicalizeBytes(data as List<int>, start, end, asciiOnly);
  }

  String canonicalizeBytes(List<int> data, int start, int end, bool asciiOnly) {
    if (_count > _size) rehash();
    final int index = hashBytes(data, start, end) & (_size - 1);
    Node? s = _nodes[index];
    Node? t = s;
    int len = end - start;
    while (t != null) {
      if (t is Utf8Node) {
        final List<int> tData = t.data;
        if (t.end - t.start == len) {
          int i = start, j = t.start;
          while (i < end && data[i] == tData[j]) {
            i++;
            j++;
          }
          if (i == end) {
            return t.payload;
          }
        }
      }
      t = t.next;
    }
    String payload = decode(data, start, end, asciiOnly);
    _nodes[index] = new Utf8Node(data, start, end, payload, s);
    _count++;
    return payload;
  }

  String canonicalizeSubString(String data, int start, int end) {
    if (_count > _size) rehash();
    final int index = hashString(data, start, end) & (_size - 1);
    Node? s = _nodes[index];
    Node? t = s;
    int len = end - start;
    while (t != null) {
      if (t is StringNode) {
        final String tData = t.payload;
        if (identical(data, tData)) return tData;
        if (tData.length == len) {
          int i = start, j = 0;
          while (i < end && data.codeUnitAt(i) == tData.codeUnitAt(j)) {
            i++;
            j++;
          }
          if (i == end) {
            return tData;
          }
        }
      }
      t = t.next;
    }
    return insertStringNode(index, s, data.substring(start, end));
  }

  String canonicalizeString(String data) {
    if (_count > _size) rehash();
    final int index =
        hashString(data, /* start = */ 0, data.length) & (_size - 1);
    Node? s = _nodes[index];
    Node? t = s;
    while (t != null) {
      if (t is StringNode) {
        final String tData = t.payload;
        if (identical(data, tData)) return tData;
        if (data == tData) return tData;
      }
      t = t.next;
    }
    return insertStringNode(index, s, data);
  }

  String insertStringNode(int index, Node? next, String value) {
    final StringNode newNode = new StringNode(value, next);
    _nodes[index] = newNode;
    _count++;
    return value;
  }

  String insertUtf8Node(int index, Node? next, List<int> buffer, int start,
      int end, String value) {
    final Utf8Node newNode = new Utf8Node(buffer, start, end, value, next);
    _nodes[index] = newNode;
    _count++;
    return value;
  }

  clear() {
    _size = INITIAL_SIZE;
    _nodes = new List<Node?>.filled(_size, /* fill = */ null);
    _count = 0;
  }
}
