// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

package com.google.dart.fling;

/**
 * @param <T>
 */
public class PrefixTree<T> {

  /**
   * 
   * @param <A>
   */
  public static class Entry<A> {
    private final String prefix;
    private final Node<A> node;

    private Entry(String prefix, Node<A> node) {
      this.prefix = prefix;
      this.node = node;
    }

    public String getPrefix() {
      return prefix;
    }

    public A getValue() {
      return node.data;
    }
  }

  /**
   * 
   * @param <A>
   */
  private static class Node<A> {
    final char splitChar;

    A data;

    Node<A> lo, ea, hi;

    Node(char splitChar) {
      this.splitChar = splitChar;
    }
  }

  private Node<T> root = null;
  private int numNodes = 0;

  public void add(String prefix, T obj) {
    final Node<T> nd = placeNode(prefix);
    if (nd.data == null) {
      numNodes++;
    }
    nd.data = obj;
  }

  public Entry<T> resolve(String key) {
    return findEntry(key, root, null, 0, key.length());
  }

  public int size() {
    return numNodes;
  }

  private Entry<T> findEntry(String key, Node<T> cNode, Entry<T> sEntry, int cur, int len) {
    if (cNode == null || cur == len) {
      return sEntry;
    } else {
      final int cp = key.charAt(cur) - cNode.splitChar;
      if (cp == 0) {
        final int nex = cur + 1;
        return findEntry(key, cNode.ea, (cNode.data == null) ? sEntry : new Entry<T>(key.substring(0, nex), cNode), nex, len);
      } else {
        return findEntry(key, (cp < 0) ? cNode.lo : cNode.hi, sEntry, cur, len);
      }
    }
  }

  private Node<T> placeNode(String key) {
    if (root == null) {
      root = new Node<T>(key.charAt(0));
    }

    Node<T> nd = root;
    int ix = 0, ln = key.length();

    while (true) {
      int cp = key.charAt(ix) - nd.splitChar;
      if (cp == 0) {
        ix++;
        if (ix == ln) {
          return nd;
        }
        if (nd.ea == null) {
          nd.ea = new Node<T>(key.charAt(ix));
        }
        nd = nd.ea;
      } else if (cp < 0) {
        if (nd.lo == null) {
          nd.lo = new Node<T>(key.charAt(ix));
        }
        nd = nd.lo;
      } else {
        if (nd.hi == null) {
          nd.hi = new Node<T>(key.charAt(ix));
        }
        nd = nd.hi;
      }
    }
  }
}
