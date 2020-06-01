import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../hydrated_bloc.dart' hide BuildContext$;

typedef ScopeBuilder = HydratedScope Function(Widget child);

class Hydrated {
  static Hydrated _hydrated;
  final _builders = <String, ScopeBuilder>{};
  final _storages = <String, HydratedStorage>{};
  // final _pendings = ListQueue<String>();

  Future<void> config$(Map<String, ScopeConfig> configs) async {
    for (final token in configs.keys) {
      _builders[token] = (child) => HydratedScope(token: token, child: child);
      _storages[token] = await HydratedBlocStorage.getScoped(
        config: configs[token].tokenize(token),
      );
    }
  }

  String _pending;

  /// Registration and Bloc instantiation are sequential,
  /// so one variable should be enough.
  void register$(String pendingToken) {
    // _pendings.add(pendingToken);
    _pending = pendingToken;
  }

  /// Acquire previously registered token.
  /// Can return `null`, when bloc was not scoped.
  String acquire$() {
    // return _pendings.removeLast();
    return _pending;
  }

  static Future<void> config(Map<String, ScopeConfig> configs) async {
    HydratedProvider.registerPrecursor((context, create) {
      final token = context.scope()?.token;
      if (token == null) return create;
      return (context) {
        Hydrated.register(token);
        return create(context);
      };
    });
    final hydrated = Hydrated();
    await hydrated.config$(configs);
    _hydrated = hydrated;
  }

  static void register(String pendingToken) {
    _instance.register$(pendingToken);
  }

  /// Acquire previously registered token.
  /// Can return `null`, when bloc was not scoped.
  static String acquire() {
    return _hydrated?.acquire$();
  }

  static ScopeBuilder scope(String name) {
    return _instance._builders[name];
  }

  static HydratedStorage storage(String name) {
    return _instance._storages[name];
  }

  static Hydrated get _instance {
    return _hydrated ?? (throw '`config()` should be called first ');
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
