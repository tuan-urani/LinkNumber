import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flow_connection/src/enums/bottom_navigation_page.dart';
import 'package:flow_connection/src/ui/main/bloc/main_event.dart';
import 'package:flow_connection/src/ui/main/bloc/main_state.dart';

class MainBloc extends Bloc<MainEvent, MainState> {
  final List<GlobalKey<NavigatorState>> tabNavKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  MainBloc() : super(const MainState()) {
    on<MainInitialized>(_onInitialized);
    on<OnChangeTabEvent>(_onChangeTab);
  }

  void _onInitialized(MainInitialized event, Emitter<MainState> emit) {
    emit(state.copyWith(currentPage: BottomNavigationPage.home));
  }

  void _onChangeTab(OnChangeTabEvent event, Emitter<MainState> emit) {
    emit(state.copyWith(currentPage: event.page));
  }
}
