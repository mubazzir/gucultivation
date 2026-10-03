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
    _sessionBox = await Hive.openBox<CultivationSession>(AppConstants.hiveBoxSession);
    _pathBox = await Hive.openBox<PathModel>(AppConstants.hiveBoxPaths);
    _guBox = await Hive.openBox<OwnedGu>(AppConstants.hiveBoxGu);
    _materialBox = await Hive.openBox<OwnedMaterial>(AppConstants.hiveBoxMaterials);
    _taskBox = await Hive.openBox<TaskModel>(AppConstants.hiveBoxTasks);
    _statsBox = await Hive.openBox<Statistics>(AppConstants.hiveBoxStats);
    _settingsBox = await Hive.openBox(AppConstants.hiveBoxSettings);

    await _loadStaticData();
    _initialized = true;
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
    } catch (e) {
      // Fallback empty if assets missing during early development
      guTemplates = [];
      materialTemplates = [];
    }
  }

  // ---------- User Profile ----------
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

    // Seed default paths
    final defaultPaths = [
      PathModel(id: const Uuid().v4(), name: 'Wisdom Path', createdAt: DateTime.now()),
      PathModel(id: const Uuid().v4(), name: 'Strength Path', createdAt: DateTime.now()),
      PathModel(id: const Uuid().v4(), name: 'Refinement Path', createdAt: DateTime.now()),
    ];
    for (final p in defaultPaths) {
      await _pathBox.put(p.id, p);
    }
    profile.selectedPathId = defaultPaths.first.id;
    await saveProfile(profile);

    // Init stats
    await _statsBox.put('main', Statistics());

    // Init empty session
    await _sessionBox.put('current', CultivationSession());

    return profile;
  }

  // ---------- Session ----------
  CultivationSession getSession() {
    return _sessionBox.get('current') ?? CultivationSession();
  }

  Future<void> saveSession(CultivationSession session) async {
    await _sessionBox.put('current', session);
  }

  // ---------- Paths ----------
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

  // ---------- Gu ----------
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

  // ---------- Materials ----------
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
      await _materialBox.add(OwnedMaterial(materialId: materialId, quantity: qty));
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

  // ---------- Tasks ----------
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

  // ---------- Stats ----------
  Statistics getStats() {
    return _statsBox.get('main') ?? Statistics();
  }

  Future<void> saveStats(Statistics stats) async {
    await _statsBox.put('main', stats);
  }

  // ---------- Settings ----------
  T? getSetting<T>(String key, {T? defaultValue}) {
    return _settingsBox.get(key, defaultValue: defaultValue) as T?;
  }

  Future<void> setSetting(String key, dynamic value) async {
    await _settingsBox.put(key, value);
  }

  // ---------- Full wipe (Punishment / Reset) ----------
  Future<void> wipeAllData() async {
    await _userBox.clear();
    await _sessionBox.clear();
    await _pathBox.clear();
    await _guBox.clear();
    await _materialBox.clear();
    await _taskBox.clear();
    await _statsBox.clear();
    // Keep settings except we clear display name related if needed
  }

  // ---------- Backup / Restore ----------
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
      final profile = UserProfile.fromJson(data['profile'] as Map<String, dynamic>);
      await saveProfile(profile);
    }
    if (data['session'] != null) {
      await saveSession(CultivationSession.fromJson(data['session'] as Map<String, dynamic>));
    }
    if (data['paths'] != null) {
      for (final p in data['paths'] as List) {
        final path = PathModel.fromJson(p as Map<String, dynamic>);
        await savePath(path);
      }
    }
    if (data['ownedGu'] != null) {
      for (final g in data['ownedGu'] as List) {
        final gu = OwnedGu.fromJson(g as Map<String, dynamic>);
        await _guBox.add(gu);
      }
    }
    if (data['ownedMaterials'] != null) {
      for (final m in data['ownedMaterials'] as List) {
        final mat = OwnedMaterial.fromJson(m as Map<String, dynamic>);
        await _materialBox.add(mat);
      }
    }
    if (data['tasks'] != null) {
      for (final t in data['tasks'] as List) {
        final task = TaskModel.fromJson(t as Map<String, dynamic>);
        await saveTask(task);
      }
    }
    if (data['statistics'] != null) {
      await saveStats(Statistics.fromJson(data['statistics'] as Map<String, dynamic>));
    }
  }
}
