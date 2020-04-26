import 'package:benchmark/hooks.dart';
import 'package:benchmark/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'benchmark.dart';

void main() => runApp(App());

class App extends StatefulWidget {
  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: _theme(),
      home: Builder(
        builder: (context) => Scaffold(
          body: SafeArea(
            child: _view(context),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }

  ThemeData _theme() {
    return ThemeData(
      brightness: Brightness.light,
      buttonTheme: ButtonThemeData(
        highlightColor: Colors.blue.withOpacity(0.2),
        splashColor: Colors.blue.withOpacity(0.5),
      ),
      textTheme: TextTheme(
        button: TextStyle(fontSize: 18),
        title: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  var _running = false;
  final _results = <Result>[];
  Widget _benchmark(BuildContext context) {
    return OutlineButton(
      padding: EdgeInsets.symmetric(
        horizontal: 12.0,
        vertical: 4.0,
      ),
      child: Text("BENCHMARK"),
      onPressed: _running
          ? null
          : () async {
              if (_running) return;
              _results.clear();
              setState(() => _running = true);
              print('RUNNING');
              final bm = Benchmark(settings);
              final maa = {
                Mode.read: bm.doReads,
                Mode.write: bm.doWrites,
                Mode.wake: bm.doWakes,
                // Mode.delete: bm.doDeletes,
              };

              final mm = settings.modes;
              await Stream.fromIterable(mm.keys.where((m) => mm[m]))
                  .asyncExpand((m) => maa[m]())
                  .act((r) => setState(() => _results.add(r)))
                  .map((r) sync* {
                    yield '${r.runner.storageType}: int64 : ${r.intTime}ms';
                    yield '${r.runner.storageType}: string: ${r.stringTime}ms';
                  })
                  .act(print)
                  .drain();
              setState(() => _running = false);
              print('DONE');
              Future.delayed(const Duration(milliseconds: 100)).then(
                  (_) => setState(() {})); //controller.position.extentAfter
            },
    );
  }

  List<Widget> _list(BuildContext context) => [
        ..._results.map(
          (r) => Card(
            color: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              side: BorderSide(
                color: Colors.grey.withOpacity(0.3),
                width: 1.0,
              ),
              borderRadius: BorderRadius.circular(4.0),
            ),
            margin: EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
            child: ListTile(
              dense: true,
              selected: true,
              subtitle: () {
                format(Duration d) => d.inSeconds >= 10
                    ? '${d.inSeconds}s'
                    : d.inMilliseconds > 0
                        ? '${d.inMilliseconds}ms'
                        : '${d.inMicroseconds}μs';
                final it = format(r.intTime);
                final st = format(r.stringTime);
                return Text('i64 $it, str $st');
              }(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 4.0,
              ),
              leading: Container(
                child: () {
                  final icon = r.runner.aes ? Icons.fingerprint : Icons.blur_on;
                  return Icon(icon, color: Colors.black, size: 30);
                }(),
              ),
              title: Text(
                '${r.runner.storageType}: ${r.mode}',
                style: Theme.of(context).textTheme.title,
              ),
            ),
          ),
        )
      ];

  final settings = BenchmarkSettings();
  Widget _view(BuildContext context) {
    return HookBuilder(
      builder: (context) {
        final controller = useScrollController(initialScrollOffset: 400);
        return CustomScrollView(
          controller: controller,
          reverse: true,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // BOTTOM
            SliverAppBar(
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                background: Container(
                  padding: EdgeInsets.only(top: 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0x00ffffff), Colors.blue.withOpacity(0.2)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: ListView(
                    reverse: true,
                    physics: const BouncingScrollPhysics(),
                    children: <Widget>[
                      IconButton(
                        icon: Icon(Icons.keyboard_arrow_up),
                        onPressed: _results.isEmpty ||
                                controller.position.maxScrollExtent <= 0
                            ? null
                            : () => controller.animateTo(
                                  controller.position.maxScrollExtent -
                                      controller.position.viewportDimension +
                                      5,
                                  duration: Duration(
                                      milliseconds: 200 + 50 * _results.length),
                                  curve: Curves.easeInOut,
                                ),
                      ),
                      // SETTINGS TOP
                      RangeSlider(
                        min: settings.stateSizeRange.start,
                        max: settings.stateSizeRange.end,
                        divisions: settings.stateSizeDivs,
                        labels: settings.stateSizeLabels,
                        values: settings.stateSize,
                        onChanged: (rv) =>
                            setState(() => settings.stateSize = rv),
                      ),
                      () {
                        const px = '⩾';
                        final cc = settings.stateSizeBytesMax ~/ 4;
                        $(int cc) {
                          if (cc < 1e3) {
                            return '$cc';
                          } else if (cc < 1e5) {
                            cc ~/= 1e3;
                            return '$px${cc}k';
                          } else if (cc < 1e6) {
                            cc ~/= 1e4;
                            cc *= 10;
                            return '$px${cc}k';
                          } else {
                            cc ~/= 1e6;
                            return '$px${cc}M';
                          }
                        }

                        final text = '${$(cc)} int64${cc > 1 ? 's' : ''}';
                        const title = 'STATE SIZE';
                        return TitleRow(
                          text: text,
                          title: title,
                          decorator: (ww) => [
                            TitleText(text: px, transparent: true),
                            ...ww,
                            TitleText(text: px, transparent: true),
                          ],
                        );
                      }(),
                      Divider(),
                      () {
                        // final controller2 = ScrollController();
                        final view = HookBuilder(
                          builder: (context) {
                            final controller2 = useScrollController();

                            return CustomScrollView(
                              controller: controller2,
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(
                                parent: AlwaysScrollableScrollPhysics(),
                              ),
                              slivers: [
                                SliverFillRemaining(
                                  child: () {
                                    const ss = [
                                      Storage.single,
                                      Storage.multi,
                                      Storage.ether
                                    ];
                                    const ll = {
                                      Storage.single: 'Single file',
                                      Storage.multi: 'Isolated files',
                                      Storage.ether: 'Temporal'
                                    };
                                    Widget bb = ToggleButtons(
                                      isSelected: ss
                                          .map((s) => settings.storages[s])
                                          .toList(),
                                      onPressed: (i) => setState(
                                          () => settings.flipStorage(ss[i])),
                                      children:
                                          ss.map((s) => Text(ll[s])).toList(),
                                      constraints: const BoxConstraints(
                                        minWidth: 100.0,
                                        minHeight: 32.0,
                                      ),
                                      borderColor: Colors.grey.withOpacity(0.3),
                                      selectedBorderColor:
                                          Colors.blue.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(8),
                                    );
                                    bb = Center(child: bb);
                                    final tap = Align(
                                      alignment: Alignment.centerRight,
                                      child: IconButton(
                                        onPressed: () {
                                          controller2.animateTo(
                                            controller2.position.extentBefore >
                                                    0
                                                ? controller2
                                                    .position.minScrollExtent
                                                : controller2
                                                    .position.maxScrollExtent,
                                            duration: const Duration(
                                                milliseconds: 250),
                                            curve: Curves.easeOut,
                                          );
                                        },
                                        icon: Icon(
                                          Icons.keyboard_arrow_left,
                                          color: Colors.blue.withOpacity(0.5),
                                        ),
                                      ),
                                    );
                                    return Stack(children: [bb, tap]);
                                  }(),
                                ),
                                SliverToBoxAdapter(
                                  child: Container(
                                    padding: EdgeInsets.only(right: 12),
                                    alignment: Alignment.center,
                                    child: () {
                                      const ll = ['AES', 'Base64'];
                                      final ss = {
                                        'AES': settings.useAES,
                                        'Base64': settings.useB64,
                                      };
                                      final pp = {
                                        'AES': settings.flipUseAES,
                                        'Base64': settings.flipUseB64,
                                      };
                                      return ToggleButtons(
                                        isSelected:
                                            ll.map((l) => ss[l]).toList(),
                                        onPressed: (i) =>
                                            setState(() => pp[ll[i]]()),
                                        // onPressed: (i) => null,
                                        children:
                                            ll.map((l) => Text(l)).toList(),
                                        constraints: const BoxConstraints(
                                          minWidth: 80.0,
                                          minHeight: 32.0,
                                        ),
                                        borderColor:
                                            Colors.grey.withOpacity(0.3),
                                        selectedBorderColor:
                                            Colors.blue.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(8),
                                      );
                                    }(),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                        return SizedBox(height: 48, child: view);
                      }(),
                      // SizedBox(height: 8),
                      () {
                        final cur =
                            settings.storages.values.where((v) => v).length;
                        final tot = settings.storages.length;
                        final text = '$cur/$tot';
                        const title = 'STORAGES';
                        return TitleRow(text: text, title: title);
                      }(),
                      Divider(),

                      RangeSlider(
                        min: settings.blocCountRange.start,
                        max: settings.blocCountRange.end,
                        divisions: settings.blocCountDivs,
                        labels: settings.blocCountLabels,
                        values: settings.blocCount,
                        onChanged: (rv) =>
                            setState(() => settings.blocCount = rv),
                      ),
                      () {
                        final start = settings.blocCount.start.toInt();
                        final end = settings.blocCount.end.toInt();
                        final text =
                            start == end ? '$end' : '$start-$end'.padLeft(2);
                        const title = 'BLOC COUNT';
                        return TitleRow(text: text, title: title);
                      }(),
                      Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: () {
                          const mm = [
                            Mode.wake,
                            Mode.read,
                            Mode.write,
                            Mode.delete
                          ];
                          const ll = {
                            Mode.wake: 'WAKE',
                            Mode.read: 'READ',
                            Mode.write: 'WRITE',
                            Mode.delete: 'DELETE',
                          };
                          const oss = {
                            Mode.wake: true,
                            Mode.read: true,
                            Mode.write: true,
                            Mode.delete: false,
                          };
                          final ss = settings.modes;
                          return mm.map((m) => ChoiceChip(
                              onSelected: oss[m]
                                  ? (b) => setState(() => settings.flipMode(m))
                                  : null,
                              selected: ss[m],
                              shape: StadiumBorder(
                                side: BorderSide(
                                  color: ss[m]
                                      ? Colors.blue.withOpacity(0.3)
                                      : Colors.grey.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              selectedColor: Colors.blue.withOpacity(0.15),
                              shadowColor: Colors.grey.withOpacity(0.25),
                              selectedShadowColor:
                                  Colors.blue.withOpacity(0.25),
                              backgroundColor: Theme.of(context).canvasColor,
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              label: Text(ll[m])));
                        }() // insert gaps between chips
                            .expand((w) sync* {
                              yield const SizedBox(width: 8);
                              yield w;
                            })
                            .skip(1)
                            .toList(),
                      ),
                      () {
                        final cur =
                            settings.modes.values.where((v) => v).length;
                        final tot = settings.modes.length;
                        final text = '$cur/$tot';
                        const title = 'BENCH MODES';
                        return TitleRow(text: text, title: title);
                      }()
                    ],
                  ),
                ),
                collapseMode: CollapseMode.parallax,
              ),
              centerTitle: true,
              backgroundColor: Colors.transparent,
              leading: Icon(Icons.developer_board, color: Colors.black),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('UI LOCK', style: Theme.of(context).textTheme.title),
                    Switch(
                      value: settings.uiLock,
                      onChanged: (b) => setState(() => settings.uiLock = b),
                    ),
                  ],
                ),
              ],
              expandedHeight: 400,
            ),
            // MIDDLE
            SliverAppBar(
              backgroundColor: Colors.transparent,
              expandedHeight: 120,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                title: _benchmark(context),
                collapseMode: CollapseMode.none,
              ),
            ),
            SliverList(delegate: SliverChildListDelegate(_list(context))),
            SliverFillViewport(
              delegate: SliverChildListDelegate(
                [
                  Column(
                    verticalDirection: VerticalDirection.up,
                    children: [
                      SizedBox(height: 8),
                      Text('v3.1.0',
                          style: Theme.of(context).textTheme.title.copyWith(
                                color: Colors.grey.withOpacity(0.4),
                              )),
                      IconButton(
                        iconSize: 96,
                        icon: Icon(
                          Icons.select_all,
                          color: Colors.blueGrey.withOpacity(0.4),
                        ),
                        onPressed: () {
                          controller.animateTo(
                            0,
                            duration: const Duration(seconds: 1),
                            curve: Curves.easeInOut,
                          );
                        },
                      ),
                      SizedBox(height: 120),
                      Text(
                        'Tap on little blue processor\nto see tuning options',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .title
                            .copyWith(color: Colors.grey.withOpacity(0.4)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

typedef TitleRowDecorator = List<Widget> Function(List<Widget>);

class TitleRow extends StatelessWidget {
  TitleRow({
    Key key,
    @required this.text,
    @required this.title,
    TitleRowDecorator decorator,
  })  : this.decorator = decorator ?? ((ww) => ww),
        super(key: key);

  final String text;
  final String title;
  final TitleRowDecorator decorator;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: decorator([
        TitleText(text: text, transparent: true),
        Text(title),
        SizedBox(width: 4),
        TitleText(text: text, transparent: false),
      ]),
    );
  }
}

class TitleText extends StatelessWidget {
  const TitleText({
    Key key,
    @required this.text,
    @required this.transparent,
  }) : super(key: key);

  final String text;
  final bool transparent;

  @override
  Widget build(BuildContext context) {
    const tc = Colors.transparent;
    final cc = Colors.grey.withOpacity(.35);
    return Text(
      text,
      textScaleFactor: 0.825,
      style: TextStyle(color: transparent ? tc : cc),
    );
  }
}

extension Stream$<T> on Stream<T> {
  Stream<T> act(void action(T)) {
    return this.map((item) {
      action(item);
      return item;
    });
  }
}
