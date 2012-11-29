// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of html;

class _Utils {
  static List convertToList(List list) {
    // FIXME: [possible optimization]: do not copy the array if Dart_IsArray is fine w/ it.
    final length = list.length;
    List result = new List(length);
    result.setRange(0, length, list);
    return result;
  }

  static List convertMapToList(Map map) {
    List result = [];
    map.forEach((k, v) => result.addAll([k, v]));
    return result;
  }

  static void populateMap(Map result, List list) {
    for (int i = 0; i < list.length; i += 2) {
      result[list[i]] = list[i + 1];
    }
  }

  static bool isMap(obj) => obj is Map;

  static Map createMap() => {};

  static makeUnimplementedError(String fileName, int lineNo) {
    return new UnsupportedError('[info: $fileName:$lineNo]');
  }

  static window() native "Utils_window";
  static print(String message) native "Utils_print";
  static SendPort spawnDomFunctionImpl(Function topLevelFunction) native "Utils_spawnDomFunction";
  static int _getNewIsolateId() native "Utils_getNewIsolateId";
  static bool shadowRootSupported(Document document) native "Utils_shadowRootSupported";
}

class _NPObject extends NativeFieldWrapperClass1 {
  _NPObject.internal();
  static _NPObject retrieve(String key) native "NPObject_retrieve";
  property(String propertyName) native "NPObject_property";
  invoke(String methodName, [List args = null]) native "NPObject_invoke";
}

class _DOMWindowCrossFrame extends NativeFieldWrapperClass1 implements Window {
  _DOMWindowCrossFrame.internal();

  // Fields.
  History get history native "DOMWindow_history_cross_frame_Getter";
  Location get location native "DOMWindow_location_cross_frame_Getter";
  bool get closed native "DOMWindow_closed_Getter";
  int get length native "DOMWindow_length_Getter";
  Window get opener native "DOMWindow_opener_Getter";
  Window get parent native "DOMWindow_parent_Getter";
  Window get top native "DOMWindow_top_Getter";

  // Methods.
  void close() native "DOMWindow_close_Callback";
  void postMessage(/*SerializedScriptValue*/ message, String targetOrigin, [List messagePorts]) native "DOMWindow_postMessage_Callback";

  // Implementation support.
  String get typeName => "DOMWindow";
}

class _HistoryCrossFrame extends NativeFieldWrapperClass1 implements History {
  _HistoryCrossFrame.internal();

  // Methods.
  void back() native "History_back_Callback";
  void forward() native "History_forward_Callback";
  void go(int distance) native "History_go_Callback";

  // Implementation support.
  String get typeName => "History";
}

class _LocationCrossFrame extends NativeFieldWrapperClass1 implements Location {
  _LocationCrossFrame.internal();

  // Fields.
  void set href(String) native "Location_href_Setter";

  // Implementation support.
  String get typeName => "Location";
}

class _DOMStringMap extends NativeFieldWrapperClass1 implements Map<String, String> {
  _DOMStringMap.internal();

  bool containsValue(String value) => Maps.containsValue(this, value);
  bool containsKey(String key) native "DOMStringMap_containsKey_Callback";
  String operator [](String key) native "DOMStringMap_item_Callback";
  void operator []=(String key, String value) native "DOMStringMap_setItem_Callback";
  String putIfAbsent(String key, String ifAbsent()) => Maps.putIfAbsent(this, key, ifAbsent);
  String remove(String key) native "DOMStringMap_remove_Callback";
  void clear() => Maps.clear(this);
  void forEach(void f(String key, String value)) => Maps.forEach(this, f);
  Collection<String> get keys native "DOMStringMap_getKeys_Callback";
  Collection<String> get values => Maps.getValues(this);
  int get length => Maps.length(this);
  bool get isEmpty => Maps.isEmpty(this);
}

get _printClosure => (s) {
  try {
    window.console.log(s);
  } catch (_) {
    _Utils.print(s);
  }
};
