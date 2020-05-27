import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../hydrated_bloc.dart';

typedef ScopeBuilder = HydratedScope Function(Widget child);

class Hydrated {
  static Hydrated _hydrated;
  final _builders = <String, ScopeBuilder>{};
  final _storages = <String, HydratedStorage>{};

  Future<void> config$(Map<String, ScopeConfig> configs) async {
    for (final key in configs.keys) {
      _builders[key] = (child) => HydratedScope(token: key, child: child);
      final cfg = configs[key];
      _storages[key] = await HydratedBlocStorage.getInstance(
        storageDirectory: cfg.storageDirectory,
        encryptionCipher: cfg.encryptionCipher,
      );
    }
  }

  static Future<void> config(Map<String, ScopeConfig> configs) async {
    final hydrated = Hydrated();
    await hydrated.config$(configs);
    _hydrated = hydrated;
  }

  static ScopeBuilder scope(String name) {
    return _hydrated._builders[name];
  }

  static HydratedStorage storage(String name) {
    return _hydrated._storages[name];
  }
}

class ScopeConfig {
  const ScopeConfig({this.storageDirectory, this.encryptionCipher});
  final Directory storageDirectory;
  final HydratedCipher encryptionCipher;
}

class HydratedScope extends InheritedWidget {
  const HydratedScope({
    Key key,
    @required child,
    @required this.token,
  })  : assert(token != null),
        assert(child != null),
        super(key: key, child: child);

  final String token;

  static HydratedScope of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<HydratedScope>();
  }

  @override
  bool updateShouldNotify(HydratedScope old) => token != old.token;
}

extension BuildContext$ on BuildContext {
  HydratedScope scope() => HydratedScope.of(this);
}
