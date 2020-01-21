## loadableModule

This directory contains all the files to create a loadable kernel module to intercept the `execve` system call and do my custom function. The aim is to check, before executing the application locally, if it can be executed remotely in the cluster.

This feature is still ongoing, need to be completed (in loadable.c our new execve does nothing right now) and tested in a virtual environment (for our system safety).

* `Makefile`: the build file to ease compilation
* `loadable.c`: the main file of the module
* `hook_function_ptr.h`: header file with logical addresses of syscall table and execve