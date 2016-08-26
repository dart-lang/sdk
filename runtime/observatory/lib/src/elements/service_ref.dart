// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library service_ref_element;

import 'dart:html';

import 'package:logging/logging.dart';
import 'package:observatory/service.dart';
import 'package:observatory/repositories.dart';
import 'package:polymer/polymer.dart';

import 'helpers/any_ref.dart';
import 'observatory_element.dart';

class ServiceRefElement extends ObservatoryElement {
  @published ServiceObject ref;
  @published bool internal = false;
  @published String expandKey;
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
    return gotoLink('/inspect', ref);
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
    return (name == null) || name.isEmpty;
  }


  @published bool expanded = false;
  dynamic expander() {
    return expandEvent;
  }
  void expandEvent(bool expand, Function onDone) {
    if (expand) {
      ref.reload().then((result) {
        ref = result;
        notifyPropertyChange(#ref, 0, 1);
        expanded = true;
      }).whenComplete(onDone);
    } else {
      expanded = false;
      onDone();
    }
  }
}


@CustomTag('any-service-ref')
class AnyServiceRefElement extends ObservatoryElement {
  @published ServiceObject ref;
  @published String expandKey;
  @published bool asValue = false;
  AnyServiceRefElement.created() : super.created();

  refChanged(oldValue) {
    // Remove the current view.
    children.clear();
    if (ref == null) {
      Logger.root.info('Viewing null object.');
      return;
    }
    var obj;
    if (ref is Guarded) {
      var g = ref as Guarded;
      obj = g.asValue ?? g.asSentinel;
    } else {
      obj = ref;
    }
    var element;
    switch (obj.type) {
      case 'Class':
        if (asValue) {
          element = new Element.tag('class-ref-as-value');
          element.ref = obj;
        } else {
          element = new Element.tag('class-ref');
          element.ref = obj;
        }
        break;
      case 'Code':
        element = new Element.tag('code-ref');
        element.ref = obj;
        break;
      case 'Context':
        element = new Element.tag('context-ref');
        element.ref = obj;
        break;
      case 'Error':
        element = new Element.tag('error-ref');
        element.ref = obj;
        break;
      case 'Field':
        element = new Element.tag('field-ref');
        element.ref = obj;
        break;
      case 'Function':
        element = new Element.tag('function-ref');
        element.ref = obj;
        break;
      case 'Instance':
        element = new Element.tag('instance-ref');
        element.ref = obj;
        break;
      case 'Library':
        if (asValue) {
          element =
              new Element.tag('library-ref-as-value');
          element.ref = obj;
        } else {
          element =
              new Element.tag('library-ref');
          element.ref = obj;
        }
        break;
      case 'Script':
        element = new Element.tag('script-ref');
        element.ref = obj;
        break;
      default:
        element = anyRef(obj.isolate, obj,
            new InstanceRepository(obj.isolate), queue: app.queue);
        break;
    }
    if (element == null) {
      Logger.root.info('Unable to find a ref element for \'${ref.type}\'');
      element = new Element.tag('span');
      element.text = "<<Unknown service ref: $ref>>";
      return;
    }
    children.add(element);
  }
}
