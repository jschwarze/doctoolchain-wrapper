# DocToolchain Wrapper Script

## Why this project

I like the following things:

* Well structured and commonly known architecture documentation with [Arc42](https://arc42.de).
* Documentation as code and the idea behind [docToolchain](https://doctoolchain.github.io/docToolchain)
* [Asciidoctor](https://asciidoctor.org/)
* [PlantUML](http://plantuml.com)
* [C4Model and Examples from Ricardo Niepel](https://github.com/RicardoNiepel/C4-PlantUML/tree/master/samples)
* [Icons and Graphics for PlantUM](https://github.com/Roemer/plantuml-office)
* [PlantUML Documentation](https://plantuml-documentation.readthedocs.io/en/latest/)
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

## How to use it

### How to install

You can simply download the shell script via:

```bash
 wget https://github.com/jschwarze/doctoolchain-wrapper/raw/master/doctoolchain.sh && chmod +x doctoolchain.sh
```

Put it into a folder like ~/bin for getting it into your PATH.
Now you are ready to initialize your first project:

### How to initialize my project

```bash
doctoolchain.sh initArc42EN <your-documentation-folder>
```

Voila! You should now have an initialized documentation project. Jump into the created folder.
Here you'll find the stuff created by docToolchain and the downloaded template ressources.
Additionally, we have:

* A copy of [doctoolchain.sh](doctoolchain.sh) for execution inside the project.
* A '.gitignore' file that will exclude the folders 'build' and '.gradle' from version control.
* A 'graddle.properties' file that is used during the docToolchain runs. Modify it according the official documentation.

### How to configure

Here are the environment variables to configure the doctoolchain wrapper:

* **DTC_VERSION** - Configure the version of the used [docToolchain docker image](https://hub.docker.com/r/rdmueller/doctoolchain). Default **is v1.1.1**.
* **DTC_IMAGE** - The image that is used. defaults to [rdmueller/doctoolchain](https://hub.docker.com/r/rdmueller/doctoolchain)
* **DTC_DOC_ROOT** - The home of your documentation sources
* **DTC_OUTPUT_DIR** - The folder where the output is generated in.

### How to generate the Docs

That's it. Time to generate your first documentation:

```bash
cd <your-documentation-folder>
./doctoolchain.sh generateHTML
./doctoolchain.sh generatePDF
```

After the execution, you'll find the HTML5 and the PDF outputs inside of the`DTC_OUTPUT_DIR` folder.

### How to push to Confluence

To push the documentation into a confluence, you have to configure the coordinates inside of 'Config.groovy'.
Please ignore 'scrips/ConfluenceConfig.groovy', that file isn't used anymore.
Here is an example, how to configure the confluence connection:

```groovy
confluence.with {
    input = [
            [ file: "build/html5/arc42-template.html", ancestorId: '<page-id-of-parent-page>', preambleTitle: '<custom-title != arc42>' ],
    ]
    api = 'https://<your-confluence-host>/rest/api/'
    spaceKey = '<confluence-space-key>'
    createSubpages = true
    pagePrefix = ''
    credentials = "<username>:<password>".bytes.encodeBase64().toString()
    extraPageContent = '<ac:structured-macro ac:name="warning"><ac:parameter ac:name="title" /><ac:rich-text-body>This is a generated page, do not edit!</ac:rich-text-body></ac:structured-macro>'
}
```

This example will push the architecture documentation into the confluence space given by `<confluence-space-key>` on the host `<your-confluence-host>`.
It will create the pages as subpages of `<page-id-of-parent-page>`.
You have to enter user credentials for Confluence. NEVER commit this part into git! Use a dynamic way with Jenkins Credentials that adds that variables during runtime.

```bash
cd <your-documentation-folder>
./doctoolchain.sh publishToConfluence
```

### How to insert diagrams

You can easily include UML diagrams with the help of [PlantUML](http://plantuml.com).
You will find the documentation for PlantUML and diagram usage in general at the [pages of asciidoctor](https://asciidoctor.org/news/2014/02/18/plain-text-diagrams-in-asciidoctor/)

There are two ways for inclusion:

1. Directly inside the AsciiDoc file
2. Externally written and only referenced inside the AsciiDoc.
  
#### Diagram inside

Place the content directly into the asciidoc file, e.g.:

```asciidoc
[[main-classes]]
.The PlantUML block extension class
[plantuml, sample-plantuml-diagram, alt="Class diagram", width=135, height=118]
----
class BlockProcessor
class PlantUmlBlock
BlockProcessor <|-- PlantUmlBlock
----
```

#### Referenced Diagram

Put the diagram definition in a text file and make a reference to it inside your asciidoc:

```asciidoc
plantuml::classes.txt[format=svg, alt="Class diagram", width=300, height=200]
```

#### How to write diagrams

Please read the [documentation pages of PlantUML](http://plantuml.com/) to learn, which diagrams are possible and how to write them.

For a simple editor and preview, you are able to start the PlantUML server with the command:

```bash
./doctoolchain.sh plantUML
```

This will download and start (docker required) the PlantUML server. It is reachable at [http://localhost:8081](http://localhost:8081)
If port 8081 is already in use, you can change it with the environment variable `PLANTUML_PORT`.

#### Which diagram

With help of the [C4 model](https://c4model.com/), it becomes simpler to get a good starting point for the needed diagrams.
The model defines four types, all starting with C:

* Context
* Container
* Components
* Classes

So the first type **Context** maps to chapter 3 of Arc42, scope and context.
The second **Containers** and the third **Components** fits fine into chapter 5, the building block view. The last, the **Class** diagram fits into chapter 8, concepts: Here it could help to explain general concepts that should be used by developers to follow architectural patterns. Also, that diagrams will help inside of the documentation of a single component to explain the main thoughts. A good starting point for C4 with PlantUML could be found on Github: [C4Model and Examples from Ricardo Niepel](https://github.com/RicardoNiepel/C4-PlantUML/tree/master/samples)

### What else

You can also list available commands with:

```bash
./doctoolchain.sh help
```

## Why not contributing to [docToolchain](https://github.com/docToolchain/docToolchain)

It's a good idea and I'm thinking about it.

First, I'm not sure if it fits my needs. So it is an experiment.

If I'm happy, and some of my colleagues also, I'll contact the maintainer and suggest it.
