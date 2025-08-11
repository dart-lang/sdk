// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:math' as Math;

import 'package:web/web.dart';

import 'package:observatory/models.dart' as M;
import 'package:observatory/src/elements/code_ref.dart';
import 'package:observatory/src/elements/containers/virtual_tree.dart';
import 'package:observatory/src/elements/function_ref.dart';
import 'package:observatory/src/elements/helpers/custom_element.dart';
import 'package:observatory/src/elements/helpers/element_utils.dart';
import 'package:observatory/src/elements/helpers/rendering_scheduler.dart';
import 'package:observatory/utils.dart';

import 'package:observatory/src/elements/stack_trace_tree_config.dart'
    show ProfileTreeMode;

export 'package:observatory/src/elements/stack_trace_tree_config.dart'
    show ProfileTreeMode;

class CpuProfileVirtualTreeElement extends CustomElement implements Renderable {
  late RenderingScheduler<CpuProfileVirtualTreeElement> _r;

  Stream<RenderedEvent<CpuProfileVirtualTreeElement>> get onRendered =>
      _r.onRendered;

  late M.ProfileTreeDirection _direction;
  late ProfileTreeMode _mode;
  late M.SampleProfileType _type;
  M.IsolateRef? _isolate;
  late M.SampleProfile _profile;
  Iterable<M.CallTreeNodeFilter>? _filters;

  M.ProfileTreeDirection get direction => _direction;
  ProfileTreeMode get mode => _mode;
  M.SampleProfileType get type => _type;
  M.IsolateRef? get isolate => _isolate;
  M.SampleProfile get profile => _profile;
  Iterable<M.CallTreeNodeFilter>? get filters => _filters;

  set direction(M.ProfileTreeDirection value) =>
      _direction = _r.checkAndReact(_direction, value);
  set mode(ProfileTreeMode value) => _mode = _r.checkAndReact(_mode, value);
  set filters(Iterable<M.CallTreeNodeFilter>? value) {
    _filters = new List.unmodifiable(value!);
    _r.dirty();
  }

  factory CpuProfileVirtualTreeElement(
      M.IsolateRef? isolate, M.SampleProfile profile,
      {ProfileTreeMode mode = ProfileTreeMode.function,
      M.SampleProfileType type = M.SampleProfileType.cpu,
      M.ProfileTreeDirection direction = M.ProfileTreeDirection.exclusive,
      RenderingQueue? queue}) {
    CpuProfileVirtualTreeElement e = new CpuProfileVirtualTreeElement.created();
    e._r =
        new RenderingScheduler<CpuProfileVirtualTreeElement>(e, queue: queue);
    e._isolate = isolate;
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
    removeChildren();
  }

  VirtualTreeElement? _tree;

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
    }
    if (filters != null) {
      tree = filters!.fold(tree, (dynamic tree, filter) {
        return tree?.filtered(filter);
      });
    }
    if (tree == null) {
      children = <HTMLElement>[
        new HTMLHeadingElement.h1()..textContent = 'No Results'
      ];
      return;
    }
    _tree = new VirtualTreeElement(create, update, _getChildren,
        items: tree.root.children, search: search, queue: _r.queue);
    if (tree.root.children.length == 0) {
      children = <HTMLElement>[
        new HTMLDivElement()
          ..className = 'tree-item'
          ..appendChild(HTMLHeadingElement.h1()..textContent = 'No Samples')
      ];
      return;
    } else if (tree.root.children.length == 1) {
      _tree!.expand(tree.root.children.first, autoExpandSingleChildNodes: true);
    }
    children = <HTMLElement>[_tree!.element];
  }

  static HTMLElement _createCpuRow(toggle) {
    return new HTMLDivElement()
      ..className = 'tree-item'
      ..appendChildren(<HTMLElement>[
        new HTMLSpanElement()
          ..className = 'inclusive'
          ..title = 'global % on stack',
        new HTMLSpanElement()
          ..className = 'exclusive'
          ..title = 'global % executing',
        new HTMLSpanElement()..className = 'lines',
        new HTMLButtonElement()
          ..className = 'expander'
          ..onClick.listen((_) => toggle(autoToggleSingleChildNodes: true)),
        new HTMLSpanElement()
          ..className = 'percentage'
          ..title = 'tree node %',
        new HTMLSpanElement()..className = 'name'
      ]);
  }

  static HTMLElement _createMemoryRow(toggle) {
    return new HTMLDivElement()
      ..className = 'tree-item'
      ..appendChildren(<HTMLElement>[
        new HTMLSpanElement()
          ..className = 'inclusive'
          ..title = 'memory allocated from resulting calls: ',
        new HTMLSpanElement()
          ..className = 'exclusive'
          ..title = 'memory allocated during execution: ',
        new HTMLSpanElement()..className = 'lines',
        new HTMLButtonElement()
          ..className = 'expander'
          ..onClick.listen((_) => toggle(autoToggleSingleChildNodes: true)),
        new HTMLSpanElement()
          ..className = 'percentage'
          ..title = 'tree node %',
        new HTMLSpanElement()..className = 'name'
      ]);
  }

  static Iterable<M.CallTreeNode> _getChildren(nodeDynamic) {
    M.CallTreeNode node = nodeDynamic;
    return node.children;
  }

  static const String _expandedIcon = '▼';
  static const String _collapsedIcon = '►';

  void _updateCpuFunctionRow(HTMLElement element, itemDynamic, int depth) {
    M.FunctionCallTreeNode item = itemDynamic;
    (element.children.item(0) as HTMLElement).textContent =
        Utils.formatPercentNormalized(
            item.profileFunction.normalizedInclusiveTicks);
    (element.children.item(1) as HTMLElement).textContent =
        Utils.formatPercentNormalized(
            item.profileFunction.normalizedExclusiveTicks);
    _updateLines(element.children.item(2) as HTMLElement, depth);
    if (item.children.isNotEmpty) {
      (element.children.item(3) as HTMLElement).textContent =
          _tree!.isExpanded(item) ? _expandedIcon : _collapsedIcon;
    } else {
      (element.children.item(3) as HTMLElement).textContent = '';
    }
    (element.children.item(4) as HTMLElement).textContent =
        Utils.formatPercentNormalized(item.percentage);
    final old = element.children.item(5)!;
    element.insertBefore(
        old,
        element.appendChild((new FunctionRefElement(
                _isolate, item.profileFunction.function!,
                queue: _r.queue)
              ..className = 'name')
            .element));
    element.removeChild(old);
  }

  void _updateMemoryFunctionRow(HTMLElement element, itemDynamic, int depth) {
    M.FunctionCallTreeNode item = itemDynamic;
    (element.children.item(0) as HTMLElement).textContent =
        Utils.formatSize(item.inclusiveNativeAllocations);
    (element.children.item(0) as HTMLElement).title =
        'memory allocated from resulting calls: '
        '${item.inclusiveNativeAllocations}B';
    (element.children.item(1) as HTMLElement).textContent =
        Utils.formatSize(item.exclusiveNativeAllocations);
    (element.children.item(1) as HTMLElement).title =
        'memory allocated during execution: '
        '${item.exclusiveNativeAllocations}B';
    _updateLines(element.children.item(2)!, depth);
    if (item.children.isNotEmpty) {
      (element.children.item(3) as HTMLElement).textContent =
          _tree!.isExpanded(item) ? _expandedIcon : _collapsedIcon;
    } else {
      (element.children.item(3) as HTMLElement).textContent = '';
    }
    (element.children.item(4) as HTMLElement).textContent =
        Utils.formatPercentNormalized(item.percentage);
    final old = element.children.item(5)!;
    element.insertBefore(
        old,
        (new FunctionRefElement(null, item.profileFunction.function!,
                queue: _r.queue)
              ..className = 'name')
            .element);
    element.removeChild(old);
  }

  bool _searchFunction(Pattern pattern, itemDynamic) {
    M.FunctionCallTreeNode item = itemDynamic;
    return M
        .getFunctionFullName(item.profileFunction.function!)
        .contains(pattern);
  }

  void _updateCpuCodeRow(HTMLElement element, itemDynamic, int depth) {
    M.CodeCallTreeNode item = itemDynamic;
    (element.children.item(0) as HTMLElement).textContent =
        Utils.formatPercentNormalized(
            item.profileCode.normalizedInclusiveTicks);
    (element.children.item(1) as HTMLElement).textContent =
        Utils.formatPercentNormalized(
            item.profileCode.normalizedExclusiveTicks);
    _updateLines(element.children.item(2)!, depth);
    if (item.children.isNotEmpty) {
      (element.children.item(3) as HTMLElement).textContent =
          _tree!.isExpanded(item) ? _expandedIcon : _collapsedIcon;
    } else {
      (element.children.item(3) as HTMLElement).textContent = '';
    }
    (element.children.item(4) as HTMLElement).textContent =
        Utils.formatPercentNormalized(item.percentage);
    final old = element.children.item(5)!;
    element.insertBefore(
        old,
        element.appendChild((new CodeRefElement(
                _isolate, item.profileCode.code!,
                queue: _r.queue)
              ..className = 'name')
            .element));
    element.removeChild(old);
  }

  void _updateMemoryCodeRow(HTMLElement element, itemDynamic, int depth) {
    M.CodeCallTreeNode item = itemDynamic;
    (element.children.item(0) as HTMLElement).textContent =
        Utils.formatSize(item.inclusiveNativeAllocations);
    (element.children.item(0) as HTMLElement).title =
        'memory allocated from resulting calls: '
        '${item.inclusiveNativeAllocations}B';
    (element.children.item(1) as HTMLElement).textContent =
        Utils.formatSize(item.exclusiveNativeAllocations);
    (element.children.item(1) as HTMLElement).title =
        'memory allocated during execution: '
        '${item.exclusiveNativeAllocations}B';
    _updateLines(element.children.item(2)!, depth);
    if (item.children.isNotEmpty) {
      (element.children.item(3) as HTMLElement).textContent =
          _tree!.isExpanded(item) ? _expandedIcon : _collapsedIcon;
    } else {
      (element.children.item(3) as HTMLElement).textContent = '';
    }
    (element.children.item(4) as HTMLElement).textContent =
        Utils.formatPercentNormalized(item.percentage);
    final old = element.children.item(5)!;
    element.insertBefore(
        old,
        element.appendChild(
            (new CodeRefElement(null, item.profileCode.code!, queue: _r.queue)
                  ..className = 'name')
                .element));
    element.removeChild(old);
  }

  bool _searchCode(Pattern pattern, itemDynamic) {
    M.CodeCallTreeNode item = itemDynamic;
    return item.profileCode.code!.name!.contains(pattern);
  }

  static _updateLines(Element element, int n) {
    n = Math.max(0, n);
    while (element.children.length > n) {
      element.removeChild(element.lastChild!);
    }
    while (element.children.length < n) {
      element.appendChild(HTMLSpanElement());
    }
  }
}
