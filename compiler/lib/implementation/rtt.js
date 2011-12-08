// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The following methods are used to handle type information
//

/** 
 * @constructor
 * @param {string} classkey
 * @param {string=} typekey
 * @param {Array.<RTT>=} typeargs
 * @param {RTT} returnType
 * @param {bool} functionType
 */ 
function RTT(classkey, typekey, typeargs, returnType, functionType) {
  this.classKey = classkey;
  this.typeKey = typekey ? typekey : classkey;
  this.typeArgs = typeargs;
  this.returnType = returnType; // key for the return type
  this.implementedTypes = {};
  this.functionType = functionType;
  // Add self
  this.implementedTypes[classkey] = this;
  // Add Object
  if (!functionType && classkey != $cls('Object')) {
    this.implementedTypes[$cls('Object')] = RTT.objectType;
  }
}

/** @type {Object.<string, Object>} */
RTT.types = {};

/** @type {Array.<RTT>} */
RTT.prototype.derivedTypes = [];

/** @return {string} */
RTT.prototype.toString = function() { return this.typeKey; }

/**
 * @param {*} value 
 * @return {boolean} Whether this type is implemented by the value
 */
RTT.prototype.implementedBy = function(value){ 
  return (value == null) ? RTT.nullInstanceOf(this) :
      this.functionType ? this.implementedByTypeFunc(value) :
      this.implementedByType(RTT.getTypeInfo(value)); 
};

/** 
 * A helper function for safely looking up a value
 * in a Object used as a map.
 * @param {Object.<*>} map
 * @param {srting} key
 * @return {*} the value or null;
 */
function $mapLookup(map, key) {
  return map.hasOwnProperty(key) ? map[key] : null;
}

RTT.prototype.implementedByTypeSwitch = function(value){
  return this.functionType ? this.implementedByTypeFunc(value) :
      this.implementedByType(value);
};

/**
 * @param {!RTT} other
 * @return {boolean} Whether this type is implement by other
 */
RTT.prototype.implementedByType = function(otherType) { 
  if (otherType === this || otherType === RTT.dynamicType) {
    return true;
  }
  var targetTypeInfo = $mapLookup(otherType.implementedTypes, this.classKey);
  if (targetTypeInfo == null) { 
    return false; 
  }
  if (targetTypeInfo.typeArgs && this.typeArgs) {
    for(var i = this.typeArgs.length - 1; i >= 0; i--) {
      if (!this.typeArgs[i].implementedByTypeSwitch(targetTypeInfo.typeArgs[i])) {
        return false;
      }
    }
  }
  return true;
};

/**
 * @param {!RTT} other
 * @return {boolean} Whether this type is assignable by other
 */
RTT.prototype.assignableByType = function(otherType) {
  if (otherType === this || otherType === RTT.dynamicType || this === RTT.dynamicType) {
    return true;
  }
  var targetTypeInfo = $mapLookup(otherType.implementedTypes, this.classKey);
  if (targetTypeInfo == null) {
    targetTypeInfo = $mapLookup(this.implementedTypes, otherType.classKey);
    if (targetTypeInfo == null) {
      return false;
    }
  }
  if (targetTypeInfo.typeArgs && this.typeArgs) {
    for(var i = this.typeArgs.length - 1; i >= 0; i--) {
      if (!this.typeArgs[i].assignableByType(targetTypeInfo.typeArgs[i])) {
        return false;
      }
    }
  }
  return true;
};


/**
 * @param {!RTT} other
 * @return {boolean} Whether this type is implemented by other
 */
RTT.prototype.implementedByTypeFunc = function(otherType) {
  if (otherType.$lookupRTT) {
    otherType = otherType.$lookupRTT();
  } else if (!(otherType instanceof RTT)) {
    return false;
  }
  if (otherType === this || otherType === RTT.dynamicType) {
    return true;
  }
  var props = Object.getOwnPropertyNames(otherType.implementedTypes);
  NEXT_PROPERTY: for (var i = 0 ; i < props.length; i++) {
    var mapped = otherType.implementedTypes[props[i]];
    if (mapped.returnType && this.returnType &&
        !this.returnType.assignableByType(mapped.returnType)) {
      continue;
    }
    if (mapped.typeArgs && this.typeArgs) {
      if (this.typeArgs.length != mapped.typeArgs.length) {
        continue;
      }
      for (var x = this.typeArgs.length - 1; x >= 0; x--) {
        if (!this.typeArgs[x].assignableByType(mapped.typeArgs[x])) {
          continue NEXT_PROPERTY;
        }
      }
    } else if (mapped.typeArgs || this.typeArgs) {
      return false;
    }
    return true;
  }
  return false;
};

/**
 * @return {string} the class name associated with this type
 */
RTT.prototype.getClassName = function() {
  var name = this.classKey;
  if (name.substr(0, 4) == "cls:") {
    name = name.substr(4);
  }
  if (name.substr(-5) == "$Dart") {
    name = name.substr(0, name.length - 5);
  }
  return name;
}

/** 
 * @param {RTT}
 * @return {boolean} 
 */
RTT.nullInstanceOf = function(type) {
  return type === RTT.objectType || type === RTT.dynamicType;
};

/**
 * @param {*} value The value to retrieve type information for
 * @return {RTT} 
 */
RTT.getNativeTypeInfo = function(value) {
  if (value instanceof Array) return Array.$lookupRTT();
  switch (typeof value) {
    case 'string': return String.$lookupRTT();
    case 'number': return Number.$lookupRTT();
    case 'boolean': return Boolean.$lookupRTT();
  } 
  return RTT.placeholderType;
};

/**
 * @param {string} name
 * @param {function(RTT,Array.<RTT>)=} implementsSupplier 
 * @param {Array.<RTT>=} typeArgs
 * @return {RTT} The RTT information object
 */
RTT.create = function(name, implementsSupplier, typeArgs) {
  if (name == $cls("Object")) return RTT.objectType;
  var typekey = RTT.getTypeKey(name, typeArgs);
  var rtt = $mapLookup(RTT.types, typekey);
  if (rtt) {
    return rtt;
  }
  var classkey = RTT.getTypeKey(name);
  rtt = new RTT(classkey, typekey, typeArgs);
  RTT.types[typekey] = rtt;
  if (implementsSupplier) {
    implementsSupplier(rtt, typeArgs);
  }
  return rtt;
};

/**
 * @param {Array.<RTT>=} typeArgs
 * @param {<RTT>=} returnType (if defined)
 * @return {RTT} The RTT information object
 */
RTT.createFunction = function(typeArgs, returnType) {
  var name = $cls("Function");
  var typekey = RTT.getTypeKey(name, typeArgs, returnType);
  var rtt = $mapLookup(RTT.types, typekey);
  if (rtt) {
    return rtt;
  }
  var classkey = RTT.getTypeKey(name);
  rtt = new RTT(classkey, typekey, typeArgs, returnType, true);
  RTT.types[typekey] = rtt;
  return rtt;
};

/**
 * @param {string} classkey
 * @param {Array.<(RTT|string)>=} typeargs
 * @param {string} returntype
 * @return {string}
 */
RTT.getTypeKey = function(classkey, typeargs, returntype) {
  var key = classkey;
  if (typeargs) {
    key += "<" + typeargs.join(",") + ">";
  }
  if (returntype) {
    key += "-><" + returntype + ">";
  }
  return key;
};

/**
 * @return {*} value
 * @return {RTT} return the RTT information object for the value
 */
RTT.getTypeInfo = function(value) {
  return (value.$typeInfo) ? value.$typeInfo : RTT.getNativeTypeInfo(value);
};

/**
 * @param {Object} o
 * @param {RTT} rtt
 * Sets the RTT on the object and returns the object itself.
 */
RTT.setTypeInfo = function(o, rtt) {
  o.$typeInfo = rtt;
  return o;
};

/**
 * @param {Object} o
 * Removes any RTT from the object and returns the object itself.
 */
RTT.removeTypeInfo = function(o) {
  o.$typeInfo = null;
  return o;
};

/**
 * The typeArg array is optional
 * @param {Array.<RTT>=} typeArgs
 * @param {number} i
 * @return {RTT}
 */
RTT.getTypeArg = function(typeArgs, i) {
  if (typeArgs) {
    if (typeArgs.length > i) {
      return typeArgs[i];
    } else {
      throw new Error("Missing type arg");
    }
  } 
  return RTT.dynamicType; 
};

/**
 * The typeArg array is optional
 * @param {*} o
 * @param {string} classkey
 * @return {Array.<RTT>}
 */
RTT.getTypeArgsFor = function(o, classkey) {
  var rtt = $mapLookup(RTT.getTypeInfo(o).implementedTypes, classkey);
  if (!rtt) {
    throw new Error("internal error: can not find " +
        classkey + " in " + JSON.stringify(o));
  }
  return rtt.typeArgs;
};

// Base types for runtime type information

/** @type {!RTT} */
function ImplementsAll(name) {
  RTT.call(this,name);
}
$inherits(ImplementsAll,RTT);
ImplementsAll.prototype.implementedBy = function(o) {return true};
ImplementsAll.prototype.implementedByType = function(o) {return true};

RTT.objectType = new ImplementsAll($cls('Object'));
RTT.dynamicType = new ImplementsAll($cls('Dynamic')); 
RTT.placeholderType = new ImplementsAll($cls('::'));

/**
 * Checks that a value is assignable to an expected type, and either returns that
 * value if it is, or else throws a TypeMismatchException.
 *
 * @param {!RTT} the expected type
 * @param {*} the value to check
 * @return {*} the value
 */
function $chk(rtt, value) {
  // null can be assigned to any type
  if (value == $Dart$Null || rtt.implementedBy(value)) {
    return value;
  }
  $te(rtt, value);
}

/**
 * Throw a TypeError.  See core.dart for the ExceptionHelper class.
 *
 * @param {!RTT} the expected type
 * @param {*) the value that failed
 */
function $te(rtt, value) {
  var srcType = RTT.getTypeInfo(value).getClassName();
  var dstType = rtt.getClassName();
  var e = native_ExceptionHelper_createTypeError(srcType, dstType);
  $Dart$ThrowException(e);
}

// Setup the Function object
Function.prototype.$implements$Function$Dart = 1;
RTT.setTypeInfo(Function.prototype, RTT.create($cls('Function$Dart')));

/** 
 * @param {string} cls 
 * @return {string}
 * @consistentIdGenerator 
 */
function $cls(cls) {
  return "cls:" + cls;
}

/**
 * @param {*} o
 * @return {boolean}
 */
function $isBool(o) {
  return typeof o == 'boolean';
}

/**
 * @param {*} o
 * @return {boolean}
 */
function $isNum(o) {
  return typeof o == 'number';
}

/**
 * @param {*} o
 * @return {boolean}
 */
function $isString(o) {
  return typeof o == 'string';
}
