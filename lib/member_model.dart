import 'dart:convert';

class PlayerModel {
  final String id;
  final String name;
  final int count;
  final bool isChampion;

  PlayerModel({
    required this.id,
    required this.name,
    required this.count,
    required this.isChampion,
  });

  PlayerModel copyWith({
    String? id,
    String? name,
    int? count,
    bool? isChampion,
  }) {
    return PlayerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      count: count ?? this.count,
      isChampion: isChampion ?? this.isChampion,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'count': count,
      'isChampion': isChampion,
    };
  }

  factory PlayerModel.fromMap(Map<String, dynamic> map) {
    return PlayerModel(
      id: map['id'] as String,
      name: map['name'] as String,
      count: map['count'] as int,
      isChampion: map['isChampion'] as bool? ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory PlayerModel.fromJson(String source) =>
      PlayerModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'PlayerModel(id: $id, name: $name, count: $count, isChampion: $isChampion)';
  }

  @override
  bool operator ==(covariant PlayerModel other) {
    if (identical(this, other)) return true;

    return other.id == id &&
        other.name == name &&
        other.count == count &&
        other.isChampion == isChampion;
  }

  @override
  int get hashCode {
    return id.hashCode ^ name.hashCode ^ count.hashCode ^ isChampion.hashCode;
  }
}
