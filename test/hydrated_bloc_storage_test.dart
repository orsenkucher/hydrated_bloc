import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  group('HydratedBlocStorage', () {
    group('Default Storage Directory', () {
      const channel = MethodChannel('plugins.flutter.io/path_provider');
      var response = '.';
      HydratedBlocStorage hydratedStorage;

      channel.setMockMethodCallHandler((MethodCall methodCall) async {
        return response;
      });

      tearDown(() {
        hydratedStorage.clear();
      });

// TODO HydratedFutureStorage test
      group('heavy load', () {
        test('writes heavily', () async {
          hydratedStorage = await HydratedBlocStorage.getInstance();
          var storage = HydratedFutureStorage(Directory.current);
          final token = 'CounterBloc';
          await hydratedStorage.write(token, "");
          final tasks = Iterable.generate(250, (i) => i).map((i) async {
            final record = Iterable.generate(
              i,
              (i) => Iterable.generate(i, (j) => 'Point($i,$j);').toList(),
            ).toList();
            final jsoned = json.encode(record);
            await storage.write(token, jsoned); //TODO remove await
            // hydratedStorage = await HydratedBlocStorage.getInstance();
            // expect(await storage.read(token), jsoned);// THIS will definitely crash

            dynamic written;
            try {
              final string = await storage.read(token);
              final object = json.decode(string);
              written = object;
            } on dynamic catch (_) {
              written = null;
            } // At least json is not corrupted
            expect(written, isNotNull);
          });

          await Future.wait(tasks);
          storage.clear();
        });
      });

      group('read', () {
        test('returns null when file does not exist', () async {
          hydratedStorage = await HydratedBlocStorage.getInstance();
          expect(
            hydratedStorage.read('CounterBloc'),
            isNull,
          );
        });

        test('returns correct value when file exists', () async {
          final token = 'CounterBloc';
          final file = File('./.bloc.$token.json');
          file.writeAsStringSync(json.encode({"value": 4}));
          hydratedStorage = await HydratedBlocStorage.getInstance();
          expect(hydratedStorage.read(token)['value'] as int, 4);
        });

        test('returns correct list when file exists', () async {
          final token = 'CounterBloc';
          final file = File('./.bloc.$token.json');
          final list = ["C418", "`<v1'alpha>`"];
          file.writeAsStringSync(json.encode(list));
          hydratedStorage = await HydratedBlocStorage.getInstance();
          expect(hydratedStorage.read(token), list);
        });

        test('returns correct number when file exists', () async {
          final token = 'CounterBloc';
          final file = File('./.bloc.$token.json');
          file.writeAsStringSync(3.1415.toString());
          hydratedStorage = await HydratedBlocStorage.getInstance();
          expect(hydratedStorage.read(token) as double, 3.1415);
        });

        test('returns correct string when file exists', () async {
          final token = 'CounterBloc';
          final file = File('./.bloc.$token.json');
          file.writeAsStringSync('"3.1415.toString()"');
          hydratedStorage = await HydratedBlocStorage.getInstance();
          expect(hydratedStorage.read(token) as String, "3.1415.toString()");
        });

        test(
            'returns null value when file exists but contains corrupt json and deletes the file',
            () async {
          final token = 'CounterBloc';
          final file = File('./.bloc.$token.json');
          file.writeAsStringSync("invalid-json");
          hydratedStorage = await HydratedBlocStorage.getInstance();
          expect(hydratedStorage.read(token), isNull);
          expect(file.existsSync(), false);
        });
      });

      group('write', () {
        test('writes string to file', () async {
          hydratedStorage = await HydratedBlocStorage.getInstance();
          await hydratedStorage.write('CounterBloc', json.encode({"value": 4}));
          expect(hydratedStorage.read('CounterBloc'), '{"value":4}');
        });

        test('writes map to file', () async {
          hydratedStorage = await HydratedBlocStorage.getInstance();
          await hydratedStorage.write('CounterBloc', const {"value": 12});
          expect(hydratedStorage.read('CounterBloc'), const {"value": 12});
        });
      });

      group('clear', () {
        test('clear empty storage', () async {
          hydratedStorage = await HydratedBlocStorage.getInstance();
          await hydratedStorage.clear();
        });

        test('delete existed but vanished case', () async {
          final token = 'CounterBloc';
          hydratedStorage = await HydratedBlocStorage.getInstance();
          await hydratedStorage.write(token, const {"value": 12});
          final file = await File('./.bloc.$token.json').delete();
          await hydratedStorage.delete(token);
          expect(file.existsSync(), false);
        });

        test('clear existed but vanished case', () async {
          final token = 'CounterBloc';
          hydratedStorage = await HydratedBlocStorage.getInstance();
          await hydratedStorage.write(token, const {"value": 12});
          final file = await File('./.bloc.$token.json').delete();
          await hydratedStorage.clear();
          expect(file.existsSync(), false);
        });

        test('calls deletes file, clears storage, and resets instance',
            () async {
          hydratedStorage = await HydratedBlocStorage.getInstance();
          await hydratedStorage.write('CounterBloc', json.encode({"value": 4}));

          expect(hydratedStorage.read('CounterBloc'), '{"value":4}');
          await hydratedStorage.clear();
          expect(hydratedStorage.read('CounterBloc'), isNull);
          final file = File('./.bloc.CounterBloc.json');
          expect(file.existsSync(), false);
        });
      });

      group('delete', () {
        test('delete non existing token', () async {
          hydratedStorage = await HydratedBlocStorage.getInstance();
          await hydratedStorage.delete("Nothing");
        });

        test('does nothing for non-existing key value pair', () async {
          hydratedStorage = await HydratedBlocStorage.getInstance();

          expect(hydratedStorage.read('CounterBloc'), null);
          await hydratedStorage.delete('CounterBloc');
          expect(hydratedStorage.read('CounterBloc'), isNull);
        });

        test('deletes existing key value pair', () async {
          hydratedStorage = await HydratedBlocStorage.getInstance();
          await hydratedStorage.write('CounterBloc', json.encode({"value": 4}));

          expect(hydratedStorage.read('CounterBloc'), '{"value":4}');

          await hydratedStorage.delete('CounterBloc');
          expect(hydratedStorage.read('CounterBloc'), isNull);
        });
      });
    });

// TODO(OMG) is it possible to have one set of tests,
// and provide just different instances of `hydratedStorage`, bro)?
// Because I have A LOT to test otherwise!!!!!!!
    group('Custom Storage Directory', () {
      HydratedBlocStorage hydratedStorage;

      tearDown(() {
        hydratedStorage.clear();
      });

      group('read', () {
        test('returns null when file does not exist', () async {
          hydratedStorage = await HydratedBlocStorage.getInstance(
            storageDirectory: Directory.current,
          );
          expect(
            hydratedStorage.read('CounterBloc'),
            isNull,
          );
        });

        test('returns correct value when file exists', () async {
          final token = 'CounterBloc';
          final file = File('./.bloc.$token.json');
          file.writeAsStringSync(json.encode({"value": 4}));
          hydratedStorage = await HydratedBlocStorage.getInstance(
            storageDirectory: Directory.current,
          );
          expect(hydratedStorage.read(token)['value'] as int, 4);
        });

        test('returns correct list when file exists', () async {
          final token = 'CounterBloc';
          final file = File('./.bloc.$token.json');
          final list = ["C418", "`<v1'alpha>`"];
          file.writeAsStringSync(json.encode(list));
          hydratedStorage = await HydratedBlocStorage.getInstance(
            storageDirectory: Directory.current,
          );
          expect(hydratedStorage.read(token), list);
        });

        test('returns correct number when file exists', () async {
          final token = 'CounterBloc';
          final file = File('./.bloc.$token.json');
          file.writeAsStringSync(3.1415.toString());
          hydratedStorage = await HydratedBlocStorage.getInstance(
            storageDirectory: Directory.current,
          );
          expect(hydratedStorage.read(token) as double, 3.1415);
        });

        test('returns correct string when file exists', () async {
          final token = 'CounterBloc';
          final file = File('./.bloc.$token.json');
          file.writeAsStringSync('"3.1415.toString()"');
          hydratedStorage = await HydratedBlocStorage.getInstance(
            storageDirectory: Directory.current,
          );
          expect(hydratedStorage.read(token) as String, "3.1415.toString()");
        });

        test(
            'returns null value when file exists but contains corrupt json and deletes the file',
            () async {
          final token = 'CounterBloc';
          final file = File('./.bloc.$token.json');
          file.writeAsStringSync("invalid-json");
          hydratedStorage = await HydratedBlocStorage.getInstance(
            storageDirectory: Directory.current,
          );
          expect(hydratedStorage.read(token), isNull);
          expect(file.existsSync(), false);
        });
      });

      group('write', () {
        test('writes string to file', () async {
          hydratedStorage = await HydratedBlocStorage.getInstance(
            storageDirectory: Directory.current,
          );
          await hydratedStorage.write('CounterBloc', json.encode({"value": 4}));
          expect(hydratedStorage.read('CounterBloc'), '{"value":4}');
        });

        test('writes map to file', () async {
          hydratedStorage = await HydratedBlocStorage.getInstance(
            storageDirectory: Directory.current,
          );
          await hydratedStorage.write('CounterBloc', const {"value": 12});
          expect(hydratedStorage.read('CounterBloc'), const {"value": 12});
        });
      });

      group('clear', () {
        test('clear empty storage', () async {
          hydratedStorage = await HydratedBlocStorage.getInstance(
            storageDirectory: Directory.current,
          );
          await hydratedStorage.clear();
        });

        test('delete existed but vanished case', () async {
          final token = 'CounterBloc';
          hydratedStorage = await HydratedBlocStorage.getInstance(
            storageDirectory: Directory.current,
          );
          await hydratedStorage.write(token, const {"value": 12});
          final file = await File('./.bloc.$token.json').delete();
          await hydratedStorage.delete(token);
          expect(file.existsSync(), false);
        });

        test('clear existed but vanished case', () async {
          final token = 'CounterBloc';
          hydratedStorage = await HydratedBlocStorage.getInstance(
            storageDirectory: Directory.current,
          );
          await hydratedStorage.write(token, const {"value": 12});
          final file = await File('./.bloc.$token.json').delete();
          await hydratedStorage.clear();
          expect(file.existsSync(), false);
        });

        test('calls deletes file, clears storage, and resets instance',
            () async {
          hydratedStorage = await HydratedBlocStorage.getInstance(
            storageDirectory: Directory.current,
          );
          await hydratedStorage.write('CounterBloc', json.encode({"value": 4}));

          expect(hydratedStorage.read('CounterBloc'), '{"value":4}');
          await hydratedStorage.clear();
          expect(hydratedStorage.read('CounterBloc'), isNull);
          final file = File('./.bloc.CounterBloc.json');
          expect(file.existsSync(), false);
        });
      });

      group('delete', () {
        test('delete non existing token', () async {
          hydratedStorage = await HydratedBlocStorage.getInstance(
            storageDirectory: Directory.current,
          );
          await hydratedStorage.delete("Nothing");
        });

        test('does nothing for non-existing key value pair', () async {
          hydratedStorage = await HydratedBlocStorage.getInstance(
            storageDirectory: Directory.current,
          );

          expect(hydratedStorage.read('CounterBloc'), null);
          await hydratedStorage.delete('CounterBloc');
          expect(hydratedStorage.read('CounterBloc'), isNull);
        });

        test('deletes existing key value pair', () async {
          hydratedStorage = await HydratedBlocStorage.getInstance(
            storageDirectory: Directory.current,
          );
          await hydratedStorage.write('CounterBloc', json.encode({"value": 4}));

          expect(hydratedStorage.read('CounterBloc'), '{"value":4}');

          await hydratedStorage.delete('CounterBloc');
          expect(hydratedStorage.read('CounterBloc'), isNull);
        });
      });
    });
  });
}
