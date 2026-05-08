import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tonefix/features/home/bloc/home_event.dart';

class HomeState {}
class HomeInitial extends HomeState {}

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(HomeInitial()) {
    on<HomeInitEvent>((event, emit) => emit(HomeInitial()));
  }
}
