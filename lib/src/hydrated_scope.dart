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
    for (final token in configs.keys) {
      _builders[token] = (child) => HydratedScope(token: token, child: child);
      _storages[token] = await HydratedBlocStorage.getScoped(
        config: configs[token].tokenize(token),
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

class TokenedConfig extends ScopeConfig {
  final String token;
  const TokenedConfig({
    @required this.token,
    Directory storageDirectory,
    HydratedCipher encryptionCipher,
  }) : super(
          storageDirectory: storageDirectory,
          encryptionCipher: encryptionCipher,
        );
}

class ScopeConfig {
  const ScopeConfig({this.storageDirectory, this.encryptionCipher});
  final Directory storageDirectory;
  final HydratedCipher encryptionCipher;
  TokenedConfig tokenize(String token) {
    return TokenedConfig(
      token: token,
      storageDirectory: storageDirectory,
      encryptionCipher: encryptionCipher,
    );
  }
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
