// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Utils {
  static List convertToList(List list) {
    // FIXME: [possible optimization]: do not copy the array if Dart_IsArray is fine w/ it.
    final length = list.length;
    List result = new List(length);
    result.copyFrom(list, 0, 0, length);
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

  static makeNotImplementedException(String fileName, int lineNo) {
    return new UnsupportedOperationException('[info: $fileName:$lineNo]');
  }

  static window() native "Utils_window";
  static print(String message) native "Utils_print";
  static SendPort spawnDomIsolate(Window window, String entryPoint) native "Utils_spawnDomIsolate";
}

/*
 * [NPObjectBase] is native wrapper class injected from embedder's code.
 */
class NPObject extends DOMWrapperBase {
  static NPObject retrieve(String key) native "NPObject_retrieve";
  property(String propertyName) native "NPObject_property";
  invoke(String methodName, [ObjectArray args = null]) native "NPObject_invoke";

  static _createNPObject() => new NPObject._createNPObject();
  NPObject._createNPObject();
}

class DOMWindowCrossFrameImplementation extends DOMWrapperBase implements DOMWindow {
  // Fields.
  History get history() native "DOMWindow_history_cross_frame_Getter";
  Location get location() native "DOMWindow_location_cross_frame_Getter";
  bool get closed() native "DOMWindow_closed_Getter";
  int get length() native "DOMWindow_length_Getter";
  DOMWindow get opener() native "DOMWindow_opener_Getter";
  DOMWindow get parent() native "DOMWindow_parent_Getter";
  DOMWindow get top() native "DOMWindow_top_Getter";

  // Methods.
  void focus() native "DOMWindow_focus_Callback";
  void blur() native "DOMWindow_blur_Callback";
  void close() native "DOMWindow_close_Callback";
  void postMessage(/*SerializedScriptValue*/ message, String targetOrigin, [List messagePorts]) native "DOMWindow_postMessage_Callback";

  // Implementation support.
  static DOMWindowCrossFrameImplementation _createDOMWindowCrossFrameImplementation() => new DOMWindowCrossFrameImplementation._createDOMWindowCrossFrameImplementation();
  DOMWindowCrossFrameImplementation._createDOMWindowCrossFrameImplementation();

  String get typeName() => "DOMWindow";
}

class HistoryCrossFrameImplementation extends DOMWrapperBase implements History {
  // Methods.
  void back() native "History_back_Callback";
  void forward() native "History_forward_Callback";
  void go(int distance) native "History_go_Callback";

  // Implementation support.
  static HistoryCrossFrameImplementation _createHistoryCrossFrameImplementation() => new HistoryCrossFrameImplementation._createHistoryCrossFrameImplementation();
  HistoryCrossFrameImplementation._createHistoryCrossFrameImplementation();

  String get typeName() => "History";
}

class LocationCrossFrameImplementation extends DOMWrapperBase implements Location {
  // Fields.
  void set href(String) native "Location_href_Setter";

  // Implementation support.
  static LocationCrossFrameImplementation _createLocationCrossFrameImplementation() => new LocationCrossFrameImplementation._createLocationCrossFrameImplementation();
  LocationCrossFrameImplementation._createLocationCrossFrameImplementation();

  String get typeName() => "Location";
}

class DOMStringMapImplementation extends DOMWrapperBase implements DOMStringMap {
  static DOMStringMapImplementation _createDOMStringMapImplementation() => new DOMStringMapImplementation._createDOMStringMapImplementation();
  DOMStringMapImplementation._createDOMStringMapImplementation();

  bool containsValue(String value) => Maps.containsValue(this, value);
  bool containsKey(String key) native "DOMStringMap_containsKey_Callback";
  String operator [](String key) native "DOMStringMap_item_Callback";
  void operator []=(String key, String value) native "DOMStringMap_setItem_Callback";
  String putIfAbsent(String key, String ifAbsent()) => Maps.putIfAbsent(this, key, ifAbsent);
  String remove(String key) native "DOMStringMap_remove_Callback";
  void clear() => Maps.clear(this);
  void forEach(void f(String key, String value)) => Maps.forEach(this, f);
  Collection<String> getKeys() native "DOMStringMap_getKeys_Callback";
  Collection<String> getValues() => Maps.getValues(this);
  int get length() => Maps.length(this);
  bool isEmpty() => Maps.isEmpty(this);
}
