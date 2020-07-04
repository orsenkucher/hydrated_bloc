import 'package:hydrated_bloc/hydrated_bloc.dart';

class TestBloc extends HydratedBloc<dynamic, Map<String, int>> {
  TestBloc() : super(<String, int>{'Initial empty map': 0});

  @override
  Stream<Map<String, int>> mapEventToState(dynamic event) async* {
    final now = DateTime.now();
    yield <String, int>{
      'Today is': now.day,
      'Hour': now.hour,
      'Minute': now.minute,
      'Second': now.second,
    };
  }

  @override
  Map<String, dynamic> toJson(Map<String, int> state) => state;

  @override
  Map<String, int> fromJson(Map<String, dynamic> json) =>
      json.cast<String, int>();
}
