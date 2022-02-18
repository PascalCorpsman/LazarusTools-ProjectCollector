I have a Codebase folder structure like this:

<Projects_folder>
  <Project_1>
  <Project_2>
  <Project_3>
  <Project_4>
  ..

<Personal_lib_folders>
 <Lib_1>
 <Lib_2>
 <Lib_3>

if i want to share one of my projects to others (or even want to upload them to Github) there is the need to collect all files that are within the project into one folder. This can be really annoying and error creating.

Project collector is a program to do that work for you. It reads out the project.lpi file and collects all the files in a given folder.

command line support:

-i <input.lpi file>
-o <output directory>


If you get back a project and want to "move back" all the project files into the <Lib_*> directories, use the ProjectUnCollector project.

