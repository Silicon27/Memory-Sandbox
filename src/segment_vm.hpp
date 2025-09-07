/**
 * Memory Sandbox (segment_vm.hpp)
 *
 * This file is part of the Memory Sandbox project.
 * Usage and distribution licensed under the MIT License. See LICENSE file.
 * Copyright (c) 2025 by Mingde Yang
 *
 * File created on 2025-09-07
 * Author: Mingde Yang
 */

#ifndef SEGMENT_VM_HPP
#define SEGMENT_VM_HPP

#include <csignal>
#include <ucontext.h>
#include <sys/mman.h>
#include <stdexcept>
#include <unistd.h>

// Segment Virtual Memory Manager is used by Memory Sandbox to
// segment virtual memory space in some program such
// that Memory Sandbox classes can use memory safely and
// avoid interference with the program's other memory usage.

namespace memory_sandbox {

    class Segment_virtual_memory_manager {
    public:
        // prohibit copying for memory exclusivity
        Segment_virtual_memory_manager(Segment_virtual_memory_manager const &) = delete;
        Segment_virtual_memory_manager &operator=(Segment_virtual_memory_manager const &) = delete;

        explicit Segment_virtual_memory_manager(std::size_t size, bool use_guard_pages = true)
        : size_(size), use_guard_pages_(use_guard_pages)
        {
            std::size_t page_size = sysconf(_SC_PAGESIZE);

            // round up to nearest page
            std::size_t total_alloc_size = ((size_ + page_size - 1) / page_size) * page_size;

            if (use_guard_pages_) {
                total_alloc_size += 2 * page_size; // one at start, one at end
            }

            memory_ = mmap(nullptr, total_alloc_size, PROT_READ | PROT_WRITE,
                           MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
            if (memory_ == MAP_FAILED) {
                throw std::runtime_error("mmap failed to allocate memory segment");
            }

            alloc_size_ = total_alloc_size;

            if (use_guard_pages_) {
                // start guard page
                if (mprotect(memory_, page_size, PROT_NONE) != 0) {
                    munmap(memory_, alloc_size_);
                    throw std::runtime_error("mprotect failed to set start guard page");
                }

                // end guard page
                void* end_guard = static_cast<char *>(memory_) + total_alloc_size - page_size;
                if (mprotect(end_guard, page_size, PROT_NONE) != 0) {
                    munmap(memory_, alloc_size_);
                    throw std::runtime_error("mprotect failed to set end guard page");
                }

                user_memory_ = static_cast<char *>(memory_) + page_size; // usable memory after start guard
            } else {
                user_memory_ = memory_; // no guard pages, user memory starts at beginning
            }
        }

        ~Segment_virtual_memory_manager() {
            if (memory_) {
                munmap(memory_, alloc_size_);
            }
        }


    protected:
        void* memory() { return user_memory_; }
        std::size_t size() { return size_; }
    private:
        void* memory_ = nullptr;            // start of allocated memory segment (includes guard pages)
        void* user_memory_ = nullptr;       // memory pointer for user to use
        std::size_t size_ = 0;              // requested size
        std::size_t alloc_size_ = 0;        // total allocated size including guard pages
        bool use_guard_pages_ = true;
    };
}





#endif //SEGMENT_VM_HPP
