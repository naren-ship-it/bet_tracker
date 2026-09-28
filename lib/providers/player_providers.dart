// lib/providers/player_providers.dart

import 'package:flutter/foundation.dart';

import '../models/player.dart';
import '../models/player_choice.dart';
import '../services/player_service.dart';
import 'dart:io';

class PlayerProvider extends ChangeNotifier {
  final PlayerService _service = PlayerService();

  List<Player> _players = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  // ─── CHOICES STATE ─────────────────────────────────────────────────────────
  List<PlayerChoice> _roles = [];
  List<PlayerChoice> _battingStyles = [];
  List<PlayerChoice> _bowlingStyles = [];
  bool _choicesLoaded = false;

  List<Player> get players => _players;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  List<PlayerChoice> get roles => _roles;
  List<PlayerChoice> get battingStyles => _battingStyles;
  List<PlayerChoice> get bowlingStyles => _bowlingStyles;
  bool get choicesLoaded => _choicesLoaded;

  // ─── FETCH LIST ────────────────────────────────────────────────────────────

  Future<void> fetchPlayers() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      _players = await _service.getPlayers();
    } catch (e) {
      _errorMessage = _extractError(e);
    } finally {
      _setLoading(false);
    }
  }

  // ─── FETCH CHOICES ─────────────────────────────────────────────────────────

  Future<void> fetchChoices() async {
    if (_choicesLoaded) return; // only fetch once per session
    try {
      final results = await Future.wait([
        _service.getPlayerRoles(),
        _service.getBattingStyles(),
        _service.getBowlingStyles(),
      ]);
      _roles         = results[0];
      _battingStyles = results[1];
      _bowlingStyles = results[2];
      _choicesLoaded = true;
      notifyListeners();
    } catch (e) {
      _errorMessage = _extractError(e);
      notifyListeners();
    }
  }

  // ─── CREATE ────────────────────────────────────────────────────────────────

  Future<bool> createPlayer(Player player, {File? photo}) async {
    _setSaving(true);
    _errorMessage = null;
    try {
      final created = await _service.createPlayer(player, photo: photo);
      _players = [..._players, created];
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _extractError(e);
      notifyListeners();
      return false;
    } finally {
      _setSaving(false);
    }
  }

  // ─── UPDATE ────────────────────────────────────────────────────────────────
  Future<bool> updatePlayer(int id, Player player, {File? photo}) async {
    _setSaving(true);
    _errorMessage = null;
    try {
      final updated = await _service.updatePlayer(id, player, photo: photo);
      _players = _players.map((p) => p.id == id ? updated : p).toList();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _extractError(e);
      notifyListeners();
      return false;
    } finally {
      _setSaving(false);
    }
  }
  // ─── DELETE ────────────────────────────────────────────────────────────────

  Future<bool> deletePlayer(int id) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _service.deletePlayer(id);
      _players = _players.where((p) => p.id != id).toList();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = _extractError(e);
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── HELPERS ───────────────────────────────────────────────────────────────

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setSaving(bool value) {
    _isSaving = value;
    notifyListeners();
  }

  String _extractError(Object error) =>
      error.toString().replaceFirst('Exception: ', '');
}