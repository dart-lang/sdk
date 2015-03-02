// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library cpu_profile_element;

import 'dart:async';
import 'dart:html';
import 'observatory_element.dart';
import 'package:logging/logging.dart';
import 'package:observatory/service.dart';
import 'package:observatory/app.dart';
import 'package:observatory/cpu_profile.dart';
import 'package:observatory/elements.dart';
import 'package:polymer/polymer.dart';

List<String> sorted(Set<String> attributes) {
  var list = attributes.toList();
  list.sort();
  return list;
}

abstract class ProfileTreeRow<T> extends TableTreeRow {
  final CpuProfile profile;
  final T node;
  final String selfPercent;
  final String percent;
  bool _infoBoxShown = false;
  HtmlElement infoBox;
  HtmlElement infoButton;

  ProfileTreeRow(TableTree tree, TableTreeRow parent,
                 this.profile, this.node, double selfPercent, double percent)
      : super(tree, parent),
        selfPercent = Utils.formatPercentNormalized(selfPercent),
        percent = Utils.formatPercentNormalized(percent);

  static _addToMemberList(DivElement memberList, Map<String, String> items) {
    items.forEach((k, v) {
      var item = new DivElement();
      item.classes.add('memberItem');
      var name = new DivElement();
      name.classes.add('memberName');
      name.text = k;
      var value = new DivElement();
      value.classes.add('memberValue');
      value.text = v;
      item.children.add(name);
      item.children.add(value);
      memberList.children.add(item);
    });
  }

  makeInfoBox() {
    if (infoBox != null) {
      return;
    }
    infoBox = new DivElement();
    infoBox.classes.add('infoBox');
    infoBox.classes.add('shadow');
    infoBox.style.display = 'none';
    infoBox.onClick.listen((e) => e.stopPropagation());
  }

  makeInfoButton() {
    infoButton = new SpanElement();
    infoButton.style.marginLeft = 'auto';
    infoButton.style.marginRight = '1em';
    infoButton.children.add(new Element.tag('icon-info-outline'));
    infoButton.onClick.listen((event) {
      event.stopPropagation();
      toggleInfoBox();
    });
  }

  static const attributes = const {
    'optimized' : const ['O', null, 'Optimized'],
    'unoptimized' : const ['U', null, 'Unoptimized'],
    'inlined' : const ['I', null, 'Inlined'],
    'dart' : const ['D', null, 'Dart'],
    'tag' : const ['T', null, 'Tag'],
    'native' : const ['N', null, 'Native'],
    'stub': const ['S', null, 'Stub'],
    'synthetic' : const ['?', null, 'Synthetic'],
  };

  HtmlElement newAttributeBox(String attribute) {
    List attributeDetails = attributes[attribute];
    if (attributeDetails == null) {
      print('could not find attribute $attribute');
      return null;
    }
    var element = new SpanElement();
    element.style.border = 'solid 2px #ECECEC';
    element.style.height = '100%';
    element.style.display = 'inline-block';
    element.style.textAlign = 'center';
    element.style.minWidth = '1.5em';
    element.style.fontWeight = 'bold';
    if (attributeDetails[1] != null) {
      element.style.backgroundColor = attributeDetails[1];
    }
    element.text = attributeDetails[0];
    element.title = attributeDetails[2];
    return element;
  }

  onHide() {
    super.onHide();
    infoBox = null;
    infoButton = null;
  }

  showInfoBox() {
    if ((infoButton == null) || (infoBox == null)) {
      return;
    }
    _infoBoxShown = true;
    infoBox.style.display = 'block';
    infoButton.children.clear();
    infoButton.children.add(new Element.tag('icon-info'));
  }

  hideInfoBox() {
    _infoBoxShown = false;
    if ((infoButton == null) || (infoBox == null)) {
      return;
    }
    infoBox.style.display = 'none';
    infoButton.children.clear();
    infoButton.children.add(new Element.tag('icon-info-outline'));
  }

  toggleInfoBox() {
   if (_infoBoxShown) {
     hideInfoBox();
   } else {
     showInfoBox();
   }
  }

  hideAllInfoBoxes() {
    final List<ProfileTreeRow> rows = tree.rows;
    for (var row in rows) {
      row.hideInfoBox();
    }
  }

  onClick(MouseEvent e) {
    e.stopPropagation();
    if (e.altKey) {
      bool show = !_infoBoxShown;
      hideAllInfoBoxes();
      if (show) {
        showInfoBox();
      }
      return;
    }
    super.onClick(e);
  }

  HtmlElement newCodeRef(ProfileCode code) {
    var codeRef = new Element.tag('code-ref');
    codeRef.ref = code.code;
    return codeRef;
  }

  HtmlElement newFunctionRef(ProfileFunction function) {
    var ref = new Element.tag('function-ref');
    ref.ref = function.function;
    return ref;
  }

  HtmlElement hr() {
    var element = new HRElement();
    return element;
  }

  HtmlElement div(String text) {
    var element = new DivElement();
    element.text = text;
    return element;
  }

  HtmlElement br() {
    return new BRElement();
  }

  HtmlElement span(String text) {
    var element = new SpanElement();
    element.style.minWidth = '1em';
    element.text = text;
    return element;
  }
}

class CodeProfileTreeRow extends ProfileTreeRow<CodeCallTreeNode> {
  CodeProfileTreeRow(TableTree tree, CodeProfileTreeRow parent,
                     CpuProfile profile, CodeCallTreeNode node)
      : super(tree, parent, profile, node,
              node.profileCode.normalizedExclusiveTicks,
              node.percentage) {
    // fill out attributes.
  }

  bool hasChildren() => node.children.length > 0;

  void onShow() {
    super.onShow();

    if (children.length == 0) {
      for (var childNode in node.children) {
        var row = new CodeProfileTreeRow(tree, this, profile, childNode);
        children.add(row);
      }
    }

    // Fill in method column.
    var methodColumn = flexColumns[0];
    methodColumn.style.justifyContent = 'flex-start';
    methodColumn.style.position = 'relative';

    // Percent.
    var percentNode = new DivElement();
    percentNode.text = percent;
    percentNode.style.minWidth = '5em';
    percentNode.style.textAlign = 'right';
    percentNode.title = 'Self: $selfPercent';
    methodColumn.children.add(percentNode);

    // Gap.
    var gap = new SpanElement();
    gap.style.minWidth = '1em';
    methodColumn.children.add(gap);

    // Code link.
    var codeRef = newCodeRef(node.profileCode);
    codeRef.style.alignSelf = 'center';
    methodColumn.children.add(codeRef);

    gap = new SpanElement();
    gap.style.minWidth = '1em';
    methodColumn.children.add(gap);

    for (var attribute in sorted(node.attributes)) {
      methodColumn.children.add(newAttributeBox(attribute));
    }

    makeInfoBox();
    methodColumn.children.add(infoBox);

    infoBox.children.add(span('Code '));
    infoBox.children.add(newCodeRef(node.profileCode));
    infoBox.children.add(span(' '));
    for (var attribute in sorted(node.profileCode.attributes)) {
      infoBox.children.add(newAttributeBox(attribute));
    }
    infoBox.children.add(br());
    infoBox.children.add(br());
    var memberList = new DivElement();
    memberList.classes.add('memberList');
    infoBox.children.add(br());
    infoBox.children.add(memberList);
    ProfileTreeRow._addToMemberList(memberList, {
        'Exclusive ticks' : node.profileCode.formattedExclusiveTicks,
        'Cpu time' : node.profileCode.formattedCpuTime,
        'Inclusive ticks' : node.profileCode.formattedInclusiveTicks,
        'Call stack time' : node.profileCode.formattedOnStackTime,
    });

    makeInfoButton();
    methodColumn.children.add(infoButton);

    // Fill in self column.
    var selfColumn = flexColumns[1];
    selfColumn.style.position = 'relative';
    selfColumn.style.alignItems = 'center';
    selfColumn.text = selfPercent;
  }
}

class FunctionProfileTreeRow extends ProfileTreeRow<FunctionCallTreeNode> {
  FunctionProfileTreeRow(TableTree tree, FunctionProfileTreeRow parent,
                         CpuProfile profile, FunctionCallTreeNode node)
      : super(tree, parent, profile, node,
              node.profileFunction.normalizedExclusiveTicks,
              node.percentage) {
    // fill out attributes.
  }

  bool hasChildren() => node.children.length > 0;

  onShow() {
    super.onShow();
    if (children.length == 0) {
      for (var childNode in node.children) {
        var row = new FunctionProfileTreeRow(tree, this, profile, childNode);
        children.add(row);
      }
    }

    var methodColumn = flexColumns[0];
    methodColumn.style.justifyContent = 'flex-start';

    var codeAndFunctionColumn = new DivElement();
    codeAndFunctionColumn.classes.add('flex-column');
    codeAndFunctionColumn.style.justifyContent = 'center';
    codeAndFunctionColumn.style.width = '100%';
    methodColumn.children.add(codeAndFunctionColumn);

    var functionRow = new DivElement();
    functionRow.classes.add('flex-row');
    functionRow.style.position = 'relative';
    functionRow.style.justifyContent = 'flex-start';
    codeAndFunctionColumn.children.add(functionRow);

    // Insert the parent percentage
    var parentPercent = new SpanElement();
    parentPercent.text = percent;
    parentPercent.style.minWidth = '4em';
    parentPercent.style.alignSelf = 'center';
    parentPercent.style.textAlign = 'right';
    parentPercent.title = 'Self: $selfPercent';
    functionRow.children.add(parentPercent);

    // Gap.
    var gap = new SpanElement();
    gap.style.minWidth = '1em';
    gap.text = ' ';
    functionRow.children.add(gap);

    var functionRef = new Element.tag('function-ref');
    functionRef.ref = node.profileFunction.function;
    functionRef.style.alignSelf = 'center';
    functionRow.children.add(functionRef);

    gap = new SpanElement();
    gap.style.minWidth = '1em';
    gap.text = ' ';
    functionRow.children.add(gap);

    for (var attribute in sorted(node.attributes)) {
      functionRow.children.add(newAttributeBox(attribute));
    }

    makeInfoBox();
    functionRow.children.add(infoBox);

    if (node.profileFunction.function.kind.hasDartCode()) {
      infoBox.children.add(div('Hot code for current node'));
      infoBox.children.add(br());
      var totalTicks = node.totalCodesTicks;
      var numCodes = node.codes.length;
      for (var i = 0; i < numCodes; i++) {
        var codeRowSpan = new DivElement();
        codeRowSpan.style.paddingLeft = '1em';
        infoBox.children.add(codeRowSpan);
        var nodeCode = node.codes[i];
        var ticks = nodeCode.ticks;
        var percentage = Utils.formatPercent(ticks, totalTicks);
        var percentageSpan = new SpanElement();
        percentageSpan.style.display = 'inline-block';
        percentageSpan.text = '$percentage';
        percentageSpan.style.minWidth = '5em';
        percentageSpan.style.textAlign = 'right';
        codeRowSpan.children.add(percentageSpan);
        var codeRef = new Element.tag('code-ref');
        codeRef.ref = nodeCode.code.code;
        codeRef.style.marginLeft = '1em';
        codeRef.style.marginRight = 'auto';
        codeRef.style.width = '100%';
        codeRowSpan.children.add(codeRef);
      }
      infoBox.children.add(hr());
    }
    infoBox.children.add(span('Function '));
    infoBox.children.add(newFunctionRef(node.profileFunction));
    infoBox.children.add(span(' '));
    for (var attribute in sorted(node.profileFunction.attributes)) {
      infoBox.children.add(newAttributeBox(attribute));
    }
    var memberList = new DivElement();
    memberList.classes.add('memberList');
    infoBox.children.add(br());
    infoBox.children.add(br());
    infoBox.children.add(memberList);
    infoBox.children.add(br());
    ProfileTreeRow._addToMemberList(memberList, {
        'Exclusive ticks' : node.profileFunction.formattedExclusiveTicks,
        'Cpu time' : node.profileFunction.formattedCpuTime,
        'Inclusive ticks' : node.profileFunction.formattedInclusiveTicks,
        'Call stack time' : node.profileFunction.formattedOnStackTime,
    });

    if (node.profileFunction.function.kind.hasDartCode()) {
      infoBox.children.add(div('Hot code containing function'));
      infoBox.children.add(br());
      var totalTicks = profile.sampleCount;
      var codes = node.profileFunction.profileCodes;
      var numCodes = codes.length;
      for (var i = 0; i < numCodes; i++) {
        var codeRowSpan = new DivElement();
        codeRowSpan.style.paddingLeft = '1em';
        infoBox.children.add(codeRowSpan);
        var profileCode = codes[i];
        var code = profileCode.code;
        var ticks = profileCode.inclusiveTicks;
        var percentage = Utils.formatPercent(ticks, totalTicks);
        var percentageSpan = new SpanElement();
        percentageSpan.style.display = 'inline-block';
        percentageSpan.text = '$percentage';
        percentageSpan.style.minWidth = '5em';
        percentageSpan.style.textAlign = 'right';
        percentageSpan.title = 'Inclusive ticks';
        codeRowSpan.children.add(percentageSpan);
        var codeRef = new Element.tag('code-ref');
        codeRef.ref = code;
        codeRef.style.marginLeft = '1em';
        codeRef.style.marginRight = 'auto';
        codeRef.style.width = '100%';
        codeRowSpan.children.add(codeRef);
      }
    }

    makeInfoButton();
    methodColumn.children.add(infoButton);

    // Fill in self column.
    var selfColumn = flexColumns[1];
    selfColumn.style.position = 'relative';
    selfColumn.style.alignItems = 'center';
    selfColumn.text = selfPercent;
  }
}

/// Displays a CpuProfile
@CustomTag('cpu-profile')
class CpuProfileElement extends ObservatoryElement {
  static const MICROSECONDS_PER_SECOND = 1000000.0;

  @published Isolate isolate;
  @observable String sampleCount = '';
  @observable String refreshTime = '';
  @observable String sampleRate = '';
  @observable String stackDepth = '';
  @observable String timeSpan = '';
  @observable String fetchTime = '';
  @observable String loadTime = '';
  @observable String tagSelector = 'UserVM';
  @observable String modeSelector = 'Function';
  @observable String directionSelector = 'Up';

  @observable String state = 'Requested';
  @observable var exception;
  @observable var stackTrace;

  final Stopwatch _sw = new Stopwatch();

  final CpuProfile profile = new CpuProfile();

  CpuProfileElement.created() : super.created();

  @override
  void attached() {
    super.attached();
  }

  void isolateChanged(oldValue) {
    _getCpuProfile();
  }

  void tagSelectorChanged(oldValue) {
    _getCpuProfile();
  }

  void modeSelectorChanged(oldValue) {
    _updateView();
  }

  void directionSelectorChanged(oldValue) {
    _updateView();
  }

  void clear(var done) {
    _clearCpuProfile().whenComplete(done);
  }

  Future _clearCpuProfile() {
    profile.clear();
    if (isolate == null) {
      return new Future.value(null);
    }
    return isolate.invokeRpc('clearCpuProfile', { })
        .then((ServiceMap response) {
          _updateView();
        });
  }

  void refresh(var done) {
    _getCpuProfile().whenComplete(done);
  }

  _onFetchStarted() {
    _sw.reset();
    _sw.start();
    state = 'Requested';
  }

  _onFetchFinished() {
    _sw.stop();
    fetchTime = formatTimeMilliseconds(_sw.elapsedMilliseconds);
  }

  _onLoadStarted() {
    _sw.reset();
    _sw.start();
    state = 'Loading';
  }

  _onLoadFinished() {
    _sw.stop();
    loadTime = formatTimeMilliseconds(_sw.elapsedMilliseconds);
    state = 'Loaded';
  }

  Future _getCpuProfile() async {
    profile.clear();
    if (functionTree != null) {
      functionTree.clear();
    }
    if (codeTree != null) {
      codeTree.clear();
    }
    if (isolate == null) {
      return new Future.value(null);
    }
    _onFetchStarted();
    var response =
        await isolate.invokeRpc('getCpuProfile', { 'tags': tagSelector });
    _onFetchFinished();
    _onLoadStarted();
    await window.animationFrame;
    try {
      profile.load(isolate, response);
      _onLoadFinished();
      _updateView();
    } catch (e, st) {
      state = 'Exception';
      exception = e;
      stackTrace = st;
    }
  }

  void _updateView() {
    sampleCount = profile.sampleCount.toString();
    refreshTime = new DateTime.now().toString();
    stackDepth = profile.stackDepth.toString();
    sampleRate = profile.sampleRate.toStringAsFixed(0);
    timeSpan = formatTime(profile.timeSpan);
    if (functionTree != null) {
      functionTree.clear();
    }
    if (codeTree != null) {
      codeTree.clear();
    }
    bool exclusive = directionSelector == 'Up';
    if (modeSelector == 'Code') {
      _buildCodeTree(exclusive);
    } else {
      _buildFunctionTree(exclusive);
    }
  }

  TableTree codeTree;
  TableTree functionTree;

  void _buildFunctionTree(bool exclusive) {
    if (functionTree == null) {
      var tableBody = shadowRoot.querySelector('#treeBody');
      assert(tableBody != null);
      functionTree = new TableTree(tableBody, 2);
    }
    var tree = profile.functionTrees[exclusive ? 'exclusive' : 'inclusive'];
    if (tree == null) {
      return;
    }
    var rootRow =
        new FunctionProfileTreeRow(functionTree, null, profile, tree.root);
    functionTree.initialize(rootRow);
  }

  void _buildCodeTree(bool exclusive) {
    if (codeTree == null) {
      var tableBody = shadowRoot.querySelector('#treeBody');
      assert(tableBody != null);
      codeTree = new TableTree(tableBody, 2);
    }
    var tree = profile.codeTrees[exclusive ? 'exclusive' : 'inclusive'];
    if (tree == null) {
      return;
    }
    var rootRow = new CodeProfileTreeRow(codeTree, null, profile, tree.root);
    codeTree.initialize(rootRow);
  }
}
