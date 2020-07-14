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
    final stateJson = _toJson(this.state);
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
  //   throw JsonUnsupportedObjectError(object, partialResult: _partialResult);
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

//  /// Serialize a [List].
//   void writeList(List list) {
//     writeString('[');
//     if (list.isNotEmpty) {
//       writeObject(list[0]);
//       for (var i = 1; i < list.length; i++) {
//         writeString(',');
//         writeObject(list[i]);
//       }
//     }
//     writeString(']');
//   }

//   /// Serialize a [Map].
//   bool writeMap(Map map) {
//     if (map.isEmpty) {
//       writeString("{}");
//       return true;
//     }
//     var keyValueList = List(map.length * 2);
//     var i = 0;
//     var allStringKeys = true;
//     map.forEach((key, value) {
//       if (key is! String) {
//         allStringKeys = false;
//       }
//       keyValueList[i++] = key;
//       keyValueList[i++] = value;
//     });
//     if (!allStringKeys) return false;
//     writeString('{');
//     var separator = '"';
//     for (var i = 0; i < keyValueList.length; i += 2) {
//       writeString(separator);
//       separator = ',"';
//       writeStringContent(keyValueList[i]);
//       writeString('":');
//       writeObject(keyValueList[i + 1]);
//     }
//     writeString('}');
//     return true;
//   }
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

  // ==================

  final List _seen = [];

  void _checkCycle(object) {
    for (var i = 0; i < _seen.length; i++) {
      if (identical(object, _seen[i])) {
        throw StateCyclicError(object);
      }
    }
    _seen.add(object);
  }

  void _removeSeen(object) {
    assert(_seen.isNotEmpty);
    assert(identical(_seen.last, object));
    _seen.removeLast();
  }

  Map<String, dynamic> _toJson(State state) {
    return _traverseWrite(toJson(state));
  }

  // dynamic _traverseWrite(dynamic value) {}

  dynamic _traverseWrite(dynamic value) {
    if (_checkJsonValue(value)) return _writeValueJson(value);
    _checkCycle(value);
    try {
      var customJson = _toEncodable(value);
      if (!_checkJsonValue(customJson)) {
        throw UnsupportedStateError(value);
      }
      _removeSeen(value);
      return _writeValueJson(customJson);
    } on dynamic catch (e) {
      throw UnsupportedStateError(value, cause: e);
    }
  }

  dynamic _writeValueJson(dynamic value) {
    if (value is Map) {
      final map = <String, dynamic>{};
      value.forEach((key, value) {
        map[key] = _traverseWrite(value);
      });
      return map;
    }
    if (value is List) {
      final list = <dynamic>[];
      for (var item in value) {
        list.add(_traverseWrite(item));
      }
      return list;
    }
    return value;
  }

  bool _checkJsonValue(object) {
    if (object is num) {
      if (!object.isFinite) return false;
      return true;
    } else if (identical(object, true)) {
      return true;
    } else if (identical(object, false)) {
      return true;
    } else if (object == null) {
      return true;
    } else if (object is String) {
      return true;
    } else if (object is List) {
      _checkCycle(object);
      _removeSeen(object);
      return true;
    } else if (object is Map) {
      _checkCycle(object); // TODO move this
      _removeSeen(object);
      return true;
    } else {
      return false;
    }
  }

  // bool _isJson(dynamic object) {}

  dynamic _toEncodable(dynamic object) => object.toJson();

  // ==================

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
    final stateJson = _toJson(state);
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

class StateCyclicError extends UnsupportedStateError {
  /// The first object that was detected as part of a cycle.
  StateCyclicError(Object object) : super(object);
  String toString() => "Cyclic error in JSON stringify";
}

class UnsupportedStateError extends Error {
  /// The object that could not be serialized.
  final Object unsupportedObject;

  /// The exception thrown when trying to convert the object.
  final Object cause;

  UnsupportedStateError(
    this.unsupportedObject, {
    this.cause,
  });

  String toString() {
    var safeString = Error.safeToString(unsupportedObject);
    String prefix;
    if (cause != null) {
      prefix = "Converting object to an encodable object failed:";
    } else {
      prefix = "Converting object did not return an encodable object:";
    }
    return "$prefix $safeString";
  }
}
