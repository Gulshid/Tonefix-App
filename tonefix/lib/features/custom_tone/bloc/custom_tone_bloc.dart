import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tonefix/core/services/custom_tone_service.dart';
import 'package:tonefix/shared/models/tone_models.dart';

// ── Events ────────────────────────────────────────────────────────────────────

abstract class CustomToneEvent extends Equatable {
  const CustomToneEvent();
  @override
  List<Object?> get props => [];
}

class CustomToneLoadEvent extends CustomToneEvent {
  const CustomToneLoadEvent();
}

class CustomToneSaveEvent extends CustomToneEvent {
  const CustomToneSaveEvent(this.profile);
  final CustomToneProfile profile;
  @override
  List<Object?> get props => [profile];
}

class CustomToneDeleteEvent extends CustomToneEvent {
  const CustomToneDeleteEvent(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
}

// ── States ────────────────────────────────────────────────────────────────────

abstract class CustomToneState extends Equatable {
  const CustomToneState();
  @override
  List<Object?> get props => [];
}

class CustomToneInitial extends CustomToneState {}

class CustomToneLoading extends CustomToneState {}

class CustomToneLoaded extends CustomToneState {
  const CustomToneLoaded(this.profiles);
  final List<CustomToneProfile> profiles;
  @override
  List<Object?> get props => [profiles];
}

class CustomToneError extends CustomToneState {
  const CustomToneError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

// ── BLoC ──────────────────────────────────────────────────────────────────────

/// Phase 3 – Task 2: Manages custom tone profiles (CRUD).
class CustomToneBloc extends Bloc<CustomToneEvent, CustomToneState> {
  CustomToneBloc({required CustomToneService customToneService})
      : _service = customToneService,
        super(CustomToneInitial()) {
    on<CustomToneLoadEvent>(_onLoad);
    on<CustomToneSaveEvent>(_onSave);
    on<CustomToneDeleteEvent>(_onDelete);
  }

  final CustomToneService _service;

  Future<void> _onLoad(
    CustomToneLoadEvent event,
    Emitter<CustomToneState> emit,
  ) async {
    emit(CustomToneLoading());
    try {
      final profiles = await _service.loadProfiles();
      emit(CustomToneLoaded(profiles));
    } catch (e) {
      emit(const CustomToneError('Failed to load custom tones'));
    }
  }

  Future<void> _onSave(
    CustomToneSaveEvent event,
    Emitter<CustomToneState> emit,
  ) async {
    try {
      await _service.saveProfile(event.profile);
      add(const CustomToneLoadEvent()); // Refresh list
    } catch (e) {
      emit(const CustomToneError('Failed to save custom tone'));
    }
  }

  Future<void> _onDelete(
    CustomToneDeleteEvent event,
    Emitter<CustomToneState> emit,
  ) async {
    try {
      await _service.deleteProfile(event.id);
      add(const CustomToneLoadEvent());
    } catch (e) {
      emit(const CustomToneError('Failed to delete custom tone'));
    }
  }
}
