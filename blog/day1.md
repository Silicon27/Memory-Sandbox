Just to note, this blog thingy is not going to be a daily thing and I won't be doing it by day number (day1.md, day2.md, so on), this particular markdown file is to mark the beginning of my endeavours.

This is where it all starts. In this markdown file I would describe the intuition and idea behind this project as well as the day one work that has been completed. 

*Memory Sandbox* is a project that came to mind more than once, and the original rendition of the idea in my mind was to create a lightweight "sandboxed" environment that's fast and runs in the same host process. The core philosophy was to create something that is as lightweight as a library and with functionalities similar to that of a traditional virtual machine. 

The second idea went out the window when I actually got started with the coding today. Turns out I had severely overestimated my programming skills. The main challenge became clear, as to create a fully sandboxed environment within the same host process is extremely difficult. In a single process, all code shares the same memory space, which means any native code running within the process could theoretically access or overwrite data in the host or other sandbox instances. True isolation, the kind you get from traditional virtual machines or separate processes, is simply unachievable purely in-process without relying on extremely careful software fault isolation techniques or running code in a managed runtime. 

Even with bounds checking and memory safety enforced within a runtime, the sandbox is only as strong as the runtime itself. Any untrusted native code loaded into the same process could breach the sandbox and bypass these protections easily. This lead me to rethink my design philosophy for this project, with now the core functionality being the ability of customization within this contained runtime.  Or in other words, **a in-process configurable computer**.

Now let's get into the technical and implementation details.

The sandbox would be based on `mmap()`, a libc function that, 
> *"... creates a new mapping in the virtual address space of the
calling process. "*

and the idea is to construct a sandboxed environment that looks as the following:
```
---------------------------------------------------------------------
|   Guard Page  |       Sandboxed Environment       |   Guard Page  |
---------------------------------------------------------------------
```

In this structure, the runtime environment would handle the portion dedicated to the sandboxed environment, together with a bounds checker for the guard pages.

### I decided to split In-Process and CProcess.

Now Memory Sandbox is divided into In-Process and Child Process runtime managers, each one using different sandboxing/isolation techniques.
