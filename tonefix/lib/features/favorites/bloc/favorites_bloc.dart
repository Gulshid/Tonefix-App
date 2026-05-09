import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tonefix/core/services/favorites_service.dart';
import 'package:tonefix/shared/models/tone_models.dart';

// ── Events ────────────────────────────────────────────────────────────────────

abstract class FavoritesEvent extends Equatable {
  const FavoritesEvent();
  @override
  List<Object?> get props => [];
}

class FavoritesLoadEvent extends FavoritesEvent {
  const FavoritesLoadEvent({this.category});
  final FavoriteCategory? category;
  @override
  List<Object?> get props => [category];
}

class FavoritesSaveEvent extends FavoritesEvent {
  const FavoritesSaveEvent(this.phrase);
  final FavoritePhrase phrase;
  @override
  List<Object?> get props => [phrase];
}

class FavoritesDeleteEvent extends FavoritesEvent {
  const FavoritesDeleteEvent(this.id);
  final String id;
  @override
  List<Object?> get props => [id];
}

// ── States ────────────────────────────────────────────────────────────────────

abstract class FavoritesState extends Equatable {
  const FavoritesState();
  @override
  List<Object?> get props => [];
}

class FavoritesInitial extends FavoritesState {}

class FavoritesLoading extends FavoritesState {}

class FavoritesLoaded extends FavoritesState {
  const FavoritesLoaded(this.items);
  final List<FavoritePhrase> items;
  @override
  List<Object?> get props => [items];
}

class FavoritesError extends FavoritesState {
  const FavoritesError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

// ── BLoC ──────────────────────────────────────────────────────────────────────

/// Phase 3 – Task 5: Manages favorite phrase templates (CRUD).
class FavoritesBloc extends Bloc<FavoritesEvent, FavoritesState> {
  FavoritesBloc({required FavoritesService favoritesService})
      : _service = favoritesService,
        super(FavoritesInitial()) {
    on<FavoritesLoadEvent>(_onLoad);
    on<FavoritesSaveEvent>(_onSave);
    on<FavoritesDeleteEvent>(_onDelete);
  }

  final FavoritesService _service;

  Future<void> _onLoad(
    FavoritesLoadEvent event,
    Emitter<FavoritesState> emit,
  ) async {
    emit(FavoritesLoading());
    try {
      final items = await _service.loadFavorites(category: event.category);
      emit(FavoritesLoaded(items));
    } catch (e) {
      emit(const FavoritesError('Failed to load favorites'));
    }
  }

  Future<void> _onSave(
    FavoritesSaveEvent event,
    Emitter<FavoritesState> emit,
  ) async {
    try {
      await _service.saveFavorite(event.phrase);
      add(const FavoritesLoadEvent()); // Refresh
    } catch (e) {
      emit(const FavoritesError('Failed to save favorite'));
    }
  }

  Future<void> _onDelete(
    FavoritesDeleteEvent event,
    Emitter<FavoritesState> emit,
  ) async {
    try {
      await _service.deleteFavorite(event.id);
      add(const FavoritesLoadEvent());
    } catch (e) {
      emit(const FavoritesError('Failed to delete favorite'));
    }
  }
}
