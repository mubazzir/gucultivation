import 'package:hive/hive.dart';
import '../../models/user_profile.dart';
import '../../models/cultivation_session.dart';
import '../../models/path_model.dart';
import '../../models/gu_worm.dart';
import '../../models/material_item.dart';
import '../../models/task_model.dart';
import '../../models/statistics.dart';

/// Manual Hive TypeAdapters to avoid requiring code generation at first run.

class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final int typeId = 0;

  @override
  UserProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserProfile(
      id: fields[0] as String,
      name: fields[1] as String,
      aptitude: fields[2] as String,
      cultivationRank: fields[3] as int? ?? 1,
      realmStage: fields[4] as int? ?? 0,
      currentEssenceInStage: (fields[5] as num?)?.toDouble() ?? 0,
      totalEssenceEarned: (fields[6] as num?)?.toDouble() ?? 0,
      totalStudySeconds: fields[7] as int? ?? 0,
      createdAt: fields[8] as DateTime,
      lastActiveAt: fields[9] as DateTime,
      currentStreak: fields[10] as int? ?? 0,
      longestStreak: fields[11] as int? ?? 0,
      lastCultivationDate: fields[12] as DateTime?,
      todayStudySeconds: fields[13] as int? ?? 0,
      todayDate: fields[14] as DateTime?,
      selectedPathId: fields[15] as String?,
      primalStones: fields[16] as int? ?? 0,
      secondsTowardNextStone: fields[17] as int? ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.aptitude)
      ..writeByte(3)
      ..write(obj.cultivationRank)
      ..writeByte(4)
      ..write(obj.realmStage)
      ..writeByte(5)
      ..write(obj.currentEssenceInStage)
      ..writeByte(6)
      ..write(obj.totalEssenceEarned)
      ..writeByte(7)
      ..write(obj.totalStudySeconds)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.lastActiveAt)
      ..writeByte(10)
      ..write(obj.currentStreak)
      ..writeByte(11)
      ..write(obj.longestStreak)
      ..writeByte(12)
      ..write(obj.lastCultivationDate)
      ..writeByte(13)
      ..write(obj.todayStudySeconds)
      ..writeByte(14)
      ..write(obj.todayDate)
      ..writeByte(15)
      ..write(obj.selectedPathId)
      ..writeByte(16)
      ..write(obj.primalStones)
      ..writeByte(17)
      ..write(obj.secondsTowardNextStone);
  }
}

class CultivationSessionAdapter extends TypeAdapter<CultivationSession> {
  @override
  final int typeId = 1;

  @override
  CultivationSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CultivationSession(
      isActive: fields[0] as bool? ?? false,
      isPaused: fields[1] as bool? ?? false,
      sessionStart: fields[2] as DateTime?,
      pauseStart: fields[3] as DateTime?,
      accumulatedSeconds: fields[4] as int? ?? 0,
      pathId: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CultivationSession obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.isActive)
      ..writeByte(1)
      ..write(obj.isPaused)
      ..writeByte(2)
      ..write(obj.sessionStart)
      ..writeByte(3)
      ..write(obj.pauseStart)
      ..writeByte(4)
      ..write(obj.accumulatedSeconds)
      ..writeByte(5)
      ..write(obj.pathId);
  }
}

class PathModelAdapter extends TypeAdapter<PathModel> {
  @override
  final int typeId = 2;

  @override
  PathModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PathModel(
      id: fields[0] as String,
      name: fields[1] as String,
      level: fields[2] as int? ?? 0,
      currentXp: (fields[3] as num?)?.toDouble() ?? 0,
      totalStudySeconds: fields[4] as int? ?? 0,
      createdAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, PathModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.level)
      ..writeByte(3)
      ..write(obj.currentXp)
      ..writeByte(4)
      ..write(obj.totalStudySeconds)
      ..writeByte(5)
      ..write(obj.createdAt);
  }
}

class OwnedGuAdapter extends TypeAdapter<OwnedGu> {
  @override
  final int typeId = 3;

  @override
  OwnedGu read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OwnedGu(
      guId: fields[0] as int,
      quantity: fields[1] as int? ?? 1,
      isRefined: fields[2] as bool? ?? false,
      obtainedAt: fields[3] as DateTime,
      masteryLevel: fields[4] as int? ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, OwnedGu obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.guId)
      ..writeByte(1)
      ..write(obj.quantity)
      ..writeByte(2)
      ..write(obj.isRefined)
      ..writeByte(3)
      ..write(obj.obtainedAt)
      ..writeByte(4)
      ..write(obj.masteryLevel);
  }
}

class OwnedMaterialAdapter extends TypeAdapter<OwnedMaterial> {
  @override
  final int typeId = 4;

  @override
  OwnedMaterial read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OwnedMaterial(
      materialId: fields[0] as int,
      quantity: fields[1] as int? ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, OwnedMaterial obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.materialId)
      ..writeByte(1)
      ..write(obj.quantity);
  }
}

class TaskModelAdapter extends TypeAdapter<TaskModel> {
  @override
  final int typeId = 5;

  @override
  TaskModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TaskModel(
      id: fields[0] as String,
      title: fields[1] as String,
      pathId: fields[2] as String?,
      difficulty: fields[3] as String? ?? 'Normal',
      deadline: fields[4] as DateTime?,
      isCompleted: fields[5] as bool? ?? false,
      isDaily: fields[6] as bool? ?? false,
      createdAt: fields[7] as DateTime,
      completedAt: fields[8] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, TaskModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.pathId)
      ..writeByte(3)
      ..write(obj.difficulty)
      ..writeByte(4)
      ..write(obj.deadline)
      ..writeByte(5)
      ..write(obj.isCompleted)
      ..writeByte(6)
      ..write(obj.isDaily)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.completedAt);
  }
}

class StatisticsAdapter extends TypeAdapter<Statistics> {
  @override
  final int typeId = 6;

  @override
  Statistics read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Statistics(
      tasksCompleted: fields[0] as int? ?? 0,
      guObtained: fields[1] as int? ?? 0,
      guRefined: fields[2] as int? ?? 0,
      materialsObtained: fields[3] as int? ?? 0,
      breakthroughs: fields[4] as int? ?? 0,
      eventsTriggered: fields[5] as int? ?? 0,
      totalSessions: fields[6] as int? ?? 0,
      dailyStudySeconds: (fields[7] as Map?)?.cast<String, int>() ?? {},
    );
  }

  @override
  void write(BinaryWriter writer, Statistics obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.tasksCompleted)
      ..writeByte(1)
      ..write(obj.guObtained)
      ..writeByte(2)
      ..write(obj.guRefined)
      ..writeByte(3)
      ..write(obj.materialsObtained)
      ..writeByte(4)
      ..write(obj.breakthroughs)
      ..writeByte(5)
      ..write(obj.eventsTriggered)
      ..writeByte(6)
      ..write(obj.totalSessions)
      ..writeByte(7)
      ..write(obj.dailyStudySeconds);
  }
}

void registerHiveAdapters() {
  Hive.registerAdapter(UserProfileAdapter());
  Hive.registerAdapter(CultivationSessionAdapter());
  Hive.registerAdapter(PathModelAdapter());
  Hive.registerAdapter(OwnedGuAdapter());
  Hive.registerAdapter(OwnedMaterialAdapter());
  Hive.registerAdapter(TaskModelAdapter());
  Hive.registerAdapter(StatisticsAdapter());
}
