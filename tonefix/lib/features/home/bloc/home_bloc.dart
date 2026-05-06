// ─── Events ───────────────────────────────────────────────────────────────────
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();
  @override
  List<Object?> get props => [];
}

class HomeInitEvent extends HomeEvent {
  const HomeInitEvent();
}

// ─── States ──────────────────────────────────────────────────────────────────

abstract class HomeState extends Equatable {
  const HomeState();
  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {
  const HomeInitial();
}

class HomeReady extends HomeState {
  const HomeReady();
}

// ─── Bloc ─────────────────────────────────────────────────────────────────────

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(const HomeInitial()) {
    on<HomeInitEvent>(_onInit);
  }

  Future<void> _onInit(HomeInitEvent event, Emitter<HomeState> emit) async {
    // Phase 1: simple ready state; Phase 3+ will load onboarding status etc.
    emit(const HomeReady());
  }
}
