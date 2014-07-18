library dart2js.compilation_info;

import 'dart2jslib.dart';
import 'elements/elements.dart';
import 'tree/tree.dart';


abstract class CompilationInformation {
  factory CompilationInformation(Enqueuer enqueuer, bool dumpInfoEnabled) {
    if (dumpInfoEnabled) {
      return new _CompilationInformation(enqueuer);
    } else {
      return new _EmptyCompilationInformation();
    }
  }

  Map<Element, Set<Element>> get enqueuesMap;
  Map<Element, Set<Element>> get addsToWorkListMap;

  void enqueues(Element function, Element source) {}
  void addsToWorkList(Element context, Element element) {}
  void registerCallSite(TreeElements context, Send node) {}
}

class _EmptyCompilationInformation implements CompilationInformation {
  _EmptyCompilationInformation();
  Map<Element, Set<Element>> get enqueuesMap => <Element, Set<Element>>{};
  Map<Element, Set<Element>> get addsToWorkListMap => <Element, Set<Element>>{};

  void enqueues(Element function, Element source) {}
  void addsToWorkList(Element context, Element element) {}
  void registerCallSite(TreeElements context, Send node) {}
}


class _CompilationInformation implements CompilationInformation {
  final String prefix;

  final Map<Element, Set<Element>> enqueuesMap = {};
  final Map<Element, Set<Element>> addsToWorkListMap = {};

  _CompilationInformation(Enqueuer enqueuer)
    : prefix = enqueuer.isResolutionQueue ? 'resolution' : 'codegen';

  Set<CallSite> callSites = new Set<CallSite>();

  enqueues(Element function, Element source) {
    enqueuesMap.putIfAbsent(function, () => new Set())
    .add(source);
  }

  addsToWorkList(Element context, Element element) {
    addsToWorkListMap.putIfAbsent(context, () => new Set())
    .add(element);
  }

  registerCallSite(TreeElements context, Send node) {
    callSites.add(new CallSite(context, node));
  }
}

class CallSite {
  final TreeElements context;
  final Send node;
  CallSite(this.context, this.node);
}
