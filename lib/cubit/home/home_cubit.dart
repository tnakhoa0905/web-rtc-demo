import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_call_flutter/cubit/home/home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(const HomeInitial());
  List<int> listInt = [1, 2, 3, 4, 5, 6, 7, 8, 9];
  Future<void> getList() async {
    emit(const HomeInitial());
    Future.delayed(const Duration(seconds: 2), () {
      emit(HomeLoaded(listInt));
    });
  }
}
