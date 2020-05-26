import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../hydrated_bloc.dart';

typedef ScopeBuilder = HydratedScope Function(Widget child);

class HydratedImpl {
  final _builders = <String, ScopeBuilder>{};
  final _storages = <String, HydratedStorage>{};
  Future<void> config(Map<String, ScopeConfig> configs) {
    configs.forEach((k, v) async {
      // TODO fix
      _builders[k] = (child) => HydratedScope(name: k, child: child);
      _storages[k] = await HydratedBlocStorage.getInstance(
        storageDirectory: v.storageDirectory,
        encryptionCipher: v.encryptionCipher,
      );
    });
  }

  ScopeBuilder scope(String name) {
    return _builders[name];
  }

  HydratedStorage storage(String name) {
    return _storages[name];
  }
}

// extension BuildContext$ on BuildContext{
// //   ScopeBuilder scopeBuilder() => this.
// }

class ScopeConfig {
  const ScopeConfig({this.storageDirectory, this.encryptionCipher});
  final Directory storageDirectory;
  final HydratedCipher encryptionCipher;
}

class HydratedScope extends InheritedWidget {
  const HydratedScope({
    Key key,
    @required this.name,
    @required child,
  })  : assert(name != null),
        assert(child != null),
        super(key: key, child: child);

  final String name;

  static HydratedScope of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<HydratedScope>();
  }

  @override
  bool updateShouldNotify(HydratedScope old) => name != old.name;
}
