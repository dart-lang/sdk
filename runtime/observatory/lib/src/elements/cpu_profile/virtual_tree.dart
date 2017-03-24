// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html';
import 'dart:math' as Math;
import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/stack_trace_tree_config.dart'
    show ProfileTreeMode;
import 'package:observatory/src/elements/code_ref.dart';
import 'package:observatory/src/elements/containers/virtual_tree.dart';
import 'package:observatory/src/elements/function_ref.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/src/elements/helpers/tag.dart';
import 'package:observatory/utils.dart';

export 'package:observatory/src/elements/stack_trace_tree_config.dart'
    show ProfileTreeMode;

class CpuProfileVirtualTreeElement extends HtmlElement implements Renderable {
  static const tag =
      const Tag<CpuProfileVirtualTreeElement>('cpu-profile-virtual-tree');

  RenderingScheduler<CpuProfileVirtualTreeElement> _r;

  Stream<RenderedEvent<CpuProfileVirtualTreeElement>> get onRendered =>
      _r.onRendered;

  M.ProfileTreeDirection _direction;
  ProfileTreeMode _mode;
  M.IsolateRef _isolate;
  M.SampleProfile _profile;
  Iterable<M.CallTreeNodeFilter> _filters;

  M.ProfileTreeDirection get direction => _direction;
  ProfileTreeMode get mode => _mode;
  M.IsolateRef get isolate => _isolate;
  M.SampleProfile get profile => _profile;
  Iterable<M.CallTreeNodeFilter> get filters => _filters;

  set direction(M.ProfileTreeDirection value) =>
      _direction = _r.checkAndReact(_direction, value);
  set mode(ProfileTreeMode value) => _mode = _r.checkAndReact(_mode, value);
  set filters(Iterable<M.CallTreeNodeFilter> value) {
    _filters = new List.unmodifiable(value);
    _r.dirty();
  }

  factory CpuProfileVirtualTreeElement(
      M.IsolateRef isolate, M.SampleProfile profile,
      {ProfileTreeMode mode: ProfileTreeMode.function,
      M.ProfileTreeDirection direction: M.ProfileTreeDirection.exclusive,
      RenderingQueue queue}) {
    assert(isolate != null);
    assert(profile != null);
    assert(mode != null);
    assert(direction != null);
    CpuProfileVirtualTreeElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._isolate = isolate;
    e._profile = profile;
    e._mode = mode;
    e._direction = direction;
    return e;
  }

  CpuProfileVirtualTreeElement.created() : super.created();

  @override
  attached() {
    super.attached();
    _r.enable();
  }

  @override
  detached() {
    super.detached();
    _r.disable(notify: true);
    children = [];
  }

  VirtualTreeElement _tree;

  void render() {
    var tree;
    var update;
    switch (mode) {
      case ProfileTreeMode.code:
        tree = _profile.loadCodeTree(_direction);
        update = _updateCodeRow;
        break;
      case ProfileTreeMode.function:
        tree = _profile.loadFunctionTree(_direction);
        update = _updateFunctionRow;
        break;
      default:
        throw new Exception('Unknown ProfileTreeMode: $mode');
    }
    if (filters != null) {
      tree = filters.fold(tree, (tree, filter) {
        return tree?.filtered(filter);
      });
    }
    if (tree == null) {
      children = [new HeadingElement.h1()..text = 'No Results'];
      return;
    }
    _tree = new VirtualTreeElement(_createRow, update, _getChildren,
        items: tree.root.children, queue: _r.queue);
    if (tree.root.children.length == 1) {
      _tree.expand(tree.root.children.first, autoExpandSingleChildNodes: true);
    }
    children = [_tree];
  }

  static Element _createRow(toggle) {
    return new DivElement()
      ..classes = ['tree-item']
      ..children = [
        new SpanElement()
          ..classes = ['inclusive']
          ..title = 'global % on stack',
        new SpanElement()
          ..classes = ['exclusive']
          ..title = 'global % executing',
        new SpanElement()..classes = ['lines'],
        new ButtonElement()
          ..classes = ['expander']
          ..onClick.listen((_) => toggle(autoToggleSingleChildNodes: true)),
        new SpanElement()
          ..classes = ['percentage']
          ..title = 'tree node %',
        new SpanElement()..classes = ['name']
      ];
  }

  static _getChildren(M.CallTreeNode node) => node.children;

  void _updateFunctionRow(
      HtmlElement element, M.FunctionCallTreeNode item, int depth) {
    element.children[0].text = Utils
        .formatPercentNormalized(item.profileFunction.normalizedInclusiveTicks);
    element.children[1].text = Utils
        .formatPercentNormalized(item.profileFunction.normalizedExclusiveTicks);
    _updateLines(element.children[2].children, depth);
    if (item.children.isNotEmpty) {
      element.children[3].text = _tree.isExpanded(item) ? '▼' : '►';
    } else {
      element.children[3].text = '';
    }
    element.children[4].text = Utils.formatPercentNormalized(item.percentage);
    element.children[5] = new FunctionRefElement(
        _isolate, item.profileFunction.function, queue: _r.queue)
      ..classes = ['name'];
  }

  void _updateCodeRow(HtmlElement element, M.CodeCallTreeNode item, int depth) {
    element.children[0].text = Utils
        .formatPercentNormalized(item.profileCode.normalizedInclusiveTicks);
    element.children[1].text = Utils
        .formatPercentNormalized(item.profileCode.normalizedExclusiveTicks);
    _updateLines(element.children[2].children, depth);
    if (item.children.isNotEmpty) {
      element.children[3].text = _tree.isExpanded(item) ? '▼' : '►';
    } else {
      element.children[3].text = '';
    }
    element.children[4].text = Utils.formatPercentNormalized(item.percentage);
    element.children[5] = new CodeRefElement(_isolate, item.profileCode.code,
        queue: _r.queue)..classes = ['name'];
  }

  static _updateLines(List<Element> lines, int n) {
    n = Math.max(0, n);
    while (lines.length > n) {
      lines.removeLast();
    }
    while (lines.length < n) {
      lines.add(new SpanElement());
    }
  }
}
