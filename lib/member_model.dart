import 'dart:convert';

class PlayerModel {
  final String id;
  final String name;
  final int count;

  PlayerModel({
    required this.id,
    required this.name,
    required this.count,
  });

  PlayerModel copyWith({
    String? id,
    String? name,
    int? count,
  }) {
    return PlayerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      count: count ?? this.count,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'count': count,
    };
  }

  factory PlayerModel.fromMap(Map<String, dynamic> map) {
    return PlayerModel(
      id: map['id'] as String,
      name: map['name'] as String,
      count: map['count'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory PlayerModel.fromJson(String source) =>
      PlayerModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'PlayerModel(id: $id, name: $name, count: $count)';

  @override
  bool operator ==(covariant PlayerModel other) {
    if (identical(this, other)) return true;

    return other.id == id && other.name == name && other.count == count;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ count.hashCode;
}
