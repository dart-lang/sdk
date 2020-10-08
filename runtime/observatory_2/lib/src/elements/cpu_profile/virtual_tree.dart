// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html';
import 'dart:math' as Math;
import 'package:observatory_2/models.dart' as M;
import 'package:observatory_2/src/elements/stack_trace_tree_config.dart'
    show ProfileTreeMode;
import 'package:observatory_2/src/elements/code_ref.dart';
import 'package:observatory_2/src/elements/containers/virtual_tree.dart';
import 'package:observatory_2/src/elements/function_ref.dart';
import 'package:observatory_2/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory_2/src/elements/helpers/custom_element.dart';
import 'package:observatory_2/utils.dart';

export 'package:observatory_2/src/elements/stack_trace_tree_config.dart'
    show ProfileTreeMode;

class CpuProfileVirtualTreeElement extends CustomElement implements Renderable {
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
    CpuProfileVirtualTreeElement e = new CpuProfileVirtualTreeElement.created();
    e._r =
        new RenderingScheduler<CpuProfileVirtualTreeElement>(e, queue: queue);
    e._isolate = owner;
    e._profile = profile;
    e._mode = mode;
    e._type = type;
    e._direction = direction;
    return e;
  }

  CpuProfileVirtualTreeElement.created()
      : super.created('cpu-profile-virtual-tree');

  @override
  attached() {
    super.attached();
    _r.enable();
  }

  @override
  detached() {
    super.detached();
    _r.disable(notify: true);
    children = <Element>[];
  }

  VirtualTreeElement _tree;

  void render() {
    var tree;
    var create;
    var update;
    var search;
    switch (type) {
      case M.SampleProfileType.cpu:
        create = _createCpuRow;
        if (mode == ProfileTreeMode.code) {
          update = _updateCpuCodeRow;
          search = _searchCode;
          tree = _profile.loadCodeTree(_direction);
        } else if (mode == ProfileTreeMode.function) {
          update = _updateCpuFunctionRow;
          search = _searchFunction;
          tree = _profile.loadFunctionTree(_direction);
        } else {
          throw new Exception('Unknown ProfileTreeMode: $mode');
        }
        break;
      case M.SampleProfileType.memory:
        create = _createMemoryRow;
        if (mode == ProfileTreeMode.code) {
          update = _updateMemoryCodeRow;
          search = _searchCode;
          tree = _profile.loadCodeTree(_direction);
        } else if (mode == ProfileTreeMode.function) {
          update = _updateMemoryFunctionRow;
          search = _searchFunction;
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
      children = <Element>[new HeadingElement.h1()..text = 'No Results'];
      return;
    }
    _tree = new VirtualTreeElement(create, update, _getChildren,
        items: tree.root.children, search: search, queue: _r.queue);
    if (tree.root.children.length == 0) {
      children = <Element>[
        new DivElement()
          ..classes = ['tree-item']
          ..children = <Element>[new HeadingElement.h1()..text = 'No Samples']
      ];
      return;
    } else if (tree.root.children.length == 1) {
      _tree.expand(tree.root.children.first, autoExpandSingleChildNodes: true);
    }
    children = <Element>[_tree.element];
  }

  static HtmlElement _createCpuRow(toggle) {
    return new DivElement()
      ..classes = ['tree-item']
      ..children = <Element>[
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

  static HtmlElement _createMemoryRow(toggle) {
    return new DivElement()
      ..classes = ['tree-item']
      ..children = <Element>[
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

  static Iterable<M.CallTreeNode> _getChildren(nodeDynamic) {
    M.CallTreeNode node = nodeDynamic;
    return node.children;
  }

  static const String _expandedIcon = '▼';
  static const String _collapsedIcon = '►';

  void _updateCpuFunctionRow(HtmlElement element, itemDynamic, int depth) {
    M.FunctionCallTreeNode item = itemDynamic;
    element.children[0].text = Utils.formatPercentNormalized(
        item.profileFunction.normalizedInclusiveTicks);
    element.children[1].text = Utils.formatPercentNormalized(
        item.profileFunction.normalizedExclusiveTicks);
    _updateLines(element.children[2].children, depth);
    if (item.children.isNotEmpty) {
      element.children[3].text =
          _tree.isExpanded(item) ? _expandedIcon : _collapsedIcon;
    } else {
      element.children[3].text = '';
    }
    element.children[4].text = Utils.formatPercentNormalized(item.percentage);
    element.children[5] = (new FunctionRefElement(
            _isolate, item.profileFunction.function,
            queue: _r.queue)
          ..classes = ['name'])
        .element;
  }

  void _updateMemoryFunctionRow(HtmlElement element, itemDynamic, int depth) {
    M.FunctionCallTreeNode item = itemDynamic;
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
    element.children[5] = (new FunctionRefElement(
            null, item.profileFunction.function,
            queue: _r.queue)
          ..classes = ['name'])
        .element;
  }

  bool _searchFunction(Pattern pattern, itemDynamic) {
    M.FunctionCallTreeNode item = itemDynamic;
    return M
        .getFunctionFullName(item.profileFunction.function)
        .contains(pattern);
  }

  void _updateCpuCodeRow(HtmlElement element, itemDynamic, int depth) {
    M.CodeCallTreeNode item = itemDynamic;
    element.children[0].text = Utils.formatPercentNormalized(
        item.profileCode.normalizedInclusiveTicks);
    element.children[1].text = Utils.formatPercentNormalized(
        item.profileCode.normalizedExclusiveTicks);
    _updateLines(element.children[2].children, depth);
    if (item.children.isNotEmpty) {
      element.children[3].text =
          _tree.isExpanded(item) ? _expandedIcon : _collapsedIcon;
    } else {
      element.children[3].text = '';
    }
    element.children[4].text = Utils.formatPercentNormalized(item.percentage);
    element.children[5] =
        (new CodeRefElement(_isolate, item.profileCode.code, queue: _r.queue)
              ..classes = ['name'])
            .element;
  }

  void _updateMemoryCodeRow(HtmlElement element, itemDynamic, int depth) {
    M.CodeCallTreeNode item = itemDynamic;
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
        (new CodeRefElement(null, item.profileCode.code, queue: _r.queue)
              ..classes = ['name'])
            .element;
  }

  bool _searchCode(Pattern pattern, itemDynamic) {
    M.CodeCallTreeNode item = itemDynamic;
    return item.profileCode.code.name.contains(pattern);
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
