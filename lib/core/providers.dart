import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../models/cultivation_session.dart';
import '../models/path_model.dart';
import '../models/gu_worm.dart';
import '../models/material_item.dart';
import '../models/statistics.dart';
import '../services/persistence_service.dart';
import '../services/cultivation_service.dart';
import '../services/gu_service.dart';

final persistenceProvider = Provider<PersistenceService>((ref) {
  return PersistenceService();
});

final cultivationServiceProvider = Provider<CultivationService>((ref) {
  return CultivationService();
});

final guServiceProvider = Provider<GuService>((ref) {
  return GuService();
});

final profileProvider =
StateNotifierProvider<ProfileNotifier, UserProfile?>((ref) {
  return ProfileNotifier(ref.watch(persistenceProvider));
});

class ProfileNotifier extends StateNotifier<UserProfile?> {
  final PersistenceService _db;
  ProfileNotifier(this._db) : super(_db.getProfile());

  void refresh() {
    state = _db.getProfile();
  }

  Future<void> save(UserProfile profile) async {
    await _db.saveProfile(profile);
    state = profile;
  }
}

final sessionProvider =
StateNotifierProvider<SessionNotifier, CultivationSession>((ref) {
  return SessionNotifier(ref.watch(persistenceProvider));
});

class SessionNotifier extends StateNotifier<CultivationSession> {
  final PersistenceService _db;
  SessionNotifier(this._db) : super(_db.getSession());

  void refresh() {
    state = _db.getSession();
  }

  Future<void> save(CultivationSession session) async {
    await _db.saveSession(session);
    state = session;
  }
}

final pathsProvider =
StateNotifierProvider<PathsNotifier, List<PathModel>>((ref) {
  return PathsNotifier(ref.watch(persistenceProvider));
});

class PathsNotifier extends StateNotifier<List<PathModel>> {
  final PersistenceService _db;
  PathsNotifier(this._db) : super(_db.getAllPaths());

  void refresh() {
    state = _db.getAllPaths();
  }

  Future<void> add(String name) async {
    await _db.addPath(name);
    refresh();
  }
}

final guCollectionProvider =
StateNotifierProvider<GuCollectionNotifier, List<OwnedGu>>((ref) {
  return GuCollectionNotifier(ref.watch(persistenceProvider));
});

class GuCollectionNotifier extends StateNotifier<List<OwnedGu>> {
  final PersistenceService _db;
  GuCollectionNotifier(this._db) : super(_db.getOwnedGu());

  void refresh() => state = List<OwnedGu>.from(_db.getOwnedGu());
}

final materialCollectionProvider =
StateNotifierProvider<MaterialCollectionNotifier, List<OwnedMaterial>>(
        (ref) {
      return MaterialCollectionNotifier(ref.watch(persistenceProvider));
    });

class MaterialCollectionNotifier extends StateNotifier<List<OwnedMaterial>> {
  final PersistenceService _db;
  MaterialCollectionNotifier(this._db) : super(_db.getOwnedMaterials());

  void refresh() => state = List<OwnedMaterial>.from(_db.getOwnedMaterials());
}

final statsProvider = Provider<Statistics>((ref) {
  return ref.watch(persistenceProvider).getStats();
});