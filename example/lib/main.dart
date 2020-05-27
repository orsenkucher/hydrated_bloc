import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:bloc/bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:crypto/crypto.dart';

void main() async {
  // https://github.com/flutter/flutter/pull/38464
  // Changes in Flutter v1.9.4 require you to call WidgetsFlutterBinding.ensureInitialized()
  // before using any plugins if the code is executed before runApp.
  // As a result, you will need the following line if you're using Flutter >=1.9.4.
  WidgetsFlutterBinding.ensureInitialized();
  BlocSupervisor.delegate = await HydratedBlocDelegate.build();

  const password = 'hydration';
  final byteskey = sha256.convert(utf8.encode(password)).bytes;
  await Hydrated.config({
    'secure': ScopeConfig(encryptionCipher: HydratedAesCipher(byteskey)),
    'number': ScopeConfig(),
  });
  runApp(App());
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Hydrated.scope('number')(HydratedProvider<CounterBloc>(
      create: (context, scope) => CounterBloc(scope),
      child: Builder(builder: (context) {
        return Hydrated.scope('secure')(HydratedProvider<CounterBloc>(
          create: (context, scope) => CounterBloc(scope),
          child: MaterialApp(
            title: 'Flutter Demo',
            home: CounterPage(context.bloc<CounterBloc>()),
          ),
        ));
      }),
    ));
  }
}

class CounterPage extends StatelessWidget {
  final CounterBloc counterBlocOuter;
  const CounterPage(this.counterBlocOuter);

  @override
  Widget build(BuildContext context) {
    final CounterBloc counterBlocInner = context.bloc<CounterBloc>();
    return Scaffold(
      appBar: AppBar(title: Text('Counter')),
      body: BlocBuilder<CounterBloc, CounterState>(
        bloc: counterBlocOuter,
        builder: (BuildContext context, CounterState stateOuter) {
          return BlocBuilder<CounterBloc, CounterState>(
            builder: (BuildContext context, CounterState stateInner) {
              return Center(
                child: Text(
                  'inner: ${stateInner.value}\nouter: ${stateOuter.value}',
                  style: TextStyle(fontSize: 24.0),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FabColumn(counterBloc: counterBlocInner),
          SizedBox(width: 12),
          FabColumn(counterBloc: counterBlocOuter),
        ],
      ),
    );
  }
}

class FabColumn extends StatelessWidget {
  const FabColumn({
    Key key,
    @required this.counterBloc,
  }) : super(key: key);

  final CounterBloc counterBloc;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.symmetric(vertical: 5.0),
          child: FloatingActionButton(
            child: Icon(Icons.add),
            onPressed: () {
              counterBloc.add(CounterEvent.increment);
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 5.0),
          child: FloatingActionButton(
            child: Icon(Icons.remove),
            onPressed: () {
              counterBloc.add(CounterEvent.decrement);
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 5.0),
          child: FloatingActionButton(
            child: Icon(Icons.delete_forever),
            onPressed: () async {
              await counterBloc.clear();
              counterBloc.add(CounterEvent.reset);
            },
          ),
        ),
      ],
    );
  }
}

enum CounterEvent { increment, decrement, reset }

class CounterState {
  int value;

  CounterState(this.value);

  @override
  String toString() => 'CounterState { value: $value }';
}

class CounterBloc extends HydratedBloc<CounterEvent, CounterState> {
  CounterBloc(String scope) : super(scope);

  @override
  CounterState get initialState => super.initialState ?? CounterState(0);

  @override
  Stream<CounterState> mapEventToState(CounterEvent event) async* {
    switch (event) {
      case CounterEvent.decrement:
        yield CounterState(state.value - 1);
        break;
      case CounterEvent.increment:
        yield CounterState(state.value + 1);
        break;
      case CounterEvent.reset:
        yield CounterState(0);
        break;
    }
  }

  @override
  CounterState fromJson(Map<String, dynamic> source) {
    return CounterState(source['value'] as int);
  }

  @override
  Map<String, int> toJson(CounterState state) {
    return {'value': state.value};
  }
}
