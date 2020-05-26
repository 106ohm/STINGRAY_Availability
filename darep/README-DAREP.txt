DAREP:
------
An approach to automatically define in Mobius tool a composed model that represents
different sets of indexed components and their interdependencies. 

* Required software:
 - Mobius tool
 - Perl language
 - Perl modules: YAML::XS (required to install some modules), Text::Xslate, Path::Tiny, File::Touch, File::Cat, IO::Prompter, File::Slurp, Linux::Distribution, XML::LibXML, XML::Normalize::LibXML, File::Find::Rule, XML::Entities
 - Bash shell
 - Rsync tool

* Perl scripts use /usr/local/bin/perl command.
  Thus, link /usr/local/bin/perl to the current version of perl,
  e.g., on MacOSX 10.13.1:
        cd /usr/local/bin/
        sudo ln -s /opt/local/bin/perl5.26 /usr/local/bin/perl
        
* To install perl modules for perl use the
  corresponding version of cpan.
  E.g., on MacOSX 10.13.1, for perl 5.26 (installed with macports)
  you can use cpan-5.26 (see next bullet below, to fix cpan install errors).
  Module YAML::XS (yaml) is required to install other modules [ https://metacpan.org/pod/YAML::XS ].
  Library libxml2 is required to compile and install a version of XML::LibXML directly from CPAN [ https://grantm.github.io/perl-libxml-by-example/installation.html ].

  You can use the script:
  darep/bin/perl-modules-install.bash

  or manually:

sudo apt-get install libxml2 libxml2-dev
sudo apt-get install libxml2 libxml2-devel (opensuse leap 15)

sudo with-readline cpan-5.26
sudo /usr/local/bin/with-readline cpan (opensuse leap 15)
cpan[...]> install CPAN
cpan[...]> install Bundle::CPAN
cpan[...]> load CPAN
cpan[...]> install YAML::XS 
cpan[...]> install Text::Xslate
cpan[...]> install Path::Tiny
cpan[...]> install File::Touch
cpan[...]> install File::Cat
cpan[...]> install IO::Prompter
cpan[...]> install File::Slurp
cpan[...]> install XML::LibXML::Reader
cpan[...]> install Linux::Distribution
cpan[...]> notest install Linux::Distribution (if test fails)
cpan[...]> install XML::Normalize::LibXML
cpan[...]> install File::Find::Rule
cpan[...]> install XML::Entities
cpan[...]> install Sort::Naturally

* cpan install error and cpan configuration:
  to fix following error, when command line tools without xcode on MacOSX are used:
  Can't exec "/Applications/Xcode.app/Contents/Developer/usr/bin/make": No such file or directory at /opt/local/lib/perl5/5.26/CPAN/Distribution.pm line 2213.
  BINGOS/<module-to-install>.tar.gz
  /Applications/Xcode.app/Contents/Developer/usr/bin/make -- NOT OK
  No such file or directory
  
[ https://perldoc.perl.org/CPAN.html#CONFIGURATION ]
sudo with-readline cpan-5.26
cpan[1]> o conf  (to displays all subcommands and config variables)
...
    make               [/Applications/Xcode.app/Contents/Developer/usr/bin/make]
    make_arg           []
    make_install_arg   []
    make_install_make_command [/Applications/Xcode.app/Contents/Developer/usr/bin/make]
...
cpan[2]> o conf make /Library/Developer/CommandLineTools/usr/bin/make
cpan[2]> o conf make_install_make_command /Library/Developer/CommandLineTools/usr/bin/make
cpan[4]> o conf commit                    

alternatively you can edit cpan config file: $HOME/.cpan/CPAN/MyConfig.pm


* Bash scripts defined in darep are based on:
     - variables defined in config files:
          darep/etc/bash.conf
          darep/etc/bash_macosx.conf (for MacOSX)
          darep/etc/bash_linux.conf (for linux)
     - functions defined in:
          darep/lib/lib.bash

* Bash scripts are structured as follow:
     loadlib "../lib/lib.bash" 
     loadconfig # defined in lib
     function main() {
         foo <args>
         bar <args> # defined in lib
         baz <args> # defined in lib
     }
     function foo() {...}
     function loadlib() {...}
     main "$@"


* Steps of DAREP approach:
 A. Definition of DAREP input xml file.
 B. Definition of DAREP template models, using Mobius GUI.
 C. Automatic generation of DAREP model, using DAREP scripts.

A. DAREP input file:
--------------------
Xml file, based on a template, defining:
 - The names of the template models.
 - The names of the DAREP-shared places included in each template model.
 - The interdependencies, defined for DAREP-shared places, among replicas of the same or
   different SAN templates.

B. DAREP template model:
------------------------
DAREP template model is an atomic SAN model that represents
a generic indexed replica of an atomic SAN.
The SAN formalism used in DAREP template model is extended with:
 - DAREP-shared place, i.e., a place for which:
     1. An instance of the place is generated for each replica of the template model
        associated to the place.
     2. The instances of the place are shared among the instances of the same or different
        template models, based on the dependencies of the place for each replica.
     3. Each replica of the template model can access (in read/write mode) to instances
        of the place included in other replicas of the same SAN template model or in other
        replicas of different SAN model templates.
 - Function/method deps(i): method associated to a DAREP shared place.
     1. Method deps(), without input index, for each replica of the template model (where
        DAREP shared place is defined) returns the list of references to all instances of
        the place shared with the replica, i.e., the instances of the place from wich the
        replica depends or that impact on the replica.
     2. Method deps(i), for each replica of the template model (where DAREP shared place is
        defined) returns the i-th reference of the list deps(). 
     Example of usage:
       P->deps(i): returns the i-th reference of the list P->deps().
       P->deps(i)->Mark(): returns the values of the i-th instance of the place P included
                           in the list P->deps().
     Notice that the index i is not the absolute index of the instances of P.
  - Function/method deps(i)->Index(): method returning the absolute index of the instance
                                      of the place P referred by the i-th entry of the
                                      list P->deps().
Non DAREP-shared places can be local to each instance of the SAN template model or shared
among all instances. These latter places can be shared manually after the automatic
generation of the composed DAREP join.


C. DAREP model:
---------------

DAREP model is a composed model joining the replicas of the template models.
Replicas of DAREP-shared places are automatically generated in the replicas of the SAN templates
models and are also automatically shared among the replicas of the template models, based on the
topology associated to each place for each replica of the SAN template where the place is included.


How to use DAREP approach to automatically generate DAREP model:

For each different experiment that requires a different setting for
n and delta, perform the following steps:

1.  close Mobius GUI before generating darep models
2.  set the running project: 
    - the original project PROJECTNAME, or 
    - an automatically-generated copy of the original project PROJECTNAME, named using a name extension that identifies the solver(s) to evaluate, e.g., _n1000_delta999:
        cd originalproject/darep/
        ./bin/mkrunningproj.bash -e _n1000_delta999
3.  move into the running project:
    cd originalproject_n1000_delta999/darep
4.  generate the DAREP xml input file corresponding to the setting for n and delta, using a name extension that identifies the setting to be used, e.g., _n1000_delta999, resulting in the file input_n1000_delta999.xml:
    ./bin/inputxml.bash -s SAN -c Comp -j SANSANDAREP -p S -t Place -n 1000 -d 999 -e _n1000_delta999
5.  generate the darep models and the C++ data structures and the corresponding library for a setting of n and delta, e.g., for the input file input_n1000_delta999.xml:
    ./bin/darep.pl input_n1000_delta999.xml
6.  generate the files makefile and cpp, using:
       - gui command resave, or
       - manually mobius shell (with linux, on MacOSX mobius shell does not work), with mobius shell on linux perform the following steps:
         setenv DISPLAY :3
         rlwrap /usr/share/mobius-2.5/mobius-shell.sh -c
         Mobius> open projectnameendingwith_n1000_delta999
         Mobius> resave
       - automatic script based on batch commands to mobius shell:
       ./bin/resaveproject.bash
7.  split the resulting composed model cpp file, e.g., for the composed model Comp:
    ./bin/splitrj.sh Comp
    you can skip this step if the resulting composed model cpp file is not so big file
8.  generate DAREP lib:
    cd c++
    make opt
9.  generate the solver, compiling all the models, using:
       - the gui command resave, or
       - by command line using the command make opt, e.g., for the simulator solver ms_n1000_delta999 to make the solver ms_varn_delta999_splitSim_linux:
    cd originalproject_n1000_delta999/Solver/ms_n1000_delta999
    make -j 8 -f makefile_split clean
    make -j 8 -f makefile_split opt
       or, alternatively, the following, if you skipped step 7:
    cd c++
    make opt
    cd originalproject_n1000_delta999/Solver/ms_n1000_delta999
    make -j 8 clean
    time make -j 8 opt
10. run the experiment(s), using:
       - the executable generated at step 9. with the experiment(s) corresponding to the setting of n and delta, e.g., n=1000, delta=999.
       - a batch file defined in batches directory
11. if used a copy of the original project, copy the results from the solver of the copied project to the solver of the original project:
    cd originalproject/darep/
    ./bin/getresultsfromrun.bash -p originalproject_n1000_delta999 -s ms_n1000_delta999 
   
   
=============================
   Other info
=============================

With Xml use:
&lt; for <
&gt; for >
&amp; for &

=============================

Files in directory "auto" are automatically generated by scripts, thus
please do not edit them, because they will be overwitten.

To change the files in "auto" please edit the original template files or the
scripts used to generate them.

=============================

=============================
   TODO:
=============================

- Multiple dependency-related state variables.
- Extend dependency-related state variables associating to each variable a template model name "tname", such that, each instance of the variable is defined in the corresponding instance of the template model "tname".
When "tname" is the name of the template model where the variable is used, then each instance of the variable is defined in the corresponding instance of the same template model.
When "tname" is not the name of the template model where the variable is used, then each instance of the variable is defined in the corresponding instance of a different template model, i.e., the model "tname".



