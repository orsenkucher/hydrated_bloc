import 'dart:async';
import 'dart:convert';

import 'package:hydrated_cubit/hydrated_cubit.dart';
import 'package:meta/meta.dart';
import 'package:bloc/bloc.dart';

/// {@template hydrated_bloc}
/// Specialized [Bloc] which handles initializing the [Bloc] state
/// based on the persisted state. This allows state to be persisted
/// across hot restarts as well as complete app restarts.
/// {@endtemplate}
abstract class HydratedBloc<Event, State> extends Bloc<Event, State> {
  /// {@macro hydrated_bloc}
  HydratedBloc(State state) : super(state) {
    final stateJson = toJson(this.state);
    if (stateJson != null) {
      try {
        storage.write(storageToken, stateJson);
      } on dynamic catch (error, stackTrace) {
        onError(error, stackTrace);
      }
    }
  }

  /// Instance of [Storage] which will be used to
  /// manage persisting/restoring the [Bloc] state.
  static Storage storage;

  State _state;

  @override
  State get state {
    if (_state != null) return _state;
    try {
      final stateJson = storage.read(storageToken);
      // json.encode(value)
      if (stateJson == null) return _state = super.state;
      // return _state = fromJson(Map<String, dynamic>.from(stateJson));
      return _state = fromJson(_traverse(stateJson));
    } on dynamic catch (error, stackTrace) {
      onError(error, stackTrace);
      return _state = super.state;
    }
  }

  //   void writeObject(object) {
  //   // Tries stringifying object directly. If it's not a simple value, List or
  //   // Map, call toJson() to get a custom representation and try serializing
  //   // that.
  //   if (writeJsonValue(object)) return;
  //   _checkCycle(object);
  //   try {
  //     var customJson = _toEncodable(object);
  //     if (!writeJsonValue(customJson)) {
  //       throw JsonUnsupportedObjectError(object, partialResult: _partialResult);
  //     }
  //     _removeSeen(object);
  //   } catch (e) {
  //     throw JsonUnsupportedObjectError(object,
  //         cause: e, partialResult: _partialResult);
  //   }
  // }

//   bool writeJsonValue(object) {
//   if (object is num) {
//     if (!object.isFinite) return false;
//     writeNumber(object);
//     return true;
//   } else if (identical(object, true)) {
//     writeString('true');
//     return true;
//   } else if (identical(object, false)) {
//     writeString('false');
//     return true;
//   } else if (object == null) {
//     writeString('null');
//     return true;
//   } else if (object is String) {
//     writeString('"');
//     writeStringContent(object);
//     writeString('"');
//     return true;
//   } else if (object is List) {
//     _checkCycle(object);
//     writeList(object);
//     _removeSeen(object);
//     return true;
//   } else if (object is Map) {
//     _checkCycle(object);
//     // writeMap can fail if keys are not all strings.
//     var success = writeMap(object);
//     _removeSeen(object);
//     return success;
//   } else {
//     return false;
//   }
// }

  // /// List of objects currently being traversed. Used to detect cycles.
  // final List _seen = [];

  // /// Check if an encountered object is already being traversed.
  // ///
  // /// Records the object if it isn't already seen. Should have a matching call to
  // /// [_removeSeen] when the object is no longer being traversed.
  // void _checkCycle(object) {
  //   for (var i = 0; i < _seen.length; i++) {
  //     if (identical(object, _seen[i])) {
  //       throw JsonCyclicError(object);
  //     }
  //   }
  //   _seen.add(object);
  // }

  // /// Remove [object] from the list of currently traversed objects.
  // ///
  // /// Should be called in the opposite order of the matching [_checkCycle]
  // /// calls.
  // void _removeSeen(object) {
  //   assert(_seen.isNotEmpty);
  //   assert(identical(_seen.last, object));
  //   _seen.removeLast();
  // }

  // bool _check(object) {
  //   if (object is num) {
  //     if (!object.isFinite) return false;
  //     return true;
  //   } else if (identical(object, true)) {
  //     return true;
  //   } else if (identical(object, false)) {
  //     return true;
  //   } else if (object == null) {
  //     return true;
  //   } else if (object is String) {
  //     return true;
  //   } else if (object is List) {
  //     return true;
  //   } else if (object is Map) {
  //     return true;
  //   } else {
  //     return false;
  //   }
  // }

  dynamic _traverse(dynamic value) {
    if (value is Map) {
      final map = <String, dynamic>{};
      value.forEach((key, value) {
        map[key] = _traverse(value);
      });
      return map;
    }
    if (value is List) {
      final list = <dynamic>[];
      for (var item in value) {
        list.add(_traverse(item));
      }
      return list;
    }
    return value;
  }

  @override
  void onTransition(Transition<Event, State> transition) {
    final state = transition.nextState;
    final stateJson = toJson(state);
    if (stateJson != null) {
      try {
        storage.write(storageToken, stateJson);
      } on dynamic catch (error, stackTrace) {
        onError(error, stackTrace);
      }
    }
    _state = state;
    super.onTransition(transition);
  }

  /// `id` is used to uniquely identify multiple instances
  /// of the same `HydratedBloc` type.
  /// In most cases it is not necessary;
  /// however, if you wish to intentionally have multiple instances
  /// of the same `HydratedBloc`, then you must override `id`
  /// and return a unique identifier for each `HydratedBloc` instance
  /// in order to keep the caches independent of each other.
  String get id => '';

  /// `storageToken` is used as registration token for hydrated storage.
  @nonVirtual
  String get storageToken => '${runtimeType.toString()}${id ?? ''}';

  /// `clear` is used to wipe or invalidate the cache of a `HydratedBloc`.
  /// Calling `clear` will delete the cached state of the bloc
  /// but will not modify the current state of the bloc.
  Future<void> clear() => storage.delete(storageToken);

  /// Responsible for converting the `Map<String, dynamic>` representation
  /// of the bloc state into a concrete instance of the bloc state.
  ///
  /// If `fromJson` throws an `Exception`,
  /// `HydratedBloc` will return an `initialState` of `null`
  /// so it is recommended to set `initialState` in the bloc to
  /// `super.initialState() ?? defaultInitialState()`.
  State fromJson(Map<String, dynamic> json);

  /// Responsible for converting a concrete instance of the bloc state
  /// into the the `Map<String, dynamic>` representation.
  ///
  /// If `toJson` returns `null`, then no state changes will be persisted.
  Map<String, dynamic> toJson(State state);
}
