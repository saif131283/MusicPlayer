import 'package:hive_flutter/hive_flutter.dart';

part 'playlist.g.dart';

@HiveType(typeId: 1)
class Playlist extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  List<int> songIds;

  @HiveField(2)
  DateTime createdAt;

  Playlist({
    required this.name,
    required this.songIds,
    required this.createdAt,
  });
}
