#!/usr/bin/python
# Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

html_interface_renames = {
    'DOMCoreException': 'DOMException',
    'DOMFormData': 'FormData',
    'DOMWindow': 'LocalWindow',
    'History': 'LocalHistory',
    'Location': 'LocalLocation',
    'WebKitAnimation': 'Animation',
    'WebKitAnimationEvent': 'AnimationEvent',
    'WebKitBlobBuilder': 'BlobBuilder',
    'WebKitCSSKeyframeRule': 'CSSKeyframeRule',
    'WebKitCSSKeyframesRule': 'CSSKeyframesRule',
    'WebKitCSSMatrix': 'CSSMatrix',
    'WebKitCSSTransformValue': 'CSSTransformValue',
    'WebKitFlags': 'Flags',
    'WebKitLoseContext': 'LoseContext',
    'WebKitPoint': 'Point',
    'WebKitTransitionEvent': 'TransitionEvent',
    'XMLHttpRequest': 'HttpRequest',
    'XMLHttpRequestException': 'HttpRequestException',
    'XMLHttpRequestProgressEvent': 'HttpRequestProgressEvent',
    'XMLHttpRequestUpload': 'HttpRequestUpload',
}

# Members from the standard dom that should not be exposed publicly in dart:html
# but need to be exposed internally to implement dart:html on top of a standard
# browser.
_private_html_members = set([
  'CustomEvent.initCustomEvent',
  'Document.createElement',
  'Document.createElementNS',
  'Document.createEvent',
  'Document.createTextNode',
  'Document.createTouchList',
  'DocumentFragment.querySelector',
  'DocumentFragment.querySelectorAll',
  'Document.getElementById',
  'Document.getElementsByClassName',
  'Document.getElementsByName',
  'Document.getElementsByTagName',
  'Document.querySelector',
  'Document.querySelectorAll',
  'Element.childElementCount',
  'Element.children',
  'Element.className',
  'Element.firstElementChild',
  'Element.getAttribute',
  'Element.getElementsByClassName',
  'Element.getElementsByTagName',
  'Element.hasAttribute',
  'Element.lastElementChild',
  'Element.querySelector',
  'Element.querySelectorAll',
  'Element.removeAttribute',
  'Element.setAttribute',
  'Event.initEvent',
  'EventTarget.addEventListener',
  'EventTarget.dispatchEvent',
  'EventTarget.removeEventListener',
  'LocalWindow.getComputedStyle',
  'MouseEvent.initMouseEvent',
  'Node.appendChild',
  'Node.attributes',
  'Node.childNodes',
  'Node.firstChild',
  'Node.lastChild',
  "Node.nodeType",
  'Node.removeChild',
  'Node.replaceChild',
  'ShadowRoot.getElementById',
  'ShadowRoot.getElementsByClassName',
  'ShadowRoot.getElementsByTagName',
  'Storage.clear',
  'Storage.getItem',
  'Storage.key',
  'Storage.length',
  'Storage.removeItem',
  'Storage.setItem',
  'WheelEvent.wheelDeltaX',
  'WheelEvent.wheelDeltaY',
])

# Members from the standard dom that exist in the dart:html library with
# identical functionality but with cleaner names.
_renamed_html_members = {
    'Document.defaultView': 'window',
    'Element.webkitMatchesSelector' : 'matchesSelector',
    'Element.scrollIntoViewIfNeeded': 'scrollIntoView',
    'Node.cloneNode': 'clone',
    'Node.nextSibling': 'nextNode',
    'Node.ownerDocument': 'document',
    'Node.parentNode': 'parent',
    'Node.previousSibling': 'previousNode',
    'Node.textContent': 'text',
    'SVGElement.className': '$dom_svgClassName',
    'SVGAnimatedString.className': '$dom_svgClassName',
    'SVGStylable.className': '$dom_svgClassName',
}

# Members and classes from the dom that should be removed completely from
# dart:html.  These could be expressed in the IDL instead but expressing this
# as a simple table instead is more concise.
# Syntax is: ClassName.(get\.|set\.)?MemberName
# Using get: and set: is optional and should only be used when a getter needs
# to be suppressed but not the setter, etc.
# TODO(jacobr): cleanup and augment this list.
_removed_html_members = set([
    'NodeList.item',
    "Attr.*",
#    "BarProp.*",
#    "BarInfo.*",
#    "Blob.webkitSlice",
#    "CDATASection.*",
#    "Comment.*",
#    "DOMImplementation.*",
    "CanvasRenderingContext2D.setFillColor",
    "CanvasRenderingContext2D.setStrokeColor",
    "Document.get:forms",
#    "Document.get:selectedStylesheetSet",
#    "Document.set:selectedStylesheetSet",
#    "Document.get:preferredStylesheetSet",
    "Document.get:links",
    "Document.set:domain",
    "Document.createAttributeNS",
    "Document.get:inputEncoding",
    "Document.get:height",
    "Document.get:width",
    "Element.getElementsByTagNameNS",
    "Document.get:compatMode",
    "Document.importNode",
    "Document.evaluate",
    "Document.get:images",
    "Document.createExpression",
    "Document.getOverrideStyle",
    "Document.xmlStandalone",
    "Document.createComment",
    "Document.adoptNode",
    "Document.get:characterSet",
    "Document.createAttribute",
    "Document.get:URL",
    "Document.createEntityReference",
    "Document.get:documentURI",
    "Document.set:documentURI",
    "Document.createNodeIterator",
    "Document.createProcessingInstruction",
    "Document.get:doctype",
    "Document.createTreeWalker",
    "Document.location",
    "Document.createNSResolver",
    "Document.get:xmlEncoding",
    "Document.get:defaultCharset",
    "Document.get:applets",
    "Document.getSelection",
    "Document.xmlVersion",
    "Document.get:anchors",
    "Document.getElementsByTagNameNS",
    "DocumentType.*",
    "Element.hasAttributeNS",
    "Element.getAttributeNS",
    "Element.setAttributeNode",
    "Element.getAttributeNode",
    "Element.removeAttributeNode",
    "Element.removeAttributeNS",
    "Element.setAttributeNodeNS",
    "Element.getAttributeNodeNS",
    "Element.setAttributeNS",
    "BodyElement.text",
    "AnchorElement.text",
    "OptionElement.text",
    "ScriptElement.text",
    "TitleElement.text",
#    "EventSource.get:url",
# TODO(jacobr): should these be removed?
    "Document.close",
    "Document.hasFocus",

    "Document.vlinkColor",
    "Document.captureEvents",
    "Document.releaseEvents",
    "Document.get:compatMode",
    "Document.designMode",
    "Document.dir",
    "Document.all",
    "Document.write",
    "Document.fgColor",
    "Document.bgColor",
    "Document.get:plugins",
    "Document.alinkColor",
    "Document.get:embeds",
    "Document.open",
    "Document.clear",
    "Document.get:scripts",
    "Document.writeln",
    "Document.linkColor",
    "Element.get:itemRef",
    "Element.outerText",
    "Element.accessKey",
    "Element.get:itemType",
    "Element.innerText",
    "Element.set:outerHTML",
    "Element.itemScope",
    "Element.itemValue",
    "Element.itemId",
    "Element.get:itemProp",
    'Element.scrollIntoView',
    'Element.get:classList',
    "FormElement.get:elements",
    "HTMLFrameElement.*",
    "HTMLFrameSetElement.*",
    "HtmlElement.version",
    "HtmlElement.manifest",
    "Document.version",
    "Document.manifest",
    "InputElement.dirName",
    "HTMLIsIndexElement.*",
    "HTMLOptionsCollection.*",
    "HTMLPropertiesCollection.*",
    "SelectElement.remove",
    "TextAreaElement.dirName",
    "NamedNodeMap.*",
    "Node.isEqualNode",
    "Node.get:TEXT_NODE",
    "Node.hasAttributes",
    "Node.get:DOCUMENT_TYPE_NODE",
    "Node.get:DOCUMENT_POSITION_FOLLOWING",
    "Node.lookupNamespaceURI",
    "Node.get:ELEMENT_NODE",
    "Node.get:namespaceURI",
    "Node.get:DOCUMENT_FRAGMENT_NODE",
    "Node.get:localName",
    "Node.isDefaultNamespace",
    "Node.compareDocumentPosition",
    "Node.get:baseURI",
    "Node.isSameNode",
    "Node.get:DOCUMENT_POSITION_DISCONNECTED",
    "Node.get:DOCUMENT_NODE",
    "Node.get:DOCUMENT_POSITION_CONTAINS",
    "Node.get:COMMENT_NODE",
    "Node.get:ENTITY_REFERENCE_NODE",
    "Node.isSupported",
    "Node.get:DOCUMENT_POSITION_IMPLEMENTATION_SPECIFIC",
    "Node.get:NOTATION_NODE",
    "Node.normalize",
    "Node.get:parentElement",
    "Node.get:ATTRIBUTE_NODE",
    "Node.get:ENTITY_NODE",
    "Node.get:DOCUMENT_POSITION_CONTAINED_BY",
    "Node.get:prefix",
    "Node.set:prefix",
    "Node.get:DOCUMENT_POSITION_PRECEDING",
    "Node.get:nodeValue",
    "Node.set:nodeValue",
    "Node.get:CDATA_SECTION_NODE",
    "Node.get:nodeName",
    "Node.lookupPrefix",
    "Node.get:PROCESSING_INSTRUCTION_NODE",
    'ShadowRoot.getElementsByTagNameNS',
    "LocalWindow.get:frames",
    "LocalWindow.get:length",
    "LocalWindow.webkitCancelRequestAnimationFrame",
    "WheelEvent.wheelDelta",
    ])

class HtmlRenamer(object):
  def __init__(self, database):
    self._database = database

  def RenameInterface(self, interface):
    if interface.id.startswith('HTML'):
      if any(interface.id in ['Element', 'Document']
             for interface in self._database.Hierarchy(interface)):
        return interface.id[len('HTML'):]
    elif interface.id in html_interface_renames:
      return html_interface_renames[interface.id]
    return interface.id

  def RenameMember(self, interface_name, member_node, member, member_prefix=''):
    """
    Returns the name of the member in the HTML library or None if the member is
    suppressed in the HTML library
    """
    interface = self._database.GetInterface(interface_name)

    if self._FindMatch(interface, member, member_prefix, _removed_html_members):
      return None

    if 'CheckSecurityForNode' in member_node.ext_attrs:
      return None

    name = self._FindMatch(interface, member, member_prefix,
                           _renamed_html_members)
    target_name = _renamed_html_members[name] if name else member
    if self._FindMatch(interface, member, member_prefix, _private_html_members):
      if not target_name.startswith('$dom_'):  # e.g. $dom_svgClassName
        target_name = '$dom_' + target_name
    return target_name

  def _FindMatch(self, interface, member, member_prefix, candidates):
    for interface in self._database.Hierarchy(interface):
      html_interface_name = self.RenameInterface(interface)
      member_name = html_interface_name + '.' + member
      if member_name in candidates:
        return member_name
      member_name = html_interface_name + '.' + member_prefix + member
      if member_name in candidates:
        return member_name
