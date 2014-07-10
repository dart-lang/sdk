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

  void enqueues(Element function, Element source) {}
  void addsToWorkList(Element context, Element element) {}
  void registerCallSite(TreeElements context, Send node) {}

  void collectGlobalInformation(Compiler compiler) {}

  void buildDatabase(builder) {}
}


class _CompilationInformation implements CompilationInformation {
  final String prefix;

  _CompilationInformation(Enqueuer enqueuer)
    : prefix = enqueuer.isResolutionQueue ? 'resolution' : 'codegen';

  // TODO(karlklose): support arbitrary relations.
  Map<String, Map<dynamic, Set>> relations = {};

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

  void collectGlobalInformation(Compiler compiler) {
    for (CallSite callSite in callSites) {
      TreeElements context = callSite.context;
      Selector selector = context.getSelector(callSite.node);
      Element source = context.currentElement;
      for (Element target in compiler.world.allFunctions.filter(selector)) {
        put('calls', source, target);
      }
    }
  }

  void buildDatabase(builder) {
    for (String name in relations.keys) {
      relations[name].forEach((source, target) {
        builder.addRelation('${prefix}_$name', [source, target]);
      });
    }
  }
}


class CallSite {
  final TreeElements context;
  final Send node;
  CallSite(this.context, this.node);
}
