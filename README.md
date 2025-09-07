# Memory Sandbox

Memory Sandbox is an in-process memory sandboxing environment manager that allows segmentation of virtual memory in a processes and provides custom tools to manipulate the sandboxed memory.

> [!WARNING]\
> Memory Sandbox does **NOT** containerize, virtualize, or fully isolate code.
> Code running within the sandbox:
> - shares the same process as the host program
> - can access global/static memory outside the sandbox
>
> The guard pages only protect against **simple buffer overflows** at the edges of the sandboxed memory.  
> For running **untrusted or malicious code**, use proper process-level (in progress) or OS-level sandboxing. 
> 
> Please note: the developers of Memory Sandbox are **void of responsibility** in the event users of Memory Sandbox are to experience malicious and/or ill-natured outcomes on the host machine due to an escaped virus or items of similar nature.


