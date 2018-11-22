// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if defined(DART_PRECOMPILER)

#include "vm/v8_snapshot_writer.h"

#include "vm/dart.h"
#include "vm/os.h"

namespace dart {

const char* ZoneString(Zone* Z, const char* str) {
  const intptr_t len = strlen(str) + 1;
  char* dest = Z->Alloc<char>(len);
  snprintf(dest, len, "%s", str);
  return dest;
}

V8SnapshotProfileWriter::V8SnapshotProfileWriter(Zone* zone)
    : zone_(zone),
      node_types_(zone_),
      edge_types_(zone_),
      strings_(zone),
      roots_(zone_, 100) {
  node_types_.Insert({"Unknown", kUnknown});
  node_types_.Insert({"ArtificialRoot", kArtificialRoot});

  edge_types_.Insert({"context", kContext});
  edge_types_.Insert({"element", kElement});
  edge_types_.Insert({"property", kProperty});
  edge_types_.Insert({"internal", kInternal});
  edge_types_.Insert({"hidden", kHidden});
  edge_types_.Insert({"shortcut", kShortcut});
  edge_types_.Insert({"weak", kWeak});
  edge_types_.Insert({"extra", kExtra});

  strings_.Insert({"<unknown>", kUnknownString});
  strings_.Insert({"<object>", kObjectString});
  strings_.Insert({"<property>", kPropertyString});
  strings_.Insert({"<artificial root>", kArtificialRootString});
}

void V8SnapshotProfileWriter::SetObjectTypeAndName(ObjectId object_id,
                                                   const char* type,
                                                   const char* name) {
  ASSERT(type != nullptr);
  NodeInfo* info = EnsureId(object_id);

  if (!node_types_.HasKey(type)) {
    node_types_.Insert({ZoneString(zone_, type), node_types_.Size()});
  }

  intptr_t type_id = node_types_.LookupValue(type);
  ASSERT(info->type == kUnknown || info->type == type_id);
  info->type = type_id;

  if (name != nullptr) {
    info->name = EnsureString(name);
  } else {
    info->name = EnsureString(type);
  }
}

void V8SnapshotProfileWriter::AttributeBytesTo(ObjectId object_id,
                                               size_t num_bytes) {
  EnsureId(object_id)->self_size += num_bytes;
}

void V8SnapshotProfileWriter::AttributeReferenceTo(ObjectId object_id,
                                                   ObjectId to_object_id) {
  EnsureId(to_object_id);
  NodeInfo* info = EnsureId(object_id);

#if defined(DEBUG)
  // We should never add a reference twice.
  for (intptr_t i = 0; i < info->edges->length(); ++i) {
    ASSERT(info->edges->At(i).to_node != object_id);
  }
#endif

  info->edges->Add(EdgeInfo{to_object_id});
  ++edge_count_;
}

V8SnapshotProfileWriter::NodeInfo V8SnapshotProfileWriter::DefaultNode(
    ObjectId object_id) {
  return {
      kUnknown,
      kUnknownString,
      object_id,
      0,
      new (zone_) ZoneGrowableArray<EdgeInfo>(zone_, 0),
  };
}

V8SnapshotProfileWriter::NodeInfo V8SnapshotProfileWriter::ArtificialRoot() {
  return {
      kArtificialRoot, kArtificialRootString, {kArtificial, 0}, 0, nullptr, 0,
  };
}

V8SnapshotProfileWriter::NodeInfo* V8SnapshotProfileWriter::EnsureId(
    ObjectId object_id) {
  if (!nodes_.HasKey(object_id)) {
    NodeInfo info = DefaultNode(object_id);
    nodes_.Insert({object_id, info});
  }
  return &nodes_.Lookup(object_id)->value;
}

intptr_t V8SnapshotProfileWriter::EnsureString(const char* str) {
  if (!strings_.HasKey(str)) {
    strings_.Insert({ZoneString(zone_, str), strings_.Size()});
    return strings_.Size() - 1;
  }
  return strings_.LookupValue(str);
}

void V8SnapshotProfileWriter::WriteNodeInfo(JSONWriter* writer,
                                            const NodeInfo& info) {
  writer->PrintValue(info.type);
  writer->PrintValue(info.name);
  writer->PrintValue(NodeIdFor(info.id));
  writer->PrintValue(info.self_size);
  // The artificial root has 'nullptr' edges, it actually points to all the
  // roots.
  writer->PrintValue64(info.edges != nullptr ? info.edges->length()
                                             : roots_.length());
  writer->PrintNewline();
}

void V8SnapshotProfileWriter::WriteEdgeInfo(JSONWriter* writer,
                                            const EdgeInfo& info) {
  writer->PrintValue64(kProperty);  // type, not really used atm
  writer->PrintValue64(
      kPropertyString);  // name_or_index, not really used either
  writer->PrintValue64(nodes_.LookupValue(info.to_node).offset);
  writer->PrintNewline();
}

void V8SnapshotProfileWriter::AddRoot(ObjectId object_id) {
  EnsureId(object_id);
  roots_.Add(object_id);
}

void V8SnapshotProfileWriter::WriteStringsTable(
    JSONWriter* writer,
    const DirectChainedHashMap<StringToIntMapTraits>& map) {
  const char** strings = zone_->Alloc<const char*>(map.Size());
  StringToIntMapTraits::Pair* pair = nullptr;
  auto it = map.GetIterator();
  while ((pair = it.Next()) != nullptr) {
    ASSERT(pair->value >= 0 && pair->value < map.Size());
    strings[pair->value] = pair->key;
  }
  for (intptr_t i = 0; i < map.Size(); ++i) {
    writer->PrintValue(strings[i]);
    writer->PrintNewline();
  }
}

void V8SnapshotProfileWriter::Write(JSONWriter* writer) {
  writer->OpenObject();

  writer->OpenObject("snapshot");
  {
    writer->OpenObject("meta");

    {
      writer->OpenArray("node_fields");
      writer->PrintValue("type");
      writer->PrintValue("name");
      writer->PrintValue("id");
      writer->PrintValue("self_size");
      writer->PrintValue("edge_count");
      writer->CloseArray();
    }

    {
      writer->OpenArray("node_types");
      {
        writer->OpenArray();
        WriteStringsTable(writer, node_types_);
        writer->CloseArray();
      }
      writer->CloseArray();
    }

    {
      writer->OpenArray("edge_fields");
      writer->PrintValue("type");
      writer->PrintValue("name_or_index");
      writer->PrintValue("to_node");
      writer->CloseArray();
    }

    {
      writer->OpenArray("edge_types");
      {
        writer->OpenArray();
        WriteStringsTable(writer, edge_types_);
        writer->CloseArray();
      }
      writer->CloseArray();
    }

    writer->CloseObject();

    writer->PrintProperty64("node_count",
                            nodes_.Size() + 1 /* artificial root */);
    writer->PrintProperty64("edge_count", edge_count_ + roots_.length());
  }
  writer->CloseObject();

  {
    writer->OpenArray("nodes");
    // Write the artificial root node.
    WriteNodeInfo(writer, ArtificialRoot());
    intptr_t offset = kNumNodeFields;
    ObjectIdToNodeInfoTraits::Pair* entry = nullptr;
    auto it = nodes_.GetIterator();
    while ((entry = it.Next()) != nullptr) {
      ASSERT(entry->key == entry->value.id);
      entry->value.offset = offset;
      WriteNodeInfo(writer, entry->value);
      offset += kNumNodeFields;
    }
    writer->CloseArray();
  }

  {
    writer->OpenArray("edges");

    // Write references from the artificial root to the actual roots.
    for (ObjectId root : roots_) {
      WriteEdgeInfo(writer, {root});
    }

    ObjectIdToNodeInfoTraits::Pair* entry = nullptr;
    auto it = nodes_.GetIterator();
    while ((entry = it.Next()) != nullptr) {
      for (intptr_t i = 0; i < entry->value.edges->length(); ++i) {
        WriteEdgeInfo(writer, entry->value.edges->At(i));
      }
    }

    writer->CloseArray();
  }

  {
    writer->OpenArray("strings");
    WriteStringsTable(writer, strings_);
    writer->CloseArray();
  }

  writer->CloseObject();
}

void V8SnapshotProfileWriter::Write(const char* filename) {
  JSONWriter json;
  Write(&json);

  auto file_open = Dart::file_open_callback();
  auto file_write = Dart::file_write_callback();
  auto file_close = Dart::file_close_callback();
  if ((file_open == nullptr) || (file_write == nullptr) ||
      (file_close == nullptr)) {
    OS::PrintErr("Could not access file callbacks to write snapshot profile.");
    return;
  }

  auto file = file_open(filename, /*write=*/true);
  if (file == nullptr) {
    OS::PrintErr("Failed to open file %s\n", filename);
  } else {
    char* output = nullptr;
    intptr_t output_length = 0;
    json.Steal(&output, &output_length);
    file_write(output, output_length, file);
    free(output);
    file_close(file);
  }
}

}  // namespace dart

#endif
