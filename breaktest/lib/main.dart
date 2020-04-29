import 'package:breaktest/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  BlocSupervisor.delegate = await HydratedBlocDelegate.build();
  runApp(App());
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider<TestBloc>(
      create: (_) => TestBloc(),
      child: MaterialApp(
        title: 'Break Test',
        theme: ThemeData(
          appBarTheme: AppBarTheme(
              color: Colors.black,
              textTheme: TextTheme(
                  title: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ))),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            splashColor: Colors.amber,
          ),
          canvasColor: Colors.black,
          textTheme: TextTheme(
              body1: TextStyle(
            color: Colors.white,
            fontSize: 34,
          )),
        ),
        home: HomePage(title: 'Hydrated v3.1.0'),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  HomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: BlocBuilder<TestBloc, Map<String, int>>(
          builder: (context, state) =>
              Text(state.keys.map((k) => '$k:${state[k]}').join('\n\n')),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.bloc<TestBloc>().add(Object),
        child: Icon(
          Icons.watch_later,
          size: 36,
        ),
      ),
    );
  }
}
