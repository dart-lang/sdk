# Dart VM Service Heap Snapshot

A snapshot of a heap in the Dart VM that allows for arbitrary analysis of memory usage.

## Object IDs

An object id is a 1-origin index into SnapshotGraph.objects.

Object id 0 is a sentinel value. It indicates target of a reference has been omitted from the snapshot.

The root object is has object id 1.

This notion of id is unrelated to the id used by the rest of the VM service and cannot, for example, be used as a argument to getObject.

## Class IDs

A class id is a 1-origin index into SnapshotGraph.classes.

Class id 0 is a sentinel value.

This notion of id is unrelated to the id used by the rest of the VM service and cannot, for example, be used as a argument to getObject.

## Graph properties

The graph may contain unreachable objects.

The graph may references without a corresponding SnapshotField.

## Format

```
type SnapshotGraph {
  magic : uint8[8] = "dartheap",

  flags : uleb128,
  name : Utf8String,

  // The sum of shallow sizes of all objects in this graph.
  shallowSize : uleb128,

  // The amount of memory reserved for this heap. At least as large as |shallowSize|.
  capacity : uleb128,

  // The sum of sizes of all external properites in this graph.
  externalSize : uleb128,

  classCount : uleb128,
  classes : SnapshotClass[classCount],

  // At least as big as the sum of SnapshotObject.referenceCount.
  referenceCount : uleb128,
  objectCount : uleb128,
  objects : SnapshotObject[objectCount],

  externalPropertyCount : uleb128,
  externalProperties : SnapshotExternalProperty[externalPropertyCount],
}
```

```
type SnapshotClass {
  // Reserved.
  flags : uleb128,

  // The simple (not qualified) name of the class.
  name : Utf8String,

  // The name of the class's library.
  libraryName : Utf8String,

  // The URI of the class's library.
  libraryUri : Utf8String,

  reserved : Utf8String,

  fieldCount : uleb128,
  fields : SnapshotField[fieldCount],
}
```

```
type SnapshotField {
  // Reserved.
  flags : uleb128,

  // A 0-origin index into SnapshotObject.references.
  index : uleb128,

  name : Utf8String,

  reserved : Utf8String,
}
```

```
type SnapshotObject {
  // A 1-origin index into SnapshotGraph.classes.
  classId : uleb128,

  // The space used by this object in bytes.
  shallowSize : uleb128,

  data : NonReferenceData,

  referenceCount : uleb128,
  // A list of 1-origin indicies into SnapshotGraph.objects
  references : uleb128[referenceCount],
}
```

```
type NonReferenceData {
  tag : uleb128,
}

type NoData extends NonReferenceData {
  tag : uleb128 = 0,
}

type NullData extends NonReferenceData {
  tag : uleb128 = 1,
}

type BoolData extends NonReferenceData {
  tag : uleb128 = 2,
  value : uleb128,
}

type IntegerData extends NonReferenceData {
  tag : uleb128 = 3,
  value : uleb128,
}

type DoubleData extends NonReferenceData {
  tag: uleb128 = 4,
  value: float64,
}

type Latin1StringData extends NonReferenceData {
  tag : uleb128 = 5,
  length : uleb128,
  truncatedLength : uleb128,
  codeUnits : uint8[truncatedLength],
}

type Utf16StringData extends NonReferenceData {
  tag : uleb128 = 6,
  length : uleb128,
  truncatedLength : uleb128,
  codeUnits : uint16[truncatedLength],
}

// Indicates the object is variable length, such as a known implementation
// of List, Map or Set.
type LengthData extends NonReferenceData {
  tag : uleb128 = 7,
  length : uleb128,
}

// Indicates the object has some name, such as Function, Field, Class or Library.
type NameData extends NonReferenceData {
  tag : uleb128 = 7,
  name : Utf8String,
}
```

```
type SnapshotExternalProperty {
  // A 1-origin index into SnapshotGraph.objects.
  object : uleb128,

  externalSize : uleb128,

  name : Utf8String,
}
```

```
type Utf8String {
  length : uleb128,
  codeUnits : uint8[length],
}
```
