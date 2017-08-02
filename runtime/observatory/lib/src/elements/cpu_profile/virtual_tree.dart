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
  M.SampleProfileType _type;
  M.IsolateRef _isolate;
  M.SampleProfile _profile;
  Iterable<M.CallTreeNodeFilter> _filters;

  M.ProfileTreeDirection get direction => _direction;
  ProfileTreeMode get mode => _mode;
  M.SampleProfileType get type => _type;
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

  factory CpuProfileVirtualTreeElement(Object owner, M.SampleProfile profile,
      {ProfileTreeMode mode: ProfileTreeMode.function,
      M.SampleProfileType type: M.SampleProfileType.cpu,
      M.ProfileTreeDirection direction: M.ProfileTreeDirection.exclusive,
      RenderingQueue queue}) {
    assert(profile != null);
    assert(mode != null);
    assert(direction != null);
    CpuProfileVirtualTreeElement e = document.createElement(tag.name);
    e._r = new RenderingScheduler(e, queue: queue);
    e._isolate = owner;
    e._profile = profile;
    e._mode = mode;
    e._type = type;
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
    var create;
    var update;

    switch (type) {
      case M.SampleProfileType.cpu:
        create = _createCpuRow;
        if (mode == ProfileTreeMode.code) {
          update = _updateCpuCodeRow;
          tree = _profile.loadCodeTree(_direction);
        } else if (mode == ProfileTreeMode.function) {
          update = _updateCpuFunctionRow;
          tree = _profile.loadFunctionTree(_direction);
        } else {
          throw new Exception('Unknown ProfileTreeMode: $mode');
        }
        break;
      case M.SampleProfileType.memory:
        create = _createMemoryRow;
        if (mode == ProfileTreeMode.code) {
          update = _updateMemoryCodeRow;
          tree = _profile.loadCodeTree(_direction);
        } else if (mode == ProfileTreeMode.function) {
          update = _updateMemoryFunctionRow;
          tree = _profile.loadFunctionTree(_direction);
        } else {
          throw new Exception('Unknown ProfileTreeMode: $mode');
        }
        break;
      default:
        throw new Exception('Unknown SampleProfileType: $type');
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
    _tree = new VirtualTreeElement(create, update, _getChildren,
        items: tree.root.children, queue: _r.queue);
    if (tree.root.children.length == 1) {
      _tree.expand(tree.root.children.first, autoExpandSingleChildNodes: true);
    }
    children = [_tree];
  }

  static Element _createCpuRow(toggle) {
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

  static Element _createMemoryRow(toggle) {
    return new DivElement()
      ..classes = ['tree-item']
      ..children = [
        new SpanElement()
          ..classes = ['inclusive']
          ..title = 'memory allocated from resulting calls: ',
        new SpanElement()
          ..classes = ['exclusive']
          ..title = 'memory allocated during execution: ',
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

  static const String _expandedIcon = '▼';
  static const String _collapsedIcon = '►';

  void _updateCpuFunctionRow(
      HtmlElement element, M.FunctionCallTreeNode item, int depth) {
    element.children[0].text = Utils
        .formatPercentNormalized(item.profileFunction.normalizedInclusiveTicks);
    element.children[1].text = Utils
        .formatPercentNormalized(item.profileFunction.normalizedExclusiveTicks);
    _updateLines(element.children[2].children, depth);
    if (item.children.isNotEmpty) {
      element.children[3].text =
          _tree.isExpanded(item) ? _expandedIcon : _collapsedIcon;
    } else {
      element.children[3].text = '';
    }
    element.children[4].text = Utils.formatPercentNormalized(item.percentage);
    element.children[5] = new FunctionRefElement(
        _isolate, item.profileFunction.function,
        queue: _r.queue)
      ..classes = ['name'];
  }

  void _updateMemoryFunctionRow(
      HtmlElement element, M.FunctionCallTreeNode item, int depth) {
    element.children[0].text =
        Utils.formatSize(item.inclusiveNativeAllocations);
    element.children[0].title = 'memory allocated from resulting calls: '
        '${item.inclusiveNativeAllocations}B';
    element.children[1].text =
        Utils.formatSize(item.exclusiveNativeAllocations);
    element.children[1].title = 'memory allocated during execution: '
        '${item.exclusiveNativeAllocations}B';
    _updateLines(element.children[2].children, depth);
    if (item.children.isNotEmpty) {
      element.children[3].text =
          _tree.isExpanded(item) ? _expandedIcon : _collapsedIcon;
    } else {
      element.children[3].text = '';
    }
    element.children[4].text = Utils.formatPercentNormalized(item.percentage);
    element.children[5] = new FunctionRefElement(
        null, item.profileFunction.function,
        queue: _r.queue)
      ..classes = ['name'];
  }

  void _updateCpuCodeRow(
      HtmlElement element, M.CodeCallTreeNode item, int depth) {
    element.children[0].text = Utils
        .formatPercentNormalized(item.profileCode.normalizedInclusiveTicks);
    element.children[1].text = Utils
        .formatPercentNormalized(item.profileCode.normalizedExclusiveTicks);
    _updateLines(element.children[2].children, depth);
    if (item.children.isNotEmpty) {
      element.children[3].text =
          _tree.isExpanded(item) ? _expandedIcon : _collapsedIcon;
    } else {
      element.children[3].text = '';
    }
    element.children[4].text = Utils.formatPercentNormalized(item.percentage);
    element.children[5] =
        new CodeRefElement(_isolate, item.profileCode.code, queue: _r.queue)
          ..classes = ['name'];
  }

  void _updateMemoryCodeRow(
      HtmlElement element, M.CodeCallTreeNode item, int depth) {
    element.children[0].text =
        Utils.formatSize(item.inclusiveNativeAllocations);
    element.children[0].title = 'memory allocated from resulting calls: '
        '${item.inclusiveNativeAllocations}B';
    element.children[1].text =
        Utils.formatSize(item.exclusiveNativeAllocations);
    element.children[1].title = 'memory allocated during execution: '
        '${item.exclusiveNativeAllocations}B';
    _updateLines(element.children[2].children, depth);
    if (item.children.isNotEmpty) {
      element.children[3].text =
          _tree.isExpanded(item) ? _expandedIcon : _collapsedIcon;
    } else {
      element.children[3].text = '';
    }
    element.children[4].text = Utils.formatPercentNormalized(item.percentage);
    element.children[5] =
        new CodeRefElement(null, item.profileCode.code, queue: _r.queue)
          ..classes = ['name'];
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
