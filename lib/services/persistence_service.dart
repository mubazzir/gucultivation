import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';
import '../core/database/hive_adapters.dart';
import '../models/user_profile.dart';
import '../models/cultivation_session.dart';
import '../models/path_model.dart';
import '../models/gu_worm.dart';
import '../models/material_item.dart';
import '../models/task_model.dart';
import '../models/statistics.dart';

class PersistenceService {
  static final PersistenceService _instance = PersistenceService._();
  factory PersistenceService() => _instance;
  PersistenceService._();

  late Box<UserProfile> _userBox;
  late Box<CultivationSession> _sessionBox;
  late Box<PathModel> _pathBox;
  late Box<OwnedGu> _guBox;
  late Box<OwnedMaterial> _materialBox;
  late Box<TaskModel> _taskBox;
  late Box<Statistics> _statsBox;
  late Box _settingsBox;

  List<GuWormTemplate> guTemplates = [];
  List<MaterialTemplate> materialTemplates = [];
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    registerHiveAdapters();

    _userBox = await Hive.openBox<UserProfile>(AppConstants.hiveBoxUser);
    _sessionBox =
    await Hive.openBox<CultivationSession>(AppConstants.hiveBoxSession);
    _pathBox = await Hive.openBox<PathModel>(AppConstants.hiveBoxPaths);
    _guBox = await Hive.openBox<OwnedGu>(AppConstants.hiveBoxGu);
    _materialBox =
    await Hive.openBox<OwnedMaterial>(AppConstants.hiveBoxMaterials);
    _taskBox = await Hive.openBox<TaskModel>(AppConstants.hiveBoxTasks);
    _statsBox = await Hive.openBox<Statistics>(AppConstants.hiveBoxStats);
    _settingsBox = await Hive.openBox(AppConstants.hiveBoxSettings);

    await _loadStaticData();

    if (hasProfile) {
      await ensureHeavenPath();
      await ensureHeavenDayRollover();
    }

    _initialized = true;
  }

  Future<void> deletePath(String id) async {
    await _pathBox.delete(id);
  }

  Future<void> _loadStaticData() async {
    try {
      final guJson = await rootBundle.loadString('assets/data/gu_worms.json');
      final guList = jsonDecode(guJson) as List;
      guTemplates = guList
          .map((e) => GuWormTemplate.fromJson(e as Map<String, dynamic>))
          .toList();

      final matJson = await rootBundle.loadString('assets/data/materials.json');
      final matList = jsonDecode(matJson) as List;
      materialTemplates = matList
          .map((e) => MaterialTemplate.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      guTemplates = [];
      materialTemplates = [];
    }
  }

  bool get hasProfile => _userBox.isNotEmpty;

  UserProfile? getProfile() {
    if (_userBox.isEmpty) return null;
    return _userBox.getAt(0);
  }

  Future<void> saveProfile(UserProfile profile) async {
    profile.lastActiveAt = DateTime.now();
    if (_userBox.isEmpty) {
      await _userBox.add(profile);
    } else {
      await _userBox.putAt(0, profile);
    }
  }

  Future<UserProfile> createProfile(String name, String aptitude) async {
    final profile = UserProfile(
      id: const Uuid().v4(),
      name: name.trim(),
      aptitude: aptitude,
      createdAt: DateTime.now(),
      lastActiveAt: DateTime.now(),
    );
    await saveProfile(profile);

    final defaultPaths = [
      PathModel(
        id: const Uuid().v4(),
        name: 'Wisdom Path',
        createdAt: DateTime.now(),
      ),
      PathModel(
        id: const Uuid().v4(),
        name: 'Strength Path',
        createdAt: DateTime.now(),
      ),
      PathModel(
        id: const Uuid().v4(),
        name: 'Refinement Path',
        createdAt: DateTime.now(),
      ),
      PathModel(
        id: const Uuid().v4(),
        name: AppConstants.heavenPathName,
        createdAt: DateTime.now(),
      ),
    ];
    for (final p in defaultPaths) {
      await _pathBox.put(p.id, p);
    }
    profile.selectedPathId = defaultPaths.first.id;
    await saveProfile(profile);

    await _statsBox.put('main', Statistics());
    await _sessionBox.put('current', CultivationSession());
    await ensureHeavenDayRollover();

    return profile;
  }

  CultivationSession getSession() {
    return _sessionBox.get('current') ?? CultivationSession();
  }

  Future<void> saveSession(CultivationSession session) async {
    await _sessionBox.put('current', session);
  }

  List<PathModel> getAllPaths() => _pathBox.values.toList();

  PathModel? getPath(String id) => _pathBox.get(id);

  Future<void> savePath(PathModel path) async {
    await _pathBox.put(path.id, path);
  }

  Future<PathModel> addPath(String name) async {
    final path = PathModel(
      id: const Uuid().v4(),
      name: name.trim(),
      createdAt: DateTime.now(),
    );
    await savePath(path);
    return path;
  }

  // ----- Heaven Path -----
  static const _kHeavenDate = 'heaven_tasks_date';
  static String _heavenKey(String taskId) => 'heaven_task_$taskId';

  String _todayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  Future<void> ensureHeavenPath() async {
    final exists = _pathBox.values.any((p) => p.isHeavenPath);
    if (!exists) {
      await savePath(PathModel(
        id: const Uuid().v4(),
        name: AppConstants.heavenPathName,
        createdAt: DateTime.now(),
      ));
    }
  }

  PathModel? getHeavenPath() {
    try {
      return _pathBox.values.firstWhere((p) => p.isHeavenPath);
    } catch (_) {
      return null;
    }
  }

  Future<void> ensureHeavenDayRollover() async {
    final today = _todayKey();
    final stored = _settingsBox.get(_kHeavenDate) as String?;

    if (stored == null) {
      await _settingsBox.put(_kHeavenDate, today);
      for (final t in AppConstants.heavenDailyTasks) {
        await _settingsBox.put(_heavenKey(t), false);
      }
      return;
    }

    if (stored == today) return;

    final heaven = getHeavenPath();
    if (heaven != null) {
      var marks = heaven.daoMarks;
      for (final t in AppConstants.heavenDailyTasks) {
        final done =
            _settingsBox.get(_heavenKey(t), defaultValue: false) == true;
        if (!done) {
          marks = (marks - 1).clamp(0, 999999);
        }
      }
      heaven.daoMarks = marks;
      await savePath(heaven);
    }

    await _settingsBox.put(_kHeavenDate, today);
    for (final t in AppConstants.heavenDailyTasks) {
      await _settingsBox.put(_heavenKey(t), false);
    }
  }

  Map<String, bool> getHeavenTaskStatus() {
    final map = <String, bool>{};
    for (final t in AppConstants.heavenDailyTasks) {
      map[t] = _settingsBox.get(_heavenKey(t), defaultValue: false) == true;
    }
    return map;
  }

  Future<bool> completeHeavenTask(String taskId) async {
    await ensureHeavenDayRollover();
    if (!AppConstants.heavenDailyTasks.contains(taskId)) return false;

    final already =
        _settingsBox.get(_heavenKey(taskId), defaultValue: false) == true;
    if (already) return false;

    await _settingsBox.put(_heavenKey(taskId), true);

    final heaven = getHeavenPath();
    if (heaven != null) {
      heaven.daoMarks += 1;
      await savePath(heaven);
    }
    return true;
  }

  // ----- Gu -----
  List<OwnedGu> getOwnedGu() => _guBox.values.toList();

  OwnedGu? getOwnedGuById(int guId) {
    try {
      return _guBox.values.firstWhere((g) => g.guId == guId);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveOwnedGu(OwnedGu gu) async {
    final existing = getOwnedGuById(gu.guId);
    if (existing != null) {
      existing.quantity = gu.quantity;
      existing.isRefined = gu.isRefined;
      existing.masteryLevel = gu.masteryLevel;
      await existing.save();
    } else {
      await _guBox.add(gu);
    }
  }

  Future<void> addGu(int guId, {int qty = 1}) async {
    final existing = getOwnedGuById(guId);
    if (existing != null) {
      existing.quantity += qty;
      await existing.save();
    } else {
      await _guBox.add(OwnedGu(
        guId: guId,
        quantity: qty,
        obtainedAt: DateTime.now(),
      ));
    }
    final stats = getStats();
    stats.guObtained += qty;
    await saveStats(stats);
  }

  GuWormTemplate? getGuTemplate(int id) {
    try {
      return guTemplates.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }

  List<GuWormTemplate> getGuByRank(int rank) =>
      guTemplates.where((g) => g.rank == rank).toList();

  // ----- Materials -----
  List<OwnedMaterial> getOwnedMaterials() => _materialBox.values.toList();

  OwnedMaterial? getOwnedMaterialById(int id) {
    try {
      return _materialBox.values.firstWhere((m) => m.materialId == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> addMaterial(int materialId, int qty) async {
    final existing = getOwnedMaterialById(materialId);
    if (existing != null) {
      existing.quantity += qty;
      await existing.save();
    } else {
      await _materialBox
          .add(OwnedMaterial(materialId: materialId, quantity: qty));
    }
    final stats = getStats();
    stats.materialsObtained += qty;
    await saveStats(stats);
  }

  Future<bool> consumeMaterial(int materialId, int qty) async {
    final existing = getOwnedMaterialById(materialId);
    if (existing == null || existing.quantity < qty) return false;
    existing.quantity -= qty;
    if (existing.quantity <= 0) {
      await existing.delete();
    } else {
      await existing.save();
    }
    return true;
  }

  MaterialTemplate? getMaterialTemplate(int id) {
    try {
      return materialTemplates.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  // ----- Tasks -----
  List<TaskModel> getTasks({bool completed = false}) =>
      _taskBox.values.where((t) => t.isCompleted == completed).toList();

  Future<void> saveTask(TaskModel task) async {
    await _taskBox.put(task.id, task);
  }

  Future<TaskModel> addTask({
    required String title,
    String? pathId,
    String difficulty = 'Normal',
    bool isDaily = false,
    DateTime? deadline,
  }) async {
    final task = TaskModel(
      id: const Uuid().v4(),
      title: title.trim(),
      pathId: pathId,
      difficulty: difficulty,
      isDaily: isDaily,
      deadline: deadline,
      createdAt: DateTime.now(),
    );
    await saveTask(task);
    return task;
  }

  Future<void> completeTask(TaskModel task) async {
    task.isCompleted = true;
    task.completedAt = DateTime.now();
    await saveTask(task);
    final stats = getStats();
    stats.tasksCompleted += 1;
    await saveStats(stats);
  }

  Statistics getStats() => _statsBox.get('main') ?? Statistics();

  Future<void> saveStats(Statistics stats) async {
    await _statsBox.put('main', stats);
  }

  T? getSetting<T>(String key, {T? defaultValue}) {
    return _settingsBox.get(key, defaultValue: defaultValue) as T?;
  }

  Future<void> setSetting(String key, dynamic value) async {
    await _settingsBox.put(key, value);
  }

  Future<void> wipeAllData() async {
    await _userBox.clear();
    await _sessionBox.clear();
    await _pathBox.clear();
    await _guBox.clear();
    await _materialBox.clear();
    await _taskBox.clear();
    await _statsBox.clear();
    await _settingsBox.clear();
  }

  Future<String> exportToJson() async {
    final profile = getProfile();
    final data = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'profile': profile?.toJson(),
      'session': getSession().toJson(),
      'paths': getAllPaths().map((p) => p.toJson()).toList(),
      'ownedGu': getOwnedGu().map((g) => g.toJson()).toList(),
      'ownedMaterials': getOwnedMaterials().map((m) => m.toJson()).toList(),
      'tasks': _taskBox.values.map((t) => t.toJson()).toList(),
      'statistics': getStats().toJson(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Future<void> importFromJson(String jsonStr) async {
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;
    await wipeAllData();

    if (data['profile'] != null) {
      await saveProfile(
          UserProfile.fromJson(data['profile'] as Map<String, dynamic>));
    }
    if (data['session'] != null) {
      await saveSession(CultivationSession.fromJson(
          data['session'] as Map<String, dynamic>));
    }
    if (data['paths'] != null) {
      for (final p in data['paths'] as List) {
        await savePath(PathModel.fromJson(p as Map<String, dynamic>));
      }
    }
    if (data['ownedGu'] != null) {
      for (final g in data['ownedGu'] as List) {
        await _guBox.add(OwnedGu.fromJson(g as Map<String, dynamic>));
      }
    }
    if (data['ownedMaterials'] != null) {
      for (final m in data['ownedMaterials'] as List) {
        await _materialBox
            .add(OwnedMaterial.fromJson(m as Map<String, dynamic>));
      }
    }
    if (data['tasks'] != null) {
      for (final t in data['tasks'] as List) {
        await saveTask(TaskModel.fromJson(t as Map<String, dynamic>));
      }
    }
    if (data['statistics'] != null) {
      await saveStats(
          Statistics.fromJson(data['statistics'] as Map<String, dynamic>));
    }
    await ensureHeavenPath();
  }
}