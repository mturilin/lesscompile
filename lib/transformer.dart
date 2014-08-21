/*
 * Copyright (c) 2014, mikhail@turilin.com
 * (based on https://github.com/AdalbertoLacruz/less_node - thanks a lot)
 */
library lesscompile;

import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:convert';
import 'package:barback/barback.dart';


class LessTransformer extends Transformer {
    final BarbackSettings settings;
    bool cleancss = false;

    bool compress = false;

    String start_dir = '';

    String executable = 'lessc';

    String include_path = '';

    List<String> files;

    LessTransformer.asPlugin(this.settings) {
        var args = settings.configuration;

        executable = args['executable'] != null ? args['executable'] : 'lessc';

        if (args['cleancss'] != null) cleancss = args['cleancss'];
        if (args['compress'] != null) compress = args['compress'];
        if (args['include_path'] != null) include_path = args['include_path'];

        files = args['files'];
    }


    Future<bool> isPrimary(AssetId id) {
        return new Future.value(files.contains(id.path));
    }

    Future apply(Transform transform) {
        var input = transform.primaryInput;
        String inputFile = input.id.path;

        var flags = [];
        flags.add('--no-color');
        if (cleancss) flags.add('--clean-css');
        if (compress) flags.add('--compress');
        if (include_path != '') flags.add('--include-path=' + include_path);
        flags.add(inputFile);

        print('\nless_node> command: $executable ${flags.join(' ')}');

        return Process.start(executable, flags, runInShell: true).then((Process process) {
            AssetId outputId = input.id.changeExtension('.css');
            var asset = new Asset.fromStream(outputId, process.stdout);

            return process.exitCode.then((exitCode) {
                if (exitCode == 0) {
                    print('less> $executable process completed');
                    transform.addOutput(asset);
                } else {
                    throw new LessException(stderr.toString());
                }
            });

        }).catchError((ProcessException e) {
            throw new LessException(e.toString());
        }, test: (e) => e is ProcessException);
    }


}


class LessException implements Exception {
    final String message;

    LessException(this.message);

    String toString() => '\n' + message;
}