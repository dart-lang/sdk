// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/v8_snapshot_writer.h"

#include "vm/dart.h"
#include "vm/os.h"

namespace dart {

const V8SnapshotProfileWriter::ObjectId
    V8SnapshotProfileWriter::kArtificialRootId{kArtificial, 0};

#if defined(DART_PRECOMPILER)

static const char* ZoneString(Zone* Z, const char* str) {
  return OS::SCreate(Z, "%s", str);
}

V8SnapshotProfileWriter::V8SnapshotProfileWriter(Zone* zone)
    : zone_(zone),
      node_types_(zone_),
      edge_types_(zone_),
      strings_(zone_),
      roots_(zone_) {
  node_types_.Insert({"Unknown", kUnknown});
  node_types_.Insert({"ArtificialRoot", kArtificialRoot});

  edge_types_.Insert({"context", kContext});
  edge_types_.Insert({"element", kElement});
  edge_types_.Insert({"property", kProperty});
  edge_types_.Insert({"internal", kInternal});

  strings_.Insert({"<unknown>", kUnknownString});
  strings_.Insert({"<artificial root>", kArtificialRootString});

  nodes_.Insert(NodeInfo(zone_, kArtificialRoot, kArtificialRootString,
                         kArtificialRootId, 0, 0));
}

void V8SnapshotProfileWriter::SetObjectTypeAndName(ObjectId object_id,
                                                   const char* type,
                                                   const char* name) {
  ASSERT(type != nullptr);

  if (!node_types_.HasKey(type)) {
    node_types_.Insert({ZoneString(zone_, type), node_types_.Size()});
  }

  intptr_t type_id = node_types_.LookupValue(type);
  NodeInfo* info = EnsureId(object_id);
  ASSERT(info->type == kUnknown || info->type == type_id);
  info->type = type_id;
  if (name != nullptr) {
    info->name = EnsureString(name);
  } else {
    info->name =
        EnsureString(OS::SCreate(zone_, "Unnamed [%s] %s", type, "(nil)"));
  }
}

void V8SnapshotProfileWriter::AttributeBytesTo(ObjectId object_id,
                                               size_t num_bytes) {
  EnsureId(object_id)->self_size += num_bytes;
}

V8SnapshotProfileWriter::ConstantEdgeType
V8SnapshotProfileWriter::ReferenceTypeToEdgeType(Reference::Type type) {
  switch (type) {
    case Reference::kElement:
      return ConstantEdgeType::kElement;
    case Reference::kProperty:
      return ConstantEdgeType::kProperty;
  }
}

void V8SnapshotProfileWriter::AttributeReferenceTo(ObjectId from_object_id,
                                                   Reference reference,
                                                   ObjectId to_object_id) {
  const bool is_element = reference.reference_type == Reference::kElement;
  ASSERT(is_element ? reference.offset >= 0 : reference.name != nullptr);

  EnsureId(to_object_id);
  const Edge edge(ReferenceTypeToEdgeType(reference.reference_type),
                  is_element ? reference.offset : EnsureString(reference.name));
  EnsureId(from_object_id)->AddEdge(edge, to_object_id);
  ++edge_count_;
}

void V8SnapshotProfileWriter::AttributeDroppedReferenceTo(
    ObjectId from_object_id,
    Reference reference,
    ObjectId to_object_id,
    ObjectId replacement_object_id) {
  ASSERT(to_object_id.first == kArtificial);
  ASSERT(replacement_object_id.first != kArtificial);

  const bool is_element = reference.reference_type == Reference::kElement;
  ASSERT(is_element ? reference.offset >= 0 : reference.name != nullptr);

  // The target node is added normally.
  AttributeReferenceTo(from_object_id, reference, to_object_id);

  // Put the replacement node at an invalid offset or name that can still be
  // associated with the real one. For offsets, this is the negative offset.
  // For names, it's the name prefixed with ":replacement_".
  EnsureId(replacement_object_id);
  const Edge replacement_edge(
      ReferenceTypeToEdgeType(reference.reference_type),
      is_element ? -reference.offset
                 : EnsureString(
                       OS::SCreate(zone_, ":replacement_%s", reference.name)));
  EnsureId(from_object_id)->AddEdge(replacement_edge, replacement_object_id);
  ++edge_count_;
}

bool V8SnapshotProfileWriter::HasId(const ObjectId& object_id) {
  return nodes_.HasKey(object_id);
}

V8SnapshotProfileWriter::NodeInfo* V8SnapshotProfileWriter::EnsureId(
    ObjectId object_id) {
  if (!HasId(object_id)) {
    nodes_.Insert(NodeInfo(zone_, kUnknown, kUnknownString, object_id, 0, -1));
  }
  return nodes_.Lookup(object_id);
}

intptr_t V8SnapshotProfileWriter::EnsureString(const char* str) {
  if (!strings_.HasKey(str)) {
    strings_.Insert({ZoneString(zone_, str), strings_.Size()});
    return strings_.Size() - 1;
  }
  return strings_.LookupValue(str);
}

intptr_t V8SnapshotProfileWriter::WriteNodeInfo(JSONWriter* writer,
                                                const NodeInfo& info) {
  writer->PrintValue(info.type);
  writer->PrintValue(info.name);
  writer->PrintValue(NodeIdFor(info.id));
  writer->PrintValue(info.self_size);
  writer->PrintValue64(info.edges->Length());
  writer->PrintNewline();
  return kNumNodeFields;
}

void V8SnapshotProfileWriter::WriteEdgeInfo(JSONWriter* writer,
                                            const Edge& info,
                                            const ObjectId& target) {
  writer->PrintValue64(info.first);
  writer->PrintValue64(info.second);
  writer->PrintValue64(nodes_.LookupValue(target).offset);
  writer->PrintNewline();
}

void V8SnapshotProfileWriter::AddRoot(ObjectId object_id,
                                      const char* name /*= nullptr*/) {
  EnsureId(object_id);
  // HeapSnapshotWorker.HeapSnapshot.calculateDistances (from HeapSnapshot.js)
  // assumes that the root does not have more than one edge to any other node
  // (most likely an oversight).
  if (roots_.HasKey(object_id)) return;

  auto const info = NodeInfo(
      zone_, 0, name != nullptr ? EnsureString(name) : -1, object_id, 0, 0);
  roots_.Insert(info);
  auto const root = EnsureId(kArtificialRootId);
  root->AddEdge(info.name != -1 ? Edge(kProperty, info.name)
                                : Edge(kInternal, root->edges->Length()),
                object_id);
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

    writer->PrintProperty64("node_count", nodes_.Size());
    writer->PrintProperty64("edge_count", edge_count_ + roots_.Size());
  }
  writer->CloseObject();

  const auto& root = *nodes_.Lookup(kArtificialRootId);
  auto nodes_it = nodes_.GetIterator();

  {
    writer->OpenArray("nodes");
    //  Always write the information for the artificial root first.
    intptr_t offset = WriteNodeInfo(writer, root);
    for (auto entry = nodes_it.Next(); entry != nullptr;
         entry = nodes_it.Next()) {
      if (entry->id == kArtificialRootId) continue;
      entry->offset = offset;
      offset += WriteNodeInfo(writer, *entry);
    }
    writer->CloseArray();
    nodes_it.Reset();
  }

  {
    auto write_edges = [&](const NodeInfo& info) {
      auto edges_it = info.edges->GetIterator();
      while (auto const pair = edges_it.Next()) {
        WriteEdgeInfo(writer, pair->edge, pair->target);
      }
    };
    writer->OpenArray("edges");
    //  Always write the information for the artificial root first.
    write_edges(root);
    while (auto const entry = nodes_it.Next()) {
      if (entry->id == kArtificialRootId) continue;
      write_edges(*entry);
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

#endif

}  // namespace dart
