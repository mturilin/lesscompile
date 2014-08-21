/*
 * Copyright (c) 2014, adalberto.lacruz@gmail.com
 * Thanks to juha.komulainen@evident.fi for inspiration and some code
 * (Copyright (c) 2013 Evident Solutions Oy) from package http://pub.dartlang.org/packages/sass
 *
 * v 0.1.1  20140521 compatibility with barback (0.13.0) and lessc (1.7.0)
 * v 0.1.0  20140218
 */
library lesscompile;

import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:convert';
import 'package:barback/barback.dart';

/*
 * Transformer used by 'pub build' to convert .less files to .css
 * Based on lessc over nodejs executing a process like
 * CMD> lessc --flags input.less > output.css
 * Uses only one file as entry point and produces only one css file
 * To mix several .less files, the input contents could have "@import 'filexx.less'; ..." directives
 * See http://lesscss.org/ for more information
 */
class LessTransformer extends Transformer {
    final BarbackSettings settings;
    bool cleancss = false;

    // cleancss: true - compress output by using clean-css
    bool compress = false;

    // compress: true - compress output by removing some whitespaces
    String start_dir = '';

    // start_dir: web/ - main folder to start
    String executable = 'lessc';

    //executable: lessc - command to execute lessc
    String include_path = '';


    List<String> files;

    //to build process arguments

//    String get allowedExtensions => ".less";

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
/* ************************************** */
/*
 * process error management
 */
class LessException implements Exception {
    final String message;

    LessException(this.message);

    String toString() => '\n' + message;
}