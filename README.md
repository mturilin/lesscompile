#Less Compile

Lessompile is a transformer of .less -> .css for Dart projects.
It uses node.js and lessc installed on your system.

Compilation happens during "pub build" process. Because of that the transformer is good only for the final deployment.
It doesn't automatically update files during the development (this is tru for all pub transformers).

The code is base on less_node: https://github.com/AdalbertoLacruz/less_node

# Installing

    dependencies:
      lesscompile: any

# Configuring

    transformers:
      - lesscompile:
          files:
            - web/asimov.less
            - web/baley.less
            - web/components/elijah.less

# Using

    pub build


#Troubleshooting

Make sure lessc and node can work on you machine without shell environment variables.
Sometimes this requires:

- Installing lessc globally
- Putting symlinks into /usr/bin for node and lessc.