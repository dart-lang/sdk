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
 * @param {string=} named optional
 */ 
function RTT(classkey, typekey, typeargs, returnType, functionType, named) {
  this.classKey = classkey;
  this.typeKey = typekey ? typekey : classkey;
  this.typeArgs = typeargs;
  this.returnType = returnType; // key for the return type
  this.named = named;
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
  if (otherType === this || otherType === RTT.dynamicType.$lookupRTT(null,otherType.named)) {
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
  if (otherType === this || otherType === RTT.dynamicType.$lookupRTT(null,otherType.named)
      || this === RTT.dynamicType.$lookupRTT(null,this.named)) {
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
  if (otherType === this || otherType === RTT.dynamicType.$lookupRTT(null,otherType.named)) {
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
      if (mapped.typeArgs.length < this.typeArgs.length) {
        continue;
      }
      var named = false;
      var x;
      for (x = 0; x < this.typeArgs.length; x++) {
        if (this.typeArgs[x].named || mapped.typeArgs[x].named) {
          named = true;
          break;
        }
        if (!this.typeArgs[x].assignableByType(mapped.typeArgs[x])) {
          continue NEXT_PROPERTY;
        }
      }
      if (!named && x < this.typeArgs.length) {
        continue NEXT_PROPERTY;
      }
      for (; x < this.typeArgs.length; x++) {
        if (!this.typeArgs[x].assignableByType(mapped.typeArgs[x])
            || !(this.typeArgs[x].named === mapped.typeArgs[x].named)) {
          continue NEXT_PROPERTY;
        }
      }
    } else if (mapped.typeArgs || this.typeArgs) {
      continue NEXT_PROPERTY;
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
  return type === RTT.objectType || type === RTT.dynamicType.$lookupRTT(null,type.named);
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
 * @param {string} named optional value
 * @return {RTT} The RTT information object
 */
RTT.create = function(name, implementsSupplier, typeArgs, named) {
  if (name == $cls("Object") && !named) return RTT.objectType;
  var typekey = RTT.getTypeKey(name, typeArgs, null, named);
  var rtt = $mapLookup(RTT.types, typekey);
  if (rtt) {
    return rtt;
  }
  var classkey = RTT.getTypeKey(name);
  rtt = new RTT(classkey, typekey, typeArgs, null, false, named);
  RTT.types[typekey] = rtt;
  if (implementsSupplier) {
    implementsSupplier(rtt, typeArgs);
  }
  return rtt;
};

/**
 * @param {Array.<RTT>=} typeArgs
 * @param {<RTT>=} returnType (if defined)
 * @param {string} named optional value
 * @return {RTT} The RTT information object
 */
RTT.createFunction = function(typeArgs, returnType, named) {
  var name = $cls("Function$Dart");
  var typekey = RTT.getTypeKey(name, typeArgs, returnType, named);
  var rtt = $mapLookup(RTT.types, typekey);
  if (rtt) {
    return rtt;
  }
  var classkey = RTT.getTypeKey(name);
  rtt = new RTT(classkey, typekey, typeArgs, returnType, true, named);
  RTT.types[typekey] = rtt;
  return rtt;
};

/**
 * @param {RTT} old
 * @param {string} named optional
 * @return {RTT} The RTT information object with named
 */
RTT.clone = function(old, named) {
  var name = old.getClassName();
  var typekey = RTT.getTypeKey(name, old.typeArgs, old.returnType, named);
  var rtt = $mapLookup(RTT.types, typekey);
  if (rtt) {
    return rtt;
  }
  var classkey = RTT.getTypeKey(name);
  rtt = new RTT(classkey, typekey, old.typeArgs, old.returnType, old.functionType, named);
  RTT.types[typekey] = rtt;
  rtt.implementedTypes = old.implementedTypes
  return rtt;
};

/**
 * @param {string} classkey
 * @param {Array.<(RTT|string)>=} typeargs
 * @param {string} returntype
 * @param {string=} named optional
 * @return {string}
 */
RTT.getTypeKey = function(classkey, typeargs, returntype, named) {
  var key = classkey;
  if (named) {
    key += ":" + named;
  }
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
 * @param {string=} named optional
 * @return {RTT}
 */
RTT.getTypeArg = function(typeArgs, i, named) {
  if (typeArgs) {
    if (typeArgs.length > i) {
      if (named && named != typeArgs[i].named) {
        return RTT.clone(typeArgs[i], named);
      }
      return typeArgs[i];
    } else {
      throw new Error("Missing type arg");
    }
  } 
  return RTT.dynamicType.$lookupRTT(null,named);
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
function ImplementsAll(name,named) {
  var typeKey = RTT.getTypeKey(name, null, null, named);
  RTT.call(this,name,typeKey,null,null,null,named);
}
$inherits(ImplementsAll,RTT);
ImplementsAll.prototype.implementedBy = function(o) {return true};
ImplementsAll.prototype.implementedByType = function(o) {return true};

RTT.objectType = new ImplementsAll($cls('Object'));
RTT.placeholderType = new ImplementsAll($cls('::'));

function ImplementsDynamic(named) {
  ImplementsAll.call(this,$cls('Dynamic'),named);
}
$inherits(ImplementsDynamic,ImplementsAll);
ImplementsDynamic.prototype.$lookupRTT = function(typeArgs, named) {
  var typekey = RTT.getTypeKey($cls('Dynamic'), null, null, named);
  var rtt = $mapLookup(RTT.types, typekey);
  if (rtt) {
    return rtt;
  }
  rtt = new ImplementsDynamic(named);
  RTT.types[typekey] = rtt;
  return rtt;
}
RTT.dynamicType = ImplementsDynamic.prototype.$lookupRTT();

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
