# DocToolchain Wrapper Script

## Why this project?

I like the following things:

* Well structured and commonly known architecture documentation with [Arc42](https://arc42.de).
* Documentation as code and the idea behind [docToolchain](https://doctoolchain.github.io/docToolchain)
* Containerize your applications with [Docker](https://www.docker.com/products/docker-engine)

Then I've tried out the getting started manual from [docToolchain](https://doctoolchain.github.io/docToolchain/#_how_to_install_doctoolchain).
I was getting into trouble:

1. The configured gradle is version 4.3.1 which was incompatible with my java 11 installation.
2. I've upgraded the 'gradle-wrapper.properties' to 5.4.1 which works fine, but...
3. The generateHTML and generatePDF goals did not work because of that known [issue 259](https://github.com/docToolchain/docToolchain/issues/259)
4. So I was looking for an existing docker container and got it: [rdmueller/doctoolchain](https://hub.docker.com/r/rdmueller/doctoolchain). But got the same issue.
5. I've realized that the solution given in [issue 259](https://github.com/docToolchain/docToolchain/issues/259) is to change the gradle.properties, which is part of the image.
6. I still wanted to have a flexible solution where my colleagues could easily adapt. 
7. So I had two options:
    1. Use an older version of the docToolchain container. --> I got other problems. :-(
    2. Find a nice work around. --> Here comes the script. ;-) 

## How to use it?

You can simply download the shell script via:

```bash
 wget https://github.com/jschwarze/doctoolchain-wrapper/raw/master/doctoolchain.sh && chmod +x doctoolchain.sh
```

Put it into a folder like ~/bin for getting it into your PATH.
Now you are ready to initialize your first project:

```bash
doctoolchain.sh initArc42EN <your-documentation-folder>
```

Voila! You should now have an initialized documentation project. Jump into the created folder.
Here you'll find the stuff created by docToolchain and the downloaded template ressources.
Additionally, we have:

* A copy of [doctoolchain.sh](doctoolchain.sh) for execution inside the project.
* A '.gitignore' file that will exclude the folders 'build' and '.gradle' from version control.
* A 'graddle.properties' file that is used during the docToolchain runs. Modify it according the official documentation.

That's it. Time to generate your first documentation:

```bash
cd <your-documentation-folder>
./doctoolchain.sh generateHTML
./doctoolchain.sh generatePDF
```

To push the documentation into a confluence, you have to configure the coordinates inside of 'Config.groovy'.
Please ignore 'scrips/ConfluenceConfig.groovy', that file isn't used anymore.
Here is an example, how to configure the confluence connection:

```groovy
confluence.with {
    input = [
            [ file: "build/html5/arc42-template.html" ],
    ]
    api = 'https://<your-confluence-host>/rest/api/'
    ancestorId = '<page-id-of-parent-page>'
    spaceKey = '<confluence-space-key>'
    createSubpages = true
    pagePrefix = ''
    credentials = "<username>:<password>".bytes.encodeBase64().toString()
    extraPageContent = '<ac:structured-macro ac:name="warning"><ac:parameter ac:name="title" /><ac:rich-text-body>This is a generated page, do not edit!</ac:rich-text-body></ac:structured-macro>'
}
```

This example will push the architecture documentation into the KiwiOS space 

```bash
cd <your-documentation-folder>
./doctoolchain.sh publishToConfluence
```

You can also list available commands with:

```bash
./doctoolchain.sh help
```

## Why not contributing to [docToolchain](https://github.com/docToolchain/docToolchain)?
It's a good idea and I'm thinking about it.

First, I'm not sure if it fits my needs. So it is an experiment.

If I'm happy, and some of my colleagues also, I'll contact the maintainer and suggest it.

