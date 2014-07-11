library dart2js.compilation_info;

import 'dart2jslib.dart';
import 'elements/elements.dart';
import 'tree/tree.dart';


class CompilationInformation {
  static const DUMP_COMPILATION_INFO_DATABASE = true;

  CompilationInformation._internal();

  factory CompilationInformation(Enqueuer enqueuer) {
    if (DUMP_COMPILATION_INFO_DATABASE) {
      return new _CompilationInformation(enqueuer);
    } else {
      return new CompilationInformation._internal();
    }
  }


  Map<String, Map<dynamic, Set>> relations = {};

  void enqueues(Element function, Element source) {}
  void addsToWorkList(Element context, Element element) {}
  void registerCallSite(TreeElements context, Send node) {}
}


class _CompilationInformation implements CompilationInformation {
  final String prefix;

  Map<String, Map<dynamic, Set>> relations = {};

  _CompilationInformation(Enqueuer enqueuer)
    : prefix = enqueuer.isResolutionQueue ? 'resolution' : 'codegen';

  Set<CallSite> callSites = new Set<CallSite>();

  put(String relation, target, source) {
    relations.putIfAbsent(relation, () => {})
      .putIfAbsent(target, () => new Set())
      .add(source);
  }

  enqueues(Element function, Element source) {
    put('enqueues', function, source);
  }

  addsToWorkList(Element context, Element element) {
    put('addsToWorklist', context, element);
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
