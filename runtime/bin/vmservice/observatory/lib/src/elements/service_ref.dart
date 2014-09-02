// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library service_ref_element;

import 'dart:html';
import 'package:logging/logging.dart';
import 'package:polymer/polymer.dart';
import 'observatory_element.dart';
import 'package:observatory/service.dart';

@CustomTag('service-ref')
class ServiceRefElement extends ObservatoryElement {
  @published ServiceObject ref;
  @published bool internal = false;
  ServiceRefElement.created() : super.created();

  void refChanged(oldValue) {
    notifyPropertyChange(#url, "", url);
    notifyPropertyChange(#name, [], name);
    notifyPropertyChange(#nameIsEmpty, 0, 1);
    notifyPropertyChange(#hoverText, "", hoverText);
  }

  String get url {
    if (ref == null) {
      return 'NULL REF';
    }
    return gotoLink(ref.link);
  }

  String get serviceId {
    if (ref == null) {
      return 'NULL REF';
    }
    return ref.id;
  }

  String get hoverText {
    if (ref == null) {
      return 'NULL REF';
    }
    return ref.vmName;
  }

  String get name {
    if (ref == null) {
      return 'NULL REF';
    }
    return ref.name;
  }

  // Workaround isEmpty not being useable due to missing @MirrorsUsed.
  bool get nameIsEmpty {
    return name.isEmpty;
  }
}


@CustomTag('any-service-ref')
class AnyServiceRefElement extends ObservatoryElement {
  @published ServiceObject ref;
  AnyServiceRefElement.created() : super.created();

  Element _constructElementForRef() {
    var type = ref.vmType;
    switch (type) {
     case 'Class':
        ServiceRefElement element = new Element.tag('class-ref');
        element.ref = ref;
        return element;
      case 'Code':
        ServiceRefElement element = new Element.tag('code-ref');
        element.ref = ref;
        return element;
      case 'Error':
        ServiceRefElement element = new Element.tag('error-ref');
        element.ref = ref;
        return element;
      case 'Field':
        ServiceRefElement element = new Element.tag('field-ref');
        element.ref = ref;
        return element;
      case 'Function':
        ServiceRefElement element = new Element.tag('function-ref');
        element.ref = ref;
        return element;
      case 'Library':
        ServiceRefElement element = new Element.tag('library-ref');
        element.ref = ref;
        return element;
      case 'Array':
      case 'Bigint':
      case 'Bool':
      case 'Closure':
      case 'Double':
      case 'GrowableObjectArray':
      case 'Instance':
      case 'Mint':
      case 'Null':
      case 'Sentinel':  // TODO(rmacnak): Separate this out.
      case 'Smi':
      case 'String':
      case 'Type':
        ServiceRefElement element = new Element.tag('instance-ref');
        element.ref = ref;
        return element;
      default:
        SpanElement element = new Element.tag('span');
        element.text = "<<Unknown service ref: $ref>>";
        return element;
    }
  }

  refChanged(oldValue) {
    // Remove the current view.
    children.clear();
    if (ref == null) {
      Logger.root.info('Viewing null object.');
      return;
    }
    var type = ref.vmType;
    var element = _constructElementForRef();
    if (element == null) {
      Logger.root.info('Unable to find a ref element for \'${type}\'');
      return;
    }
    children.add(element);
    Logger.root.info('Viewing object of \'${type}\'');
  }
}
