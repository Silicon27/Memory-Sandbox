# Planning the Interprocess Communication

Imagine this function:
```c++
struct func_ret; // contains info on the performance including the returned value of the function.

template <typename Ret, typename... Args>
func_ret run_function(std::function<Ret(Args...)> func, Args... arg);
```

It specifies a "*simple*" (with nuance) wrapper that runs the function passed into it.

That "*simple*" is where it gets complicated. Although simple on the surface, the internals of the function would be quite the opposite to simple.

The functionality of the function is as follows: 
1. Allow the endpoint user to specify a function pointer part of the host process's memory space
2. `run_function` would thereafter take that pointer and attempt to run it on the child process.



fork the main process and make a new child process and run the function that way

```c++
enum class Ret_Code {
    SUCCESS,
    FAILED
};

template <typename T>
struct Func_Ret {
    T ret_val;
    Ret_Code ret_code
};

template <typename Ret, typename... Args>
Func_Ret<Ret> run_function(std::function<Ret(Args...)> func, Args... args);
```


